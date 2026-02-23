# =============================================================================
# STAR ELZ V1 — IAM Groups — TEAM 2 OWNED FILE
# 12 groups covering all compartment admin + read roles
# Sprint 1, Week 1
# Branch: sprint1/iam-policies (Team 2)
# =============================================================================
#
# GROUPS TO DEFINE (12 total):
#   UG_ELZ_NW, UG_ELZ_SEC, UG_ELZ_SOC, UG_ELZ_OPS,
#   UG_ELZ_CSVCS, UG_DEVT_CSVCS,
#   UG_OS_ELZ_NW, UG_SS_ELZ_NW, UG_TS_ELZ_NW, UG_DEVT_ELZ_NW,
#   UG_ELZ_ADMIN (break-glass), UG_ELZ_AUDITOR (read-all)
#
# INSTRUCTIONS:
#   Use the lz_groups module from terraform-oci-modules-iam.
#   Source: github.com/oci-landing-zones/terraform-oci-modules-iam//groups
#   Each group needs: name, description, defined_tags, freeform_tags
#   Reference: iam_compartments.tf for module call pattern.
# =============================================================================

locals {
  custom_groups_defined_tags  = null
  custom_groups_freeform_tags = null
}

# YOUR CODE HERE — module "lz_groups" call
