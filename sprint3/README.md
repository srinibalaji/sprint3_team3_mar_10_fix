# STAR ELZ V1 — Sprint 3

**Dates:** 9–10 March 2026 | **Module:** Security, Observability, Forced Inspection
**Prerequisite:** Sprint 1 (IAM) ✅ | Sprint 2 (Networking) ✅ | Sprint 1 IAM Patch ⚡ (see Deployment)
**Deployment:** Sprint 1 re-apply (IAM patch) → Sprint 3 ORM single Plan → Apply

---

## What we are building

<img width="720" height="405" alt="Sprint3" src="https://github.com/user-attachments/assets/cefd27bc-5d7e-49c7-ab8a-c85077464c98" />

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

Shell variables (set once after Sprint 3 apply):

```bash
export DRG_ID=$(terraform output -raw hub_spoke_mesh_drgrt_id | cut -d. -f1-4)  # or from Sprint 2 output
export VAULT_ID=$(terraform output -raw vault_id)
export VAULT_EP=$(terraform output -raw vault_management_endpoint)
export KEY_ID=$(terraform output -raw master_key_id)
export CG_TARGET=$(terraform output -raw cg_target_id)
export SZ_SEC=$(terraform output -raw sz_sec_id)
export SZ_NW=$(terraform output -raw sz_nw_id)
```

| # | What | CLI / Method | Expected |
|---|---|---|---|
| TC-20 | Custom DRG RTs exist | `oci network drg-route-table list --drg-id $HUB_DRG_ID --all --query 'data[].{name:"display-name"}'` | drgrt_r_hub_spoke_mesh + drgrt_spoke_to_hub |
| TC-21 | Spoke attachments use spoke_to_hub RT | `oci network drg-attachment get --drg-attachment-id $OS_ATTACH_ID --query 'data."drg-route-table-id"'` | Points to spoke_to_hub OCID |
| TC-22 | Forced inspection — OS → TS via Hub FW | SSH to OS Sim FW via Bastion, run `traceroute 10.3.0.x` | Packet hits Hub FW IP (10.0.x.x) before reaching TS |
| TC-23 | VCN flow logs capturing | Console → Logging → lg_r_elz_nw_flow → fl_r_elz_nw_fw | Flow entries showing spoke source IPs on Hub FW subnet |
| TC-24 | Events rule fires | Manually update a route table via Console, then check ONS | Event delivered to nt_r_elz_sec_alerts topic |
| TC-25 | Object Storage bucket | `oci os bucket get --bucket-name bkt_r_elz_sec_logs --query 'data.{versioning:versioning,access:"public-access-type"}'` | Enabled / NoPublicAccess |
| TC-26 | Bastion session — OS SSH | `oci bastion session get --session-id $OS_SESSION_ID --query 'data.{state:"lifecycle-state",target:"target-resource-details"."target-resource-id"}'` | ACTIVE, target = OS Sim FW |
| TC-27 | Bastion session — TS SSH | `oci bastion session get --session-id $TS_SESSION_ID --query 'data.{state:"lifecycle-state"}'` | ACTIVE |
| TC-28 | Vault ACTIVE | `oci kms vault get --vault-id $VAULT_ID --query 'data."lifecycle-state"'` | ACTIVE |
| TC-29 | Master key AES-256 HSM | `oci kms key get --key-id $KEY_ID --endpoint $VAULT_EP --query 'data.{"alg":"key-shape".algorithm,"len":"key-shape".length,"mode":"protection-mode"}'` | AES / 32 / HSM |
| TC-30 | Cloud Guard target ACTIVE | `oci cloud-guard target get --target-id $CG_TARGET --query 'data."lifecycle-state"'` | ACTIVE |
| TC-31 | CG detector recipes attached | `oci cloud-guard target get --target-id $CG_TARGET --query 'data."target-detector-recipes"[].{name:"display-name"}'` | cgdr_r_elz_config + cgdr_r_elz_activity |
| TC-32 | Security Zone SEC ACTIVE | `oci cloud-guard security-zone get --security-zone-id $SZ_SEC --query 'data."lifecycle-state"'` | ACTIVE |
| TC-33 | Security Zone NW ACTIVE | `oci cloud-guard security-zone get --security-zone-id $SZ_NW --query 'data."lifecycle-state"'` | ACTIVE |
| TC-34 | SZ NW blocks public subnet | Create public subnet in C1_R_ELZ_NW via Console | HTTP 409 — security zone violation |
| TC-35 | SZ SEC blocks unencrypted volume | Create block volume without CMK in C1_R_ELZ_SEC via Console | HTTP 409 — security zone violation |

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

**Sprint 3 owner:** STAR + Oracle | **Gate to Sprint 4:** TC-20 through TC-35 all PASS
