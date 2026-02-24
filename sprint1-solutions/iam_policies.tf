# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# OCI ELZ Landing Zone V1 - aligned to terraform-oci-core-landingzone

locals {
  #------------------------------------------------------------------------------------------------------
  #-- Any of these local variables can be overridden in a _override.tf file
  #------------------------------------------------------------------------------------------------------
  custom_policies_defined_tags  = null
  custom_policies_freeform_tags = null
}

#------------------------------------------------------------------------
#----- Module call - same pattern as core LZ iam_policies.tf
#------------------------------------------------------------------------
module "lz_policies" {
  depends_on             = [module.lz_compartments, module.lz_groups]
  source                 = "github.com/oci-landing-zones/terraform-oci-modules-iam//policies?ref=v0.3.1"
  providers              = { oci = oci.home }
  tenancy_ocid           = var.tenancy_ocid
  policies_configuration = local.policies_configuration
}

locals {
  #------------------------------------------------------------------------------------------------------
  #-- These variables are NOT meant to be overridden
  #------------------------------------------------------------------------------------------------------

  default_policies_defined_tags  = null
  default_policies_freeform_tags = local.landing_zone_tags

  policies_defined_tags  = local.custom_policies_defined_tags != null ? merge(local.custom_policies_defined_tags, local.default_policies_defined_tags) : local.default_policies_defined_tags
  policies_freeform_tags = local.custom_policies_freeform_tags != null ? merge(local.custom_policies_freeform_tags, local.default_policies_freeform_tags) : local.default_policies_freeform_tags

  #-----------------------------------------------------------
  #----- Policy statement groups (built as lists, same pattern as core LZ)
  #-----------------------------------------------------------

  # Network admin grants - manages all network resources across hub and spokes
  nw_admin_grants_on_root = [
    "allow group ${join(",", local.nw_admin_group_name)} to read all-resources in tenancy",
    "allow group ${join(",", local.nw_admin_group_name)} to use cloud-shell in tenancy"
  ]
  nw_admin_grants_on_nw_cmp = [
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment ${local.provided_nw_compartment_name}",
    "allow group ${join(",", local.nw_admin_group_name)} to manage drgs in compartment ${local.provided_nw_compartment_name}"
  ]
  nw_admin_grants_on_spoke_cmps = [
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment ${local.provided_os_nw_compartment_name}",
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment ${local.provided_ss_nw_compartment_name}",
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment ${local.provided_ts_nw_compartment_name}",
    "allow group ${join(",", local.nw_admin_group_name)} to manage virtual-network-family in compartment ${local.provided_devt_nw_compartment_name}"
  ]

  # Security admin grants
  sec_admin_grants_on_root = [
    "allow group ${join(",", local.sec_admin_group_name)} to manage cloud-guard-family in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to manage cloudevents-rules in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to read tenancies in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to read objectstorage-namespaces in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to use cloud-shell in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to manage tag-namespaces in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to manage tag-defaults in tenancy",
    "allow group ${join(",", local.sec_admin_group_name)} to read audit-events in tenancy"
  ]
  sec_admin_grants_on_sec_cmp = [
    "allow group ${join(",", local.sec_admin_group_name)} to manage vaults in compartment ${local.provided_sec_compartment_name}",
    "allow group ${join(",", local.sec_admin_group_name)} to manage keys in compartment ${local.provided_sec_compartment_name}",
    "allow group ${join(",", local.sec_admin_group_name)} to manage bastion-family in compartment ${local.provided_sec_compartment_name}",
    "allow group ${join(",", local.sec_admin_group_name)} to manage security-zone in compartment ${local.provided_sec_compartment_name}",
    "allow group ${join(",", local.sec_admin_group_name)} to manage all-resources in compartment ${local.provided_sec_compartment_name}"
  ]

  # SOC grants - read-only security monitoring
  soc_grants_on_root = [
    "allow group ${join(",", local.soc_group_name)} to read cloud-guard-family in tenancy",
    "allow group ${join(",", local.soc_group_name)} to read audit-events in tenancy",
    "allow group ${join(",", local.soc_group_name)} to read all-resources in tenancy",
    "allow group ${join(",", local.soc_group_name)} to use cloud-shell in tenancy"
  ]

  # Operations admin grants
  ops_admin_grants_on_ops_cmp = [
    "allow group ${join(",", local.ops_admin_group_name)} to manage logging-family in compartment ${local.provided_ops_compartment_name}",
    "allow group ${join(",", local.ops_admin_group_name)} to manage ons-family in compartment ${local.provided_ops_compartment_name}",
    "allow group ${join(",", local.ops_admin_group_name)} to manage alarms in compartment ${local.provided_ops_compartment_name}",
    "allow group ${join(",", local.ops_admin_group_name)} to manage metrics in compartment ${local.provided_ops_compartment_name}",
    "allow group ${join(",", local.ops_admin_group_name)} to manage object-family in compartment ${local.provided_ops_compartment_name}",
    "allow group ${join(",", local.ops_admin_group_name)} to read all-resources in tenancy"
  ]

  # Common services grants
  csvcs_admin_grants = [
    "allow group ${join(",", local.csvcs_admin_group_name)} to manage all-resources in compartment ${local.provided_csvcs_compartment_name}",
    "allow group ${join(",", local.csvcs_admin_group_name)} to read all-resources in tenancy"
  ]
  devt_csvcs_admin_grants = [
    "allow group ${join(",", local.devt_csvcs_admin_group_name)} to manage all-resources in compartment ${local.provided_devt_csvcs_compartment_name}",
    "allow group ${join(",", local.devt_csvcs_admin_group_name)} to read all-resources in tenancy"
  ]

  # Spoke network admin grants
  spoke_nw_admin_grants = [
    "allow group ${join(",", local.os_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_os_nw_compartment_name}",
    "allow group ${join(",", local.ss_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_ss_nw_compartment_name}",
    "allow group ${join(",", local.ts_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_ts_nw_compartment_name}",
    "allow group ${join(",", local.devt_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_devt_nw_compartment_name}"
  ]

  # CIS required OCI service policies
  oci_services_grants = [
    "allow service cloudguard to read keys in tenancy",
    "allow service cloudguard to read compartments in tenancy",
    "allow service cloudguard to read tenancies in tenancy",
    "allow service cloudguard to read audit-events in tenancy",
    "allow service cloudguard to read compute-management-family in tenancy",
    "allow service cloudguard to read instance-family in tenancy",
    "allow service cloudguard to read virtual-network-family in tenancy",
    "allow service cloudguard to read volume-family in tenancy",
    "allow service cloudguard to read database-family in tenancy",
    "allow service cloudguard to read object-family in tenancy",
    "allow service cloudguard to read load-balancers in tenancy",
    "allow service cloudguard to read users in tenancy",
    "allow service cloudguard to read groups in tenancy",
    "allow service cloudguard to read policies in tenancy",
    "allow service objectstorage-${var.region} to manage object-family in tenancy",
    "allow service vulnerability-scanning-service to manage instances in tenancy",
    "allow service vulnerability-scanning-service to read compartments in tenancy",
    "allow service vulnerability-scanning-service to read vnics in tenancy",
    "allow service vulnerability-scanning-service to read vnic-attachments in tenancy"
  ]

  #------------------------------------------------------------------------
  #----- Policies configuration map - input to module
  #------------------------------------------------------------------------
  policies_configuration = {
    enable_cis_benchmark_checks : true
    defined_tags  : local.policies_defined_tags
    freeform_tags : local.policies_freeform_tags

    supplied_policies : {
      "NW-ADMIN-ROOT-POLICY" : {
        name        : "${var.service_label}-nw-admin-root-policy"
        description : "${var.lz_provenant_label} network admin root-level grants."
        compartment_id : var.tenancy_ocid
        statements  : local.nw_admin_grants_on_root
        defined_tags  : local.policies_defined_tags
        freeform_tags : local.policies_freeform_tags
      },
      "NW-ADMIN-POLICY" : {
        name        : "${var.service_label}-nw-admin-policy"
        description : "${var.lz_provenant_label} network admin grants on hub and spoke compartments."
        compartment_id : var.tenancy_ocid
        statements  : concat(local.nw_admin_grants_on_nw_cmp, local.nw_admin_grants_on_spoke_cmps)
        defined_tags  : local.policies_defined_tags
        freeform_tags : local.policies_freeform_tags
      },
      "SEC-ADMIN-ROOT-POLICY" : {
        name        : "${var.service_label}-sec-admin-root-policy"
        description : "${var.lz_provenant_label} security admin root-level grants."
        compartment_id : var.tenancy_ocid
        statements  : local.sec_admin_grants_on_root
        defined_tags  : local.policies_defined_tags
        freeform_tags : local.policies_freeform_tags
      },
      "SEC-ADMIN-POLICY" : {
        name        : "${var.service_label}-sec-admin-policy"
        description : "${var.lz_provenant_label} security admin grants on security compartment."
        compartment_id : var.tenancy_ocid
        statements  : local.sec_admin_grants_on_sec_cmp
        defined_tags  : local.policies_defined_tags
        freeform_tags : local.policies_freeform_tags
      },
      "SOC-POLICY" : {
        name        : "${var.service_label}-soc-policy"
        description : "${var.lz_provenant_label} SOC read-only monitoring grants."
        compartment_id : var.tenancy_ocid
        statements  : local.soc_grants_on_root
        defined_tags  : local.policies_defined_tags
        freeform_tags : local.policies_freeform_tags
      },
      "OPS-ADMIN-POLICY" : {
        name        : "${var.service_label}-ops-admin-policy"
        description : "${var.lz_provenant_label} operations admin grants."
        compartment_id : var.tenancy_ocid
        statements  : local.ops_admin_grants_on_ops_cmp
        defined_tags  : local.policies_defined_tags
        freeform_tags : local.policies_freeform_tags
      },
      "CSVCS-POLICY" : {
        name        : "${var.service_label}-csvcs-policy"
        description : "${var.lz_provenant_label} common services grants."
        compartment_id : var.tenancy_ocid
        statements  : concat(local.csvcs_admin_grants, local.devt_csvcs_admin_grants)
        defined_tags  : local.policies_defined_tags
        freeform_tags : local.policies_freeform_tags
      },
      "SPOKE-NW-ADMIN-POLICY" : {
        name        : "${var.service_label}-spoke-nw-admin-policy"
        description : "${var.lz_provenant_label} spoke network admin grants."
        compartment_id : var.tenancy_ocid
        statements  : local.spoke_nw_admin_grants
        defined_tags  : local.policies_defined_tags
        freeform_tags : local.policies_freeform_tags
      },
      "OCI-SERVICES-POLICY" : {
        name        : "${var.service_label}-oci-services-policy"
        description : "${var.lz_provenant_label} CIS required OCI service policies."
        compartment_id : var.tenancy_ocid
        statements  : local.oci_services_grants
        defined_tags  : local.policies_defined_tags
        freeform_tags : local.policies_freeform_tags
      }
    }
  }
}
