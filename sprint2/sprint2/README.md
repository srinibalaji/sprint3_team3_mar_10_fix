# STAR ELZ V1 — Sprint 2: Hub and Spoke Networking

**Branch:** `sprint2`
**Dates:** 2 Mar 2026 – 4 Mar 2026
**OCI Resources:** VCN, Subnet, DRG, Route Table, Sim Firewall (Compute), Bastion

---

## What This Is

Sprint 2 builds the network foundation for the STAR ELZ — a hub-and-spoke topology connecting 5 VCNs (1 hub + 4 spokes) provisioned into the compartments created in Sprint 1. This is a **V1 isolated design** — no internet gateway, no public IPs. All validation uses OCI NPA (control plane) and Bastion SSH sessions (data plane).

| Sprint | Folder | Purpose |
|--------|--------|---------|
| `sprint1/` | IAM scaffold | Teams fork, compartments/groups/policies |
| `sprint1-solutions/` | IAM solutions | Full solutions with all fixes |
| `sprint2/` | **This folder** | Networking — two-phase apply |

---

## Architecture — Hub and Spoke via DRG (V1 Isolated)

```
C0 Tenancy Root
│
├── C1_R_ELZ_NW (T4 — Hub)           10.0.0.0/16
│     ├── SUB-FW    10.0.0.0/24      Sim FW (private, no public IP, skip_source_dest_check=true)
│     ├── SUB-MGMT  10.0.1.0/24      Bastion (private)
│     └── DRG-HUB ─────────────────── attached to all 5 VCNs (Phase 2)
│
├── C1_OS_ELZ_NW (T1)                10.1.0.0/16
│     └── SUB-APP   10.1.0.0/24      Sim FW | RT: 0.0.0.0/0 → DRG
│
├── C1_TS_ELZ_NW (T2)                10.3.0.0/16
│     └── SUB-APP   10.3.0.0/24      Sim FW | RT: 0.0.0.0/0 → DRG
│
├── C1_SS_ELZ_NW (T3)                10.2.0.0/16
│     └── SUB-APP   10.2.0.0/24      Sim FW | RT: 0.0.0.0/0 → DRG
│
└── C1_DEVT_ELZ_NW (T3)              10.4.0.0/16
      └── SUB-APP   10.4.0.0/24      Network only (no Sim FW in V1) | RT: 0.0.0.0/0 → DRG
```

---

## File Map

| File | Team | Description |
|------|------|-------------|
| `locals.tf` | — | All name constants, DNS label constants, CIDR plan, phase2 gate, sim FW cloud-init |
| `variables_general.tf` | — | Tenancy, region, service_label, CIS level, tagging |
| `variables_iam.tf` | — | 10 compartment OCIDs from Sprint 1 outputs |
| `variables_net.tf` | — | CIDRs, hub_drg_id (Phase 2), Sim FW shape, Bastion CIDR |
| `data_sources.tf` | — | Regions, tenancy, ADs, OL8 images |
| `providers.tf` | — | OCI + OCI home providers, Terraform ≥ 1.3.0 |
| `nw_main.tf` | — | Architecture doc + shared tag merge locals |
| `iam_sprint1_ref.tf` | — | READ ONLY — Sprint 1 IAM reference documentation |
| `nw_team1.tf` | **T1** | C1_OS_ELZ_NW — OS VCN, subnet, DRG attach, RT, Sim FW |
| `nw_team2.tf` | **T2** | C1_TS_ELZ_NW — TS VCN, subnet, DRG attach, RT, Sim FW |
| `nw_team3.tf` | **T3** | C1_SS_ELZ_NW + C1_DEVT_ELZ_NW — VCNs, subnets, DRG attaches, RTs, Sim FW (SS only) |
| `nw_team4.tf` | **T4** | C1_R_ELZ_NW — Hub VCN, FW+MGMT subnets, DRG, RTs, Sim FW (private), Bastion |
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

**T4 applies:** Hub VCN + FW subnet + MGMT subnet + DRG
**T1 applies:** OS VCN + OS app subnet
**T2 applies:** TS VCN + TS app subnet
**T3 applies:** SS VCN + SS app subnet + DEVT VCN + DEVT app subnet

> **Execute TC-07 and TC-08 immediately after Phase 1** — verify 5 VCNs and 6 subnets before proceeding.

5. **T4 runs after their apply:**

```bash
terraform output hub_drg_id
```

6. T4 shares the DRG OCID with all teams

### Phase 2 — Route Tables + Sim FW + Bastion

7. **All teams** update ORM Variables: paste `hub_drg_id` (Section 4)
8. **All 4 teams** Plan → Apply simultaneously
9. Phase 2 resources created: DRG attachments, route tables, Sim FW instances, Bastion

> **Execute TC-09 through TC-17 after Phase 2**

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

### NPA Scope — Read This First

**OCI Network Path Analyzer validates the OCI control plane** (route tables, DRG attachments, NSG/SL rules). It does not validate what happens inside the Linux instance — it cannot verify whether cloud-init ran, whether `net.ipv4.ip_forward=1` is set, or whether iptables rules are active.

Validation is therefore two layers:
- **TCs 07–12 and 13–14** = OCI control plane (NPA + CLI) — no SSH needed
- **TCs 15–16** = Linux data plane — requires Bastion SSH session

### When to Run Each TC

| Phase | Run After | TCs |
|---|---|---|
| Phase 1 | T4 output `hub_drg_id` confirmed | TC-07, TC-08 |
| Phase 2 | All teams have applied | TC-09, TC-10, TC-11, TC-12 |
| Phase 2 | After TC-09 confirmed | TC-13, TC-14 (NPA) |
| Phase 2 | After TC-11 Bastion ACTIVE | TC-15, TC-16 (SSH data plane) |
| Phase 2 | After all TCs pass | TC-17 (zero drift) |

---

Set shell variables first (run in OCI Cloud Shell):

```bash
# Paste from: terraform output -json > sprint2_outputs.json
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

### TC-07 — 5 VCNs Created *(Run: immediately after Phase 1)*

```bash
oci network vcn list \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output) \
  --all \
  --query "data[?starts_with(\"display-name\", 'VCN-C1')]" \
  | jq '[.[] | {name: .["display-name"], cidr: .["cidr-blocks"][0]}]'
```

**Expected:** 5 entries — VCN-C1-R-ELZ-NW-HUB, VCN-C1-OS-ELZ-NW, VCN-C1-TS-ELZ-NW, VCN-C1-SS-ELZ-NW, VCN-C1-DEVT-ELZ-NW

```bash
# Quick count — must be 5 before sharing hub_drg_id with other teams
... | jq length
```

---

### TC-08 — 6 Subnets Created *(Run: immediately after Phase 1)*

```bash
for VCN_ID in $HUB_VCN_ID $OS_VCN_ID $TS_VCN_ID $SS_VCN_ID $DEVT_VCN_ID; do
  oci network subnet list --vcn-id $VCN_ID \
    --query "data[].{name:\"display-name\", cidr:\"cidr-block\", private:\"prohibit-public-ip-on-vnic\"}" \
    | jq '.[]'
done
```

**Expected:** 6 subnets — all `"prohibit-public-ip-on-vnic": true` (all private, no public IPs in V1)

| Subnet | CIDR | Private |
|---|---|---|
| SUB-C1-R-ELZ-NW-FW | 10.0.0.0/24 | true |
| SUB-C1-R-ELZ-NW-MGMT | 10.0.1.0/24 | true |
| SUB-C1-OS-ELZ-NW-APP | 10.1.0.0/24 | true |
| SUB-C1-TS-ELZ-NW-APP | 10.3.0.0/24 | true |
| SUB-C1-SS-ELZ-NW-APP | 10.2.0.0/24 | true |
| SUB-C1-DEVT-ELZ-NW-APP | 10.4.0.0/24 | true |

---

### TC-09 — Hub DRG Has 5 Attachments *(Run: after Phase 2)*

```bash
oci network drg-attachment list \
  --drg-id $HUB_DRG_ID \
  --all \
  --query "data[].{name:\"display-name\", state:\"lifecycle-state\"}" \
  | jq '.[]'

# Quick count
oci network drg-attachment list --drg-id $HUB_DRG_ID --all | jq '.data | length'
```

**Expected:** 5 attachments, all `"lifecycle-state": "ATTACHED"`

---

### TC-10 — 4 Sim FW Instances Running + skip_source_dest_check Verified *(Run: after Phase 2)*

```bash
# Verify RUNNING state
for INST_ID in $SIM_FW_HUB_ID $SIM_FW_OS_ID $SIM_FW_TS_ID $SIM_FW_SS_ID; do
  oci compute instance get --instance-id $INST_ID \
    --query 'data.{name:"display-name", state:"lifecycle-state"}' | jq '.'
done
```

**Expected:** All 4 show `"lifecycle-state": "RUNNING"`

```bash
# Verify skip_source_dest_check = true on each VNIC
# If false, OCI will silently drop forwarded packets regardless of Linux config
for INST_ID in $SIM_FW_HUB_ID $SIM_FW_OS_ID $SIM_FW_TS_ID $SIM_FW_SS_ID; do
  ATTACH_ID=$(oci compute vnic-attachment list --instance-id $INST_ID \
    --query 'data[0].id' --raw-output)
  VNIC_ID=$(oci compute vnic-attachment get --vnic-attachment-id $ATTACH_ID \
    --query 'data."vnic-id"' --raw-output)
  oci network vnic get --vnic-id $VNIC_ID \
    --query 'data.{name:"display-name", skip_sdc:"skip-source-dest-check"}' | jq '.'
done
```

**Expected:** `"skip_sdc": true` on all 4 VNICs

---

### TC-11 — Hub Bastion Active *(Run: after Phase 2)*

```bash
oci bastion bastion get \
  --bastion-id $HUB_BASTION_ID \
  --query 'data.{name:"name", state:"lifecycle-state"}' | jq '.'
```

**Expected:** `"lifecycle-state": "ACTIVE"`

---

### TC-12 — Route Tables Have Correct Rules *(Run: after Phase 2)*

```bash
# Spoke route tables: each must have exactly one rule — 0.0.0.0/0 → Hub DRG
for VCN_ID in $OS_VCN_ID $TS_VCN_ID $SS_VCN_ID $DEVT_VCN_ID; do
  oci network route-table list --vcn-id $VCN_ID \
    --query "data[?starts_with(\"display-name\",'RT-C1')].{name:\"display-name\",rules:\"route-rules\"}" \
    | jq '.[].rules'
done
```

**Expected:** Each spoke RT has one rule: `destination: 0.0.0.0/0, networkEntityId: <hub_drg_id>`

```bash
# Hub FW route table should be EMPTY in V1 (no IGW, Sprint 3 adds DRG transit)
oci network route-table list --vcn-id $HUB_VCN_ID \
  --query "data[?\"display-name\"=='RT-C1-R-ELZ-NW-FW'].{name:\"display-name\",rules:\"route-rules\"}" \
  | jq '.[].rules'
```

**Expected:** Empty array `[]` for hub FW route table

---

### TC-13 — OCI Network Path Analyzer: POSITIVE — Spoke to Hub *(Run: after TC-09)*

NPA validates the OCI control plane path. No traffic is generated. No SSH needed.

**Console path:** Networking → Network Command Center → Network Path Analyzer → Create Path Analysis

```bash
OS_APP_SUBNET="ocid1.subnet.oc1..aaa"   # from: terraform output os_app_subnet_id
HUB_FW_SUBNET="ocid1.subnet.oc1..aaa"   # from: terraform output hub_fw_subnet_id

# Test: OS spoke subnet → Hub FW subnet (should be forwarded via DRG)
oci network path-analyzer-test create \
  --protocol 1 \
  --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$OS_APP_SUBNET\"}" \
  --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$HUB_FW_SUBNET\"}" \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output)
```

**Expected:** Path shows hops forwarded via DRG. No `DROPPED` or `INDETERMINATE` status.

Repeat for: TS → Hub, SS → Hub, DEVT → Hub.

---

### TC-14 — OCI Network Path Analyzer: NEGATIVE — Spoke to Spoke *(Run: after TC-13)*

```bash
TS_APP_SUBNET="ocid1.subnet.oc1..aaa"   # from: terraform output ts_app_subnet_id

# OS spoke → TS spoke should route via hub DRG (not a direct path)
oci network path-analyzer-test create \
  --protocol 1 \
  --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$OS_APP_SUBNET\"}" \
  --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$TS_APP_SUBNET\"}" \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output)
```

**Expected:** Traffic routes OS → DRG → Hub. **Known Sprint 3 issue:** OCI DRG v2 full-mesh means spoke-to-spoke traffic currently transits the DRG without being inspected by the Hub Sim FW. This is expected and logged in the Sprint 3 Backlog — do not mark as a fail at this stage.

---

### TC-15 — Linux Sim FW Validation via Bastion SSH *(Run: after TC-11 Bastion ACTIVE)*

This validates the **Linux data plane** — cloud-init execution, IP forwarding, and iptables. Requires a Bastion session.

**Step 1: Create a Managed SSH session to Hub Sim FW**

OCI Console → Bastion → BAS-C1-R-ELZ-NW-HUB → Create Session → Managed SSH → Target: FW-C1-R-ELZ-NW-HUB-SIM

**Step 2: Verify cloud-init completed successfully**

```bash
# Check cloud-init ran without errors
cloud-init status --long
# Expected: status: done
# If "running" — cloud-init is still executing; wait 30s and retry
# If "error" — check: sudo journalctl -u cloud-init | tail -50

sudo cat /var/log/star-elz-simfw-init.log
# Expected: "Sim FW bootstrap complete <timestamp>"
```

**Step 3: Verify IP forwarding is active and persistent**

```bash
# Runtime check
sysctl net.ipv4.ip_forward
# Expected: net.ipv4.ip_forward = 1

# Persistence check (survives reboot)
cat /etc/sysctl.d/99-ipforward.conf
# Expected: net.ipv4.ip_forward=1
```

**Step 4: Verify iptables rules and NAT masquerade**

```bash
# Check NAT masquerade rule
sudo iptables -t nat -L POSTROUTING -v -n
# Expected: MASQUERADE rule on eth0 with packet/byte counters

# Check iptables service is enabled
sudo systemctl is-enabled iptables
# Expected: enabled

# Verify rules are saved for persistence
sudo cat /etc/sysconfig/iptables | grep MASQUERADE
# Expected: -A POSTROUTING -o eth0 -j MASQUERADE
```

**Step 5: Ping spoke Sim FWs via DRG**

```bash
# Get private IPs from OCI Console (Compute → Instances → VNIC → Private IP)
# OR from VCN Flow Logs once traffic is generated

ping -c 4 10.1.0.X    # OS Sim FW private IP
# Expected: 4 packets transmitted, 4 received, 0% packet loss

ping -c 4 10.3.0.X    # TS Sim FW private IP
ping -c 4 10.2.0.X    # SS Sim FW private IP
```

**Step 6: Traceroute — verify routing traverses DRG**

```bash
traceroute -n 10.1.0.X    # OS Sim FW
# Expected: Hub FW (10.0.0.X) → DRG fabric hop (no visible IP — OCI SDN) → OS Sim FW (10.1.0.X)
# Typically 2–3 hops. A direct 1-hop to OS subnet indicates routing bypass (investigate).
```

**Step 7: tcpdump — verify packets traverse the FW interface**

```bash
# On Hub Sim FW — watch traffic on eth0 while running ping from another terminal
sudo tcpdump -ni eth0 icmp
# Expected: ICMP echo request/reply packets visible when ping is active
```

---

### TC-16 — DEVT Verify Network-Only (No Compute) *(Run: after Phase 2)*

```bash
# No instances should be running in DEVT compartment in V1
oci compute instance list \
  --compartment-id <devt_compartment_id> \
  --lifecycle-state RUNNING \
  | jq '.data | length'
# Expected: 0
```

---

### TC-17 — Zero Drift After Phase 2 *(Run: after all TCs pass)*

ORM → Sprint 2 Stack → Plan → confirm:

```
Plan: 0 to add, 0 to change, 0 to destroy.
```

If route tables show as changed — OCI sometimes reorders route rules internally; this is cosmetic. If any other resource shows drift, paste the plan output into the issue for diagnosis.

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

**No Internet Gateway in V1** — Per V1 isolated design (Han Kiat review, 27 Feb 2026). All validation is via NPA and Bastion SSH. Internet-facing routing is Sprint 3+ scope.

**Phase 2 gate** — `local.phase2_enabled = var.hub_drg_id != ""` controls all Phase 2 resources via `count`. This makes the two-phase dependency explicit and visible at plan time without requiring separate workspaces.

**Sim Firewall (Oracle Linux 8, E4.Flex)** — Single VNIC per instance. `skip_source_dest_check = true` enables OCI-level packet forwarding. cloud-init installs `iptables-services` and persists `net.ipv4.ip_forward=1` via `/etc/sysctl.d/99-ipforward.conf`. `firewalld` is intentionally not used — it conflicts with `iptables-services` on OL8. Interface `eth0` is the E4.Flex primary NIC.

**DEVT spoke** — no Sim FW in V1. Network-only. Gets DRG attachment and route table to participate in hub-and-spoke routing. Compute workloads Sprint 4+.

**DNS labels in locals.tf** — All `dns_label` strings are defined in `locals.tf` and referenced via `local.*_dns_label` in team files. This enforces the 2-hop single-source-of-truth pattern from Sprint 1.

**Hub FW route table is empty in V1** — Intentional placeholder. Sprint 3 will add DRG transit routing distribution. See Sprint 3 Backlog below.

**DRG full-mesh known gap** — OCI DRG v2 defaults to full-mesh. Spoke-to-spoke traffic currently transits the DRG but is NOT inspected by the Hub Sim FW. Logged in Sprint 3 Backlog. TC-14 acknowledges this is expected at this stage.

---

## Sprint 3 Backlog

These items are **logged here only** — do not implement in sprint2.

### S3-BACKLOG-01 — DRG Transit Routing (Architecture Gap — Priority High)

**Problem:** OCI DRG v2 full-mesh means OS→TS traffic transits the DRG directly without passing the Hub Sim FW. This bypasses the intended inspection point.

**Fix in Sprint 3:**
- Create `oci_core_drg_route_table` in `nw_team4.tf`
- Create `oci_core_drg_route_distribution` to steer spoke attachment traffic via Hub VCN attachment
- Create a VCN Ingress Route Table on the Hub VCN to forward DRG-arriving traffic to the Sim FW VNIC private IP
- Update all spoke DRG attachments to reference the new DRG route table

**Files:** `nw_team4.tf` (primary), `nw_team1.tf`, `nw_team2.tf`, `nw_team3.tf` (DRG attachment updates)

### S3-BACKLOG-02 — DNS Labels Single Source of Truth (Tech Debt — Priority Low)

**Status:** RESOLVED in sprint2. DNS labels moved to `locals.tf` dns_label block. No remaining hardcoded dns_label strings in team files.

---

## Sprint 2 → Sprint 3 Handoff Checklist

- [ ] TC-07: 5 VCNs created PASS
- [ ] TC-08: 6 subnets created — all private PASS
- [ ] TC-09: Hub DRG 5 attachments ATTACHED PASS
- [ ] TC-10: 4 Sim FW instances RUNNING + skip_source_dest_check verified PASS
- [ ] TC-11: Hub Bastion ACTIVE PASS
- [ ] TC-12: Route tables correct (spokes → DRG, hub FW empty) PASS
- [ ] TC-13: NPA POSITIVE spoke to hub PASS
- [ ] TC-14: NPA NEGATIVE spoke to spoke — DRG full-mesh acknowledged PASS
- [ ] TC-15: Linux Sim FW — cloud-init done, ip_forward=1, iptables masquerade, ping/traceroute PASS
- [ ] TC-16: DEVT no compute PASS
- [ ] TC-17: ORM Plan zero drift PASS
- [ ] `terraform output -json > sprint2_outputs.json` exported and shared with Sprint 3 lead
- [ ] Git tag `sprint2-complete` pushed to main
- [ ] State Book V2_Validation TC-07 through TC-17 updated: PASS/FAIL/date
- [ ] Sprint 3 Backlog S3-BACKLOG-01 (DRG Transit Routing) issue created in repo

---

## Changelog

### sprint2 — 27 Feb 2026 (Amit, post Han Kiat review)

| # | Change | File(s) | Reason |
|---|--------|---------|--------|
| C1 | Renamed `net_main.tf` → `nw_main.tf` | `nw_main.tf` | Standardise filename with `nw_teamX.tf` convention (Han Kiat) |
| C2 | Removed `oci_core_internet_gateway.hub` resource entirely | `nw_team4.tf` | IGW not in V1 isolated design (Han Kiat) |
| C3 | Removed `route_rules` from `oci_core_route_table.hub_fw` — empty RT placeholder | `nw_team4.tf` | Follows from C2 — no IGW target (Han Kiat) |
| C4 | Changed `assign_public_ip = true` → `false` on `sim_fw_hub` | `nw_team4.tf` | No public IP needed without IGW (Han Kiat) |
| C5 | Changed hub FW subnet to `prohibit_public_ip_on_vnic = true` | `nw_team4.tf` | Consistent with private-only V1 design |
| C6 | Removed `hub_igw_name` constant | `locals.tf` | IGW removed — constant no longer needed |
| C7 | Added DNS label constants block to `locals.tf` | `locals.tf` | Enforce 2-hop single-source-of-truth (Han Kiat, Sprint 3 backlog S3-BACKLOG-02 resolved early) |
| C8 | Replaced all hardcoded `dns_label` strings with `local.*_dns_label` refs | `nw_team1.tf`, `nw_team2.tf`, `nw_team3.tf`, `nw_team4.tf` | Follows from C7 |
| C9 | Updated cloud-init from `firewalld` to `iptables-services` approach | `locals.tf` | Oracle Linux 8 correct — firewalld conflicts with iptables-services |
| C10 | Updated cloud-init persistence: `/etc/sysctl.d/99-ipforward.conf` + `service iptables save` | `locals.tf` | Survives reboot; previously only runtime |
| C11 | Removed `sprint` freeform tag `v2-networking` → `sprint2-networking` | `locals.tf` | Clean up version nomenclature (Han Kiat) |
| C12 | Renamed `sprint1-solutions-v2` → `sprint1-solutions` in README sprint table | `README.md` | Clean up version nomenclature (Han Kiat) |
| C13 | Added TC → Phase mapping table to README | `README.md` | Teams need to know which TCs to run after Phase 1 vs Phase 2 (Han Kiat) |
| C14 | Added NPA scope note to TC section | `README.md` | Clarify NPA validates OCI control plane only; Linux-side needs Bastion SSH |
| C15 | Expanded TC-15 with cloud-init status, sysctl, iptables-services, tcpdump steps | `README.md` | Practical Linux-level validation via Bastion SSH |
| C16 | Updated TC-14 NPA negative to note DRG full-mesh is expected at this stage | `README.md` | Honest about known gap; logged as S3-BACKLOG-01 |
| C17 | Added Sprint 3 Backlog section (DRG transit routing, DNS labels) | `README.md` | Document known gaps for sprint3 |
| C18 | Updated git tag from `v2-sprint2-complete` → `sprint2-complete` | `README.md` | Clean up version nomenclature (Han Kiat) |
| C19 | Updated nw_main.tf architecture diagram — removed IGW line | `nw_main.tf` | Diagram must match V1 design |
| C20 | Added DRG full-mesh sprint3 backlog note to `nw_main.tf` and `nw_team4.tf` | `nw_main.tf`, `nw_team4.tf` | Document known gap at source |
