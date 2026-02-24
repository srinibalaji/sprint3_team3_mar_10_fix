# =============================================================================
# STAR ELZ V1 — IAM Policies — TEAM 4 OWNED FILE
# Team 4 domain: Agency Spoke Networks (OS, SS, TS, DEVT)
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-policies-team4
# =============================================================================
#
# POLICY OBJECTS IN THIS FILE (1 of 9):
#   9. SPOKE-NW-ADMIN-POLICY — Each spoke group manages all-resources in its own compartment
#
# HOW THIS FITS:
#   This file defines local.team4_policies, a map that is merged with
#   team1, team2, and team3 maps in iam_policies.tf before being passed
#   to the lz_policies module. Each team owns their map. Zero conflicts.
#
# GROUPS USED (output from iam_groups.tf module):
#   local.os_nw_admin_group_name   — star-ug-os-elz-nw
#   local.ss_nw_admin_group_name   — star-ug-ss-elz-nw
#   local.ts_nw_admin_group_name   — star-ug-ts-elz-nw
#   local.devt_nw_admin_group_name — star-ug-devt-elz-nw
#
# COMPARTMENTS REFERENCED (locals from iam_compartments.tf):
#   local.provided_os_nw_compartment_name
#   local.provided_ss_nw_compartment_name
#   local.provided_ts_nw_compartment_name
#   local.provided_devt_nw_compartment_name
#
# CRITICAL — SoD rules enforced by this file:
#   Each spoke group manages all-resources ONLY in its own compartment.
#   No spoke group appears in any policy granting access to SEC, NW hub, or OPS.
#   TC-03: star-ug-devt-elz-nw must NOT be able to write to SEC compartment.
#          The absence of SEC compartment from this policy is how TC-03 passes.
# =============================================================================

locals {
  team4_policies = {

    # -------------------------------------------------------------------------
    # SPOKE-NW-ADMIN-POLICY
    # Each of the 4 spoke groups manages all-resources in its own spoke
    # compartment only. One policy object, 4 statements — one per spoke.
    # Kept in one object (not 4 separate objects) because all 4 statements
    # share the same description and tag scope. Split only if compartment-level
    # policy attachment becomes needed in V2.
    # -------------------------------------------------------------------------
    "SPOKE-NW-ADMIN-POLICY" : {
      name           : "${var.service_label}-spoke-nw-admin-policy"
      description    : "${var.lz_provenant_label} spoke network admin grants."
      compartment_id : var.tenancy_ocid
      statements : concat(
        local.spoke_nw_admin_grants
      )
      defined_tags  : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    }
  }

  # ---------------------------------------------------------------------------
  # Statement list — owned by Team 4, consumed by policy object above
  # ---------------------------------------------------------------------------

  # Spoke network admin grants — one statement per group/compartment pair
  spoke_nw_admin_grants = [
    "allow group ${join(",", local.os_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_os_nw_compartment_name}",
    "allow group ${join(",", local.ss_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_ss_nw_compartment_name}",
    "allow group ${join(",", local.ts_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_ts_nw_compartment_name}",
    "allow group ${join(",", local.devt_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_devt_nw_compartment_name}"
  ]
}
