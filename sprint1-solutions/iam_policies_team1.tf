# =============================================================================
# STAR ELZ V1 — IAM Policies — TEAM 1 OWNED FILE
# Team 1 domain: Hub Network + Security (NW, SEC)
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-policies-team1
# =============================================================================
#
# POLICY OBJECTS IN THIS FILE (4 of 9):
#   1. NW-ADMIN-ROOT-POLICY  — Network admin tenancy-root grants
#   2. NW-ADMIN-POLICY       — Network admin hub NW + all 4 spoke compartment grants
#   3. SEC-ADMIN-ROOT-POLICY — Security admin tenancy-root grants
#   4. SEC-ADMIN-POLICY      — Security admin SEC compartment grants
#
# HOW THIS FITS:
#   This file defines local.team1_policies, a map that is merged with
#   team2, team3, and team4 maps in iam_policies.tf before being passed
#   to the lz_policies module. Each team owns their map. Zero conflicts.
#
# GROUPS USED (output from iam_groups.tf module):
#   local.nw_admin_group_name  — star-ug-elz-nw
#   local.sec_admin_group_name — star-ug-elz-sec
#
# COMPARTMENTS REFERENCED (locals from iam_compartments.tf):
#   local.provided_nw_compartment_name      — NW-ADMIN-POLICY hub grants
#   local.provided_sec_compartment_name     — SEC-ADMIN-POLICY
#   local.provided_os_nw_compartment_name   \
#   local.provided_ss_nw_compartment_name    > NW-ADMIN-POLICY spoke grants
#   local.provided_ts_nw_compartment_name   /
#   local.provided_devt_nw_compartment_name /
# =============================================================================

locals {
  team1_policies = {

    # -------------------------------------------------------------------------
    # NW-ADMIN-ROOT-POLICY
    # Tenancy-root: read all-resources lets NW admin see the full topology
    # before making any routing or DRG changes. cloud-shell for CLI access.
    # -------------------------------------------------------------------------
    "NW-ADMIN-ROOT-POLICY" : {
      name           : "${var.service_label}-nw-admin-root-policy"
      description    : "${var.lz_provenant_label} network admin root-level grants."
      compartment_id : var.tenancy_ocid
      statements : concat(
        local.nw_admin_grants_on_root
      )
      defined_tags  : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    },

    # -------------------------------------------------------------------------
    # NW-ADMIN-POLICY
    # Hub: manage virtual-network-family + DRGs (DRGs exist only in hub in V1).
    # Spoke: manage virtual-network-family in each spoke compartment —
    #   network topology only, NOT compute or security resources.
    # -------------------------------------------------------------------------
    "NW-ADMIN-POLICY" : {
      name           : "${var.service_label}-nw-admin-policy"
      description    : "${var.lz_provenant_label} network admin grants on hub and spoke compartments."
      compartment_id : var.tenancy_ocid
      statements : concat(
        local.nw_admin_grants_on_nw_cmp,
        local.nw_admin_grants_on_spoke_cmps
      )
      defined_tags  : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    },

    # -------------------------------------------------------------------------
    # SEC-ADMIN-ROOT-POLICY
    # Tenancy-root: manage cloud-guard-family and tag-namespaces are global OCI
    # services that require root-level grants regardless of compartment scope.
    # CIS Level 1 requires an auditor-level read of audit-events in tenancy.
    # -------------------------------------------------------------------------
    "SEC-ADMIN-ROOT-POLICY" : {
      name           : "${var.service_label}-sec-admin-root-policy"
      description    : "${var.lz_provenant_label} security admin root-level grants."
      compartment_id : var.tenancy_ocid
      statements : concat(
        local.sec_admin_grants_on_root
      )
      defined_tags  : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    },

    # -------------------------------------------------------------------------
    # SEC-ADMIN-POLICY
    # SEC compartment only: Vault, keys, Bastion, Security Zones, all-resources.
    # Scoped to SEC compartment — SEC admin has NO write access in NW, OPS, or spokes.
    # -------------------------------------------------------------------------
    "SEC-ADMIN-POLICY" : {
      name           : "${var.service_label}-sec-admin-policy"
      description    : "${var.lz_provenant_label} security admin grants on security compartment."
      compartment_id : var.tenancy_ocid
      statements : concat(
        local.sec_admin_grants_on_sec_cmp
      )
      defined_tags  : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    }
  }

  # ---------------------------------------------------------------------------
  # Statement lists — owned by Team 1, consumed by policy objects above
  # ---------------------------------------------------------------------------

  # Network admin grants — root level
  nw_admin_grants_on_root = [
    "allow group ${join(",", local.nw_admin_group_name)} to read all-resources in tenancy",
    "allow group ${join(",", local.nw_admin_group_name)} to use cloud-shell in tenancy"
  ]

  # Network admin grants — hub NW compartment
  nw_admin_grants_on_nw_cmp = [
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment ${local.provided_nw_compartment_name}",
    "allow group ${join(",", local.nw_admin_group_name)} to manage drgs in compartment ${local.provided_nw_compartment_name}"
  ]

  # Network admin grants — all 4 spoke compartments (VCN topology only)
  nw_admin_grants_on_spoke_cmps = [
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment ${local.provided_os_nw_compartment_name}",
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment ${local.provided_ss_nw_compartment_name}",
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment ${local.provided_ts_nw_compartment_name}",
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment ${local.provided_devt_nw_compartment_name}"
  ]

  # Security admin grants — root level
  sec_admin_grants_on_root = [
    "allow group ${join(",", local.sec_admin_group_name)} to manage cloud-guard-family in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to manage cloudevents-rules in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to read tenancies in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to read objectstorage-namespaces in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to use cloud-shell in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to manage tag-namespaces in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to manage tag-defaults in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to read audit-events in tenancy"
  ]

  # Security admin grants — SEC compartment
  sec_admin_grants_on_sec_cmp = [
    "allow group ${join(",", local.sec_admin_group_name)} to manage vaults in compartment ${local.provided_sec_compartment_name}",
    "allow group ${join(",", local.sec_admin_group_name)} to manage keys in compartment ${local.provided_sec_compartment_name}",
    "allow group ${join(",", local.sec_admin_group_name)} to manage bastion-family in compartment ${local.provided_sec_compartment_name}",
    "allow group ${join(",", local.sec_admin_group_name)} to manage security-zone in compartment ${local.provided_sec_compartment_name}",
    "allow group ${join(",", local.sec_admin_group_name)} to manage all-resources in compartment ${local.provided_sec_compartment_name}"
  ]
}
