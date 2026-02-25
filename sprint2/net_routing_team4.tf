# =============================================================================
# STAR ELZ V1 — Sprint 2: Hub Networking
# TEAM 4 OWNED FILE — Route Tables, Security Lists, Sim Firewall
#
# Sprint 2, Week 2 — Tasks:
#   Task 3a: Security List for hub subnets     (resource: oci_core_security_list.hub)
#   Task 3b: Route table for firewall subnet   (resource: oci_core_route_table.hub_fw)
#   Task 3c: Route table for mgmt subnet       (resource: oci_core_route_table.hub_mgmt)
#   Task 5:  Sim Firewall compute instance     (resource: oci_core_instance.sim_fw)
#            NOTE: provisioned via OCI Console by DSTA T4 — Terraform stub only
#   Task 6:  IP forwarding configuration       (Oracle-led — see README § Task 6)
#
# Branch: sprint2/net-routing-team4
# Owner:  UG_ELZ_NW (routing) + UG_OS_ELZ_NW (sim firewall)
#
# Depends on: net_vcn_team1.tf, net_drg_team3.tf
# =============================================================================

# TODO Sprint 2 — Team 4:
#
# Task 3a — Security List (hub subnets — internal traffic only)
# Create resource "oci_core_security_list" "hub"
#   - compartment_id = var.nw_compartment_id
#   - vcn_id         = oci_core_vcn.hub.id
#   - display_name   = "${var.service_label}-hub-sl"
#   - ingress_security_rules: allow TCP/UDP within hub VCN CIDR
#   - egress_security_rules:  allow all (stateful)
#   - freeform_tags  = local.landing_zone_tags
#
# Task 3b — Route table for firewall subnet
# Create resource "oci_core_route_table" "hub_fw"
#   - compartment_id = var.nw_compartment_id
#   - vcn_id         = oci_core_vcn.hub.id
#   - display_name   = "${var.service_label}-hub-fw-rt"
#   - route_rules: default route (0.0.0.0/0) → DRG
#   - route_rules: Oracle services → Service Gateway
#
# Task 3c — Route table for mgmt subnet
# Create resource "oci_core_route_table" "hub_mgmt"
#   - compartment_id = var.nw_compartment_id
#   - vcn_id         = oci_core_vcn.hub.id
#   - display_name   = "${var.service_label}-hub-mgmt-rt"
#   - route_rules: Oracle services → Service Gateway
#
# Task 5 — Sim Firewall compute stub (OCI Console provisioning)
# Create resource "oci_core_instance" "sim_fw"  — STUB ONLY in Sprint 2
#   - compartment_id = var.nw_compartment_id
#   - availability_domain: data lookup required
#   - shape = var.sim_fw_shape
#   - shape_config: ocpus = var.sim_fw_ocpus, memory_in_gbs = var.sim_fw_memory_gb
#   - subnet_id = oci_core_subnet.hub_fw.id
#   - source_details: Oracle Linux 8 image OCID (latest)
#   NOTE: IP forwarding enabled via metadata: {"user_data": base64(ip_forwarding_script)}
#
# Reference: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_route_table
# Reference: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance
