# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# STAR ELZ V1 — sprint2

# =============================================================================
# AUTHENTICATION — OCI Provider credentials
# ORM (Resource Manager): leave all blank — ORM injects instance principal.
# CLI / Cloud Shell: set in terraform.tfvars or environment variables.
# =============================================================================
variable "tenancy_ocid" {
  description = "The OCID of the tenancy. Found at: OCI Console → Profile → Tenancy."
  type        = string
}

variable "user_ocid" {
  description = "API-signing user OCID. Leave blank when using ORM or instance principal."
  type        = string
  default     = ""
}

variable "fingerprint" {
  description = "Fingerprint of the API public key. Leave blank when using ORM."
  type        = string
  default     = ""
}

variable "private_key_path" {
  description = "Path to the API private key PEM file. Leave blank when using ORM."
  type        = string
  default     = ""
}

variable "private_key_password" {
  description = "Passphrase for the API private key (if encrypted). Leave blank when using ORM."
  type        = string
  default     = ""
  sensitive   = true
}

# =============================================================================
# REGION
# =============================================================================
variable "region" {
  description = "OCI region identifier where networking resources are deployed, e.g. ap-singapore-2."
  type        = string
  validation {
    condition     = length(var.region) > 0
    error_message = "region must not be empty."
  }
}

# =============================================================================
# LANDING ZONE IDENTITY
# service_label used in tags and descriptions only — NOT in resource names.
# =============================================================================
variable "service_label" {
  description = <<-EOT
    Short identifier for this landing zone instance. Used in tags and descriptions only.
    Max 8 chars, uppercase letters and digits, must start with a letter. Example: C1
    NOTE: Resource names use canonical constants in locals.tf — they do NOT change
    when service_label changes.
  EOT
  type        = string
  default     = "C1"
  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{0,7}$", var.service_label))
    error_message = "service_label must be 1-8 uppercase alphanumeric characters starting with a letter."
  }
}

variable "cis_level" {
  description = "CIS OCI Foundations Benchmark level. '1' = baseline. '2' = security-critical."
  type        = string
  default     = "1"
  validation {
    condition     = contains(["1", "2"], var.cis_level)
    error_message = "cis_level must be '1' or '2'."
  }
}

# =============================================================================
# TAGGING INPUTS
# =============================================================================
variable "lz_environment" {
  description = "Deployment environment for the Environment defined tag."
  type        = string
  default     = "poc"
  validation {
    condition     = contains(["poc", "dev", "uat", "prod"], var.lz_environment)
    error_message = "lz_environment must be one of: poc, dev, uat, prod."
  }
}

variable "lz_cost_center" {
  description = "Cost center code for the CostCenter defined tag."
  type        = string
  default     = "STAR-ELZ-V1"
  validation {
    condition     = length(var.lz_cost_center) > 0 && length(var.lz_cost_center) <= 32
    error_message = "lz_cost_center must be 1-32 characters."
  }
}
