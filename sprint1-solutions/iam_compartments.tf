# =============================================================================
# STAR ELZ V1 — IAM Compartments — MODULE ORCHESTRATOR
# This file ONLY calls the lz_compartments module and defines shared locals.
# It does NOT define any individual compartments.
#
# EACH TEAM OWNS THEIR OWN FILE:
#   iam_cmps_team1.tf  — Team 1: NW, SEC           (2 compartments)
#   iam_cmps_team2.tf  — Team 2: SOC, OPS          (2 compartments)
#   iam_cmps_team3.tf  — Team 3: CSVCS, DEVT_CSVCS (2 compartments)
#   iam_cmps_team4.tf  — Team 4: OS, SS, TS, DEVT  (4 compartments)
#   Total TF-managed: 10 compartments
#
# MANUAL COMPARTMENTS (2) — OCI Console, Team 4, Sprint 1 Day 1:
#   star-sim-ext-cmp   — TEMP V1 ONLY (Dummy AD, DNS Bridge)
#   star-sim-child-cmp — TEMP V1 ONLY (Hello World workload)
#   Paste OCIDs into terraform.tfvars: sim_ext_compartment_id, sim_child_compartment_id
# =============================================================================

locals {
  custom_cmps_defined_tags  = null
  custom_cmps_freeform_tags = null

  default_cmps_defined_tags  = null
  default_cmps_freeform_tags = local.landing_zone_tags

  cmps_defined_tags  = local.custom_cmps_defined_tags != null ? merge(local.custom_cmps_defined_tags, local.default_cmps_defined_tags) : local.default_cmps_defined_tags
  cmps_freeform_tags = local.custom_cmps_freeform_tags != null ? merge(local.custom_cmps_freeform_tags, local.default_cmps_freeform_tags) : local.default_cmps_freeform_tags

  # Compartment map keys — referenced by all downstream modules
  nw_compartment_key         = "NW-CMP"
  sec_compartment_key        = "SEC-CMP"
  soc_compartment_key        = "SOC-CMP"
  ops_compartment_key        = "OPS-CMP"
  csvcs_compartment_key      = "CSVCS-CMP"
  devt_csvcs_compartment_key = "DEVT-CSVCS-CMP"
  os_nw_compartment_key      = "OS-NW-CMP"
  ss_nw_compartment_key      = "SS-NW-CMP"
  ts_nw_compartment_key      = "TS-NW-CMP"
  devt_nw_compartment_key    = "DEVT-NW-CMP"

  # Compartment names — override via variables_iam.tf vars, else use default
  provided_nw_compartment_name         = coalesce(var.custom_nw_compartment_name,         "${var.service_label}-r-elz-nw-cmp")
  provided_sec_compartment_name        = coalesce(var.custom_sec_compartment_name,        "${var.service_label}-r-elz-sec-cmp")
  provided_soc_compartment_name        = coalesce(var.custom_soc_compartment_name,        "${var.service_label}-r-elz-soc-cmp")
  provided_ops_compartment_name        = coalesce(var.custom_ops_compartment_name,        "${var.service_label}-r-elz-ops-cmp")
  provided_csvcs_compartment_name      = coalesce(var.custom_csvcs_compartment_name,      "${var.service_label}-r-elz-csvcs-cmp")
  provided_devt_csvcs_compartment_name = coalesce(var.custom_devt_csvcs_compartment_name, "${var.service_label}-r-elz-devt-csvcs-cmp")
  provided_os_nw_compartment_name      = coalesce(var.custom_os_nw_compartment_name,      "${var.service_label}-os-elz-nw-cmp")
  provided_ss_nw_compartment_name      = coalesce(var.custom_ss_nw_compartment_name,      "${var.service_label}-ss-elz-nw-cmp")
  provided_ts_nw_compartment_name      = coalesce(var.custom_ts_nw_compartment_name,      "${var.service_label}-ts-elz-nw-cmp")
  provided_devt_nw_compartment_name    = coalesce(var.custom_devt_nw_compartment_name,    "${var.service_label}-devt-elz-nw-cmp")

  # Merge all 4 team compartment maps — each team edits only their own file
  compartments_configuration = {
    default_parent_id : var.tenancy_ocid
    enable_delete     : local.enable_cmp_delete
    compartments : merge(
      local.team1_compartments,  # NW, SEC
      local.team2_compartments,  # SOC, OPS
      local.team3_compartments,  # CSVCS, DEVT_CSVCS
      local.team4_compartments   # OS_NW, SS_NW, TS_NW, DEVT_NW
    )
  }

  # Compartment IDs from module output — used by all downstream modules
  nw_compartment_id         = module.lz_compartments.compartments[local.nw_compartment_key].id
  sec_compartment_id        = module.lz_compartments.compartments[local.sec_compartment_key].id
  soc_compartment_id        = module.lz_compartments.compartments[local.soc_compartment_key].id
  ops_compartment_id        = module.lz_compartments.compartments[local.ops_compartment_key].id
  csvcs_compartment_id      = module.lz_compartments.compartments[local.csvcs_compartment_key].id
  devt_csvcs_compartment_id = module.lz_compartments.compartments[local.devt_csvcs_compartment_key].id
  os_nw_compartment_id      = module.lz_compartments.compartments[local.os_nw_compartment_key].id
  ss_nw_compartment_id      = module.lz_compartments.compartments[local.ss_nw_compartment_key].id
  ts_nw_compartment_id      = module.lz_compartments.compartments[local.ts_nw_compartment_key].id
  devt_nw_compartment_id    = module.lz_compartments.compartments[local.devt_nw_compartment_key].id

  # Manual compartment IDs — created in OCI Console, OCIDs passed via tfvars
  sim_ext_compartment_id   = var.sim_ext_compartment_id
  sim_child_compartment_id = var.sim_child_compartment_id
}

module "lz_compartments" {
  source                     = "github.com/oci-landing-zones/terraform-oci-modules-iam//compartments?ref=v0.3.1"
  providers                  = { oci = oci.home }
  tenancy_ocid               = var.tenancy_ocid
  compartments_configuration = local.compartments_configuration
}
