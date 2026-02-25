# =============================================================================
# STAR ELZ V1 — Sprint 2: Hub Networking
# Data Sources
# =============================================================================

# Tenancy metadata — used for region key resolution
data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_ocid
}

# All OCI regions — used to resolve home region key
data "oci_identity_regions" "these" {}

# Region subscriptions — used for service gateway label lookup
data "oci_identity_region_subscriptions" "these" {
  tenancy_id = var.tenancy_ocid
}

# Object Storage namespace — used in Service Gateway policy
data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

# All services in Oracle Services Network — used for Service Gateway
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}
