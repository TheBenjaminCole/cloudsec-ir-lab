# Demo script (draft)

1. Show README and architecture diagram.
2. Show Terraform state backend configured (S3 + DynamoDB) and `terraform plan`.
3. Show deployed resources: VPC, EC2 (bastion), Juice Shop in private subnet (via bastion tunnel).
4. Trigger simulated incident (script) → show EventBridge match, Security Hub / GuardDuty finding, Slack alert, Lambda quarantine action, and remediation log in S3/Athena.
5. Show GitHub Actions run: plan on PR and apply on main.
