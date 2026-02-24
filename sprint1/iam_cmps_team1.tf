# =============================================================================
# STAR ELZ V1 — IAM Compartments — TEAM 1 OWNED FILE
# Team 1 domain: Hub Network + Security (NW, SEC)
# Sprint 1, Week 1
# Branch: sprint1/iam-compartments-team1
# =============================================================================
#
# COMPARTMENTS TO DEFINE IN THIS FILE (2 of 10 TF-managed):
#   1. star-r-elz-nw-cmp   — Root hub network: DRGs, Hub VCN, route tables, Sim FW, Bastion
#   2. star-r-elz-sec-cmp  — Security services: Vault, Cloud Guard, Security Zones
#
# INSTRUCTIONS:
#   Define local.team1_compartments as a map using the same pattern as the
#   other team files. Each entry uses:
#     - key:   local.<name>_compartment_key  (defined in locals.tf)
#     - name:  local.provided_<name>_compartment_name
#     - description, defined_tags, freeform_tags, children
#
#   Reference: iam_compartments.tf shows how team maps are merged.
#   Reference: locals.tf shows available local keys and tag locals.
#
# DO NOT edit iam_compartments.tf — it is read-only and merges all team maps.
# =============================================================================

locals {
  team1_compartments = {
    # YOUR CODE HERE
    # Add NW compartment entry
    # Add SEC compartment entry
  }
}
