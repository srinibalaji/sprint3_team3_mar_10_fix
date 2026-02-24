# =============================================================================
# STAR ELZ V1 — IAM Policies — TEAM 4 OWNED FILE
# Team 4 domain: Agency Spoke Networks
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-policies-team4
# =============================================================================
# YOUR TASK:
#   Define local.team4_policies — a map with 1 policy object:
#     9. "SPOKE-NW-ADMIN-POLICY" — each spoke group manages all-resources in
#                                   its own compartment (4 statements, 1 per spoke)
#
# Also define statement list:
#   local.spoke_nw_admin_grants
#
# GROUP LOCALS → local.os_nw_admin_group_name, local.ss_nw_admin_group_name,
#                local.ts_nw_admin_group_name,  local.devt_nw_admin_group_name
# COMPARTMENTS → local.provided_os/ss/ts/devt_nw_compartment_name
# SoD RULE: NO spoke group may appear in any statement granting access to SEC cmp
#            TC-03 specifically tests that star-ug-devt-elz-nw cannot write to SEC
# =============================================================================

# TODO: write local.team4_policies and statement lists below this line
