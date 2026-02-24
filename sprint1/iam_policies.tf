# =============================================================================
# STAR ELZ V1 — IAM Policies — MODULE ORCHESTRATOR
# This file ONLY calls the lz_policies module and defines shared locals.
# It does NOT define any individual policy objects or statement lists.
#
# EACH TEAM OWNS THEIR OWN FILE:
#   iam_policies_team1.tf — Team 1: NW + SEC policies    (4 policy objects)
#   iam_policies_team2.tf — Team 2: SOC + OPS policies   (2 policy objects)
#   iam_policies_team3.tf — Team 3: CSVCS + CIS policies (2 policy objects)
#   iam_policies_team4.tf — Team 4: Spoke NW policy      (1 policy object)
#
# POLICY OBJECT INVENTORY (9 total):
#   NW-ADMIN-ROOT-POLICY  (T1) — 2 stmts  read all-resources + cloud-shell in tenancy
#   NW-ADMIN-POLICY       (T1) — 6 stmts  manage VCN-family + DRGs in NW + 4 spoke cmps
#   SEC-ADMIN-ROOT-POLICY (T1) — 8 stmts  manage cloud-guard, tag-namespaces in tenancy
#   SEC-ADMIN-POLICY      (T1) — 5 stmts  manage Vault, keys, Bastion, SecZone in SEC cmp
#   SOC-POLICY            (T2) — 4 stmts  read cloud-guard, audit, all-resources in tenancy
#   OPS-ADMIN-POLICY      (T2) — 6 stmts  manage logging/ons/alarms in OPS cmp
#   CSVCS-POLICY          (T3) — 4 stmts  manage all-resources in CSVCS + DEVT_CSVCS cmps
#   OCI-SERVICES-POLICY   (T3) — 19 stmts CIS required Cloud Guard + Object Storage + VSS grants
#   SPOKE-NW-ADMIN-POLICY (T4) — 4 stmts  manage all-resources per spoke group/compartment
#   Total: 58 policy statements
#
# CRITICAL — depends_on:
#   lz_policies must depend on BOTH lz_compartments AND lz_groups.
#   Policy statements reference compartment names (iam_compartments.tf locals)
#   and group names (module.lz_groups output). Both must exist before apply.
# =============================================================================

locals {
  #------------------------------------------------------------------------------------------------------
  #-- Any of these local variables can be overridden in a _override.tf file
  #------------------------------------------------------------------------------------------------------
  custom_policies_defined_tags  = null
  custom_policies_freeform_tags = null
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
  #----- Merge all 4 team policy maps — each team edits only their own file
  #-----------------------------------------------------------
  policies_configuration = {
    enable_cis_benchmark_checks : true
    defined_tags                : local.policies_defined_tags
    freeform_tags               : local.policies_freeform_tags

    supplied_policies : merge(
      local.team1_policies,  # NW-ADMIN-ROOT-POLICY, NW-ADMIN-POLICY, SEC-ADMIN-ROOT-POLICY, SEC-ADMIN-POLICY
      local.team2_policies,  # SOC-POLICY, OPS-ADMIN-POLICY
      local.team3_policies,  # CSVCS-POLICY, OCI-SERVICES-POLICY
      local.team4_policies   # SPOKE-NW-ADMIN-POLICY
    )
  }
}

#------------------------------------------------------------------------
#----- Module call — same pattern as iam_compartments.tf
#------------------------------------------------------------------------
module "lz_policies" {
  depends_on             = [module.lz_compartments, module.lz_groups]
  source                 = "github.com/oci-landing-zones/terraform-oci-modules-iam//policies?ref=v0.3.1"
  providers              = { oci = oci.home }
  tenancy_ocid           = var.tenancy_ocid
  policies_configuration = local.policies_configuration
}
