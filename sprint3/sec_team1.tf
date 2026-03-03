# ─────────────────────────────────────────────────────────────
# STAR ELZ V1 — Sprint 3 — sec_team1.tf (T1)
#
# T1 owns: Bastion session for OS spoke validation
#
# The Bastion service (bas_r_elz_nw_hub) was created in Sprint 2
# by T4 in nw_team4.tf. T1 creates a session to SSH into the
# OS Sim FW instance for TC-22 (forced inspection traceroute).
#
# NOTE: Bastion sessions are ephemeral — TTL defaults to 30 min.
# After expiry, Terraform will show drift. This is expected.
# Recreate the session for subsequent validation runs.
# ─────────────────────────────────────────────────────────────

resource "oci_bastion_session" "os_ssh" {
  bastion_id = var.bastion_id

  key_details {
    public_key_content = var.ssh_public_key
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = var.os_fw_instance_id
    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
  }

  display_name           = local.bastion_session_os_name
  session_ttl_in_seconds = 1800 # 30 minutes

  # Session expires naturally — don't fight drift on TTL
  lifecycle {
    ignore_changes = [session_ttl_in_seconds]
  }
}
