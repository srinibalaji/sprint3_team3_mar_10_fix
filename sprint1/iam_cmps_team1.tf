# =============================================================================
# STAR ELZ V1 — IAM Compartments — TEAM 1 OWNED FILE
# Team 1 domain: Hub Network + Security (NW, SEC)
# Sprint 1, Week 1 — Day 1
# Branch: sprint1/iam-compartments-team1
# =============================================================================
# YOUR TASK:
#   Define local.team1_compartments — a map with 2 entries:
#     1. NW  — root hub network compartment
#     2. SEC — security services compartment
#
# PATTERN (copy from iam_cmps_team2.tf if you need a reference):
#   locals {
#     team1_compartments = {
#       (local.<key>) : {
#         name          : local.provided_<name>,
#         description   : "...",
#         defined_tags  : local.cmps_defined_tags,
#         freeform_tags : local.cmps_freeform_tags,
#         children      : {}
#       }
#     }
#   }
#
# KEYS  → local.nw_compartment_key,  local.sec_compartment_key
# NAMES → local.provided_nw_compartment_name, local.provided_sec_compartment_name
# Both are defined in iam_compartments.tf — do NOT redefine them here.
# =============================================================================

# TODO: write local.team1_compartments below this line
locals {
  team1_compartments = {
    # -------------------------------------------------------------------------
    # NW — Root Hub Network Compartment
    # Contains: drg_r_hub, drg_r_ew_hub, Hub VCN, all subnets, Sim FW, Bastion
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