# STAR ELZ V1 — Sprint 3: Security, Observability, Forced Inspection

**Branch:** `sprint3` · **Dates:** 9–10 Mar 2026 · **Terraform ≥ 1.3.0** · **OCI Provider ≥ 6.0.0**

> **Coming from Sprint 2?** You need 23 OCIDs from `terraform output -json > sprint2_outputs.json`. Sprint 1 IAM patch must be applied first — see Deployment.

Sprint 2 built the roads (5 VCNs, DRG full-mesh, Sim FWs, Bastion, SGWs, security lists). Traffic flowed spoke → DRG → spoke **direct** — no inspection.

Sprint 3 adds: forced inspection through Hub FW, security services (Vault, Cloud Guard, Security Zones), observability (flow logs, events, alarms), log publishing (SCH), vulnerability scanning (VSS), and certificate management (internal CA).

After apply: OS → DRG → Hub FW → inspect → DRG → TS. Flow logs prove it. Security Zones block insecure resources. Cloud Guard monitors continuously.

---

## Network Topology — After Sprint 3

```
Forced Inspection Flow:
  OS → spoke RT (0/0→DRG) → DRG spoke_to_hub (0/0→Hub att)
  → VCN ingress RT (10/8→Hub FW VNIC) → Hub Sim FW (MASQUERADE ens3)
  → Hub FW RT (spoke CIDRs→DRG) → DRG hub_spoke_mesh (import dist)
  → destination spoke

                       ┌──────────────────────────────────────┐
                       │  drg_r_hub                            │
                       │  drgrt_spoke_to_hub   drgrt_r_hub_   │
                       │  0/0 → Hub att        spoke_mesh     │
                       │  (OS/TS/SS/DEVT)      import dist    │
                       │                       (Hub att)      │
                       └───┬──────┬─────┬─────┬──────┬────────┘
                        OS att TS att SS att DEVT  Hub att
                                                     │
                    ┌────────────────────────────────┘
                    │ Hub VCN  10.0.0.0/16
                    │ VCN ingress RT: 10/8 → Hub FW VNIC
                    │
                    │ sub_r_elz_nw_fw (10.0.0.0/24)
                    │   fw_r_elz_nw_hub_sim (ens3 MASQUERADE)
                    │   RT: 10.1/24→DRG, 10.2/24→DRG, 10.3/24→DRG, 10.4/24→DRG, +SGW
                    │
                    │ sub_r_elz_nw_mgmt (10.0.1.0/24)
                    │   bas_r_elz_nw_hub (Bastion)
                    │   RT: 0/0→DRG, +SGW
                    │
                    │ sgw_r_elz_nw_hub → All OSN (Sprint 2, referenced via var)

Spokes (Sprint 2 — unchanged):
  OS 10.1.0/24 · TS 10.3.0/24 · SS 10.2.0/24 · DEVT 10.4.0/24
  All: RT 0/0→DRG + SGW→OSN · SL allow 10/8 · SGW per VCN

Security Services (C1_R_ELZ_SEC — T3):
  vlt_r_elz_sec + key     KMS Vault + AES-256 HSM key
  cgt_r_elz_root          Cloud Guard target (tenancy root)
  sz_r_elz_sec/nw         Security Zones (encryption + network)
  lg_r_elz_nw_flow        Log group + 6 flow logs
  bkt_r_elz_sec_logs      Object Storage (versioned, private)
  sch_r_elz_sec_log..     SCH: flow logs → bucket
  vssr_r_elz_sec_host     VSS: host scan recipe + target
  ca_r_elz_sec_internal   Internal CA (V2+ TLS)
  nt_r_elz_sec_alerts     Topic + events rule + alarm
```

---

## Sprint 2 → Sprint 3 — What Changes

| Sprint 2 Resource | Sprint 3 Action |
|---|---|
| DRG auto-generated RTs | **Replaced** with custom RTs |
| DRG attachments (5) | **Reassigned** to custom DRG RTs |
| Hub FW RT (SGW rule) | **Imported** + spoke CIDR routes added |
| SGWs (5) | **No change** — referenced via `var.hub_sgw_id` |
| Security lists (6) | **No change** — events rule monitors |
| Bastion service | Sprint 3 creates **sessions** on it |

No duplicate resources. Two ORM stacks, two state files, zero conflict.

---

## Issue List

| # | Task | Team | File |
|---|---|---|---|
| S3-T4-01 | Custom DRG RTs + distribution + static route | T4 | `sec_team4.tf` |
| S3-T4-02 | VCN ingress RT + Hub FW RT update (import) | T4 | `sec_team4.tf` |
| S3-T4-03 | 5 DRG attachment management (RT reassignment) | T4 | `sec_team4.tf` |
| S3-T1-01 | Bastion session — OS spoke | T1 | `sec_team1.tf` |
| S3-T2-01 | Bastion session — TS spoke | T2 | `sec_team2.tf` |
| S3-T3-01 | Log group + 6 flow logs + SCH + bucket | T3 | `sec_team3.tf` |
| S3-T3-02 | Events rule + alarm + notification topic | T3 | `sec_team3.tf` |
| S3-T3-03 | VSS recipe + target | T3 | `sec_team3.tf` |
| S3-T3-04 | Internal CA | T3 | `sec_team3.tf` |
| S3-T3-05 | Vault + master key | T3 | `sec_team3_security.tf` |
| S3-T3-06 | Cloud Guard recipes + target | T3 | `sec_team3_security.tf` |
| S3-T3-07 | Security Zone recipes + zones | T3 | `sec_team3_security.tf` |
| S3-ORA-01 | Sprint 1 IAM patch (9 statements) | Oracle | IAM patch doc |
| S3-ORA-02 | Verify Cloud Guard ENABLED | Oracle | Console |

---

## Deployment

**Step 1 — Sprint 1 IAM patch.** Add 9 statements. Plan → Apply. "2 to change". See `docs/SPRINT1_IAM_PATCH_FOR_S3.md`.

**Step 1b — Cloud Guard ENABLED.** Console → Cloud Guard → verify.

**Step 2 — Sprint 3 ORM.** Create stack → `sprint3/` → paste OCIDs → Plan → Apply. "39 to add, 1 to import".

**Step 3 — Validate.** TC-20 through TC-39.

---

## Test Cases

### Variables

```bash
HUB_DRG_ID="<paste>"           # Sprint 2 output
VAULT_ID=$(terraform output -raw vault_id)
KEY_ID=$(terraform output -raw master_key_id)
VAULT_EP=$(terraform output -raw vault_management_endpoint)
CG_TARGET=$(terraform output -raw cg_target_id)
SZ_SEC=$(terraform output -raw sz_sec_id)
SZ_NW=$(terraform output -raw sz_nw_id)
```

### Forced Inspection (T4)

**TC-20 — Custom DRG RTs.** Console → DRGs → `drg_r_hub` → Route Tables. Expect: `drgrt_r_hub_spoke_mesh` + `drgrt_spoke_to_hub`.

**TC-21 — Spoke RT assignment.** Console → DRG Attachments → each spoke → DRG RT = `drgrt_spoke_to_hub`.

**TC-22 — Forced inspection proof.** Bastion SSH to OS Sim FW:
```bash
traceroute -n 10.3.0.x   # TS Sim FW — replace with actual IP
```
Hub FW IP (10.0.0.x) appears as hop before TS = forced inspection working.

### Observability (T3)

**TC-23 — Flow logs.** Console → Logging → `lg_r_elz_nw_flow` → `fl_r_elz_nw_fw`. Spoke source IPs visible.

**TC-24 — Events rule.** Console → edit any route table → check `nt_r_elz_sec_alerts` for event.

**TC-25 — Bucket.** Console → Object Storage → `bkt_r_elz_sec_logs`. Versioned, NoPublicAccess.

**TC-26 — SCH.** Console → Service Connectors → `sch_r_elz_sec_log_to_bucket` → ACTIVE.

### Bastion (T1, T2)

**TC-27/28 — Sessions.** Console → Bastion → Sessions → OS + TS both ACTIVE.

### Vault (T3)

**TC-29 — Vault.** Console → Vault → `vlt_r_elz_sec` → ACTIVE.

**TC-30 — Key.** Same vault → `key_r_elz_sec_master` → AES / 256 / HSM.

### Cloud Guard (T3)

**TC-31 — Target.** Console → Cloud Guard → Targets → `cgt_r_elz_root` → ACTIVE.

**TC-32 — Recipes.** Same target → Detector Recipes → both attached.

### Security Zones (T3)

**TC-33/34 — Zones ACTIVE.** Console → Security Zones → `sz_r_elz_sec` + `sz_r_elz_nw`.

**TC-35 — NW blocks public subnet.** Console → create public subnet in `C1_R_ELZ_NW` → 409.

**TC-36 — SEC blocks unencrypted volume.** Console → create volume without CMK in `C1_R_ELZ_SEC` → 409.

### VSS (T3)

**TC-37 — Recipe.** Console → Scanning → Recipes → `vssr_r_elz_sec_host`.

**TC-38 — Target.** Console → Scanning → Targets → `vsst_r_elz_nw`.

### Certificates (T3)

**TC-39 — Internal CA.** Console → Certificates → CAs → `ca_r_elz_sec_internal` → ACTIVE.

---

## Resource Count — 39

| Category | Count | Owner |
|---|---|---|
| DRG Route Tables + Distribution + Rule | 5 | T4 |
| VCN Route Tables (ingress + FW import) | 2 | T4 |
| DRG Attachment Management | 5 | T4 |
| Bastion Sessions | 2 | T1, T2 |
| Log Group + 6 Flow Logs | 7 | T3 |
| Bucket + SCH | 2 | T3 |
| Topic + Events + Alarm | 3 | T3 |
| VSS Recipe + Target | 2 | T3 |
| Internal CA | 1 | T3 |
| Vault + Key | 2 | T3 |
| Cloud Guard Recipes + Target | 4 | T3 |
| Security Zone Recipes + Zones | 4 | T3 |
| **Total** | **39** | |

Sprint 1: ~60 IAM · Sprint 2: 40 networking · Sprint 3: 39 security · **~139 total**

---

## Handoff Checklist

- [ ] TC-20/21: DRG RTs + spoke assignment
- [ ] TC-22: Forced inspection — traceroute proves Hub FW hop
- [ ] TC-23/24: Flow logs + events
- [ ] TC-25/26: Bucket + SCH
- [ ] TC-27/28: Bastion sessions
- [ ] TC-29/30: Vault + key
- [ ] TC-31/32: Cloud Guard
- [ ] TC-33–36: Security Zones + blocks non-compliant
- [ ] TC-37/38: VSS
- [ ] TC-39: Internal CA
- [ ] `sprint3_outputs.json` shared
- [ ] Git tag `sprint3-complete`
- [ ] Sprint 4 backlog (compute, AD Bridge, DNS, Hello World)

**Sprint 3 owner:** DSTA + Oracle | **Gate to Sprint 4:** TC-20–TC-39 all PASS
