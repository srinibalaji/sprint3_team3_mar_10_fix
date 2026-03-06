# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# STAR ELZ V1 — sprint2

# ---------------------------------------------------------------------------
# All regions — used for regions_map / regions_map_reverse in locals.tf
# (correct region_key resolution, fixed from old lower(replace()) pattern)
# ---------------------------------------------------------------------------
data "oci_identity_regions" "these" {}

data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_ocid
}

# ---------------------------------------------------------------------------
# Object storage namespace — bucket naming Sprint 3+
# ---------------------------------------------------------------------------
data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

# ---------------------------------------------------------------------------
# Availability Domains — Sprint 2 compute and subnet placement
# local.ad_name = first AD in the region
# ---------------------------------------------------------------------------
data "oci_identity_availability_domains" "these" {
  compartment_id = var.tenancy_ocid
}

# ---------------------------------------------------------------------------
# Platform images — Sim Firewall compute (Oracle Linux 8, E4.Flex)
# Query-based: always resolves to latest patched OL8 image at plan time.
# No hardcoded OCID — image OCIDs are region-specific and rotate on patches.
# sorted TIMECREATED DESC → images[0] = latest
# ---------------------------------------------------------------------------
data "oci_core_images" "platform_oel8" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# NOTE: oci_cloud_guard_cloud_guard_configuration data source intentionally
# omitted. It fails plan on fresh tenancies where Cloud Guard is not yet
# enabled. Cloud Guard was manually enabled by Oracle for Sprint 1.
# Sprint 2 networking does not depend on Cloud Guard state.

# ---------------------------------------------------------------------------
# OCI Services Network — required for Service Gateway (Bastion Managed SSH)
# Cloud Agent on Sim FW instances needs a route to OCI services for the
# Bastion plugin to initialise. Without this, plugin state → INVALID.
# Also required for dnf/yum access (cloud-init iptables-services install).
# ---------------------------------------------------------------------------
data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}
