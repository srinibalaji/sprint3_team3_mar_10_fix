# =============================================================================
# STAR ELZ V1 — Sprint 2: Hub Networking
# TEAM 3 OWNED FILE — DRG + VCN Attachment
#
# Sprint 2, Week 1 — Tasks:
#   Task 2a: DRG                  (resource: oci_core_drg.hub)
#   Task 2b: DRG-VCN attachment   (resource: oci_core_drg_attachment.hub_vcn)
#
# Branch: sprint2/net-drg-team3
# Owner:  UG_ELZ_NW
#
# Depends on: net_vcn_team1.tf (oci_core_vcn.hub must exist)
# =============================================================================

# TODO Sprint 2 — Team 3:
# 1. Create resource "oci_core_drg" "hub"
#    - compartment_id = var.nw_compartment_id
#    - display_name   = var.drg_name
#    - freeform_tags  = local.landing_zone_tags
#
# 2. Create resource "oci_core_drg_attachment" "hub_vcn"
#    - drg_id         = oci_core_drg.hub.id
#    - display_name   = "${var.service_label}-hub-drg-vcn-attach"
#    - network_details block:
#        id   = oci_core_vcn.hub.id
#        type = "VCN"
#
# Reference: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_drg
# Reference: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_drg_attachment
