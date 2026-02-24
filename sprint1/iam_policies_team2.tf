# =============================================================================
# STAR ELZ V1 — IAM Policies — TEAM 2 OWNED FILE
# Team 2 domain: SOC + Operations
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-policies-team2
# =============================================================================
# YOUR TASK:
#   Define local.team2_policies — a map with 2 policy objects:
#     5. "SOC-POLICY"       — read cloud-guard-family, audit-events, all-resources in tenancy
#                             CRITICAL: read verbs ONLY — no manage, no use (except cloud-shell)
#     6. "OPS-ADMIN-POLICY" — manage logging-family, ons-family, alarms, metrics,
#                             object-family in OPS cmp + read all-resources in tenancy
#
# Also define statement lists:
#   local.soc_grants_on_root, local.ops_admin_grants_on_ops_cmp
#
# GROUP LOCALS → local.soc_group_name, local.ops_admin_group_name
# COMPARTMENT  → local.provided_ops_compartment_name
# TC-04 TEST: a member of SOC attempting oci logging log-group delete must get 403
# =============================================================================

# TODO: write local.team2_policies and statement lists below this line
