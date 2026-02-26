# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# STAR ELZ V1 — sprint1-solutions-v2
#
# =============================================================================
# IAM POLICIES — TEAM 4 OWNED FILE
# Team 4 domain: Agency Spoke Networks
# Sprint 1, Week 2 | SPRINT1-ISSUE-#14
# Branch: sprint1/iam-policies-team4
# =============================================================================
#
# POLICY OBJECTS IN THIS FILE (1 of 9):
#   7. UG-SPOKE-NW-Policy — Each spoke group manages all-resources in its own cmp
#
# CRITICAL SoD RULES (TC-03):
#   Each spoke group is scoped to its own compartment ONLY.
#   No spoke group appears in any statement granting access to:
#     - C1_R_ELZ_SEC  (Security)
#     - C1_R_ELZ_NW   (Hub Network)
#     - C1_R_ELZ_OPS  (Operations)
#     - C1_R_ELZ_SOC  (SOC)
#     - Another spoke's compartment
#   TC-03 negative test: UG_DEVT_ELZ_NW attempting to create a resource in
#   C1_R_ELZ_SEC must receive HTTP 403 Authorization failed.
#
# SPRINT1-FIX (SPRINT1-ISSUE-#14, policy-naming):
#   name changed from "${var.service_label}-spoke-nw-admin-policy"
#   to local.spoke_nw_policy_name = "UG-SPOKE-NW-Policy".
# =============================================================================

locals {
  team4_policies = {

    # -------------------------------------------------------------------------
    # UG-SPOKE-NW-Policy — Spoke Network Administrator Policy
    # 4 statements, one per spoke group/compartment pair.
    # Single policy object — all statements share the same administrative scope.
    # Split into separate objects in V2 if per-compartment policy attachment required.
    # -------------------------------------------------------------------------
    "SPOKE-NW-POLICY" : {
      name : local.spoke_nw_policy_name
      description : "${local.lz_description} — Spoke Network Administrator policy. Each spoke group manages its own compartment only."
      compartment_id : local.tenancy_id
      statements : concat(
        local.spoke_nw_admin_grants
      )
      defined_tags : local.policies_defined_tags
      freeform_tags : local.policies_freeform_tags
    }
  }

  # ---------------------------------------------------------------------------
  # STATEMENT LIST — Spoke Network Administrators
  # One statement per group/compartment pair.
  # Compartment names come from locals.tf constants via provided_* locals.
  # Group names come from locals.tf constants via nw_admin_group_name etc.
  # ---------------------------------------------------------------------------
  spoke_nw_admin_grants = [
    "allow group ${join(",", local.os_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_os_nw_compartment_name}",
    "allow group ${join(",", local.ss_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_ss_nw_compartment_name}",
    "allow group ${join(",", local.ts_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_ts_nw_compartment_name}",
    "allow group ${join(",", local.devt_nw_admin_group_name)} to manage all-resources in compartment ${local.provided_devt_nw_compartment_name}"
  ]
}
