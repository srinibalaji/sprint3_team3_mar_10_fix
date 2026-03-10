# ─────────────────────────────────────────────────────────────
# STAR ELZ V1 — Sprint 3 — sec_team1.tf (T1)
#
# T1 owns: Bastion session (OS), Hub FW + OS NSGs,
#          Flow logs (hub_fw + OS), VSS recipe + target,
#          Service Connector Hub (flow logs → bucket)
#
# Rebalanced from T3 to spread workload evenly.
# ─────────────────────────────────────────────────────────────
resource "oci_bastion_bastion" "os_spoke" {
  compartment_id               = var.os_compartment_id
  bastion_type                 = "STANDARD"
  name                         = local.os_spoke_bastion_name
  target_subnet_id             = var.os_app_subnet_id
  client_cidr_block_allow_list = [var.os_bastion_client_cidr]

  defined_tags = local.common_tags
}

# ═══════════════════════════════════════════════════════════════
# 1. BASTION SESSION — OS Sim FW
# ═══════════════════════════════════════════════════════════════

# resource "oci_bastion_session" "os_ssh" {
#   bastion_id = var.bastion_id

#   key_details {
#     public_key_content = var.ssh_public_key
#   }

#   target_resource_details {
#     session_type       = "PORT_FORWARDING"
#     target_resource_id = var.os_fw_instance_id
#     target_resource_port = 22
#   }

#   display_name           = local.bastion_session_os_name
#   session_ttl_in_seconds = 1800

#   lifecycle {
#     ignore_changes = [session_ttl_in_seconds]
#   }
# }

# ═══════════════════════════════════════════════════════════════
# 2. NSGs — Hub FW + OS spoke
# ═══════════════════════════════════════════════════════════════

resource "oci_core_network_security_group" "hub_fw" {
  compartment_id = var.nw_compartment_id
  vcn_id         = var.hub_vcn_id
  display_name   = local.hub_fw_nsg_name
  defined_tags   = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "hub_fw_ingress" {
  network_security_group_id = oci_core_network_security_group.hub_fw.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source                    = "10.0.0.0/8"
  source_type               = "CIDR_BLOCK"
  description               = "Allow all internal — Sprint 3 baseline (tighten in V2)"
}

resource "oci_core_network_security_group_security_rule" "hub_fw_egress" {
  network_security_group_id = oci_core_network_security_group.hub_fw.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Allow all egress"
}

resource "oci_core_network_security_group" "os_app" {
  compartment_id = var.os_compartment_id
  vcn_id         = var.os_vcn_id
  display_name   = local.os_app_nsg_name
  defined_tags   = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "os_ingress" {
  network_security_group_id = oci_core_network_security_group.os_app.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source                    = "10.0.0.0/8"
  source_type               = "CIDR_BLOCK"
  description               = "Allow all internal"
}

resource "oci_core_network_security_group_security_rule" "os_egress" {
  network_security_group_id = oci_core_network_security_group.os_app.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Allow all egress"
}

# ═══════════════════════════════════════════════════════════════
# 3. FLOW LOGS — Hub FW + OS subnet
# ═══════════════════════════════════════════════════════════════

resource "oci_logging_log" "hub_fw_flow" {
  display_name = local.hub_fw_flow_log_name
  log_group_id = oci_logging_log_group.nw_flow.id
  log_type     = "SERVICE"

  configuration {
    source {
      category    = "all"
      resource    = var.hub_fw_subnet_id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
    compartment_id = var.nw_compartment_id
  }

  is_enabled = true
}

resource "oci_logging_log" "os_app_flow" {
  display_name = local.os_app_flow_log_name
  log_group_id = oci_logging_log_group.nw_flow.id
  log_type     = "SERVICE"

  configuration {
    source {
      category    = "all"
      resource    = var.os_app_subnet_id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
    compartment_id = var.os_compartment_id
  }

  is_enabled = true
}

# ═══════════════════════════════════════════════════════════════
# 4. VSS — Vulnerability Scanning Service
# ═══════════════════════════════════════════════════════════════

resource "oci_vulnerability_scanning_host_scan_recipe" "standard" {
  count          = var.enable_vss ? 1 : 0
  compartment_id = var.sec_compartment_id
  display_name   = local.vss_recipe_name

  port_settings {
    scan_level = "STANDARD"
  }

  agent_settings {
    scan_level = "STANDARD"

    agent_configuration {
      vendor = "OCI"
    }
  }

  schedule {
    type        = "WEEKLY"
    day_of_week = "SUNDAY"
  }

  defined_tags = local.common_tags
}

resource "oci_vulnerability_scanning_host_scan_target" "nw_instances" {
  count                 = var.enable_vss ? 1 : 0
  compartment_id        = var.sec_compartment_id
  host_scan_recipe_id   = oci_vulnerability_scanning_host_scan_recipe.standard[0].id
  display_name          = local.vss_target_name
  target_compartment_id = var.nw_compartment_id

  defined_tags = local.common_tags
}

# ═══════════════════════════════════════════════════════════════
# 5. SERVICE CONNECTOR HUB — Flow logs → Object Storage bucket
# ═══════════════════════════════════════════════════════════════

#Note that while log group oci_logging_log_group.nw_flow exists, but no logs have been ingested yet, SCH cannot read it → "Invalid query. 
#No log sources found to be read". Once flow logs are active and have ingested at least one log entry, SCH can read from the log group and archive to the bucket as expected.


resource "oci_sch_service_connector" "flow_to_bucket" {
  compartment_id = var.sec_compartment_id
  display_name   = local.sch_flow_to_bucket_name

  source {
    kind = "logging"

    log_sources {
      compartment_id = var.sec_compartment_id
      log_group_id   = oci_logging_log_group.nw_flow.id
    }
  }

  target {
    kind                       = "objectStorage"
    bucket                     = oci_objectstorage_bucket.logs.name
    namespace                  = data.oci_objectstorage_namespace.ns.namespace
    object_name_prefix         = "flow-logs/"
  }

  defined_tags = local.common_tags
}
