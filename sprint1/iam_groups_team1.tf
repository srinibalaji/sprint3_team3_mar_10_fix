# =============================================================================
# STAR ELZ V1 — IAM Groups — TEAM 1 OWNED FILE
# Team 1 domain: Hub Network + Security
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-groups-team1
# =============================================================================
# YOUR TASK:
#   Define local.team1_groups — a map with 2 entries:
#     1. NW-ADMIN-GROUP  → star-ug-elz-nw
#     2. SEC-ADMIN-GROUP → star-ug-elz-sec
#
# PATTERN:
#   locals {
#     team1_groups = {
#       (local.<key>) : {
#         name          : local.provided_<name>,
#         description   : "...",
#         defined_tags  : local.groups_defined_tags,
#         freeform_tags : local.groups_freeform_tags
#       }
#     }
#   }
#
# KEYS  → local.nw_admin_group_key,  local.sec_admin_group_key
# NAMES → local.provided_nw_admin_group_name, local.provided_sec_admin_group_name
# Both defined in iam_groups.tf — do NOT redefine here.
# =============================================================================

# TODO: write local.team1_groups below this line
