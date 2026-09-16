# Minecraft Java Server on Huawei Cloud

Terraform for a publicly reachable Minecraft Java server on Huawei Cloud
(`la-south-2` by default), built to self-heal and back itself up.

## Architecture

- **Network**: VPC/subnet + security group (game port open to the internet, SSH restricted to `admin_cidr`).
- **Compute**: Auto Scaling group pinned to 1 instance — a failed instance is auto-replaced, no load balancer needed. Re-associates a fixed EIP with itself at boot.
- **Storage**: SFS Turbo (NFS) holds the world data, so a replacement instance mounts the same share automatically.
- **Backup**: CBR backs up the SFS Turbo share daily (7 dailies + 4 weeklies retained).
- **Monitoring**: Cloud Eye alarms (high CPU, instance count < 1) notify by email via SMN.
- **State**: Terraform state in a versioned OBS bucket (S3-compatible backend).

## Prerequisites

- Huawei Cloud API keys as `HW_ACCESS_KEY` / `HW_SECRET_KEY` env vars.
- SSH keypair: `ssh-keygen -t ed25519 -f ~/.ssh/mc-minecraft -N ""`.
- Terraform >= 1.6.3.

## Deploying

```bash
# 1. Bootstrap the state bucket
cd bootstrap && terraform init
terraform apply -var="bucket_name=<your-globally-unique-name>"
# copy the state_bucket_name output into backend.tf's `bucket` field

# 2. Deploy the server
cd ..
cp terraform.tfvars.example terraform.tfvars   # edit admin_cidr, alarm_email
terraform init
terraform apply
```

Connect with a Minecraft Java client to `<minecraft_server_address>:<minecraft_server_port>` (see `terraform output`).
