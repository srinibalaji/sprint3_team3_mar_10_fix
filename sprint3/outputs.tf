# ─────────────────────────────────────────────────────────────
# STAR ELZ V1 — Sprint 3 — Outputs
# Sprint 4 (Compute) needs these for AD Bridge, DNS, Hello World.
# ─────────────────────────────────────────────────────────────

# ── DRG Route Tables ──
output "hub_spoke_mesh_drgrt_id" {
  description = "OCID of drgrt_r_hub_spoke_mesh (Hub DRG RT with import distribution)"
  value       = oci_core_drg_route_table.hub_spoke_mesh.id
}

output "spoke_to_hub_drgrt_id" {
  description = "OCID of drgrt_spoke_to_hub (Spoke DRG RT with static 0/0 → Hub)"
  value       = oci_core_drg_route_table.spoke_to_hub.id
}

# ── Service Gateway ──
# NOTE: SGW moved to Sprint 2. Output hub_sgw_id is in Sprint 2 outputs.tf.

# ── Logging ──
output "nw_log_group_id" {
  description = "OCID of lg_r_elz_nw_flow log group"
  value       = oci_logging_log_group.nw_flow.id
}

# ── Object Storage ──
output "log_bucket_name" {
  description = "Name of bkt_r_elz_sec_logs bucket"
  value       = oci_objectstorage_bucket.logs.name
}

# ── Notifications ──
output "security_alerts_topic_id" {
  description = "OCID of nt_r_elz_sec_alerts notification topic"
  value       = oci_ons_notification_topic.security_alerts.id
}

# ── VCN Ingress RT ──
output "hub_ingress_rt_id" {
  description = "OCID of rt_r_elz_nw_hub_ingress (VCN ingress RT on Hub DRG attachment)"
  value       = oci_core_route_table.hub_ingress.id
}

# ── Vault (KMS) ──
output "vault_id" {
  description = "OCID of vlt_r_elz_sec Vault"
  value       = oci_kms_vault.sec.id
}

output "vault_management_endpoint" {
  description = "Management endpoint for vlt_r_elz_sec Vault"
  value       = oci_kms_vault.sec.management_endpoint
}

output "vault_crypto_endpoint" {
  description = "Crypto endpoint for vlt_r_elz_sec Vault (encrypt/decrypt operations)"
  value       = oci_kms_vault.sec.crypto_endpoint
}

output "master_key_id" {
  description = "OCID of key_r_elz_sec_master AES-256 master encryption key"
  value       = oci_kms_key.master.id
}

# ── Cloud Guard ──
output "cg_target_id" {
  description = "OCID of Cloud Guard target on tenancy root"
  value       = oci_cloud_guard_target.root.id
}

output "cg_config_recipe_id" {
  description = "OCID of custom configuration detector recipe"
  value       = oci_cloud_guard_detector_recipe.config.id
}

# ── Security Zones ──
output "sz_sec_id" {
  description = "OCID of security zone on C1_R_ELZ_SEC"
  value       = oci_cloud_guard_security_zone.sec.id
}

output "sz_nw_id" {
  description = "OCID of security zone on C1_R_ELZ_NW"
  value       = oci_cloud_guard_security_zone.nw.id
}

# ── Service Connector Hub ──
output "sch_connector_id" {
  description = "OCID of sch_r_elz_sec_log_to_bucket — flow logs → Object Storage"
  value       = oci_sch_service_connector.log_to_bucket.id
}

# ── VSS ──
output "vss_recipe_id" {
  description = "OCID of vssr_r_elz_sec_host scan recipe"
  value       = oci_vulnerability_scanning_host_scan_recipe.default.id
}

# ── Certificates Manager ──
output "internal_ca_id" {
  description = "OCID of ca_r_elz_sec_internal — Internal CA for V2+ TLS"
  value       = oci_certificates_management_certificate_authority.internal.id
}
