# Terraform Projects

Infrastructure-as-code assignments from my DevOps learning path. Each project provisions real
AWS infrastructure end-to-end with Terraform — no manual console clicks, no post-boot SSH steps.

## Projects

| # | Project | What it deploys | Status |
|---|---------|-----------------|--------|
| 1 | [WordPress on EC2](assignment-1-wordpress/) | Full LAMP + WordPress stack on a single EC2 instance, provisioned via `user_data` | ✅ Complete |
| 2 | [EC2 with Cloud-Init](assignment-2-cloudinit/) | EC2 instance configured on boot with a cloud-init YAML file | 🚧 Not started |

## Repository structure

```
.
├── README.md                      # You are here
├── .gitignore                     # Keeps state files + secrets out of git
├── assignment-1-wordpress/        # Project 1 — WordPress via user_data
│   ├── README.md                  # Full write-up: build, structure, learnings, issues
│   ├── provider.tf                # AWS provider + version pinning
│   ├── main.tf                    # AMI lookup, security group, EC2 instance
│   ├── variables.tf               # Region + instance type inputs
│   ├── outputs.tf                 # Public IP + site URL
│   ├── setup.sh                   # Bootstrap script passed as user_data
│   └── screenshots/               # Evidence of the working deployment
└── assignment-2-cloudinit/        # Project 2 — cloud-init (scaffolded, empty)
```

## Conventions used across projects

- **One folder per assignment**, each independently `terraform init`-able.
- **Provider versions pinned** (`.terraform.lock.hcl` committed) so runs are reproducible.
- **Everything parameterised** through `variables.tf` — no hardcoded regions or instance types
  in resource blocks.
- **State is never committed.** `terraform.tfstate` contains plaintext secrets; `.gitignore`
  excludes it.

## Prerequisites

- Terraform ≥ 1.0
- AWS CLI configured with credentials (`aws configure`)
- An AWS account with a **default VPC** in the target region (see project 1 notes on why)

## Running any project

```bash
cd assignment-1-wordpress
terraform init      # download providers
terraform plan      # preview changes
terraform apply     # provision
terraform destroy   # tear down (avoid surprise bills)
```
