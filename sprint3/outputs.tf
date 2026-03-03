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
output "hub_service_gw_id" {
  description = "OCID of sgw_r_elz_nw_hub Service Gateway"
  value       = oci_core_service_gateway.hub.id
}

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
