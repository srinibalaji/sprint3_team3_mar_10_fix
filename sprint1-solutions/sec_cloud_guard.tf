# =============================================================================
# STAR ELZ V1 — Cloud Guard Configuration
# Sprint 1 — Security Baseline
# Team: Team 1 (SEC compartment) owns this file
# Branch: sprint1/iam-compartments-team1
# =============================================================================
#
# PREREQUISITE — complete this BEFORE terraform plan:
#   OCI Console → Security → Cloud Guard → Enable
#   Reporting region: ap-singapore-1
#   Takes approximately 2 minutes to activate.
#
# WHAT THIS FILE DOES:
#   - Creates a Cloud Guard target covering the entire tenancy (root compartment)
#   - Attaches Oracle-managed Configuration + Activity detector recipes
#   - Attaches Oracle-managed Responder recipe
#   - Outputs Cloud Guard target OCID for State Book recording
#
# WHAT THIS FILE DOES NOT DO:
#   - Does not enable Cloud Guard (one-time Console action, see prerequisite above)
#   - Does not create Security Zones (Sprint 3)
#   - Does not clone recipes (set enable_cloud_guard_cloned_recipes=true to clone)
# =============================================================================

variable "enable_cloud_guard_cloned_recipes" {
  description = "Set true to clone Oracle-managed recipes into self-managed copies. Recommended before production."
  type        = bool
  default     = false
}

variable "cloud_guard_reporting_region" {
  description = "Cloud Guard reporting region. Leave null to auto-use the tenancy home region."
  type        = string
  default     = null
}

locals {
  cloud_guard_reporting_region = coalesce(
    var.cloud_guard_reporting_region,
    local.regions_map[local.home_region_key]
  )
  cloud_guard_target_name = "${var.service_label}-elz-cg-target"
}

# =============================================================================
# Cloud Guard Target — covers entire tenancy root compartment
# =============================================================================
resource "oci_cloud_guard_target" "elz_root_target" {
  compartment_id       = var.tenancy_ocid
  display_name         = local.cloud_guard_target_name
  target_resource_id   = var.tenancy_ocid
  target_resource_type = "COMPARTMENT"
  description          = "${var.lz_provenant_label} Cloud Guard target — monitors entire tenancy."

  target_detector_recipes {
    detector_recipe_id = data.oci_cloud_guard_detector_recipes.configuration_recipe.detector_recipe_collection[0].items[0].id
  }

  target_detector_recipes {
    detector_recipe_id = data.oci_cloud_guard_detector_recipes.activity_recipe.detector_recipe_collection[0].items[0].id
  }

  target_responder_recipes {
    responder_recipe_id = data.oci_cloud_guard_responder_recipes.responder_recipe.responder_recipe_collection[0].items[0].id
  }

  freeform_tags = local.landing_zone_tags

  lifecycle {
    ignore_changes = [target_detector_recipes, target_responder_recipes]
  }
}

# =============================================================================
# Oracle-managed recipe lookups — no hardcoded OCIDs
# =============================================================================
data "oci_cloud_guard_detector_recipes" "configuration_recipe" {
  compartment_id         = var.tenancy_ocid
  display_name           = "OCI Configuration Detector Recipe"
  resource_metadata_only = true
  state                  = "ACTIVE"
}

data "oci_cloud_guard_detector_recipes" "activity_recipe" {
  compartment_id         = var.tenancy_ocid
  display_name           = "OCI Activity Detector Recipe"
  resource_metadata_only = true
  state                  = "ACTIVE"
}

data "oci_cloud_guard_responder_recipes" "responder_recipe" {
  compartment_id         = var.tenancy_ocid
  display_name           = "OCI Responder Recipe"
  resource_metadata_only = true
  state                  = "ACTIVE"
}

# =============================================================================
# Outputs — record in State Book after apply
# =============================================================================
output "cloud_guard_target_id" {
  description = "OCID of Cloud Guard target. Record in State Book V1_Validation."
  value       = oci_cloud_guard_target.elz_root_target.id
}

output "cloud_guard_reporting_region" {
  description = "Cloud Guard reporting region in use."
  value       = local.cloud_guard_reporting_region
}
