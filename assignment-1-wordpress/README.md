# Project 1 — Deploy WordPress Using Terraform

Deploys a complete, publicly reachable WordPress site on AWS using nothing but `terraform apply`.
The instance boots, installs a LAMP stack, configures a database, downloads WordPress and wires up
`wp-config.php` — all without a single manual step or SSH session.

**Result:** a working WordPress installation at `http://<public-ip>`, ready for the famous
five-minute install.

---

## What I built

A single-instance WordPress stack in AWS, provisioned entirely as code:

- **EC2 instance** (`t3.micro`, Ubuntu 20.04 LTS) running the full stack
- **Security group** allowing HTTP (80) and SSH (22) inbound, all traffic outbound
- **Dynamic AMI lookup** so the latest Canonical Ubuntu image is always used — no stale
  hardcoded AMI IDs that break across regions
- **`user_data` bootstrap script** (`setup.sh`) that installs and configures Apache, MySQL,
  PHP and WordPress on first boot
- **Outputs** exposing the public IP and a click-ready URL

### Architecture

```mermaid
flowchart LR
    User([User]) -->|HTTP :80| SG
    subgraph AWS["AWS · eu-north-1 · Default VPC"]
        SG[Security Group<br/>wordpress_sg<br/>in: 80, 22 · out: all]
        SG --> EC2
        subgraph EC2["EC2 · t3.micro · Ubuntu 20.04"]
            Apache[Apache2 + PHP]
            MySQL[(MySQL<br/>db: wordpress)]
            Apache <--> MySQL
        end
    end
    AMI[/data.aws_ami<br/>latest Ubuntu/] -.->|resolves AMI id| EC2
    Script[/setup.sh<br/>user_data/] -.->|runs on first boot| EC2
```

**Boot sequence:** Terraform creates the SG → launches EC2 with `setup.sh` as `user_data` →
cloud-init runs the script as root on first boot → Apache serves WordPress on port 80.

---

## How the Terraform code is structured

Split by responsibility rather than dumped in one file, so each concern is easy to find:

| File | Responsibility |
|------|----------------|
| `provider.tf` | Declares the AWS provider, pins it to `6.55.0`, sets the region from a variable |
| `main.tf` | The infrastructure itself — AMI data source, security group, EC2 instance |
| `variables.tf` | Inputs: `aws_region`, `instance_type` — both with sensible defaults |
| `outputs.tf` | What I need after apply: the public IP and the full site URL |
| `setup.sh` | The bootstrap script, referenced by `user_data` rather than inlined |
| `.terraform.lock.hcl` | Locks provider hashes so `init` is reproducible on any machine |

### `provider.tf` — pinned, not floating

```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "6.55.0"
  }
}
```

Pinning to an exact version means a provider release can't silently change behaviour under me.
The lock file is committed for the same reason.

### `main.tf` — three blocks, in dependency order

**1. AMI data source** — looks the image up at plan time instead of hardcoding an ID:

```hcl
data "aws_ami" "Ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
```

AMI IDs are region-specific. Hardcoding one pins the code to a single region and rots the moment
Canonical publishes a new build. The filter + `most_recent` combination keeps it portable.

**2. Security group** — least surface I could get away with for the assignment:

```hcl
ingress { from_port = 80, to_port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
ingress { from_port = 22, to_port = 22,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
egress  { from_port = 0,  to_port = 0,   protocol = "-1",  cidr_blocks = ["0.0.0.0/0"] }
```

Egress is wide open by design — the instance needs it to reach the Ubuntu apt mirrors and
`wordpress.org` during bootstrap. Without it, `setup.sh` silently fails.

**3. EC2 instance** — ties the other two together:

```hcl
resource "aws_instance" "wordpress_server" {
  ami             = data.aws_ami.Ubuntu.id                    # from the data source
  instance_type   = var.instance_type                          # from variables
  security_groups = [aws_security_group.wordpress_sg.name]     # implicit dependency
  user_data       = file("${path.module}/setup.sh")            # from the script
}
```

I never wrote an explicit `depends_on`. Referencing `aws_security_group.wordpress_sg.name` is
enough — Terraform builds the dependency graph from that reference and creates the SG first.

### `setup.sh` — the bootstrap

Runs as root via cloud-init on first boot only. In order:

1. Set `DEBIAN_FRONTEND=noninteractive` so `apt` never blocks on a prompt
2. Wait for the dpkg lock to clear (see Issues below)
3. `apt install` Apache, MySQL, PHP, `php-mysql`, `libapache2-mod-php`
4. Enable + start both services so they survive a reboot
5. Create the `wordpress` database, the `wp_user` account, and grant privileges
6. Download and extract the latest WordPress tarball to `/var/www/html`
7. `chown` to `www-data` and remove Apache's default `index.html`
8. Copy `wp-config-sample.php` → `wp-config.php` and `sed` the DB credentials in
9. Restart Apache to load the PHP module

### `outputs.tf` — no hunting through the console

```hcl
output "wordpress_url" {
  value = "http://${aws_instance.wordpress_server.public_ip}"
}
```

Building the URL in the output rather than just emitting a bare IP means apply finishes with a
link I can paste straight into a browser.

---

## Deploying it

```bash
cd assignment-1-wordpress

terraform init      # downloads the pinned AWS provider
terraform plan      # review: 2 resources to add
terraform apply     # type 'yes' — takes ~1 min for the instance
```

Then **wait 2–4 minutes** after apply returns. Terraform reports success the moment the instance
is *running*, but `user_data` is still installing packages in the background. Hitting the URL
immediately gives a connection error or an Apache default page — that's expected, not a failure.

```bash
terraform output wordpress_url   # → http://16.x.x.x
terraform destroy                # tear it down when finished
```

---

## Screenshots

> **How to add these:** save each image into `assignment-1-wordpress/screenshots/` using the exact
> filename below and the embed will render automatically. See
> [`screenshots/README.md`](screenshots/) for the full capture checklist.

### 1. `terraform init` — provider downloaded

> 📸 **Capture from:** your terminal, in `assignment-1-wordpress/`, after running `terraform init`.
> Show the "Terraform has been successfully initialized!" message.

![terraform init output](screenshots/01-terraform-init.png)

### 2. `terraform plan` — 2 resources to add

> 📸 **Capture from:** your terminal, after `terraform plan`. Show the
> "Plan: 2 to add, 0 to change, 0 to destroy." summary line.

![terraform plan output](screenshots/02-terraform-plan.png)

### 3. `terraform apply` — outputs with the live URL

> 📸 **Capture from:** your terminal, after `terraform apply` completes. Show the
> "Apply complete!" line **and** the `wordpress_public_ip` / `wordpress_url` outputs.

![terraform apply output](screenshots/03-terraform-apply.png)

### 4. WordPress installer — the stack is live

> 📸 **Capture from:** your browser at `http://<public-ip>` (from the apply output), 2–4 minutes
> after apply. Show the WordPress language-selection / "Welcome" install screen. This is the proof
> that Apache, PHP **and** MySQL all came up correctly from `user_data`.

![WordPress installation screen](screenshots/04-wordpress-install-screen.png)

### 5. WordPress site — running

> 📸 **Capture from:** your browser at `http://<public-ip>` after completing the five-minute
> install. Show the default theme homepage with your site title.

![WordPress site running](screenshots/05-wordpress-site-live.png)

### 6. WordPress admin dashboard

> 📸 **Capture from:** your browser at `http://<public-ip>/wp-admin` after logging in. Show the
> dashboard — this proves the DB connection and admin account both work.

![WordPress admin dashboard](screenshots/06-wordpress-admin-dashboard.png)

### 7. EC2 instance in the AWS console

> 📸 **Capture from:** AWS Console → EC2 → Instances (region **eu-north-1**). Show the instance
> named **"WordPress Server Project 1"** in the `running` state with its public IP visible.

![EC2 instance in AWS console](screenshots/07-aws-console-ec2.png)

### 8. Security group rules in the AWS console

> 📸 **Capture from:** AWS Console → EC2 → Security Groups → `wordpress_sg` → Inbound rules.
> Show the port 80 and port 22 rules.

![Security group inbound rules](screenshots/08-aws-console-security-group.png)

### 9. The cloud-init log that exposed the failure *(if you still have it)*

> 📸 **Capture from:** EC2 Instance Connect on the broken instance, running
> `tail -n 50 /var/log/cloud-init-output.log`. Show the
> `Failed to restart apache2.service: Unit apache2.service not found` error.
>
> **Optional — you may not have this.** It's from the first, broken deploy. If you didn't grab it
> at the time, don't rebuild a broken instance just for the screenshot; the log output is already
> quoted verbatim in [Issues #3](#3-what-the-log-showed--a-cascade-of-misleading-errors), which
> tells the story fine on its own. Delete this section if you're not adding it.

![cloud-init error log](screenshots/09-cloudinit-error-log.png)

### 10. `terraform destroy` — clean teardown *(optional but nice)*

> 📸 **Capture from:** your terminal, after `terraform destroy`. Show
> "Destroy complete! Resources: 2 destroyed." — demonstrates the full lifecycle.

![terraform destroy output](screenshots/10-terraform-destroy.png)

---

## What I learnt

**Terraform builds its own dependency graph.** I expected to have to sequence resource creation
manually. I didn't — referencing `aws_security_group.wordpress_sg.name` inside the instance block
is what tells Terraform the SG must exist first. The graph comes from the references, not from
the order the blocks appear in the file.

**Data sources decouple code from a region.** Hardcoding an AMI ID would have locked this to one
region and broken on the next Canonical release. `data "aws_ami"` with a name filter solves both
at once, and it resolves at plan time so you see the real ID before you apply.

**"Instance running" ≠ "application ready".** Terraform's job ends when the EC2 API says the
instance is up. `user_data` is still running for minutes afterwards. This gap is invisible to
Terraform and it's why the site 404s right after apply. Understanding it stopped me from
debugging a problem that didn't exist.

**`user_data` only runs once.** It executes on first boot, not on every start. Editing `setup.sh`
and re-applying forces a full instance *replacement* — Terraform destroys and recreates rather
than re-running the script. Every bootstrap fix meant a fresh instance.

**Read logs top-down, not bottom-up.** My first instinct was to look at the last error. That was
the *most downstream* one and it sent me looking in completely the wrong place. Six failures
traced back to a single `Could not get lock` line buried near the top. The last error is usually
a symptom; the first one is usually the cause.

**Cloud boot is a race, not a sequence.** I'd assumed my script was the only thing running on a
fresh instance. It isn't — `unattended-upgrades` is already competing for the package manager.
Bootstrap scripts have to *wait for* the environment rather than assume it's ready and idle.

**Scripts fail forward, and that's dangerous.** Bash doesn't stop when a command fails. `apt`
skipped the entire install, and the script cheerfully carried on for another thirty lines
configuring software that wasn't there. A `set -e` at the top would have failed loudly at the
real error instead of generating a cascade of noise.

**You can debug an instance you have no SSH key for.** EC2 Instance Connect gave me a root
terminal in the browser with no key pair configured and no port I had to keep open for it. Not
hardcoding an SSH key turned out to cost me nothing.

**Immutable infrastructure clicked here.** The pull to just SSH in and `apt install` by hand was
strong — it would have worked in about a minute. But that fix would have existed only on that one
box and disappeared on the next rebuild. Fixing the *script* and running `taint` + `apply` meant
the fix lived in git, and the next instance would be correct for the same reason this one was.
That's the difference between a server that works and infrastructure you can actually reproduce.

**`file()` beats inline heredocs.** Keeping the bootstrap in `setup.sh` rather than a `<<-EOF`
block inside `main.tf` means real shell syntax highlighting, a lintable script, and a `main.tf`
that stays readable.

---

## Issues I hit and how I fixed them

The first deployment failed completely. Terraform reported success, the instance was `running`,
and the site was dead. This is the full debugging story.

### 1. The symptom: apply succeeded, WordPress didn't exist

`terraform apply` finished cleanly. The EC2 instance was healthy in the console. Browsing to the
public IP gave nothing. Terraform had done its job perfectly — the failure was entirely inside
`user_data`, which Terraform has no visibility into and never reports on.

### 2. Getting into the black box — without an SSH key

`user_data` runs unattended during boot. No terminal, no output, no error — just a broken box.
The logs are the only source of truth.

I deliberately hadn't put an SSH key pair in the Terraform config, so I used **EC2 Instance
Connect** instead — AWS's browser-based terminal:

> AWS Console → EC2 → select the instance → **Connect** → **EC2 Instance Connect**

Then read the log where Linux dumps everything `user_data` printed:

```bash
tail -n 50 /var/log/cloud-init-output.log   # my script's full stdout/stderr
grep -i error /var/log/cloud-init-output.log  # filter to just the failures
```

This turned an invisible failure into a readable stack of errors in about thirty seconds.

### 3. What the log showed — a cascade of misleading errors

The bottom of the log was full of failures:

```
cp: cannot stat '/tmp/wordpress/.': No such file or directory
chown: cannot access '/var/www/html/': No such file or directory
rm: cannot remove '/var/www/html/index.html': No such file or directory
cp: cannot stat '/var/www/html/wp-config-sample.php': No such file or directory
sed: can't read /var/www/html/wp-config.php: No such file or directory
Failed to restart apache2.service: Unit apache2.service not found.
```

`Unit apache2.service not found` was the tell. **Apache was never installed at all.** Every other
error was downstream of that single fact — no Apache meant no `/var/www/html`, which meant the
copy failed, which meant there was no `wp-config.php` for `sed` to edit. MySQL hadn't installed
either, so the database commands had failed silently much earlier.

Six errors, one root cause.

### 4. The root cause: an apt lock race condition

The real error was buried much higher up the log:

```
E: Could not get lock /var/lib/dpkg/lock-frontend
```

When a fresh Ubuntu instance boots, `unattended-upgrades` starts automatically and immediately
grabs the dpkg lock to apply security patches. My `setup.sh` ran at the *exact same moment*,
tried to `apt install apache2 mysql-server php...`, found the package manager already locked,
and **skipped the entire installation** — then carried on running every subsequent command
against a machine that had none of the software it needed.

**Fix — wait for the lock to clear before installing anything:**

```bash
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for apt lock..."
    sleep 5
done
```

**And prevent a second, related hang** — package installs on Ubuntu 20.04/22.04 can pop
interactive dialogs asking you to confirm daemon restarts. There's no TTY attached to a
`user_data` run, so the script would hang forever waiting on an answer nobody can give:

```bash
export DEBIAN_FRONTEND=noninteractive
```

### 5. A second bug hiding behind the first: extracting to the wrong directory

The log showed `tar` successfully unpacking every WordPress file — and *then*
`cp: cannot stat '/tmp/wordpress/.': No such file or directory`. Extraction worked, but the files
weren't where the next line expected them.

**Cause:** `curl -O` and `tar` both operate on the current working directory, and `user_data`
doesn't run from `/tmp` — cloud-init executes scripts from its own directory. So WordPress
unpacked somewhere else entirely, while the `cp` looked in `/tmp`.

**Fix — `cd` explicitly instead of assuming the working directory:**

```bash
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
```

I also added `sudo mkdir -p /var/www/html` before the copy, so the script no longer depends on
Apache having created that directory first.

> Worth noting: this bug was **masked** by the apt failure. Because Apache was missing, the copy
> would have failed regardless — so fixing only the lock race would have surfaced this one next.

### 6. Fixing it the right way — replace the box, don't patch it

The temptation was to just SSH in and run the install commands by hand. That would have produced
a working server and **defeated the entire point of Infrastructure as Code** — the fix would live
only on that one box, and vanish the next time the instance was rebuilt.

Instead I fixed `setup.sh` locally and forced Terraform to rebuild from scratch:

```bash
terraform taint aws_instance.wordpress_server   # mark the instance as corrupted
terraform apply                                 # destroy it, rebuild, re-run the new script
```

`taint` tells Terraform the resource is broken so it destroys and recreates it on the next apply,
guaranteeing the updated script runs on a genuinely clean slate.

> **Note for current Terraform:** `taint` is deprecated in favour of
> `terraform apply -replace="aws_instance.wordpress_server"`, which does the same thing in one
> command and shows you the plan before committing.

Waited 3–4 minutes after apply, hit the URL, and WordPress loaded.

---

## Known gaps / what I'd do next

Honest list of what this build doesn't do yet. Every one of these is deliberate scope, not an
oversight I'm unaware of.

1. **🔴 The database password is hardcoded in `setup.sh` — and committed to a public repo.**
   `REDACTED` sits in plaintext in the script and in git history. It only protects a
   `localhost`-bound MySQL user on a throwaway box, so the blast radius is small — but the habit
   is the problem. Real fix: a `sensitive` Terraform variable injected via `templatefile()`, or
   generate it on the instance with `openssl rand`. Better still, AWS Secrets Manager.

2. **🟠 The security group description promises HTTPS but there's no port 443 rule.** The
   description reads "Allow HTTP, HTTPS and SSH" — only 80 and 22 are actually open. Either add
   the 443 ingress with a real certificate (Let's Encrypt / ACM) or correct the description. Right
   now the site is HTTP-only, which means the WordPress admin login is sent in cleartext.

3. **🟠 SSH is open to `0.0.0.0/0`.** Already flagged in my own code comment. Should be locked to
   my own IP via a `variable "my_ip"` — or removed entirely in favour of SSM Session Manager,
   which needs no open port at all.

4. **🟡 Port 22 is open but no `key_name` is attached.** Leaving the SSH key out was deliberate —
   it keeps a private key off my machine and out of the repo, and EC2 Instance Connect covered
   debugging without one (see Issues #2). But that makes the port 22 ingress rule **dead weight**:
   nothing can use it, and it widens the attack surface for no benefit. The rule should be dropped
   entirely, since Instance Connect in this region works through the console rather than my SG.

5. **`security_groups` (by name) instead of `vpc_security_group_ids`.** The name-based argument
   is the older EC2-Classic style; it works here only because it lands in the account's **default
   VPC**. This code will fail in an account without one. The modern form is
   `vpc_security_group_ids = [aws_security_group.wordpress_sg.id]`, and a production build would
   define its own VPC and subnets rather than borrowing the default.

6. **WordPress salts are left at their defaults.** The `sed` commands replace the DB name, user
   and password — but not the `AUTH_KEY` / `SECURE_AUTH_KEY` / etc. placeholders, which still read
   "put your unique phrase here". They should be pulled from
   `https://api.wordpress.org/secret-key/1.1/salt/` during bootstrap.

7. **The public IP is ephemeral.** Stop and start the instance and the address changes. An
   `aws_eip` would pin it.

8. **No state backend.** State is a local `terraform.tfstate` file — fine solo, useless for a
   team and one laptop failure away from an orphaned instance. S3 + DynamoDB locking is the
   standard answer.

9. **Single instance, no persistence.** Everything — web server, database, uploads — lives on one
   box with no backups. Terminate it and the site is gone. The real architecture separates the DB
   (RDS) and puts the instance behind a load balancer in an ASG.
