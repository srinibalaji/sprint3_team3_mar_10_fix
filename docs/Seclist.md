In locals.tf — add these 6 name constants (you do this before the session):
hcl# Security Lists — Sprint 2 validation (Sprint 3 replaces with NSGs)
hub_fw_seclist_name   = "sl_r_elz_nw_fw"
hub_mgmt_seclist_name = "sl_r_elz_nw_mgmt"
os_app_seclist_name   = "sl_os_elz_nw_app"
ts_app_seclist_name   = "sl_ts_elz_nw_app"
ss_app_seclist_name   = "sl_ss_elz_nw_app"
devt_app_seclist_name = "sl_devt_elz_nw_app"
Each team adds to their file:
T1 — nw_team1.tf (after the subnet block):
hclresource "oci_core_security_list" "os_app" {
  compartment_id = var.os_compartment_id
  vcn_id         = oci_core_vcn.os.id
  display_name   = local.os_app_seclist_name

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }

  ingress_security_rules {
    protocol  = "all"
    source    = "10.0.0.0/8"
    stateless = false
  }
}
Then add one line to their existing subnet:
hclsecurity_list_ids = [oci_core_security_list.os_app.id]
T2 — nw_team2.tf: Same pattern, replace os with ts, use var.ts_compartment_id, oci_core_vcn.ts.id, local.ts_app_seclist_name.
T3 — nw_team3.tf: Two security lists — one for SS (ss_app), one for DEVT (devt_app). Same pattern each.
T4 — nw_team4.tf: Two security lists — one for Hub FW (hub_fw), one for Hub MGMT (hub_mgmt). Both use var.nw_compartment_id and oci_core_vcn.hub.id.
That's it. Each team writes one block (T3 and T4 write two), adds one line to their subnet. Same pattern, same rules, different names.
