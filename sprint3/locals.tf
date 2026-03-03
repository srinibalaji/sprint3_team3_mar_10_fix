# ─────────────────────────────────────────────────────────────
# STAR ELZ V1 — Sprint 3 — locals.tf
# Single source of truth for all Sprint 3 display names.
# Pattern: same as Sprint 1 (IAM) and Sprint 2 (networking).
# Rule: team files reference local.* only — never hardcode strings.
# ─────────────────────────────────────────────────────────────

locals {
  # ── Tag namespace (from Sprint 1 — C0 = tenancy root) ──
  tag_namespace_name = "C0-star-elz-v1"

  # ── Common tags (applied to all Sprint 3 resources) ──
  common_tags = {
    "${local.tag_namespace_name}.Environment" = "dev"
    "${local.tag_namespace_name}.Owner"       = "DSTA"
    "${local.tag_namespace_name}.Sprint"      = "3"
  }

  # ── Forced Inspection — Custom DRG Route Tables (T4) ──
  hub_spoke_mesh_drgrt_name = "drgrt_r_hub_spoke_mesh"  # Hub attachment — import distribution
  spoke_to_hub_drgrt_name   = "drgrt_spoke_to_hub"      # Spoke attachments — static 0/0 → Hub
  hub_import_dist_name      = "drgrd_r_hub_vcn_import"  # Import distribution — auto-learn VCN CIDRs
  hub_ingress_rt_name       = "rt_r_elz_nw_hub_ingress" # VCN ingress RT on Hub DRG attachment

  # ── Service Gateway (T4) ──
  hub_service_gw_name = "sgw_r_elz_nw_hub" # Hub VCN — centralised Oracle service access

  # ── Logging (T3) ──
  nw_log_group_name      = "lg_r_elz_nw_flow"
  hub_fw_flow_log_name   = "fl_r_elz_nw_fw"
  hub_mgmt_flow_log_name = "fl_r_elz_nw_mgmt"
  os_app_flow_log_name   = "fl_os_elz_nw_app"
  ts_app_flow_log_name   = "fl_ts_elz_nw_app"
  ss_app_flow_log_name   = "fl_ss_elz_nw_app"
  devt_app_flow_log_name = "fl_devt_elz_nw_app"

  # ── Object Storage (T3) ──
  log_bucket_name = "bkt_r_elz_sec_logs"

  # ── Events and Alarms (T3) ──
  notification_topic_name = "nt_r_elz_sec_alerts"
  events_rule_name        = "ev_r_elz_sec_nw_changes"
  drg_change_alarm_name   = "al_r_elz_sec_drg_change"

  # ── Bastion Sessions (T1, T2) ──
  bastion_session_os_name = "bsn_os_elz_nw_ssh"
  bastion_session_ts_name = "bsn_ts_elz_nw_ssh"
}
