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
locals {
    team2_policies = {
        "SOC-POLICY-TENANCY" : {
            name : "UG_ELZ_SOC-Policy"
            description : "SOC - Read all resources, read audit-events"
            compartment_id : var.tenancy_ocid
            statements : [
                "Allow group ${local.provided_soc_group_name} to read all-resources in tenancy",
                "Allow group ${local.provided_soc_group_name} to read audit-events in tenancy"
            ]
        }
        "SOC-POLICY-COMPARTMENT" : {
            name : "UG_ELZ_SOC-Policy"
            description : "SOC - Read log-groups, log-content in SOC cmp"
            compartment_id : module.lz_compartments.compartments[local.soc_compartment_key].id
            statements : [
                "Allow group ${local.provided_soc_group_name} to read log-groups in compartment ${local.provided_soc_compartment_name}",
                "Allow group ${local.provided_soc_group_name} to read log-content in compartment ${local.provided_soc_compartment_name}"
            ]
        }
        "OPS-ADMIN-POLICY-TENANCY" : {
            name : "UG_ELZ_OPS-Admin-Policy"
            description : "OPS - Manage logging, objects, service-connector in OPS cmp"
            compartment_id : var.tenancy_ocid
            statements : [
                "Allow group ${local.provided_ops_admin_group_name} to manage alarms in tenancy",
                "Allow group ${local.provided_ops_admin_group_name} to manage metrics in tenancy"
            ]
        }
        "OPS-ADMIN-POLICY-COMPARTMENT" : {
            name : "UG_ELZ_OPS-Admin-Policy"
            description : "OPS - Manage alarms, metrics"
            compartment_id : module.lz_compartments.compartments[local.ops_compartment_key].id
            statements : [
                "Allow group ${local.provided_ops_admin_group_name} to manage logging-family in compartment ${local.provided_ops_compartment_name}",
                "Allow group ${local.provided_ops_admin_group_name} to manage objects in compartment ${local.provided_ops_compartment_name}",
                "Allow group ${local.provided_ops_admin_group_name} to manage serviceconnectors in compartment ${local.provided_ops_compartment_name}"
            ]
        }
    }
}
