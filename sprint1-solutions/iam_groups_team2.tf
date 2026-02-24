# =============================================================================
# STAR ELZ V1 — IAM Groups — TEAM 2 OWNED FILE
# Team 2 domain: SOC + Operations (SOC, OPS)
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-groups-team2
# =============================================================================
#
# GROUPS IN THIS FILE (2 of 10 TF-managed):
#   3. star-ug-elz-soc — SOC Analysts (read-only across tenancy)
#        Scope: read cloud-guard-family, read audit-events, read all-resources
#        CRITICAL: must use ONLY read/inspect verbs in all policies (TC-04)
#   4. star-ug-elz-ops — Operations Administrators
#        Scope: manage logging-family, ons-family, alarms, metrics, object-family
#               in OPS compartment + read all-resources in tenancy
#
# HOW THIS FITS:
#   This file defines local.team2_groups, a map that is merged with
#   team1, team3, and team4 maps in iam_groups.tf before being passed
#   to the lz_groups module. Each team owns their map. Zero conflicts.
#
# POLICY ALIGNMENT (iam_policies_team2.tf):
#   SOC-POLICY       — read cloud-guard-family, read audit-events, read all-resources
#                      NEVER manage/use — TC-04 verifies this
#   OPS-ADMIN-POLICY — manage logging/ons/alarms/metrics/object-family in OPS cmp
# =============================================================================

locals {
  team2_groups = {

    # -------------------------------------------------------------------------
    # SOC-GROUP — Security Operations Centre Analysts
    # Owner: Team 2
    # Compartment: tenancy root (read-only monitoring across all compartments)
    # CRITICAL: TC-04 negative test — member of this group must NOT be able to
    #           delete any resource. Policy for this group uses read verbs only.
    # -------------------------------------------------------------------------
    (local.soc_group_key) : {
      name          : local.provided_soc_group_name,
      description   : "${var.lz_provenant_label} SOC Analysts — read-only security monitoring, log review, incident response.",
      defined_tags  : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    },

    # -------------------------------------------------------------------------
    # OPS-ADMIN-GROUP — Operations Administrators
    # Owner: Team 2
    # Compartment: star-r-elz-ops-cmp (write) + tenancy root (read)
    # -------------------------------------------------------------------------
    (local.ops_admin_group_key) : {
      name          : local.provided_ops_admin_group_name,
      description   : "${var.lz_provenant_label} Operations Administrators — logging, monitoring, alarms, deployment pipeline.",
      defined_tags  : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    }
  }
}
