# =============================================================================
# STAR ELZ V1 — Sprint 2: Hub Networking
# Network Variables — Hub VCN, DRG, Subnets
#
# Team 1 (NW) owns this file.
# All CIDR values follow the STAR ELZ V1 IP Plan.
# Do NOT change CIDRs without updating the IP Plan in the State Book.
# =============================================================================

# ---------------------------------------------------------------------------
# Compartment OCIDs — from Sprint 1 outputs
# Paste values from sprint1_outputs.json
# ---------------------------------------------------------------------------

variable "nw_compartment_id" {
  description = "OCID of C1_R_ELZ_NW — hub network compartment from Sprint 1."
  type        = string
  default     = ""
  # TODO Sprint 2: paste OCID from sprint1_outputs.json
}

variable "sec_compartment_id" {
  description = "OCID of C1_R_ELZ_SEC — security compartment from Sprint 1."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Hub VCN
# ---------------------------------------------------------------------------

variable "hub_vcn_cidr" {
  description = "CIDR block for the Hub VCN."
  type        = string
  default     = "10.0.0.0/16"
}

variable "hub_vcn_name" {
  description = "Display name for the Hub VCN."
  type        = string
  default     = "C1-R-ELZ-Hub-VCN"
}

# ---------------------------------------------------------------------------
# Hub Subnets
# ---------------------------------------------------------------------------

variable "hub_fw_subnet_cidr" {
  description = "CIDR for the Sim Firewall subnet (dummy IP forwarding compute)."
  type        = string
  default     = "10.0.0.0/24"
}

variable "hub_mgmt_subnet_cidr" {
  description = "CIDR for the management/bastion subnet."
  type        = string
  default     = "10.0.1.0/24"
}

# ---------------------------------------------------------------------------
# DRG
# ---------------------------------------------------------------------------

variable "drg_name" {
  description = "Display name for the hub DRG."
  type        = string
  default     = "C1-R-ELZ-DRG"
}

# ---------------------------------------------------------------------------
# Sim Firewall Compute (Task 5 & 6 — Team 4 + Oracle)
# ---------------------------------------------------------------------------

variable "sim_fw_shape" {
  description = "Compute shape for the dummy firewall instance."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "sim_fw_ocpus" {
  description = "OCPUs for the sim firewall instance."
  type        = number
  default     = 1
}

variable "sim_fw_memory_gb" {
  description = "Memory in GB for the sim firewall instance."
  type        = number
  default     = 8
}
