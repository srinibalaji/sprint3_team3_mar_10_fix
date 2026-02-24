# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# OCI ELZ Landing Zone V1 - aligned to terraform-oci-core-landingzone

locals {
  # Region maps from data sources (same pattern as core LZ)
  regions_map         = { for r in data.oci_identity_regions.these.regions : r.key => r.name }
  regions_map_reverse = { for r in data.oci_identity_regions.these.regions : r.name => r.key }
  home_region_key     = data.oci_identity_tenancy.this.home_region_key
  region_key          = lower(local.regions_map_reverse[var.region])

  # Network helpers
  anywhere                    = "0.0.0.0/0"
  valid_service_gateway_cidrs = ["all-${local.region_key}-services-in-oracle-services-network", "oci-${local.region_key}-objectstorage"]

  # Compartment delete protection (same as core LZ)
  enable_cmp_delete = false

  # Landing zone freeform tag applied to all resources - same pattern as core LZ
  landing_zone_tags = { "oci-elz-landing-zone" : "${var.service_label}/v1" }
}
