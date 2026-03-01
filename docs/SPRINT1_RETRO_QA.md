# Sprint 1 Retrospective & Sprint 2 Resolution Q&A

**File:** `docs/SPRINT1_RETRO_QA.md`
**Date Updated:** 2026-02-28
**Owner:** Principal Architect (Amit)
**Purpose:** Tracking resolutions from the Feb 26 STAR Team Zoom session and aligning them with the Sprint 1 & Sprint 2 Terraform architecture updates.

---

## 1. Tagging & State Conflicts

**Q: Policy creation fails — resource in conflicted state (tag namespace exists).**

**Resolution: ✅ FIXED IN CODE**

The conflict originated in `mon_tags.tf`, where `oci_identity_tag_default` was incorrectly reusing `oci_identity_tag.owner.id` during creation. This caused the `Owner` tag to receive `${iam.principal.name}` at provisioning time and then be overridden by `lz_defined_tags` on apply — producing an inconsistent state cycle that ORM interpreted as perpetual drift.

The file was completely rewritten. Changes made:

- `DataClassification` tag added as a dedicated 5th tag (SG Government classification: Official-Open / Official-Closed / Sensitive-Normal / Sensitive-High / Restricted).
- `oci_identity_tag_default` now correctly references `oci_identity_tag.data_classification.id`, with a static default value of `Official-Closed` (CIS 3.2 compliance).
- `lifecycle { prevent_destroy = true }` applied to `oci_identity_tag_namespace.elz_v1` to prevent ORM from attempting to delete and recreate the namespace, which was the root cause of the conflicted-state error.

---

**Q: Tagging — Terraform implementation and design best practices (review with Global Architect Inderpal).**

**Resolution: ✅ IMPLEMENTED**

The baseline best practice is established. Tags are defined once at the Hub/Root level (`mon_tags.tf`) under the `C0-star-elz-v1` namespace. Three tagging layers are in effect across all resources:

- **Layer 1 (freeform):** `oci-elz-landing-zone`, `managed-by`, `sprint` — no dependencies, applied immediately.
- **Layer 2 (defined):** `C0-star-elz-v1.{Environment, Owner, ManagedBy, CostCenter}` — applied via `lz_defined_tags` local.
- **Layer 3 (tag default):** `DataClassification = Official-Closed` auto-applied at tenancy root via `oci_identity_tag_default` — no team action required, every new resource inherits it.

Teams do not need to write tag blocks on individual resources. `depends_on` is used where necessary to handle the OCI tag service's ~10-second propagation lag.

---

## 2. Variables, Naming & ORM UI

**Q: Global and local variable implementation and design best practices (Amit / Inderpal review).**

**Resolution: ✅ IMPLEMENTED**

Hardcoding is fully deprecated. All global routing names (e.g., `ew_hub_drg_name = "drg_r_ew_hub"`), base CIDR blocks, resource display names, DNS labels, and DRG attachment names are centralised in `locals.tf` and `variables_net.tf`. No resource file defines a string literal for any infrastructure name — all reference `local.*` constants. This ensures a single rename in `locals.tf` propagates everywhere automatically.

---

**Q: Naming consistency check — uppercase with underscores issue was present in module YAML and variables.**

**Resolution: ✅ FIXED & DOCUMENTED**

The naming standard documentation is now in `docs/` in the repository and is the single source of truth. The conventions in force are:

| Resource Class | Pattern | Example |
|---|---|---|
| Compartments | `C1_<AGENCY>_ELZ_<FUNCTION>` | `C1_R_ELZ_NW` |
| Groups | `UG_[<AGENCY>_]ELZ_<FUNCTION>` | `UG_ELZ_NW`, `UG_OS_ELZ_NW` |
| Policies | `<GROUP_NAME>-Policy` | `UG_ELZ_NW-Policy` |
| VCNs | `vcn_<agency>_elz_nw` | `vcn_r_elz_nw` |
| Subnets | `sub_<agency>_elz_nw_<zone>` | `sub_os_elz_nw_app` |
| DRGs | `drg_r_<qualifier>` | `drg_r_hub` |
| Route Tables | `rt_<agency>_elz_nw_<zone>` | `rt_os_elz_nw_app` |
| Sim Firewalls | `fw_<agency>_elz_nw_sim` | `fw_os_elz_nw_sim` |
| Bastion | `bas_r_elz_nw_hub` | — |
| DRG Attachments | `drga_<agency>_elz_nw` | `drga_os_elz_nw` |
| Tag Namespace | `C0-<project>-elz-v<N>` | `C0-star-elz-v1` |

All 29 resource display-name constants in `sprint2/locals.tf` were programmatically validated against this convention — zero drift.

---

**Q: `schema.yaml` in ORM UI — one name per variable; tags in ORM should match universal tagging.**

**Resolution: ✅ FIXED IN CODE**

`schema.yaml` was fully audited. All four spoke VCN CIDR defaults were corrected from `/16` to `/24` to exactly match the Terraform `variables_net.tf` defaults. The ORM UI will now present values that are directly deployable without any manual correction. Defined tag keys in the ORM UI match the `C0-star-elz-v1` namespace exactly.

---

## 3. State Management & Tracking

**Q: Policy naming — must match Sprint 1 agreement. Move from Excel to JSON state ledger.**

**Resolution: ✅ CONFIRMED**

Excel tracking is officially deprecated. `sprint_state_ledger.json` was merged into the repository today and is the single source of truth for state sync across all teams. Policy names follow the `<GROUP_NAME>-Policy` convention and are validated against the ledger. The Sprint 1 stack contains 7 policy objects (60 statements). SIM policies (`UG_SIM_EXT-Policy`, `UG_SIM_CHILD-Policy`) are Sprint 4 scope and are not in the Sprint 1 state.

---

**Q: ORM deletion of resources and drift — not caught for one team (Feb 26 Zoom session; workarounds from Amit and Wendy).**

**Resolution: ✅ MITIGATED**

`.gitignore` files have been added to both `sprint1/` and `sprint2/` directories, excluding `*.tfstate`, `*.tfvars`, `.terraform/`, and `*.tfplan` from version control. This prevents local state files from overriding ORM remote state on the next plan. The specific drift anomaly from Feb 26 is still under investigation — TCE team has been asked to retrieve the ORM Job logs for the affected stack.

> **Standing action:** Do not run `terraform destroy` and re-apply to resolve drift. Contact the architect first so the drifted resource can be imported (`terraform import`) rather than recreated.

---

## 4. Sprint 2 Setup & Execution

**Q: Sprint 2 code scaffold needs updates per sprint schedule — must include VCNs, subnets, routing, and smoother validation.**

**Resolution: ✅ COMPLETED — Amit / Han Kiat Review**

The comprehensive audit branch was merged today. The scaffold now fully maps to the V1 Isolated Design:

- 5 VCNs (`vcn_r_elz_nw`, `vcn_os_elz_nw`, `vcn_ts_elz_nw`, `vcn_ss_elz_nw`, `vcn_devt_elz_nw`)
- 6 subnets (2 hub, 4 spoke app subnets)
- 2 DRGs in `C1_R_ELZ_NW`: `drg_r_hub` (active, 5 attachments in Phase 2) and `drg_r_ew_hub` (V2 placeholder, 0 attachments)
- 6 route tables — all spoke RTs updated in-place via dynamic `route_rules` block in Phase 2 (no subnet recreation)
- 4 Sim FW instances (hub, OS, TS, SS) — DEVT is network-only in V1
- 1 OCI Bastion Service (`bas_r_elz_nw_hub`) in hub MGMT subnet

All resources are parameterised. CIDR defaults in `variables_net.tf`, `locals.tf`, `schema.yaml`, and `terraform.tfvars.template` are fully consistent at `/24` for spokes.

---

**Q: Positive and negative validation tests via OCI CLI — not yet completed by teams.**

**Resolution: ✅ ACTIONED**

GitHub issues have been bulk-generated for the Sprint 2 board (StarPrj). Validation tasks TC-07 through TC-12b are mapped as explicit tickets for teams to execute via CLI post-deployment. The CLI commands are documented in `ARCHITECT_RUNBOOK.md`. TC-12b (E-W DRG exists) is a new test case added today alongside the `drg_r_ew_hub` resource.

---

**Q: Access policies, service gateways — reference link for teams to write their own blocks.**

**Resolution: ⏳ DEFERRED TO SPRINT 3**

Service Gateways are officially a Sprint 3 backlog item (Ticket `S3-ALL` created on the board). Teams should reference the standard OCI Terraform provider documentation for service gateway resource blocks: [registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_service_gateway](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_service_gateway).

---

## 5. Security & Auditing

**Q: Did Dawei ask for auditor/read role or full admin policy? (Clarified from Tuesday — SoD concern.)**

**Resolution: ✅ RESOLVED VIA SoD**

Dawei requires validation/auditor access, not administrative rights. During today's audit, a Separation of Duties (SoD) violation was identified: the Hub NW admin group (`UG_ELZ_NW`) had `manage virtual-network-family` in all four spoke compartments, which would allow the hub admin to modify spoke subnets and route tables directly.

This was downgraded to `read virtual-network-family` in `iam_policies_team1.tf` (pushed today). The SoD principle (A-06) is now enforced: each spoke team manages their own VCN exclusively via `UG-SPOKE-NW-Policy`, while the hub admin has read-only visibility for validation and dashboard use. TC-03 verifies this boundary.

---

**Q: Cloud Guard Terraform enablement — to be confirmed (manually completed).**

**Resolution: ✅ ACKNOWLEDGED**

Cloud Guard was enabled manually in the tenancy. Importing it into Terraform state via `terraform import` will be evaluated in a future hardening sprint. No action required today.

---

## 6. Outstanding Items — Global Architect & TCE Review

The following items remain open pending architectural review:

| Item | Owner | Status |
|---|---|---|
| Clean Tenancy Script (Python — full teardown) | Amit / Inderpal | 🔴 Pending |
| Multi-Tenancy / Env Strategy (dev/prod mirror, 2-root tenancy design, split-tenancy for test) | TCE Team / Paxton | 🔴 Pending |
| ORM drift anomaly (Feb 26) — retrieve Job logs | TCE Team | 🟡 In Progress |
| Cloud Guard Terraform import (future hardening sprint) | Architect | 🔵 Backlog |
| Service Gateways (Sprint 3 backlog — Ticket S3-ALL) | All Teams | 🔵 Sprint 3 |
