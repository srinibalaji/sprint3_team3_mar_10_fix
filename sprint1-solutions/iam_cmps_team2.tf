# =============================================================================
# STAR ELZ V1 — IAM Compartments — TEAM 2 OWNED FILE
# Team 2 domain: SOC + Operations (SOC, OPS)
# Sprint 1, Week 1
# Branch: sprint1/iam-compartments-team2
# =============================================================================
#
# COMPARTMENTS IN THIS FILE (2 of 10 TF-managed):
#   3. star-r-elz-soc-cmp  — SOC operations: SIEM analytics, read-only incident response
#   4. star-r-elz-ops-cmp  — Operations: VCN flow logs, monitoring, alarms, deployment pipeline
# =============================================================================

locals {
  team2_compartments = {

    # -------------------------------------------------------------------------
    # SOC — Security Operations Centre
    # Read-only access to all tenancy logs and audit events
    # Owner: UG_ELZ_SOC
    # -------------------------------------------------------------------------
    (local.soc_compartment_key) : {
      name        : local.provided_soc_compartment_name,
      description : "${var.lz_provenant_label} SOC compartment — read-only monitoring, log review, incident response.",
      defined_tags  : local.cmps_defined_tags,
      freeform_tags : local.cmps_freeform_tags,
      children      : {}
    },

    # -------------------------------------------------------------------------
    # OPS — Operations Compartment
    # Contains: VCN Flow Log groups (all 5 VCNs), Service Connector Hub,
    #           bkt_elz_central_logs, Deployment Pipeline, Linux instances
    # Owner: UG_ELZ_OPS
    # -------------------------------------------------------------------------
    (local.ops_compartment_key) : {
      name        : local.provided_ops_compartment_name,
      description : "${var.lz_provenant_label} operations compartment — logging, monitoring, alarms, deployment pipeline.",
      defined_tags  : local.cmps_defined_tags,
      freeform_tags : local.cmps_freeform_tags,
      children      : {}
    }
  }
}
