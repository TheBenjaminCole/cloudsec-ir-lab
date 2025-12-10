import os
import json
import time
import boto3
from datetime import datetime, timezone, timedelta

ec2 = boto3.client("ec2")
sns = boto3.client("sns")

LAMBDA_ROLE_ARN = os.environ.get("LAMBDA_ROLE_ARN")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
RISKY_CIDRS = [c.strip() for c in os.environ.get("RISKY_CIDRS", "0.0.0.0/0").split(",")]
REMEDIATION_TAG_KEY = os.environ.get("REMEDIATION_TAG_KEY", "auto-remediated")
REMEDIATION_TTL_MINUTES = int(os.environ.get("REMEDIATION_TTL_MINUTES", "60"))

def log(msg, level="INFO"):
    print(f"{datetime.now(timezone.utc).isoformat()} {level}: {msg}")

def tag_recent(sg):
    # returns True if SG has REMEDIATION_TAG_KEY and it's within TTL
    tags = sg.get("Tags") or []
    for t in tags:
        if t.get("Key") == REMEDIATION_TAG_KEY:
            try:
                ts = float(t.get("Value"))
                then = datetime.fromtimestamp(ts, timezone.utc)
                if datetime.now(timezone.utc) - then < timedelta(minutes=REMEDIATION_TTL_MINUTES):
                    return True
            except Exception:
                return True
    return False

def tag_sg(sg_id):
    now_ts = time.time()
    ec2.create_tags(Resources=[sg_id],
                    Tags=[{"Key": REMEDIATION_TAG_KEY, "Value": str(now_ts)},
                          {"Key": "remediated_by", "Value": "cloudsec-autoremediate"}])

def sns_publish(subject, message):
    if not SNS_TOPIC_ARN:
        log("SNS_TOPIC_ARN not set - skipping SNS publish", level="WARN")
        return
    sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=subject, Message=message)

def revoke_ingress(sg_id, ip_permission):
    # ip_permission is structured per AWS API: dict with IpProtocol, FromPort, ToPort, IpRanges, Ipv6Ranges
    try:
        ec2.revoke_security_group_ingress(GroupId=sg_id, IpPermissions=[ip_permission])
        log(f"Revoked ingress on {sg_id}: {ip_permission}")
        tag_sg(sg_id)
        sns_publish(
            subject=f"Auto-Remediated SG {sg_id}",
            message=json.dumps({"sg_id": sg_id, "action": "revoked", "ip_permission": ip_permission}, default=str)
        )
    except Exception as e:
        log(f"Failed to revoke ingress on {sg_id}: {e}", level="ERROR")
        sns_publish(subject=f"Failed remediation for {sg_id}", message=str(e))

def any_ip_in_ranges(ip_ranges, risky_cidrs):
    # ip_ranges: list of {"CidrIp": "..."} or similar
    for ipr in ip_ranges:
        cidr = ipr.get("CidrIp") or ipr.get("CidrIpv6")
        if cidr and cidr in risky_cidrs:
            return True
    return False

def handler_authorize_sg(event_detail):
    # event_detail is detail from CloudTrail 'AuthorizeSecurityGroupIngress' event
    # find groupId
    try:
        req_params = event_detail.get("requestParameters", {})
        # requestParameters can include groupId or groupName; groupId is preferred
        sg_id = req_params.get("groupId") or None
        if not sg_id:
            log("No SG id found in event; skipping", level="WARN")
            return

        # check if event was caused by this Lambda (avoid remediating our own API calls)
        user_identity = event_detail.get("userIdentity", {})
        arn = user_identity.get("arn") or user_identity.get("principalId")
        if arn and LAMBDA_ROLE_ARN and LAMBDA_ROLE_ARN == arn:
            log(f"Ignoring event because userIdentity arn == lambda role arn ({arn})")
            return

        # fetch SG description (current tags)
        sg = ec2.describe_security_groups(GroupIds=[sg_id])["SecurityGroups"][0]
        if tag_recent(sg):
            log(f"Skipping {sg_id} because it was recently remediated (tag present).")
            return

        # inspect ipPermissions that were added (requestParameters.ipPermissions)
        ip_permissions = req_params.get("ipPermissions") or []
        # ip_permissions may be dict with 'item' in some CloudTrail shapes; normalize:
        if isinstance(ip_permissions, dict):
            ip_permissions = ip_permissions.get("items") or ip_permissions.get("item") or [ip_permissions]

        for perm in ip_permissions:
            from_port = perm.get("fromPort")
            to_port = perm.get("toPort")
            protocol = perm.get("ipProtocol") or perm.get("IpProtocol")
            
            # handle nested ipRanges / ipv6Ranges
            ip_ranges = perm.get("ipRanges") or perm.get("Ipv4Ranges") or []
            if isinstance(ip_ranges, dict) and "items" in ip_ranges:
                ip_ranges = ip_ranges["items"]

            ipv6_ranges = perm.get("ipv6Ranges") or perm.get("Ipv6Ranges") or []
            if isinstance(ipv6_ranges, dict) and "items" in ipv6_ranges:
                ipv6_ranges = ipv6_ranges["items"]

            # combine ip ranges
            ranges = []
            for r in ip_ranges:
                if isinstance(r, dict):
                    ranges.append({"CidrIp": r.get("cidrIp") or r.get("CidrIp")})
                else:
                    ranges.append({"CidrIp": r})
            for r in ipv6_ranges:
                if isinstance(r, dict):
                    ranges.append({"CidrIpv6": r.get("cidrIpv6") or r.get("CidrIpv6")})
                else:
                    ranges.append({"CidrIpv6": r})

            # check if this permission includes SSH/tcp/22
            ports_match = False
            if protocol in ("tcp", "6", None) or protocol == "-1":
                try:
                    if from_port is None and to_port is None:
                        ports_match = True
                    else:
                        if isinstance(from_port, str):
                            from_port = int(from_port)
                        if isinstance(to_port, str):
                            to_port = int(to_port)
                        if from_port is not None and to_port is not None:
                            ports_match = (from_port <= 22 <= to_port)
                except Exception:
                    ports_match = False

            if not ports_match:
                continue

            # check if any range is in risky cidrs
            if any_ip_in_ranges(ranges, RISKY_CIDRS):
                api_perm = {
                    "IpProtocol": "tcp",
                    "FromPort": 22,
                    "ToPort": 22,
                    "IpRanges": [r for r in ranges if r.get("CidrIp")],
                    "Ipv6Ranges": [r for r in ranges if r.get("CidrIpv6")]
                }
                # revoke the rule
                revoke_ingress(sg_id, api_perm)

    except Exception as e:
        log(f"Exception in handler_authorize_sg: {e}", level="ERROR")
        sns_publish(subject="sg-autoremediate handler exception", message=str(e))


def lambda_handler(event, context):
    log(f"Received event: {json.dumps(event)}")
    detail = event.get("detail") or {}
    event_name = detail.get("eventName")
    # guard: only process AuthorizeSecurityGroupIngress/Egress
    if event_name in ("AuthorizeSecurityGroupIngress", "AuthorizeSecurityGroupEgress"):
        handler_authorize_sg(detail)
    else:
        log(f"Ignoring eventName {event_name}")

def lambda_handler_wrapper(event, context):
    return lambda_handler(event, context)

lambda_handler = lambda_handler

