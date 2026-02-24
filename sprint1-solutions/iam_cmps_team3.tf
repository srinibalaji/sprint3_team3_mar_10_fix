# =============================================================================
# STAR ELZ V1 — IAM Compartments — TEAM 3 OWNED FILE
# Team 3 domain: Shared Services (CSVCS, DEVT_CSVCS)
# Sprint 1, Week 1
# Branch: sprint1/iam-compartments-team3
# =============================================================================
#
# COMPARTMENTS IN THIS FILE (2 of 10 TF-managed):
#   5. star-r-elz-csvcs-cmp      — Common Shared Services: APM, File Transfer, ServiceNow, Jira
#   6. star-r-elz-devt-csvcs-cmp — Dev Common Services: development toolchain shared services
# =============================================================================

locals {
  team3_compartments = {

    # -------------------------------------------------------------------------
    # CSVCS — Common Shared Services Compartment
    # Contains: Data Exchange, File Transfer, File Storage, APM, ServiceNow, Jira
    # Owner: UG_ELZ_CSVCS
    # -------------------------------------------------------------------------
    (local.csvcs_compartment_key) : {
      name        : local.provided_csvcs_compartment_name,
      description : "${var.lz_provenant_label} common shared services — APM, File Transfer, Data Exchange, ServiceNow, Jira.",
      defined_tags  : local.cmps_defined_tags,
      freeform_tags : local.cmps_freeform_tags,
      children      : {}
    },

    # -------------------------------------------------------------------------
    # DEVT_CSVCS — Development Common Services Compartment
    # Contains: development toolchain shared services (non-production tier)
    # Owner: UG_DEVT_CSVCS
    # -------------------------------------------------------------------------
    (local.devt_csvcs_compartment_key) : {
      name        : local.provided_devt_csvcs_compartment_name,
      description : "${var.lz_provenant_label} development common services — dev toolchain and shared non-production services.",
      defined_tags  : local.cmps_defined_tags,
      freeform_tags : merge(local.cmps_freeform_tags, { "environment" = "development" }),
      children      : {}
    }
  }
}
