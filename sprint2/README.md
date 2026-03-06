# STAR ELZ V1 — Sprint 2: Hub and Spoke Networking

**Branch:** `sprint2` · **Dates:** 2–4 Mar 2026 · **Terraform ≥ 1.3.0** · **OCI Provider ≥ 6.0.0**

> **Coming from Sprint 1?** You need 10 compartment OCIDs from `terraform output -json > sprint1_outputs.json`. Paste them into Sprint 2's `terraform.tfvars` or ORM variables (Section 3). The mapping is documented in [`terraform.tfvars.template`](terraform.tfvars.template). Everything else you need is in this README.

Sprint 2 builds a hub-and-spoke network — 5 VCNs (1 hub + 4 spokes) inside Sprint 1 compartments. V1 is fully isolated: no IGW, no public IPs. Validation uses NPA (control plane) and Bastion SSH (data plane).

E-W spoke↔spoke routing works via DRG v2 full-mesh (TC-18/TC-19). Hub FW inspection of E-W traffic is Sprint 3 (S3-BACKLOG-01).

---

## What we are building

<img width="720" height="405" alt="Sprint2" src="https://github.com/user-attachments/assets/82c28bb2-bc5b-408a-a09c-835091f668f2" />

## Network Topology

```
STAR ELZ V1 — Network Topology

C1_R_ELZ_NW  (T4 — Hub)
├── vcn_r_elz_nw                    10.0.0.0/16
│   ├── sub_r_elz_nw_fw             10.0.0.0/24   [private]
│   │   ├── fw_r_elz_nw_hub_sim     Sim FW  (ip_fwd + MASQUERADE)
│   │   └── rt_r_elz_nw_fw          [empty — Sprint 3 transit routing]
│   └── sub_r_elz_nw_mgmt           10.0.1.0/24   [private]
│       ├── bas_r_elz_nw_hub        Bastion (STANDARD)
│       └── rt_r_elz_nw_mgmt        0/0 → DRG (Phase 2)
│
├── drg_r_hub                        5 VCN attachments (E-W full-mesh)
│   ├── drga_r_elz_nw_hub           Hub VCN
│   ├── drga_os_elz_nw              OS spoke
│   ├── drga_ss_elz_nw              SS spoke
│   ├── drga_ts_elz_nw              TS spoke
│   └── drga_devt_elz_nw            DEVT spoke
│
└── drg_r_ew_hub                     0 attachments (V2 — child tenancy RPC)

C1_OS_ELZ_NW  (T1)
└── vcn_os_elz_nw                    10.1.0.0/24
    └── sub_os_elz_nw_app           fw_os_elz_nw_sim    RT: 0/0 → DRG

C1_SS_ELZ_NW  (T3)
└── vcn_ss_elz_nw                    10.2.0.0/24
    └── sub_ss_elz_nw_app           fw_ss_elz_nw_sim    RT: 0/0 → DRG

C1_TS_ELZ_NW  (T2)
└── vcn_ts_elz_nw                    10.3.0.0/24
    └── sub_ts_elz_nw_app           fw_ts_elz_nw_sim    RT: 0/0 → DRG

C1_DEVT_ELZ_NW  (T3)
└── vcn_devt_elz_nw                  10.4.0.0/24
    └── sub_devt_elz_nw_app         (no Sim FW)         RT: 0/0 → DRG

All subnets: prohibit_public_ip = true
All Sim FW VNICs: skip_source_dest_check = true
Spoke↔spoke: works via DRG full-mesh (bypasses Hub FW — Sprint 3 adds forced inspection)
```

---

## Naming Convention

| Resource | Pattern | Example |
|---|---|---|
| VCN | `vcn_<agency>_elz_nw` | `vcn_os_elz_nw` |
| Subnet | `sub_<agency>_elz_nw_<func>` | `sub_r_elz_nw_fw` |
| DRG | `drg_r_<qualifier>` | `drg_r_hub` |
| DRG Attachment | `drga_<agency>_elz_nw` | `drga_os_elz_nw` |
| Route Table | `rt_<agency>_elz_nw_<func>` | `rt_os_elz_nw_app` |
| Sim FW | `fw_<agency>_elz_nw[_hub]_sim` | `fw_os_elz_nw_sim` |
| Bastion | `bas_r_elz_nw_hub` | — |

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

## Two-Phase Apply — How It Works

**Important:** Sprint 2 also uses a **single shared ORM Stack**. All 4 teams work in the same codebase. There is one collective Apply per phase — not per team.

### Prerequisites

Sprint 1 complete: TC-01–TC-06b PASS, `sprint1_outputs.json` exported, git tag `v1-sprint1-complete` pushed.

**IAM access for Phase 2 — verified clean:**

All Sprint 2 resources create successfully under existing Sprint 1 policies when applied via ORM (admin principal). The full audit:

| Sprint 2 Resource | OCI Verb | Compartment | Sprint 1 Policy | Status |
|---|---|---|---|---|
| VCNs, subnets, RTs, security lists | manage virtual-network-family | C1_R_ELZ_NW + spoke cmps | UG_ELZ_NW + UG_*_ELZ_NW | ✅ |
| DRGs (2) | manage drgs | C1_R_ELZ_NW | UG_ELZ_NW | ✅ |
| DRG attachments (5) | manage drgs | C1_R_ELZ_NW | UG_ELZ_NW | ✅ |
| Sim FW instances (4) | manage instances | C1_R_ELZ_NW + spoke cmps | UG_ELZ_NW + UG_*_ELZ_NW | ✅ |
| Bastion service (1) | manage bastion-family | C1_R_ELZ_NW | **No grant** — works via ORM admin | ⚡ |

**Bastion note:** The Bastion service (`bas_r_elz_nw_hub`) creates successfully because ORM runs as tenancy admin. However, `UG_ELZ_NW` team members will get HTTP 403 if they try to manage the Bastion via CLI/Console (e.g. creating sessions for TC-15/TC-19). This does not block Phase 2 apply or any Phase 2 test cases — Bastion sessions are Sprint 3 scope. The fix (adding `manage bastion-family in C1_R_ELZ_NW` to `UG_ELZ_NW-Policy`) is applied as a Sprint 1 ORM re-apply at the start of Sprint 3. See `SPRINT1_IAM_PATCH_FOR_S3.md`.

### Phase 1 — VCNs + Subnets + DRG

| Who | Action |
|---|---|
| All teams | Write your team file (VCN + subnet section), push PR, get merged |
| Any team member | ORM **Plan** anytime to check your work |
| **Oracle / Architect** | One collective ORM **Apply** after all PRs merged |
| All teams | Run **TC-07** (5 VCNs) and **TC-08** (6 subnets) |
| T4 | Run `terraform output hub_drg_id` → share OCID with T1/T2/T3 |

### Phase 2 — DRG Attachments + Route Tables + Sim FW + Bastion

| Who | Action |
|---|---|
| **Oracle / Architect** | Paste `hub_drg_id` into ORM variable (Section 4) |
| All teams | Verify Phase 2 code in your team file is ready (DRG attach, RT, Sim FW) |
| **Oracle / Architect** | One collective ORM **Apply** |
| All teams | Run **TC-09** through **TC-19** |

**Why one collective apply per phase?** All team resources are in one Terraform state. DRG attachments depend on the DRG created by T4. Route tables reference `var.hub_drg_id`. Applying per-team would create partial state and dependency errors.

**Can I run Plan on my own?** Yes — any team member can trigger ORM Plan at any time to preview changes. Plan is read-only, it never modifies infrastructure. Use it freely to check your code compiles and your resources look correct.

### After Phase 2

```bash
terraform output -json > sprint2_outputs.json
git tag sprint2-complete && git push origin sprint2-complete
```

---

## Sprint 2 Issue List

### VCN + Subnet (Phase 1)

| # | Task | Team | Compartment | File |
|---|---|---|---|---|
| S2-T1 | Write & provision VCN + Subnet for OS compartment | T1 | C1_OS_ELZ_NW | `nw_team1.tf` |
| S2-T2 | Write & provision VCN + Subnet for TS compartment | T2 | C1_TS_ELZ_NW | `nw_team2.tf` |
| S2-T3 | Write & provision VCN + Subnet for SS + DEVT compartment | T3 | C1_SS/DEVT_ELZ_NW | `nw_team3.tf` |
| S2-T4 | Write & provision VCN + Subnet + DRG for ELZ_NW compartment | T4 | C1_R_ELZ_NW | `nw_team4.tf` |

### Route Tables (Phase 2)

| # | Task | Team | Compartment | File |
|---|---|---|---|---|
| S2-T1 | Write & provision Route Table for OS compartment | T1 | C1_OS_ELZ_NW | `nw_team1.tf` |
| S2-T2 | Write & provision Route Table for TS compartment | T2 | C1_TS_ELZ_NW | `nw_team2.tf` |
| S2-T3 | Write & provision Route Table for SS + DEVT compartment | T3 | C1_SS/DEVT_ELZ_NW | `nw_team3.tf` |
| S2-T4 | Write & provision Route Table for ELZ_NW compartment | T4 | C1_R_ELZ_NW | `nw_team4.tf` |

### Sim Firewall (Phase 2)

| # | Task | Team | Compartment | File |
|---|---|---|---|---|
| S2-T1 | Simulate compute / provision Firewall for OS compartment | T1 | C1_OS_ELZ_NW | `nw_team1.tf` |
| S2-T2 | Simulate compute / provision Firewall for TS compartment | T2 | C1_TS_ELZ_NW | `nw_team2.tf` |
| S2-T3 | Simulate compute / provision Firewall for SS compartment | T3 | C1_SS_ELZ_NW | `nw_team3.tf` |
| S2-T4 | Simulate compute / provision Firewall for ELZ_NW compartment | T4 | C1_R_ELZ_NW | `nw_team4.tf` |

### Bastion (Phase 2)

| # | Task | Team | Compartment | File |
|---|---|---|---|---|
| S2-T4 | Write & provision Bastion for ELZ_NW compartment | T4 | C1_R_ELZ_NW | `nw_team4.tf` |

All dates: 2–4 Mar 2026. Phase 1 resources (VCN/subnet/DRG) apply first; Phase 2 resources (RT rules/DRG attach/Sim FW/Bastion) require `hub_drg_id`.

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

### What Works in Sprint 2 (and what doesn't)

OCI DRG v2 with no custom `drg_route_table` on attachments defaults to **full-mesh**: every attached VCN can reach every other attached VCN via the DRG fabric. This means real traffic flows between all 5 VCNs right now.

**Works — testable now (NPA + data plane):**

| Path | NPA | Data Plane | TC |
|---|---|---|---|
| Spoke → Hub FW subnet (e.g. OS 10.1.0.x → Hub 10.0.0.x) | REACHABLE | ping/SSH | TC-13, TC-15 |
| Spoke → Spoke (e.g. OS 10.1.0.x → TS 10.3.0.x) | REACHABLE | ping/traceroute/TCP | TC-14, TC-18, TC-19 |
| Hub MGMT → any spoke (Bastion reachability) | REACHABLE | Bastion SSH | TC-18, TC-15 |
| Hub Sim FW → all spoke Sim FWs | REACHABLE | ping/traceroute/tcpdump/TCP:22 | TC-19 |

**Does NOT work yet — Sprint 3 scope (S3-BACKLOG-01):**

| Path | Why | Fix |
|---|---|---|
| Spoke → Hub FW **inspection** → Spoke (transit routing) | Hub FW RT (`rt_r_elz_nw_fw`) is empty. No VCN ingress route table. No DRG route distribution. | Sprint 3: add `oci_core_drg_route_table` + `oci_core_drg_route_distribution` to force spoke traffic via Hub FW VNIC |

**What to say if asked:** "Spoke-to-spoke ping works right now — the DRG v2 full-mesh routes it directly. What we don't have yet is forced inspection through the Hub Firewall. That's the DRG transit routing in Sprint 3. Sprint 2 proves the fabric is connected; Sprint 3 adds the security enforcement point."

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
REGION="ap-singapore-1"

# Subnet OCIDs — needed for NPA tests (TC-13, TC-14, TC-18)
HUB_FW_SUBNET="ocid1.subnet.oc1..aaa"     # terraform output hub_fw_subnet_id
HUB_MGMT_SUBNET="ocid1.subnet.oc1..aaa"   # terraform output hub_mgmt_subnet_id
OS_APP_SUBNET="ocid1.subnet.oc1..aaa"      # terraform output os_app_subnet_id
TS_APP_SUBNET="ocid1.subnet.oc1..aaa"      # terraform output ts_app_subnet_id
SS_APP_SUBNET="ocid1.subnet.oc1..aaa"      # terraform output ss_app_subnet_id
DEVT_APP_SUBNET="ocid1.subnet.oc1..aaa"    # terraform output devt_app_subnet_id
TENANCY_ID=$(oci iam tenancy get --query 'data.id' --raw-output)

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
| sub_r_elz_nw_fw | 10.0.0.0/24 | true |
| sub_r_elz_nw_mgmt | 10.0.1.0/24 | true |
| sub_os_elz_nw_app | 10.1.0.0/24 | true |
| sub_ts_elz_nw_app | 10.3.0.0/24 | true |
| sub_ss_elz_nw_app | 10.2.0.0/24 | true |
| sub_devt_elz_nw_app | 10.4.0.0/24 | true |

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
    --query "data[?starts_with(\"display-name\",'rt_')].{name:\"display-name\",rules:\"route-rules\"}" \
    | jq '.[].rules'
done

# Hub FW RT: EMPTY
oci network route-table list --vcn-id $HUB_VCN_ID \
  --query "data[?\"display-name\"=='rt_r_elz_nw_fw'].\"route-rules\"" | jq '.'

# Hub MGMT RT: 0/0 → DRG
oci network route-table list --vcn-id $HUB_VCN_ID \
  --query "data[?\"display-name\"=='rt_r_elz_nw_mgmt'].\"route-rules\"" | jq '.'
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

**Create Bastion Managed SSH session:**

Console → Bastion → `bas_r_elz_nw_hub` → Create Session → Managed SSH → Target: `fw_r_elz_nw_hub_sim` → Username: `opc` → paste your `~/.ssh/id_rsa.pub` → Create. Copy the SSH ProxyCommand from session details and run it.

**Prerequisites:** Service Gateway in VCN with route rule `All Oracle Services Network → SGW` (Cloud Agent needs OSN access). Bastion plugin ENABLED via `agent_config`. Wait 3–5 min after apply.

**Once connected — verify Sim FW is working:**

```bash
# cloud-init completed?
cloud-init status --long                          # status: done
sudo cat /var/log/star-elz-simfw-init.log         # "Sim FW bootstrap complete — interface=ens3"

# IP forwarding active?
sysctl net.ipv4.ip_forward                        # = 1

# MASQUERADE on correct interface (ens3, not eth0)?
sudo iptables -t nat -L POSTROUTING -v -n         # MASQUERADE on ens3

# Ping spoke Sim FWs
ping -c 2 $OS_FW_IP && ping -c 2 $TS_FW_IP && ping -c 2 $SS_FW_IP
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
| Sim FW | OL8 E4.Flex. `iptables-services` (not firewalld). Persistent `ip_forward=1`. `MASQUERADE` on `eth0`. Boot volume 50GB (OCI minimum). |
| Bastion Managed SSH | No SSH key in Terraform. User pastes key in Console at session creation. Cloud Agent handles auth. **Service Gateway required** — Cloud Agent needs route to Oracle Services Network for Bastion plugin initialisation and yum access. |
| Bastion plugin | `agent_config.plugins_config` with `Bastion = ENABLED` on all Sim FW instances. Plugin takes 3–5 min after apply to start. Requires SGW route rule in subnet RT. |
| Service Gateway | One SGW per VCN (Hub + 4 spokes). Route rule `All Oracle Services Network → SGW` in every subnet RT. Required for Cloud Agent, Bastion plugin, and cloud-init yum/dnf. |
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
- [ ] **Sprint 1 IAM patch queued** — 5 statements to add to `UG_ELZ_NW-Policy` before Sprint 3 apply (see `SPRINT1_IAM_PATCH_FOR_S3.md`)

> **Note for Sprint 3 lead:** Sprint 2 Phase 2 apply works with no IAM changes.
> The Bastion service creates fine via ORM admin. The IAM patch adds `manage bastion-family`
> for CLI access and Sprint 3 session creation — apply it as the first action on Sprint 3 day
> by re-running Sprint 1 ORM Plan → Apply (additive, 5 new statements, zero destroys).

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

### 3 Mar 2026 (cross-sprint IAM audit)

| # | Change | File(s) |
|---|---|---|
| C36 | Added Sprint 1 IAM ↔ Sprint 2 resource matrix to Prerequisites | `README.md` |
| C37 | Documented Bastion CLI access gap (ORM works, CLI 403 for UG_ELZ_NW) | `README.md` |
| C38 | Noted Sprint 1 patch timing (start of Sprint 3, not Sprint 2) | `README.md` |

### 6 Mar 2026 (Phase 2 apply fixes)

| # | Change | File(s) |
|---|---|---|
| C39 | Added `agent_config` with Bastion plugin ENABLED on all 4 Sim FW instances | `nw_team1.tf`, `nw_team2.tf`, `nw_team3.tf`, `nw_team4.tf` |
| C40 | Added `boot_volume_size_in_gbs = 50` — OL8 image default 47GB below OCI 50GB minimum | `nw_team1.tf`, `nw_team2.tf`, `nw_team3.tf`, `nw_team4.tf` |
| C41 | Updated TC-15 with Bastion Managed SSH session creation instructions | `README.md` |
| C42 | **CORRECTED:** Service Gateway IS required for Bastion Managed SSH — Cloud Agent needs OSN route for plugin init + yum | `README.md` |
| C43 | Added Service Gateway to Hub VCN + route rules to Hub FW and Hub MGMT RTs | `nw_team4.tf`, `data_sources.tf`, `locals.tf` |
| C44 | Added Service Gateway to OS/TS/SS/DEVT spoke VCNs + route rules to spoke RTs | `nw_team1.tf`, `nw_team2.tf`, `nw_team3.tf` |
| C45 | Added `oci_core_services` data source and `hub_sgw_id` output | `data_sources.tf`, `outputs.tf` |
| C46 | **CRITICAL:** Fixed cloud-init `eth0` → auto-detect primary interface (ens3 on OL8 E4.Flex) | `locals.tf` |
| C47 | Added missing subnet OCIDs to TC shell variables block (NPA tests need them) | `README.md` |
| C48 | Simplified TC-15 validation steps, fixed ens3 references | `README.md` |
