# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

locals {
  #------------------------------------------------------------------------------------------------------
  #-- Any of these local vars can be overridden in a _override.tf file
  #------------------------------------------------------------------------------------------------------
  tag_namespace_name           = ""
  tag_namespace_compartment_id = var.tenancy_ocid
  tag_defaults_compartment_id  = var.tenancy_ocid

  all_tags_defined_tags  = {}
  all_tags_freeform_tags = {}
}

locals {
  #------------------------------------------------------------------------------------------------------
  #-- These variables are not meant to be overridden
  #------------------------------------------------------------------------------------------------------

  default_tags_defined_tags  = null
  default_tags_freeform_tags = local.landing_zone_tags

  tags_defined_tags  = length(local.all_tags_defined_tags)  > 0 ? local.all_tags_defined_tags  : local.default_tags_defined_tags
  tags_freeform_tags = length(local.all_tags_freeform_tags) > 0 ? merge(local.all_tags_freeform_tags, local.default_tags_freeform_tags) : local.default_tags_freeform_tags

  default_tag_namespace_name = "${var.service_label}-namesp"

  #------------------------------------------------------------------------
  #----- Tags configuration definition. Input to module.
  #------------------------------------------------------------------------
  tags_configuration = {
    default_compartment_id = local.tag_namespace_compartment_id
    cis_namespace_name     = length(local.tag_namespace_name) > 0 ? local.tag_namespace_name : local.default_tag_namespace_name
    default_defined_tags   = local.tags_defined_tags
    default_freeform_tags  = local.tags_freeform_tags

    namespaces = {
      "ELZ-V1-NAMESPACE" = {
        name        = "${var.service_label}-elz-v1"
        description = "ELZ Landing Zone V1 tag namespace"
        is_retired  = false
        tags = {
          "COSTCENTER-TAG" = {
            name        = "CostCenter"
            description = "Cost centre code for billing and chargeback reporting"
            is_cost_tracking = true
          },
          "ENVIRONMENT-TAG" = {
            name        = "environment"
            description = "Deployment environment e.g. v1-poc, v2, prod"
          },
          "OWNER-TAG" = {
            name        = "owner"
            description = "Resource owner team"
          },
          "MANAGED-BY-TAG" = {
            name        = "managed-by"
            description = "IaC tool managing this resource"
          },
          "VERSION-TAG" = {
            name        = "version"
            description = "Landing Zone version"
          }
        }
      }
    }
  }
}

module "lz_tags" {
  source             = "github.com/oci-landing-zones/terraform-oci-modules-governance//tags?ref=v0.1.5"
  providers          = { oci = oci.home }
  tags_configuration = local.tags_configuration
  tenancy_ocid       = var.tenancy_ocid
}
