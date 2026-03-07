# STAR ELZ V1 — Sprint 3: Security, Forced Inspection, Observability

**Branch:** `sprint3` · **Dates:** 9–11 Mar 2026 · **Terraform ≥ 1.3.0** · **OCI Provider ≥ 6.0.0**

> **Coming from Sprint 2?** You need `sprint2_outputs.json` for DRG, VCN, subnet, Bastion, Sim FW, and SGW OCIDs. Paste them into Sprint 3 ORM Variables. Run the Sprint 1 IAM patch FIRST — see `SPRINT1_IAM_PATCH_FOR_S3.md`.

Sprint 3 adds the security enforcement layer on top of Sprint 2's hub-and-spoke network. The main goal: **forced inspection** — all spoke-to-spoke traffic now flows through the Hub Sim FW instead of bypassing it via DRG full-mesh.

Also added: Vault/KMS, Cloud Guard, Security Zones, NSGs, VCN flow logs, Service Connector Hub (log publishing), VSS vulnerability scanning, Certificate Authority, events/alarms, and Bastion SSH sessions for validation.

---

## Network Topology

```
STAR ELZ V1 — Sprint 3 Topology (builds on Sprint 2)

C1_R_ELZ_NW  (Hub — T4 routing, T1/T2 NSGs + flow logs)
├── vcn_r_elz_nw                      10.0.0.0/16
│   ├── sub_r_elz_nw_fw               10.0.0.0/24   [private]
│   │   ├── fw_r_elz_nw_hub_sim       Sim FW (Sprint 2) — forced inspection point
│   │   ├── nsg_r_elz_nw_fw           NSG (T1) — all internal + egress
│   │   ├── fl_r_elz_nw_fw            Flow log (T1)
│   │   └── rt_r_elz_nw_fw            Sprint 2 SGW + Sprint 3 spoke CIDRs → DRG
│   │
│   ├── sub_r_elz_nw_mgmt             10.0.1.0/24   [private]
│   │   ├── bas_r_elz_nw_hub          Bastion (Sprint 2)
│   │   ├── nsg_r_elz_nw_mgmt         NSG (T2) — all internal + egress
│   │   ├── fl_r_elz_nw_mgmt          Flow log (T2)
│   │   └── rt_r_elz_nw_mgmt          Sprint 2: 0/0 → DRG + SGW
│   │
│   ├── sgw_r_elz_nw_hub              Service Gateway (Sprint 2)
│   │
│   ├── rt_r_elz_nw_hub_ingress       VCN Ingress RT (T4) → Hub FW private IP
│   │                                  (attached to Hub DRG attachment)
│   │
│   ├── drg_r_hub                      Hub DRG (Sprint 2) — 5 attachments
│   │   ├── drgrt_r_hub_spoke_mesh     Custom DRG RT (T4) — import distribution
│   │   │   └── drgrd_r_hub_vcn_import  Import dist — learns all VCN CIDRs
│   │   ├── drgrt_spoke_to_hub         Custom DRG RT (T4) — static 0/0 → Hub
│   │   │
│   │   ├── drga_r_elz_nw_hub ────→ drgrt_r_hub_spoke_mesh + VCN ingress RT
│   │   ├── drga_os_elz_nw ──────→ drgrt_spoke_to_hub
│   │   ├── drga_ts_elz_nw ──────→ drgrt_spoke_to_hub
│   │   ├── drga_ss_elz_nw ──────→ drgrt_spoke_to_hub
│   │   └── drga_devt_elz_nw ────→ drgrt_spoke_to_hub
│   │
│   └── drg_r_ew_hub                   E-W DRG (Sprint 2, V2 placeholder)
│
├── C1_OS_ELZ_NW  (T1)
│   └── vcn_os_elz_nw                  10.1.0.0/24
│       ├── sub_os_elz_nw_app         fw_os_elz_nw_sim · nsg_os_elz_nw_app · fl_os_elz_nw_app
│       └── sgw_os_elz_nw             Sprint 2
│
├── C1_SS_ELZ_NW  (T3/T2)
│   └── vcn_ss_elz_nw                  10.2.0.0/24
│       ├── sub_ss_elz_nw_app         fw_ss_elz_nw_sim · nsg_ss_elz_nw_app · fl_ss_elz_nw_app
│       └── sgw_ss_elz_nw             Sprint 2
│
├── C1_TS_ELZ_NW  (T2)
│   └── vcn_ts_elz_nw                  10.3.0.0/24
│       ├── sub_ts_elz_nw_app         fw_ts_elz_nw_sim · nsg_ts_elz_nw_app · fl_ts_elz_nw_app
│       └── sgw_ts_elz_nw             Sprint 2
│
└── C1_DEVT_ELZ_NW  (T2)
    └── vcn_devt_elz_nw                10.4.0.0/24
        ├── sub_devt_elz_nw_app       (no Sim FW) · nsg_devt_elz_nw_app · fl_devt_elz_nw_app
        └── sgw_devt_elz_nw           Sprint 2

C1_R_ELZ_SEC  (T3 security services)
├── vlt_r_elz_sec                      OCI Vault (Virtual Private)
│   └── key_r_elz_sec_master          AES-256 Master Encryption Key
├── ca_r_elz_sec                       Certificate Authority (T2, V2 readiness)
├── cgdr_r_elz_config                  Cloud Guard config detector recipe
├── cgdr_r_elz_activity                Cloud Guard activity detector recipe
├── cgrr_r_elz_responder               Cloud Guard responder recipe
├── cgt_r_elz_root                     Cloud Guard target (root compartment)
├── szr_r_elz_sec / sz_r_elz_sec       Security Zone recipe + zone (SEC)
├── szr_r_elz_nw / sz_r_elz_nw         Security Zone recipe + zone (NW)
├── lg_r_elz_nw_flow                   Log group (T3) — contains 6 flow logs
├── bkt_r_elz_sec_logs                 Object Storage bucket (log retention)
├── sch_r_elz_sec_flow_logs            Service Connector Hub (T1) — logs → bucket
├── vssr_r_elz_sec                     VSS scan recipe (T1)
├── vsst_r_elz_nw                      VSS scan target (T1) — scans NW instances
├── nt_r_elz_sec_alerts                Notification topic
├── ev_r_elz_sec_nw_changes            Events rule (DRG/routing changes)
└── al_r_elz_sec_drg_change            Monitoring alarm (Hub FW drops)

FORCED INSPECTION — the Sprint 3 difference:
  Sprint 2: OS → DRG full-mesh → TS (bypasses Hub FW)
  Sprint 3: OS → DRG(spoke_to_hub) → Hub VCN(ingress RT) → Hub FW → rt_r_elz_nw_fw → DRG → TS
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
| `hub_fw_private_ip_id` | `hub_fw_private_ip_id` | VCN ingress RT next-hop |
| `hub_fw_rt_id` | `hub_fw_rt_id` | Import Hub FW RT into Sprint 3 |
| `hub_sgw_id` | `hub_sgw_id` | SGW route rule in Hub FW RT |

**No hardcoding.** Every Sprint 2 reference is a Terraform variable. Paste OCIDs in ORM once.

**DRG handover:** Sprint 2 creates the DRG with auto-generated (default) DRG route tables. Sprint 3 creates custom DRG route tables and reassigns them to attachments using `oci_core_drg_attachment_management`. This doesn't conflict with Sprint 2 state — `drg_attachment_management` only modifies DRG-side properties, not the attachment lifecycle.

**SGW handover:** Sprint 2 owns all 5 Service Gateways. Sprint 3 references the Hub SGW via `var.hub_sgw_id` for the Hub FW RT route rule. No duplication.

**Cloud-init (Sim FW):** Sprint 2 created Sim FWs with `ip_forward=1` + MASQUERADE on ens3 + `skip_source_dest_check=true`. Sprint 3's forced inspection routing relies on this — DRG sends packets to the Hub VCN, ingress RT points to the Hub FW private IP, the FW forwards packets back to the DRG via rt_r_elz_nw_fw. No cloud-init changes needed.

---

## Pre-Apply Steps (do these FIRST)

1. **Run Sprint 1 IAM patch** — see `SPRINT1_IAM_PATCH_FOR_S3.md`. Re-run Sprint 1 ORM Apply (9 new policy statements, zero destroys).
2. **Verify Cloud Guard is ENABLED** — Console → Security → Cloud Guard. If not enabled, enable it manually. Sprint 3 creates Cloud Guard recipes/targets which fail if the service isn't on.
3. **Paste Sprint 2 OCIDs** into Sprint 3 ORM Variables (22 values from `sprint2_outputs.json`).
4. **Paste SSH public key** into ORM Variable `ssh_public_key` — this is used by Bastion sessions created via Terraform.

---

## Team Assignments

| Team | File(s) | Resources | Count |
|---|---|---|---|
| T1 | `sec_team1.tf` | Bastion (OS), Hub FW + OS NSGs, flow logs (hub_fw + OS), VSS recipe + target, SCH | 12 |
| T2 | `sec_team2.tf` | Bastion (TS), Hub MGMT + TS + SS + DEVT NSGs, flow logs (4), Certificate Authority | 18 |
| T3 | `sec_team3.tf` + `sec_team3_security.tf` | Log group, bucket, notifications, events, alarm, Vault/KMS, Cloud Guard, Security Zones | 15 |
| T4 | `sec_team4.tf` | DRG route tables, import distribution, forced inspection, VCN ingress RT, Hub FW RT, DRG attachment management | 12 |
| **Total** | | | **57** |

---

## SSH Public Key

Sprint 3 Bastion sessions (`sec_team1.tf`, `sec_team2.tf`) are created via Terraform and require `var.ssh_public_key`. This key is used in the `key_details` block of `oci_bastion_session`. The Bastion session presents this key to the target instance's Cloud Agent for authentication.

Sprint 2 Managed SSH sessions (created via Console) don't need this — you paste your key at session creation time. But Sprint 3 Terraform-created sessions need the key in the code.

**How to provide:** Paste the contents of `~/.ssh/id_rsa.pub` into the ORM Variable `ssh_public_key`. If you don't have a key, generate one: `ssh-keygen -t rsa -b 4096`.

**Vault integration (V2):** In production, SSH keys should be stored in the Vault (`vlt_r_elz_sec`) and referenced via `oci_kms_secret`. For V1 POC, pasting the key directly in ORM is sufficient.

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

---

## Design Decisions

| Decision | Detail |
|---|---|
| Forced inspection | Custom DRG RTs replace auto-generated full-mesh. `spoke_to_hub` sends 0/0 → Hub attachment. Hub ingress RT → Hub FW private IP. Hub FW RT → spoke CIDRs back to DRG. |
| `drg_attachment_management` | Modifies DRG-side properties on existing Sprint 2 attachments without importing them into Sprint 3 state. Two ORM stacks, zero state conflicts. |
| Hub FW RT import | Sprint 2 created `rt_r_elz_nw_fw` (had only SGW rule). Sprint 3 imports it via `import{}` block and adds spoke CIDR routes. SGW rule preserved. |
| SGW from Sprint 2 | Sprint 3 references Sprint 2's Hub SGW via `var.hub_sgw_id`. No duplication. Spoke SGWs not touched by Sprint 3. |
| NSGs | 6 NSGs (one per subnet). Current rules: allow all internal 10/8 + egress. V2 tightens per-service (SSH only from Bastion CIDR, ICMP between spokes, deny all else). |
| VSS | Weekly STANDARD scan. Recipe in SEC compartment. Target scans NW compartment instances. First scan runs on next schedule cycle. |
| SCH | Flow logs → Object Storage bucket. Provides log retention beyond OCI Logging's 30-day window. |
| Certificate Authority | Root CA in SEC compartment, signed by Vault master key. V2 issues certs for Load Balancers and API Gateways. No certs issued in V1 (no HTTPS endpoints). |
| Security Zones | Enforce compliance: no public buckets, no public subnets, encryption required. Applied to SEC + NW compartments. |
| SSH key | `var.ssh_public_key` for Terraform Bastion sessions. No keys in Vault for V1 POC. Console sessions use paste-at-creation. |

---

## Handoff Checklist

- [ ] Sprint 1 IAM patch applied (9 statements)
- [ ] TC-20: 2 custom DRG route tables
- [ ] TC-21: spoke attachments → spoke_to_hub RT, hub → hub_spoke_mesh RT
- [ ] TC-22: **Forced inspection proven** — traceroute shows Hub FW hop + NPA confirms
- [ ] TC-23: VCN ingress RT → Hub FW private IP
- [ ] TC-24: Hub FW RT has spoke CIDRs + SGW
- [ ] TC-25: 6 NSGs
- [ ] TC-26/27: Bastion SSH sessions work
- [ ] TC-28: Flow logs ACTIVE
- [ ] TC-29: Log bucket has objects
- [ ] TC-30: SCH ACTIVE + data transferred
- [ ] TC-31: Notification topic (email subscription added)
- [ ] TC-32: Events rule ACTIVE
- [ ] TC-33: Monitoring alarm OK
- [ ] TC-34: Vault + Master Key ENABLED
- [ ] TC-35: Cloud Guard target ACTIVE
- [ ] TC-36/37: Security Zones block non-compliant resources (409 test)
- [ ] TC-38/39: VSS recipe + target created
- [ ] TC-40: Certificate Authority ACTIVE
- [ ] TC-41: Zero drift
- [ ] `sprint3_outputs.json` exported
- [ ] Git tag `sprint3-complete` pushed
