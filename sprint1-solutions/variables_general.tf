# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# OCI ELZ Landing Zone V1 - aligned to terraform-oci-core-landingzone

variable "tenancy_ocid" {}
variable "user_ocid"           { default = "" }
variable "fingerprint"         { default = "" }
variable "private_key_path"    { default = "" }
variable "private_key_password"{ default = "" }

variable "region" {
  description = "The OCI region where workload resources are deployed."
  type        = string
}

variable "service_label" {
  description = "A unique label prepended to all resources. Max 15 chars, alphanumeric, starts with a letter."
  type        = string
  validation {
    condition     = length(regexall("^[A-Za-z][A-Za-z0-9]{1,14}$", var.service_label)) > 0
    error_message = "service_label must be alphanumeric, start with a letter, max 15 chars."
  }
}

variable "cis_level" {
  description = "CIS OCI Benchmark Level. '1' = practical. '2' = security-critical (enables Vault, bucket encryption, Security Zones)."
  type        = string
  default     = "1"
  validation {
    condition     = contains(["1", "2"], var.cis_level)
    error_message = "cis_level must be '1' or '2'."
  }
}

variable "display_output" {
  description = "Whether to display resource OCIDs and names in Terraform output."
  type        = bool
  default     = true
}

variable "lz_provenant_label" {
  description = "Human-readable label used in resource descriptions."
  type        = string
  default     = "ELZ Landing Zone"
}
