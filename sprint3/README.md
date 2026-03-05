# STAR ELZ V1 — Sprint 3

**Dates:** 9–10 March 2026 | **Module:** Security, Observability, Forced Inspection
**Prerequisite:** Sprint 1 (IAM) ✅ Applied | Sprint 2 (Networking) ✅ Applied
**Deployment:** OCI Resource Manager — single Plan → Apply (no phases)

---

## What Sprint 3 Does

Sprint 2 built the roads — 5 VCNs, 6 subnets, 2 DRGs, 5 DRG attachments, 6 route tables, 4 Sim FWs, Bastion, 6 security lists. Traffic flows OS → DRG → TS direct (full-mesh, no inspection).

Sprint 3 adds the checkpoint — forced inspection through Hub Sim FW, custom DRG route tables replacing auto-generated, OCI Bastion Service sessions, VCN flow logs, OCI Logging, Object Storage for log retention, events and alarms on DRG/routing changes.

**After Sprint 3 apply:** OS → DRG → Hub FW → inspect → DRG → TS. Every spoke-to-spoke packet transits the Hub Firewall. Flow logs prove it. Alarms catch unauthorised routing changes.

---

## Sprint 2 → Sprint 3 Handover Checklist

Before writing Sprint 3 code, verify Sprint 2 state is clean:

| Check | CLI Command | Expected |
|---|---|---|
| 5 VCNs exist | `oci network vcn list --compartment-id $NW_CMP --all --query 'data[].{name:"display-name"}' --output table` | vcn_r_elz_nw, vcn_os_elz_nw, vcn_ts_elz_nw, vcn_ss_elz_nw, vcn_devt_elz_nw |
| 6 subnets exist | `oci network subnet list --compartment-id $NW_CMP --all --query 'data[].{name:"display-name"}' --output table` | sub_r_elz_nw_fw, sub_r_elz_nw_mgmt, sub_os_elz_nw_app, sub_ts_elz_nw_app, sub_ss_elz_nw_app, sub_devt_elz_nw_app |
| DRG has 5 attachments | `oci network drg-attachment list --drg-id $DRG_ID --all --query 'data[].{name:"display-name"}' --output table` | drga_r_elz_nw_hub, drga_os_elz_nw, drga_ts_elz_nw, drga_ss_elz_nw, drga_devt_elz_nw |
| 6 security lists exist | `oci network security-list list --compartment-id $NW_CMP --all --query 'data[].{name:"display-name"}' --output table` | sl_r_elz_nw_fw, sl_r_elz_nw_mgmt, sl_os_elz_nw_app, sl_ts_elz_nw_app, sl_ss_elz_nw_app, sl_devt_elz_nw_app |
| 4 Sim FW instances running | `oci compute instance list --compartment-id $NW_CMP --all --query 'data[?contains("display-name","sim")].{name:"display-name",state:"lifecycle-state"}' --output table` | fw_r_elz_nw_hub_sim, fw_os_elz_nw_sim, fw_ts_elz_nw_sim, fw_ss_elz_nw_sim — all RUNNING |
| Bastion service active | `oci bastion bastion list --compartment-id $NW_CMP --all --query 'data[].{name:"name",state:"lifecycle-state"}' --output table` | bas_r_elz_nw_hub — ACTIVE |
| Hub Sim FW VNIC IP | `oci compute instance list-vnics --instance-id $HUB_FW_INSTANCE_ID --query 'data[0]."private-ip"' --raw-output` | 10.0.x.x (record this — used as next-hop in VCN ingress RT) |
| Tag namespace exists | `oci iam tag-namespace list --compartment-id $TENANCY_ID --all --query 'data[?name=="C0-star-elz-v1"].{name:name,state:"lifecycle-state"}' --output table` | C0-star-elz-v1 — ACTIVE |
| No ORM drift | `oci resource-manager stack detect-drift --stack-id $SPRINT2_STACK_ID` | No drift detected |
| Sprint 1 IAM patch applied | `oci iam policy get --policy-id $NW_POLICY_ID --query 'data.statements[?contains(@, \`bastion-family\`)]'` | Statement "manage bastion-family in C1_R_ELZ_NW" present |

**Sprint 1 known issue — tag namespace depends_on:** Sprint 1 `mon_tags.tf` requires `depends_on = [oci_identity_compartment.root_compartments]` on the tag namespace resource to avoid race condition where tags are created before compartments. This was fixed in Sprint 1. Sprint 3 references tags via `data.oci_identity_tag_namespace` — no depends_on needed in Sprint 3.

**Sprint 1 IAM patch required — Bastion sessions + spoke instance read:**

Sprint 3 creates Bastion sessions in `C1_R_ELZ_NW` and targets Sim FW instances in spoke compartments. No existing Sprint 1 policy grants these permissions. Before Sprint 3 apply, add 5 statements to `UG_ELZ_NW-Policy` in Sprint 1 `iam_policies_team1.tf`:

```
allow group UG_ELZ_NW to manage bastion-family in compartment C1_R_ELZ_NW
allow group UG_ELZ_NW to read instance-family in compartment C1_OS_ELZ_NW
allow group UG_ELZ_NW to read instance-family in compartment C1_TS_ELZ_NW
allow group UG_ELZ_NW to read instance-family in compartment C1_SS_ELZ_NW
allow group UG_ELZ_NW to read instance-family in compartment C1_DEVT_ELZ_NW
```

Re-apply Sprint 1 ORM stack (additive — no destroy). See `SPRINT1_IAM_PATCH_FOR_S3.md` for verification commands.

**Events rule compartment placement:** The `oci_events_rule.nw_changes` resource is created in `C1_R_ELZ_SEC` (not `C1_R_ELZ_NW`) because `UG_ELZ_SEC` has `manage events-family` in SEC. The rule monitors NW compartment events cross-compartment — this works because `UG_ELZ_SEC` has `read all-resources in tenancy`.

---

## Issue List

| ID | Task | Status | Owner | Start | End | Days |
|---|---|---|---|---|---|---|
| S3-T4-01 | Develop Terraform for custom DRG route tables (replace auto-generated) | New | T4 | 3/9/26 | 3/9/26 | 1 |
| S3-T4-02 | Develop Terraform for DRG route distribution (import policy) | New | T4 | 3/9/26 | 3/9/26 | 1 |
| S3-T4-03 | Develop Terraform for spoke DRG RT with static route to Hub | New | T4 | 3/9/26 | 3/9/26 | 1 |
| S3-T4-04 | Develop Terraform for VCN ingress route table on Hub DRG attachment | New | T4 | 3/9/26 | 3/9/26 | 1 |
| S3-T4-05 | Develop Terraform to update Hub FW subnet RT with spoke CIDRs | New | T4 | 3/9/26 | 3/9/26 | 1 |
| S3-T1-01 | Develop Terraform for OCI Bastion Service session (OS spoke) | New | T1 | 3/9/26 | 3/9/26 | 1 |
| S3-T2-01 | Develop Terraform for OCI Bastion Service session (TS spoke) | New | T2 | 3/9/26 | 3/9/26 | 1 |
| S3-T3-01 | Develop Terraform for OCI Logging — log group and VCN flow logs | New | T3 | 3/9/26 | 3/10/26 | 2 |
| S3-T3-02 | Develop Terraform for Object Storage bucket for log retention | New | T3 | 3/9/26 | 3/10/26 | 2 |
| S3-T3-03 | Develop Terraform for OCI events and alarms on DRG changes | New | T3 | 3/9/26 | 3/10/26 | 2 |
| S3-T3-04 | Develop Terraform for OCI Vault (KMS) and AES-256 master encryption key | New | T3 | 3/9/26 | 3/9/26 | 1 |
| S3-T3-05 | Develop Terraform for Cloud Guard detector/responder recipes (clone Oracle-managed) | New | T3 | 3/9/26 | 3/10/26 | 2 |
| S3-T3-06 | Develop Terraform for Cloud Guard target on tenancy root | New | T3 | 3/9/26 | 3/10/26 | 2 |
| S3-T3-07 | Develop Terraform for Security Zone recipes (SEC encryption + NW isolation) | New | T3 | 3/10/26 | 3/10/26 | 1 |
| S3-T3-08 | Develop Terraform for Security Zones on C1_R_ELZ_SEC and C1_R_ELZ_NW | New | T3 | 3/10/26 | 3/10/26 | 1 |
| S3-T4-06 | Develop Terraform for Service Gateway on Hub VCN (centralised Oracle service access) | New | T4 | 3/9/26 | 3/9/26 | 1 |
| S3-ORA-01 | Deploy Sprint 3 to OCI using Resource Manager | New | Oracle | 3/10/26 | 3/10/26 | 1 |
| S3-ORA-02 | Sprint 1 IAM patch re-apply (7 new statements: 5 NW + 2 SEC) | New | Oracle | 3/9/26 | 3/9/26 | 1 |
| S3-ORA-03 | Verify Cloud Guard is ENABLED in tenancy before Sprint 3 apply | New | Oracle | 3/9/26 | 3/9/26 | 1 |
| S3-ORA-04 | Validate Security Zone policy OCIDs for ap-singapore-2 region | New | Oracle | 3/9/26 | 3/9/26 | 1 |

---

## Team Structure — Sprint 3

| Team | File | Scope |
|---|---|---|
| T1 | `sec_team1.tf` | Bastion session for OS spoke validation |
| T2 | `sec_team2.tf` | Bastion session for TS spoke validation |
| T3 | `sec_team3.tf` | OCI Logging (log group, VCN flow logs for all 6 subnets), Object Storage bucket for log retention, events and alarms for DRG routing changes |
| T4 | `sec_team4.tf` | Custom DRG route tables, DRG route distribution, spoke DRG RT (static route to Hub), VCN ingress RT on Hub DRG attachment, Hub FW subnet RT update with spoke CIDRs |
| Architect | `locals.tf` | All Sprint 3 name constants (pre-session) |

---

## Sprint 3 Inputs (from Sprint 2 outputs)

These values come from Sprint 2 `outputs.tf` and are passed as variables to Sprint 3:

```hcl
# variables_s2_ref.tf — Sprint 2 outputs consumed by Sprint 3
variable "hub_drg_id"            { description = "OCID of drg_r_hub" }
variable "hub_drg_attachment_id" { description = "OCID of drga_r_elz_nw_hub" }
variable "os_drg_attachment_id"  { description = "OCID of drga_os_elz_nw" }
variable "ts_drg_attachment_id"  { description = "OCID of drga_ts_elz_nw" }
variable "ss_drg_attachment_id"  { description = "OCID of drga_ss_elz_nw" }
variable "devt_drg_attachment_id" { description = "OCID of drga_devt_elz_nw" }
variable "hub_fw_subnet_id"     { description = "OCID of sub_r_elz_nw_fw" }
variable "hub_mgmt_subnet_id"   { description = "OCID of sub_r_elz_nw_mgmt" }
variable "os_app_subnet_id"     { description = "OCID of sub_os_elz_nw_app" }
variable "ts_app_subnet_id"     { description = "OCID of sub_ts_elz_nw_app" }
variable "ss_app_subnet_id"     { description = "OCID of sub_ss_elz_nw_app" }
variable "devt_app_subnet_id"   { description = "OCID of sub_devt_elz_nw_app" }
variable "hub_fw_private_ip"    { description = "Private IP of fw_r_elz_nw_hub_sim VNIC — next-hop for VCN ingress RT" }
variable "bastion_id"           { description = "OCID of bas_r_elz_nw_hub Bastion service" }
variable "hub_vcn_id"           { description = "OCID of vcn_r_elz_nw" }
variable "os_vcn_id"            { description = "OCID of vcn_os_elz_nw" }
variable "ts_vcn_id"            { description = "OCID of vcn_ts_elz_nw" }
variable "ss_vcn_id"            { description = "OCID of vcn_ss_elz_nw" }
variable "devt_vcn_id"          { description = "OCID of vcn_devt_elz_nw" }
```

---

## File Map

```
sprint3/
├── README.md                      ← This file
├── locals.tf                      (Sprint 3 name constants — DRG RTs, log groups, buckets, alarms)
├── sec_team1.tf                   (T1 — Bastion session for OS spoke)
├── sec_team2.tf                   (T2 — Bastion session for TS spoke)
├── sec_team3.tf                   (T3 — Logging, flow logs, Object Storage, events, alarms)
├── sec_team4.tf                   (T4 — Custom DRG RTs, forced inspection routing, Service Gateway)
├── data_sources.tf                (Object Storage namespace, Service Gateway service CIDR lookup)
├── s2_sprint2_ref.tf              (Sprint 2 reference — read-only, no resources)
├── variables_general.tf           (tenancy, region, service_label)
├── variables_iam.tf               (10 compartment OCIDs from Sprint 1)
├── variables_net.tf               (CIDRs — reused from Sprint 2)
├── variables_s2_ref.tf            (Sprint 2 output OCIDs — DRG, attachments, subnets, Bastion, FW IP)
├── outputs.tf                     (Sprint 3 outputs for Sprint 4)
├── schema.yaml                    (ORM UI)
└── terraform.tfvars.template
```

---

## locals.tf — Sprint 3 Name Constants

Architect adds before the session:

```hcl
locals {
  # ── Forced Inspection — DRG Route Tables ──
  hub_spoke_mesh_drgrt_name = "drgrt_r_hub_spoke_mesh"   # Hub attachment — import distribution (dynamic)
  spoke_to_hub_drgrt_name   = "drgrt_spoke_to_hub"       # Spoke attachments — static 0/0 → Hub
  hub_import_dist_name      = "drgrd_r_hub_vcn_import"   # Import distribution — auto-learn VCN CIDRs
  hub_ingress_rt_name       = "rt_r_elz_nw_hub_ingress"  # VCN ingress RT on Hub DRG attachment

  # ── Logging ──
  nw_log_group_name         = "lg_r_elz_nw_flow"
  hub_fw_flow_log_name      = "fl_r_elz_nw_fw"
  hub_mgmt_flow_log_name    = "fl_r_elz_nw_mgmt"
  os_app_flow_log_name      = "fl_os_elz_nw_app"
  ts_app_flow_log_name      = "fl_ts_elz_nw_app"
  ss_app_flow_log_name      = "fl_ss_elz_nw_app"
  devt_app_flow_log_name    = "fl_devt_elz_nw_app"

  # ── Object Storage ──
  log_bucket_name           = "bkt_r_elz_sec_logs"

  # ── Events and Alarms ──
  drg_change_alarm_name     = "al_r_elz_sec_drg_change"
  rt_change_alarm_name      = "al_r_elz_sec_rt_change"
  notification_topic_name   = "nt_r_elz_sec_alerts"
  events_rule_name          = "ev_r_elz_sec_nw_changes"

  # ── Bastion Sessions ──
  bastion_session_os_name   = "bsn_os_elz_nw_ssh"
  bastion_session_ts_name   = "bsn_ts_elz_nw_ssh"
}
```

---

## T4 — sec_team4.tf — Forced Inspection Routing

T4 owns all DRG routing changes. This is the core of Sprint 3.

**What T4 creates:**

| Resource | Terraform Type | Purpose |
|---|---|---|
| Hub DRG RT | `oci_core_drg_route_table` | Import distribution — dynamic VCN CIDR learning. Assigned to Hub VCN attachment. |
| Import Distribution | `oci_core_drg_route_distribution` + `_statement` | Auto-learn VCN CIDRs. Hub DRG RT uses this. |
| Spoke DRG RT | `oci_core_drg_route_table` | Static route `0/0 → Hub VCN attachment`. Assigned to all 4 spoke attachments. |
| VCN Ingress RT | `oci_core_route_table` | `10.0.0.0/8 → Hub FW VNIC IP`. Attached to Hub DRG attachment `network_details`. |
| Hub FW Subnet RT update | `oci_core_route_table_attachment` (or inline rules) | Spoke CIDRs → DRG. Return path after firewall inspection. |

**What T4 modifies (in-place, no destroy):**

| Existing Resource | Change | Effect |
|---|---|---|
| `drga_os_elz_nw` | `drg_route_table_id` → spoke_to_hub DRG RT | OS traffic forced to Hub |
| `drga_ts_elz_nw` | `drg_route_table_id` → spoke_to_hub DRG RT | TS traffic forced to Hub |
| `drga_ss_elz_nw` | `drg_route_table_id` → spoke_to_hub DRG RT | SS traffic forced to Hub |
| `drga_devt_elz_nw` | `drg_route_table_id` → spoke_to_hub DRG RT | DEVT traffic forced to Hub |
| `drga_r_elz_nw_hub` | `drg_route_table_id` → hub_spoke_mesh DRG RT + VCN ingress RT | Hub learns all CIDRs, ingress routes to FW |
| `rt_r_elz_nw_fw` (Hub FW subnet RT) | Add rules: 10.1/24, 10.2/24, 10.3/24, 10.4/24 → DRG | Return path after FW inspection |

**Important:** The 5 DRG attachments already exist in Sprint 2 state. Sprint 3 adds `drg_route_table_id` to each — this is an in-place update, not destroy/recreate. The VCN ingress RT is a new `oci_core_route_table` attached to the Hub DRG attachment via `network_details.route_table_id`.

```hcl
# sec_team4.tf — Forced Inspection Routing (T4)

# ── Custom DRG Route Table — Hub (import distribution, dynamic learning) ──
resource "oci_core_drg_route_table" "hub_spoke_mesh" {
  drg_id                           = var.hub_drg_id
  display_name                     = local.hub_spoke_mesh_drgrt_name
  import_drg_route_distribution_id = oci_core_drg_route_distribution.hub_vcn_import.id
}

resource "oci_core_drg_route_distribution" "hub_vcn_import" {
  drg_id           = var.hub_drg_id
  display_name     = local.hub_import_dist_name
  distribution_type = "IMPORT"
}

resource "oci_core_drg_route_distribution_statement" "accept_vcn" {
  drg_route_distribution_id = oci_core_drg_route_distribution.hub_vcn_import.id
  action                    = "ACCEPT"
  match_criteria {
    match_type      = "DRG_ATTACHMENT_TYPE"
    attachment_type = "VCN"
  }
  priority = 1
}

# ── Custom DRG Route Table — Spoke (static route to Hub) ──
resource "oci_core_drg_route_table" "spoke_to_hub" {
  drg_id       = var.hub_drg_id
  display_name = local.spoke_to_hub_drgrt_name
  # No import distribution — this RT uses static routes only (inductive)
}

resource "oci_core_drg_route_table_route_rule" "force_hub" {
  drg_route_table_id         = oci_core_drg_route_table.spoke_to_hub.id
  destination_type           = "CIDR_BLOCK"
  destination                = "0.0.0.0/0"
  next_hop_drg_attachment_id = var.hub_drg_attachment_id
}

# ── VCN Ingress Route Table on Hub DRG Attachment ──
resource "oci_core_route_table" "hub_ingress" {
  compartment_id = var.nw_compartment_id
  vcn_id         = var.hub_vcn_id
  display_name   = local.hub_ingress_rt_name

  route_rules {
    network_entity_id = data.oci_core_private_ips.hub_fw_vnic.private_ips[0].id
    destination       = "10.0.0.0/8"
    destination_type  = "CIDR_BLOCK"
    description       = "All spoke traffic → Hub Sim FW for inspection"
  }
}

# ── Hub FW Subnet RT — return path after inspection ──
# These rules are ADDED to the existing rt_r_elz_nw_fw (Sprint 2 created it empty)
resource "oci_core_route_table" "hub_fw_return" {
  compartment_id = var.nw_compartment_id
  vcn_id         = var.hub_vcn_id
  display_name   = "rt_r_elz_nw_fw"  # Same name as Sprint 2 — updates in-place

  route_rules {
    network_entity_id = oci_core_drg.hub.id  # or var.hub_drg_id
    destination       = "10.1.0.0/24"
    destination_type  = "CIDR_BLOCK"
    description       = "OS spoke → DRG"
  }
  route_rules {
    network_entity_id = oci_core_drg.hub.id
    destination       = "10.2.0.0/24"
    destination_type  = "CIDR_BLOCK"
    description       = "SS spoke → DRG"
  }
  route_rules {
    network_entity_id = oci_core_drg.hub.id
    destination       = "10.3.0.0/24"
    destination_type  = "CIDR_BLOCK"
    description       = "TS spoke → DRG"
  }
  route_rules {
    network_entity_id = oci_core_drg.hub.id
    destination       = "10.4.0.0/24"
    destination_type  = "CIDR_BLOCK"
    description       = "DEVT spoke → DRG"
  }
}

# NOTE: DRG attachment reassignment happens by adding drg_route_table_id
# to the existing oci_core_drg_attachment resources in Sprint 2 team files.
# This is done via s2_sprint2_ref.tf or by updating the Sprint 2 state.
# See "Sprint 2 Attachment Updates" section below.
```

---

## T1 — sec_team1.tf — Bastion Session (OS Spoke)

Bastion service (`bas_r_elz_nw_hub`) was created in Sprint 2 by T4. Sprint 3 T1 creates a session to SSH into the OS Sim FW for validation.

```hcl
# sec_team1.tf — Bastion Session for OS spoke (T1)

resource "oci_bastion_session" "os_ssh" {
  bastion_id = var.bastion_id
  key_details {
    public_key_content = var.ssh_public_key
  }
  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = var.os_fw_instance_id
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
  }
  display_name           = local.bastion_session_os_name
  session_ttl_in_seconds = 1800
}
```

---

## T2 — sec_team2.tf — Bastion Session (TS Spoke)

```hcl
# sec_team2.tf — Bastion Session for TS spoke (T2)

resource "oci_bastion_session" "ts_ssh" {
  bastion_id = var.bastion_id
  key_details {
    public_key_content = var.ssh_public_key
  }
  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = var.ts_fw_instance_id
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
  }
  display_name           = local.bastion_session_ts_name
  session_ttl_in_seconds = 1800
}
```

---

## T3 — sec_team3.tf — Logging, Flow Logs, Object Storage, Events, Alarms

```hcl
# sec_team3.tf — Observability (T3)

# ── Log Group ──
resource "oci_logging_log_group" "nw_flow" {
  compartment_id = var.sec_compartment_id
  display_name   = local.nw_log_group_name
  description    = "VCN flow logs for all Sprint 2 subnets"
}

# ── VCN Flow Logs — one per subnet ──
resource "oci_logging_log" "hub_fw_flow" {
  display_name = local.hub_fw_flow_log_name
  log_group_id = oci_logging_log_group.nw_flow.id
  log_type     = "SERVICE"
  configuration {
    source {
      category    = "all"
      resource    = var.hub_fw_subnet_id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
  }
  is_enabled = true
}

resource "oci_logging_log" "hub_mgmt_flow" {
  display_name = local.hub_mgmt_flow_log_name
  log_group_id = oci_logging_log_group.nw_flow.id
  log_type     = "SERVICE"
  configuration {
    source {
      category    = "all"
      resource    = var.hub_mgmt_subnet_id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
  }
  is_enabled = true
}

resource "oci_logging_log" "os_app_flow" {
  display_name = local.os_app_flow_log_name
  log_group_id = oci_logging_log_group.nw_flow.id
  log_type     = "SERVICE"
  configuration {
    source {
      category    = "all"
      resource    = var.os_app_subnet_id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
  }
  is_enabled = true
}

resource "oci_logging_log" "ts_app_flow" {
  display_name = local.ts_app_flow_log_name
  log_group_id = oci_logging_log_group.nw_flow.id
  log_type     = "SERVICE"
  configuration {
    source {
      category    = "all"
      resource    = var.ts_app_subnet_id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
  }
  is_enabled = true
}

resource "oci_logging_log" "ss_app_flow" {
  display_name = local.ss_app_flow_log_name
  log_group_id = oci_logging_log_group.nw_flow.id
  log_type     = "SERVICE"
  configuration {
    source {
      category    = "all"
      resource    = var.ss_app_subnet_id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
  }
  is_enabled = true
}

resource "oci_logging_log" "devt_app_flow" {
  display_name = local.devt_app_flow_log_name
  log_group_id = oci_logging_log_group.nw_flow.id
  log_type     = "SERVICE"
  configuration {
    source {
      category    = "all"
      resource    = var.devt_app_subnet_id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
  }
  is_enabled = true
}

# ── Object Storage — log retention bucket ──
resource "oci_objectstorage_bucket" "logs" {
  compartment_id = var.sec_compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = local.log_bucket_name
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
  versioning     = "Enabled"

  freeform_tags = local.common_tags
}

# ── Notification Topic — alarm destination ──
resource "oci_ons_notification_topic" "security_alerts" {
  compartment_id = var.sec_compartment_id
  name           = local.notification_topic_name
  description    = "P1 alerts for DRG and route table changes"
}

# ── Events Rule — DRG and route table changes ──
resource "oci_events_rule" "nw_changes" {
  compartment_id = var.nw_compartment_id
  display_name   = local.events_rule_name
  is_enabled     = true
  description    = "Detect DRG attachment, route table, and security list changes"

  condition = jsonencode({
    eventType = [
      "com.oraclecloud.virtualnetwork.updatedrgroutetable",
      "com.oraclecloud.virtualnetwork.createdrgroutetable",
      "com.oraclecloud.virtualnetwork.deletedrgroutetable",
      "com.oraclecloud.virtualnetwork.updatedrgattachment",
      "com.oraclecloud.virtualnetwork.updateroutetable",
      "com.oraclecloud.virtualnetwork.updatesecuritylist"
    ]
  })

  actions {
    actions {
      action_type = "ONS"
      is_enabled  = true
      topic_id    = oci_ons_notification_topic.security_alerts.id
    }
  }
}

# ── Monitoring Alarm — DRG routing drift ──
resource "oci_monitoring_alarm" "drg_change" {
  compartment_id        = var.sec_compartment_id
  display_name          = local.drg_change_alarm_name
  namespace             = "oci_vcn"
  metric_compartment_id = var.nw_compartment_id
  query                 = "VcnFlowLogs[1m].count() > 0"
  severity              = "CRITICAL"
  is_enabled            = true
  pending_duration      = "PT5M"
  body                  = "DRG routing or VCN flow anomaly detected — verify change is authorised and matches Terraform state."
  destinations          = [oci_ons_notification_topic.security_alerts.id]
}
```

---

## Data Sources — data_sources.tf

```hcl
# data_sources.tf — shared data sources

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_private_ips" "hub_fw_vnic" {
  subnet_id = var.hub_fw_subnet_id
  # Filter to get the Hub Sim FW VNIC private IP
  # Alternative: pass var.hub_fw_private_ip directly
}

# Tag merge — same pattern as Sprint 2
locals {
  common_tags = {
    "C0-star-elz-v1.Environment" = "dev"
    "C0-star-elz-v1.Owner"       = "DSTA"
    "C0-star-elz-v1.Sprint"      = "3"
  }
}
```

---

## Sprint 2 Attachment Updates

Sprint 3 needs to reassign DRG attachments from auto-generated RT to custom RTs. There are two approaches:

**Option A — Update Sprint 2 state (recommended):** Add `drg_route_table_id` to each `oci_core_drg_attachment` in Sprint 2 team files. Run ORM Apply on Sprint 2 stack first. Then apply Sprint 3 stack.

**Option B — Import and manage in Sprint 3:** Import the 5 DRG attachments into Sprint 3 state using `import {}` blocks, then manage `drg_route_table_id` from Sprint 3.

Option A is cleaner — the attachment stays in the same state as the VCN and subnet it belongs to. Option B creates cross-state dependency.

---

## Test Cases

| TC | Description | How to Validate | Expected |
|---|---|---|---|
| TC-20 | Custom DRG RT exists and assigned | `oci network drg-route-table list --drg-id $DRG_ID --all` | drgrt_r_hub_spoke_mesh + drgrt_spoke_to_hub visible |
| TC-21 | Spoke attachments use spoke_to_hub RT | `oci network drg-attachment get --drg-attachment-id $OS_ATTACH_ID --query 'data."drg-route-table-id"'` | Points to spoke_to_hub DRG RT OCID |
| TC-22 | Forced inspection — OS → TS via Hub FW | SSH to OS Sim FW via Bastion, `traceroute 10.3.0.x` | Packet hits Hub FW IP (10.0.x.x) before reaching TS |
| TC-23 | VCN flow logs capturing | OCI Console → Logging → lg_r_elz_nw_flow | Flow log entries for Hub FW subnet showing spoke traffic |
| TC-24 | Events rule firing | Manually update a route table via Console, check notification topic | Event delivered to nt_r_elz_sec_alerts |
| TC-25 | Object Storage bucket exists | `oci os bucket get --bucket-name bkt_r_elz_sec_logs` | Bucket exists, versioning enabled, no public access |
| TC-26 | Bastion session — OS SSH | `oci bastion session get --session-id $OS_SESSION_ID` | State = ACTIVE, target = OS Sim FW instance |
| TC-27 | Bastion session — TS SSH | `oci bastion session get --session-id $TS_SESSION_ID` | State = ACTIVE, target = TS Sim FW instance |
| TC-28 | Vault exists and ACTIVE | `oci kms vault get --vault-id $VAULT_ID --query 'data."lifecycle-state"'` | ACTIVE |
| TC-29 | Master encryption key — AES-256 HSM | `oci kms key get --key-id $KEY_ID --endpoint $VAULT_MGMT_EP --query 'data.{"alg":"key-shape".algorithm,"len":"key-shape".length,"mode":"protection-mode"}'` | AES / 32 / HSM |
| TC-30 | Cloud Guard target ACTIVE | `oci cloud-guard target get --target-id $CG_TARGET_ID --query 'data."lifecycle-state"'` | ACTIVE, covers tenancy root |
| TC-31 | Cloud Guard detector recipes attached | `oci cloud-guard target get --target-id $CG_TARGET_ID --query 'data."target-detector-recipes"[].{name:"display-name"}'` | cgdr_r_elz_config + cgdr_r_elz_activity |
| TC-32 | Security Zone on SEC — ACTIVE | `oci cloud-guard security-zone get --security-zone-id $SZ_SEC_ID --query 'data."lifecycle-state"'` | ACTIVE |
| TC-33 | Security Zone on NW — ACTIVE | `oci cloud-guard security-zone get --security-zone-id $SZ_NW_ID --query 'data."lifecycle-state"'` | ACTIVE |
| TC-34 | SZ NW blocks public subnet | Create public subnet in C1_R_ELZ_NW via Console | HTTP 409 — violates security zone policy |
| TC-35 | SZ SEC blocks unencrypted volume | Create block volume without CMK in C1_R_ELZ_SEC | HTTP 409 — violates security zone policy |

**Gate:** TC-20 through TC-35 all PASS before Sprint 4.

---

## Deployment — Sprint 3 Day (9 March)

Sprint 3 day has **three ORM applies** in sequence — Sprint 1 (patch), Sprint 2 (no change needed), and Sprint 3 (new stack). All are run by Oracle/Architect.

### Step 0 — Pre-flight (night before)

```bash
# Confirm Sprint 2 complete
oci network vcn list --compartment-id $NW_CMP --query 'data[].{name:"display-name"}' | grep vcn | wc -l
# Expected: 5

oci network drg-attachment list --compartment-id $NW_CMP --drg-id $HUB_DRG_ID --query 'data[].{state:"lifecycle-state"}' | grep ATTACHED | wc -l
# Expected: 5

oci bastion bastion get --bastion-id $BASTION_ID --query 'data."lifecycle-state"'
# Expected: ACTIVE
```

### Step 1 — Sprint 1 ORM re-apply (IAM patch — 5 new policy statements)

**Why:** Sprint 3 creates Bastion sessions in `C1_R_ELZ_NW` and targets Sim FW instances in spoke compartments. No existing Sprint 1 policy grants `manage bastion-family` in `C1_R_ELZ_NW`, and no policy grants `read instance-family` on spoke compartments for Bastion target access. This patch also retroactively fixes Sprint 2 Bastion CLI access (Sprint 2 creation worked via ORM admin, but `UG_ELZ_NW` members get 403 on Bastion CLI commands without this).

**What changes:** 7 new statements — 5 in `UG_ELZ_NW-Policy`, 2 in `UG_ELZ_SEC-Policy`:

```hcl
# UG_ELZ_NW-Policy — iam_policies_team1.tf
"allow group UG_ELZ_NW to manage bastion-family in compartment C1_R_ELZ_NW",
"allow group UG_ELZ_NW to read instance-family in compartment C1_OS_ELZ_NW",
"allow group UG_ELZ_NW to read instance-family in compartment C1_TS_ELZ_NW",
"allow group UG_ELZ_NW to read instance-family in compartment C1_SS_ELZ_NW",
"allow group UG_ELZ_NW to read instance-family in compartment C1_DEVT_ELZ_NW"

# UG_ELZ_SEC-Policy — iam_policies_team1.tf
"allow group UG_ELZ_SEC to manage security-zone in compartment C1_R_ELZ_SEC",
"allow group UG_ELZ_SEC to manage security-zone in compartment C1_R_ELZ_NW"
```

**Process:**

| # | Action | Expected Result |
|---|---|---|
| 1a | Add 5 statements to `iam_policies_team1.tf` → `nw_admin_grants` list | — |
| 1b | Commit, push to `main` | — |
| 1c | Sprint 1 ORM stack → **Plan** | "2 to change" — UG_ELZ_NW-Policy +5, UG_ELZ_SEC-Policy +2 |
| 1d | Verify Plan: zero destroys, zero new resources | Only policy updates |
| 1e | **Apply** | ~30 seconds |
| 1f | Verify | See command below |

```bash
# Verify NW patch
oci iam policy get --policy-id $NW_POLICY_ID \
  --query 'data.statements[?contains(@, `bastion-family`)]'

# Verify SEC patch
oci iam policy get --policy-id $SEC_POLICY_ID \
  --query 'data.statements[?contains(@, `security-zone`)]'
```

### Step 1b — Verify Cloud Guard is ENABLED (prerequisite for Security Zones)

```bash
oci cloud-guard configuration get --compartment-id $TENANCY_OCID \
  --query 'data.status'
# Expected: ENABLED

# If not enabled:
oci cloud-guard configuration update --compartment-id $TENANCY_OCID \
  --reporting-region ap-singapore-2 --status ENABLED
```

Security Zones require Cloud Guard to be enabled. If Cloud Guard is not enabled, `oci_cloud_guard_security_zone` and `oci_cloud_guard_target` resources will fail on apply.

### Step 2 — Sprint 3 ORM apply (single phase — no gate)

| # | Action | Expected Result |
|---|---|---|
| 2a | Create Sprint 3 ORM stack, upload `sprint3/` directory | — |
| 2b | Configure variables from Sprint 1 + Sprint 2 outputs (see `terraform.tfvars.template`) | — |
| 2c | **Plan** | "37 to add, 0 to change, 0 to destroy" (36 resources + 1 import) |
| 2d | Verify Plan: Service Gateway, DRG RTs, flow logs, events, Bastion sessions all present | — |
| 2e | **Apply** | ~5 minutes |
| 2f | Run TC-20 through TC-35 | All PASS |

```bash
# Export Sprint 3 outputs for Sprint 4
terraform output -json > sprint3_outputs.json
git tag sprint3-complete && git push origin sprint3-complete
```

### IAM Coverage Matrix — All 3 Sprints (Complete)

| Sprint | Resource | OCI Verb | Compartment | Policy | Status |
|---|---|---|---|---|---|
| **S1** | Compartments, groups, policies | manage iam-family | tenancy root | Tenancy admin | ✅ |
| **S1** | Tag namespace + tags | manage tag-namespaces | tenancy root | Tenancy admin | ✅ |
| **S2** | VCNs, subnets, RTs, security lists | manage virtual-network-family | C1_R_ELZ_NW + spokes | UG_ELZ_NW + UG_*_ELZ_NW | ✅ |
| **S2** | DRGs + attachments | manage drgs | C1_R_ELZ_NW | UG_ELZ_NW | ✅ |
| **S2** | Sim FW instances | manage instances | C1_R_ELZ_NW + spokes | UG_ELZ_NW + UG_*_ELZ_NW | ✅ |
| **S2** | Bastion service | manage bastion-family | C1_R_ELZ_NW | **⚡ Patched in Step 1** | ✅ after patch |
| **S3** | DRG route tables, distributions | manage drgs | C1_R_ELZ_NW | UG_ELZ_NW | ✅ |
| **S3** | VCN route tables (ingress, FW) | manage virtual-network-family | C1_R_ELZ_NW | UG_ELZ_NW | ✅ |
| **S3** | Service Gateway | manage virtual-network-family | C1_R_ELZ_NW | UG_ELZ_NW (SG is part of VNF) | ✅ |
| **S3** | DRG attachment management (5) | manage drgs | C1_R_ELZ_NW | UG_ELZ_NW | ✅ |
| **S3** | Log group + flow logs (7) | manage logging-family | C1_R_ELZ_SEC | UG_ELZ_SEC | ✅ |
| **S3** | Object Storage bucket | manage object-family | C1_R_ELZ_SEC | UG_ELZ_SEC | ✅ |
| **S3** | Notification topic | manage ons-family | C1_R_ELZ_SEC | UG_ELZ_SEC | ✅ |
| **S3** | Events rule | manage events-family | C1_R_ELZ_SEC | UG_ELZ_SEC | ✅ |
| **S3** | Monitoring alarm | manage alarms | C1_R_ELZ_SEC | UG_ELZ_SEC | ✅ |
| **S3** | Bastion sessions (2) | manage bastion-family | C1_R_ELZ_NW | **⚡ Patched in Step 1** | ✅ after patch |
| **S3** | Bastion → spoke targets | read instance-family | spoke cmps | **⚡ Patched in Step 1** | ✅ after patch |

---

## Resource Count

| Category | New Resources | Modified (in Sprint 2 state) |
|---|---|---|
| DRG Route Tables | 2 (hub_spoke_mesh, spoke_to_hub) | — |
| DRG Route Distribution | 1 + 1 statement | — |
| DRG Route Rule | 1 (static 0/0 → Hub) | — |
| VCN Route Table | 1 (hub_ingress) | 1 (rt_r_elz_nw_fw — imported, add spoke CIDRs + SG route) |
| DRG Attachment Management | 5 (reassign drg_route_table_id) | — |
| Service Gateway | 1 (sgw_r_elz_nw_hub) | — |
| Log Group | 1 | — |
| Flow Logs | 6 (one per subnet) | — |
| Object Storage Bucket | 1 | — |
| Notification Topic | 1 | — |
| Events Rule | 1 | — |
| Monitoring Alarm | 1 | — |
| Bastion Sessions | 2 | — |
| KMS Vault | 1 (vlt_r_elz_sec) | — |
| KMS Key | 1 (key_r_elz_sec_master, AES-256 HSM) | — |
| Cloud Guard Detector Recipes | 2 (config + activity, cloned from Oracle) | — |
| Cloud Guard Responder Recipe | 1 (cloned from Oracle) | — |
| Cloud Guard Target | 1 (tenancy root) | — |
| Security Zone Recipes | 2 (SEC encryption + NW isolation) | — |
| Security Zones | 2 (C1_R_ELZ_SEC + C1_R_ELZ_NW) | — |
| **Total** | **36 resources** | **1 imported from Sprint 2** |

Sprint 2 resource count: 38 (32 + 6 security lists). Sprint 3 adds 36 new (including 5 attachment management + 1 imported RT + 10 security resources) = **74 total resources under Terraform management across Sprint 2 + Sprint 3.**

---

## Known Considerations

**Tag namespace (Sprint 1 fix):** `mon_tags.tf` in Sprint 1 uses `depends_on` on the tag namespace resource to prevent race condition. Sprint 3 references tags via `local.common_tags` map — no depends_on needed.

**Bastion sessions are ephemeral:** `oci_bastion_session` has a TTL (default 30 min). Sessions expire and need to be recreated for subsequent validation. Terraform will show drift when the session expires — this is expected. Use `lifecycle { ignore_changes = [session_ttl_in_seconds] }` if needed.

**Hub FW Subnet RT:** Sprint 2 created `rt_r_elz_nw_fw` with rules pointing `0/0 → DRG`. Sprint 3 adds 4 specific spoke CIDR rules to this same RT. This is managed in Sprint 3's `sec_team4.tf` but references the existing RT. If using separate ORM stacks, use `import {}` to bring the RT into Sprint 3 state, or update it in Sprint 2 state alongside the attachment changes.

**VCN ingress RT vs Subnet RT:** Both are `oci_core_route_table`. The VCN ingress RT is attached to the DRG attachment's `network_details.route_table_id`, not to a subnet. This is a common confusion point — see DRG Routing Guide Section 1.

---

**Sprint 3 owner:** DSTA + Oracle | **Gate to Sprint 4:** TC-20 through TC-35 all PASS
