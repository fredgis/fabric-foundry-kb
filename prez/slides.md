---
theme: seriph
title: Network Security in Microsoft Fabric
info: Architecture, Security & Best Practices — April 2026
class: text-center
transition: slide-left
mdc: true
drawings:
  persist: false
---

# Network Security in Microsoft Fabric

Architecture, Security & Best Practices

<div class="pt-6 text-gray-400">
April 2026
</div>

<style>
h1 {
  background: linear-gradient(135deg, #0078d4 0%, #00bcf2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
</style>

---
layout: two-cols
layoutClass: gap-8
---

# Agenda

<br>

<v-clicks>

**1.** Fabric Security Foundations

**2.** Inbound Protection

**3.** Secure Outbound Access

**4.** Outbound Protection & DEP

**5.** DNS Configuration

**6.** Monitoring & Auditing

**7.** Architecture Patterns

**8.** Feature Status & Roadmap

</v-clicks>

::right::

<br>
<br>

```mermaid {scale: 0.65}
flowchart TB
    subgraph In["Inbound"]
        CA["Conditional Access"]
        PL["Private Link"]
        FW["IP Firewall"]
    end
    subgraph Fabric["Microsoft Fabric"]
        WS["Workspaces"]
        OL["OneLake"]
    end
    subgraph Out["Outbound"]
        MPE["Managed PE"]
        TWA["TWA"]
        GW["Gateways"]
    end
    In --> Fabric --> Out
    style In fill:#e8eaf6,stroke:#3949ab
    style Fabric fill:#e3f2fd,stroke:#0078d4
    style Out fill:#e8f5e9,stroke:#2e7d32
```

---

# Three Pillars of Network Security

```mermaid {scale: 0.7}
flowchart LR
    subgraph Inbound["🛡️ Inbound Protection"]
        direction TB
        CA["Conditional Access"]
        TLPL["Private Link — Tenant"]
        WSPL["Private Link — Workspace"]
        IPFW["IP Firewall"]
    end
    subgraph Fabric["Microsoft Fabric"]
        direction TB
        WS["Workspaces"]
        OL["OneLake"]
    end
    subgraph Outbound["🔗 Secure Outbound"]
        direction TB
        TWA["Trusted WS Access"]
        MPE["Managed PE"]
        VGW["VNet Gateway"]
        OGW["On-Prem Gateway"]
    end
    subgraph Block["🚫 Outbound Protection"]
        OAP["Outbound Access Policies"]
    end
    Inbound --> Fabric
    Fabric --> Outbound
    Fabric --> Block
    style Inbound fill:#e8eaf6,stroke:#3949ab
    style Fabric fill:#e3f2fd,stroke:#0078d4
    style Outbound fill:#e8f5e9,stroke:#2e7d32
    style Block fill:#ffebee,stroke:#c62828
```

> **Inbound + Outbound Protection = Data Exfiltration Protection (DEP)**

---

# Secure by Default

No configuration needed — Fabric is secure out of the box.

<br>

```mermaid {scale: 0.65}
flowchart LR
    Client["Client"] -->|"TLS 1.2+"| Entra["Entra ID Auth"]
    Entra --> Fabric["Microsoft Fabric"]
    subgraph Fabric
        direction LR
        DF["Data Factory"] <-->|backbone| DE["Data Eng."]
        DE <-->|backbone| DW["Warehouse"]
        DW <-->|backbone| PBI["Power BI"]
        ALL["All"] <-->|private| OL["OneLake"]
    end
    style Client fill:#f3e5f5,stroke:#6a1b9a
    style Entra fill:#d1c4e9,stroke:#4527a0
    style Fabric fill:#e3f2fd,stroke:#0078d4
```

| Layer | Mechanism |
|-------|-----------|
| Authentication | Entra ID on every request |
| Transit encryption | TLS 1.2 min, 1.3 negotiated |
| Rest encryption | Microsoft-managed keys, all OneLake data |
| Internal traffic | Microsoft backbone only — never public internet |

---
layout: section
---

# Inbound Protection
Controlling access to Fabric

---

# Inbound Options at a Glance

<br>

| | Conditional Access | PL Tenant | PL Workspace | IP Firewall |
|---|:---:|:---:|:---:|:---:|
| **Scope** | Tenant | Tenant | Workspace | Workspace |
| **Infra needed** | None | VNet + PE | VNet + PE | None |
| **Complexity** | Low | High | Medium | Low |
| **Approach** | Zero Trust | Perimeter | Perimeter | IP-based |
| **User impact** | Transparent | VPN/ER mandatory | VPN/ER for target WS | None |
| **Status** | **GA** | **GA** | **GA** | **GA** |

<br>

> **Prerequisite:** Tenant admin must enable *Workspace-level inbound network rules* before WS admins can configure PL or IP FW per workspace.

---

# Entra Conditional Access

```mermaid {scale: 0.7}
flowchart LR
    User["User"] --> Signals["Signals\nIdentity · Location\nDevice · Risk"]
    Signals --> CA{"Conditional\nAccess"}
    CA -->|"Grant + MFA"| Fabric["Fabric"]
    CA -->|"Block"| Denied["Access Denied"]
    style User fill:#e1f5fe,stroke:#0277bd
    style Signals fill:#fff9c4,stroke:#f9a825
    style CA fill:#d1c4e9,stroke:#4527a0
    style Fabric fill:#c8e6c9,stroke:#2e7d32
    style Denied fill:#ef9a9a,stroke:#c62828
```

| Practice | Detail |
|----------|--------|
| **Phishing-resistant MFA** | FIDO2, Windows Hello, cert-based |
| **Device compliance** | Require Intune-managed devices |
| **PIM** | Just-in-time admin elevation |
| **CAE** | Near-real-time token revocation |

**Prerequisite:** Entra ID P1 (included in M365 E3/E5)

---

# Private Link — Tenant vs Workspace

```mermaid {scale: 0.55}
flowchart TB
    subgraph TenantPL["Tenant PL — All or Nothing"]
        CorpA["Corp Users\n(VPN/ER)"] --> PE_T["Tenant PE"]
        PE_T --> TFabric["Entire Tenant\n🔒 All Locked"]
        Internet1["Internet"] -.->|"Blocked"| TFabric
    end
    subgraph WorkspacePL["Workspace PL — Granular ★"]
        CorpB["Corp Users\n(VPN/ER)"] --> PE_W1["PE → WS1"]
        CorpB --> PE_W2["PE → WS2"]
        PE_W1 --> WS1["WS1 Data Eng.\n🔒 Private"]
        PE_W2 --> WS2["WS2 Warehouse\n🔒 Private"]
        Internet2["Internet"] -->|"CA OK"| WS3["WS3 BI\n🌐 Public"]
        Internet2 -.->|"Blocked"| WS1
    end
    style TenantPL fill:#fff3e0,stroke:#e65100
    style WorkspacePL fill:#e8f5e9,stroke:#2e7d32
    style TFabric fill:#ffe0b2,stroke:#e65100
    style WS1 fill:#c8e6c9,stroke:#2e7d32
    style WS2 fill:#c8e6c9,stroke:#2e7d32
    style WS3 fill:#fff9c4,stroke:#f9a825
```

| | Tenant PL | Workspace PL ★ |
|---|---|---|
| **Scope** | Entire tenant | Per workspace |
| **Impact** | All users need VPN/ER | Only users of protected WS |
| **Limitations** | Copilot disabled, exports limited | Power BI items not yet covered |
| **Best for** | Strict regulation | Most organizations |

---

# Workspace IP Firewall

```mermaid {scale: 0.7}
flowchart LR
    IP1["Paris Office\n203.0.113.0/24"] -->|"✅ Allowed"| FW{"IP Firewall"}
    IP2["London Office\n198.51.100.0/24"] -->|"✅ Allowed"| FW
    IP3["Unknown IP"] -.->|"❌ Blocked"| FW
    FW --> WS["Fabric Workspace"]
    style IP1 fill:#c8e6c9,stroke:#2e7d32
    style IP2 fill:#c8e6c9,stroke:#2e7d32
    style IP3 fill:#ef9a9a,stroke:#c62828
    style FW fill:#fff9c4,stroke:#f9a825
    style WS fill:#bbdefb,stroke:#1565c0
```

- **GA Q1 2026** — Lakehouse, Warehouse, Notebook, Pipeline, Dataflow, Eventstream, Mirrored DB
- No Azure infrastructure needed
- Fabric REST API stays accessible (by design — prevents lockout)
- Power BI items and Fabric DBs **not covered** (planned)

---

# Tenant ↔ Workspace Interaction

| Tenant Public | WS PL | WS IP FW | Portal | API |
|:---:|:---:|:---:|---|---|
| Allowed | — | — | Public | Public |
| Allowed | ✅ | — | WS PL only | WS PL only |
| Allowed | — | ✅ | Allowed IPs | Allowed IPs |
| Restricted | — | — | Tenant PL | Tenant PL |
| Restricted | ✅ | — | Tenant PL | WS PL or Tenant PL |
| Restricted | — | ✅ | Tenant PL | Tenant PL |

<br>

> When tenant access is **restricted**, tenant PL takes precedence for portal. Workspace PL adds API paths only.

---
layout: section
---

# Secure Outbound Access
Connecting Fabric to protected data sources

---

# Outbound Connectors

```mermaid {scale: 0.6}
flowchart LR
    subgraph Fabric["Microsoft Fabric"]
        NB["Notebook"]
        PL["Pipeline"]
        SM["Semantic Model"]
        DF["Dataflow Gen2"]
    end
    subgraph Methods["Connection Methods"]
        TWA["Trusted WS\nAccess"]
        MPE["Managed PE\n(in Managed VNet)"]
        VGW["VNet Data\nGateway"]
        OGW["On-Prem\nGateway"]
    end
    subgraph Sources["Data Sources"]
        ADLS["ADLS Gen2\n🔒 Firewall"]
        SQL["Azure SQL\n🔒 Private"]
        SQLMI["SQL MI\n(in VNet)"]
        OnPrem["SQL Server\nSAP · Oracle"]
    end
    PL --> TWA --> ADLS
    NB --> MPE --> SQL
    SM --> VGW --> SQLMI
    DF --> OGW --> OnPrem
    style Fabric fill:#e3f2fd,stroke:#0078d4
    style Methods fill:#e8f5e9,stroke:#2e7d32
    style Sources fill:#fff3e0,stroke:#e65100
```

| Method | Sources | Workloads |
|--------|---------|-----------|
| **TWA** | ADLS Gen2 (firewall) | Shortcuts, Pipelines, COPY INTO |
| **Managed PE** | Azure SQL, Cosmos DB, Key Vault | Spark, Lakehouses, Eventstream |
| **VNet GW** | Azure services in VNet | Dataflows Gen2, Semantic Models |
| **On-Prem GW** | SQL Server, Oracle, SAP | Dataflows, Semantic Models, Pipelines |

---

# Trusted Workspace Access — Prerequisites

```mermaid {scale: 0.65}
flowchart LR
    FSKU["F SKU\nCapacity"] --> WI["Workspace\nIdentity"]
    WI --> RBAC["RBAC on\nADLS Gen2"]
    RBAC --> RIR["Resource\nInstance Rule"]
    RIR --> ADLS["ADLS Gen2\n🔒 Firewall"]
    style FSKU fill:#ffe0b2,stroke:#e65100
    style WI fill:#e1bee7,stroke:#6a1b9a
    style RBAC fill:#e1bee7,stroke:#6a1b9a
    style RIR fill:#c8e6c9,stroke:#2e7d32
    style ADLS fill:#fff3e0,stroke:#e65100
```

All **four** prerequisites are required:

1. Workspace on **Fabric F SKU** (not Trial or P SKU)
2. **Workspace Identity** created and enabled
3. **RBAC role** on storage: `Storage Blob Data Contributor/Owner/Reader`
4. **Resource Instance Rule** on storage firewall (ARM / Bicep / PowerShell)

> ⚠️ Failure at any step **silently blocks** access — no error, just empty results.

---

# Managed Private Endpoints

```mermaid {scale: 0.65}
flowchart LR
    subgraph Fabric["Microsoft Fabric"]
        subgraph MVNET["Managed VNet (auto-provisioned)"]
            Spark["Spark"]
            MPE1["MPE → SQL"]
            MPE2["MPE → ADLS"]
        end
    end
    SQL["Azure SQL\n🔒 Firewall"]
    ADLS["ADLS Gen2\n🔒 Private"]
    Spark --> MPE1 -->|"Private Link"| SQL
    Spark --> MPE2 -->|"Private Link"| ADLS
    style Fabric fill:#e3f2fd,stroke:#0078d4
    style MVNET fill:#bbdefb,stroke:#1565c0
    style Spark fill:#90caf9,stroke:#0d47a1
    style MPE1 fill:#c8e6c9,stroke:#2e7d32
    style MPE2 fill:#c8e6c9,stroke:#2e7d32
    style SQL fill:#ffe0b2,stroke:#e65100
    style ADLS fill:#ffe0b2,stroke:#e65100
```

- Managed VNet auto-provisioned on first MPE or Spark job
- Source owner must **approve** the PE
- All traffic on Microsoft backbone
- **Limitations:** Starter Pools disabled (3-5 min startup), not all regions

---

# Data Gateways

```mermaid {scale: 0.65}
flowchart TB
    subgraph Fabric["Fabric"]
        DF["Dataflows Gen2"]
        SM["Semantic Models"]
    end
    subgraph OnPrem["On-Premises"]
        OGW["On-Prem Gateway"]
        SQLSrv["SQL Server"]
        SAP["SAP"]
    end
    subgraph Azure["Azure VNet"]
        VGW["VNet Data Gateway"]
        SQLMI["Azure SQL MI"]
    end
    DF --> OGW --> SQLSrv
    OGW --> SAP
    SM --> VGW --> SQLMI
    style Fabric fill:#e3f2fd,stroke:#0078d4
    style OnPrem fill:#e0f2f1,stroke:#00695c
    style Azure fill:#e8eaf6,stroke:#283593
    style OGW fill:#80cbc4,stroke:#00695c
    style VGW fill:#b39ddb,stroke:#4527a0
```

| | On-Premises GW | VNet Data GW |
|---|---|---|
| Management | Manual | Managed by Microsoft |
| Sources | Any on-prem | Azure VNet services |
| **Proxy + Cert Auth** | — | **GA** (2026) |

---
layout: section
---

# Outbound Protection & DEP
Preventing data exfiltration

---

# Outbound Access Policies + DEP

```mermaid {scale: 0.6}
flowchart LR
    ExtUser["Unauthorized\nUser"] -.->|"Blocked"| Inbound["Inbound\nPL / IPFW / CA"]
    IntUser["Authorized\nUser"] -->|"Private Link"| Inbound
    Inbound --> Fabric["Fabric WS"]
    Fabric --> OAP{"Outbound\nPolicy"}
    OAP -->|"Declared dest."| Corp["Corporate\nADLS Gen2"]
    OAP -.->|"Blocked"| Unknown["Unknown\nEndpoint"]
    style ExtUser fill:#ef9a9a,stroke:#c62828
    style IntUser fill:#c8e6c9,stroke:#2e7d32
    style Inbound fill:#c5cae9,stroke:#1a237e
    style Fabric fill:#90caf9,stroke:#0d47a1
    style OAP fill:#fff9c4,stroke:#f9a825
    style Corp fill:#c8e6c9,stroke:#2e7d32
    style Unknown fill:#ef9a9a,stroke:#c62828
```

**DEP = Inbound + Outbound.** Complementary data controls:

| Control | Mechanism |
|---------|-----------|
| Purview labels | Sensitivity labels across all Fabric items |
| DLP | Block export of classified data |
| PBI export restrictions | Disable CSV/Excel/PPT export |
| Endpoint DLP | Block USB / unauthorized cloud copy |
| Defender session | Monitor & block downloads in real time |

---
layout: section
---

# DNS Configuration
The #1 Private Link failure point

---

# DNS — Required Zones & Architecture

```mermaid {scale: 0.55}
flowchart LR
    subgraph OnPrem["On-Premises"]
        DNS["DNS Servers"]
    end
    subgraph Azure["Azure"]
        Resolver["DNS Private\nResolver"]
        PDNS["Private DNS Zones\n*.analysis.windows.net\n*.pbidedicated.windows.net\n*.dfs.core.windows.net"]
    end
    PE["Private Endpoints\n(10.x.x.x)"]
    DNS -->|"Conditional\nForwarder"| Resolver --> PDNS -->|"Private IP"| PE
    style OnPrem fill:#e0f2f1,stroke:#00695c
    style Azure fill:#e8eaf6,stroke:#283593
    style PE fill:#c8e6c9,stroke:#2e7d32
```

| Zone | Used By |
|------|---------|
| `privatelink.analysis.windows.net` | Power BI / Semantic Models |
| `privatelink.pbidedicated.windows.net` | Dedicated capacity |
| `privatelink.dfs.core.windows.net` | OneLake (DFS) |
| `privatelink.blob.core.windows.net` | OneLake (Blob) |
| `privatelink.servicebus.windows.net` | Event Hubs |

> Missing DNS zones = traffic bypasses PE silently. Always `nslookup` → expect `10.x.x.x`.

---

# DNS Best Practices

<v-clicks>

1. **Create all zones** + link to every VNet hosting PEs
2. **Test:** `Resolve-DnsName <ws>.pbidedicated.windows.net` → private IP
3. **Hybrid:** conditional forwarders → Azure DNS (`168.63.129.16`) via Private Resolver
4. **Automate:** Azure Policy `Deploy-DINE-PrivateDNSZoneGroup` for DNS records
5. **Monitor:** re-test after infra changes — broken links revert silently to public

</v-clicks>

<br>

**IP Planning:** 1 PE = 1 IP. Reserve `/27` (32 IPs) minimum for Fabric PEs.

---
layout: section
---

# Monitoring & Auditing

---

# Monitoring Stack

```mermaid {scale: 0.6}
flowchart LR
    subgraph Sources["Log Sources"]
        E["Entra Logs"]
        F["Fabric Audit"]
        P["PE Metrics"]
        N["NSG Flows"]
    end
    LA["Log Analytics"] --> Sentinel["Microsoft Sentinel"]
    LA --> Alerts["Azure Monitor\nAlerts"]
    Sentinel --> Play["Playbooks\n(auto-response)"]
    Sources --> LA
    style Sources fill:#e0f7fa,stroke:#00838f
    style LA fill:#e8eaf6,stroke:#283593
    style Sentinel fill:#c5cae9,stroke:#1a237e
    style Alerts fill:#fff9c4,stroke:#f9a825
    style Play fill:#ef9a9a,stroke:#c62828
```

| Review | Frequency | Owner |
|--------|-----------|-------|
| IP FW rules | Monthly | WS admin |
| Outbound allowed destinations | Quarterly | Security |
| PE approvals | Quarterly | Azure sub owner |
| CA effectiveness | Quarterly | Identity team |
| DNS records | Semi-annually | Network team |

---
layout: section
---

# Architecture Patterns

---

# Feature Dependencies

```mermaid {scale: 0.55}
flowchart TD
    FSKU["F SKU"] --> TWA["TWA"]
    FSKU --> MVNET["Managed VNet"]
    TS["Tenant Setting:\nWS Inbound Rules"] --> WSPL["WS Private Link"]
    TS --> IPFW["WS IP Firewall"]
    P1["Entra P1"] --> CA["Conditional Access"]
    MVNET --> MPE["Managed PE"]
    MPE --> OAP["Outbound Policies"]
    VNet["Customer VNet"] --> PE["PE"] --> WSPL
    DNS["Private DNS"] --> WSPL
    WI["WS Identity"] --> TWA
    RBAC["RBAC"] --> TWA
    style FSKU fill:#ffe0b2,stroke:#e65100
    style TS fill:#ffe0b2,stroke:#e65100
    style P1 fill:#ffe0b2,stroke:#e65100
    style WSPL fill:#c5cae9,stroke:#1a237e
    style IPFW fill:#c5cae9,stroke:#1a237e
    style CA fill:#d1c4e9,stroke:#4527a0
    style TWA fill:#c8e6c9,stroke:#2e7d32
    style MVNET fill:#c8e6c9,stroke:#2e7d32
    style MPE fill:#c8e6c9,stroke:#2e7d32
    style OAP fill:#ef9a9a,stroke:#c62828
    style VNet fill:#b2dfdb,stroke:#00695c
    style PE fill:#b2dfdb,stroke:#00695c
    style DNS fill:#b2dfdb,stroke:#00695c
    style WI fill:#e1bee7,stroke:#6a1b9a
    style RBAC fill:#e1bee7,stroke:#6a1b9a
```

| Chain | Steps |
|-------|-------|
| **WS PL** | Tenant setting → VNet + PE + DNS → disable public |
| **MPE** | F SKU → MVNet (auto) → MPE → source approves |
| **TWA** | F SKU → WS Identity → RBAC → Resource Instance Rule |

---

# End-to-End Architecture — Workspace-Level

```mermaid {scale: 0.45}
flowchart TB
    subgraph Corp["Corporate Network"]
        Users["Users"]
        ERVPN["ER / VPN"]
    end
    subgraph Azure["Customer Azure"]
        subgraph Spoke["Spoke VNet"]
            PE1["PE → WS1"]
            PE2["PE → WS2"]
        end
        PDNS["Private DNS Zones"]
    end
    subgraph Entra["Entra ID"]
        CA["Conditional Access"]
    end
    subgraph Fabric["Microsoft Fabric Tenant"]
        subgraph WS1["WS1 Data Eng 🔒"]
            LH["Lakehouse"]
            NB["Notebook"]
        end
        subgraph WS2["WS2 Warehouse 🔒"]
            WH["Warehouse"]
        end
        subgraph WS3["WS3 BI 🌐"]
            RPT["Reports"]
        end
        subgraph OutB["Outbound"]
            MPE["Managed PE"]
            TWA["TWA"]
        end
    end
    subgraph Data["Data Sources"]
        SQL["Azure SQL"]
        ADLS["ADLS Gen2"]
    end
    Users --> ERVPN --> Spoke
    PE1 --> WS1
    PE2 --> WS2
    PDNS -.-> PE1
    PDNS -.-> PE2
    Users --> CA -->|"MFA OK"| WS3
    MPE -->|"Private Link"| SQL
    TWA -->|"Workspace ID"| ADLS
    style Corp fill:#e0f2f1,stroke:#00695c
    style Azure fill:#e8eaf6,stroke:#283593
    style Entra fill:#d1c4e9,stroke:#4527a0
    style Fabric fill:#e3f2fd,stroke:#0078d4
    style WS1 fill:#c8e6c9,stroke:#2e7d32
    style WS2 fill:#c8e6c9,stroke:#2e7d32
    style WS3 fill:#fff9c4,stroke:#f9a825
    style OutB fill:#e8f5e9,stroke:#2e7d32
    style Data fill:#fff3e0,stroke:#e65100
```

> **Workspace-level** = protect sensitive WS only. Tenant PL possible but more restrictive.

---

# Scenario 1 — Regulated Enterprise

<span class="text-sm text-gray-400">GDPR / HIPAA / PCI DSS</span>

| Layer | Recommendation |
|-------|---------------|
| **Inbound** | Tenant PL + Block Public. All users VPN/ER. |
| **Outbound** | MVNet + MPE + Outbound Policies everywhere |
| **Identity** | Phishing-resistant MFA + PIM + compliant devices |
| **Data** | CMK + Purview labels + DLP. Disable PBI exports. |
| **DNS** | Centralized zones + DNS Private Resolver |
| **Monitoring** | Full Sentinel. Quarterly reviews. |

> Most restrictive. Disables Copilot, Publish to Web, some exports.

---

# Scenario 2 — Mixed Sensitivity ★

<span class="text-sm text-gray-400">Most common pattern</span>

| Layer | Recommendation |
|-------|---------------|
| **Inbound** | WS PL (sensitive) + IP FW (semi) + Public+CA (BI) |
| **Outbound** | TWA for ADLS. MPE for SQL/Cosmos. VNet GW for DF. |
| **Identity** | MFA all. Device compliance for admins. |
| **Data** | CMK on sensitive WS. Labels to reports. |
| **Monitoring** | Audit logs + PE failure alerts |

> Best balance of security and usability for enterprise data platforms.

---

# Scenarios 3 & 4

<div class="grid grid-cols-2 gap-8">
<div>

### Startup — Cost-Optimized

| Layer | Choice |
|-------|--------|
| Inbound | CA + IP Firewall |
| Outbound | VNet GW / On-Prem GW |
| Data | Default encryption |
| Monitoring | Entra + Fabric logs |

<span class="text-sm text-gray-400">No VNet infra. Minimal cost.</span>

</div>
<div>

### Multi-Region Global

| Layer | Choice |
|-------|--------|
| Inbound | WS PL per region |
| Outbound | Regional MVNet + MPE |
| Data | Regional KV + multi-geo |
| Monitoring | Regional LA → Sentinel |

<span class="text-sm text-gray-400">PEs co-located with capacity.</span>

</div>
</div>

---
layout: section
---

# Feature Status & Roadmap
April 2026

---

# Feature Summary

| Feature | Scope | Status |
|---------|-------|:---:|
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
| Eventstream Private Network | Workspace | *Preview* |
| Power BI Network Isolation | Workspace | *Planned* |
| Fabric DB Network Isolation | Workspace | *Planned* |

---

# Known Limitations

| Item | WS PL | IP FW | MVNet | Outbound | CMK |
|------|:---:|:---:|:---:|:---:|:---:|
| Lakehouse | ✅ | ✅ | ✅ | ✅ | ✅ |
| Warehouse | ✅ | ✅ | — | ✅ | ✅ |
| Notebook / Spark | ✅ | ✅ | ✅ | ✅ | ✅ |
| Pipeline / Dataflow | ✅ | ✅ | — | ✅ | ✅ |
| Eventstream | ✅ | ✅ | ✅ | ✅ | ✅ |
| Mirrored DB | ✅ | ✅ | — | ✅ | — |
| **Power BI** | 🔜 | 🔜 | — | 🔜 | 🔜 |
| **Fabric DBs** | 🔜 | 🔜 | — | 🔜 | 🔜 |
| **Data Activator** | 🔜 | 🔜 | — | — | — |

> Until PBI/DBs covered → protect with **tenant PL** or **Conditional Access**.

---

# Key Takeaways

<br>

**Identity first** — CA + MFA + PIM before network controls

**Workspace-level ★** — PL/IPFW per workspace, not tenant-wide

**Layered defense** — Inbound + Outbound + Data = full DEP

**DNS is #1 failure** — Private DNS Zones, test with `nslookup`, monitor drift

**Monitor everything** — Sentinel + playbooks + quarterly reviews

<br>

---
layout: center
class: text-center
---

# Thank You

<br>

Network Security in Microsoft Fabric — April 2026

<br>

[Fabric Security Overview](https://learn.microsoft.com/en-us/fabric/security/security-overview) ·
[Private Links](https://learn.microsoft.com/en-us/fabric/security/security-private-links-overview) ·
[Managed VNets](https://learn.microsoft.com/en-us/fabric/security/security-managed-vnets-fabric-overview)

[TWA](https://learn.microsoft.com/en-us/fabric/security/security-trusted-workspace-access) ·
[IP Firewall](https://learn.microsoft.com/en-us/fabric/security/security-ip-firewall-rules) ·
[Whitepaper](https://aka.ms/FabricSecurityWhitepaper)
