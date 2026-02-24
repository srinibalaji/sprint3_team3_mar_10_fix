# =============================================================================
# STAR ELZ V1 — IAM Policies — TEAM 2 OWNED FILE
# 38 policy statements scoped to compartments
# Sprint 1, Week 1
# Branch: sprint1/iam-policies (Team 2)
# =============================================================================
#
# POLICIES TO DEFINE (38 statements across these policy groups):
#   - NW admin: manage virtual-network-family, manage drg in nw compartment
#   - SEC admin: manage vaults, manage cloud-guard in sec compartment
#   - SOC: read all-resources in tenancy (read-only)
#   - OPS admin: manage logging-family, manage ons-family in ops compartment
#   - CSVCS/DEVT admin: manage all-resources in their compartments
#   - Spoke NW admins: manage virtual-network-family in their spoke compartment
#   - ADMIN (break-glass): manage all-resources in tenancy
#   - AUDITOR: inspect all-resources in tenancy
#
# INSTRUCTIONS:
#   Use the lz_policies module from terraform-oci-modules-iam.
#   Source: github.com/oci-landing-zones/terraform-oci-modules-iam//policies
#   depends_on: [module.lz_compartments, module.lz_groups]
#   Reference: TC-03 and TC-04 in README describe the NEGATIVE tests your
#   policies must pass — write deny rules accordingly.
# =============================================================================

locals {
  custom_policies_defined_tags  = null
  custom_policies_freeform_tags = null
}

# YOUR CODE HERE — module "lz_policies" call
