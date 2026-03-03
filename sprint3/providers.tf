# ─────────────────────────────────────────────────────────────
# STAR ELZ V1 — Sprint 3 — Providers
# Mirrors Sprint 2 provider configuration exactly.
# ORM injects authentication automatically — no API keys in code.
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = ">= 6.0.0"
      configuration_aliases = [oci.home]
    }
  }
}

# Default provider — workload region (ap-singapore-2)
provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  region       = var.region
}

# Home region provider — IAM resources only (not used in Sprint 3)
provider "oci" {
  alias        = "home"
  tenancy_ocid = var.tenancy_ocid
  region       = var.home_region
}
