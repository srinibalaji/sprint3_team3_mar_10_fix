# =============================================================================
# STAR ELZ V1 — Sprint 2: Hub Networking
# General Variables
# =============================================================================

variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy root compartment."
  type        = string
}

variable "region" {
  description = "OCI region. Must be ap-singapore-2 for STAR ELZ."
  type        = string
}

variable "service_label" {
  description = "Short label for resource names. Max 15 chars, starts with letter."
  type        = string
  validation {
    condition     = length(regexall("^[A-Za-z][A-Za-z0-9]{1,14}$", var.service_label)) > 0
    error_message = "service_label must be alphanumeric, start with a letter, max 15 chars."
  }
}

variable "cis_level" {
  description = "CIS OCI Benchmark Level. '1' = standard. '2' = security-critical."
  type        = string
  default     = "1"
}
