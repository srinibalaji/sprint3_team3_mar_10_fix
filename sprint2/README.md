# STAR ELZ V1 — Sprint 2: Hub and Spoke Networking

**Branch:** `sprint2` &nbsp;|&nbsp; **Dates:** 2 Mar 2026 – 4 Mar 2026 &nbsp;|&nbsp; **OCI Resources:** VCN, Subnet, DRG, Route Table, Sim Firewall (Compute), Bastion

---

## What This Is

Sprint 2 builds the network foundation for the STAR ELZ — a hub-and-spoke topology connecting 5 VCNs (1 hub + 4 spokes) provisioned into the compartments created in Sprint 1. This is a V1 isolated design — no internet gateway, no public IPs. All validation uses OCI NPA (control plane) and Bastion SSH sessions (data plane).

East-West routing between spokes is testable in Sprint 2 via OCI DRG v2 full-mesh — all spoke-to-spoke paths traverse the Hub DRG and are validated with NPA (TC-18) and data-plane ping/traceroute/tcpdump (TC-19). Hub Sim FW inspection of spoke-to-spoke traffic is a Sprint 3 item (S3-BACKLOG-01).

| Sprint | Folder | Purpose |
|---|---|---|
| `sprint1/` | IAM | Teams fork, compartments/groups/policies |
| `sprint2/` | This folder | Networking — two-phase apply |

---

## Architecture — Hub and Spoke via DRG (V1 Isolated)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  C0  TENANCY ROOT                                                                                                │
│  Tag Namespace : C0-star-elz-v1   Tags: Environment · Owner · ManagedBy · CostCenter [cost-tracking] · DataClassi│
│  Tag Default   : DataClassification = Official-Closed  (auto-applied at tenancy root · CIS 3.2 compliance)       │
└────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────┘
                                                         │  tenancy parent
┌────────────────────────────────────────────────────────▼─────────────────────────────────────────────────────────┐
│  C1_R_ELZ_NW  ──  HUB COMPARTMENT  (Team 4)                                                                      │
│  VCN-C1-R-ELZ-NW-HUB   10.0.0.0/16                                                                               │
│                                                                                                                  │
│  ┌──────────────────────────────────────────────────┐  ┌──────────────────────────────────────────────────┐      │
│  │ SUB-C1-R-ELZ-NW-FW                               │  │ SUB-C1-R-ELZ-NW-MGMT                             │      │
│  │ 10.0.0.0/24  [private · no public IP]            │  │ 10.0.1.0/24  [private · no public IP]            │      │
│  ├──────────────────────────────────────────────────┤  ├──────────────────────────────────────────────────┤      │
│  │ FW-C1-R-ELZ-NW-HUB-SIM                           │  │ BAS-C1-R-ELZ-NW-HUB                              │      │
│  │ VM.Standard.E4.Flex · 1 OCPU · 2 GB              │  │ OCI Bastion Service STANDARD                     │      │
│  │ skip_source_dest_check = true                    │  │ Admin SSH · managed sessions (TC-15/TC-19)       │      │
│  │ assign_public_ip       = false                   │  │ Target: Sim FW private IPs                       │      │
│  │ net.ipv4.ip_forward    = 1 (sysctl)              │  │                                                  │      │
│  │ iptables MASQUERADE on eth0                      │  │                                                  │      │
│  ├──────────────────────────────────────────────────┤  ├──────────────────────────────────────────────────┤      │
│  │ RT-C1-R-ELZ-NW-FW                                │  │ RT-C1-R-ELZ-NW-MGMT                              │      │
│  │ └─▶  [ empty in V1 ]                             │  │ └─▶  0.0.0.0/0 ──────▶ DRG  (Phase 2)            │      │
│  │       Sprint 3: DRG transit routing              │  │       enables Bastion → spoke reach              │      │
│  └──────────────────────────────────────────────────┘  └──────────────────────────────────────────────────┘      │
│                                                                                                                  │
│  ┌──────────────────────────────────────────────────┐  ┌──────────────────────────────────────────────────┐      │
│  │ DRG-C1-R-ELZ-NW-HUB  ◀── hub_drg_id              │  │ DRG-C1-R-ELZ-NW-EW                               │      │
│  │ North-South hub DRG · Phase 1 output             │  │ East-West inter-agency DRG                       │      │
│  ├──────────────────────────────────────────────────┤  ├──────────────────────────────────────────────────┤      │
│  │ Phase 2 VCN attachments:                         │  │ V2 placeholder · 0 attachments in V1             │      │
│  │  ├─ DRGA-C1-R-ELZ-NW-HUB (Hub VCN)               │  │ Sprint 3: add DRG route tables +                 │      │
│  │  ├─ DRGA-C1-OS-ELZ-NW    (OS  VCN)               │  │           spoke attachments for E-W              │      │
│  │  ├─ DRGA-C1-TS-ELZ-NW    (TS  VCN)               │  │ TC-12b: validate AVAILABLE, 0 attachments        │      │
│  │  ├─ DRGA-C1-SS-ELZ-NW    (SS  VCN)               │  │         output: ew_hub_drg_id                    │      │
│  │  └─ DRGA-C1-DEVT-ELZ-NW  (DEVT VCN)              │  │                                                  │      │
│  └─────────────────────────┴────────────────────────┘  └──────────────────────────────────────────────────┘      │
│                                                                                                                  │
└────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────┘
                             │
                             │  hub_drg_id ◀── after T4 Phase 1 apply · share OCID with T1 T2 T3 before Phase 2
                             │
┌─────────────┬──────────────┴─────────────┬────────────────────────────┬────────────────────────────┬─────────────┐
│  DRG SWITCHING FABRIC  ·  OCI DRG v2 full-mesh  ·  all spoke↔spoke paths REACHABLE via DRG          │            │
│  E-W routing testable in Sprint 2 (TC-18 NPA, TC-19 data plane)  ·  Hub FW inspection: S3-BACKLOG-01 │            │
└─────────────┴────────────────────────────┴────────────────────────────┴────────────────────────────┴─────────────┘
              │                            │                            │                            │
              ▼                            ▼                            ▼                            ▼
 ┌─────────────────────────┐  ┌─────────────────────────┐  ┌─────────────────────────┐  ┌─────────────────────────┐
 │ C1_OS_ELZ_NW  T1        │  │ C1_TS_ELZ_NW  T2        │  │ C1_SS_ELZ_NW  T3        │  │ C1_DEVT_ELZ_NW  T3      │
 ├─────────────────────────┤  ├─────────────────────────┤  ├─────────────────────────┤  ├─────────────────────────┤
 │ VCN-C1-OS-ELZ-NW        │  │ VCN-C1-TS-ELZ-NW        │  │ VCN-C1-SS-ELZ-NW        │  │ VCN-C1-DEVT-ELZ-NW      │
 │ 10.1.0.0/24             │  │ 10.3.0.0/24             │  │ 10.2.0.0/24             │  │ 10.4.0.0/24             │
 ├─────────────────────────┤  ├─────────────────────────┤  ├─────────────────────────┤  ├─────────────────────────┤
 │ SUB-C1-OS-ELZ-NW-APP    │  │ SUB-C1-TS-ELZ-NW-APP    │  │ SUB-C1-SS-ELZ-NW-APP    │  │ SUB-C1-DEVT-ELZ-NW-APP  │
 │ 10.1.0.0/24             │  │ 10.3.0.0/24             │  │ 10.2.0.0/24             │  │ 10.4.0.0/24             │
 │ prohibit_pub_ip=true    │  │ prohibit_pub_ip=true    │  │ prohibit_pub_ip=true    │  │ prohibit_pub_ip=true    │
 ├─────────────────────────┤  ├─────────────────────────┤  ├─────────────────────────┤  ├─────────────────────────┤
 │ FW-C1-OS-ELZ-NW-SIM     │  │ FW-C1-TS-ELZ-NW-SIM     │  │ FW-C1-SS-ELZ-NW-SIM     │  │ ── no Sim FW in V1 ──   │
 │ E4.Flex · skip_sdc=true │  │ E4.Flex · skip_sdc=true │  │ E4.Flex · skip_sdc=true │  │ network-only spoke      │
 │ ip_fwd=1 · MASQUERADE   │  │ ip_fwd=1 · MASQUERADE   │  │ ip_fwd=1 · MASQUERADE   │  │ compute: Sprint 4+      │
 ├─────────────────────────┤  ├─────────────────────────┤  ├─────────────────────────┤  ├─────────────────────────┤
 │ RT-C1-OS-ELZ-NW-APP     │  │ RT-C1-TS-ELZ-NW-APP     │  │ RT-C1-SS-ELZ-NW-APP     │  │ RT-C1-DEVT-ELZ-NW-APP   │
 │ 0.0.0.0/0 ─▶ DRG-HUB    │  │ 0.0.0.0/0 ─▶ DRG-HUB    │  │ 0.0.0.0/0 ─▶ DRG-HUB    │  │ 0.0.0.0/0 ─▶ DRG-HUB    │
 │ depends_on: DRGA attach │  │ depends_on: DRGA attach │  │ depends_on: DRGA attach │  │ depends_on: DRGA attach │
 └─────────────────────────┘  └─────────────────────────┘  └─────────────────────────┘  └─────────────────────────┘

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 LEGEND
 [private]       prohibit_public_ip_on_vnic=true on all subnets · no Internet Gateway anywhere in V1
 skip_sdc        skip_source_dest_check=true on all Sim FW VNICs — required for OCI-level packet forwarding
 ip_fwd=1        net.ipv4.ip_forward=1 via /etc/sysctl.d/99-ipforward.conf (persists across reboot)
 MASQUERADE      iptables POSTROUTING MASQUERADE eth0 — saved via: service iptables save
 Phase 2 gate    All DRG attachments/RT rules/Sim FW/Bastion require hub_drg_id != ''  (count gate)
 DRG-EW          DRG-C1-R-ELZ-NW-EW: 0 attachments in V1 · output: ew_hub_drg_id · TC-12b validates
 dynamic RT      route_rules dynamic{} block: in-place Phase 2 update — no subnet recreation on apply
 E-W in V1       Spoke↔spoke routing EXISTS via DRG v2 full-mesh · tested TC-18 (NPA) + TC-19 (data plane)
 S3-BACKLOG-01   Hub FW inspection of E-W traffic requires DRG route tables — Sprint 3 scope
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

---

## File Map

| File | Team | Description |
|---|---|---|
| `locals.tf` | — | All name constants, DNS label constants, CIDR plan, phase2 gate, Sim FW cloud-init |
| `variables_general.tf` | — | Tenancy, region, service_label, CIS level, tagging |
| `variables_iam.tf` | — | 10 compartment OCIDs from Sprint 1 outputs |
| `variables_net.tf` | — | CIDRs, hub_drg_id (Phase 2 gate), Sim FW shape, Bastion CIDR |
| `data_sources.tf` | — | Regions, tenancy, ADs, OL8 platform images |
| `providers.tf` | — | OCI + OCI home providers, Terraform ≥ 1.3.0 |
| `nw_main.tf` | — | Architecture doc comment + shared tag merge locals |
| `iam_sprint1_ref.tf` | — | READ ONLY — Sprint 1 IAM reference documentation |
| `nw_team1.tf` | T1 | C1_OS_ELZ_NW — OS VCN, subnet, DRG attachment, RT, Sim FW |
| `nw_team2.tf` | T2 | C1_TS_ELZ_NW — TS VCN, subnet, DRG attachment, RT, Sim FW |
| `nw_team3.tf` | T3 | C1_SS_ELZ_NW + C1_DEVT_ELZ_NW — VCNs, subnets, DRG attachments, RTs, Sim FW (SS only) |
| `nw_team4.tf` | T4 | C1_R_ELZ_NW — Hub VCN, FW+MGMT subnets, both DRGs, RTs, Sim FW (private), Bastion |
| `outputs.tf` | — | All VCN/subnet/DRG OCIDs, Sim FW instance IDs, Bastion ID |
| `schema.yaml` | — | ORM UI schema — 8 sections, hub_drg_id Phase 1/2 label |
| `terraform.tfvars.template` | — | Clean template — paste Sprint 1 compartment OCIDs here |

---

## Sprint 2 Issue List

### VCN + Subnet (Phase 1)

| # | Task | Team | Start | Finish | Compartment | File |
|---|---|---|---|---|---|---|
| S2-T1 | Write & provision VCN + Subnet for OS compartment | T1 | 3/2/26 | 3/4/26 | C1_OS_ELZ_NW | nw_team1.tf |
| S2-T2 | Write & provision VCN + Subnet for TS compartment | T2 | 3/2/26 | 3/4/26 | C1_TS_ELZ_NW | nw_team2.tf |
| S2-T3 | Write & provision VCN + Subnet for SS + DEVT compartment | T3 | 3/2/26 | 3/4/26 | C1_SS_ELZ_NW + C1_DEVT_ELZ_NW | nw_team3.tf |
| S2-T4 | Write & provision VCN + Subnet + DRG for ELZ_NW compartment | T4 | 3/2/26 | 3/4/26 | C1_R_ELZ_NW | nw_team4.tf |

### Route Tables (Phase 2)

| # | Task | Team | Start | Finish | Compartment | File |
|---|---|---|---|---|---|---|
| S2-T1 | Write & provision Route Table for OS compartment | T1 | 3/2/26 | 3/4/26 | C1_OS_ELZ_NW | nw_team1.tf |
| S2-T2 | Write & provision Route Table for TS compartment | T2 | 3/2/26 | 3/4/26 | C1_TS_ELZ_NW | nw_team2.tf |
| S2-T3 | Write & provision Route Table for SS + DEVT compartment | T3 | 3/2/26 | 3/4/26 | C1_SS_ELZ_NW + C1_DEVT_ELZ_NW | nw_team3.tf |
| S2-T4 | Write & provision Route Table for ELZ_NW compartment | T4 | 3/2/26 | 3/4/26 | C1_R_ELZ_NW | nw_team4.tf |

### Sim Firewall (Phase 2)

| # | Task | Team | Start | Finish | Compartment | File |
|---|---|---|---|---|---|---|
| S2-T1 | Simulate compute / provision Firewall for OS compartment | T1 | 3/2/26 | 3/4/26 | C1_OS_ELZ_NW | nw_team1.tf |
| S2-T2 | Simulate compute / provision Firewall for TS compartment | T2 | 3/2/26 | 3/4/26 | C1_TS_ELZ_NW | nw_team2.tf |
| S2-T3 | Simulate compute / provision Firewall for SS compartment | T3 | 3/2/26 | 3/4/26 | C1_SS_ELZ_NW | nw_team3.tf |
| S2-T4 | Simulate compute / provision Firewall for ELZ_NW compartment | T4 | 3/2/26 | 3/4/26 | C1_R_ELZ_NW | nw_team4.tf |

### Bastion (Phase 2)

| # | Task | Team | Start | Finish | Compartment | File |
|---|---|---|---|---|---|---|
| S2-T4 | Write & provision Bastion for ELZ_NW compartment | T4 | 3/2/26 | 3/4/26 | C1_R_ELZ_NW | nw_team4.tf |

---

## Two-Phase Apply — Step by Step

### Pre-requisites (Sprint 1 → Sprint 2 Handoff Checklist)

Before Sprint 2 begins, verify Sprint 1 is complete:

- [ ] TC-01: 10 TF compartments PASS
- [ ] TC-01b: 2 manual compartments + OCIDs recorded
- [ ] TC-02: 12 groups PASS (10 TF + 2 manual)
- [ ] TC-03: SoD NEGATIVE PASS (screenshot in issue #20)
- [ ] TC-04: SOC read-only PASS
- [ ] TC-05: ELZ tags PASS (CostCenter is_cost_tracking=true)
- [ ] TC-06: ORM Stack Apply SUCCEEDED
- [ ] TC-06b: ORM Plan zero drift PASS
- [ ] `terraform output -json > sprint1_outputs.json` exported and shared with Sprint 2 lead
- [ ] Git tag `v1-sprint1-complete` pushed to main

### Phase 1 — Simultaneous VCN + Subnet Provisioning

1. All 4 teams create a new ORM Stack pointing to `sprint2/` working directory
2. Paste all 10 compartment OCIDs into ORM Variables (Section 3) from `sprint1_outputs.json`
3. Leave `hub_drg_id` **empty** (Section 4)
4. Plan → Apply simultaneously (no inter-team dependency in Phase 1)

> T4 applies: Hub VCN + FW subnet + MGMT subnet + both DRGs
> T1 applies: OS VCN + OS app subnet
> T2 applies: TS VCN + TS app subnet
> T3 applies: SS VCN + SS app subnet + DEVT VCN + DEVT app subnet

Execute **TC-07** and **TC-08** immediately after Phase 1 — verify 5 VCNs and 6 subnets before proceeding.

T4 runs after their apply:

```bash
terraform output hub_drg_id
```

T4 shares the DRG OCID with all teams.

### Phase 2 — Route Tables + DRG Attachments + Sim FW + Bastion

1. All teams update ORM Variables: paste `hub_drg_id` (Section 4)
2. All 4 teams Plan → Apply simultaneously
3. Phase 2 resources created: DRG attachments, route table rules, Sim FW instances, Bastion
4. Execute **TC-09** through **TC-19** after Phase 2

### After Phase 2 Apply

```bash
# Export all outputs for Sprint 3 Security lead
terraform output -json > sprint2_outputs.json

# Git tag
git tag sprint2-complete
git push origin sprint2-complete
```

---

## Test Cases — Sprint 2 Validation

### NPA and Data Plane Scope — Read This First

**OCI Network Path Analyzer (NPA)** validates the OCI **control plane** — route tables, DRG attachments, NSG and security list rules. It does not validate what happens inside the Linux instance. It cannot verify whether cloud-init ran, whether `net.ipv4.ip_forward=1` is set, or whether iptables rules are active.

**Data plane tests** (ping, traceroute, tcpdump, TCP) validate actual packet flow and require a Bastion SSH session into a Sim FW instance.

**East-West routing in V1** — Spoke-to-spoke traffic is routable right now via OCI DRG v2 full-mesh. Every spoke RT sends `0.0.0.0/0` to the Hub DRG, and the DRG full-mesh means OS can reach TS, SS, and DEVT subnets through the DRG fabric. TC-18 validates this at the NPA control plane. TC-19 validates it with actual packets from the Hub Sim FW. The known gap is that this traffic bypasses the Hub Sim FW (S3-BACKLOG-01) — that is a Sprint 3 fix, not a Sprint 2 defect.

| Phase | Run After | TCs |
|---|---|---|
| Phase 1 | T4 confirms `hub_drg_id` | TC-07, TC-08 |
| Phase 2 | All teams applied | TC-09, TC-10, TC-11, TC-12, TC-12b |
| Phase 2 | After TC-09 confirmed | TC-13, TC-14, TC-18 (NPA) |
| Phase 2 | After TC-11 Bastion ACTIVE | TC-15, TC-16, TC-19 (SSH data plane) |
| Phase 2 | After all TCs pass | TC-17 (zero drift) |

### Set Shell Variables First (run in OCI Cloud Shell)

```bash
# Paste OCIDs from: terraform output -json > sprint2_outputs.json
HUB_DRG_ID="ocid1.drg.oc1..aaa"
EW_HUB_DRG_ID="ocid1.drg.oc1..aaa"
HUB_VCN_ID="ocid1.vcn.oc1..aaa"
OS_VCN_ID="ocid1.vcn.oc1..aaa"
TS_VCN_ID="ocid1.vcn.oc1..aaa"
SS_VCN_ID="ocid1.vcn.oc1..aaa"
DEVT_VCN_ID="ocid1.vcn.oc1..aaa"
HUB_BASTION_ID="ocid1.bastion.oc1..aaa"
SIM_FW_HUB_ID="ocid1.instance.oc1..aaa"
SIM_FW_OS_ID="ocid1.instance.oc1..aaa"
SIM_FW_TS_ID="ocid1.instance.oc1..aaa"
SIM_FW_SS_ID="ocid1.instance.oc1..aaa"
REGION="ap-singapore-2"

# Helper: resolve Sim FW private IPs (OCI assigns dynamically, no static output)
# Required for E-W data plane tests TC-19
get_private_ip() {
  local inst_id=$1
  local attach_id=$(oci compute vnic-attachment list --instance-id $inst_id \
    --query 'data[0].id' --raw-output)
  local vnic_id=$(oci compute vnic-attachment get --vnic-attachment-id $attach_id \
    --query 'data."vnic-id"' --raw-output)
  oci network vnic get --vnic-id $vnic_id --query 'data."private-ip"' --raw-output
}
HUB_FW_IP=$(get_private_ip $SIM_FW_HUB_ID)
OS_FW_IP=$(get_private_ip $SIM_FW_OS_ID)
TS_FW_IP=$(get_private_ip $SIM_FW_TS_ID)
SS_FW_IP=$(get_private_ip $SIM_FW_SS_ID)
echo "Hub FW : $HUB_FW_IP"
echo "OS  FW : $OS_FW_IP"
echo "TS  FW : $TS_FW_IP"
echo "SS  FW : $SS_FW_IP"
```

---

### TC-07 — 5 VCNs Created (Run: immediately after Phase 1)

```bash
oci network vcn list \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output) \
  --all \
  --query "data[?starts_with(\"display-name\", 'VCN-C1')]" \
  | jq '[.[] | {name: .["display-name"], cidr: .["cidr-blocks"][0]}]'

# Quick count — must be 5 before sharing hub_drg_id with other teams
... | jq length
```

Expected: 5 entries — `VCN-C1-R-ELZ-NW-HUB`, `VCN-C1-OS-ELZ-NW`, `VCN-C1-TS-ELZ-NW`, `VCN-C1-SS-ELZ-NW`, `VCN-C1-DEVT-ELZ-NW`

---

### TC-08 — 6 Subnets Created (Run: immediately after Phase 1)

```bash
for VCN_ID in $HUB_VCN_ID $OS_VCN_ID $TS_VCN_ID $SS_VCN_ID $DEVT_VCN_ID; do
  oci network subnet list --vcn-id $VCN_ID \
    --query "data[].{name:\"display-name\", cidr:\"cidr-block\", private:\"prohibit-public-ip-on-vnic\"}" \
    | jq '.[]'
done
```

Expected: 6 subnets — all `"prohibit-public-ip-on-vnic": true`

| Subnet | CIDR | Private |
|---|---|---|
| SUB-C1-R-ELZ-NW-FW | 10.0.0.0/24 | true |
| SUB-C1-R-ELZ-NW-MGMT | 10.0.1.0/24 | true |
| SUB-C1-OS-ELZ-NW-APP | 10.1.0.0/24 | true |
| SUB-C1-TS-ELZ-NW-APP | 10.3.0.0/24 | true |
| SUB-C1-SS-ELZ-NW-APP | 10.2.0.0/24 | true |
| SUB-C1-DEVT-ELZ-NW-APP | 10.4.0.0/24 | true |

---

### TC-09 — Hub DRG Has 5 Attachments (Run: after Phase 2)

```bash
oci network drg-attachment list \
  --drg-id $HUB_DRG_ID \
  --all \
  --query "data[].{name:\"display-name\", state:\"lifecycle-state\"}" \
  | jq '.[]'

# Quick count
oci network drg-attachment list --drg-id $HUB_DRG_ID --all | jq '.data | length'
```

Expected: 5 attachments, all `"lifecycle-state": "ATTACHED"`

---

### TC-10 — 4 Sim FW Instances Running + skip_source_dest_check Verified (Run: after Phase 2)

```bash
# Verify RUNNING state
for INST_ID in $SIM_FW_HUB_ID $SIM_FW_OS_ID $SIM_FW_TS_ID $SIM_FW_SS_ID; do
  oci compute instance get --instance-id $INST_ID \
    --query 'data.{name:"display-name", state:"lifecycle-state"}' | jq '.'
done
```

Expected: All 4 show `"lifecycle-state": "RUNNING"`

```bash
# Verify skip_source_dest_check = true on each VNIC
# If false, OCI silently drops forwarded packets regardless of Linux ip_forward setting
for INST_ID in $SIM_FW_HUB_ID $SIM_FW_OS_ID $SIM_FW_TS_ID $SIM_FW_SS_ID; do
  ATTACH_ID=$(oci compute vnic-attachment list --instance-id $INST_ID \
    --query 'data[0].id' --raw-output)
  VNIC_ID=$(oci compute vnic-attachment get --vnic-attachment-id $ATTACH_ID \
    --query 'data."vnic-id"' --raw-output)
  oci network vnic get --vnic-id $VNIC_ID \
    --query 'data.{name:"display-name", skip_sdc:"skip-source-dest-check"}' | jq '.'
done
```

Expected: `"skip_sdc": true` on all 4 VNICs

---

### TC-11 — Hub Bastion Active (Run: after Phase 2)

```bash
oci bastion bastion get \
  --bastion-id $HUB_BASTION_ID \
  --query 'data.{name:"name", state:"lifecycle-state"}' | jq '.'
```

Expected: `"lifecycle-state": "ACTIVE"`

---

### TC-12 — Route Tables Have Correct Rules (Run: after Phase 2)

```bash
# Spoke route tables: each must have exactly one rule — 0.0.0.0/0 → Hub DRG
for VCN_ID in $OS_VCN_ID $TS_VCN_ID $SS_VCN_ID $DEVT_VCN_ID; do
  oci network route-table list --vcn-id $VCN_ID \
    --query "data[?starts_with(\"display-name\",'RT-C1')].{name:\"display-name\",rules:\"route-rules\"}" \
    | jq '.[].rules'
done
```

Expected: Each spoke RT — one rule, `destination: 0.0.0.0/0`, `networkEntityId: <hub_drg_id>`

```bash
# Hub FW route table — EMPTY in V1 (Sprint 3 adds DRG transit routing)
oci network route-table list --vcn-id $HUB_VCN_ID \
  --query "data[?\"display-name\"=='RT-C1-R-ELZ-NW-FW'].{name:\"display-name\",rules:\"route-rules\"}" \
  | jq '.[].rules'
```

Expected: Empty array `[]`

```bash
# Hub MGMT route table — must have 0.0.0.0/0 → DRG (Phase 2 adds this rule)
# This enables Bastion sessions to reach spoke Sim FW private IPs
oci network route-table list --vcn-id $HUB_VCN_ID \
  --query "data[?\"display-name\"=='RT-C1-R-ELZ-NW-MGMT'].{name:\"display-name\",rules:\"route-rules\"}" \
  | jq '.[].rules'
```

Expected: One rule, `destination: 0.0.0.0/0`, `networkEntityId: <hub_drg_id>`

---

### TC-12b — Inter E-W DRG Exists in C1_R_ELZ_NW (Run: after Phase 2)

`DRG-C1-R-ELZ-NW-EW` is provisioned in Sprint 2 with **zero attachments** in V1. It is the placeholder for Sprint 3 East-West inter-agency segmentation. Validate its existence now so Sprint 3 can attach without a separate apply to create the DRG itself.

```bash
oci network drg get \
  --drg-id $EW_HUB_DRG_ID \
  --query 'data.{name:"display-name", state:"lifecycle-state"}' | jq '.'
```

Expected: `"display-name": "DRG-C1-R-ELZ-NW-EW"`, `"lifecycle-state": "AVAILABLE"`

```bash
# Confirm zero attachments in V1
oci network drg-attachment list --drg-id $EW_HUB_DRG_ID --all | jq '.data | length'
```

Expected: `0`

---

### TC-13 — OCI Network Path Analyzer: POSITIVE — Spoke to Hub (Run: after TC-09)

NPA validates the OCI control plane path. No traffic is generated. No SSH needed.

Console: Networking → Network Command Center → Network Path Analyzer → Create Path Analysis

```bash
OS_APP_SUBNET="ocid1.subnet.oc1..aaa"   # terraform output os_app_subnet_id
HUB_FW_SUBNET="ocid1.subnet.oc1..aaa"   # terraform output hub_fw_subnet_id

oci network path-analyzer-test create \
  --protocol 1 \
  --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$OS_APP_SUBNET\"}" \
  --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$HUB_FW_SUBNET\"}" \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output)
```

Expected: Path hops show DRG transit. No `DROPPED` or `INDETERMINATE` status.

Repeat for: TS → Hub, SS → Hub, DEVT → Hub.

---

### TC-14 — OCI Network Path Analyzer: Spoke to Spoke via DRG (Run: after TC-13)

```bash
TS_APP_SUBNET="ocid1.subnet.oc1..aaa"   # terraform output ts_app_subnet_id

oci network path-analyzer-test create \
  --protocol 1 \
  --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$OS_APP_SUBNET\"}" \
  --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$TS_APP_SUBNET\"}" \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output)
```

Expected: Path shows OS → DRG → TS, status `REACHABLE`. **Known V1 behaviour:** DRG v2 full-mesh routes spoke-to-spoke traffic directly through the DRG fabric without transiting the Hub Sim FW. This is expected — log this observation, do not mark as FAIL. S3-BACKLOG-01 adds DRG route tables to force all E-W traffic via the Hub FW inspection point.

---

### TC-15 — Linux Sim FW Validation via Bastion SSH (Run: after TC-11 Bastion ACTIVE)

Validates cloud-init execution, IP forwarding, iptables rules, and basic connectivity. Requires a Bastion session.

**Step 1 — Create a Managed SSH session to Hub Sim FW**

OCI Console → Bastion → `BAS-C1-R-ELZ-NW-HUB` → Create Session → Managed SSH → Target: `FW-C1-R-ELZ-NW-HUB-SIM`

**Step 2 — Verify cloud-init completed**

```bash
cloud-init status --long
# Expected: status: done
# If "running": wait 30s, retry. If "error": sudo journalctl -u cloud-init | tail -50

sudo cat /var/log/star-elz-simfw-init.log
# Expected: "Sim FW bootstrap complete <timestamp>"
```

**Step 3 — Verify IP forwarding is active and persistent**

```bash
sysctl net.ipv4.ip_forward
# Expected: net.ipv4.ip_forward = 1

cat /etc/sysctl.d/99-ipforward.conf
# Expected: net.ipv4.ip_forward=1
```

**Step 4 — Verify iptables rules and NAT masquerade**

```bash
sudo iptables -t nat -L POSTROUTING -v -n
# Expected: MASQUERADE rule present on eth0

sudo systemctl is-enabled iptables
# Expected: enabled

sudo cat /etc/sysconfig/iptables | grep MASQUERADE
# Expected: -A POSTROUTING -o eth0 -j MASQUERADE
```

**Step 5 — Ping spoke Sim FWs via DRG**

```bash
ping -c 4 $OS_FW_IP    # OS Sim FW — 0% packet loss expected
ping -c 4 $TS_FW_IP    # TS Sim FW
ping -c 4 $SS_FW_IP    # SS Sim FW
```

**Step 6 — Traceroute — verify DRG transit hop**

```bash
traceroute -n $OS_FW_IP
# Expected: Hub FW gateway (10.0.0.1) → OCI SDN fabric (no IP) → OS Sim FW (10.1.0.X)
# Typically 2–3 hops. A direct 1-hop indicates routing bypass — investigate RT and DRG attachment.
```

**Step 7 — tcpdump — confirm packets traverse the FW interface**

```bash
sudo tcpdump -ni eth0 icmp
# While running, execute ping from Step 5 in a second terminal
# Expected: ICMP echo request/reply packets visible
```

---

### TC-16 — DEVT Verify Network-Only (No Compute) (Run: after Phase 2)

```bash
oci compute instance list \
  --compartment-id <devt_compartment_id> \
  --lifecycle-state RUNNING \
  | jq '.data | length'
```

Expected: `0`

---

### TC-17 — Zero Drift After Phase 2 (Run: after all TCs pass)

ORM → Sprint 2 Stack → Plan → confirm:

`Plan: 0 to add, 0 to change, 0 to destroy.`

If route tables show as changed — OCI sometimes reorders route rules internally; this is cosmetic. If any other resource shows drift, paste the plan output into the issue for diagnosis.

---

### TC-18 — NPA East-West: All Spoke Pairs via DRG (Run: after TC-09)

Validates E-W control plane reachability between every spoke pair. OCI DRG v2 full-mesh means all spoke-to-spoke paths exist in the DRG routing table without any additional configuration. NPA confirms each path traverses the DRG and is not dropped.

```bash
OS_APP_SUBNET="ocid1.subnet.oc1..aaa"    # terraform output os_app_subnet_id
TS_APP_SUBNET="ocid1.subnet.oc1..aaa"    # terraform output ts_app_subnet_id
SS_APP_SUBNET="ocid1.subnet.oc1..aaa"    # terraform output ss_app_subnet_id
DEVT_APP_SUBNET="ocid1.subnet.oc1..aaa"  # terraform output devt_app_subnet_id
HUB_MGMT_SUBNET="ocid1.subnet.oc1..aaa"  # terraform output hub_mgmt_subnet_id
TENANCY_ID=$(oci iam tenancy get --query 'data.id' --raw-output)

declare -A SUBNETS=(
  [OS]=$OS_APP_SUBNET
  [TS]=$TS_APP_SUBNET
  [SS]=$SS_APP_SUBNET
  [DEVT]=$DEVT_APP_SUBNET
)

# Test all 12 spoke-to-spoke directional pairs
for SRC in OS TS SS DEVT; do
  for DST in OS TS SS DEVT; do
    [ "$SRC" = "$DST" ] && continue
    echo "=== NPA: $SRC → $DST ==="
    oci network path-analyzer-test create \
      --protocol 1 \
      --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"${SUBNETS[$SRC]}\"}" \
      --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"${SUBNETS[$DST]}\"}" \
      --compartment-id $TENANCY_ID \
      --query 'data.result."path-analysis-result"' --raw-output
  done
done
```

Expected for each pair: `REACHABLE`. Path hops show DRG transit — not a direct VCN-to-VCN connection. Record all 12 results in the Sprint 2 issue for the Sprint 3 handoff.

```bash
# Also validate Hub MGMT → each spoke (confirms Bastion can reach spoke Sim FWs)
for DST in OS TS SS DEVT; do
  echo "=== NPA: Hub MGMT → $DST ==="
  oci network path-analyzer-test create \
    --protocol 1 \
    --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$HUB_MGMT_SUBNET\"}" \
    --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"${SUBNETS[$DST]}\"}" \
    --compartment-id $TENANCY_ID \
    --query 'data.result."path-analysis-result"' --raw-output
done
```

Expected: All 4 Hub MGMT → spoke paths `REACHABLE`.

---

### TC-19 — Data Plane East-West: Hub Sim FW ↔ Spoke Sim FWs (Run: after TC-11 Bastion ACTIVE)

Validates actual packet flow between hub and spokes using the Bastion session from TC-15. All E-W tests originate from the Hub Sim FW — the Hub MGMT RT has `0.0.0.0/0 → DRG` so the Bastion can reach the Hub Sim FW, and from there packets traverse the DRG to each spoke.

Prerequisites: TC-15 Bastion session to `FW-C1-R-ELZ-NW-HUB-SIM` is active. `HUB_FW_IP`, `OS_FW_IP`, `TS_FW_IP`, `SS_FW_IP` are set from the shell variable block above.

**Step 1 — Ping all three spoke Sim FWs from Hub**

```bash
# From the Bastion SSH session on Hub Sim FW
echo "=== Hub → OS ==="  && ping -c 4 -W 2 $OS_FW_IP
echo "=== Hub → TS ==="  && ping -c 4 -W 2 $TS_FW_IP
echo "=== Hub → SS ==="  && ping -c 4 -W 2 $SS_FW_IP
```

Expected: `0% packet loss` on all three. If a ping fails — check DRG attachment state (TC-09) and spoke RT rules (TC-12) before looking at the Linux OS firewall. 99% of routing failures in OCI are in the route table or DRG, not iptables.

**Step 2 — Traceroute hub → each spoke (verify DRG fabric hop)**

```bash
traceroute -n -m 5 $OS_FW_IP
# Expected hops:
#  1  10.0.0.1          Hub FW subnet OCI gateway
#  2  (no IP shown)     OCI DRG fabric / SDN transit
#  3  10.1.0.X          OS Sim FW private IP
# More than 3 hops: unexpected — investigate.
# Only 1 hop direct to 10.1.x: DRG bypass — check DRG attachment and RT next-hop.

traceroute -n -m 5 $TS_FW_IP
traceroute -n -m 5 $SS_FW_IP
```

**Step 3 — tcpdump on Hub FW — confirm bidirectional ICMP across eth0**

```bash
# Terminal 1: start capture on Hub Sim FW
sudo tcpdump -ni eth0 icmp -v

# Terminal 2 (same Bastion session in a new tab): run ping to OS
ping -c 4 $OS_FW_IP

# Terminal 1 expected: ICMP echo requests to 10.1.0.X and replies from 10.1.0.X
# This confirms packets physically traverse the Hub FW ethernet interface
# (not just the OCI control plane)
```

**Step 4 — TCP port test — confirm routing works for real application traffic**

```bash
# Test TCP port 22 (SSH daemon) reachability to each spoke Sim FW
nc -zv $OS_FW_IP 22
nc -zv $TS_FW_IP 22
nc -zv $SS_FW_IP 22
# Expected: Connection to <IP> 22 port [tcp/ssh] succeeded!

# If nc not available:
bash -c "</dev/tcp/$OS_FW_IP/22" && echo "OS :22 OPEN" || echo "OS :22 CLOSED"
bash -c "</dev/tcp/$TS_FW_IP/22" && echo "TS :22 OPEN" || echo "TS :22 CLOSED"
bash -c "</dev/tcp/$SS_FW_IP/22" && echo "SS :22 OPEN" || echo "SS :22 CLOSED"
```

**Step 5 — Document E-W DRG v2 full-mesh observation**

```
Spoke-to-spoke traffic (e.g. OS → TS) takes the shortest DRG path: OS subnet RT
sends 0.0.0.0/0 to DRG, DRG full-mesh routes directly to TS — without transiting
the Hub FW subnet. This is confirmed by NPA in TC-18 showing spoke→spoke paths
not passing through 10.0.0.0/24.

This is expected V1 behaviour. Hub Sim FW inspects hub↔spoke traffic only.
Spoke↔spoke inspection via Hub FW requires DRG route tables (S3-BACKLOG-01).

Record in Sprint 2 issue:
  "DRG v2 full-mesh confirmed: all 12 spoke↔spoke NPA paths REACHABLE via DRG (TC-18 PASS)
   Hub↔spoke data plane: ping/traceroute/tcpdump/TCP PASS (TC-19 PASS)
   Hub FW not in spoke↔spoke data path — S3-BACKLOG-01 logged"
```

---

## Adding a 5th Spoke

### V1 Flat-File Pattern (Sprint 2 approach — use this now)

Sprint 2 uses direct resource definitions, not modules. This is intentional — every engineer reads exactly what is provisioned without navigating module interfaces. Adding a 5th spoke requires changes in exactly 4 files, nothing else:

```
1.  sprint1/iam_cmps_team<N>.tf    — add compartment C1_<AGENCY>_ELZ_NW
2.  sprint1/iam_groups_team<N>.tf  — add group UG_<AGENCY>_ELZ_NW
3.  sprint1/iam_policies_team<N>.tf — grant VCN management to new group
4.  sprint2/nw_team<N>.tf          — copy nw_team1.tf, replace all "os" / "OS" with new agency name
```

The Hub DRG (`DRG-C1-R-ELZ-NW-HUB`) accepts additional VCN attachments with zero changes to any other team file. All naming constants go into `locals.tf` following the existing pattern. The phase2 gate (`count = local.phase2_enabled ? 1 : 0`) is already inherited by copying the team1 pattern.

> All 4 files live in the same `sprint2/` directory — this is required. Terraform builds one dependency graph across all `nw_teamN.tf` files, which means Team 4's DRG is guaranteed to exist before any spoke RT references `var.hub_drg_id`. Do not split into separate folders or separate Terraform workspaces — that breaks the automatic dependency graph and spoke route tables will fail with "DRG not found."

### Sprint 3+ Module Pattern (for production and scale)

Once the spoke count exceeds 4 or onboarding becomes repetitive, extract into a reusable module. A spoke module accepts these inputs:

```hcl
# sprint3/modules/spoke/variables.tf
variable "agency"           {}  # "OS", "TS", "NEWAGENCY" — drives all resource display names
variable "compartment_id"   {}  # from Sprint 1 terraform output
variable "vcn_cidr"         {}  # e.g. "10.5.0.0/24"
variable "app_subnet_cidr"  {}  # e.g. "10.5.0.0/24"
variable "hub_drg_id"       {}  # Phase 2 gate — empty = Phase 1 only
variable "sim_fw_enabled"   { default = true }
variable "common_defined_tags" {}
variable "common_freeform_tags" {}
```

Onboarding a new agency then becomes 10 lines in the calling file:

```hcl
# sprint3/nw_team5.tf
module "spoke_newagency" {
  source                = "./modules/spoke"
  agency                = "NEWAGENCY"
  compartment_id        = var.newagency_compartment_id
  vcn_cidr              = "10.5.0.0/24"
  app_subnet_cidr       = "10.5.0.0/24"
  hub_drg_id            = var.hub_drg_id
  sim_fw_enabled        = true
  common_defined_tags   = local.net_defined_tags
  common_freeform_tags  = local.net_freeform_tags
}
```

All naming conventions, tagging, DRG attachment, route table `depends_on`, and cloud-init are encapsulated inside the module. Every new agency is identical boilerplate — consistent, auditable, and testable.

> ⚠️ **Do not convert Sprint 2 flat resources to modules mid-sprint.** Terraform tracks state by resource address. `oci_core_vcn.os` and `module.spoke_os.oci_core_vcn.main` are different addresses. Converting without `terraform state mv` causes Terraform to destroy and recreate every resource. Perform the module extraction as a dedicated Sprint 3 refactor task with a full plan review before apply.

---

## C0/C1 Naming Convention — Sprint 2 Network Resources

| Resource Type | Pattern | Example |
|---|---|---|
| VCN | `VCN-C1-<AGENCY>-ELZ-NW[-HUB]` | `VCN-C1-R-ELZ-NW-HUB` |
| Subnet | `SUB-C1-<AGENCY>-ELZ-NW-<FUNCTION>` | `SUB-C1-R-ELZ-NW-FW` |
| DRG | `DRG-C1-R-ELZ-NW-<QUALIFIER>` | `DRG-C1-R-ELZ-NW-HUB` |
| Route Table | `RT-C1-<AGENCY>-ELZ-NW-<FUNCTION>` | `RT-C1-OS-ELZ-NW-APP` |
| Sim FW Instance | `FW-C1-<AGENCY>-ELZ-NW[-HUB]-SIM` | `FW-C1-OS-ELZ-NW-SIM` |
| Bastion | `BAS-C1-R-ELZ-NW-HUB` | — |
| DRG Attachment | `DRGA-C1-<AGENCY>-ELZ-NW` | `DRGA-C1-OS-ELZ-NW` |

---

## Known Design Decisions

**No Internet Gateway in V1** — Per V1 isolated design (Han Kiat review, 27 Feb 2026). All validation is via NPA and Bastion SSH. Internet-facing routing is Sprint 3+ scope.

**Phase 2 gate** — `local.phase2_enabled = var.hub_drg_id != ""` controls all Phase 2 resources via `count`. The two-phase dependency is explicit and visible at plan time without requiring separate workspaces or state files.

**Sim Firewall (Oracle Linux 8, E4.Flex)** — Single VNIC per instance. `skip_source_dest_check = true` enables OCI-level packet forwarding. cloud-init installs `iptables-services` and persists `net.ipv4.ip_forward=1` via `/etc/sysctl.d/99-ipforward.conf`. `firewalld` is intentionally not used — it conflicts with `iptables-services` on OL8. Interface `eth0` is the E4.Flex primary NIC.

**DEVT spoke** — no Sim FW in V1. Network-only. Gets DRG attachment and route table to participate in hub-and-spoke routing. Compute workloads Sprint 4+.

**DNS labels in locals.tf** — All `dns_label` strings are defined in `locals.tf` and referenced via `local.*_dns_label` in team files. Enforces the 2-hop single-source-of-truth pattern from Sprint 1.

**Hub FW route table is empty in V1** — Intentional placeholder. Sprint 3 adds DRG transit route distribution. See S3-BACKLOG-01 below.

**DRG v2 full-mesh** — OCI DRG v2 defaults to full-mesh routing between all attached VCNs. Spoke-to-spoke traffic is routable right now (validated by TC-18 and TC-19) but bypasses the Hub Sim FW. S3-BACKLOG-01 adds `oci_core_drg_route_table` to steer all E-W traffic via the Hub FW inspection point. TC-14 and TC-18 acknowledge this is expected V1 behaviour.

**Flat file structure — no modules in Sprint 2** — Each team owns one `nw_teamN.tf` with direct resource definitions. All files in one directory give Terraform a single dependency graph. See "Adding a 5th Spoke" section for the Sprint 3 module migration path.

---

## Sprint 3 Backlog

These items are logged here only — do not implement in sprint2.

### S3-BACKLOG-01 — DRG Transit Routing (Architecture Gap — Priority High)

**Problem:** OCI DRG v2 full-mesh means OS→TS traffic transits the DRG directly without passing the Hub Sim FW. Hub FW inspection of spoke-to-spoke traffic is not active in V1.

**Fix in Sprint 3:**

1. Create `oci_core_drg_route_table` in `nw_team4.tf`
2. Create `oci_core_drg_route_distribution` to steer all spoke attachment traffic via Hub VCN attachment
3. Create a VCN Ingress Route Table on the Hub VCN to forward DRG-arriving traffic to the Sim FW VNIC private IP
4. Update all spoke DRG attachments to reference the new DRG route table

Files: `nw_team4.tf` (primary), `nw_team1.tf`, `nw_team2.tf`, `nw_team3.tf` (DRG attachment updates)

### S3-BACKLOG-02 — DNS Labels Single Source of Truth (Tech Debt — Priority Low)

**Status:** RESOLVED in sprint2. DNS labels moved to `locals.tf` dns_label block. No remaining hardcoded `dns_label` strings in team files.

---

## Sprint 2 → Sprint 3 Handoff Checklist

- [ ] TC-07: 5 VCNs created PASS
- [ ] TC-08: 6 subnets created — all private PASS
- [ ] TC-09: Hub DRG 5 attachments ATTACHED PASS
- [ ] TC-10: 4 Sim FW instances RUNNING + skip_source_dest_check verified PASS
- [ ] TC-11: Hub Bastion ACTIVE PASS
- [ ] TC-12: Route tables correct (spokes → DRG, hub FW empty, hub MGMT → DRG) PASS
- [ ] TC-12b: DRG-C1-R-ELZ-NW-EW exists · AVAILABLE · 0 attachments PASS
- [ ] TC-13: NPA POSITIVE spoke to hub PASS
- [ ] TC-14: NPA spoke-to-spoke via DRG — full-mesh behaviour documented PASS
- [ ] TC-15: Linux Sim FW — cloud-init done, ip_forward=1, iptables masquerade, ping/traceroute/tcpdump PASS
- [ ] TC-16: DEVT no compute PASS
- [ ] TC-17: ORM Plan zero drift PASS
- [ ] TC-18: NPA E-W — all 12 spoke-pair paths REACHABLE via DRG, all 4 hub-MGMT→spoke paths REACHABLE PASS
- [ ] TC-19: Data plane E-W — hub↔spoke ping, traceroute, tcpdump, TCP port 22 PASS, DRG bypass documented PASS
- [ ] `terraform output -json > sprint2_outputs.json` exported and shared with Sprint 3 lead
- [ ] Git tag `sprint2-complete` pushed to main
- [ ] State Book V2_Validation TC-07 through TC-19 updated: PASS/FAIL/date
- [ ] Sprint 3 Backlog S3-BACKLOG-01 (DRG Transit Routing) issue created in repo

---

## Changelog

### sprint2 — 27 Feb 2026 (Amit, post Han Kiat review)

| # | Change | File(s) | Reason |
|---|---|---|---|
| C1 | Renamed `net_main.tf` → `nw_main.tf` | `nw_main.tf` | Standardise filename with `nw_teamX.tf` convention (Han Kiat) |
| C2 | Removed `oci_core_internet_gateway.hub` resource entirely | `nw_team4.tf` | IGW not in V1 isolated design (Han Kiat) |
| C3 | Removed `route_rules` from `oci_core_route_table.hub_fw` — empty RT placeholder | `nw_team4.tf` | Follows from C2 — no IGW target (Han Kiat) |
| C4 | Changed `assign_public_ip = true` → `false` on `sim_fw_hub` | `nw_team4.tf` | No public IP without IGW (Han Kiat) |
| C5 | Changed hub FW subnet to `prohibit_public_ip_on_vnic = true` | `nw_team4.tf` | Consistent with private-only V1 design |
| C6 | Removed `hub_igw_name` constant | `locals.tf` | IGW removed — constant no longer needed |
| C7 | Added DNS label constants block to `locals.tf` | `locals.tf` | Enforce 2-hop single-source-of-truth (Han Kiat, resolves S3-BACKLOG-02 early) |
| C8 | Replaced all hardcoded `dns_label` strings with `local.*_dns_label` refs | `nw_team1.tf`, `nw_team2.tf`, `nw_team3.tf`, `nw_team4.tf` | Follows from C7 |
| C9 | Updated cloud-init from `firewalld` to `iptables-services` approach | `locals.tf` | Oracle Linux 8 — `firewalld` conflicts with `iptables-services` |
| C10 | Updated cloud-init persistence: `/etc/sysctl.d/99-ipforward.conf` + `service iptables save` | `locals.tf` | Survives reboot; previously runtime only |
| C11 | Removed sprint freeform tag `v2-networking` → `sprint2-networking` | `locals.tf` | Clean version nomenclature (Han Kiat) |
| C12 | Renamed `sprint1-solutions-v2` → `sprint1` in README sprint table | `README.md` | Clean version nomenclature (Han Kiat) |
| C13 | Added TC → Phase mapping table to README | `README.md` | Teams need to know which TCs to run after Phase 1 vs Phase 2 (Han Kiat) |
| C14 | Added NPA scope note to TC section | `README.md` | Clarify NPA validates OCI control plane only; Linux-side needs Bastion SSH |
| C15 | Expanded TC-15 with cloud-init status, sysctl, iptables-services, tcpdump steps | `README.md` | Practical Linux-level validation via Bastion SSH |
| C16 | Updated TC-14 NPA negative to note DRG full-mesh is expected at this stage | `README.md` | Honest about known gap; logged as S3-BACKLOG-01 |
| C17 | Added Sprint 3 Backlog section (DRG transit routing, DNS labels) | `README.md` | Document known gaps for sprint3 |
| C18 | Updated git tag from `v2-sprint2-complete` → `sprint2-complete` | `README.md` | Clean version nomenclature (Han Kiat) |
| C19 | Updated `nw_main.tf` architecture diagram — removed IGW line | `nw_main.tf` | Diagram must match V1 isolated design |
| C20 | Added DRG full-mesh sprint3 backlog note to `nw_main.tf` and `nw_team4.tf` | `nw_main.tf`, `nw_team4.tf` | Document known gap inline |

### sprint2 — 28 Feb 2026 (Amit, post Feb 28 audit)

| # | Change | File(s) | Reason |
|---|---|---|---|
| C21 | Changed spoke VCN CIDR defaults `/16` → `/24` | `variables_net.tf`, `locals.tf`, `schema.yaml`, `terraform.tfvars.template`, `nw_main.tf` | GAP-01: architecture specifies /24 for spokes; /16 defaults caused ORM UI drift from deployed resources |
| C22 | Added `oci_core_drg.ew_hub` resource (`DRG-C1-R-ELZ-NW-EW`) | `nw_team4.tf` | GAP-02: architecture shows 2 DRGs in C1_R_ELZ_NW; E-W DRG was missing; V2 placeholder, 0 attachments in V1 |
| C23 | Added `ew_hub_drg_name = "DRG-C1-R-ELZ-NW-EW"` constant | `locals.tf` | Single source of truth — all display names defined in locals.tf |
| C24 | Added `ew_hub_drg_id` output | `outputs.tf` | TC-12b needs the OCID; Sprint 3 DRG attachment work requires this output at handoff |
| C25 | Removed contradictory `"Public IP — simulates north-south FW"` comment from `sim_fw_hub` | `nw_team4.tf` | Stale from before C2/C4; `assign_public_ip = false` is correct; comment contradicted live code |
| C26 | Added TC-12b (E-W DRG validation), TC-18 (NPA E-W all spoke pairs), TC-19 (data plane E-W) | `README.md` | E-W routing is testable in V1 via DRG v2 full-mesh; validation suite now covers all paths |
| C27 | Added `EW_HUB_DRG_ID` to TC shell variable block | `README.md` | TC-12b requires the OCID; omission caused unbound variable error |
| C28 | Added `get_private_ip` helper and Sim FW IP variables to TC preamble | `README.md` | TC-19 requires Sim FW private IPs; OCI assigns dynamically, no static output available |
| C29 | Added Hub MGMT RT rule verification to TC-12 | `README.md` | RT-C1-R-ELZ-NW-MGMT gets 0.0.0.0/0 → DRG in Phase 2; needed for Bastion→spoke reachability |
| C30 | Added "Adding a 5th Spoke" section with V1 flat pattern and Sprint 3 module pattern | `README.md` | Documents onboarding path for new agencies without mid-sprint module refactor risk |
| C31 | Replaced old text-only architecture diagram with full low-level network diagram | `README.md` | New diagram shows correct /24 CIDRs, all resource names, DRG fabric, E-W routing note, legend |
| C32 | Removed stale IGW row from naming convention table | `README.md` | IGW removed in C2; row implied IGW was provisioned |
