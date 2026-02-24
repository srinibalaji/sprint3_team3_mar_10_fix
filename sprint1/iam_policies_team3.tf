# =============================================================================
# STAR ELZ V1 — IAM Policies — TEAM 3 OWNED FILE
# Team 3 domain: Common Shared Services + Governance
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-policies-team3
# =============================================================================
# YOUR TASK:
#   Define local.team3_policies — a map with 2 policy objects:
#     7. "CSVCS-POLICY"       — manage all-resources in CSVCS cmp + DEVT_CSVCS cmp
#                               read all-resources in tenancy (both groups)
#     8. "OCI-SERVICES-POLICY" — CIS required grants for Cloud Guard, Object Storage,
#                                Vulnerability Scanning Service (service principals)
#
# Also define statement lists:
#   local.csvcs_admin_grants, local.devt_csvcs_admin_grants, local.oci_services_grants
#
# GROUP LOCALS → local.csvcs_admin_group_name, local.devt_csvcs_admin_group_name
# COMPARTMENTS → local.provided_csvcs_compartment_name, local.provided_devt_csvcs_compartment_name
# NOTE: OCI-SERVICES-POLICY uses "allow service <name>" — no IAM group needed
# =============================================================================

# TODO: write local.team3_policies and statement lists below this line
