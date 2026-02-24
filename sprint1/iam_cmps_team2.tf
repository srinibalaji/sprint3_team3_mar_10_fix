# =============================================================================
# STAR ELZ V1 — IAM Compartments — TEAM 2 OWNED FILE
# Team 2 domain: SOC + Operations (SOC, OPS)
# Sprint 1, Week 1 — Day 1
# Branch: sprint1/iam-compartments-team2
# =============================================================================
# YOUR TASK:
#   Define local.team2_compartments — a map with 2 entries:
#     3. SOC — security operations centre compartment
#     4. OPS — operations compartment
#
# KEYS  → local.soc_compartment_key,  local.ops_compartment_key
# NAMES → local.provided_soc_compartment_name, local.provided_ops_compartment_name
# =============================================================================

# TODO: write local.team2_compartments below this line
locals {
  team2_compartments = {
    (local.soc_compartment_key) : {
      name : local.provided_soc_compartment_name
      description : "SOC — read-only monitoring, incident response"
    },
    (local.ops_compartment_key) : {
      name : local.provided_ops_compartment_name
      description : "Operations — Flow Logs, Service Connector, Deployment Pipeline"
    }
  }
}
