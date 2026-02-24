# =============================================================================
# STAR ELZ V1 — IAM Policies — TEAM 1 OWNED FILE
# Team 1 domain: Hub Network + Security
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-policies-team1
# =============================================================================
# YOUR TASK:
#   Define local.team1_policies — a map with 4 policy objects:
#     1. "NW-ADMIN-ROOT-POLICY"  — read all-resources + cloud-shell in tenancy
#     2. "NW-ADMIN-POLICY"       — manage VCN-family + DRGs in NW cmp
#                                  manage VCN-family in all 4 spoke cmps
#     3. "SEC-ADMIN-ROOT-POLICY" — manage cloud-guard-family, tag-namespaces in tenancy
#     4. "SEC-ADMIN-POLICY"      — manage vaults, keys, bastion-family, security-zone in SEC cmp
#
# Also define the statement lists these policies consume:
#   local.nw_admin_grants_on_root, local.nw_admin_grants_on_nw_cmp,
#   local.nw_admin_grants_on_spoke_cmps, local.sec_admin_grants_on_root,
#   local.sec_admin_grants_on_sec_cmp
#
# GROUP LOCALS  → local.nw_admin_group_name, local.sec_admin_group_name
# COMPARTMENT LOCALS → local.provided_nw_compartment_name, local.provided_sec_compartment_name,
#                      local.provided_os/ss/ts/devt_nw_compartment_name
# TAG LOCALS    → local.policies_defined_tags, local.policies_freeform_tags
# TENANCY       → var.tenancy_ocid  (use as compartment_id for all root-level policies)
# =============================================================================

# TODO: write local.team1_policies and statement lists below this line
