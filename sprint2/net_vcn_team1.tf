# =============================================================================
# STAR ELZ V1 — Sprint 2: Hub Networking
# TEAM 1 OWNED FILE — Hub VCN + Service Gateway
#
# Sprint 2, Week 1 — Tasks:
#   Task 1a: Hub VCN (resource: oci_core_vcn.hub)
#   Task 1b: Service Gateway (resource: oci_core_service_gateway.hub_sg)
#
# Branch: sprint2/net-vcn-team1
# Owner:  UG_ELZ_NW
#
# CIDR: 10.0.0.0/16 — do not change without updating IP Plan in State Book
# =============================================================================

# TODO Sprint 2 — Team 1:
# 1. Create resource "oci_core_vcn" "hub" in var.nw_compartment_id
#    - cidr_blocks   = [var.hub_vcn_cidr]
#    - display_name  = var.hub_vcn_name
#    - dns_label     = "hubvcn"
#    - freeform_tags = local.landing_zone_tags
#
# 2. Create resource "oci_core_service_gateway" "hub_sg"
#    - compartment_id = var.nw_compartment_id
#    - vcn_id         = oci_core_vcn.hub.id
#    - services block: use data.oci_core_services.all_services.services[0].id
#    - display_name  = "${var.service_label}-hub-sg"
#    - freeform_tags = local.landing_zone_tags
#
# Reference: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn
# Reference: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_service_gateway
