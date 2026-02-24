# =============================================================================
# STAR ELZ V1 — IAM Compartments — TEAM 4 OWNED FILE
# Team 4 domain: Agency Spoke Networks (OS, SS, TS, DEVT)
# Sprint 1, Week 1
# Branch: sprint1/iam-compartments-team4
# =============================================================================
#
# COMPARTMENTS TO DEFINE IN THIS FILE (4 of 10 TF-managed):
#   7.  star-os-elz-nw-cmp   — Operational Systems spoke
#   8.  star-ss-elz-nw-cmp   — Shared Services spoke
#   9.  star-ts-elz-nw-cmp   — Trusted Services spoke
#   10. star-devt-elz-nw-cmp — Development/Test spoke
#
# TEAM 4 ALSO OWNS (OCI Console — NOT Terraform):
#   star-sim-ext-cmp   — create manually, paste OCID into terraform.tfvars
#   star-sim-child-cmp — create manually, paste OCID into terraform.tfvars
#
# INSTRUCTIONS:
#   Define local.team4_compartments following the same pattern as team1.
#   Keys: local.os_nw_compartment_key, local.ss_nw_compartment_key,
#         local.ts_nw_compartment_key, local.devt_nw_compartment_key
#   Names: local.provided_os_nw_compartment_name (same pattern for others)
# =============================================================================

locals {
  team4_compartments = {
    # YOUR CODE HERE
    # Add OS-NW compartment entry
    # Add SS-NW compartment entry
    # Add TS-NW compartment entry
    # Add DEVT-NW compartment entry
  }
}
