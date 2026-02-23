# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# OCI ELZ Landing Zone V1 - aligned to terraform-oci-core-landingzone

locals {
  #------------------------------------------------------------------------------------------------------
  #-- Any of these local variables can be overridden in a _override.tf file
  #------------------------------------------------------------------------------------------------------
  custom_groups_defined_tags  = null
  custom_groups_freeform_tags = null

  # Optional group name overrides
  custom_nw_admin_group_name        = null
  custom_sec_admin_group_name       = null
  custom_soc_group_name             = null
  custom_ops_admin_group_name       = null
  custom_csvcs_admin_group_name     = null
  custom_devt_csvcs_admin_group_name = null
  custom_os_nw_admin_group_name     = null
  custom_ss_nw_admin_group_name     = null
  custom_ts_nw_admin_group_name     = null
  custom_devt_nw_admin_group_name   = null
}

#------------------------------------------------------------------------
#----- Module call - same pattern as core LZ iam_groups.tf
#------------------------------------------------------------------------
module "lz_groups" {
  source               = "github.com/oci-landing-zones/terraform-oci-modules-iam//groups?ref=v0.3.1"
  providers            = { oci = oci.home }
  tenancy_ocid         = var.tenancy_ocid
  groups_configuration = local.groups_configuration
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
  #----- Group keys
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
  #----- Group names (custom override or default)
  #-----------------------------------------------------------
  provided_nw_admin_group_name        = coalesce(local.custom_nw_admin_group_name,         "${var.service_label}-ug-elz-nw")
  provided_sec_admin_group_name       = coalesce(local.custom_sec_admin_group_name,        "${var.service_label}-ug-elz-sec")
  provided_soc_group_name             = coalesce(local.custom_soc_group_name,              "${var.service_label}-ug-elz-soc")
  provided_ops_admin_group_name       = coalesce(local.custom_ops_admin_group_name,        "${var.service_label}-ug-elz-ops")
  provided_csvcs_admin_group_name     = coalesce(local.custom_csvcs_admin_group_name,      "${var.service_label}-ug-elz-csvcs")
  provided_devt_csvcs_admin_group_name = coalesce(local.custom_devt_csvcs_admin_group_name, "${var.service_label}-ug-devt-csvcs")
  provided_os_nw_admin_group_name     = coalesce(local.custom_os_nw_admin_group_name,      "${var.service_label}-ug-os-elz-nw")
  provided_ss_nw_admin_group_name     = coalesce(local.custom_ss_nw_admin_group_name,      "${var.service_label}-ug-ss-elz-nw")
  provided_ts_nw_admin_group_name     = coalesce(local.custom_ts_nw_admin_group_name,      "${var.service_label}-ug-ts-elz-nw")
  provided_devt_nw_admin_group_name   = coalesce(local.custom_devt_nw_admin_group_name,    "${var.service_label}-ug-devt-elz-nw")

  #------------------------------------------------------------------------
  #----- Groups configuration map - input to module
  #------------------------------------------------------------------------
  groups_configuration = {
    default_defined_tags  : local.groups_defined_tags
    default_freeform_tags : local.groups_freeform_tags

    groups : {
      # Global network admin - manages hub VCN, both DRGs, route tables
      (local.nw_admin_group_key) : {
        name        : local.provided_nw_admin_group_name,
        description : "${var.lz_provenant_label} Global Network Administrators.",
        defined_tags  : local.groups_defined_tags,
        freeform_tags : local.groups_freeform_tags
      },
      # Security admin - Vault, Cloud Guard, Bastion, Security Zones
      (local.sec_admin_group_key) : {
        name        : local.provided_sec_admin_group_name,
        description : "${var.lz_provenant_label} Security Administrators.",
        defined_tags  : local.groups_defined_tags,
        freeform_tags : local.groups_freeform_tags
      },
      # SOC - read-only security monitoring
      (local.soc_group_key) : {
        name        : local.provided_soc_group_name,
        description : "${var.lz_provenant_label} SOC Analysts - read-only security monitoring.",
        defined_tags  : local.groups_defined_tags,
        freeform_tags : local.groups_freeform_tags
      },
      # Operations admin - logging, monitoring, deployment
      (local.ops_admin_group_key) : {
        name        : local.provided_ops_admin_group_name,
        description : "${var.lz_provenant_label} Operations Administrators.",
        defined_tags  : local.groups_defined_tags,
        freeform_tags : local.groups_freeform_tags
      },
      # Common services admin
      (local.csvcs_admin_group_key) : {
        name        : local.provided_csvcs_admin_group_name,
        description : "${var.lz_provenant_label} Common Services Administrators.",
        defined_tags  : local.groups_defined_tags,
        freeform_tags : local.groups_freeform_tags
      },
      # Dev common services admin
      (local.devt_csvcs_admin_group_key) : {
        name        : local.provided_devt_csvcs_admin_group_name,
        description : "${var.lz_provenant_label} Development Common Services Administrators.",
        defined_tags  : local.groups_defined_tags,
        freeform_tags : local.groups_freeform_tags
      },
      # Spoke network admins
      (local.os_nw_admin_group_key) : {
        name        : local.provided_os_nw_admin_group_name,
        description : "${var.lz_provenant_label} Operational Services Network Administrators.",
        defined_tags  : local.groups_defined_tags,
        freeform_tags : local.groups_freeform_tags
      },
      (local.ss_nw_admin_group_key) : {
        name        : local.provided_ss_nw_admin_group_name,
        description : "${var.lz_provenant_label} Shared Services Network Administrators.",
        defined_tags  : local.groups_defined_tags,
        freeform_tags : local.groups_freeform_tags
      },
      (local.ts_nw_admin_group_key) : {
        name        : local.provided_ts_nw_admin_group_name,
        description : "${var.lz_provenant_label} Tenant Services Network Administrators.",
        defined_tags  : local.groups_defined_tags,
        freeform_tags : local.groups_freeform_tags
      },
      (local.devt_nw_admin_group_key) : {
        name        : local.provided_devt_nw_admin_group_name,
        description : "${var.lz_provenant_label} Development/Test Network Administrators.",
        defined_tags  : local.groups_defined_tags,
        freeform_tags : local.groups_freeform_tags
      }
    }
  }

  #---------------------------------------------------------------------------------------
  #----- Group names from module output - used in policy statements
  #---------------------------------------------------------------------------------------
  nw_admin_group_name        = [module.lz_groups.groups[local.nw_admin_group_key].name]
  sec_admin_group_name       = [module.lz_groups.groups[local.sec_admin_group_key].name]
  soc_group_name             = [module.lz_groups.groups[local.soc_group_key].name]
  ops_admin_group_name       = [module.lz_groups.groups[local.ops_admin_group_key].name]
  csvcs_admin_group_name     = [module.lz_groups.groups[local.csvcs_admin_group_key].name]
  devt_csvcs_admin_group_name = [module.lz_groups.groups[local.devt_csvcs_admin_group_key].name]
  os_nw_admin_group_name     = [module.lz_groups.groups[local.os_nw_admin_group_key].name]
  ss_nw_admin_group_name     = [module.lz_groups.groups[local.ss_nw_admin_group_key].name]
  ts_nw_admin_group_name     = [module.lz_groups.groups[local.ts_nw_admin_group_key].name]
  devt_nw_admin_group_name   = [module.lz_groups.groups[local.devt_nw_admin_group_key].name]
}
