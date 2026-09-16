# Minecraft Java Server on Huawei Cloud

Terraform architecture for a publicly reachable Minecraft Java server on
Huawei Cloud (`la-south-2` by default). Design rationale lives in
`docs/superpowers/specs/2026-09-14-huawei-minecraft-server-design.md`.

## Architecture

- **Network**: one VPC/subnet, one security group (Minecraft port open to
  the internet, SSH restricted to `admin_cidr`).
- **Compute**: an Auto Scaling group pinned to exactly 1 instance, so a
  failed instance is automatically replaced (ECS health check, no load
  balancer). The instance re-associates a fixed EIP with itself at boot.
- **Storage**: SFS Turbo (NFS) holds all world data, so any replacement
  instance can mount the same share with no manual reattachment.
- **Backup**: CBR backs up the SFS Turbo share daily, retaining 7 dailies
  and 4 weeklies by default.
- **Monitoring**: Cloud Eye alarms (CPU high, instance count < 1) notify an
  email address via SMN.
- **State**: Terraform state lives in a versioned OBS bucket via the
  S3-compatible backend. OBS's S3-compatible API has no native state
  locking — acceptable for a single operator, not for a team without an
  additional locking layer.

## Prerequisites

1. A Huawei Cloud account with API access keys (`HW_ACCESS_KEY`,
   `HW_SECRET_KEY` environment variables — the provider reads these; do not
   put credentials in `.tf` files).
2. A local SSH keypair (e.g. `ssh-keygen -t ed25519 -f ~/.ssh/mc-minecraft -N ""`).
   Terraform imports the public key into Huawei Cloud KPS itself — no
   console step needed. Point `ssh_public_key_path` at it if it's not at
   the default `~/.ssh/mc-minecraft.pub`.
3. Terraform >= 1.6.3.

## Deploying

1. Bootstrap the state bucket:
   ```
   cd bootstrap
   terraform init
   terraform apply -var="bucket_name=<your-globally-unique-name>"
   ```
2. Copy the `state_bucket_name` output into the `bucket` field of
   `backend.tf` at the repo root.
3. Back at the repo root:
   ```
   cp terraform.tfvars.example terraform.tfvars
   # edit terraform.tfvars: admin_cidr, alarm_email (ssh_public_key_path if not default)
   terraform init
   terraform plan
   terraform apply
   ```
4. Connect a Minecraft Java client to `<minecraft_server_address>:<minecraft_server_port>`
   (from the `terraform output`).

## Validating after apply

- Confirm the instance booted correctly: SSH in (`terraform output
  ssh_command`) and check `journalctl -u minecraft.service` and
  `/var/log/minecraft-bootstrap.log`.
- Confirm the EIP self-association worked: `terraform output
  minecraft_server_address` should match what a Minecraft client can
  actually reach. If the bootstrap log shows a `WARNING` from the EIP
  association step, verify the KooCLI command syntax by hand
  (`hcloud EIP AssociatePublicips --cli-mode=ecsAgency --help` on the
  instance) — this is the one piece of the bootstrap script that depends
  on an unversioned third-party CLI's exact flag names.
- Confirm CBR is producing backups: check the vault in the console after
  the first scheduled run (02:00 UTC by default).
- Confirm CES alarms fire: temporarily stress the CPU (e.g. `stress-ng`)
  and confirm the SMN email arrives within the 5-minute evaluation window.

## Out of scope (see spec for rationale)

DNS/domain name, KMS volume encryption, CTS audit logging, scheduled
auto start/stop for cost optimization, multi-AZ/multi-region resilience,
an SFS Turbo capacity/latency CES alarm (add via console once the file
system exists — see `modules/monitoring/main.tf`).
