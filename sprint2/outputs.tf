# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# STAR ELZ V1 — sprint2
#
# =============================================================================
# OUTPUTS — SPRINT 2 → SPRINT 3 HANDOFF
#
# After Phase 1 apply:
#   terraform output hub_drg_id
#   Share with T1, T2, T3 for Phase 2 apply.
#
# After Phase 2 apply:
#   terraform output -json > sprint2_outputs.json
#   Share with Sprint 3 (Security) lead.
#
# TC-07: Validate 5 VCNs created.
# TC-08: Validate 6 subnets created (hub_fw, hub_mgmt, os_app, ts_app, ss_app, devt_app).
# TC-09: Validate Hub DRG has 5 attachments after Phase 2 (hub + 4 spokes).
# TC-10: Validate 4 Sim FW instances RUNNING (hub, OS, TS, SS).
# TC-11: Validate Hub Bastion ACTIVE.
# TC-12: ORM Plan shows zero drift after Phase 2.
# =============================================================================

# ---------------------------------------------------------------------------
# PHASE 1 OUTPUTS — available after Phase 1 apply
# ---------------------------------------------------------------------------

output "hub_drg_id" {
  description = "OCID of Hub DRG. CRITICAL: Share with T1/T2/T3 for Phase 2. Paste into ORM Variable: hub_drg_id"
  value       = oci_core_drg.hub.id
}

output "ew_hub_drg_id" {
  description = "OCID of Inter E-W DRG (V2 placeholder). TC-12b: validate exists in C1_R_ELZ_NW."
  value       = oci_core_drg.ew_hub.id
}

output "hub_vcn_id" {
  description = "OCID of Hub VCN (10.0.0.0/16)."
  value       = oci_core_vcn.hub.id
}

output "hub_fw_subnet_id" {
  description = "OCID of Hub FW subnet (10.0.0.0/24)."
  value       = oci_core_subnet.hub_fw.id
}

output "hub_mgmt_subnet_id" {
  description = "OCID of Hub MGMT subnet (10.0.1.0/24)."
  value       = oci_core_subnet.hub_mgmt.id
}

output "os_vcn_id" {
  description = "OCID of OS spoke VCN (10.1.0.0/24)."
  value       = oci_core_vcn.os.id
}

output "ts_vcn_id" {
  description = "OCID of TS spoke VCN (10.3.0.0/24)."
  value       = oci_core_vcn.ts.id
}

output "ss_vcn_id" {
  description = "OCID of SS spoke VCN (10.2.0.0/24)."
  value       = oci_core_vcn.ss.id
}

output "devt_vcn_id" {
  description = "OCID of DEVT spoke VCN (10.4.0.0/24)."
  value       = oci_core_vcn.devt.id
}

output "os_app_subnet_id" {
  description = "OCID of OS app subnet (10.1.0.0/24). Full spoke VCN CIDR in V1."
  value       = oci_core_subnet.os_app.id
}

output "ts_app_subnet_id" {
  description = "OCID of TS app subnet (10.3.0.0/24)."
  value       = oci_core_subnet.ts_app.id
}

output "ss_app_subnet_id" {
  description = "OCID of SS app subnet (10.2.0.0/24)."
  value       = oci_core_subnet.ss_app.id
}

output "devt_app_subnet_id" {
  description = "OCID of DEVT app subnet (10.4.0.0/24)."
  value       = oci_core_subnet.devt_app.id
}

# ---------------------------------------------------------------------------
# PHASE 2 OUTPUTS — available after Phase 2 apply
# count-based resources: index [0] safe because outputs only evaluated post-apply
# ---------------------------------------------------------------------------

output "sim_fw_hub_id" {
  description = "OCID of Hub Sim FW instance. Phase 2 only."
  value       = length(oci_core_instance.sim_fw_hub) > 0 ? oci_core_instance.sim_fw_hub[0].id : "not-provisioned-complete-phase2-first"
}

output "sim_fw_os_id" {
  description = "OCID of OS Sim FW instance. Phase 2 only."
  value       = length(oci_core_instance.sim_fw_os) > 0 ? oci_core_instance.sim_fw_os[0].id : "not-provisioned-complete-phase2-first"
}

output "sim_fw_ts_id" {
  description = "OCID of TS Sim FW instance. Phase 2 only."
  value       = length(oci_core_instance.sim_fw_ts) > 0 ? oci_core_instance.sim_fw_ts[0].id : "not-provisioned-complete-phase2-first"
}

output "sim_fw_ss_id" {
  description = "OCID of SS Sim FW instance. Phase 2 only."
  value       = length(oci_core_instance.sim_fw_ss) > 0 ? oci_core_instance.sim_fw_ss[0].id : "not-provisioned-complete-phase2-first"
}

output "hub_bastion_id" {
  description = "OCID of Hub Bastion. Phase 2 only. TC-11: state must be ACTIVE."
  value       = length(oci_bastion_bastion.hub) > 0 ? oci_bastion_bastion.hub[0].id : "not-provisioned-complete-phase2-first"
}

# ---------------------------------------------------------------------------
# SUMMARY MAP — full network topology for sprint2_outputs.json handoff
# ---------------------------------------------------------------------------
output "sprint2_network_summary" {
  description = "Complete network summary for Sprint 3 security layer."
  value = {
    hub_drg_id    = oci_core_drg.hub.id
    hub_vcn_id    = oci_core_vcn.hub.id
    phase2_active = local.phase2_enabled
    vcn_cidrs = {
      hub  = local.hub_vcn_cidr
      os   = local.os_vcn_cidr
      ts   = local.ts_vcn_cidr
      ss   = local.ss_vcn_cidr
      devt = local.devt_vcn_cidr
    }
    subnet_ids = {
      hub_fw   = oci_core_subnet.hub_fw.id
      hub_mgmt = oci_core_subnet.hub_mgmt.id
      os_app   = oci_core_subnet.os_app.id
      ts_app   = oci_core_subnet.ts_app.id
      ss_app   = oci_core_subnet.ss_app.id
      devt_app = oci_core_subnet.devt_app.id
    }
  }
}
