# =============================================================================
# STAR ELZ V1 — IAM Compartments — TEAM 3 OWNED FILE
# Team 3 domain: Shared Services (CSVCS, DEVT_CSVCS)
# Sprint 1, Week 1
# Branch: sprint1/iam-compartments-team3
# =============================================================================
#
# COMPARTMENTS TO DEFINE IN THIS FILE (2 of 10 TF-managed):
#   5. star-r-elz-csvcs-cmp      — Common Shared Services: APM, File Transfer, ServiceNow
#   6. star-r-elz-devt-csvcs-cmp — Dev Common Services: development toolchain
#
# INSTRUCTIONS:
#   Define local.team3_compartments following the same pattern as team1.
#   Keys: local.csvcs_compartment_key, local.devt_csvcs_compartment_key
#   Names: local.provided_csvcs_compartment_name, local.provided_devt_csvcs_compartment_name
#   Note: DEVT_CSVCS freeform_tags should merge cmps_freeform_tags with environment=development
# =============================================================================

locals {
  team3_compartments = {
    # YOUR CODE HERE
    # Add CSVCS compartment entry
    # Add DEVT_CSVCS compartment entry (remember the extra freeform tag)
  }
}
