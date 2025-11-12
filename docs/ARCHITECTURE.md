# Architecture (draft)

This file will contain architecture diagrams (Mermaid), component descriptions, and data flows:
- VPC with public/private subnets
- Bastion host for access
- Juice Shop app deployed in isolated private subnet (reachable via bastion)
- RDS (private)
- CloudTrail -> S3
- Centralized logs bucket + Athena / OpenSearch
- GuardDuty, Security Hub, AWS Config
- EventBridge -> Lambda -> SNS -> Slack

(Full mermaid diagram to be added in next task)