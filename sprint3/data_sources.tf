# ─────────────────────────────────────────────────────────────
# STAR ELZ V1 — Sprint 3 — Data Sources
# Shared lookups used by multiple team files.
# ─────────────────────────────────────────────────────────────

# Object Storage namespace — required for bucket creation
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.tenancy_ocid
}

# Service Gateway — list available Oracle services in the region
# Used by T4 sec_team4.tf for Service Gateway service_id
# Filter to "All <region> Services In Oracle Services Network"
# This is the broadest SG service CIDR — covers Object Storage, OCI APIs, etc.
data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}
