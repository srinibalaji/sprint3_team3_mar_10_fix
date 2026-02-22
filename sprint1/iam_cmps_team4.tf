# =============================================================================
# STAR ELZ V1 — IAM Compartments — TEAM 4 OWNED FILE
# Team 4 domain: Agency Spoke Networks (OS, SS, TS, DEVT)
# Sprint 1, Week 1
# Branch: sprint1/iam-compartments-team4
# =============================================================================
#
# COMPARTMENTS IN THIS FILE (4 of 10 TF-managed):
#   7.  star-os-elz-nw-cmp   — Operational Systems spoke: VCN, subnets, NSGs
#   8.  star-ss-elz-nw-cmp   — Shared Services spoke: VCN, subnets, NSGs
#   9.  star-ts-elz-nw-cmp   — Trusted Services spoke: VCN, subnets, NSGs
#   10. star-devt-elz-nw-cmp — Development/Test spoke: VCN, subnets, NSGs
#
# TEAM 4 ALSO OWNS (done in OCI Console — NOT Terraform):
#   star-sim-ext-cmp   — Manual creation in Console. OCID passed as var.sim_ext_compartment_id
#   star-sim-child-cmp — Manual creation in Console. OCID passed as var.sim_child_compartment_id
#   Manual instructions: see sprint4/README.md § "Manual Prerequisite Steps"
# =============================================================================

locals {
  team4_compartments = {

    # -------------------------------------------------------------------------
    # OS-NW — Operational Systems Spoke Network Compartment
    # Contains: OS VCN (10.1.0.0/24), subnets, route tables, security lists,
    #           NSGs, OS workload compute instance (Sprint 4)
    # Owner: UG_OS_ELZ_NW
    # -------------------------------------------------------------------------
    (local.os_nw_compartment_key) : {
      name        : local.provided_os_nw_compartment_name,
      description : "${var.lz_provenant_label} Operational Systems spoke — VCN, subnets, NSGs, workload instances.",
      defined_tags  : local.cmps_defined_tags,
      freeform_tags : local.cmps_freeform_tags,
      children      : {}
    },

    # -------------------------------------------------------------------------
    # SS-NW — Shared Services Spoke Network Compartment
    # Contains: SS VCN (10.2.0.0/24), subnets, route tables, security lists,
    #           NSGs, SS workload compute instance (Sprint 4)
    # Owner: UG_SS_ELZ_NW
    # -------------------------------------------------------------------------
    (local.ss_nw_compartment_key) : {
      name        : local.provided_ss_nw_compartment_name,
      description : "${var.lz_provenant_label} Shared Services spoke — VCN, subnets, NSGs, workload instances.",
      defined_tags  : local.cmps_defined_tags,
      freeform_tags : local.cmps_freeform_tags,
      children      : {}
    },

    # -------------------------------------------------------------------------
    # TS-NW — Trusted Services Spoke Network Compartment
    # Contains: TS VCN (10.3.0.0/24), subnets, route tables, security lists,
    #           NSGs, TS workload compute instance (Sprint 4)
    # Owner: UG_TS_ELZ_NW
    # -------------------------------------------------------------------------
    (local.ts_nw_compartment_key) : {
      name        : local.provided_ts_nw_compartment_name,
      description : "${var.lz_provenant_label} Trusted Services spoke — VCN, subnets, NSGs, workload instances.",
      defined_tags  : local.cmps_defined_tags,
      freeform_tags : local.cmps_freeform_tags,
      children      : {}
    },

    # -------------------------------------------------------------------------
    # DEVT-NW — Development/Test Spoke Network Compartment
    # Contains: DEVT VCN (10.4.0.0/24), subnets, route tables, security lists
    #           Network-only in V1 — no compute instance deployed here
    # Owner: UG_DEVT_ELZ_NW
    # -------------------------------------------------------------------------
    (local.devt_nw_compartment_key) : {
      name        : local.provided_devt_nw_compartment_name,
      description : "${var.lz_provenant_label} Development/Test spoke — VCN, subnets, NSGs. Network-only in V1.",
      defined_tags  : local.cmps_defined_tags,
      freeform_tags : merge(local.cmps_freeform_tags, { "environment" = "development" }),
      children      : {}
    }
  }
}
