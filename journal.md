# Cloud Platform Engineering — Journal

---

## 2026-05-30 — Initial Planning: Terraform Multi-Cloud Folder Structure

### Context & Decisions

**Scope:** Design a Terraform/Terragrunt repository structure to deploy infrastructure across multiple AWS accounts in an AWS Organization. Azure support will be added later; structure must accommodate it from day one without rework.

**Key decisions recorded:**

| Decision | Choice | Rationale |
|---|---|---|
| AWS account layout | OU-based: Dev, Stage, Prod | Clear environment isolation, aligns with AWS best-practice landing zone |
| State backend | S3 + DynamoDB per account | Strongest isolation; no cross-account blast radius on state operations |
| Terraform wrapper | Terragrunt | DRY configs, automatic remote state wiring, `run-all` for batch deploys |
| GHA auth | OIDC (keyless) | No static credentials; role assumption scoped per account per workflow |

---

### Proposed Folder Structure

```
cloud-platform-engineering/
├── terraform/
│   ├── modules/                        # Reusable, versioned Terraform modules
│   │   ├── aws/
│   │   │   ├── vpc/
│   │   │   ├── eks/
│   │   │   ├── rds/
│   │   │   ├── iam-role/
│   │   │   ├── s3/
│   │   │   ├── security-group/
│   │   │   └── tf-bootstrap/          # Bootstraps S3+DynamoDB state backend per account
│   │   └── azure/                     # Placeholder — populated when Azure work begins
│   │
│   └── live/                          # Terragrunt live environment configs
│       ├── terragrunt.hcl             # Root config: remote state template, provider defaults
│       ├── aws/
│       │   ├── _global/               # Cross-account resources (e.g. org-level SCPs, IAM Identity Center)
│       │   │   └── terragrunt.hcl
│       │   ├── dev/
│       │   │   ├── account.hcl        # account_id, account_name, default_region
│       │   │   ├── us-east-1/
│       │   │   │   ├── region.hcl
│       │   │   │   ├── vpc/
│       │   │   │   │   └── terragrunt.hcl
│       │   │   │   └── eks/
│       │   │   │       └── terragrunt.hcl
│       │   │   └── us-west-2/         # Multi-region support built in
│       │   │       └── region.hcl
│       │   ├── stage/
│       │   │   ├── account.hcl
│       │   │   └── us-east-1/
│       │   │       ├── region.hcl
│       │   │       ├── vpc/
│       │   │       │   └── terragrunt.hcl
│       │   │       └── eks/
│       │   │           └── terragrunt.hcl
│       │   └── prod/
│       │       ├── account.hcl
│       │       └── us-east-1/
│       │           ├── region.hcl
│       │           ├── vpc/
│       │           │   └── terragrunt.hcl
│       │           └── eks/
│       │               └── terragrunt.hcl
│       └── azure/                     # Placeholder — mirrors aws/ layout when ready
│
├── .github/
│   └── workflows/
│       ├── tf-plan.yml                # PR: terragrunt plan on changed stacks only
│       ├── tf-apply.yml               # Merge to main: terragrunt apply (gated by environment)
│       └── tf-drift.yml               # Scheduled: detect drift across all accounts
│
├── scripts/
│   └── bootstrap/
│       └── bootstrap-account.sh       # One-time: creates S3 bucket + DynamoDB table per account
│
└── journal.md                         # This file
```

---

### Design Rationale

#### `terraform/modules/` — reusable primitives

- Each module is self-contained with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`.
- Modules are **not** environment-aware — all env-specific values injected via Terragrunt inputs.
- `tf-bootstrap/` module is run once per account to create the state S3 bucket and DynamoDB lock table before any other stack.
- `azure/` directory is a placeholder now; adding Azure modules later won't require restructuring.

#### `terraform/live/` — Terragrunt hierarchy

The 4-level hierarchy: **root → cloud provider → environment (OU) → region → stack**

- `terragrunt.hcl` (root): defines the remote state S3 backend template using `path_relative_to_include()` so each stack gets a unique key automatically.
- `account.hcl`: declares `account_id`, `account_name`, `aws_profile` — read by child configs via `read_terragrunt_config()`.
- `region.hcl`: declares `aws_region` — enables multi-region stacks within the same account.
- Stack-level `terragrunt.hcl`: specifies which module to source, inputs, and any `dependency` blocks for cross-stack outputs (e.g. VPC ID into EKS).

#### GitHub Actions Workflows

**`tf-plan.yml`** (triggers on PR):
1. Detect which `live/` paths changed (using `git diff`).
2. For each changed stack, assume the account-specific IAM role via OIDC.
3. Run `terragrunt plan` and post output as PR comment.
4. Non-prod accounts: auto-approve plan step; prod requires manual approval gate.

**`tf-apply.yml`** (triggers on merge to `main`):
1. Same changed-path detection.
2. Deploy order: dev → stage → prod (sequential, each gated).
3. Prod environment requires GitHub Environment approval before apply.

**`tf-drift.yml`** (scheduled, nightly):
1. Run `terragrunt run-all plan` across all accounts.
2. If drift detected, open a GitHub Issue or post to Slack.

#### OIDC Role Structure

Each account has an IAM role `github-actions-terraform` with:
- Trust policy scoped to this repo + `main` branch for apply; all branches for plan (read-only).
- Permissions: account-specific, least-privilege for the resources managed in that account.
- A separate `github-actions-terraform-readonly` role for plan-only runs on PRs from forks.

---

### Next Steps

- [x] Scaffold the folder structure (empty files + placeholder READMEs)
- [x] Write root `terragrunt.hcl` with remote state template
- [x] Write first module: `tf-bootstrap` (S3 + DynamoDB)
- [x] Write `vpc` module (AWS)
- [x] Write `eks` module (AWS)
- [x] Write `account.hcl` templates for dev/stage/prod
- [x] Write stack-level `terragrunt.hcl` for vpc/eks in all 3 environments
- [x] Draft `tf-plan.yml` GitHub Actions workflow
- [x] Draft `tf-apply.yml` GitHub Actions workflow (dev → stage → prod with gate)
- [x] Draft `tf-drift.yml` nightly drift detection workflow
- [x] Write `bootstrap-account.sh` one-time account setup script
- [ ] Document OIDC trust policy and IAM role setup
- [ ] Write remaining modules: `rds`, `iam-role`, `s3`, `security-group`
- [ ] Set up GitHub Environments (dev/stage/prod) with required reviewers for prod

---

## 2026-05-30 — Scaffolding Complete

All files created. Structure is live and ready for real account IDs to be substituted into:
- `terraform/live/aws/dev/account.hcl` — replace `111111111111`
- `terraform/live/aws/stage/account.hcl` — replace `222222222222`
- `terraform/live/aws/prod/account.hcl` — replace `333333333333`
- `.github/workflows/tf-apply.yml` — account IDs hardcoded in role ARNs (3 locations)
- `.github/workflows/tf-drift.yml` — account IDs in matrix (3 locations)

**First-run order for a new account:**
1. Run `scripts/bootstrap/bootstrap-account.sh <account-id> us-east-1 <profile>` to create S3 + DynamoDB
2. Create `github-actions-terraform` and `github-actions-terraform-readonly` IAM roles with OIDC trust
3. Run `terragrunt plan` from any stack directory to verify state backend connectivity

---
