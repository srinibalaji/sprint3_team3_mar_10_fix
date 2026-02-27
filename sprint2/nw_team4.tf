# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# STAR ELZ V1 — sprint2
#
# =============================================================================
# NETWORK — TEAM 4 OWNED FILE
# Team 4 domain: Hub Network (ELZ_NW) — the most complex team file
# Sprint 2 | Issues: S2-T4 (VCN+Subnet+DRG), S2-T4 (Route Table),
#                    S2-T4 (Sim FW), S2-T4 (Bastion)
# Branch: sprint2/nw-team4
# =============================================================================
#
# RESOURCES IN THIS FILE:
#   PHASE 1 (apply first — other teams depend on hub_drg_id output):
#     oci_core_vcn.hub                  — Hub VCN     10.0.0.0/16
#     oci_core_route_table.hub_fw       — FW subnet RT: empty in V1 (Sprint 3: DRG transit)
#     oci_core_subnet.hub_fw            — FW subnet 10.0.0.0/24 (private — no public IP)
#     oci_core_drg.hub                  — Hub DRG ← PRIMARY Phase 1 output
#     oci_core_route_table.hub_mgmt     — MGMT RT: empty Phase 1, DRG rule added Phase 2
#     oci_core_subnet.hub_mgmt          — MGMT subnet 10.0.1.0/24 (private)
#
#   PHASE 2 (after T4 shares hub_drg_id with all other teams):
#     oci_core_drg_attachment.hub_vcn   — Attaches Hub VCN to Hub DRG
#     MGMT route table updated in-place: DRG rule added via dynamic block
#     oci_core_instance.sim_fw_hub      — Sim Firewall in hub FW subnet (private, no public IP)
#     oci_bastion_bastion.hub           — OCI Bastion in hub MGMT subnet
#
# COMPARTMENT: C1_R_ELZ_NW — var.nw_compartment_id
#
# V1 DESIGN — NO INTERNET GATEWAY:
#   Per STAR ELZ V1 isolated design there is no IGW in the Hub.
#   Hub Sim FW has no public IP. All validation uses OCI NPA (control plane)
#   and Bastion SSH sessions (data plane). Internet-facing routing is Sprint 3+ scope.
#
# DRG TRANSIT ROUTING — SPRINT 3 BACKLOG:
#   Hub FW route table is intentionally empty in V1.
#   OCI DRG v2 defaults to full-mesh — spoke-to-spoke traffic bypasses hub FW.
#   Sprint 3 will add oci_core_drg_route_table + oci_core_drg_route_distribution
#   to force all spoke traffic through the Hub VCN attachment. See README Sprint 3 Backlog.
#
# CRITICAL AFTER PHASE 1:
#   Run: terraform output hub_drg_id
#   Share this OCID with T1, T2, T3 for their Phase 2 apply.
# =============================================================================

# =============================================================================
# PHASE 1 — HUB VCN + IGW + FW SUBNET + DRG + MGMT SUBNET
# [S2-T4] VCN + Subnet + DRG for ELZ_NW compartment
# =============================================================================

resource "oci_core_vcn" "hub" {
  compartment_id = var.nw_compartment_id
  cidr_blocks    = [local.hub_vcn_cidr]
  display_name   = local.hub_vcn_name
  dns_label      = local.hub_vcn_dns_label

  freeform_tags = local.net_freeform_tags
  defined_tags  = local.net_defined_tags
}

# Hub FW Route Table — empty in V1 (no IGW, no rules)
# Sprint 3: will add DRG route distribution to force spoke traffic through here.
# Leave this resource — it establishes the RT OCID that hub_fw subnet references.
resource "oci_core_route_table" "hub_fw" {
  compartment_id = var.nw_compartment_id
  vcn_id         = oci_core_vcn.hub.id
  display_name   = local.hub_fw_rt_name

  # Intentionally no route_rules in V1.
  # Sprint 3 backlog: add DRG transit route distribution here.

  freeform_tags = local.net_freeform_tags
  defined_tags  = local.net_defined_tags
}

# Hub FW Subnet — private in V1 (no public IPs, no IGW)
resource "oci_core_subnet" "hub_fw" {
  compartment_id             = var.nw_compartment_id
  vcn_id                     = oci_core_vcn.hub.id
  cidr_block                 = local.hub_fw_subnet_cidr
  display_name               = local.hub_fw_subnet_name
  dns_label                  = local.hub_fw_subnet_dns_label
  prohibit_public_ip_on_vnic = true   # private — no IGW in V1
  route_table_id             = oci_core_route_table.hub_fw.id

  freeform_tags = local.net_freeform_tags
  defined_tags  = local.net_defined_tags
}

# Hub DRG — THE primary Phase 1 output. Other teams need this OCID.
resource "oci_core_drg" "hub" {
  compartment_id = var.nw_compartment_id
  display_name   = local.hub_drg_name

  freeform_tags = local.net_freeform_tags
  defined_tags  = local.net_defined_tags
}

# Hub MGMT Route Table — empty Phase 1, DRG rule added Phase 2
resource "oci_core_route_table" "hub_mgmt" {
  compartment_id = var.nw_compartment_id
  vcn_id         = oci_core_vcn.hub.id
  display_name   = local.hub_mgmt_rt_name

  dynamic "route_rules" {
    for_each = local.phase2_enabled ? [1] : []
    content {
      description       = "Route to Hub DRG — spoke access for Bastion sessions"
      destination       = local.anywhere
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_drg.hub.id
    }
  }

  freeform_tags = local.net_freeform_tags
  defined_tags  = local.net_defined_tags

  depends_on = [oci_core_drg_attachment.hub_vcn]
}

# Hub MGMT Subnet — private (Bastion — no public IPs on managed resources)
resource "oci_core_subnet" "hub_mgmt" {
  compartment_id             = var.nw_compartment_id
  vcn_id                     = oci_core_vcn.hub.id
  cidr_block                 = local.hub_mgmt_subnet_cidr
  display_name               = local.hub_mgmt_subnet_name
  dns_label                  = local.hub_mgmt_subnet_dns_label
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.hub_mgmt.id

  freeform_tags = local.net_freeform_tags
  defined_tags  = local.net_defined_tags
}

# =============================================================================
# PHASE 2 — DRG ATTACHMENT + SIM FW + BASTION
# count = 0 Phase 1, count = 1 Phase 2
# [S2-T4] Route Table + Sim FW + Bastion for ELZ_NW compartment
# =============================================================================

# Attach Hub VCN to Hub DRG
resource "oci_core_drg_attachment" "hub_vcn" {
  count        = local.phase2_enabled ? 1 : 0
  drg_id       = oci_core_drg.hub.id
  display_name = local.hub_drg_attachment_name

  network_details {
    id   = oci_core_vcn.hub.id
    type = "VCN"
  }
}

# [S2-T4] Sim Firewall for Hub ELZ_NW compartment
# Placed in hub_fw subnet. Public IP — simulates north-south FW.
resource "oci_core_instance" "sim_fw_hub" {
  count               = local.phase2_enabled ? 1 : 0
  compartment_id      = var.nw_compartment_id
  availability_domain = local.ad_name
  display_name        = local.hub_fw_instance_name
  shape               = var.sim_fw_shape

  shape_config {
    ocpus         = var.sim_fw_ocpus
    memory_in_gbs = var.sim_fw_memory_gb
  }

  source_details {
    source_type = "image"
    source_id   = local.sim_fw_image_id
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.hub_fw.id
    display_name           = "VNIC-${local.hub_fw_instance_name}"
    assign_public_ip       = false   # V1 isolated design — no public IP, no IGW
    skip_source_dest_check = true    # REQUIRED: enables IP forwarding
    freeform_tags          = local.cmp_freeform_tags
  }

  metadata = {
    user_data = local.sim_fw_userdata
  }

  freeform_tags = local.cmp_freeform_tags
  defined_tags  = local.cmp_defined_tags
}

# [S2-T4] Bastion for Hub ELZ_NW compartment
# OCI Bastion Service — secure SSH access to spoke workloads without public IPs.
# Placed in hub_mgmt subnet (private).
resource "oci_bastion_bastion" "hub" {
  count                        = local.phase2_enabled ? 1 : 0
  compartment_id               = var.nw_compartment_id
  bastion_type                 = "STANDARD"
  name                         = local.hub_bastion_name
  target_subnet_id             = oci_core_subnet.hub_mgmt.id
  client_cidr_block_allow_list = [var.bastion_client_cidr]

  freeform_tags = local.net_freeform_tags
  defined_tags  = local.net_defined_tags
}
