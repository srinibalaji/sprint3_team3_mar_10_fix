# =============================================================================
# STAR ELZ V1 — IAM Groups — TEAM 1 OWNED FILE
# Team 1 domain: Hub Network + Security (NW, SEC)
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-groups-team1
# =============================================================================
#
# GROUPS IN THIS FILE (2 of 10 TF-managed):
#   1. star-ug-elz-nw  — Global Network Administrators
#        Scope: Hub VCN, both DRGs, route tables, subnets, Sim FW (NW compartment)
#               + virtual-network-family across all 4 spoke compartments
#   2. star-ug-elz-sec — Security Administrators
#        Scope: Vault, Cloud Guard, Security Zones, Bastion (SEC compartment)
#               + cloud-guard-family, tag-namespaces at tenancy root
#
# HOW THIS FITS:
#   This file defines local.team1_groups, a map that is merged with
#   team2, team3, and team4 maps in iam_groups.tf before being passed
#   to the lz_groups module. Each team owns their map. Zero conflicts.
#
# POLICY ALIGNMENT (iam_policies_team1.tf):
#   NW-ADMIN-ROOT-POLICY  — read all-resources + cloud-shell in tenancy
#   NW-ADMIN-POLICY       — manage virtual-network-family + drgs in NW cmp
#                           manage virtual-network-family in all 4 spoke cmps
#   SEC-ADMIN-ROOT-POLICY — manage cloud-guard-family, tag-namespaces in tenancy
#   SEC-ADMIN-POLICY      — manage vaults, keys, bastion-family, security-zone in SEC cmp
# =============================================================================

locals {
  team1_groups = {

    # -------------------------------------------------------------------------
    # NW-ADMIN-GROUP — Global Network Administrators
    # Owner: Team 1
    # Compartment: star-r-elz-nw-cmp (primary) + all 4 spoke NW compartments (VCN only)
    # -------------------------------------------------------------------------
    (local.nw_admin_group_key) : {
      name          : local.provided_nw_admin_group_name,
      description   : "${var.lz_provenant_label} Global Network Administrators — Hub VCN, DRGs, route tables, Sim FW, spoke VCNs.",
      defined_tags  : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    },

    # -------------------------------------------------------------------------
    # SEC-ADMIN-GROUP — Security Administrators
    # Owner: Team 1
    # Compartment: star-r-elz-sec-cmp + root-level cloud-guard and tag grants
    # -------------------------------------------------------------------------
    (local.sec_admin_group_key) : {
      name          : local.provided_sec_admin_group_name,
      description   : "${var.lz_provenant_label} Security Administrators — Vault, Cloud Guard, Security Zones, Bastion.",
      defined_tags  : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    }
  }
}
