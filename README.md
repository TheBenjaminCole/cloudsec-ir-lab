# CloudSec IR Lab (cloudsec-ir-lab)

**Description:** A reproducable AWS-based Cloud Security Incident Response lab demonstrating detection, alerting, and automated response using Terraform, GuardDuty, Security Hub, CloudTrail, EventBridge, Lambda and centralized logging.

## Timeline
- **Target:** 4 weeks
- Sprint cadence: 2-week sprints

## Repo Layout 
- `/infra` - Terraform code
- `/modules` - Terraform modules
- `/scripts` - simulation + smoke tests
- `/.github/workflows` - CI/CD

## Getting Started (dev)
1. Create branch `feature/<name>`.
2. Use Github Actions for plan/validate on PR.
3. **DO NOT** commit any secrets, `.tfvars` with creds, or AWS keys.

## TODO (Sprint 1)
- [ ] Add Terraform backend + S3/DynamoDB locking (Task 2)
- [ ] Add minimal `main.tf` that `terraform init` succeeds

(See `docs/README-draft.md` for full docs)