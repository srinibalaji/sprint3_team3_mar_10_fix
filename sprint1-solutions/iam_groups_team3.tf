# =============================================================================
# STAR ELZ V1 — IAM Groups — TEAM 3 OWNED FILE
# Team 3 domain: Common Shared Services (CSVCS, DEVT_CSVCS)
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-groups-team3
# =============================================================================
#
# GROUPS IN THIS FILE (2 of 10 TF-managed):
#   5. star-ug-elz-csvcs  — Common Services Administrators
#        Scope: manage all-resources in CSVCS compartment
#               (APM, File Transfer, Data Exchange, ServiceNow, Jira)
#   6. star-ug-devt-csvcs — Development Common Services Administrators
#        Scope: manage all-resources in DEVT_CSVCS compartment
#               (dev toolchain, non-production shared services)
#
# HOW THIS FITS:
#   This file defines local.team3_groups, a map that is merged with
#   team1, team2, and team4 maps in iam_groups.tf before being passed
#   to the lz_groups module. Each team owns their map. Zero conflicts.
#
# POLICY ALIGNMENT (iam_policies_team3.tf):
#   CSVCS-POLICY       — manage all-resources in CSVCS cmp + DEVT_CSVCS cmp
#                        read all-resources in tenancy
#   OCI-SERVICES-POLICY — CIS required OCI service grants (Cloud Guard, Object Storage,
#                          Vulnerability Scanning) — no group attachment, service grants
# =============================================================================

locals {
  team3_groups = {

    # -------------------------------------------------------------------------
    # CSVCS-ADMIN-GROUP — Common Shared Services Administrators
    # Owner: Team 3
    # Compartment: star-r-elz-csvcs-cmp
    # -------------------------------------------------------------------------
    (local.csvcs_admin_group_key) : {
      name          : local.provided_csvcs_admin_group_name,
      description   : "${var.lz_provenant_label} Common Services Administrators — APM, File Transfer, Data Exchange, ServiceNow, Jira.",
      defined_tags  : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    },

    # -------------------------------------------------------------------------
    # DEVT-CSVCS-ADMIN-GROUP — Development Common Services Administrators
    # Owner: Team 3
    # Compartment: star-r-elz-devt-csvcs-cmp
    # -------------------------------------------------------------------------
    (local.devt_csvcs_admin_group_key) : {
      name          : local.provided_devt_csvcs_admin_group_name,
      description   : "${var.lz_provenant_label} Development Common Services Administrators — dev toolchain and non-production shared services.",
      defined_tags  : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    }
  }
}
