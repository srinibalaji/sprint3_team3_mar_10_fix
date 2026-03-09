# ─────────────────────────────────────────────────────────────
# STAR ELZ V1 — Sprint 3 — sec_team4.tf (T4)
#
# T4 owns: DRG route tables, forced inspection routing,
#          Service Gateway, Hub FW return path.
#
# What this file creates:
#   1. Custom DRG Route Table — Hub (import distribution)
#   2. DRG Import Route Distribution + statement
#   3. Custom DRG Route Table — Spoke (static 0/0 → Hub)
#   4. Static route rule on Spoke DRG RT
#   5. VCN Ingress Route Table on Hub DRG attachment
#   6. Hub FW Subnet RT update (spoke CIDRs → DRG return path)
#   7. (Removed — Sprint 2 owns Service Gateway)
#   7. SGW route rule on Hub FW RT (uses Sprint 2 SGW via oci_core_service_gateway.hub.id)
#
# What this file modifies (in Sprint 2 state — see note below):
#   - 4 spoke DRG attachments: drg_route_table_id → spoke_to_hub
#   - Hub DRG attachment: drg_route_table_id → hub_spoke_mesh
# ─────────────────────────────────────────────────────────────

# ═══════════════════════════════════════════════════════════════
# 1. CUSTOM DRG ROUTE TABLE — HUB (dynamic import distribution)
# ═══════════════════════════════════════════════════════════════
# This RT replaces the auto-generated DRG RT on the Hub VCN attachment.
# It uses an import distribution to dynamically learn all VCN CIDRs
# from spoke attachments. The Hub DRG RT knows how to reach every spoke.

resource "oci_core_drg_route_table" "hub_spoke_mesh" {
  drg_id                           = var.hub_drg_id
  display_name                     = local.hub_spoke_mesh_drgrt_name
  import_drg_route_distribution_id = oci_core_drg_route_distribution.hub_vcn_import.id

  defined_tags = local.common_tags
}

# ═══════════════════════════════════════════════════════════════
# 2. DRG IMPORT ROUTE DISTRIBUTION
# ═══════════════════════════════════════════════════════════════
# Accepts routes from all VCN-type attachments.
# Hub DRG RT uses this to learn 10.1/24, 10.2/24, 10.3/24, 10.4/24
# automatically. No manual route entries needed for spoke CIDRs.

resource "oci_core_drg_route_distribution" "hub_vcn_import" {
  drg_id            = var.hub_drg_id
  display_name      = local.hub_import_dist_name
  distribution_type = "IMPORT"
}

resource "oci_core_drg_route_distribution_statement" "accept_all_vcn" {
  drg_route_distribution_id = oci_core_drg_route_distribution.hub_vcn_import.id
  action                    = "ACCEPT"
  priority                  = 1

  match_criteria {
    match_type      = "DRG_ATTACHMENT_TYPE"
    attachment_type = "VCN"
  }
}

# ═══════════════════════════════════════════════════════════════
# 3. CUSTOM DRG ROUTE TABLE — SPOKE (static route to Hub)
# ═══════════════════════════════════════════════════════════════
# All 4 spoke attachments (OS, TS, SS, DEVT) use this RT.
# No import distribution — inductive design (deny all, allow explicit).
# The single static route forces ALL spoke egress traffic to the
# Hub VCN attachment, where the VCN ingress RT steers it to the FW.

resource "oci_core_drg_route_table" "spoke_to_hub" {
  drg_id       = var.hub_drg_id
  display_name = local.spoke_to_hub_drgrt_name
  # No import_drg_route_distribution_id — static routes only (inductive)

  defined_tags = local.common_tags
}

# ═══════════════════════════════════════════════════════════════
# 4. STATIC ROUTE — 0/0 → HUB VCN ATTACHMENT
# ═══════════════════════════════════════════════════════════════
# This is the single rule that breaks full-mesh and forces inspection.
# When OS sends a packet to 10.3.0.5 (TS), the spoke DRG RT matches
# 0.0.0.0/0 and forwards to the Hub VCN attachment — not directly to TS.

resource "oci_core_drg_route_table_route_rule" "force_hub" {
  drg_route_table_id         = oci_core_drg_route_table.spoke_to_hub.id
  destination_type           = "CIDR_BLOCK"
  destination                = "0.0.0.0/0"
  next_hop_drg_attachment_id = var.hub_drg_attachment_id
}

# ═══════════════════════════════════════════════════════════════
# 5. VCN INGRESS ROUTE TABLE — on Hub DRG attachment
# ═══════════════════════════════════════════════════════════════
# When traffic arrives at Hub VCN via DRG, this RT steers it to the
# Hub Sim FW VNIC for inspection. Without this, traffic would go to
# the Hub VCN's default subnet RT and never hit the firewall.
#
# This is a VCN route table (oci_core_route_table) but attached to
# the DRG attachment's network_details.route_table_id — NOT a subnet.
# See DRG Routing Guide Section 1: "Three Route Table Types".

resource "oci_core_route_table" "hub_ingress" {
  compartment_id = var.nw_compartment_id
  vcn_id         = var.hub_vcn_id
  display_name   = local.hub_ingress_rt_name

  # All spoke traffic → Hub Sim FW private IP OCID for inspection
  route_rules {
    network_entity_id = var.hub_fw_private_ip_id
    destination       = "10.0.0.0/8"
    destination_type  = "CIDR_BLOCK"
    description       = "All spoke traffic → Hub Sim FW for inspection"
  }

  defined_tags = local.common_tags
}

# ═══════════════════════════════════════════════════════════════
# 6. HUB FW SUBNET ROUTE TABLE — return path after inspection
# ═══════════════════════════════════════════════════════════════
# After the Hub Sim FW inspects and forwards a packet, it exits the
# FW subnet. This RT sends inspected traffic back to the DRG, which
# uses the Hub DRG RT (import distribution) to reach the destination spoke.
#
# IMPORTANT: rt_r_elz_nw_fw was created in Sprint 2 state.
# We import it into Sprint 3 state so we can add spoke CIDR rules
# and the Service Gateway route. The import block (below) brings it
# under Sprint 3 management. After import, terraform plan will show
# the added routes as changes — this is expected.


# ═══════════════════════════════════════════════════════════════
# SERVICE GATEWAY — Hub VCN only (centralised Oracle service access)
# ═══════════════════════════════════════════════════════════════
# Spokes do NOT get their own SGW — all Oracle service traffic routes
# via DRG → Hub FW → SGW. Defence architecture: all traffic inspectable.
# Required for: Vault, Object Storage, OCI Logging, OCI APIs.

resource "oci_core_service_gateway" "hub" {
  compartment_id = var.nw_compartment_id
  vcn_id         = var.hub_vcn_id
  display_name   = "sgw_r_elz_nw_hub"

  services {
    service_id = data.oci_core_services.all_oci_services.services[0].id
  }

  defined_tags = local.common_tags
}

import {
  to = oci_core_route_table.hub_fw
  id = var.hub_fw_rt_id
}

resource "oci_core_route_table" "hub_fw" {
  compartment_id = var.nw_compartment_id
  vcn_id         = var.hub_vcn_id
  display_name   = "rt_r_elz_nw_fw"

  # Spoke CIDRs → DRG (return path after firewall inspection)
  route_rules {
    network_entity_id = var.hub_drg_id
    destination       = var.os_app_subnet_cidr
    destination_type  = "CIDR_BLOCK"
    description       = "OS spoke → DRG (post-inspection)"
  }

  route_rules {
    network_entity_id = var.hub_drg_id
    destination       = var.ss_app_subnet_cidr
    destination_type  = "CIDR_BLOCK"
    description       = "SS spoke → DRG (post-inspection)"
  }

  route_rules {
    network_entity_id = var.hub_drg_id
    destination       = var.ts_app_subnet_cidr
    destination_type  = "CIDR_BLOCK"
    description       = "TS spoke → DRG (post-inspection)"
  }

  route_rules {
    network_entity_id = var.hub_drg_id
    destination       = var.devt_app_subnet_cidr
    destination_type  = "CIDR_BLOCK"
    description       = "DEVT spoke → DRG (post-inspection)"
  }

  # Service Gateway — Oracle services via private backbone
  route_rules {
    network_entity_id = oci_core_service_gateway.hub.id
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    description       = "Oracle services → Service Gateway (private backbone)"
  }

  defined_tags = local.common_tags
}

# ═══════════════════════════════════════════════════════════════
# 8. DRG ATTACHMENT REASSIGNMENT
# ═══════════════════════════════════════════════════════════════
# The 5 DRG attachments exist in Sprint 2 state. Sprint 3 needs to:
#   - Assign spoke_to_hub DRG RT to OS/TS/SS/DEVT attachments
#   - Assign hub_spoke_mesh DRG RT to Hub attachment
#   - Attach hub_ingress RT to Hub attachment network_details
#
# APPROACH: Use oci_core_drg_attachment_management to update existing
# attachments without importing them from Sprint 2 state.
# This resource manages the DRG-side properties of an existing attachment.

resource "oci_core_drg_attachment_management" "hub" {
  attachment_type        = "VIRTUAL_CIRCUIT"
  compartment_id         = var.nw_compartment_id
  drg_id                 = var.hub_drg_id
  drg_route_table_id     = oci_core_drg_route_table.hub_spoke_mesh.id
  display_name           = "drga_r_elz_nw_hub"
  vcn_id                 = var.hub_vcn_id

  network_details {
    id             = var.hub_vcn_id
    type           = "VCN"
    route_table_id = oci_core_route_table.hub_ingress.id
  }
}

resource "oci_core_drg_attachment_management" "os" {
  attachment_type        = "VIRTUAL_CIRCUIT"
  compartment_id         = var.os_compartment_id
  drg_id                 = var.hub_drg_id
  drg_route_table_id     = oci_core_drg_route_table.spoke_to_hub.id
  display_name           = "drga_os_elz_nw"
  vcn_id                 = var.os_vcn_id

  network_details {
    id   = var.os_vcn_id
    type = "VIRTUAL_CIRCUIT"
  }
}

resource "oci_core_drg_attachment_management" "ts" {
  attachment_type        = "VIRTUAL_CIRCUIT"
  compartment_id         = var.ts_compartment_id
  drg_id                 = var.hub_drg_id
  drg_route_table_id     = oci_core_drg_route_table.spoke_to_hub.id
  display_name           = "drga_ts_elz_nw"
  vcn_id                 = var.ts_vcn_id

  network_details {
    id   = var.ts_vcn_id
    type = "VIRTUAL_CIRCUIT"
  }
}

resource "oci_core_drg_attachment_management" "ss" {
  attachment_type        = "VIRTUAL_CIRCUIT"
  compartment_id         = var.ss_compartment_id
  drg_id                 = var.hub_drg_id
  drg_route_table_id     = oci_core_drg_route_table.spoke_to_hub.id
  display_name           = "drga_ss_elz_nw"
  vcn_id                 = var.ss_vcn_id

  network_details {
    id   = var.ss_vcn_id
    type = "VIRTUAL_CIRCUIT"
  }
}

resource "oci_core_drg_attachment_management" "devt" {
  attachment_type        = "VIRTUAL_CIRCUIT"
  compartment_id         = var.devt_compartment_id
  drg_id                 = var.hub_drg_id
  drg_route_table_id     = oci_core_drg_route_table.spoke_to_hub.id
  display_name           = "drga_devt_elz_nw"
  vcn_id                 = var.devt_vcn_id

  network_details {
    id   = var.devt_vcn_id
    type = "VIRTUAL_CIRCUIT"
  }
}
