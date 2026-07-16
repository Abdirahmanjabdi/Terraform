# Screenshots — Project 1

Drop your images in **this folder** using the **exact filenames** below. The embeds in
[`../README.md`](../README.md) already point at these paths, so they render as soon as the files
exist. No filename changes needed anywhere.

Format: **PNG** preferred. Crop to the relevant content.

## Capture checklist

| # | Filename | Capture from | What must be visible |
|---|----------|--------------|----------------------|
| 1 | `01-terraform-init.png` | Terminal, in `assignment-1-wordpress/`, after `terraform init` | "Terraform has been successfully initialized!" |
| 2 | `02-terraform-plan.png` | Terminal, after `terraform plan` | The "Plan: 2 to add, 0 to change, 0 to destroy." line |
| 3 | `03-terraform-apply.png` | Terminal, after `terraform apply` | "Apply complete!" **and** the `wordpress_public_ip` + `wordpress_url` outputs |
| 4 | `04-wordpress-install-screen.png` | Browser → `http://<public-ip>`, 2–4 min after apply | WordPress language-select / welcome install screen |
| 5 | `05-wordpress-site-live.png` | Browser → `http://<public-ip>`, after finishing the install | Default theme homepage with your site title |
| 6 | `06-wordpress-admin-dashboard.png` | Browser → `http://<public-ip>/wp-admin`, logged in | The WP admin dashboard |
| 7 | `07-aws-console-ec2.png` | AWS Console → EC2 → Instances (**eu-north-1**) | Instance "WordPress Server Project 1" in `running` state, public IP visible |
| 8 | `08-aws-console-security-group.png` | AWS Console → EC2 → Security Groups → `wordpress_sg` → Inbound rules | The port 80 and port 22 rules |
| 9 | `09-cloudinit-error-log.png` *(optional)* | EC2 Instance Connect on the **broken** instance → `tail -n 50 /var/log/cloud-init-output.log` | The `Unit apache2.service not found` error. **Only if you captured it at the time** — don't rebuild a broken box for this |
| 10 | `10-terraform-destroy.png` *(optional)* | Terminal, after `terraform destroy` | "Destroy complete! Resources: 2 destroyed." |

## Order to capture in

Screenshots 1–3 happen during the deploy, 4–6 need the site live, 7–8 can be taken any time while
the instance is running, and 10 comes last. So: **run the deploy → capture 1, 2, 3 → wait 2–4
minutes → capture 4 → complete the WordPress install → capture 5, 6 → open the AWS console and
capture 7, 8 → destroy and capture 10.**

Don't destroy before you've taken 4–8, or you'll have to redeploy to get them.

**#9 is the odd one out** — it's from the *first, broken* deploy, so it can only come from a
screenshot you already took. If you don't have it, skip it and delete that section from the
project README. The log is quoted in full in the write-up either way.

## Before you commit

- **Blank out your AWS account ID** in any console screenshot (top-right of the AWS nav bar).
- Public IPs are fine to leave visible — the instance is destroyed afterwards.
- Don't capture the WordPress admin password you set during the install.
