# =============================================================================
# STAR ELZ V1 — IAM Groups — TEAM 4 OWNED FILE
# Team 4 domain: Agency Spoke Networks
# Sprint 1, Week 2 — Day 3
# Branch: sprint1/iam-groups-team4
# =============================================================================
# YOUR TASK:
#   Define local.team4_groups — a map with 4 entries:
#     7.  OS-NW-ADMIN-GROUP   → star-ug-os-elz-nw
#     8.  SS-NW-ADMIN-GROUP   → star-ug-ss-elz-nw
#     9.  TS-NW-ADMIN-GROUP   → star-ug-ts-elz-nw
#     10. DEVT-NW-ADMIN-GROUP → star-ug-devt-elz-nw
#
# KEYS  → local.os_nw_admin_group_key, local.ss_nw_admin_group_key,
#          local.ts_nw_admin_group_key, local.devt_nw_admin_group_key
# NAMES → local.provided_os_nw_admin_group_name, etc.
# CRITICAL: DEVT group must NOT appear in any SEC compartment policy (TC-03)
# =============================================================================

# TODO: write local.team4_groups below this line
locals {
    team4_groups {
        (local.os_nw_admin_group_key):{
            name           = local.provided_os_nw_admin_group_name
            description    = "OS Spoke Network Admin — manage all C1_OS_ELZ_NW resources"
        }, 
        (local.ss_nw_admin_group_key):{
            name           = local.provided_ss_nw_admin_group_name
            description    = "SS Spoke Network Admin — manage all C1_SS_ELZ_NW resources"
        },
        (ocal.ts_nw_admin_group_key):{
            name           = local.provided_ts_nw_admin_group_name
            description    = "TS Spoke Network Admin — manage all C1_TS_ELZ_NW resources"
        },
        (local.devt_nw_admin_group_key):{
            name           = local.provided_devt_nw_admin_group_name
            description    = "DEVT Spoke Network Admin — manage all C1_DEVT_ELZ_NW resources"
        }
    }
}