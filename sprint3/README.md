# STAR ELZ V1 — Sprint 3

**Dates:** 9–10 March 2026 | **Module:** Security, Observability, Forced Inspection
**Prerequisite:** Sprint 1 (IAM) ✅ | Sprint 2 (Networking) ✅ | Sprint 1 IAM Patch ⚡ (see Deployment)
**Deployment:** Sprint 1 re-apply (IAM patch) → Sprint 3 ORM single Plan → Apply

---

## What Sprint 3 Does

Sprint 2 built the roads (5 VCNs, DRG full-mesh, Sim FWs, Bastion, 6 security lists). Traffic flows spoke → DRG → spoke direct — no inspection.

Sprint 3 adds forced inspection, security services, and observability:

**Forced inspection (T4):** Custom DRG route tables replace auto-generated. Spoke DRG RT has static 0/0 → Hub VCN attachment. VCN ingress RT steers traffic to Hub Sim FW VNIC. Hub FW subnet RT returns inspected traffic to DRG. Service Gateway centralises Oracle service access on Hub VCN.

**Security services (T3):** OCI Vault (KMS) with AES-256 HSM master key. Cloud Guard detector/responder recipes (cloned from Oracle-managed). Cloud Guard target on tenancy root. Security Zones on C1_R_ELZ_SEC (encryption policies) and C1_R_ELZ_NW (network isolation).

**Observability (T3):** VCN flow logs on all 6 subnets. Object Storage bucket for log retention. Events rule on DRG/routing changes. Monitoring alarm on Hub FW subnet drops.

**Bastion sessions (T1, T2):** SSH sessions to OS and TS Sim FWs for TC-22 forced inspection traceroute validation.

**After apply:** OS → DRG → Hub FW → inspect → DRG → TS. Flow logs prove it. Security Zones prevent insecure resource creation. Cloud Guard monitors continuously.

---

## Issue List

| # | Task | Status | Team | Start | End | Days |
|---|---|---|---|---|---|---|
| S3-T4-01 | Custom DRG route tables (replace auto-generated) | New | T4 | 3/9 | 3/9 | 1 |
| S3-T4-02 | DRG route distribution (import policy) | New | T4 | 3/9 | 3/9 | 1 |
| S3-T4-03 | Spoke DRG RT with static route to Hub | New | T4 | 3/9 | 3/9 | 1 |
| S3-T4-04 | VCN ingress route table on Hub DRG attachment | New | T4 | 3/9 | 3/9 | 1 |
| S3-T4-05 | Hub FW subnet RT update (spoke CIDRs + SG route) | New | T4 | 3/9 | 3/9 | 1 |
| S3-T4-06 | Service Gateway on Hub VCN | New | T4 | 3/9 | 3/9 | 1 |
| S3-T1-01 | Bastion session — OS spoke | New | T1 | 3/9 | 3/9 | 1 |
| S3-T2-01 | Bastion session — TS spoke | New | T2 | 3/9 | 3/9 | 1 |
| S3-T3-01 | OCI Logging — log group + 6 VCN flow logs | New | T3 | 3/9 | 3/10 | 2 |
| S3-T3-02 | Object Storage bucket for log retention | New | T3 | 3/9 | 3/10 | 2 |
| S3-T3-03 | Events rule + monitoring alarm on DRG changes | New | T3 | 3/9 | 3/10 | 2 |
| S3-T3-04 | OCI Vault (KMS) + AES-256 master encryption key | New | T3 | 3/9 | 3/9 | 1 |
| S3-T3-05 | Cloud Guard detector/responder recipes (clone Oracle-managed) | New | T3 | 3/9 | 3/10 | 2 |
| S3-T3-06 | Cloud Guard target on tenancy root | New | T3 | 3/9 | 3/10 | 2 |
| S3-T3-07 | Security Zone recipes (SEC encryption + NW isolation) | New | T3 | 3/10 | 3/10 | 1 |
| S3-T3-08 | Security Zones on C1_R_ELZ_SEC + C1_R_ELZ_NW | New | T3 | 3/10 | 3/10 | 1 |
| S3-ORA-01 | Deploy Sprint 3 to OCI using Resource Manager | New | Oracle | 3/10 | 3/10 | 1 |
| S3-ORA-02 | Sprint 1 IAM patch re-apply (7 statements: 5 NW + 2 SEC) | New | Oracle | 3/9 | 3/9 | 1 |
| S3-ORA-03 | Verify Cloud Guard ENABLED in tenancy | New | Oracle | 3/9 | 3/9 | 1 |
| S3-ORA-04 | Validate Security Zone policy OCIDs for ap-singapore-2 | New | Oracle | 3/9 | 3/9 | 1 |

---

## File Map

| File | Owner | Resources |
|---|---|---|
| `sec_team4.tf` | T4 | 13: custom DRG RTs, route distribution, static route, VCN ingress RT, Hub FW RT (import), Service Gateway, 5 DRG attachment mgmt |
| `sec_team3.tf` | T3 | 11: log group, 6 flow logs, bucket, notification topic, events rule, alarm |
| `sec_team3_security.tf` | T3 | 10: Vault, master key, 3 CG recipes, CG target, 2 SZ recipes, 2 SZ zones |
| `sec_team1.tf` | T1 | 1: Bastion session (OS Sim FW SSH) |
| `sec_team2.tf` | T2 | 1: Bastion session (TS Sim FW SSH) |
| `locals.tf` | — | 29 name constants |
| `variables_general.tf` | — | 5 vars (tenancy, region, home_region, service_label, ssh_key) |
| `variables_iam.tf` | — | 10 compartment OCIDs from Sprint 1 |
| `variables_s2_ref.tf` | — | 30 Sprint 2 output OCIDs |
| `variables_net.tf` | — | 5 CIDR variables |
| `data_sources.tf` | — | 6 data sources (ObjStorage ns, OCI services, CG config/activity/responder, SZ policies) |
| `providers.tf` | — | OCI + OCI home |
| `outputs.tf` | — | 16 outputs for Sprint 4 |
| `schema.yaml` | — | ORM UI — 7 groups, 42 variables |
| `s2_sprint2_ref.tf` | — | Sprint 2 inventory (read-only) |
| `terraform.tfvars.template` | — | Template with CLI commands per OCID |

---

## Sprint 2 → Sprint 3 Handover

Verify before Sprint 3: 5 VCNs, 6 subnets (all private), DRG with 5 attachments ATTACHED, 6 security lists, 4 Sim FW RUNNING, Bastion ACTIVE, tag namespace C0-star-elz-v1 ACTIVE, zero ORM drift.

Sprint 2 security lists (6 SLs, allow-all internal 10.0.0.0/8) remain unchanged. NSG tightening is V2. Sprint 3 events rule monitors security list changes.

Sprint 2 Hub FW RT (`rt_r_elz_nw_fw`, created empty) is imported into Sprint 3 state via `import{}` block. Sprint 3 adds spoke CIDR routes and Service Gateway route. Requires `hub_fw_rt_id` OCID.

---

## Deployment — Sprint 3 Day (9 March)

**Step 1 — Sprint 1 IAM patch.** Add 7 statements to Sprint 1 `iam_policies_team1.tf`: 5 in UG_ELZ_NW-Policy (bastion-family + 4× read instance-family), 2 in UG_ELZ_SEC-Policy (manage security-zone in SEC + NW). Commit, Plan → Apply. Expected: "2 to change". Zero destroys. See `docs/SPRINT1_IAM_PATCH_FOR_S3.md`.

**Step 1b — Verify Cloud Guard ENABLED.** Console: `Identity & Security → Cloud Guard`. Must be ENABLED before Security Zones can be created.

**Step 2 — Sprint 3 ORM apply.** Create stack, configure 42 variables from Sprint 1 + Sprint 2 outputs, Plan → Apply. Expected: "37 to add" (36 resources + 1 import).

**Step 3 — Validate.** Run TC-20 through TC-35.

---

## Test Cases

| # | What | Expected |
|---|---|---|
| TC-20 | Custom DRG RTs exist | drgrt_r_hub_spoke_mesh + drgrt_spoke_to_hub visible |
| TC-21 | Spoke attachments use spoke_to_hub RT | drg-route-table-id points to spoke_to_hub |
| TC-22 | Forced inspection — OS → TS via Hub FW | traceroute hits Hub FW IP before TS |
| TC-23 | VCN flow logs capturing | Flow entries in lg_r_elz_nw_flow for Hub FW subnet |
| TC-24 | Events rule fires | Route table Console edit triggers nt_r_elz_sec_alerts |
| TC-25 | Object Storage bucket | bkt_r_elz_sec_logs exists, versioned, no public |
| TC-26 | Bastion session — OS SSH | ACTIVE |
| TC-27 | Bastion session — TS SSH | ACTIVE |
| TC-28 | Vault ACTIVE | vlt_r_elz_sec lifecycle-state = ACTIVE |
| TC-29 | Master key AES-256 HSM | AES / 32 / HSM |
| TC-30 | Cloud Guard target ACTIVE | cgt_r_elz_root covers tenancy |
| TC-31 | CG detector recipes attached | cgdr_r_elz_config + cgdr_r_elz_activity on target |
| TC-32 | Security Zone SEC ACTIVE | sz_r_elz_sec on C1_R_ELZ_SEC |
| TC-33 | Security Zone NW ACTIVE | sz_r_elz_nw on C1_R_ELZ_NW |
| TC-34 | SZ NW blocks public subnet | HTTP 409 creating public subnet in NW |
| TC-35 | SZ SEC blocks unencrypted volume | HTTP 409 creating volume without CMK |

**Gate:** TC-20 through TC-35 all PASS before Sprint 4.

---

## Resource Count — 36 Total

| Category | Count |
|---|---|
| DRG Route Tables + Distribution + Rule | 5 |
| VCN Route Tables (ingress + FW import) | 2 |
| DRG Attachment Management | 5 |
| Service Gateway | 1 |
| Log Group + 6 Flow Logs | 7 |
| Object Storage Bucket | 1 |
| Notification Topic + Events Rule + Alarm | 3 |
| Bastion Sessions | 2 |
| KMS Vault + Key | 2 |
| Cloud Guard Recipes + Target | 4 |
| Security Zone Recipes + Zones | 4 |
| **Total** | **36** |

Sprint 1: ~60 IAM. Sprint 2: 38 networking. Sprint 3: 36 security/observability. **~134 total under Terraform.**

---

## Known Considerations

**Cloud Guard target conflict:** If an existing target covers tenancy root, `oci_cloud_guard_target.root` will fail. Check Console first. Import or skip if exists.

**Security Zone policy OCIDs:** Hardcoded for OCI public regions. Verify in Console for ap-singapore-2 before apply. For isolated region, OCIDs may differ.

**Security Zone on existing resources:** Existing non-compliant resources are NOT modified. Cloud Guard flags them. Only new creation is blocked.

**Hub FW RT import:** First apply shows RT as "imported" with new routes added. Expected.

**Bastion sessions expire:** 30-min TTL, `ignore_changes` on TTL. Expire naturally.

**Events rule cross-compartment:** Lives in SEC, monitors NW events via `read all-resources in tenancy`.

---

**Sprint 3 owner:** DSTA + Oracle | **Gate to Sprint 4:** TC-20 through TC-35 all PASS
