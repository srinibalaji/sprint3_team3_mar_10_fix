# =============================================================================
# STAR ELZ V1 — IAM Policies — TEAM 3 OWNED FILE
# Team 3 domain: Common Shared Services + Governance (CSVCS, DEVT_CSVCS)
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-policies-team3
# =============================================================================
#
# POLICY OBJECTS IN THIS FILE (2 of 9):
#   7. CSVCS-POLICY       — Common + Dev common services grants
#   8. OCI-SERVICES-POLICY — CIS required OCI service grants (no group — service principals)
#
# HOW THIS FITS:
#   This file defines local.team3_policies, a map that is merged with
#   team1, team2, and team4 maps in iam_policies.tf before being passed
#   to the lz_policies module. Each team owns their map. Zero conflicts.
#
# GROUPS USED (output from iam_groups.tf module):
#   local.csvcs_admin_group_name      — star-ug-elz-csvcs
#   local.devt_csvcs_admin_group_name — star-ug-devt-csvcs
#
# COMPARTMENTS REFERENCED (locals from iam_compartments.tf):
#   local.provided_csvcs_compartment_name      — CSVCS-POLICY
#   local.provided_devt_csvcs_compartment_name — CSVCS-POLICY
#
# NOTE — OCI-SERVICES-POLICY:
#   These are CIS Level 1 required grants for OCI service principals
#   (Cloud Guard, Object Storage, Vulnerability Scanning Service).
#   They use "allow service <name>" — no IAM group involved.
#   Team 3 owns this because they own the governance and tagging layer.
#   TC-05 (tag namespace + CostCenter) and this policy together form
#   the full governance deliverable for Sprint 1.
# =============================================================================

locals {
  team3_policies = {

    # -------------------------------------------------------------------------
    # CSVCS-POLICY
    # CSVCS compartment: manage all-resources (APM, File Transfer, ServiceNow, Jira).
    # DEVT_CSVCS compartment: manage all-resources (dev toolchain services).
    # Both groups get read all-resources in tenancy for cross-compartment visibility.
    # -------------------------------------------------------------------------
    "CSVCS-POLICY" : {
      name           : "${var.service_label}-csvcs-policy"
      description    : "${var.lz_provenant_label} common services grants."
      compartment_id : var.tenancy_ocid
      statements : concat(
        local.csvcs_admin_grants,
        local.devt_csvcs_admin_grants
      )
      defined_tags  : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    },

    # -------------------------------------------------------------------------
    # OCI-SERVICES-POLICY
    # CIS Benchmark Level 1 required: Cloud Guard, Object Storage, and
    # Vulnerability Scanning Service need these tenancy-wide read grants
    # to function. Without them Cloud Guard cannot inspect resources (TC-03 dep).
    # -------------------------------------------------------------------------
    "OCI-SERVICES-POLICY" : {
      name           : "${var.service_label}-oci-services-policy"
      description    : "${var.lz_provenant_label} CIS required OCI service policies."
      compartment_id : var.tenancy_ocid
      statements : concat(
        local.oci_services_grants
      )
      defined_tags  : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    }
  }

  # ---------------------------------------------------------------------------
  # Statement lists — owned by Team 3, consumed by policy objects above
  # ---------------------------------------------------------------------------

  # Common services grants — CSVCS compartment
  csvcs_admin_grants = [
    "allow group ${join(",", local.csvcs_admin_group_name)} to manage all-resources in compartment ${local.provided_csvcs_compartment_name}",
    "allow group ${join(",", local.csvcs_admin_group_name)} to read all-resources in tenancy"
  ]

  # Dev common services grants — DEVT_CSVCS compartment
  devt_csvcs_admin_grants = [
    "allow group ${join(",", local.devt_csvcs_admin_group_name)} to manage all-resources in compartment ${local.provided_devt_csvcs_compartment_name}",
    "allow group ${join(",", local.devt_csvcs_admin_group_name)} to read all-resources in tenancy"
  ]

  # CIS required OCI service grants — service principals, not IAM groups
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
}
