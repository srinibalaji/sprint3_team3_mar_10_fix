# =============================================================================
# STAR ELZ V1 — IAM Groups — MODULE ORCHESTRATOR
# This file ONLY calls the lz_groups module and defines shared locals.
# It does NOT define any individual groups.
#
# EACH TEAM OWNS THEIR OWN FILE:
#   iam_groups_team1.tf — Team 1: NW-ADMIN-GROUP, SEC-ADMIN-GROUP           (2 groups)
#   iam_groups_team2.tf — Team 2: SOC-GROUP, OPS-ADMIN-GROUP                (2 groups)
#   iam_groups_team3.tf — Team 3: CSVCS-ADMIN-GROUP, DEVT-CSVCS-ADMIN-GROUP (2 groups)
#   iam_groups_team4.tf — Team 4: OS-NW-ADMIN-GROUP, SS-NW-ADMIN-GROUP,
#                                  TS-NW-ADMIN-GROUP, DEVT-NW-ADMIN-GROUP    (4 groups)
#   Total TF-managed: 10 groups
#
# MANUAL GROUPS (2) — OCI Console, Team 4, Sprint 1 Day 1:
#   star-ug-sim-ext   — TEMP V1 ONLY (simulated external agency users)
#   star-ug-sim-child — TEMP V1 ONLY (simulated child tenancy users)
#   Record OCIDs in State Book: V1_Manual_Resources tab
# =============================================================================

locals {
  #------------------------------------------------------------------------------------------------------
  #-- Any of these local variables can be overridden in a _override.tf file
  #------------------------------------------------------------------------------------------------------
  custom_groups_defined_tags  = null
  custom_groups_freeform_tags = null

  # Optional group name overrides — set in _override.tf to rename, else defaults apply
  custom_nw_admin_group_name         = null
  custom_sec_admin_group_name        = null
  custom_soc_group_name              = null
  custom_ops_admin_group_name        = null
  custom_csvcs_admin_group_name      = null
  custom_devt_csvcs_admin_group_name = null
  custom_os_nw_admin_group_name      = null
  custom_ss_nw_admin_group_name      = null
  custom_ts_nw_admin_group_name      = null
  custom_devt_nw_admin_group_name    = null
}

locals {
  #------------------------------------------------------------------------------------------------------
  #-- These variables are NOT meant to be overridden
  #------------------------------------------------------------------------------------------------------

  #-----------------------------------------------------------
  #----- Tags applied to all groups
  #-----------------------------------------------------------
  default_groups_defined_tags  = null
  default_groups_freeform_tags = local.landing_zone_tags

  groups_defined_tags  = local.custom_groups_defined_tags != null ? merge(local.custom_groups_defined_tags, local.default_groups_defined_tags) : local.default_groups_defined_tags
  groups_freeform_tags = local.custom_groups_freeform_tags != null ? merge(local.custom_groups_freeform_tags, local.default_groups_freeform_tags) : local.default_groups_freeform_tags

  #-----------------------------------------------------------
  #----- Group map keys — referenced by all team files and iam_policies*.tf
  #-----------------------------------------------------------
  nw_admin_group_key         = "NW-ADMIN-GROUP"
  sec_admin_group_key        = "SEC-ADMIN-GROUP"
  soc_group_key              = "SOC-GROUP"
  ops_admin_group_key        = "OPS-ADMIN-GROUP"
  csvcs_admin_group_key      = "CSVCS-ADMIN-GROUP"
  devt_csvcs_admin_group_key = "DEVT-CSVCS-ADMIN-GROUP"
  os_nw_admin_group_key      = "OS-NW-ADMIN-GROUP"
  ss_nw_admin_group_key      = "SS-NW-ADMIN-GROUP"
  ts_nw_admin_group_key      = "TS-NW-ADMIN-GROUP"
  devt_nw_admin_group_key    = "DEVT-NW-ADMIN-GROUP"

  #-----------------------------------------------------------
  #----- Group names — custom override or default
  #-----------------------------------------------------------
  provided_nw_admin_group_name         = coalesce(local.custom_nw_admin_group_name,         "${var.service_label}-ug-elz-nw")
  provided_sec_admin_group_name        = coalesce(local.custom_sec_admin_group_name,         "${var.service_label}-ug-elz-sec")
  provided_soc_group_name              = coalesce(local.custom_soc_group_name,               "${var.service_label}-ug-elz-soc")
  provided_ops_admin_group_name        = coalesce(local.custom_ops_admin_group_name,         "${var.service_label}-ug-elz-ops")
  provided_csvcs_admin_group_name      = coalesce(local.custom_csvcs_admin_group_name,       "${var.service_label}-ug-elz-csvcs")
  provided_devt_csvcs_admin_group_name = coalesce(local.custom_devt_csvcs_admin_group_name,  "${var.service_label}-ug-devt-csvcs")
  provided_os_nw_admin_group_name      = coalesce(local.custom_os_nw_admin_group_name,       "${var.service_label}-ug-os-elz-nw")
  provided_ss_nw_admin_group_name      = coalesce(local.custom_ss_nw_admin_group_name,       "${var.service_label}-ug-ss-elz-nw")
  provided_ts_nw_admin_group_name      = coalesce(local.custom_ts_nw_admin_group_name,       "${var.service_label}-ug-ts-elz-nw")
  provided_devt_nw_admin_group_name    = coalesce(local.custom_devt_nw_admin_group_name,     "${var.service_label}-ug-devt-elz-nw")

  #-----------------------------------------------------------
  #----- Merge all 4 team group maps — each team edits only their own file
  #-----------------------------------------------------------
  groups_configuration = {
    default_defined_tags  : local.groups_defined_tags
    default_freeform_tags : local.groups_freeform_tags

    groups : merge(
      local.team1_groups,  # NW-ADMIN-GROUP, SEC-ADMIN-GROUP
      local.team2_groups,  # SOC-GROUP, OPS-ADMIN-GROUP
      local.team3_groups,  # CSVCS-ADMIN-GROUP, DEVT-CSVCS-ADMIN-GROUP
      local.team4_groups   # OS-NW-ADMIN-GROUP, SS-NW-ADMIN-GROUP, TS-NW-ADMIN-GROUP, DEVT-NW-ADMIN-GROUP
    )
  }

  #---------------------------------------------------------------------------------------
  #----- Group names from module output — used in iam_policies*.tf statement strings
  #---------------------------------------------------------------------------------------
  nw_admin_group_name          = [module.lz_groups.groups[local.nw_admin_group_key].name]
  sec_admin_group_name         = [module.lz_groups.groups[local.sec_admin_group_key].name]
  soc_group_name               = [module.lz_groups.groups[local.soc_group_key].name]
  ops_admin_group_name         = [module.lz_groups.groups[local.ops_admin_group_key].name]
  csvcs_admin_group_name       = [module.lz_groups.groups[local.csvcs_admin_group_key].name]
  devt_csvcs_admin_group_name  = [module.lz_groups.groups[local.devt_csvcs_admin_group_key].name]
  os_nw_admin_group_name       = [module.lz_groups.groups[local.os_nw_admin_group_key].name]
  ss_nw_admin_group_name       = [module.lz_groups.groups[local.ss_nw_admin_group_key].name]
  ts_nw_admin_group_name       = [module.lz_groups.groups[local.ts_nw_admin_group_key].name]
  devt_nw_admin_group_name     = [module.lz_groups.groups[local.devt_nw_admin_group_key].name]
}

#------------------------------------------------------------------------
#----- Module call — same pattern as iam_compartments.tf
#------------------------------------------------------------------------
module "lz_groups" {
  source               = "github.com/oci-landing-zones/terraform-oci-modules-iam//groups?ref=v0.3.1"
  providers            = { oci = oci.home }
  tenancy_ocid         = var.tenancy_ocid
  groups_configuration = local.groups_configuration
}
