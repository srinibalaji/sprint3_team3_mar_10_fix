# =============================================================================
# STAR ELZ V1 — IAM Groups — TEAM 4 OWNED FILE
# Team 4 domain: Agency Spoke Networks (OS, SS, TS, DEVT)
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-groups-team4
# =============================================================================
#
# GROUPS IN THIS FILE (4 of 10 TF-managed):
#   7.  star-ug-os-elz-nw   — Operational Systems Network Administrators
#   8.  star-ug-ss-elz-nw   — Shared Services Network Administrators
#   9.  star-ug-ts-elz-nw   — Trusted Services Network Administrators
#   10. star-ug-devt-elz-nw — Development/Test Network Administrators
#
# HOW THIS FITS:
#   This file defines local.team4_groups, a map that is merged with
#   team1, team2, and team3 maps in iam_groups.tf before being passed
#   to the lz_groups module. Each team owns their map. Zero conflicts.
#
# TEAM 4 ALSO OWNS — OCI Console manual creation (NOT Terraform):
#   star-ug-sim-ext   — TEMP V1 ONLY. Create in Console on Sprint 1 Day 1.
#   star-ug-sim-child — TEMP V1 ONLY. Create in Console on Sprint 1 Day 1.
#   Instructions: see README.md § "Week 1, Day 1 — Manual IAM Groups"
#
# POLICY ALIGNMENT (iam_policies_team4.tf):
#   SPOKE-NW-ADMIN-POLICY — each group manages all-resources in its own spoke compartment
#                            NO grants in SEC, NW hub, OPS, or SOC compartments
#
# CRITICAL — TC-03 SoD test:
#   star-ug-devt-elz-nw must NOT appear in any policy granting write access
#   to the SEC compartment. TC-03 verifies this explicitly.
# =============================================================================

locals {
  team4_groups = {

    # -------------------------------------------------------------------------
    # OS-NW-ADMIN-GROUP — Operational Systems Network Administrators
    # Owner: Team 4
    # Compartment: star-os-elz-nw-cmp
    # -------------------------------------------------------------------------
    (local.os_nw_admin_group_key) : {
      name          : local.provided_os_nw_admin_group_name,
      description   : "${var.lz_provenant_label} Operational Services Network Administrators — OS spoke VCN, subnets, NSGs.",
      defined_tags  : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    },

    # -------------------------------------------------------------------------
    # SS-NW-ADMIN-GROUP — Shared Services Network Administrators
    # Owner: Team 4
    # Compartment: star-ss-elz-nw-cmp
    # -------------------------------------------------------------------------
    (local.ss_nw_admin_group_key) : {
      name          : local.provided_ss_nw_admin_group_name,
      description   : "${var.lz_provenant_label} Shared Services Network Administrators — SS spoke VCN, subnets, NSGs.",
      defined_tags  : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    },

    # -------------------------------------------------------------------------
    # TS-NW-ADMIN-GROUP — Trusted Services Network Administrators
    # Owner: Team 4
    # Compartment: star-ts-elz-nw-cmp
    # -------------------------------------------------------------------------
    (local.ts_nw_admin_group_key) : {
      name          : local.provided_ts_nw_admin_group_name,
      description   : "${var.lz_provenant_label} Tenant Services Network Administrators — TS spoke VCN, subnets, NSGs.",
      defined_tags  : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    },

    # -------------------------------------------------------------------------
    # DEVT-NW-ADMIN-GROUP — Development/Test Network Administrators
    # Owner: Team 4
    # Compartment: star-devt-elz-nw-cmp
    # CRITICAL: TC-03 negative test — this group must have NO grants in SEC cmp
    # -------------------------------------------------------------------------
    (local.devt_nw_admin_group_key) : {
      name          : local.provided_devt_nw_admin_group_name,
      description   : "${var.lz_provenant_label} Development/Test Network Administrators — DEVT spoke VCN, subnets, NSGs. Network-only in V1.",
      defined_tags  : local.groups_defined_tags,
      freeform_tags : local.groups_freeform_tags
    }
  }
}
