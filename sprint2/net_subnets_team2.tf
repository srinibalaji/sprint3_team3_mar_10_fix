# =============================================================================
# STAR ELZ V1 — Sprint 2: Hub Networking
# TEAM 2 OWNED FILE — Hub Subnets
#
# Sprint 2, Week 1 — Tasks:
#   Task 1c: Firewall subnet  (resource: oci_core_subnet.hub_fw)
#   Task 1d: Mgmt subnet      (resource: oci_core_subnet.hub_mgmt)
#
# Branch: sprint2/net-subnets-team2
# Owner:  UG_ELZ_NW
#
# Depends on: net_vcn_team1.tf (oci_core_vcn.hub must exist)
# =============================================================================

# TODO Sprint 2 — Team 2:
# 1. Create resource "oci_core_subnet" "hub_fw"  — Sim Firewall subnet
#    - compartment_id  = var.nw_compartment_id
#    - vcn_id          = oci_core_vcn.hub.id
#    - cidr_block      = var.hub_fw_subnet_cidr   # 10.0.0.0/24
#    - display_name    = "${var.service_label}-hub-fw-snet"
#    - dns_label       = "hubfw"
#    - prohibit_public_ip_on_vnic = true  (private subnet)
#    - freeform_tags   = local.landing_zone_tags
#
# 2. Create resource "oci_core_subnet" "hub_mgmt"  — Management/Bastion subnet
#    - compartment_id  = var.nw_compartment_id
#    - vcn_id          = oci_core_vcn.hub.id
#    - cidr_block      = var.hub_mgmt_subnet_cidr  # 10.0.1.0/24
#    - display_name    = "${var.service_label}-hub-mgmt-snet"
#    - dns_label       = "hubmgmt"
#    - prohibit_public_ip_on_vnic = true
#    - freeform_tags   = local.landing_zone_tags
#
# Reference: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet
