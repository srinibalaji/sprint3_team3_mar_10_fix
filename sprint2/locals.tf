# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# STAR ELZ V1 — sprint2
# =============================================================================
# LOCALS — SINGLE SOURCE OF TRUTH
# All constants, derived values, CIDR plan, and phase gate defined here.
# Team files reference these locals directly — no magic strings in team code.
# =============================================================================

locals {

  # ---------------------------------------------------------------------------
  # REGION AND TENANCY — derived from data sources
  # FIX vs old scaffold: region_key uses data.oci_identity_regions lookup.
  # Old broken pattern: lower(replace(var.region, "-", ""))
  #   produced "apsingapore2" — wrong for service gateway CIDR construction.
  # Correct pattern produces "sin2" from the OCI canonical region key.
  # ---------------------------------------------------------------------------
  regions_map         = { for r in data.oci_identity_regions.these.regions : r.key => r.name }
  regions_map_reverse = { for r in data.oci_identity_regions.these.regions : r.name => r.key }
  home_region_key     = data.oci_identity_tenancy.this.home_region_key
  region_key          = lower(local.regions_map_reverse[var.region])
  tenancy_id          = data.oci_identity_tenancy.this.id

  # ---------------------------------------------------------------------------
  # AVAILABILITY DOMAIN — first AD in the region for compute and subnet resources
  # ---------------------------------------------------------------------------
  ad_name = data.oci_identity_availability_domains.these.availability_domains[0].name

  # ---------------------------------------------------------------------------
  # SERVICE GATEWAY CIDRs — used in route rules targeting service gateway
  # ---------------------------------------------------------------------------
  anywhere                    = "0.0.0.0/0"
  oci_services_cidr           = "all-${local.region_key}-services-in-oracle-services-network"
  oci_objectstorage_cidr      = "oci-${local.region_key}-objectstorage"
  valid_service_gateway_cidrs = [local.oci_services_cidr, local.oci_objectstorage_cidr]

  # ---------------------------------------------------------------------------
  # LANDING ZONE DESCRIPTION + TAGGING — consistent with sprint1
  # ---------------------------------------------------------------------------
  lz_description = "STAR ELZ V1 [${var.service_label}]"

  tag_namespace_name = "C0-star-elz-v1" # C0 = tenancy root, immutable once created

  # Layer 1 — freeform tags, no namespace dependency
  landing_zone_tags = {
    "oci-elz-landing-zone" = "${var.service_label}/v1"
    "managed-by"           = "terraform"
    "sprint"               = "sprint2-networking"
  }

  # Layer 2 — defined tags via C0 namespace
  # depends_on oci_identity_tag.cost_center required on resources using these
  lz_defined_tags = {
    "${local.tag_namespace_name}.Environment" = var.lz_environment
    "${local.tag_namespace_name}.Owner"       = var.service_label
    "${local.tag_namespace_name}.ManagedBy"   = "terraform"
    "${local.tag_namespace_name}.CostCenter"  = var.lz_cost_center
  }

  # ---------------------------------------------------------------------------
  # CANONICAL NETWORK RESOURCE NAMES
  # C1 naming convention — matches Sprint 1 compartment names exactly.
  # All uppercase. No service_label interpolation in resource names.
  # ---------------------------------------------------------------------------

  # VCN Names
  hub_vcn_name  = "VCN-C1-R-ELZ-NW-HUB"
  os_vcn_name   = "VCN-C1-OS-ELZ-NW"
  ts_vcn_name   = "VCN-C1-TS-ELZ-NW"
  ss_vcn_name   = "VCN-C1-SS-ELZ-NW"
  devt_vcn_name = "VCN-C1-DEVT-ELZ-NW"

  # Subnet Names
  hub_fw_subnet_name   = "SUB-C1-R-ELZ-NW-FW"
  hub_mgmt_subnet_name = "SUB-C1-R-ELZ-NW-MGMT"
  os_app_subnet_name   = "SUB-C1-OS-ELZ-NW-APP"
  ts_app_subnet_name   = "SUB-C1-TS-ELZ-NW-APP"
  ss_app_subnet_name   = "SUB-C1-SS-ELZ-NW-APP"
  devt_app_subnet_name = "SUB-C1-DEVT-ELZ-NW-APP"

  # DRG Names
  hub_drg_name    = "DRG-C1-R-ELZ-NW-HUB" # Primary hub DRG — all 5 VCN attachments
  ew_hub_drg_name = "DRG-C1-R-ELZ-NW-EW"  # Inter E-W DRG — V2 placeholder (0 attachments in V1)

  # Route Table Names
  hub_fw_rt_name   = "RT-C1-R-ELZ-NW-FW"
  hub_mgmt_rt_name = "RT-C1-R-ELZ-NW-MGMT"
  os_app_rt_name   = "RT-C1-OS-ELZ-NW-APP"
  ts_app_rt_name   = "RT-C1-TS-ELZ-NW-APP"
  ss_app_rt_name   = "RT-C1-SS-ELZ-NW-APP"
  devt_app_rt_name = "RT-C1-DEVT-ELZ-NW-APP"

  # Sim Firewall Instance Names
  hub_fw_instance_name = "FW-C1-R-ELZ-NW-HUB-SIM"
  os_fw_instance_name  = "FW-C1-OS-ELZ-NW-SIM"
  ts_fw_instance_name  = "FW-C1-TS-ELZ-NW-SIM"
  ss_fw_instance_name  = "FW-C1-SS-ELZ-NW-SIM"

  # Bastion Name
  hub_bastion_name = "BAS-C1-R-ELZ-NW-HUB"

  # DRG Attachment Names
  hub_drg_attachment_name  = "DRGA-C1-R-ELZ-NW-HUB"
  os_drg_attachment_name   = "DRGA-C1-OS-ELZ-NW"
  ts_drg_attachment_name   = "DRGA-C1-TS-ELZ-NW"
  ss_drg_attachment_name   = "DRGA-C1-SS-ELZ-NW"
  devt_drg_attachment_name = "DRGA-C1-DEVT-ELZ-NW"

  # ---------------------------------------------------------------------------
  # DNS LABELS — single source of truth (OCI VCN/subnet dns_label constraints:
  # max 15 chars, alphanumeric only, no hyphens or underscores)
  # Referenced in team files — never hardcode dns_label strings in team files.
  # ---------------------------------------------------------------------------
  hub_vcn_dns_label  = "hubelznw"
  os_vcn_dns_label   = "oselznw"
  ts_vcn_dns_label   = "tselznw"
  ss_vcn_dns_label   = "sselznw"
  devt_vcn_dns_label = "devtelznw"

  hub_fw_subnet_dns_label   = "hubfw"
  hub_mgmt_subnet_dns_label = "hubmgmt"
  os_app_subnet_dns_label   = "osapp"
  ts_app_subnet_dns_label   = "tsapp"
  ss_app_subnet_dns_label   = "ssapp"
  devt_app_subnet_dns_label = "devtapp"

  # ---------------------------------------------------------------------------
  # CIDR PLAN — single source of truth for all network ranges
  # Change CIDRs only here — never in team files directly.
  # Override via variables_net.tf if non-standard ranges needed.
  # ---------------------------------------------------------------------------

  # Hub VCN (C1_R_ELZ_NW) — /16 for room to grow
  hub_vcn_cidr         = var.hub_vcn_cidr         # default 10.0.0.0/16
  hub_fw_subnet_cidr   = var.hub_fw_subnet_cidr   # default 10.0.0.0/24 — FW/untrust
  hub_mgmt_subnet_cidr = var.hub_mgmt_subnet_cidr # default 10.0.1.0/24 — MGMT/bastion

  # Spoke VCNs — /24 each per STAR ELZ architecture (one subnet = entire VCN in V1).
  # Sprint 3+ adds subnets via OCI secondary VCN CIDR blocks (oci_core_vcn_add_vcn_cidr).
  # Spoke /24 VCNs are fully consumed in V1 — secondary CIDRs (e.g. 10.1.1.0/24) provide growth.
  os_vcn_cidr        = var.os_vcn_cidr        # default 10.1.0.0/24
  os_app_subnet_cidr = var.os_app_subnet_cidr # default 10.1.0.0/24

  ts_vcn_cidr        = var.ts_vcn_cidr        # default 10.3.0.0/24
  ts_app_subnet_cidr = var.ts_app_subnet_cidr # default 10.3.0.0/24

  ss_vcn_cidr        = var.ss_vcn_cidr        # default 10.2.0.0/24
  ss_app_subnet_cidr = var.ss_app_subnet_cidr # default 10.2.0.0/24

  devt_vcn_cidr        = var.devt_vcn_cidr        # default 10.4.0.0/24
  devt_app_subnet_cidr = var.devt_app_subnet_cidr # default 10.4.0.0/24

  # ---------------------------------------------------------------------------
  # TWO-PHASE APPLY GATE
  # ==========================================================================
  # Phase 1 — ALL TEAMS apply simultaneously (no hub_drg_id needed):
  #   T4: Hub VCN + FW subnet + MGMT subnet + DRG + IGW
  #   T1: OS VCN + OS app subnet
  #   T2: TS VCN + TS app subnet
  #   T3: SS VCN + SS app subnet + DEVT VCN + DEVT app subnet
  #
  # After Phase 1:
  #   T4 runs: terraform output hub_drg_id
  #   T4 shares the DRG OCID with T1, T2, T3
  #   All teams paste hub_drg_id into ORM Variables → re-apply
  #
  # Phase 2 — All teams apply with hub_drg_id set:
  #   All: DRG attachments + Route tables + Sim FW instances
  #   T4: + Bastion
  #
  # IMPLEMENTATION: phase2_enabled = true when hub_drg_id is not empty.
  # Phase 2 resources use count = local.phase2_enabled ? 1 : 0.
  # ---------------------------------------------------------------------------
  phase2_enabled = var.hub_drg_id != ""

  # ---------------------------------------------------------------------------
  # SIM FIREWALL — compute image (Sprint 2 Phase 2)
  # Latest Oracle Linux 8 image, resolved at plan time — no hardcoded OCID.
  # Image OCIDs are region-specific and rotate on patch releases.
  # ---------------------------------------------------------------------------
  sim_fw_image_id = data.oci_core_images.platform_oel8.images[0].id

  # Sim FW cloud-init — Oracle Linux 8 (E4.Flex primary NIC: eth0)
  # Enables persistent IP forwarding and NAT masquerade via iptables-services.
  # NOTE: firewalld is intentionally NOT used — it conflicts with iptables-services
  # on OL8 when both are active. iptables-services is the correct OL/RHEL approach.
  # OCI requirement: skip_source_dest_check = true must ALSO be set on the VNIC
  # (done in each team file) — cloud-init alone is insufficient for OCI forwarding.
  # SPRINT 3 NOTE: DNS label constants moved to locals.tf (dns_label block above).
  sim_fw_userdata = base64encode(<<-EOT
    #!/bin/bash
    # STAR ELZ V1 — Sim Firewall bootstrap (Oracle Linux 8 / E4.Flex)
    # Enables persistent IP forwarding and NAT masquerade for spoke routing simulation.

    # Step 1: Persist IP forwarding via sysctl.d (survives reboot)
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
    sysctl --system

    # Step 2: Install iptables-services (Oracle Linux / RHEL persistence layer)
    dnf -y install iptables-services

    # Step 3: Add NAT masquerade rule on primary interface
    # OCI E4.Flex: primary NIC is eth0. Adjust if using a different shape.
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    # Step 4: Persist iptables rules and enable service across reboots
    service iptables save
    systemctl enable --now iptables

    echo "Sim FW bootstrap complete $(date)" >> /var/log/star-elz-simfw-init.log
  EOT
  )
}
