# =============================================================================
# STAR ELZ V1 — IAM Compartments — TEAM 1 OWNED FILE
# Team 1 domain: Hub Network + Security (NW, SEC)
# Sprint 1, Week 1
# Branch: sprint1/iam-compartments-team1
# =============================================================================
#
# COMPARTMENTS IN THIS FILE (2 of 10 TF-managed):
#   1. star-r-elz-nw-cmp   — Root hub network: DRGs, Hub VCN, route tables, Sim FW, Bastion
#   2. star-r-elz-sec-cmp  — Security services: Vault, Cloud Guard, Security Zones
#
# HOW THIS FITS:
#   This file defines local.team1_compartments, a map that is merged with
#   team2, team3, and team4 maps in iam_compartments.tf before being passed
#   to the lz_compartments module. Each team owns their map. Zero conflicts.
#
# MANUAL COMPARTMENTS (NOT in any TF file — Sprint 4 prereq):
#   star-sim-ext-cmp   — create manually in OCI Console before Sprint 4 apply
#   star-sim-child-cmp — create manually in OCI Console before Sprint 4 apply
#   Instructions: see sprint4/README.md § Manual Prereqs
# =============================================================================

locals {
  team1_compartments = {

    # -------------------------------------------------------------------------
    # NW — Root Hub Network Compartment
    # Contains: drg_r_hub, drg_r_ew_hub, Hub VCN, all subnets, Sim FW, Bastion
    # Owner: UG_ELZ_NW
    # -------------------------------------------------------------------------
    (local.nw_compartment_key) : {
      name        : local.provided_nw_compartment_name,
      description : "${var.lz_provenant_label} root hub network compartment — DRGs, Hub VCN, route tables, Sim FW, Bastion.",
      defined_tags  : local.cmps_defined_tags,
      freeform_tags : local.cmps_freeform_tags,
      children      : {}
    },

    # -------------------------------------------------------------------------
    # SEC — Security Services Compartment
    # Contains: Vault, Cloud Guard target, Security Zones
    # Note: Bastion is in NW compartment (hub subnet reach), not here
    # Owner: UG_ELZ_SEC
    # -------------------------------------------------------------------------
    (local.sec_compartment_key) : {
      name        : local.provided_sec_compartment_name,
      description : "${var.lz_provenant_label} security compartment — Vault, Cloud Guard, Security Zones.",
      defined_tags  : local.cmps_defined_tags,
      freeform_tags : local.cmps_freeform_tags,
      children      : {}
    }
  }
}
