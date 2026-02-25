# =============================================================================
# STAR ELZ V1 — IAM Policies — TEAM 1 OWNED FILE
# Team 1 domain: Hub Network + Security
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-policies-team1
# =============================================================================
# YOUR TASK:
#   Define local.team1_policies — a map with 4 policy objects:
#     1. "NW-ADMIN-ROOT-POLICY"  — read all-resources + cloud-shell in tenancy
#     2. "NW-ADMIN-POLICY"       — manage VCN-family + DRGs in NW cmp
#                                  manage VCN-family in all 4 spoke cmps
#     3. "SEC-ADMIN-ROOT-POLICY" — manage cloud-guard-family, tag-namespaces in tenancy
#     4. "SEC-ADMIN-POLICY"      — manage vaults, keys, bastion-family, security-zone in SEC cmp
#
# Also define the statement lists these policies consume:
#   local.nw_admin_grants_on_root, local.nw_admin_grants_on_nw_cmp,
#   local.nw_admin_grants_on_spoke_cmps, local.sec_admin_grants_on_root,
#   local.sec_admin_grants_on_sec_cmp
#
# GROUP LOCALS  → local.nw_admin_group_name, local.sec_admin_group_name
# COMPARTMENT LOCALS → local.provided_nw_compartment_name, local.provided_sec_compartment_name,
#                      local.provided_os/ss/ts/devt_nw_compartment_name
# TAG LOCALS    → local.policies_defined_tags, local.policies_freeform_tags
# TENANCY       → var.tenancy_ocid  (use as compartment_id for all root-level policies)
# =============================================================================

# TODO: write local.team1_policies and statement lists below this line

locals {
  team1_policies = {

    # -------------------------------------------------------------------------
    # NW-ADMIN-ROOT-POLICY
    # Tenancy-root: read all-resources lets NW admin see the full topology
    # before making any routing or DRG changes. cloud-shell for CLI access.
    # -------------------------------------------------------------------------
    "NW-ADMIN-ROOT-POLICY" : {
      name           : "UG_ELZ_NW-Policy"
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

    # -------------------------------------------------------------------------
    # SEC-ADMIN-ROOT-POLICY
    # Tenancy-root: manage cloud-guard-family and tag-namespaces are global OCI
    # services that require root-level grants regardless of compartment scope.
    # CIS Level 1 requires an auditor-level read of audit-events in tenancy.
    # -------------------------------------------------------------------------
    "SEC-ADMIN-ROOT-POLICY" : {
      name           : "UG_ELZ_SEC-Policy"
      description    : "${var.lz_provenant_label} security admin root-level grants."
      compartment_id : var.tenancy_ocid
      statements : concat(
        local.sec_admin_grants_on_root
      )
      defined_tags  : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    }

    # -------------------------------------------------------------------------
    # SEC-ADMIN-POLICY
    # SEC compartment only: Vault, keys, Bastion, Security Zones, all-resources.
    # Scoped to SEC compartment — SEC admin has NO write access in NW, OPS, or spokes.

  }

  # ---------------------------------------------------------------------------
  # Statement lists — owned by Team 1, consumed by policy objects above
  # ---------------------------------------------------------------------------

  # Network admin grants — root level
  nw_admin_grants_on_root = [
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment *",
    "allow group ${join(",", local.nw_admin_group_name)} to manage drgs in compartment *",
    "allow group ${join(",", local.nw_admin_group_name)} to use cloud-shell in tenancy",
    "allow group ${join(",", local.nw_admin_group_name)} to read virtual-network-family in compartment *",
    "allow group ${join(",", local.nw_admin_group_name)} to use cloud-shell in tenancy"

  ]

  # Security admin grants — root level
  sec_admin_grants_on_root = [
    "allow group ${join(",", local.sec_admin_group_name)} to manage all-resources in compartment *",
    "allow group ${join(",", local.sec_admin_group_name)} to manage cloud-guard-family in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to manage vaults in compartment *",
    "allow group ${join(",", local.sec_admin_group_name)} to manage keys in compartment *",
    "allow group ${join(",", local.sec_admin_group_name)} to read all-resources in tenancy",
  ]

}
