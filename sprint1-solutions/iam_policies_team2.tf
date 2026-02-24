# =============================================================================
# STAR ELZ V1 — IAM Policies — TEAM 2 OWNED FILE
# Team 2 domain: SOC + Operations (SOC, OPS)
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-policies-team2
# =============================================================================
#
# POLICY OBJECTS IN THIS FILE (2 of 9):
#   5. SOC-POLICY       — SOC read-only grants at tenancy root
#   6. OPS-ADMIN-POLICY — Operations admin grants on OPS compartment
#
# HOW THIS FITS:
#   This file defines local.team2_policies, a map that is merged with
#   team1, team3, and team4 maps in iam_policies.tf before being passed
#   to the lz_policies module. Each team owns their map. Zero conflicts.
#
# GROUPS USED (output from iam_groups.tf module):
#   local.soc_group_name       — star-ug-elz-soc
#   local.ops_admin_group_name — star-ug-elz-ops
#
# COMPARTMENTS REFERENCED (locals from iam_compartments.tf):
#   local.provided_ops_compartment_name — OPS-ADMIN-POLICY
#
# TEST CASES VALIDATED BY THIS FILE:
#   TC-03: DEVT group must NOT appear in any statement in this file (SoD check)
#   TC-04: NEGATIVE — SOC group must use ONLY read verbs, never manage/use/create
#          A member of SOC attempting oci logging log-group delete must get 403.
# =============================================================================

locals {
  team2_policies = {

    # -------------------------------------------------------------------------
    # SOC-POLICY
    # Read-only across tenancy — cloud-guard visibility, audit trail, all resources.
    # CRITICAL: every verb is "read". cloud-shell is "use" but grants no data access.
    # TC-04: member of SOC attempting any write operation must receive 403.
    # -------------------------------------------------------------------------
    "SOC-POLICY" : {
      name           : "${var.service_label}-soc-policy"
      description    : "${var.lz_provenant_label} SOC read-only monitoring grants."
      compartment_id : var.tenancy_ocid
      statements : concat(
        local.soc_grants_on_root
      )
      defined_tags  : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    },

    # -------------------------------------------------------------------------
    # OPS-ADMIN-POLICY
    # OPS compartment: manage logging, monitoring, alarms, object storage (log buckets).
    # Tenancy-root read: dashboards and service metrics require read all-resources.
    # Does NOT grant any access to SEC, NW, or spoke compartments.
    # -------------------------------------------------------------------------
    "OPS-ADMIN-POLICY" : {
      name           : "${var.service_label}-ops-admin-policy"
      description    : "${var.lz_provenant_label} operations admin grants."
      compartment_id : var.tenancy_ocid
      statements : concat(
        local.ops_admin_grants_on_ops_cmp
      )
      defined_tags  : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    }
  }

  # ---------------------------------------------------------------------------
  # Statement lists — owned by Team 2, consumed by policy objects above
  # ---------------------------------------------------------------------------

  # SOC grants — tenancy root, read-only
  soc_grants_on_root = [
    "allow group ${join(",", local.soc_group_name)} to read cloud-guard-family in tenancy",
    "allow group ${join(",", local.soc_group_name)} to read audit-events in tenancy",
    "allow group ${join(",", local.soc_group_name)} to read all-resources in tenancy",
    "allow group ${join(",", local.soc_group_name)} to use cloud-shell in tenancy"
  ]

  # Operations admin grants — OPS compartment + tenancy read
  ops_admin_grants_on_ops_cmp = [
    "allow group ${join(",", local.ops_admin_group_name)} to manage logging-family in compartment ${local.provided_ops_compartment_name}",
    "allow group ${join(",", local.ops_admin_group_name)} to manage ons-family in compartment ${local.provided_ops_compartment_name}",
    "allow group ${join(",", local.ops_admin_group_name)} to manage alarms in compartment ${local.provided_ops_compartment_name}",
    "allow group ${join(",", local.ops_admin_group_name)} to manage metrics in compartment ${local.provided_ops_compartment_name}",
    "allow group ${join(",", local.ops_admin_group_name)} to manage object-family in compartment ${local.provided_ops_compartment_name}",
    "allow group ${join(",", local.ops_admin_group_name)} to read all-resources in tenancy"
  ]
}
