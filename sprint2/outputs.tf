# =============================================================================
# STAR ELZ V1 — Sprint 2: Hub Networking
# Outputs — exported for Sprint 3 consumption
#
# After Sprint 2 apply run:
#   terraform output -json > sprint2_outputs.json
# Share sprint2_outputs.json with Sprint 3 team.
# =============================================================================

# TODO Sprint 2: uncomment outputs once resources are created

# output "hub_vcn_id" {
#   description = "OCID of the Hub VCN."
#   value       = oci_core_vcn.hub.id
# }

# output "hub_drg_id" {
#   description = "OCID of the Hub DRG."
#   value       = oci_core_drg.hub.id
# }

# output "hub_fw_subnet_id" {
#   description = "OCID of the firewall subnet."
#   value       = oci_core_subnet.hub_fw.id
# }

# output "hub_mgmt_subnet_id" {
#   description = "OCID of the management/bastion subnet."
#   value       = oci_core_subnet.hub_mgmt.id
# }

# output "sim_fw_private_ip" {
#   description = "Private IP of the sim firewall instance."
#   value       = oci_core_instance.sim_fw.private_ip
# }
