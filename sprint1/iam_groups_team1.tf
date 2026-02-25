# =============================================================================
# STAR ELZ V1 — IAM Groups — TEAM 1 OWNED FILE
# Team 1 domain: Hub Network + Security
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-groups-team1
# =============================================================================
# YOUR TASK:
#   Define local.team1_groups — a map with 2 entries:
#     1. NW-ADMIN-GROUP  → star-ug-elz-nw
#     2. SEC-ADMIN-GROUP → star-ug-elz-sec
#
# PATTERN:
#
# KEYS  → local.nw_admin_group_key,  local.sec_admin_group_key
# NAMES → local.provided_nw_admin_group_name, local.provided_sec_admin_group_name
# Both defined in iam_groups.tf — do NOT redefine here.
# =============================================================================

locals {
  team1_groups = {

    # -------------------------------------------------------------------------
    # NW-ADMIN-GROUP - Global Network Administrators
    # Compartment: star-r-elz-nw-cmp (primary) + all 4 spoke NW compartments (VCN only)
    # -------------------------------------------------------------------------
    (local.nw_admin_group_key) : {
      name : local.provided_nw_admin_group_name,
      description : "${var.lz_provenant_label} Global Network Administrators - Hub VCN, DRGs, route tables, Sim FW, spoke VCNs.",
      defined_tags : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    },

    # -------------------------------------------------------------------------
    # SEC-ADMIN-GROUP - Security Administrators
    # Compartment: star-r-elz-sec-cmp + root-level cloud-guard and tag grants
    # -------------------------------------------------------------------------
    (local.sec_admin_group_key) : {
      name : local.provided_sec_admin_group_name,
      description : "${var.lz_provenant_label} Security Administrators - Vault, Cloud Guard, Security Zones, Bastion.",
      defined_tags : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    }
  }
}
