# STAR ELZ V1 — Sprint 3: Security, Forced Inspection, Observability

**Branch:** `sprint3` · **Dates:** 9–11 Mar 2026 · **Terraform ≥ 1.3.0** · **OCI Provider ≥ 6.0.0**

> **Coming from Sprint 2?** You need `sprint2_outputs.json` for DRG, VCN, subnet, Bastion, Sim FW, and SGW OCIDs. Paste them into Sprint 3 ORM Variables. Run the Sprint 1 IAM patch FIRST — see `SPRINT1_IAM_PATCH_FOR_S3.md`.

Sprint 3 adds the security enforcement layer on top of Sprint 2's hub-and-spoke network. The main goal: **forced inspection** — all spoke-to-spoke traffic now flows through the Hub Sim FW instead of bypassing it via DRG full-mesh.

Also added: Vault/KMS, Cloud Guard, Security Zones, NSGs, VCN flow logs, Service Connector Hub (log publishing), VSS vulnerability scanning, Certificate Authority, events/alarms, and Bastion SSH sessions for validation.

---
## Network Architecture

<img width="841" height="476" alt="Screenshot 2026-03-07 at 10 21 17 PM" src="https://github.com/user-attachments/assets/8201612e-7ed9-4e76-b971-84ba9db0731e" />

## Network Topology


```
STAR ELZ V1 — Sprint 3 Topology (builds on Sprint 2)

SPRINT 2 INFRASTRUCTURE (referenced via variables, not modified):
  1 Bastion service · 5 Service Gateways · 5 VCNs · 6 subnets
  2 DRGs · 5 DRG attachments · 4 Sim FWs (ssh_authorized_keys in metadata)
  6 Route Tables · 6 Security Lists

SPRINT 3 ADDS (58 resources):

C1_R_ELZ_NW  (Hub — T4 routing, T1/T2 NSGs + flow logs)
├── vcn_r_elz_nw                      10.0.0.0/16
│   ├── sub_r_elz_nw_fw               10.0.0.0/24
│   │   ├── fw_r_elz_nw_hub_sim       Sprint 2 Sim FW — forced inspection point
│   │   ├── nsg_r_elz_nw_fw           NSG (T1)
│   │   ├── fl_r_elz_nw_fw            Flow log (T1)
│   │   └── rt_r_elz_nw_fw            Sprint 2 SGW + Sprint 3 spoke CIDRs → DRG
│   │
│   ├── sub_r_elz_nw_mgmt             10.0.1.0/24
│   │   ├── bas_r_elz_nw_hub          Bastion (Sprint 2) — 1 service, 2 TF sessions
│   │   │   ├── bsn_os_elz_nw_ssh     Session → OS Sim FW (T1)
│   │   │   └── bsn_ts_elz_nw_ssh     Session → TS Sim FW (T2)
│   │   ├── nsg_r_elz_nw_mgmt         NSG (T2)
│   │   └── fl_r_elz_nw_mgmt          Flow log (T2)
│   │
│   ├── rt_r_elz_nw_hub_ingress       VCN Ingress RT (T4) → Hub FW private IP
│   │
│   └── drg_r_hub — FORCED INSPECTION ROUTING (T4):
│       ├── drgrt_r_hub_spoke_mesh     Hub RT (import distribution)
│       ├── drgrt_spoke_to_hub         Spoke RT (static 0/0 → Hub)
│       ├── drga_r_elz_nw_hub ───→ hub_spoke_mesh + VCN ingress RT
│       ├── drga_os_elz_nw ─────→ spoke_to_hub
│       ├── drga_ts_elz_nw ─────→ spoke_to_hub
│       ├── drga_ss_elz_nw ─────→ spoke_to_hub
│       └── drga_devt_elz_nw ───→ spoke_to_hub
│
├── C1_OS_ELZ_NW  (T1)  — nsg_os_elz_nw_app + fl_os_elz_nw_app
├── C1_SS_ELZ_NW  (T2)  — nsg_ss_elz_nw_app + fl_ss_elz_nw_app
├── C1_TS_ELZ_NW  (T2)  — nsg_ts_elz_nw_app + fl_ts_elz_nw_app
└── C1_DEVT_ELZ_NW (T2) — nsg_devt_elz_nw_app + fl_devt_elz_nw_app

C1_R_ELZ_SEC  (T3 security, T1 VSS+SCH, T2 Cert)
├── vlt_r_elz_sec                      Vault (T3)
│   ├── key_r_elz_sec_master          Master Key (T3)
│   └── ssh-public-key                 Vault Secret — SSH key (T3)
├── ca_r_elz_sec                       Certificate Authority (T2)
├── Cloud Guard (T3): config + activity recipes, responder, target
├── Security Zones (T3): sz_r_elz_sec + sz_r_elz_nw
├── lg_r_elz_nw_flow                   Log group (T3) → 6 flow logs (T1/T2)
├── bkt_r_elz_sec_logs                 Log bucket (T3)
├── sch_r_elz_sec_flow_logs            SCH: logs → bucket (T1)
├── vssr_r_elz_sec + vsst_r_elz_nw     VSS recipe + target (T1)
├── nt_r_elz_sec_alerts                Notification topic (T3)
├── ev_r_elz_sec_nw_changes            Events rule (T3)
└── al_r_elz_sec_drg_change            Monitoring alarm (T3)

FORCED INSPECTION (Sprint 3 vs Sprint 2):
  Sprint 2: OS → DRG(full-mesh) → TS              [Hub FW bypassed]
  Sprint 3: OS → DRG(spoke_to_hub) → Hub FW → DRG → TS  [Hub FW inspects]

SSH KEY FLOW:
  Sprint 2: var.ssh_public_key → instance metadata (ssh_authorized_keys)
  Sprint 3: same key → Bastion session (key_details) + Vault secret
  Both paths: Bastion Managed SSH via Cloud Agent. Key on instance = backup.
```


---

## Sprint 2 → Sprint 3 Handover

Sprint 3 is a **separate ORM stack** — it does not modify Sprint 2 state directly.

**What you paste from Sprint 2 outputs (22 OCIDs):**

```bash
terraform output -json > sprint2_outputs.json
# Then paste each value into Sprint 3 ORM Variables
```

| Sprint 2 Output | Sprint 3 Variable | Why Sprint 3 Needs It |
|---|---|---|
| `hub_drg_id` | `hub_drg_id` | DRG route table creation |
| `hub_drg_attachment_id` | `hub_drg_attachment_id` | Assign hub_spoke_mesh RT |
| `os/ts/ss/devt_drg_attachment_id` | `*_drg_attachment_id` | Assign spoke_to_hub RT |
| `hub/os/ts/ss/devt_vcn_id` | `*_vcn_id` | NSG creation |
| `hub_fw/mgmt_subnet_id` + spokes | `*_subnet_id` | Flow logs + ingress RT |
| `bastion_id` | `bastion_id` | Bastion sessions |
| `os/ts_fw_instance_id` | `*_fw_instance_id` | Bastion session targets |
| `hub_fw_rt_id` | `hub_fw_rt_id` | Import Hub FW RT into Sprint 3 |
| ⚠️ `hub_fw_private_ip_id` | `hub_fw_private_ip_id` | **See note below** |

**Private IP OCID — extra step required:**

Sprint 2 outputs `hub_fw_private_ip_address` (e.g. `10.0.0.69`). Sprint 3 needs the private IP **OCID** (`ocid1.privateip...`). After Sprint 2 Phase 2 apply, run:

```bash
oci network private-ip list \
  --subnet-id $(terraform output -raw hub_fw_subnet_id) \
  --ip-address $(terraform output -raw hub_fw_private_ip_address) \
  --query 'data[0].id' --raw-output
```

Paste the `ocid1.privateip...` into Sprint 3 ORM Variable `hub_fw_private_ip_id`. Wrong value = all spoke-to-spoke traffic black-holes silently.

**No hardcoding.** Every Sprint 2 reference is a Terraform variable. Paste OCIDs in ORM once (plus the private IP OCID from the CLI step above).

**DRG handover:** Sprint 2 creates the DRG with auto-generated (default) DRG route tables. Sprint 3 creates custom DRG route tables and reassigns them to attachments using `oci_core_drg_attachment_management`. No state conflict — `drg_attachment_management` modifies DRG-side properties only.

**SGW handover:** Sprint 2 has NO Service Gateways. Sprint 3 creates the Hub-only SGW in `sec_team4.tf`. Spokes access Oracle services via DRG → Hub FW → SGW (centralised, inspectable).

**Cloud-init (Sim FW):** Sprint 2 created Sim FWs with `ip_forward=1` + firewalld masquerade + `skip_source_dest_check=true`. Sprint 3's forced inspection routing relies on this — no cloud-init changes needed.

---
## Sprint 3 Issue List

| Task ID | Description | Team | File |
|---|---|---|---|
| S3-T4-01 | Custom DRG Route Table — Hub (import distribution) | T4 | `sec_team4.tf` |
| S3-T4-02 | Custom DRG Route Table — Spoke (static 0/0 → Hub) | T4 | `sec_team4.tf` |
| S3-T4-03 | DRG Import Route Distribution + statement | T4 | `sec_team4.tf` |
| S3-T4-04 | VCN Ingress Route Table on Hub DRG attachment | T4 | `sec_team4.tf` |
| S3-T4-05 | Hub FW RT update — add spoke CIDRs → DRG (import from Sprint 2) | T4 | `sec_team4.tf` |
| S3-T4-06 | Service Gateway — Hub VCN (centralised Oracle service access) | T4 | `sec_team4.tf` |
| S3-T4-07 | DRG attachment management — reassign all 5 to custom RTs | T4 | `sec_team4.tf` |
| S3-T1-01 | Bastion session — OS Sim FW (PORT_FORWARDING) | T1 | `sec_team1.tf` |
| S3-T1-02 | NSG — Hub FW subnet | T1 | `sec_team1.tf` |
| S3-T1-03 | NSG — OS spoke subnet | T1 | `sec_team1.tf` |
| S3-T1-04 | Flow logs — Hub FW + OS subnets | T1 | `sec_team1.tf` |
| S3-T1-05 | VSS host scan recipe + target | T1 | `sec_team1.tf` |
| S3-T1-06 | Service Connector Hub — flow logs → bucket | T1 | `sec_team1.tf` |
| S3-T2-01 | Bastion session — TS Sim FW (PORT_FORWARDING) | T2 | `sec_team2.tf` |
| S3-T2-02 | NSGs — Hub MGMT + TS + SS + DEVT subnets | T2 | `sec_team2.tf` |
| S3-T2-03 | Flow logs — Hub MGMT + TS + SS + DEVT subnets | T2 | `sec_team2.tf` |
| S3-T2-04 | Certificate Authority (V2 readiness) | T2 | `sec_team2.tf` |
| S3-T3-01 | Log group for flow logs | T3 | `sec_team3.tf` |
| S3-T3-02 | Object Storage bucket — log retention | T3 | `sec_team3.tf` |

## Region

The region is set via `var.region` in ORM Variables. Both sprints use the same pattern.

**To change region** (e.g. `ap-singapore-2` → `ap-singapore-1`):
- Change `var.region` in Sprint 2 ORM Variables and Sprint 3 ORM Variables
- Home region is auto-detected from the tenancy via `data.oci_identity_tenancy` — no manual change needed
- `providers.tf` in both sprints uses `local.regions_map[local.home_region_key]` for the home provider

No code changes required. Just update the ORM variable.

---

## Pre-Apply Steps (do these FIRST on 9 Mar)

1. **Sprint 2 rerun (AM)** — Apply Sprint 2 ORM. Verify TC-07 to TC-19. Export `sprint2_outputs.json`.
2. **Get Hub FW private IP OCID** — Run the CLI command above. Note the `ocid1.privateip...` value.
3. **Run Sprint 1 IAM patch** — see `SPRINT1_IAM_PATCH_FOR_S3.md`. Code 9 statements into `sprint1/iam_policies_team1.tf`, re-run Sprint 1 ORM Apply. Zero destroys.
4. **Verify Cloud Guard is ENABLED** — Console → Security → Cloud Guard.
5. **Paste Sprint 2 OCIDs + private IP OCID** into Sprint 3 ORM Variables.
6. **Paste SSH public key** into Sprint 3 ORM Variable `ssh_public_key`.
7. **Sprint 3 apply (PM)** — Apply Sprint 3 ORM. Verify TC-20 to TC-42.

---

## Team Assignments

| Team | File(s) | Resources | Count |
|---|---|---|---|
| T1 | `sec_team1.tf` | Bastion (OS), Hub FW + OS NSGs, flow logs (hub_fw + OS), VSS recipe + target, SCH | 12 |
| T2 | `sec_team2.tf` | Bastion (TS), Hub MGMT + TS + SS + DEVT NSGs, flow logs (4), Certificate Authority | 18 |
| T3 | `sec_team3.tf` + `sec_team3_security.tf` | Log group, bucket, notifications, events, alarm, Vault/KMS, Vault SSH secret, Cloud Guard, Security Zones | 16 |
| T4 | `sec_team4.tf` | DRG route tables, import distribution, forced inspection, VCN ingress RT, Hub FW RT, SGW, DRG attachment management | 13 |
| **Total** | | | **59** |

---

## Sprint 3 Issue List

### Forced Inspection Routing (T4)

| # | Task | Team | File |
|---|---|---|---|
| S3-T4-01 | Custom DRG Route Table — Hub (import distribution) | T4 | `sec_team4.tf` |
| S3-T4-02 | Custom DRG Route Table — Spoke (static 0/0 → Hub) | T4 | `sec_team4.tf` |
| S3-T4-03 | DRG Import Route Distribution + statement | T4 | `sec_team4.tf` |
| S3-T4-04 | VCN Ingress Route Table on Hub DRG attachment | T4 | `sec_team4.tf` |
| S3-T4-05 | Hub FW RT update — add spoke CIDRs → DRG (import from Sprint 2) | T4 | `sec_team4.tf` |
| S3-T4-06 | Service Gateway — Hub VCN (centralised Oracle service access) | T4 | `sec_team4.tf` |
| S3-T4-07 | DRG attachment management — reassign all 5 to custom RTs | T4 | `sec_team4.tf` |

### Bastion Sessions + NSGs + Observability (T1)

| # | Task | Team | File |
|---|---|---|---|
| S3-T1-01 | Bastion session — OS Sim FW (PORT_FORWARDING) | T1 | `sec_team1.tf` |
| S3-T1-02 | NSG — Hub FW subnet | T1 | `sec_team1.tf` |
| S3-T1-03 | NSG — OS spoke subnet | T1 | `sec_team1.tf` |
| S3-T1-04 | Flow logs — Hub FW + OS subnets | T1 | `sec_team1.tf` |
| S3-T1-05 | VSS host scan recipe + target | T1 | `sec_team1.tf` |
| S3-T1-06 | Service Connector Hub — flow logs → bucket | T1 | `sec_team1.tf` |

### Bastion Sessions + NSGs + Observability + Cert (T2)

| # | Task | Team | File |
|---|---|---|---|
| S3-T2-01 | Bastion session — TS Sim FW (PORT_FORWARDING) | T2 | `sec_team2.tf` |
| S3-T2-02 | NSGs — Hub MGMT + TS + SS + DEVT subnets | T2 | `sec_team2.tf` |
| S3-T2-03 | Flow logs — Hub MGMT + TS + SS + DEVT subnets | T2 | `sec_team2.tf` |
| S3-T2-04 | Certificate Authority (V2 readiness) | T2 | `sec_team2.tf` |

### Security Services (T3)

| # | Task | Team | File |
|---|---|---|---|
| S3-T3-01 | Log group for flow logs | T3 | `sec_team3.tf` |
| S3-T3-02 | Object Storage bucket — log retention | T3 | `sec_team3.tf` |
| S3-T3-03 | Notification topic + events rule + alarm | T3 | `sec_team3.tf` |
| S3-T3-04 | Vault (Virtual Private) + AES-256 Master Key | T3 | `sec_team3_security.tf` |
| S3-T3-05 | SSH public key — Vault secret | T3 | `sec_team3_security.tf` |
| S3-T3-06 | Cloud Guard — detector recipes + responder + target | T3 | `sec_team3_security.tf` |
| S3-T3-07 | Security Zones — SEC + NW compartments | T3 | `sec_team3_security.tf` |

### Pre-Apply (before ORM Apply)

| # | Task | Owner |
|---|---|---|
| S3-PRE-01 | Run Sprint 1 IAM patch (9 new policy statements) | Architect |
| S3-PRE-02 | Verify Cloud Guard is ENABLED | Architect |
| S3-PRE-03 | Paste 22 Sprint 2 OCIDs into ORM Variables | Architect |
| S3-PRE-04 | Paste SSH public key into ORM Variable | All teams |

Apply order: T1/T2/T3 first (no inter-team deps), T4 last (forced inspection routing depends on T3 log group for flow logs).

---

## SSH Public Key

The same SSH key is used in three places across Sprint 2 and Sprint 3:

| Where | What | Why |
|---|---|---|
| Sprint 2: instance metadata `ssh_authorized_keys` | Key baked into all 4 Sim FW instances | PORT_FORWARDING connects directly to sshd — key must be on instance |
| Sprint 3: Bastion session `key_details` | Key used when Terraform creates PORT_FORWARDING sessions | Bastion presents key to instance sshd via TCP proxy |
| Sprint 3: Vault secret `ssh-public-key` | Key stored encrypted in `vlt_r_elz_sec` | Audit trail + production pattern (V2: reference via data source) |

**How to provide:** Paste contents of `~/.ssh/id_rsa.pub` into ORM Variable `ssh_public_key` (both Sprint 2 and Sprint 3 stacks). If you don't have a key: `ssh-keygen -t rsa -b 4096`.

**Validation (TC-42):** Verify the key exists in all three locations — instance metadata, Bastion session, and Vault.

---

## Test Cases

### Shell Variables (paste from `sprint2_outputs.json` + Sprint 3 outputs)

```bash
# Sprint 2 outputs (already set from Sprint 2)
HUB_DRG_ID="<paste>"
HUB_VCN_ID="<paste>"
HUB_FW_SUBNET="<paste>"
OS_APP_SUBNET="<paste>"
TS_APP_SUBNET="<paste>"
BASTION_ID="<paste>"
SIM_FW_HUB_ID="<paste>"
SIM_FW_OS_ID="<paste>"
TENANCY_ID=$(oci iam tenancy get --query 'data.id' --raw-output)
```

### Forced Inspection (T4) — The Main Event

**TC-20 — DRG route tables created.** Console → DRGs → `drg_r_hub` → DRG Route Tables.

```bash
oci network drg-route-table list --drg-id $HUB_DRG_ID \
  --query 'data[].{name:"display-name",id:id}' --output table
```

Expected: `drgrt_r_hub_spoke_mesh` + `drgrt_spoke_to_hub` (2 custom RTs).

**TC-21 — Spoke attachments use spoke_to_hub RT.** Console → DRGs → Attachments → click each spoke.

```bash
oci network drg-attachment list --drg-id $HUB_DRG_ID --all \
  --query 'data[].{name:"display-name","drg-rt":"drg-route-table-id"}' --output table
```

Expected: OS/TS/SS/DEVT attachments point to `drgrt_spoke_to_hub`. Hub attachment points to `drgrt_r_hub_spoke_mesh`.

**TC-22 — Forced inspection proof (THE key test).**

Create Bastion session to OS Sim FW, then traceroute to TS:

```bash
# From OS Sim FW (via Bastion SSH)
traceroute -n 10.3.0.x    # TS Sim FW IP
```

**Sprint 2 showed:** OS → DRG → TS (2-3 hops, direct).
**Sprint 3 must show:** OS → DRG → Hub FW (10.0.0.x) → DRG → TS (4-5 hops, via Hub FW).

If the Hub FW IP appears in the traceroute — forced inspection is working.

Also run NPA to compare:

```bash
oci network path-analyzer-test create --protocol 1 \
  --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$OS_APP_SUBNET\"}" \
  --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$TS_APP_SUBNET\"}" \
  --compartment-id $TENANCY_ID
```

Sprint 2 NPA showed: OS subnet → DRG → TS subnet (direct).
Sprint 3 NPA must show: OS subnet → DRG → Hub VCN → Hub FW subnet → DRG → TS subnet.

**TC-23 — VCN Ingress RT.** Console → Hub VCN → Route Tables → `rt_r_elz_nw_hub_ingress`.

Expected: 4 spoke CIDR rules pointing to Hub FW private IP OCID.

**TC-24 — Hub FW RT has spoke return routes.** Console → Hub VCN → Route Tables → `rt_r_elz_nw_fw`.

Expected: 4 spoke CIDR rules → DRG + 1 SGW rule (from Sprint 2).

### NSGs (T1/T2)

**TC-25 — 6 NSGs created.** Console → Networking → each VCN → Network Security Groups.

```bash
oci network nsg list --compartment-id <nw_compartment_id> --all \
  --query 'data[].{name:"display-name",id:id}' --output table
```

Expected: `nsg_r_elz_nw_fw`, `nsg_r_elz_nw_mgmt`, `nsg_os_elz_nw_app`, `nsg_ts_elz_nw_app`, `nsg_ss_elz_nw_app`, `nsg_devt_elz_nw_app`.

### Bastion Sessions (T1/T2)

**TC-26 — Bastion session to OS Sim FW.** Console → Bastion → Sessions → `bsn_os_elz_nw_ssh`. Copy SSH command, connect, ping TS Sim FW.

**TC-27 — Bastion session to TS Sim FW.** Same for `bsn_ts_elz_nw_ssh`.

> Note: Terraform-created sessions expire after 30 min (TTL). Recreate via Console if expired.

### Observability (T1/T2/T3)

**TC-28 — Flow logs active.** Console → Observability → Logging → Log Group `lg_r_elz_nw_flow`. Click any flow log → verify ACTIVE and data appearing within 5 min.

**TC-29 — Log bucket exists.** Console → Storage → Buckets → `bkt_r_elz_sec_logs`. Should have objects if SCH is running.

**TC-30 — Service Connector Hub running.** Console → Observability → Service Connectors → `sch_r_elz_sec_flow_logs`. State: ACTIVE. Check "Last run" shows data transferred.

**TC-31 — Notification topic.** Console → Developer Services → Notifications → `nt_r_elz_sec_alerts`. Add an email subscription to test.

**TC-32 — Events rule.** Console → Observability → Events → `ev_r_elz_sec_nw_changes`. State: ACTIVE. Make a minor DRG change → check event fires.

**TC-33 — Monitoring alarm.** Console → Observability → Alarms → `al_r_elz_sec_drg_change`. State: OK (no drops yet).

### Security Services (T3)

**TC-34 — Vault + Master Key.** Console → Security → Vault → `vlt_r_elz_sec`. Key: `key_r_elz_sec_master` → ENABLED.

```bash
oci kms management key list --compartment-id <sec_compartment_id> \
  --service-endpoint <vault_management_endpoint> \
  --query 'data[].{name:"display-name",state:"lifecycle-state"}' --output table
```

**TC-35 — Cloud Guard target active.** Console → Security → Cloud Guard → Targets → `cgt_r_elz_root`. Status: ACTIVE. Check Problems tab for findings.

**TC-36 — Security Zones enforcing.** Console → Security → Security Zones → `sz_r_elz_sec`. Try creating a public bucket in C1_R_ELZ_SEC:

```bash
# This should FAIL with HTTP 409 — Security Zone blocks public buckets
oci os bucket create --compartment-id <sec_compartment_id> \
  --name "test-public-bucket" --public-access-type ObjectRead
# Expected: 409 Conflict — violates security zone policy
```

**TC-37 — Security Zone on NW.** Same test for `sz_r_elz_nw` — try creating a public subnet:

```bash
oci network subnet create --compartment-id <nw_compartment_id> \
  --vcn-id $HUB_VCN_ID --cidr-block "10.0.99.0/24" \
  --prohibit-public-ip-on-vnic false
# Expected: 409 Conflict — Security Zone blocks public subnets
```

### Vulnerability Scanning (T1)

**TC-38 — VSS recipe created.** Console → Security → Scanning → Host Scan Recipes → `vssr_r_elz_sec`.

**TC-39 — VSS target scanning.** Console → Scanning → Host Scan Targets → `vsst_r_elz_nw`. Check "Scanned instances" — should show the 4 Sim FWs after first scan cycle (Sunday for weekly schedule, or trigger manual scan).

### Certificate Authority (T2)

**TC-40 — CA created.** Console → Security → Certificates → Certificate Authorities → `ca_r_elz_sec`. Status: ACTIVE.

```bash
oci certs-mgmt certificate-authority list --compartment-id <sec_compartment_id> \
  --query 'data.items[].{name:name,state:"lifecycle-state"}' --output table
```

### Final

**TC-41 — Zero drift.** ORM → Plan → `0 to add, 0 to change, 0 to destroy`.

**TC-42 — SSH key in Vault + instance metadata.**

Console → Vault → `vlt_r_elz_sec` → Secrets → `ssh-public-key` → ACTIVE.

```bash
# Vault secret exists
oci vault secret list --compartment-id <sec_compartment_id> \
  --query "data[?\"secret-name\"=='ssh-public-key'].{name:\"secret-name\",state:\"lifecycle-state\"}" --output table

# Instance has the key in metadata (set by Sprint 2)
oci compute instance get --instance-id $SIM_FW_HUB_ID \
  --query 'data.metadata."ssh_authorized_keys"' --raw-output | head -c 50
# Expected: ssh-rsa AAAA...
```

From a Bastion session (TC-26), confirm key is on the instance:

```bash
cat ~/.ssh/authorized_keys | head -c 50
# Expected: same ssh-rsa AAAA... as your public key
```

---

## Design Decisions

| Decision | Detail |
|---|---|
| Forced inspection | Custom DRG RTs replace auto-generated full-mesh. `spoke_to_hub` sends 0/0 → Hub attachment. Hub ingress RT → Hub FW private IP. Hub FW RT → spoke CIDRs back to DRG. |
| `drg_attachment_management` | Modifies DRG-side properties on existing Sprint 2 attachments without importing them into Sprint 3 state. Two ORM stacks, zero state conflicts. |
| Hub FW RT import | Sprint 2 created `rt_r_elz_nw_fw` (SGW rule). Sprint 3 imports via `import{}` and adds spoke CIDR routes. SGW rule preserved. |
| SGW from Sprint 2 | Sprint 3 references Hub SGW via `var.hub_sgw_id`. No duplication. 5 SGWs total (all Sprint 2). |
| Bastion | 1 Bastion service (Sprint 2). 2 Terraform sessions (Sprint 3 T1/T2). Console sessions also work. |
| NSGs | 6 NSGs (one per subnet). Allow all internal 10/8 + egress. V2 tightens to per-service rules. |
| SSH key (3 locations) | Instance metadata `ssh_authorized_keys` (Sprint 2) + Bastion session `key_details` (Sprint 3) + Vault secret (Sprint 3). Same key in all three. Cloud Agent brokers Managed SSH. Key on instance = backup if Cloud Agent fails. |
| VSS | Weekly STANDARD scan. Recipe in SEC. Target scans NW instances. |
| SCH | Flow logs → Object Storage bucket. Retention beyond Logging's 30-day window. |
| Certificate Authority | Root CA in SEC, signed by Vault master key. V2 issues certs for LBs/API GWs. |
| Security Zones | No public buckets, no public subnets, encryption required. SEC + NW compartments. |

---

## Handoff Checklist

- [ ] Sprint 1 IAM patch applied (9 statements)
- [ ] TC-20: 2 custom DRG route tables
- [ ] TC-21: Spoke attachments → spoke_to_hub RT, hub → hub_spoke_mesh RT
- [ ] TC-22: **Forced inspection proven** — traceroute + NPA
- [ ] TC-23: VCN ingress RT → Hub FW private IP
- [ ] TC-24: Hub FW RT has spoke CIDRs + SGW
- [ ] TC-25: 6 NSGs created
- [ ] TC-26/27: Bastion SSH sessions connect
- [ ] TC-28: Flow logs ACTIVE
- [ ] TC-29: Log bucket has objects (SCH delivering)
- [ ] TC-30: SCH ACTIVE
- [ ] TC-31: Notification topic + subscription
- [ ] TC-32: Events rule fires
- [ ] TC-33: Monitoring alarm OK
- [ ] TC-34: Vault + Master Key ENABLED
- [ ] TC-35: Cloud Guard target ACTIVE with findings
- [ ] TC-36/37: Security Zones block non-compliant (409 confirmed)
- [ ] TC-38/39: VSS recipe + target, scan pending/complete
- [ ] TC-40: Certificate Authority ACTIVE
- [ ] TC-41: Zero drift
- [ ] TC-42: SSH key in Vault + instance metadata confirmed
- [ ] `sprint3_outputs.json` exported
- [ ] Git tag `sprint3-complete` pushed
