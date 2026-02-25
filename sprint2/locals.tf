# =============================================================================
# STAR ELZ V1 — Sprint 2: Hub Networking
# Locals — computed values shared across all Sprint 2 networking files
# =============================================================================

locals {
  # Region key — used in Service Gateway CIDR labels
  # e.g. "ap-singapore-2" → "sin2"
  region_key = lower(replace(var.region, "-", ""))

  # Service Gateway all-services CIDR label
  all_services_cidr = "all-${local.region_key}-services-in-oracle-services-network"

  # Landing zone freeform tag applied to all Sprint 2 resources
  landing_zone_tags = {
    "oci-elz-landing-zone" = "${var.service_label}/v1"
  }
}
