---
theme: apple-basic
title: Network Security in Microsoft Fabric
info: Architecture, Security & Best Practices — April 2026
drawings:
  persist: false
transition: slide-left
mdc: true
---

# Network Security in Microsoft Fabric

Architecture, Security & Best Practices

<div class="absolute bottom-10">
  <span class="font-700">
    April 2026
  </span>
</div>

---
layout: intro-image-right
image: https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800
---

# Agenda

<div class="leading-8">

**Foundations** — Secure by Default

**Inbound** — Conditional Access, Private Link, IP Firewall

**Outbound** — TWA, MPE, Gateways

**Protection** — DEP & Exfiltration Controls

**Operations** — DNS, Monitoring, Testing

**Patterns** — Architecture Scenarios

**Roadmap** — Feature Status

</div>

---

# Microsoft Fabric — Unified SaaS Analytics

<br>

| Experience | Role |
|---|---|
| **Data Factory** | ETL & Orchestration |
| **Data Engineering** | Spark & Notebooks |
| **Data Science** | ML Experiments & Models |
| **Data Warehouse** | T-SQL Analytics |
| **Real-Time Intelligence** | Streaming & KQL |
| **Power BI** | Reports & Dashboards |

<br>

All experiences share **OneLake** — a single, unified data lake built on ADLS Gen2.

---

# Three Pillars of Network Security

<br>

| Pillar | Objective | Key Features |
|--------|-----------|-------------|
| **Inbound Protection** | Control who accesses Fabric and from where | Conditional Access, Private Links, IP Firewall |
| **Secure Outbound** | Connect Fabric to protected data sources | Trusted Workspace Access, Managed PE, Gateways |
| **Outbound Protection** | Prevent data exfiltration | Outbound Access Policies, allowed destinations |

<br>

> **Inbound + Outbound Protection = Data Exfiltration Protection (DEP)**

---

# Secure by Default

No configuration needed — Fabric is secure out of the box.

<br>

| Feature | Detail |
|---------|--------|
| **Authentication** | Every request authenticated via Microsoft Entra ID |
| **Encryption in transit** | TLS 1.2 minimum, TLS 1.3 negotiated when available |
| **Encryption at rest** | All OneLake data automatically encrypted |
| **Microsoft backbone** | Internal traffic never traverses the public internet |
| **Secure endpoints** | Backend protected by VNet, not directly accessible |

<br>

The features that follow add **additional layers** on top of this baseline.

---
layout: section
---

# Inbound Protection

---

# Inbound Options Comparison

<br>

| Criteria | Conditional Access | PL Tenant | PL Workspace | IP Firewall |
|---|:---:|:---:|:---:|:---:|
| **Granularity** | Tenant | Tenant | Workspace | Workspace |
| **Azure infra needed** | No | VNet + PE | VNet + PE | No |
| **Complexity** | Low | High | Medium | Low |
| **Approach** | Zero Trust | Perimeter | Perimeter | IP-based |
| **User impact** | Transparent | VPN/ER required | VPN/ER for protected WS | None |
| **Status** | GA | GA | GA | GA |

<br>

> **Prerequisite:** A tenant admin must enable *Workspace-level inbound network rules* before WS admins can configure Private Link or IP Firewall.

---

# Entra Conditional Access

The **first gate** — Zero Trust identity-based controls.

<br>

| Signal | Examples |
|--------|---------|
| User / Group | Target specific populations |
| Location / IP | Allow only certain ranges or countries |
| Device | Require Intune compliance |
| Application | Per-Fabric-app rules |
| Risk level | Block high-risk sign-ins |

<br>

**Decisions:** Block · Grant · Require MFA · Require compliant device

**Prerequisite:** Entra ID P1 license (included in M365 E3/E5)

---

# Zero Trust Identity Best Practices

<br>

| Practice | Description |
|----------|-------------|
| **Phishing-resistant MFA** | FIDO2 keys, Windows Hello, certificate-based |
| **Device Compliance** | Require managed devices via Intune |
| **PIM** | Just-in-time, time-limited admin elevation |
| **Service Principal Governance** | Audit & restrict SPN/MI access to Fabric APIs |
| **Continuous Access Evaluation** | Near-real-time token revocation on risk events |

<br>

> **Start with identity** (MFA, CA, PIM) before layering network controls. This ensures baseline protection regardless of the user's network path.

---

# Tenant-Level Private Link

Full tenant isolation — Fabric becomes inaccessible from the public internet.

<br>

| Setting | Effect |
|---------|--------|
| **Azure Private Links** | VNet traffic routed through Private Link |
| **Block Public Access** | Public internet access disabled |

<br>

**Considerations:**

- All users must connect via VPN or ExpressRoute
- Copilot, Publish to Web, some exports are **disabled**
- Spark Starter Pools disabled — custom pools take 3-5 min
- Cross-tenant access not supported
- Private DNS Zone required

<br>

> **Best for:** Regulated industries where zero public traffic is mandated. Consider workspace-level PL first.

---

# Workspace-Level Private Link ★

**Recommended approach** — protect only sensitive workspaces.

<br>

**Characteristics:**

- 1:1 relationship: workspace ↔ Private Link Service
- Multiple PEs from different VNets to the same workspace
- Public access disabled **per workspace**
- GA since September 2025

<br>

**Supported:** Lakehouse, Warehouse, Notebook, Pipeline, Dataflow, Eventstream, Mirrored DB, ML Experiment/Model

**Not yet supported:** Power BI reports/dashboards, Fabric databases, Data Activator *(planned)*

<br>

> Unlike tenant-level PL, this allows self-service BI workspaces to remain publicly accessible with CA protection.

---

# Workspace IP Firewall

The simplest option — no Azure infrastructure required.

<br>

**Concept:** Only explicitly allowed IP ranges can access the workspace.

**GA since Q1 2026.** Same supported items as Workspace PL.

<br>

**Key notes:**

- Fabric REST API remains accessible regardless of IP rules (by design, to prevent lockout)
- Use Conditional Access to govern API-level access
- Power BI items and Fabric databases are **not covered** (planned)

<br>

> **Best for:** Organizations with static office IPs, no VNet infrastructure, needing quick workspace-level protection.

---

# Tenant vs Workspace Interaction

<br>

| Tenant Public Access | WS PL | WS IP FW | Portal | API |
|:---:|:---:|:---:|---|---|
| Allowed | — | — | Public | Public |
| Allowed | Configured | — | WS PL only | WS PL only |
| Allowed | — | Configured | Allowed IPs | Allowed IPs |
| Restricted | — | — | Tenant PL only | Tenant PL only |
| Restricted | Configured | — | Tenant PL only | WS PL or Tenant PL |
| Restricted | — | Configured | Tenant PL only | Tenant PL only |

<br>

> When tenant public access is **restricted**, tenant PL takes precedence for portal access. Workspace PL only adds API-level paths.

---
layout: section
---

# Secure Outbound Access

---

# Outbound Options Overview

<br>

| Method | Sources | Fabric Workloads |
|--------|---------|-----------------|
| **Trusted Workspace Access** | ADLS Gen2 (firewall-enabled) | Shortcuts, Pipelines, COPY INTO, Semantic Models |
| **Managed Private Endpoints** | Azure SQL, Cosmos DB, Key Vault, ADLS... | Spark Notebooks, Lakehouses, Eventstream |
| **VNet Data Gateway** | Azure services in a VNet | Dataflows Gen2, Semantic Models |
| **On-Premises Gateway** | SQL Server, Oracle, SAP, files | Dataflows Gen2, Semantic Models, Pipelines |

---

# Trusted Workspace Access

Access **firewall-enabled ADLS Gen2** via workspace identity.

<br>

**Prerequisites — all four are required:**

1. Workspace on **Fabric F SKU** capacity (not Trial or P SKU)
2. **Workspace Identity** created and enabled
3. RBAC role on ADLS Gen2 (`Storage Blob Data Contributor/Owner/Reader`)
4. **Resource Instance Rule** on storage firewall (deploy via ARM/Bicep/PowerShell)

<br>

**Supported:** OneLake Shortcuts, Pipelines, T-SQL COPY INTO, Semantic Models, AzCopy

<br>

> Failure at any step **silently blocks** access — no error, just empty results. Verify all four prerequisites.

---

# Managed Private Endpoints

Private connections to Azure services in a Microsoft-managed VNet.

<br>

**How it works:**

1. Workspace admin creates an MPE (specifies resource ID + sub-resource)
2. Fabric provisions a **Managed VNet** (auto, on first MPE or Spark job)
3. Source owner **approves** the Private Endpoint
4. All traffic stays on the Microsoft backbone

<br>

**Supported sources:** Azure SQL, ADLS Gen2, Cosmos DB, Key Vault, and more

**Limitations:** Starter Pools disabled (3-5 min startup), OneLake shortcuts don't support MPE yet, not all regions available

---

# Data Gateways

<br>

| | On-Premises Gateway | VNet Data Gateway |
|---|---|---|
| **Deployment** | Windows server on-prem | Into customer Azure VNet |
| **Management** | Manual (updates, HA) | Managed by Microsoft |
| **Sources** | Any on-prem source | Azure services in VNet/peered VNets |
| **Workloads** | Dataflows Gen2, Semantic Models, Pipelines | Dataflows Gen2, Semantic Models |
| **Proxy / Cert Auth** | — | **GA** (enterprise proxy + cert auth) |

<br>

**Eventstream Private Network** *(Preview Q1 2026):* Ingest from private networks via managed VNet and streaming data gateway. Supports Event Hubs, IoT Hub, custom VNet sources.

---
layout: section
---

# Outbound Protection & DEP

---

# Outbound Access Policies

Restrict outbound connections to **authorized destinations only**.

<br>

1. Declare allowed destinations via **MPE** or **Data Connections**
2. Enable **Outbound Access Policy** on workspace
3. Any undeclared destination → **blocked**

<br>

| Item Type | Status |
|-----------|--------|
| Lakehouse, Spark, Notebooks | **GA** |
| Pipelines, Warehouse, Mirrored DBs | **GA** |
| Power BI, Databases | Planned |

<br>

> Declare **all** legitimate destinations before enabling the policy. Undeclared connections will break immediately.

---

# Data Exfiltration Protection

**Complete DEP = Inbound + Outbound Protection**

<br>

| Component | Role |
|-----------|------|
| **Inbound** (PL / IP FW / CA) | Controls who can access data and from where |
| **Outbound** (Outbound Access Policies) | Prevents exfiltration to unapproved destinations |

<br>

**Complementary data-level controls:**

| Control | Mechanism |
|---------|-----------|
| **Purview Information Protection** | Sensitivity labels across Fabric items |
| **Data Loss Prevention** | Block export of classified items |
| **Power BI Export Restrictions** | Disable CSV/Excel/PPT export |
| **Endpoint DLP** | Block copy to USB / unauthorized cloud |
| **Defender Session Controls** | Monitor/block downloads in real time |

---
layout: section
---

# DNS Configuration

---

# DNS — The #1 Private Link Failure Point

<br>

**Required Private DNS Zones:**

| Zone | Used By |
|------|---------|
| `privatelink.analysis.windows.net` | Power BI / Semantic Models |
| `privatelink.pbidedicated.windows.net` | Dedicated capacity |
| `privatelink.blob.core.windows.net` | OneLake (Blob) |
| `privatelink.dfs.core.windows.net` | OneLake (DFS) |
| `privatelink.servicebus.windows.net` | Event Hubs |
| `privatelink.prod.powerapps.com` | Dataflows |

<br>

> Forgetting to create or link DNS zones is the **most common** cause of Private Link failures. Always verify with `nslookup` — expect `10.x.x.x`, not a public IP.

---

# DNS Best Practices

<br>

1. **Create all required zones** and link to every VNet hosting a PE
2. **Test before go-live** — `Resolve-DnsName <ws>.pbidedicated.windows.net` must return a private IP
3. **Hybrid DNS** — configure conditional forwarders for `privatelink.*` zones to Azure DNS (`168.63.129.16`) via a DNS Private Resolver
4. **Automate** — use Azure Policy (`Deploy-DINE-PrivateDNSZoneGroup`) to auto-create DNS records on PE creation
5. **Monitor for drift** — re-test after infrastructure changes (VNet peering, new PEs, zone re-linking)

<br>

**IP Planning:** 1 PE = 1 private IP. Reserve at least a `/27` subnet (32 IPs) for Fabric PEs.

<br>

> A broken DNS zone link **silently reverts** traffic to the public path — no error, no warning.

---
layout: section
---

# Monitoring & Auditing

---

# Monitoring Stack

<br>

| Log Source | Key Signals |
|------------|-------------|
| **Entra Sign-in Logs** | MFA challenges, CA hits, risky sign-ins |
| **Fabric Admin Audit** | Sharing, exports, gateway operations |
| **Private Endpoint Metrics** | Bytes in/out, connection counts |
| **NSG Flow Logs** | Allow/deny on PE subnets |
| **Azure Firewall Logs** | Rule hits, threat intel, DNS queries |

<br>

**Sentinel integration:** Ingest all sources into Log Analytics → Microsoft Sentinel for anomaly detection, automated playbooks, and hunting queries.

**NSG + Azure Firewall:** Apply service tags (`PowerBI`, `DataFactory`, `SQL`) in NSG rules. Route outbound through Azure Firewall for centralized logging. NAT Gateway for static outbound IP.

---

# Audit & Review Cadence

<br>

| Review | Frequency | Owner |
|--------|-----------|-------|
| IP Firewall rules accuracy | Monthly | Workspace admin |
| Outbound policy allowed destinations | Quarterly | Security team |
| Private Endpoint approvals | Quarterly | Azure subscription owner |
| Conditional Access effectiveness | Quarterly | Identity team |
| DNS zone records and VNet links | Semi-annually | Network team |
| Penetration testing | Annually | Security team |

---
layout: section
---

# Testing & Validation

---

# Connectivity & Performance Tests

<br>

| Test | Tool | Expected Result |
|------|------|----------------|
| DNS resolution for PE | `nslookup` / `Resolve-DnsName` | Private IP (`10.x.x.x`) |
| Portal access via PE | Browser from VNet | Portal loads, no public fallback |
| IP Firewall block | Access from unauthorized IP | HTTP 403 |
| MPE to Azure SQL | Notebook query | Succeeds, SQL audit shows private IP |
| Outbound policy block | Connect to undeclared destination | Connection refused |

<br>

**Performance notes:**

- Baseline **before** enabling PL/MVNet
- Spark custom pools: 3-5 min startup (vs seconds for Starter Pools)
- PE throughput: up to 8 Gbps per endpoint
- Cross-region: co-locate PEs with capacities to minimize latency

---
layout: section
---

# Architecture Patterns

---

# Feature Dependencies

<br>

| Chain | Steps |
|-------|-------|
| **Workspace Private Link** | Tenant setting → VNet + PE + DNS Zone → WS admin disables public access |
| **Workspace IP Firewall** | Tenant setting → WS admin adds IP ranges (no infra needed) |
| **Managed Private Endpoints** | F SKU → Managed VNet (auto) → MPE → Source owner approves PE |
| **Trusted Workspace Access** | F SKU → Workspace Identity → RBAC role → Resource Instance Rule |
| **Outbound Access Policies** | Managed VNet + MPE in place → Enable policy → Undeclared destinations blocked |
| **Full DEP** | Inbound (PL or IPFW or CA) + Outbound (OAP) |

---

# Scenario 1 — Regulated Enterprise

GDPR / HIPAA / PCI DSS

<br>

| Layer | Recommendation |
|-------|---------------|
| **Inbound** | Tenant PL + Block Public Access. All users on VPN/ER. |
| **Outbound** | MVNet + MPE + Outbound Policies on every workspace |
| **Identity** | Phishing-resistant MFA, compliant devices, PIM |
| **Data** | CMK + Purview labels + DLP. Disable Power BI exports. |
| **DNS** | Centralized zones in hub. DNS Private Resolver for hybrid. |
| **Monitoring** | Full Sentinel integration. Quarterly rule reviews. |

<br>

> Most restrictive. Disables Copilot, Publish to Web, some exports. Required when regulations mandate zero public internet traffic.

---

# Scenario 2 — Mixed Sensitivity

Central data platform team with varying workspace sensitivity levels.

<br>

| Layer | Recommendation |
|-------|---------------|
| **Inbound** | WS PL for sensitive workspaces. IP FW for semi-restricted. Public + CA for BI. |
| **Outbound** | TWA for ADLS Gen2. MPE for Azure SQL/Cosmos. VNet GW for Dataflows. |
| **Identity** | MFA for all. Device compliance for admin roles. |
| **Data** | CMK on sensitive workspaces. Labels propagated to reports. |
| **Monitoring** | Audit logs + PE failure alerts. |

<br>

> Best balance of security and usability. **Most common pattern** in enterprise deployments.

---

# Scenarios 3 & 4

<br>

**Scenario 3 — Startup (Cost-Optimized)**

| Layer | Choice |
|-------|--------|
| Inbound | Conditional Access + IP Firewall (no VNet) |
| Outbound | VNet GW or On-Prem GW |
| Data | Default encryption. Labels if M365 E5. |
| Monitoring | Entra sign-in logs + Fabric admin logs |

<br>

**Scenario 4 — Multi-Region Global**

| Layer | Choice |
|-------|--------|
| Inbound | WS PL per region (PEs co-located with capacity) |
| Outbound | Regional MVNets + MPE. Azure Firewall per hub. |
| Data | Regional Key Vaults + multi-geo residency |
| Monitoring | Regional Log Analytics → global Sentinel |

---
layout: section
---

# Feature Status & Roadmap

---

# Feature Summary — April 2026

<br>

| Feature | Scope | Status |
|---------|-------|--------|
| Entra Conditional Access | Tenant | **GA** |
| Private Link — Tenant | Tenant | **GA** |
| Private Link — Workspace | Workspace | **GA** |
| IP Firewall — Workspace | Workspace | **GA** |
| Trusted Workspace Access | Workspace | **GA** |
| Managed Private Endpoints | Workspace | **GA** |
| Managed VNets | Workspace | **GA** |
| VNet Data Gateway (+ proxy/cert) | Org | **GA** |
| Outbound Access Policies | Workspace | **GA** |
| Customer Managed Keys | Workspace | **GA** |
| Eventstream Private Network | Workspace | **Preview** |
| Power BI Network Isolation | Workspace | **Planned** |
| Fabric DB Network Isolation | Workspace | **Planned** |

---

# Known Limitations

<br>

| Item Type | WS PL | WS IP FW | Managed VNet | Outbound Policies | CMK |
|-----------|:---:|:---:|:---:|:---:|:---:|
| Lakehouse | GA | GA | GA | GA | GA |
| Warehouse | GA | GA | — | GA | GA |
| Notebook / Spark | GA | GA | GA | GA | GA |
| Pipeline / Dataflow | GA | GA | — | GA | GA |
| Eventstream | GA | GA | GA | GA | GA |
| Mirrored DB | GA | GA | — | GA | — |
| **Power BI** | Planned | Planned | — | Planned | Planned |
| **Fabric Databases** | Planned | Planned | — | Planned | Planned |
| **Data Activator** | Planned | Planned | — | — | — |

<br>

> Until Power BI and Fabric DB are covered, protect with **tenant-level PL** or **Conditional Access**.

---

# Key Takeaways

<br>

**Identity first** — Start with Conditional Access, MFA, PIM. Network controls complement identity, they don't replace it.

**Workspace-level preferred** — Use workspace PL/IPFW for sensitive workspaces. Reserve tenant PL for strict regulatory mandates.

**Layered defense** — Combine inbound + outbound + data controls for full DEP. No single control is sufficient.

**DNS is critical** — Private DNS Zones are the #1 failure point. Test resolution before go-live. Monitor for drift.

**Monitor everything** — Route logs to Sentinel. Review rules quarterly. Automate response with playbooks.

---
layout: intro
---

# Thank You

Network Security in Microsoft Fabric — April 2026

<br>

**References:**

- [Fabric Security Overview](https://learn.microsoft.com/en-us/fabric/security/security-overview)
- [Private Links](https://learn.microsoft.com/en-us/fabric/security/security-private-links-overview)
- [Managed VNets & PE](https://learn.microsoft.com/en-us/fabric/security/security-managed-vnets-fabric-overview)
- [Trusted Workspace Access](https://learn.microsoft.com/en-us/fabric/security/security-trusted-workspace-access)
- [IP Firewall Rules](https://learn.microsoft.com/en-us/fabric/security/security-ip-firewall-rules)
- [Fabric Security Whitepaper](https://aka.ms/FabricSecurityWhitepaper)
