# STAR ELZ V1 — Sprint 2: Hub and Spoke Networking

**Branch:** `sprint2`
**Dates:** 2 Mar 2026 – 4 Mar 2026
**OCI Resources:** VCN, Subnet, DRG, Internet Gateway, Route Table, Sim Firewall (Compute), Bastion

---

## What This Is

Sprint 2 builds the network foundation for the STAR ELZ — a hub-and-spoke topology connecting the 5 VCNs (1 hub + 4 spokes) provisioned into the compartments created in Sprint 1.

| Sprint | Folder | Purpose |
|--------|--------|---------|
| `sprint1/` | IAM scaffold | Teams fork, compartments/groups/policies |
| `sprint1-solutions-v2/` | IAM solutions | Full solutions with all fixes |
| `sprint2/` | **This folder** | Networking scaffold — two-phase apply |

---

## Architecture — Hub and Spoke via DRG

```
C0 Tenancy Root
│
├── C1_R_ELZ_NW (T4 — Hub)           10.0.0.0/16
│     ├── SUB-FW    10.0.0.0/24      Sim Firewall (public, skip_source_dest_check=true)
│     ├── SUB-MGMT  10.0.1.0/24      Bastion (private)
│     ├── DRG-HUB ─────────────────── attached to all 5 VCNs (Phase 2)
│     └── IGW ─────────────────────── internet (north-south)
│
├── C1_OS_ELZ_NW (T1)                10.1.0.0/16
│     └── SUB-APP   10.1.0.0/24      Sim FW — RT: 0.0.0.0/0 → DRG
│
├── C1_TS_ELZ_NW (T2)                10.3.0.0/16
│     └── SUB-APP   10.3.0.0/24      Sim FW — RT: 0.0.0.0/0 → DRG
│
├── C1_SS_ELZ_NW (T3)                10.2.0.0/16
│     └── SUB-APP   10.2.0.0/24      Sim FW — RT: 0.0.0.0/0 → DRG
│
└── C1_DEVT_ELZ_NW (T3)              10.4.0.0/16
      └── SUB-APP   10.4.0.0/24      Network only (no Sim FW in V1)
```

---

## File Map

| File | Team | Description |
|------|------|-------------|
| `locals.tf` | — | All name constants, CIDR plan, phase2 gate, sim FW cloud-init |
| `variables_general.tf` | — | Tenancy, region, service_label, CIS level, tagging |
| `variables_iam.tf` | — | 10 compartment OCIDs from Sprint 1 outputs |
| `variables_net.tf` | — | CIDRs, hub_drg_id (Phase 2), Sim FW shape, Bastion CIDR |
| `data_sources.tf` | — | Regions, tenancy, ADs, OL8 images |
| `providers.tf` | — | OCI + OCI home providers, Terraform ≥ 1.3.0 |
| `net_main.tf` | — | Architecture doc + shared tag merge locals |
| `iam_sprint1_ref.tf` | — | READ ONLY — Sprint 1 IAM reference documentation |
| `nw_team1.tf` | **T1** | C1_OS_ELZ_NW — OS VCN, subnet, DRG attach, RT, Sim FW |
| `nw_team2.tf` | **T2** | C1_TS_ELZ_NW — TS VCN, subnet, DRG attach, RT, Sim FW |
| `nw_team3.tf` | **T3** | C1_SS_ELZ_NW + C1_DEVT_ELZ_NW — VCNs, subnets, DRG attaches, RTs, Sim FW (SS only) |
| `nw_team4.tf` | **T4** | C1_R_ELZ_NW — Hub VCN, FW+MGMT subnets, DRG, IGW, RTs, Sim FW, Bastion |
| `outputs.tf` | — | All VCN/subnet/DRG OCIDs, Sim FW IDs, Bastion ID |
| `schema.yaml` | — | ORM UI schema — 8 sections, hub_drg_id Phase 1/2 label |
| `terraform.tfvars.template` | — | Clean template — paste Sprint 1 OCIDs here |

---

## Sprint 2 Issue List

### VCN + Subnet (Phase 1)

| # | Task | Team | Start | Finish | Compartment | File |
|---|------|------|-------|--------|-------------|------|
| S2-T1 | Write & provision VCN + Subnet for OS compartment | T1 | 3/2/26 | 3/4/26 | C1_OS_ELZ_NW | nw_team1.tf |
| S2-T2 | Write & provision VCN + Subnet for TS compartment | T2 | 3/2/26 | 3/4/26 | C1_TS_ELZ_NW | nw_team2.tf |
| S2-T3 | Write & provision VCN + Subnet for SS + DEVT compartment | T3 | 3/2/26 | 3/4/26 | C1_SS_ELZ_NW + C1_DEVT_ELZ_NW | nw_team3.tf |
| S2-T4 | Write & provision VCN + Subnet + DRG for ELZ_NW compartment | T4 | 3/2/26 | 3/4/26 | C1_R_ELZ_NW | nw_team4.tf |

### Route Tables (Phase 2)

| # | Task | Team | Start | Finish | Compartment | File |
|---|------|------|-------|--------|-------------|------|
| S2-T1 | Write & provision Route Table for OS compartment | T1 | 3/2/26 | 3/4/26 | C1_OS_ELZ_NW | nw_team1.tf |
| S2-T2 | Write & provision Route Table for TS compartment | T2 | 3/2/26 | 3/4/26 | C1_TS_ELZ_NW | nw_team2.tf |
| S2-T3 | Write & provision Route Table for SS + DEVT compartment | T3 | 3/2/26 | 3/4/26 | C1_SS_ELZ_NW + C1_DEVT_ELZ_NW | nw_team3.tf |
| S2-T4 | Write & provision Route Table for ELZ_NW compartment | T4 | 3/2/26 | 3/4/26 | C1_R_ELZ_NW | nw_team4.tf |

### Sim Firewall (Phase 2)

| # | Task | Team | Start | Finish | Compartment | File |
|---|------|------|-------|--------|-------------|------|
| S2-T1 | Simulate compute / provision Firewall for OS compartment | T1 | 3/2/26 | 3/4/26 | C1_OS_ELZ_NW | nw_team1.tf |
| S2-T2 | Simulate compute / provision Firewall for TS compartment | T2 | 3/2/26 | 3/4/26 | C1_TS_ELZ_NW | nw_team2.tf |
| S2-T3 | Simulate compute / provision Firewall for SS compartment | T3 | 3/2/26 | 3/4/26 | C1_SS_ELZ_NW | nw_team3.tf |
| S2-T4 | Simulate compute / provision Firewall for ELZ_NW compartment | T4 | 3/2/26 | 3/4/26 | C1_R_ELZ_NW | nw_team4.tf |

### Bastion (Phase 2)

| # | Task | Team | Start | Finish | Compartment | File |
|---|------|------|-------|--------|-------------|------|
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

1. **All 4 teams** create a new ORM Stack pointing to `sprint2/` working directory
2. Paste all 10 compartment OCIDs into ORM Variables (Section 3) from `sprint1_outputs.json`
3. Leave `hub_drg_id` **empty** (Section 4)
4. Plan → Apply simultaneously (no inter-team dependency in Phase 1)

**T4 applies:** Hub VCN + FW subnet + MGMT subnet + DRG + IGW
**T1 applies:** OS VCN + OS app subnet
**T2 applies:** TS VCN + TS app subnet
**T3 applies:** SS VCN + SS app subnet + DEVT VCN + DEVT app subnet

5. **T4 runs after their apply:**

```bash
terraform output hub_drg_id
```

6. T4 shares the DRG OCID with all teams

### Phase 2 — Route Tables + Sim FW + Bastion

7. **All teams** update ORM Variables: paste `hub_drg_id` (Section 4)
8. **All 4 teams** Plan → Apply simultaneously
9. Phase 2 resources created: DRG attachments, route tables, Sim FW instances, Bastion

### After Phase 2 Apply

```bash
# Export all outputs for Sprint 3 Security lead
terraform output -json > sprint2_outputs.json

# Git tag
git tag v2-sprint2-complete
git push origin v2-sprint2-complete
```

---

## Test Cases — Sprint 2 Validation

Run all TCs in OCI Cloud Shell after Phase 2 apply. Set shell variables first:

```bash
# Paste from terraform output -json > sprint2_outputs.json
HUB_DRG_ID="ocid1.drg.oc1..aaa"
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
```

---

### TC-07 — 5 VCNs Created

```bash
oci network vcn list \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output) \
  --all \
  --query "data[?starts_with(\"display-name\", 'VCN-C1')]" \
  | jq '[.[] | {name: .["display-name"], cidr: .["cidr-blocks"][0]}]'
```

**Expected:** 5 entries — VCN-C1-R-ELZ-NW-HUB, VCN-C1-OS-ELZ-NW, VCN-C1-TS-ELZ-NW, VCN-C1-SS-ELZ-NW, VCN-C1-DEVT-ELZ-NW

```bash
# Count only
... | jq length
# Expected: 5
```

---

### TC-08 — 6 Subnets Created

```bash
# Check each VCN's subnets
for VCN_ID in $HUB_VCN_ID $OS_VCN_ID $TS_VCN_ID $SS_VCN_ID $DEVT_VCN_ID; do
  oci network subnet list --vcn-id $VCN_ID \
    --query "data[].{name:\"display-name\", cidr:\"cidr-block\", private:\"prohibit-public-ip-on-vnic\"}" \
    | jq '.[]'
done
```

**Expected:** 6 subnets total

| Subnet | CIDR | Public IPs |
|---|---|---|
| SUB-C1-R-ELZ-NW-FW | 10.0.0.0/24 | allowed (false=public) |
| SUB-C1-R-ELZ-NW-MGMT | 10.0.1.0/24 | prohibited (true=private) |
| SUB-C1-OS-ELZ-NW-APP | 10.1.0.0/24 | prohibited |
| SUB-C1-TS-ELZ-NW-APP | 10.3.0.0/24 | prohibited |
| SUB-C1-SS-ELZ-NW-APP | 10.2.0.0/24 | prohibited |
| SUB-C1-DEVT-ELZ-NW-APP | 10.4.0.0/24 | prohibited |

---

### TC-09 — Hub DRG Has 5 Attachments

```bash
oci network drg-attachment list \
  --drg-id $HUB_DRG_ID \
  --all \
  --query "data[].{name:\"display-name\", state:\"lifecycle-state\", type:\"network-details.type\"}" \
  | jq '.[]'
```

**Expected:** 5 attachments all in `ATTACHED` state — DRGA-C1-R-ELZ-NW-HUB, DRGA-C1-OS-ELZ-NW, DRGA-C1-TS-ELZ-NW, DRGA-C1-SS-ELZ-NW, DRGA-C1-DEVT-ELZ-NW

```bash
# Quick count
oci network drg-attachment list --drg-id $HUB_DRG_ID --all | jq '.data | length'
# Expected: 5
```

---

### TC-10 — 4 Sim FW Instances Running + skip_source_dest_check Verified

```bash
# Check lifecycle state for all 4 Sim FW instances
for INST_ID in $SIM_FW_HUB_ID $SIM_FW_OS_ID $SIM_FW_TS_ID $SIM_FW_SS_ID; do
  oci compute instance get --instance-id $INST_ID \
    --query 'data.{name:"display-name", state:"lifecycle-state"}' | jq '.'
done
```

**Expected:** All 4 show `"lifecycle-state": "RUNNING"`

```bash
# Verify skip_source_dest_check = true on each VNIC
# (Required for IP forwarding — if false, routing will silently fail)
for INST_ID in $SIM_FW_HUB_ID $SIM_FW_OS_ID $SIM_FW_TS_ID $SIM_FW_SS_ID; do
  VNIC_ATTACH=$(oci compute vnic-attachment list --instance-id $INST_ID \
    --query 'data[0].id' --raw-output)
  VNIC_ID=$(oci compute vnic-attachment get --vnic-attachment-id $VNIC_ATTACH \
    --query 'data."vnic-id"' --raw-output)
  oci network vnic get --vnic-id $VNIC_ID \
    --query 'data.{name:"display-name", skip_sdc:"skip-source-dest-check"}' | jq '.'
done
```

**Expected:** `"skip_sdc": true` on all 4 VNICs

---

### TC-11 — Hub Bastion Active

```bash
oci bastion bastion get \
  --bastion-id $HUB_BASTION_ID \
  --query 'data.{name:"name", state:"lifecycle-state", subnet:"target-subnet-id"}' \
  | jq '.'
```

**Expected:** `"lifecycle-state": "ACTIVE"`

---

### TC-12 — Route Tables Have Correct Rules

```bash
# Verify each spoke route table has the DRG default route
for VCN_ID in $OS_VCN_ID $TS_VCN_ID $SS_VCN_ID $DEVT_VCN_ID; do
  oci network route-table list --vcn-id $VCN_ID \
    --query "data[?starts_with(\"display-name\",'RT-C1')].{name:\"display-name\", rules:\"route-rules\"}" \
    | jq '.[].rules'
done
```

**Expected:** Each spoke RT has one rule: `destination: 0.0.0.0/0, networkEntityId: <hub_drg_id>`

```bash
# Hub FW route table should have IGW rule
oci network route-table list --vcn-id $HUB_VCN_ID \
  --query "data[?\"display-name\"=='RT-C1-R-ELZ-NW-FW'].{rules:\"route-rules\"}" \
  | jq '.[].rules'
# Expected: destination: 0.0.0.0/0 → internet gateway
```

---

### TC-13 — OCI Network Path Analyzer (POSITIVE — Spoke to Hub Reachability)

OCI Network Path Analyzer validates routing at the control plane — no traffic generated, no SSH needed. Run in OCI Console or CLI.

**Console path:** Networking → Network Command Center → Network Path Analyzer → Create Path Analysis

```bash
# CLI: verify OS spoke subnet can reach Hub FW subnet via DRG
# Get subnet OCIDs from outputs
OS_APP_SUBNET="ocid1.subnet.oc1..aaa"    # from terraform output os_app_subnet_id
HUB_FW_SUBNET="ocid1.subnet.oc1..aaa"   # from terraform output hub_fw_subnet_id

oci network network-security-group list || true  # confirm CLI access

# Create and run path analysis: OS spoke → Hub
oci network path-analyzer-test create \
  --protocol 1 \
  --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$OS_APP_SUBNET\"}" \
  --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$HUB_FW_SUBNET\"}" \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output)
```

**Expected result:** Path analysis shows forwarded hops — OS subnet → DRG → Hub FW subnet with no `DROPPED` or `INDETERMINATE` status.

Repeat for TS → Hub, SS → Hub, DEVT → Hub.

---

### TC-14 — OCI Network Path Analyzer (NEGATIVE — Spoke to Spoke Blocked)

Spokes should NOT be able to route directly to each other — all east-west must go via the Hub DRG and Sim FW.

```bash
# OS spoke → TS spoke should NOT have a direct path
# (DRG will route but there is no route rule allowing spoke-to-spoke bypass)
oci network path-analyzer-test create \
  --protocol 1 \
  --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$OS_APP_SUBNET\"}" \
  --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$TS_APP_SUBNET\"}" \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output)
```

**Expected result:** Traffic routed OS → DRG → Hub (correct). Verify it does NOT short-circuit from TS DRG attachment back to TS subnet without passing the hub FW subnet — this is the expected hub-and-spoke inspection point.

---

### TC-15 — Ping and Traceroute via Bastion Session (Sim FW to Sim FW)

This validates **data plane** connectivity end-to-end. Requires a Bastion SSH session.

**Step 1: Create a Bastion session to Hub Sim FW (via OCI Console)**

OCI Console → Bastion → BAS-C1-R-ELZ-NW-HUB → Create Session
- Session type: Managed SSH
- Target instance: FW-C1-R-ELZ-NW-HUB-SIM
- SSH key: paste your public key

**Step 2: Connect and test**

```bash
# Connect via Bastion tunnel (OCI Console provides the SSH command)
# Once connected to Hub Sim FW:

# Ping OS Sim FW private IP (from terraform output or OCI Console)
ping -c 4 10.1.0.X    # OS Sim FW private IP
# Expected: 4 packets transmitted, 4 received, 0% packet loss

# Ping TS Sim FW
ping -c 4 10.3.0.X    # TS Sim FW private IP
# Expected: success

# Ping SS Sim FW
ping -c 4 10.2.0.X    # SS Sim FW private IP
# Expected: success
```

**Step 3: Traceroute — verify traffic traverses DRG (not direct)**

```bash
# From Hub Sim FW → OS Sim FW
traceroute 10.1.0.X
# Expected path: Hub FW (10.0.0.X) → DRG hop (no visible IP, OCI fabric) → OS Sim FW (10.1.0.X)
# Hop count: typically 2-3 hops. A direct 1-hop would indicate routing bypass (fail).

# From Hub Sim FW → TS Sim FW
traceroute 10.3.0.X

# From Hub Sim FW → SS Sim FW
traceroute 10.2.0.X
```

**Step 4: Create a Bastion session to OS Sim FW and test spoke-to-spoke via hub**

```bash
# From OS Sim FW → TS Sim FW (should route via hub DRG, not directly)
traceroute 10.3.0.X
# Expected: traffic leaves OS (10.1.0.X) → DRG → Hub → DRG → TS (10.3.0.X)
# If traceroute shows direct 1-hop to TS — routing is bypassing hub (fail)
```

---

### TC-16 — Ping NEGATIVE (DEVT No Sim FW — Verify Network-Only)

DEVT spoke has no Sim FW instance in V1. Verify the subnet exists and route table is correct but no compute is running there.

```bash
# Verify no instances in DEVT compartment
oci compute instance list \
  --compartment-id <devt_compartment_id> \
  --lifecycle-state RUNNING \
  | jq '.data | length'
# Expected: 0
```

---

### TC-17 — Zero Drift After Phase 2

ORM → Sprint 2 Stack → Plan → confirm output is:

```
Plan: 0 to add, 0 to change, 0 to destroy.
```

If any resource shows as changed — check for tag propagation timing on defined tags (wait 30 seconds and re-plan). If still showing changes, paste plan output here for diagnosis.

---

## C0/C1 Naming Convention — Sprint 2 Network Resources

| Resource Type | Pattern | Example |
|---|---|---|
| VCN | `VCN-C1-<AGENCY>-ELZ-NW[-HUB]` | `VCN-C1-R-ELZ-NW-HUB` |
| Subnet | `SUB-C1-<AGENCY>-ELZ-NW-<FUNCTION>` | `SUB-C1-R-ELZ-NW-FW` |
| DRG | `DRG-C1-R-ELZ-NW-HUB` | — |
| IGW | `IGW-C1-R-ELZ-NW-HUB` | — |
| Route Table | `RT-C1-<AGENCY>-ELZ-NW-<FUNCTION>` | `RT-C1-OS-ELZ-NW-APP` |
| Sim FW Instance | `FW-C1-<AGENCY>-ELZ-NW[-HUB]-SIM` | `FW-C1-OS-ELZ-NW-SIM` |
| Bastion | `BAS-C1-R-ELZ-NW-HUB` | — |
| DRG Attachment | `DRGA-C1-<AGENCY>-ELZ-NW` | `DRGA-C1-OS-ELZ-NW` |

---

## Known Design Decisions

**Phase 2 gate** — `local.phase2_enabled = var.hub_drg_id != ""` controls all Phase 2 resources via `count`. This is intentional — it makes the two-phase dependency explicit and visible at plan time without requiring separate Terraform workspaces.

**Sim Firewall** — `oci_core_instance` with `skip_source_dest_check = true` and cloud-init enabling `net.ipv4.ip_forward = 1`. Not a production firewall — validates routing topology before Sprint 3 security layer.

**DEVT spoke** — no Sim FW in V1. DEVT is network-only. Compute workloads in Sprint 4+. DEVT gets DRG attachment and route table to participate in hub-and-spoke routing.

**Hub FW subnet** — public (`prohibit_public_ip_on_vnic = false`). Sim FW in hub requires public IP for north-south NAT simulation. All spoke subnets are private.

**Cloud Guard data source** — intentionally omitted (fails plan on fresh tenancies). See `data_sources.tf` for note.

---

## Sprint 2 → Sprint 3 Handoff Checklist

- [ ] TC-07: 5 VCNs created PASS
- [ ] TC-08: 6 subnets created PASS
- [ ] TC-09: Hub DRG 5 attachments PASS
- [ ] TC-10: 4 Sim FW instances RUNNING PASS
- [ ] TC-11: Hub Bastion ACTIVE PASS
- [ ] TC-12: ORM Plan zero drift PASS
- [ ] `terraform output -json > sprint2_outputs.json` exported and shared with Sprint 3 lead
- [ ] Git tag `v2-sprint2-complete` pushed to main
- [ ] State Book V2_Validation TC-07 through TC-12 updated: PASS/FAIL/date
