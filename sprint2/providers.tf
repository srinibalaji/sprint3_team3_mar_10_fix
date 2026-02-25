# =============================================================================
# STAR ELZ V1 — Sprint 2: Hub Networking
# Provider Configuration
#
# Same provider block as Sprint 1. Both providers are required:
#   - default oci  : used by networking resources (VCN, subnets, DRG, routes)
#   - oci.home     : used by any IAM/identity resources created in this sprint
#
# Do NOT change region — all Sprint 2 resources deploy to ap-singapore-2.
# =============================================================================

provider "oci" {
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
  ignore_defined_tags = ["Oracle-Tags.CreatedBy", "Oracle-Tags.CreatedOn"]
}

provider "oci" {
  alias               = "home"
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
  ignore_defined_tags = ["Oracle-Tags.CreatedBy", "Oracle-Tags.CreatedOn"]
}

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    oci = {
      source                = "oracle/oci"
      configuration_aliases = [oci.home]
    }
  }
}
