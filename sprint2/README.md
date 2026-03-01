# STAR ELZ V1 — Sprint 2: Hub and Spoke Networking

**Branch:** `sprint2` · **Dates:** 2–4 Mar 2026 · **Terraform ≥ 1.3.0** · **OCI Provider ≥ 6.0.0**

Sprint 2 builds a hub-and-spoke network — 5 VCNs (1 hub + 4 spokes) inside Sprint 1 compartments. V1 is fully isolated: no IGW, no public IPs. Validation uses NPA (control plane) and Bastion SSH (data plane).

E-W spoke↔spoke routing works via DRG v2 full-mesh (TC-18/TC-19). Hub FW inspection of E-W traffic is Sprint 3 (S3-BACKLOG-01).

---

## Network Topology

```
C0 Tenancy Root
│   Tag Namespace: C0-star-elz-v1
│   Tags: Environment · Owner · ManagedBy · CostCenter · DataClassification
│
└── C1_R_ELZ_NW  (T4 — Hub)
    ├── vcn_r_elz_nw ── 10.0.0.0/16
    │   ├── SUB-C1-R-ELZ-NW-FW ── 10.0.0.0/24 [private]
    │   │   ├── FW-C1-R-ELZ-NW-HUB-SIM  (E4.Flex · skip_sdc · ip_fwd · MASQUERADE)
    │   │   └── RT-C1-R-ELZ-NW-FW ── [empty — Sprint 3 DRG transit]
    │   └── SUB-C1-R-ELZ-NW-MGMT ── 10.0.1.0/24 [private]
    │       ├── BAS-C1-R-ELZ-NW-HUB  (Bastion STANDARD)
    │       └── RT-C1-R-ELZ-NW-MGMT ── 0/0 → DRG (Phase 2)
    │
    ├── drg_r_hub ── Hub DRG · 5 attachments (Phase 2)
    │   ├── DRGA-C1-R-ELZ-NW-HUB   (Hub VCN)
    │   ├── DRGA-C1-OS-ELZ-NW      (OS)
    │   ├── DRGA-C1-TS-ELZ-NW      (TS)
    │   ├── DRGA-C1-SS-ELZ-NW      (SS)
    │   └── DRGA-C1-DEVT-ELZ-NW    (DEVT)
    │
    └── drg_r_ew_hub ── E-W DRG · V2 placeholder · 0 attachments

├── C1_OS_ELZ_NW  (T1)
│   └── vcn_os_elz_nw ── 10.1.0.0/24
│       └── SUB-C1-OS-ELZ-NW-APP · FW-C1-OS-ELZ-NW-SIM · RT: 0/0 → DRG

├── C1_TS_ELZ_NW  (T2)
│   └── vcn_ts_elz_nw ── 10.3.0.0/24
│       └── SUB-C1-TS-ELZ-NW-APP · FW-C1-TS-ELZ-NW-SIM · RT: 0/0 → DRG

├── C1_SS_ELZ_NW  (T3)
│   └── vcn_ss_elz_nw ── 10.2.0.0/24
│       └── SUB-C1-SS-ELZ-NW-APP · FW-C1-SS-ELZ-NW-SIM · RT: 0/0 → DRG

└── C1_DEVT_ELZ_NW  (T3)
    └── vcn_devt_elz_nw ── 10.4.0.0/24
        └── SUB-C1-DEVT-ELZ-NW-APP · no Sim FW · RT: 0/0 → DRG
```

> All subnets: `prohibit_public_ip = true`. All Sim FW VNICs: `skip_source_dest_check = true`.  
> Spoke↔spoke works via DRG full-mesh but bypasses Hub FW — Sprint 3 fixes this (S3-BACKLOG-01).

---

## Naming Convention

| Resource | Pattern | Example |
|---|---|---|
| VCN | `vcn_<agency>_elz_nw` | `vcn_os_elz_nw` |
| Subnet | `SUB-C1-<AGENCY>-ELZ-NW-<FUNC>` | `SUB-C1-R-ELZ-NW-FW` |
| DRG | `drg_r_<qualifier>` | `drg_r_hub` |
| DRG Attachment | `DRGA-C1-<AGENCY>-ELZ-NW` | `DRGA-C1-OS-ELZ-NW` |
| Route Table | `RT-C1-<AGENCY>-ELZ-NW-<FUNC>` | `RT-C1-OS-ELZ-NW-APP` |
| Sim FW | `FW-C1-<AGENCY>-ELZ-NW[-HUB]-SIM` | `FW-C1-OS-ELZ-NW-SIM` |
| Bastion | `BAS-C1-R-ELZ-NW-HUB` | — |

---

## File Map

| File | Owner | What It Contains |
|---|---|---|
| `locals.tf` | — | Name constants, DNS labels, CIDR plan, phase2 gate, cloud-init |
| `variables_general.tf` | — | Tenancy, region, service_label, CIS level, tags |
| `variables_iam.tf` | — | 10 compartment OCIDs from Sprint 1 |
| `variables_net.tf` | — | CIDRs, hub_drg_id (phase gate), Sim FW shape, Bastion CIDR |
| `data_sources.tf` | — | Regions, tenancy, ADs, OL8 images |
| `providers.tf` | — | OCI + OCI home, Terraform ≥ 1.3.0 |
| `nw_main.tf` | — | Tag merge locals, architecture notes |
| `iam_sprint1_ref.tf` | — | Sprint 1 IAM reference (read-only, no resources) |
| `nw_team1.tf` | T1 | OS VCN, subnet, DRG attachment, RT, Sim FW |
| `nw_team2.tf` | T2 | TS VCN, subnet, DRG attachment, RT, Sim FW |
| `nw_team3.tf` | T3 | SS + DEVT VCNs, subnets, DRG attachments, RTs, Sim FW (SS only) |
| `nw_team4.tf` | T4 | Hub VCN, FW+MGMT subnets, both DRGs, RTs, Sim FW, Bastion |
| `outputs.tf` | — | All VCN/subnet/DRG OCIDs, Sim FW IDs, Bastion ID |
| `schema.yaml` | — | ORM UI — 8 sections |
| `terraform.tfvars.template` | — | Template for Sprint 1 OCIDs |

---

## Two-Phase Apply

### Prerequisites

Sprint 1 complete: TC-01–TC-06b PASS, `sprint1_outputs.json` exported, git tag `v1-sprint1-complete` pushed.

### Phase 1 — VCNs + Subnets + DRG (all teams simultaneous)

1. Create ORM Stack → `sprint2/`
2. Paste 10 compartment OCIDs (Section 3) from `sprint1_outputs.json`
3. Leave `hub_drg_id` **empty** (Section 4)
4. All teams Plan → Apply
5. Run **TC-07** (5 VCNs) and **TC-08** (6 subnets)
6. T4: `terraform output hub_drg_id` → share with T1/T2/T3

### Phase 2 — DRG Attachments + RTs + Sim FW + Bastion

1. All teams paste `hub_drg_id` (Section 4)
2. All teams Plan → Apply
3. Run **TC-09** through **TC-19**

### After Phase 2

```bash
terraform output -json > sprint2_outputs.json
git tag sprint2-complete && git push origin sprint2-complete
```

---

## Sprint 2 Issues

| # | Task | Team | Compartment | File |
|---|---|---|---|---|
| S2-T1 | OS: VCN + Subnet + RT + Sim FW | T1 | C1_OS_ELZ_NW | `nw_team1.tf` |
| S2-T2 | TS: VCN + Subnet + RT + Sim FW | T2 | C1_TS_ELZ_NW | `nw_team2.tf` |
| S2-T3 | SS+DEVT: VCNs + Subnets + RTs + Sim FW (SS) | T3 | C1_SS/DEVT_ELZ_NW | `nw_team3.tf` |
| S2-T4 | Hub: VCN + Subnets + DRGs + RTs + Sim FW + Bastion | T4 | C1_R_ELZ_NW | `nw_team4.tf` |

All dates: 2–4 Mar 2026. Phase 1 resources (VCN/subnet) apply first; Phase 2 resources (DRG attach/RT rules/Sim FW/Bastion) require `hub_drg_id`.

---

## Test Cases

### Phase → TC Mapping

| Phase | Gate | TCs |
|---|---|---|
| Phase 1 | T4 confirms `hub_drg_id` | TC-07, TC-08 |
| Phase 2 | All teams applied | TC-09, TC-10, TC-11, TC-12, TC-12b |
| Phase 2 | After TC-09 | TC-13, TC-14, TC-18 |
| Phase 2 | After TC-11 (Bastion ACTIVE) | TC-15, TC-16, TC-19 |
| Final | All TCs pass | TC-17 |

> **NPA** validates the OCI control plane (route tables, DRG attachments, NSG rules). It cannot verify cloud-init, `ip_forward`, or iptables.  
> **Data plane** tests (ping, traceroute, tcpdump) require Bastion SSH into Sim FW instances.

### Shell Variables (OCI Cloud Shell)

```bash
# Paste from: terraform output -json > sprint2_outputs.json
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

# Resolve Sim FW private IPs (dynamically assigned)
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
```

### TC-07 — 5 VCNs Created

```bash
oci network vcn list \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output) --all \
  --query "data[?starts_with(\"display-name\",'vcn_')]" \
  | jq '[.[] | {name:.["display-name"], cidr:.["cidr-blocks"][0]}]'
```

Expected: `vcn_r_elz_nw`, `vcn_os_elz_nw`, `vcn_ts_elz_nw`, `vcn_ss_elz_nw`, `vcn_devt_elz_nw`

### TC-08 — 6 Subnets (all private)

```bash
for VCN_ID in $HUB_VCN_ID $OS_VCN_ID $TS_VCN_ID $SS_VCN_ID $DEVT_VCN_ID; do
  oci network subnet list --vcn-id $VCN_ID \
    --query 'data[].{name:"display-name",cidr:"cidr-block",private:"prohibit-public-ip-on-vnic"}' | jq '.[]'
done
```

| Subnet | CIDR | Private |
|---|---|---|
| SUB-C1-R-ELZ-NW-FW | 10.0.0.0/24 | true |
| SUB-C1-R-ELZ-NW-MGMT | 10.0.1.0/24 | true |
| SUB-C1-OS-ELZ-NW-APP | 10.1.0.0/24 | true |
| SUB-C1-TS-ELZ-NW-APP | 10.3.0.0/24 | true |
| SUB-C1-SS-ELZ-NW-APP | 10.2.0.0/24 | true |
| SUB-C1-DEVT-ELZ-NW-APP | 10.4.0.0/24 | true |

### TC-09 — Hub DRG: 5 Attachments

```bash
oci network drg-attachment list --drg-id $HUB_DRG_ID --all \
  --query 'data[].{name:"display-name",state:"lifecycle-state"}' | jq '.[]'
```

Expected: 5 × `ATTACHED`

### TC-10 — 4 Sim FW RUNNING + skip_source_dest_check

```bash
for INST_ID in $SIM_FW_HUB_ID $SIM_FW_OS_ID $SIM_FW_TS_ID $SIM_FW_SS_ID; do
  oci compute instance get --instance-id $INST_ID \
    --query 'data.{name:"display-name",state:"lifecycle-state"}' | jq '.'
  ATTACH_ID=$(oci compute vnic-attachment list --instance-id $INST_ID --query 'data[0].id' --raw-output)
  VNIC_ID=$(oci compute vnic-attachment get --vnic-attachment-id $ATTACH_ID --query 'data."vnic-id"' --raw-output)
  oci network vnic get --vnic-id $VNIC_ID \
    --query 'data.{vnic:"display-name",skip_sdc:"skip-source-dest-check"}' | jq '.'
done
```

Expected: All `RUNNING`, all `skip_sdc: true`

### TC-11 — Bastion ACTIVE

```bash
oci bastion bastion get --bastion-id $HUB_BASTION_ID \
  --query 'data.{name:"name",state:"lifecycle-state"}' | jq '.'
```

### TC-12 — Route Tables

```bash
# Spoke RTs: 1 rule each — 0/0 → Hub DRG
for VCN_ID in $OS_VCN_ID $TS_VCN_ID $SS_VCN_ID $DEVT_VCN_ID; do
  oci network route-table list --vcn-id $VCN_ID \
    --query "data[?starts_with(\"display-name\",'RT-C1')].{name:\"display-name\",rules:\"route-rules\"}" \
    | jq '.[].rules'
done

# Hub FW RT: EMPTY
oci network route-table list --vcn-id $HUB_VCN_ID \
  --query "data[?\"display-name\"=='RT-C1-R-ELZ-NW-FW'].\"route-rules\"" | jq '.'

# Hub MGMT RT: 0/0 → DRG
oci network route-table list --vcn-id $HUB_VCN_ID \
  --query "data[?\"display-name\"=='RT-C1-R-ELZ-NW-MGMT'].\"route-rules\"" | jq '.'
```

### TC-12b — E-W DRG Exists (V2 placeholder)

```bash
oci network drg get --drg-id $EW_HUB_DRG_ID \
  --query 'data.{name:"display-name",state:"lifecycle-state"}' | jq '.'
oci network drg-attachment list --drg-id $EW_HUB_DRG_ID --all | jq '.data | length'
```

Expected: `drg_r_ew_hub` · `AVAILABLE` · 0 attachments

### TC-13 — NPA: Spoke → Hub

```bash
oci network path-analyzer-test create --protocol 1 \
  --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$OS_APP_SUBNET\"}" \
  --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$HUB_FW_SUBNET\"}" \
  --compartment-id $(oci iam tenancy get --query 'data.id' --raw-output)
```

Expected: DRG transit, no `DROPPED`. Repeat for TS/SS/DEVT → Hub.

### TC-14 — NPA: Spoke → Spoke

Same pattern, OS → TS. Expected: `REACHABLE` via DRG full-mesh. Traffic bypasses Hub FW — expected V1 behaviour, S3-BACKLOG-01.

### TC-15 — Sim FW Linux Validation (Bastion SSH)

Bastion → `FW-C1-R-ELZ-NW-HUB-SIM`:

```bash
cloud-init status --long                             # status: done
sudo cat /var/log/star-elz-simfw-init.log            # "Sim FW bootstrap complete"
sysctl net.ipv4.ip_forward                           # = 1
cat /etc/sysctl.d/99-ipforward.conf                  # net.ipv4.ip_forward=1
sudo iptables -t nat -L POSTROUTING -v -n            # MASQUERADE on eth0
sudo systemctl is-enabled iptables                   # enabled
ping -c 4 $OS_FW_IP && ping -c 4 $TS_FW_IP && ping -c 4 $SS_FW_IP
traceroute -n $OS_FW_IP                              # 2–3 hops via DRG
sudo tcpdump -ni eth0 icmp                           # while pinging
```

### TC-16 — DEVT: No Compute

```bash
oci compute instance list --compartment-id <devt_compartment_id> \
  --lifecycle-state RUNNING | jq '.data | length'    # Expected: 0
```

### TC-17 — Zero Drift

ORM → Plan → `0 to add, 0 to change, 0 to destroy`

### TC-18 — NPA E-W: All Spoke Pairs

```bash
declare -A SUBNETS=([OS]=$OS_APP_SUBNET [TS]=$TS_APP_SUBNET [SS]=$SS_APP_SUBNET [DEVT]=$DEVT_APP_SUBNET)
TENANCY_ID=$(oci iam tenancy get --query 'data.id' --raw-output)

for SRC in OS TS SS DEVT; do
  for DST in OS TS SS DEVT; do
    [ "$SRC" = "$DST" ] && continue
    echo "=== $SRC → $DST ==="
    oci network path-analyzer-test create --protocol 1 \
      --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"${SUBNETS[$SRC]}\"}" \
      --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"${SUBNETS[$DST]}\"}" \
      --compartment-id $TENANCY_ID --query 'data.result."path-analysis-result"' --raw-output
  done
done

# Hub MGMT → each spoke (Bastion reachability)
for DST in OS TS SS DEVT; do
  oci network path-analyzer-test create --protocol 1 \
    --source-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"$HUB_MGMT_SUBNET\"}" \
    --destination-endpoint "{\"type\":\"SUBNET\",\"subnetId\":\"${SUBNETS[$DST]}\"}" \
    --compartment-id $TENANCY_ID --query 'data.result."path-analysis-result"' --raw-output
done
```

Expected: All 16 paths `REACHABLE`.

### TC-19 — Data Plane E-W (Bastion SSH)

From Hub Sim FW (TC-15 session):

```bash
# Ping
ping -c 4 -W 2 $OS_FW_IP && ping -c 4 -W 2 $TS_FW_IP && ping -c 4 -W 2 $SS_FW_IP

# Traceroute (gateway → DRG fabric → spoke)
traceroute -n -m 5 $OS_FW_IP

# tcpdump (confirm packets on eth0)
sudo tcpdump -ni eth0 icmp -v   # while pinging from second terminal

# TCP port 22
nc -zv $OS_FW_IP 22 && nc -zv $TS_FW_IP 22 && nc -zv $SS_FW_IP 22
```

Record: *"DRG v2 full-mesh confirmed. Hub↔spoke PASS. Hub FW not in spoke↔spoke path — S3-BACKLOG-01."*

---

## Adding a 5th Spoke

4 files, nothing else:

```
sprint1/iam_cmps_team<N>.tf      — C1_<AGENCY>_ELZ_NW
sprint1/iam_groups_team<N>.tf    — UG_<AGENCY>_ELZ_NW
sprint1/iam_policies_team<N>.tf  — grants for new group
sprint2/nw_team<N>.tf            — copy nw_team1.tf, replace os/OS
```

`drg_r_hub` accepts additional attachments with zero changes to existing files. All names go into `locals.tf`. Do not split into separate Terraform workspaces.

> **Sprint 3+ module pattern:** Once spokes exceed 4, extract into `./modules/spoke` with `agency`, `compartment_id`, `vcn_cidr`, `hub_drg_id` inputs. Do NOT convert mid-sprint — `terraform state mv` required or Terraform destroys and recreates.

---

## Design Decisions

| Decision | Detail |
|---|---|
| No IGW in V1 | Isolated design. NPA + Bastion only. IGW is Sprint 3+. |
| Phase 2 gate | `local.phase2_enabled = var.hub_drg_id != ""` via `count`. |
| Sim FW | OL8 E4.Flex. `iptables-services` (not firewalld). Persistent `ip_forward=1`. `MASQUERADE` on `eth0`. |
| DEVT spoke | Network-only. No Sim FW. Compute Sprint 4+. |
| Hub FW RT empty | Placeholder. Sprint 3 adds DRG transit routing. |
| DRG v2 full-mesh | Spoke↔spoke works now but bypasses Hub FW. S3-BACKLOG-01 fixes. |
| Flat files | No modules in Sprint 2. Single dir = single dependency graph. |
| DNS labels | Centralised in `locals.tf`. No hardcoded strings in team files. |

---

## Sprint 3 Backlog

**S3-BACKLOG-01 — DRG Transit Routing (High)**  
DRG v2 full-mesh bypasses Hub FW for spoke↔spoke. Fix: `oci_core_drg_route_table` + `oci_core_drg_route_distribution` to force E-W via Hub VCN attachment → Sim FW. Files: `nw_team4.tf` (primary), `nw_team1-3.tf`.

**S3-BACKLOG-02 — DNS Labels (RESOLVED)**  
Moved to `locals.tf` in Sprint 2.

---

## Handoff Checklist

- [ ] TC-07: 5 VCNs
- [ ] TC-08: 6 subnets, all private
- [ ] TC-09: Hub DRG 5 attachments ATTACHED
- [ ] TC-10: 4 Sim FW RUNNING + skip_sdc
- [ ] TC-11: Bastion ACTIVE
- [ ] TC-12: RTs correct (spokes → DRG, hub FW empty, hub MGMT → DRG)
- [ ] TC-12b: `drg_r_ew_hub` AVAILABLE, 0 attachments
- [ ] TC-13: NPA spoke → hub
- [ ] TC-14: NPA spoke → spoke (DRG full-mesh documented)
- [ ] TC-15: Sim FW Linux: cloud-init, ip_forward, iptables, ping/traceroute/tcpdump
- [ ] TC-16: DEVT no compute
- [ ] TC-17: Zero drift
- [ ] TC-18: NPA E-W all 16 paths REACHABLE
- [ ] TC-19: Data plane E-W PASS, DRG bypass documented
- [ ] `sprint2_outputs.json` shared with Sprint 3 lead
- [ ] Git tag `sprint2-complete` pushed
- [ ] State Book updated
- [ ] S3-BACKLOG-01 issue created

---

## Changelog

### 27 Feb 2026 (post Han Kiat review)

| # | Change | File(s) |
|---|---|---|
| C1 | `net_main.tf` → `nw_main.tf` | `nw_main.tf` |
| C2–C5 | Removed IGW, all subnets private, no public IPs | `nw_team4.tf` |
| C6 | Removed `hub_igw_name` | `locals.tf` |
| C7–C8 | DNS labels centralised | `locals.tf`, `nw_team*.tf` |
| C9–C10 | cloud-init: `iptables-services`, persistent `ip_forward` | `locals.tf` |
| C11–C20 | README: NPA scope, TC-15, Sprint 3 backlog, diagram | `README.md`, `nw_main.tf` |

### 28 Feb 2026 (post audit)

| # | Change | File(s) |
|---|---|---|
| C21 | Spoke CIDRs `/16` → `/24` | `variables_net.tf`, `locals.tf`, `schema.yaml` |
| C22–C24 | Added `drg_r_ew_hub` + output | `nw_team4.tf`, `locals.tf`, `outputs.tf` |
| C25 | Removed stale public IP comment | `nw_team4.tf` |
| C26–C32 | TC-12b, TC-18, TC-19, 5th spoke guide, network diagram | `README.md` |

### 1 Mar 2026 (naming sync)

| # | Change | File(s) |
|---|---|---|
| C33 | VCN names → `vcn_*_elz_nw`, DRG names → `drg_r_*` | `locals.tf`, `README.md` |
| C34 | `UG_ELZ_DEVT_CSVCS` → `UG_DEVT_CSVCS` | `iam_sprint1_ref.tf` |
| C35 | Spoke CIDR header `/16` → `/24` | `variables_net.tf` |
