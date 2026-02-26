# =============================================================================
# STAR ELZ V1 — Tag Namespace + Tags — TEAM 3 OWNED FILE
# ELZ tag namespace with 5 tags, CostCenter cost-tracking enabled
# Sprint 1, Week 1
# Branch: sprint1/tagging (Team 3)
# =============================================================================
#
# TAGS TO DEFINE (5 tags in ELZ namespace):
#   1. CostCenter    — is-cost-tracking: true
#   2. Environment   — values: POC, DEV, TEST, PROD
#   3. Owner         — free text
#   4. ManagedBy     — values: Terraform, Manual
#   5. DataClassification — values: OFFICIAL, SENSITIVE, RESTRICTED
#
# INSTRUCTIONS:
#   Use the lz_tags module from terraform-oci-modules-iam.
#   Source: github.com/oci-landing-zones/terraform-oci-modules-iam//tags
#   Tag namespace compartment: var.tenancy_ocid (root)
#   Reference: TC-05 describes the validation — CostCenter must show
#   is-cost-tracking = true in the OCI Console tag namespace.
# =============================================================================

locals {
  tag_namespace_name           = ""
  tag_namespace_compartment_id = var.tenancy_ocid
  tag_defaults_compartment_id  = var.tenancy_ocid
  all_tags_defined_tags        = {}
  all_tags_freeform_tags       = {}
}

# YOUR CODE HERE — module "lz_tags" call
