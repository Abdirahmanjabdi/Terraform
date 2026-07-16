# Terraform Projects

Infrastructure-as-code assignments from my DevOps learning path. Each project provisions real AWS
infrastructure end-to-end with Terraform, with no manual console clicks and no post-boot SSH steps.

## Projects

| # | Project | What it deploys | Status |
|---|---------|-----------------|--------|
| 1 | [WordPress on EC2](assignment-1-wordpress/) | Full LAMP and WordPress stack on a single EC2 instance, bootstrapped with an imperative bash script | Complete |
| 2 | [NGINX with Cloud-Init](assignment-2-cloudinit/) | NGINX web server configured on boot with a declarative cloud-init YAML file | Complete |

The two projects deliberately solve the same class of problem in opposite ways. Project 1
bootstraps a server with bash through `user_data` and hits an apt lock race condition that silently
breaks the deploy. Project 2 does comparable work declaratively with cloud-init, where that race
cannot occur. Reading them in order is the point.

## Repository structure

```
.
├── README.md                      # You are here
├── .gitignore                     # Keeps state files and secrets out of git
├── assignment-1-wordpress/        # Project 1: WordPress via user_data
│   ├── README.md                  # Full write-up: build, structure, learnings, issues
│   ├── provider.tf                # AWS provider and version pinning
│   ├── main.tf                    # AMI lookup, security group, EC2 instance
│   ├── variables.tf               # Region and instance type inputs
│   ├── outputs.tf                 # Public IP and site URL
│   └── setup.sh                   # Bootstrap script passed as user_data
└── assignment-2-cloudinit/        # Project 2: NGINX via cloud-init
    ├── README.md                  # Full write-up, including the contrast with project 1
    ├── provider.tf                # AWS provider and version pinning
    ├── main.tf                    # AMI lookup, security group, EC2 instance
    ├── variables.tf               # Region and instance type inputs
    ├── outputs.tf                 # Site URL
    └── cloud-init.yaml            # Declarative instance config passed as user_data
```

## Conventions used across projects

- **One folder per assignment**, each independently `terraform init`-able.
- **Provider versions pinned** with `.terraform.lock.hcl` committed, so runs are reproducible.
- **Everything parameterised** through `variables.tf`. No hardcoded regions or instance types in
  resource blocks.
- **State is never committed.** `terraform.tfstate` contains plaintext secrets, so `.gitignore`
  excludes it.

## Prerequisites

- Terraform 1.0 or later
- AWS CLI configured with credentials (`aws configure`)
- An AWS account with a default VPC in the target region (see project 1 notes on why)

## Running any project

```bash
cd assignment-1-wordpress
terraform init      # download providers
terraform plan      # preview changes
terraform apply     # provision
terraform destroy   # tear down and avoid surprise bills
```
