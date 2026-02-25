# STAR ELZ V1 — Sprint 2: Hub Networking

## Sprint Overview

| Field | Value |
|-------|-------|
| **Sprint** | Sprint 2 of 4 |
| **Dates** | 3 Mar – 5 Mar 2026 |
| **Goal** | Build the Hub VCN, all subnets, DRG, Service Gateway, route tables, security lists, and provision the dummy firewall compute instance. Prove east-west routing is functional before spoke VCNs are attached in Sprint 3. |
| **Outcome** | A fully wired Hub VCN in `C1_R_ELZ_NW` with DRG attached, Service Gateway operational, and a dummy Linux VM acting as a simulated firewall with IP forwarding enabled. Zero spoke connectivity — that is Sprint 3 scope. |
| **ORM Zip** | `STAR_ELZ_Sprint2_Networking.zip` (this directory zipped) |
| **Prerequisite** | Sprint 1 complete — all compartments, groups, and policies deployed and validated |

---

## Sprint 2 Task Schedule

| Task | Description | Owner | Start | End | Days |
|------|-------------|-------|-------|-----|------|
| 1 | VCN, subnets, Service Gateway | DSTA | 3 Mar | 3 Mar | 1 |
| 2 | DRG + VCN attachment | DSTA | 3 Mar | 3 Mar | 1 |
| 3 | Route tables + security lists | DSTA | 3 Mar | 4 Mar | 2 |
| 4 | Deploy to OCI via Resource Manager | Oracle | 4 Mar | 4 Mar | 1 |
| 5 | Provision sim firewall compute (OCI Console) | DSTA T4 | 5 Mar | 5 Mar | 1 |
| 6 | Configure IP forwarding on sim firewall | Oracle | 5 Mar | 5 Mar | 1 |

---

## Files in This Sprint

| File | Team | Purpose |
|------|------|---------|
| `providers.tf` | All | OCI provider — same pattern as Sprint 1 |
| `data_sources.tf` | All | Tenancy, region, services lookups |
| `variables_general.tf` | All | `tenancy_ocid`, `region`, `service_label` |
| `variables_net_hub.tf` | Team 1 | Hub VCN CIDRs, compartment OCIDs, DRG name, sim FW shape |
| `locals.tf` | All | Region key, service gateway label, landing zone tags |
| `net_vcn_team1.tf` | **Team 1** | Hub VCN + Service Gateway |
| `net_subnets_team2.tf` | **Team 2** | Hub subnets — firewall + management |
| `net_drg_team3.tf` | **Team 3** | DRG + VCN attachment |
| `net_routing_team4.tf` | **Team 4** | Route tables, security lists, sim FW compute stub |
| `outputs.tf` | All | Exported OCIDs for Sprint 3 consumption |
| `terraform.tfvars.template` | All | Input template — copy to `terraform.tfvars` |

---

## Architecture — What Gets Built

```
Tenancy Root
└── AMIT_AD_LZ_Dev (Sprint 1)
    └── C1_R_ELZ_NW
        └── Hub VCN (10.0.0.0/16)
            ├── Service Gateway → Oracle Services Network
            ├── DRG (C1-R-ELZ-DRG)
            │   └── VCN Attachment
            ├── Subnet: hub_fw   (10.0.0.0/24) — Sim Firewall
            │   ├── Route Table → DRG (default), SG (Oracle services)
            │   └── Security List — internal VCN traffic
            └── Subnet: hub_mgmt (10.0.1.0/24) — Management/Bastion
                ├── Route Table → SG (Oracle services)
                └── Security List — internal VCN traffic
```

**Sim Firewall (Task 5 & 6):**
```
C1_R_ELZ_NW
└── sim-fw-instance (VM.Standard.E4.Flex, 1 OCPU, 8GB)
    ├── NIC: hub_fw subnet — 10.0.0.x
    └── IP forwarding: enabled (sysctl net.ipv4.ip_forward=1)
```

> **Note:** The sim firewall is a placeholder for Sprint V1. It provides basic IP forwarding to simulate east-west traffic inspection. A real NGFW (Palo Alto, Fortinet) replaces it in V2.

---

## Prerequisites

Before starting Sprint 2:

1. **Sprint 1 complete** — all validation tests TC-01 to TC-06 passed
2. **Sprint 1 outputs captured:**
   ```bash
   # In Sprint 1 ORM stack → Outputs tab, copy:
   # - enclosing_compartment_id → not needed directly but good reference
   # - Use OCI Console → Identity → Compartments to get:
   #   C1_R_ELZ_NW OCID → paste as nw_compartment_id in terraform.tfvars
   #   C1_R_ELZ_SEC OCID → paste as sec_compartment_id in terraform.tfvars
   ```
3. **ORM Dynamic Group** `ORM-Sprint2-DynGroup` created (or reuse Sprint 1 group)
4. **IP Plan confirmed** — CIDR `10.0.0.0/16` for Hub VCN agreed with DSTA network team

---

## How to Deploy via OCI Resource Manager (ORM) — Recommended

### Step 1 — Complete the code (teams work in parallel)

Each team implements their stub file. See the TODO comments in each file.

```bash
# Validate your file before raising PR
terraform fmt net_vcn_team1.tf
terraform validate
```

### Step 2 — Prepare the zip

```bash
# From inside the sprint2/ directory:
zip STAR_ELZ_Sprint2_Networking.zip *.tf terraform.tfvars.template
```

### Step 3 — Create ORM Stack

1. OCI Console → **Developer Services → Resource Manager → Stacks**
2. **Create Stack** → upload `STAR_ELZ_Sprint2_Networking.zip`
3. Set region: `ap-singapore-2`

### Step 4 — Fill in Variables

| Variable | Value | Source |
|----------|-------|--------|
| `tenancy_ocid` | Your tenancy OCID | OCI Console → Profile |
| `region` | `ap-singapore-2` | Fixed |
| `service_label` | `c1` | Sprint 1 value |
| `nw_compartment_id` | OCID of C1_R_ELZ_NW | Sprint 1 outputs |
| `sec_compartment_id` | OCID of C1_R_ELZ_SEC | Sprint 1 outputs |
| `hub_vcn_cidr` | `10.0.0.0/16` | IP Plan |

### Step 5 — Plan

Expected plan output:
```
Plan: 8 to add, 0 to change, 0 to destroy.
  + oci_core_vcn.hub
  + oci_core_service_gateway.hub_sg
  + oci_core_subnet.hub_fw
  + oci_core_subnet.hub_mgmt
  + oci_core_drg.hub
  + oci_core_drg_attachment.hub_vcn
  + oci_core_route_table.hub_fw
  + oci_core_route_table.hub_mgmt
  (+ security lists and route table associations)
```

### Step 6 — Apply (Task 4 — Oracle-led)

Oracle TAD runs the apply and confirms all resources created cleanly.

### Step 7 — Task 5: Sim Firewall via Console (DSTA T4)

After Terraform apply completes:
1. OCI Console → **Compute → Instances → Create Instance**
2. Compartment: `C1_R_ELZ_NW`
3. Shape: `VM.Standard.E4.Flex` — 1 OCPU, 8GB RAM
4. Image: Oracle Linux 8 (latest)
5. Network: Hub VCN → `hub_fw` subnet
6. **Do NOT assign a public IP**
7. Add SSH key (Oracle provides the key pair for Task 6)

### Step 8 — Task 6: IP Forwarding (Oracle-led)

Oracle SSH into the sim FW instance and runs:
```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Verify
cat /proc/sys/net/ipv4/ip_forward
# Expected: 1
```

---

## Sprint 2 Validation — Pass/Fail Criteria

Run all tests before handing off to Sprint 3.

### TC-07 — ★ Hub VCN created with correct CIDR

```bash
oci network vcn list \
  --compartment-id <nw_compartment_id> \
  --query "data[].{name:\"display-name\",cidr:\"cidr-block\",state:\"lifecycle-state\"}" \
  --output table

# Expected: 1 VCN, cidr-block = 10.0.0.0/16, state = AVAILABLE
```

### TC-08 — ★ DRG created and attached to Hub VCN

```bash
oci network drg list \
  --compartment-id <nw_compartment_id> \
  --query "data[].{name:\"display-name\",state:\"lifecycle-state\"}" \
  --output table

oci network drg-attachment list \
  --compartment-id <nw_compartment_id> \
  --query "data[].{drg:\"drg-id\",vcn:\"network-details\",state:\"lifecycle-state\"}" \
  --output table

# Expected: 1 DRG (AVAILABLE), 1 attachment (ATTACHED) to Hub VCN
```

### TC-09 — ★ Service Gateway operational

```bash
oci network service-gateway list \
  --compartment-id <nw_compartment_id> \
  --vcn-id <hub_vcn_id> \
  --query "data[].{name:\"display-name\",state:\"lifecycle-state\",blocked:\"block-traffic\"}" \
  --output table

# Expected: state = AVAILABLE, block-traffic = false
```

### TC-10 — ★ Both subnets created, private (no public IPs)

```bash
oci network subnet list \
  --compartment-id <nw_compartment_id> \
  --vcn-id <hub_vcn_id> \
  --query "data[].{name:\"display-name\",cidr:\"cidr-block\",publicIp:\"prohibit-public-ip-on-vnic\"}" \
  --output table

# Expected: 2 subnets, both prohibit-public-ip-on-vnic = true
```

### TC-11 — ★ Sim firewall IP forwarding enabled

```bash
# SSH to sim FW instance (Oracle-provided key) or via Bastion
ssh -i <key> opc@<sim_fw_private_ip>
cat /proc/sys/net/ipv4/ip_forward

# Expected: 1
```

### TC-12 — ★ Terraform plan shows zero drift after apply

```bash
terraform plan -detailed-exitcode
# Expected: exit code 0, "No changes."
```

---

## Team Structure for Sprint 2 — 16 People, 4 Teams of 4

| Team | Name | Members | Primary Domain |
|------|------|---------|----------------|
| Team 1 | VCN & Gateway | 4 people | `net_vcn_team1.tf` — Hub VCN, Service Gateway |
| Team 2 | Subnets | 4 people | `net_subnets_team2.tf` — firewall + mgmt subnets |
| Team 3 | DRG | 4 people | `net_drg_team3.tf` — DRG, VCN attachment |
| Team 4 | Routing & Sim FW | 4 people | `net_routing_team4.tf` — route tables, security lists, sim firewall |

### Branch Strategy

```
main (protected)
├── sprint2/net-vcn-team1       (Team 1 — VCN + SG)
├── sprint2/net-subnets-team2   (Team 2 — Subnets)
├── sprint2/net-drg-team3       (Team 3 — DRG)
└── sprint2/net-routing-team4   (Team 4 — Routing + Sim FW)
```

### Dependencies Between Teams

```
Team 1 (VCN) ──► Team 2 (Subnets need vcn_id)
Team 1 (VCN) ──► Team 3 (DRG attachment needs vcn_id)
Team 3 (DRG) ──► Team 4 (Route table needs drg_id)
Team 2 (Subnets) ──► Team 4 (Sim FW needs subnet_id)
```

Work order: Team 1 merges first → Teams 2 & 3 in parallel → Team 4 last.

---

## Sprint 2 → Sprint 3 Handoff Checklist

- [ ] TC-07: Hub VCN created and verified
- [ ] TC-08: DRG attached to Hub VCN
- [ ] TC-09: Service Gateway operational
- [ ] TC-10: Both subnets private, correct CIDRs
- [ ] TC-11: Sim firewall IP forwarding = 1
- [ ] TC-12: `terraform plan` zero drift
- [ ] `sprint2_outputs.json` captured and shared with Sprint 3 team
- [ ] State Book `V1_Networking` sheet updated
- [ ] Git tag `v1-sprint2-complete` applied to main

---

## Common Issues and Fixes

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| `nw_compartment_id` not found | Wrong OCID pasted from Sprint 1 | Re-copy from OCI Console → Identity → Compartments → C1_R_ELZ_NW → OCID |
| DRG attachment fails | VCN not yet fully provisioned | Add `depends_on = [oci_core_vcn.hub]` to DRG attachment resource |
| Route table has no effect | Route table not associated with subnet | Add `route_table_id` to subnet resource or use `oci_core_route_table_attachment` |
| Sim FW can't route traffic | IP forwarding not persisted across reboot | Confirm `/etc/sysctl.conf` has `net.ipv4.ip_forward = 1` (not just runtime sysctl) |
| ORM apply fails on compute | Availability domain not specified | Use `data "oci_identity_availability_domains"` to fetch AD name dynamically |

---

*Sprint 2 Complete → proceed to [Sprint 3 README](../sprint3/README.md)*
