# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
# OCI ELZ Landing Zone V1 - aligned to terraform-oci-core-landingzone

# --- Compartment name overrides (optional) ---
variable "custom_enclosing_compartment_name"  { default = null }
variable "custom_nw_compartment_name"         { default = null }
variable "custom_sec_compartment_name"        { default = null }
variable "custom_soc_compartment_name"        { default = null }
variable "custom_ops_compartment_name"        { default = null }
variable "custom_csvcs_compartment_name"      { default = null }
variable "custom_devt_csvcs_compartment_name" { default = null }
variable "custom_os_nw_compartment_name"      { default = null }
variable "custom_ss_nw_compartment_name"      { default = null }
variable "custom_ts_nw_compartment_name"      { default = null }
variable "custom_devt_nw_compartment_name"    { default = null }

# =============================================================================
# Manual Compartment OCIDs — SIM compartments created in OCI Console
# Set these in terraform.tfvars before running Sprint 4 apply.
# Team 4 creates these manually on Sprint 1 Day 1 and records the OCIDs.
# =============================================================================

variable "sim_ext_compartment_id" {
  description = "OCID of star-sim-ext-cmp — created manually in OCI Console by Team 4 (Sprint 1 Day 1). Required before Sprint 4 apply."
  type        = string
  default     = ""
  validation {
    condition     = var.sim_ext_compartment_id == "" || can(regex("^ocid1\\.compartment\\.", var.sim_ext_compartment_id))
    error_message = "sim_ext_compartment_id must be a valid OCI compartment OCID (ocid1.compartment...) or empty string."
  }
}

variable "sim_child_compartment_id" {
  description = "OCID of star-sim-child-cmp — created manually in OCI Console by Team 4 (Sprint 1 Day 1). Required before Sprint 4 apply."
  type        = string
  default     = ""
  validation {
    condition     = var.sim_child_compartment_id == "" || can(regex("^ocid1\\.compartment\\.", var.sim_child_compartment_id))
    error_message = "sim_child_compartment_id must be a valid OCI compartment OCID (ocid1.compartment...) or empty string."
  }
}
