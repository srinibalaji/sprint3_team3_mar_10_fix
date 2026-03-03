# ─────────────────────────────────────────────────────────────
# STAR ELZ V1 — Sprint 3 — sec_team2.tf (T2)
#
# T2 owns: Bastion session for TS spoke validation
#
# Same pattern as T1. Session targets the TS Sim FW instance
# for TC-22 (forced inspection traceroute) and TC-27 validation.
# ─────────────────────────────────────────────────────────────

resource "oci_bastion_session" "ts_ssh" {
  bastion_id = var.bastion_id

  key_details {
    public_key_content = var.ssh_public_key
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = var.ts_fw_instance_id
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
  }

  display_name           = local.bastion_session_ts_name
  session_ttl_in_seconds = 1800

  lifecycle {
    ignore_changes = [session_ttl_in_seconds]
  }
}
