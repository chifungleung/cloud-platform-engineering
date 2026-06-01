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
- `terraform/live/aws/dev/public-web-app-dev-01/account.hcl` — replace `444444444444`
- `terraform/live/aws/stage/account.hcl` — replace `222222222222`
- `terraform/live/aws/prod/account.hcl` — replace `333333333333`

**First-run order for a new account:**
1. Run `scripts/bootstrap/bootstrap-account.sh <account-id> us-east-1 <profile>` to create S3 + DynamoDB
2. Create `github-actions-terraform` and `github-actions-terraform-readonly` IAM roles with OIDC trust
3. Run `terragrunt plan` from any stack directory to verify state backend connectivity

---

## 2026-05-30 — Onboard `public-web-app-dev-01` (DEV OU)

### What changed

**Structural change — multi-account OU layout:**
The initial scaffold assumed one account per OU (`dev/account.hcl` directly). With multiple named accounts needed under a single OU, an account-name level was inserted into the hierarchy:

```
Before: live/aws/dev/us-east-1/vpc/
After:  live/aws/dev/<account-name>/us-east-1/vpc/
```

This change was applied to `dev/` immediately. `stage/` and `prod/` will be restructured when their first named account is onboarded.

**New account: `public-web-app-dev-01`**
| File | Purpose |
|---|---|
| `live/aws/dev/public-web-app-dev-01/account.hcl` | Account ID `444444444444` (placeholder), OU tag `dev` |
| `live/aws/dev/public-web-app-dev-01/us-east-1/region.hcl` | Region declaration |
| `live/aws/dev/public-web-app-dev-01/us-east-1/vpc/terragrunt.hcl` | VPC — CIDR `10.10.0.0/16`, 2 AZs, public + private subnets |
| `live/aws/dev/public-web-app-dev-01/us-east-1/ec2/terragrunt.hcl` | EC2 web server — depends on VPC via `dependency` block |

**New module: `modules/aws/ec2`**
- EC2 instance with IMDSv2 enforced, encrypted EBS, SSM agent IAM role attached
- Configurable security group via `ingress_rules` input
- IAM instance profile included — no need to manage separately

**Workflow improvements — dynamic account ID resolution:**
- Removed hardcoded account IDs from all three workflows
- Added `scripts/get-account-id.sh` — walks up the directory tree from any stack path to find the nearest `account.hcl` and extracts the `account_id`
- `tf-drift.yml` now auto-discovers all `account.hcl` files at runtime — no changes required to the workflow when a new account is added

### Bootstrap steps for `public-web-app-dev-01`

1. Replace placeholder account ID in `account.hcl`:
   ```hcl
   account_id = "444444444444"  →  actual 12-digit account ID
   ```

2. Bootstrap state backend:
   ```bash
   ./scripts/bootstrap/bootstrap-account.sh <actual-account-id> us-east-1 public-web-app-dev-01
   ```

3. Create OIDC IAM roles in the account:
   - `github-actions-terraform` (apply — trust: `repo:*:ref:refs/heads/main`)
   - `github-actions-terraform-readonly` (plan — trust: `repo:*:*`)

4. Verify connectivity:
   ```bash
   cd terraform/live/aws/dev/public-web-app-dev-01/us-east-1/vpc
   terragrunt plan
   ```

5. Open a PR touching the new stacks to trigger `tf-plan.yml` and confirm the workflow resolves the correct account.

### Next Steps

- [ ] Replace placeholder account ID `444444444444` with real account ID
- [ ] Run bootstrap script for `public-web-app-dev-01`
- [ ] Create OIDC IAM roles in `public-web-app-dev-01`
- [ ] Restructure `stage/` and `prod/` to named-account layout when first account is onboarded
- [ ] Document OIDC trust policy and IAM role setup
- [ ] Write remaining modules: `rds`, `iam-role`, `s3`, `security-group`
- [ ] Set up GitHub Environments (dev/stage/prod) with required reviewers for prod

---

## 2026-06-01 — Onboard `network-dev` (DEV OU)

### Account Onboarding Flow — Feature Branch + PR

This entry documents the repeatable flow for onboarding a new AWS account into the platform.

#### 1. Create a feature branch

```bash
git checkout -b feat/onboard-<account-name>
```

Keeps the change isolated and reviewable. All onboarding work is committed here before anything touches `main`.

#### 2. Scaffold the account directory

Under `terraform/live/aws/<ou>/<account-name>/`, create three files:

| File | Purpose |
|---|---|
| `account.hcl` | Account metadata: `account_id`, `account_name`, `ou`, `aws_profile` |
| `us-east-1/region.hcl` | Region declaration |
| `us-east-1/vpc/terragrunt.hcl` | VPC baseline — CIDR must not overlap other accounts |

Choose a non-overlapping CIDR. Convention so far:

| Account | VPC CIDR |
|---|---|
| `public-web-app-dev-01` | `10.10.0.0/16` |
| `network-dev` | `10.20.0.0/16` |

Add additional stacks (EC2, EKS, TGW, etc.) under `us-east-1/` as required for the account's purpose.

#### 3. Commit and push

```bash
git add terraform/live/aws/<ou>/<account-name>/
git commit -m "feat: onboard <account-name> to <OU> OU"
git push -u origin feat/onboard-<account-name>
```

#### 4. Open a Pull Request

```bash
gh pr create --title "feat: onboard <account-name> to <OU> OU" ...
```

Opening the PR automatically triggers `tf-plan.yml`, which:
- Detects the changed stacks via `git diff`
- Assumes the account-specific OIDC IAM role
- Runs `terragrunt plan` and posts output as a PR comment

Review the plan output before merging.

#### 5. Post-merge bootstrap (one-time, per account)

After the PR merges to `main`, complete the one-time account setup:

1. Replace the `account_id` placeholder in `account.hcl` with the real 12-digit AWS account ID.
2. Run the bootstrap script to create the S3 state bucket and DynamoDB lock table:
   ```bash
   ./scripts/bootstrap/bootstrap-account.sh <account-id> us-east-1 <aws-profile>
   ```
3. Create OIDC IAM roles in the new account:
   - `github-actions-terraform` — apply, trust: `repo:*:ref:refs/heads/main`
   - `github-actions-terraform-readonly` — plan, trust: `repo:*:*`
4. Verify state backend connectivity:
   ```bash
   cd terraform/live/aws/<ou>/<account-name>/us-east-1/vpc
   terragrunt plan
   ```

### What changed this session

**New account: `network-dev`**

| File | Purpose |
|---|---|
| `live/aws/dev/network-dev/account.hcl` | Account metadata, OU tag `dev` (account ID placeholder) |
| `live/aws/dev/network-dev/us-east-1/region.hcl` | Region declaration |
| `live/aws/dev/network-dev/us-east-1/vpc/terragrunt.hcl` | VPC — CIDR `10.20.0.0/16`, 2 AZs, public + private subnets |

**Branch:** `feat/onboard-network-dev`
**PR:** https://github.com/chifungleung/cloud-platform-engineering/pull/2

### Next Steps

- [ ] Replace placeholder account ID in `network-dev/account.hcl` with real account ID
- [ ] Run bootstrap script for `network-dev`
- [ ] Create OIDC IAM roles in `network-dev`
- [ ] Add network-specific stacks (TGW, Route 53 Resolver, etc.) as needed

---
