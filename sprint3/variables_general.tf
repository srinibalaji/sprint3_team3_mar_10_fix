# ─────────────────────────────────────────────────────────────
# STAR ELZ V1 — Sprint 3 — General Variables
# Same as Sprint 1/2. ORM populates from stack configuration.
# ─────────────────────────────────────────────────────────────

variable "tenancy_ocid" {
  description = "Tenancy OCID"
  type        = string
}

variable "region" {
  description = "Workload region (ap-singapore-2)"
  type        = string
  default     = "ap-singapore-2"
}

variable "home_region" {
  description = "Home region for IAM operations"
  type        = string
  default     = "ap-singapore-2"
}

variable "service_label" {
  description = "Service label — used in tags and descriptions only, never in resource names"
  type        = string
  default     = "star"
}

variable "ssh_public_key" {
  description = "SSH public key for Bastion sessions and compute access"
  type        = string
}
