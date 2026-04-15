---
theme: seriph
background: https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=1920
title: "Network Security in Microsoft Fabric"
info: |
  ## Network Configurations in Microsoft Fabric
  Architecture, Security & Best Practices — April 2026
class: text-center
drawings:
  persist: false
transition: slide-left
mdc: true
lineNumbers: false
---

# Network Security in Microsoft Fabric

Architecture, Security & Best Practices

<div class="abs-br m-6 flex gap-2">
  <span class="text-sm opacity-50">April 2026</span>
</div>

<style>
h1 {
  background-color: #2B90B6;
  background-image: linear-gradient(45deg, #4EC5D4 10%, #146b8c 20%);
  background-size: 100%;
  -webkit-background-clip: text;
  -moz-background-clip: text;
  -webkit-text-fill-color: transparent;
  -moz-text-fill-color: transparent;
}
</style>

---
transition: fade-out
layout: two-cols
layoutClass: gap-16
---

# Agenda

<v-clicks>

1. 🔐 Fabric Security Foundations
2. 🛡️ Inbound Protection
3. 🔗 Secure Outbound Access
4. 🚫 Outbound Protection & DEP
5. 🔑 Data Security & Encryption
6. 🌐 DNS Configuration
7. 📊 Monitoring & Auditing
8. ✅ Testing & Validation
9. 🏗️ Architecture Patterns
10. 📋 Feature Status & Roadmap

</v-clicks>

::right::

<div class="mt-12">

```mermaid
pie title Security Pillars
    "Inbound Protection" : 30
    "Outbound Security" : 30
    "Data Protection" : 20
    "Monitoring" : 20
```

</div>

---
layout: section
---

# Fabric Security Foundations
Understanding the baseline

---
layout: default
---

# What is Microsoft Fabric?

A **unified SaaS analytics platform** bringing together:

<div class="grid grid-cols-3 gap-4 mt-4">

<div class="bg-blue-50 p-4 rounded-lg text-center border border-blue-200">
  <div class="text-2xl mb-2">🏭</div>
  <div class="font-bold text-blue-800">Data Factory</div>
  <div class="text-xs text-gray-600">ETL & Orchestration</div>
</div>

<div class="bg-blue-50 p-4 rounded-lg text-center border border-blue-200">
  <div class="text-2xl mb-2">⚙️</div>
  <div class="font-bold text-blue-800">Data Engineering</div>
  <div class="text-xs text-gray-600">Spark & Notebooks</div>
</div>

<div class="bg-blue-50 p-4 rounded-lg text-center border border-blue-200">
  <div class="text-2xl mb-2">🧬</div>
  <div class="font-bold text-blue-800">Data Science</div>
  <div class="text-xs text-gray-600">ML & Experiments</div>
</div>

<div class="bg-blue-50 p-4 rounded-lg text-center border border-blue-200">
  <div class="text-2xl mb-2">🏢</div>
  <div class="font-bold text-blue-800">Data Warehouse</div>
  <div class="text-xs text-gray-600">SQL Analytics</div>
</div>

<div class="bg-blue-50 p-4 rounded-lg text-center border border-blue-200">
  <div class="text-2xl mb-2">⚡</div>
  <div class="font-bold text-blue-800">Real-Time Intelligence</div>
  <div class="text-xs text-gray-600">Streaming & KQL</div>
</div>

<div class="bg-yellow-50 p-4 rounded-lg text-center border border-yellow-200">
  <div class="text-2xl mb-2">📊</div>
  <div class="font-bold text-yellow-800">Power BI</div>
  <div class="text-xs text-gray-600">Reports & Dashboards</div>
</div>

</div>

<div class="mt-4 p-3 bg-cyan-50 rounded-lg border border-cyan-200 text-center">
  <strong>OneLake</strong> — Unified data lake for all experiences
</div>

---

# Three Pillars of Network Security

<div class="grid grid-cols-3 gap-6 mt-8">

<div class="bg-indigo-50 p-6 rounded-xl border-2 border-indigo-300 shadow-lg">
  <div class="text-3xl text-center mb-3">🛡️</div>
  <h3 class="text-center text-indigo-800 font-bold">Inbound Protection</h3>
  <p class="text-sm mt-2 text-gray-700">Control <strong>who</strong> accesses Fabric and <strong>from where</strong></p>
  <ul class="text-xs mt-2 text-gray-600">
    <li>Conditional Access</li>
    <li>Private Links</li>
    <li>IP Firewall</li>
  </ul>
</div>

<div class="bg-green-50 p-6 rounded-xl border-2 border-green-300 shadow-lg">
  <div class="text-3xl text-center mb-3">🔗</div>
  <h3 class="text-center text-green-800 font-bold">Secure Outbound</h3>
  <p class="text-sm mt-2 text-gray-700">Connect Fabric to <strong>protected data sources</strong> securely</p>
  <ul class="text-xs mt-2 text-gray-600">
    <li>Trusted Workspace Access</li>
    <li>Managed Private Endpoints</li>
    <li>Data Gateways</li>
  </ul>
</div>

<div class="bg-red-50 p-6 rounded-xl border-2 border-red-300 shadow-lg">
  <div class="text-3xl text-center mb-3">🚫</div>
  <h3 class="text-center text-red-800 font-bold">Outbound Protection</h3>
  <p class="text-sm mt-2 text-gray-700">Prevent data <strong>exfiltration</strong> to unauthorized destinations</p>
  <ul class="text-xs mt-2 text-gray-600">
    <li>Outbound Access Policies</li>
    <li>Allowed destinations only</li>
  </ul>
</div>

</div>

<div class="mt-6 text-center">
  <div class="inline-block bg-purple-100 px-6 py-2 rounded-full border border-purple-300">
    <strong>Inbound + Outbound = Data Exfiltration Protection (DEP)</strong>
  </div>
</div>

---

# Secure by Default

Fabric is **secure out of the box** — no configuration needed:

| Feature | Detail |
|---------|--------|
| **Authentication** | Every interaction authenticated via **Microsoft Entra ID** |
| **Encryption in transit** | TLS 1.2 minimum (TLS 1.3 negotiated when available) |
| **Encryption at rest** | All OneLake data automatically encrypted |
| **Microsoft backbone** | Internal Fabric traffic never traverses the public internet |
| **Secure endpoints** | Fabric backend protected by VNet, not directly accessible |

<div class="mt-4 p-3 bg-green-50 rounded-lg border border-green-300">
💡 <strong>Key point:</strong> Even without any configuration, Fabric provides enterprise-grade security. The features that follow add <em>additional</em> layers.
</div>

---
layout: section
---

# Inbound Protection
Controlling access to Fabric

---

# Inbound Options at a Glance

| Criteria | Conditional Access | Private Link (Tenant) | Private Link (Workspace) | IP Firewall |
|----------|:--:|:--:|:--:|:--:|
| **Granularity** | Tenant | Tenant | Workspace | Workspace |
| **Azure infra needed** | No | VNet + PE | VNet + PE | No |
| **Complexity** | Low | High | Medium | Low |
| **Approach** | Zero Trust | Perimeter | Perimeter | IP-based |
| **User impact** | Transparent | VPN/ER required | VPN/ER for protected WS | None if IP allowed |
| **Status** | **GA** | **GA** | **GA** | **GA** |

<div class="mt-4 p-3 bg-amber-50 rounded-lg border border-amber-300">
⚠️ <strong>Prerequisite:</strong> A <strong>tenant admin</strong> must enable "Workspace-level inbound network rules" before WS admins can configure Private Link or IP Firewall per workspace.
</div>

---

# Entra Conditional Access — Zero Trust

The **first gate** for every request to Fabric.

<div class="grid grid-cols-2 gap-6 mt-4">

<div>

**Evaluated Signals:**
- 👤 Users and groups
- 📍 Location / IP ranges
- 💻 Device compliance (Intune)
- 📱 Applications
- ⚠️ Sign-in risk level

**Decisions:**
- ✅ Grant
- ✅ Grant + MFA
- 🚫 Block

</div>

<div>

**Zero Trust Best Practices:**

| Practice | Description |
|----------|-------------|
| **Phishing-resistant MFA** | FIDO2, Windows Hello |
| **Device Compliance** | Require managed devices |
| **PIM** | Just-in-time admin access |
| **Service Principal Gov.** | Limit SPN surface area |
| **CAE** | Real-time token revocation |

</div>

</div>

<div class="mt-2 p-2 bg-purple-50 rounded border border-purple-200 text-sm">
📋 <strong>Prerequisite:</strong> Microsoft Entra ID P1 license (included in M365 E3/E5)
</div>

---

# Tenant-Level Private Link

**Full tenant** network isolation — Fabric becomes inaccessible from the public internet.

<div class="grid grid-cols-2 gap-6 mt-4">

<div>

**How it works:**
1. Create Private Endpoint in customer VNet
2. Private tunnel to Fabric via Microsoft backbone
3. Enable "Block Public Internet Access"

**Two settings:**

| Setting | Effect |
|---------|--------|
| Azure Private Links | VNet traffic goes through PL |
| Block Public Access | No public internet access |

</div>

<div>

**Considerations:**
- ⚠️ **All users** must use VPN/ExpressRoute
- ⚠️ Bandwidth impact (static resources via PE)
- ⚠️ Copilot, Publish to Web **disabled**
- ⚠️ Spark Starter Pools disabled
- ⚠️ Cross-tenant access not supported
- ⚠️ **Private DNS Zone required**

</div>

</div>

<div class="mt-3 p-3 bg-orange-50 rounded-lg border border-orange-300 text-sm">
🔒 <strong>Best for:</strong> Regulated industries (healthcare, finance) where NO Fabric traffic may traverse the public internet. Most restrictive option — consider workspace-level PL first.
</div>

---

# Workspace-Level Private Link
<span class="text-green-600 font-bold">★ Recommended Approach</span>

**Granular** control: protect only sensitive workspaces while others remain publicly accessible.

<div class="grid grid-cols-2 gap-6 mt-4">

<div>

**Key characteristics:**
- 1:1 relationship: workspace ↔ PL Service
- Multiple PEs from different VNets
- Public access disabled **per workspace**
- GA since September 2025

**Supported items:**
- ✅ Lakehouse, Warehouse, Notebook
- ✅ Pipeline, Dataflow, Eventstream
- ✅ Mirrored DB, ML Experiment/Model
- ❌ Power BI Reports/Dashboards *(planned)*
- ❌ Fabric Databases *(planned)*

</div>

<div>

```mermaid
flowchart TB
    VNet["Customer VNet"]
    PE1["PE → WS1"]
    PE2["PE → WS2"]
    WS1["Workspace 1\n🔒 Private Only"]
    WS2["Workspace 2\n🔒 Private Only"]
    WS3["Workspace 3\n🌐 Public (CA)"]

    VNet --> PE1 --> WS1
    VNet --> PE2 --> WS2
    Internet["Internet"] -.->|Blocked| WS1
    Internet -->|CA OK| WS3
```

</div>

</div>

---

# Workspace IP Firewall

The **simplest** solution — no Azure infrastructure required.

<div class="grid grid-cols-2 gap-6 mt-4">

<div>

**Concept:** Allow only specific IP ranges to access the workspace.

**GA since Q1 2026** — supported items:
- ✅ Lakehouse, Notebook, Pipeline
- ✅ Warehouse, Dataflow, Eventstream
- ✅ Mirrored DB, ML Experiment/Model
- ❌ Power BI items *(planned)*
- ❌ Fabric Databases *(planned)*

**Important notes:**
- Fabric REST API remains accessible for rule management (by design)
- Use Conditional Access to govern API access

</div>

<div>

```mermaid
flowchart LR
    IP1["Paris Office\n203.0.113.0/24"] -->|✅| FW{"IP Firewall"}
    IP2["London Office\n198.51.100.0/24"] -->|✅| FW
    IP3["Unknown IP"] -.->|❌| FW
    FW --> WS["Fabric\nWorkspace"]
```

<div class="mt-4 p-3 bg-blue-50 rounded border border-blue-200 text-sm">
💡 <strong>Best for:</strong> Organizations with static office IPs, no VNet infrastructure, need quick protection.
</div>

</div>

</div>

---

# Tenant vs Workspace Access Interaction

When both tenant-level and workspace-level settings are configured:

| Tenant Public Access | WS Private Link | WS IP Firewall | Portal Access | API Access |
|:---:|:---:|:---:|---|---|
| **Allowed** | — | — | Public | Public |
| **Allowed** | ✅ (public disabled) | — | WS PL only | WS PL only |
| **Allowed** | — | ✅ | Allowed IPs | Allowed IPs |
| **Restricted** | — | — | Tenant PL only | Tenant PL only |
| **Restricted** | ✅ | — | Tenant PL only | WS PL or Tenant PL |
| **Restricted** | — | ✅ | Tenant PL only | Tenant PL only |

<div class="mt-4 p-3 bg-amber-50 rounded-lg border border-amber-300 text-sm">
⚠️ <strong>Key takeaway:</strong> When tenant public access is <strong>restricted</strong>, tenant Private Link takes precedence for portal access. Workspace PL only adds API-level paths — it does not bypass the tenant restriction for the Fabric portal.
</div>

---
layout: section
---

# Secure Outbound Access
Connecting Fabric to protected data sources

---

# Outbound Options Overview

<div class="grid grid-cols-2 gap-4 mt-4">

<div class="bg-green-50 p-4 rounded-lg border border-green-200">
<h3 class="text-green-800">🔐 Trusted Workspace Access</h3>
<p class="text-sm">Access firewall-enabled <strong>ADLS Gen2</strong> via workspace identity + Resource Instance Rules</p>
<div class="text-xs mt-2 text-gray-600">Shortcuts, Pipelines, COPY INTO, Semantic Models</div>
</div>

<div class="bg-green-50 p-4 rounded-lg border border-green-200">
<h3 class="text-green-800">🔗 Managed Private Endpoints</h3>
<p class="text-sm">Private Link to Azure SQL, Cosmos DB, Key Vault etc. in a <strong>Managed VNet</strong></p>
<div class="text-xs mt-2 text-gray-600">Spark Notebooks, Lakehouses, Spark Jobs, Eventstream</div>
</div>

<div class="bg-blue-50 p-4 rounded-lg border border-blue-200">
<h3 class="text-blue-800">🌐 VNet Data Gateway</h3>
<p class="text-sm">Managed gateway in customer VNet. <strong>GA:</strong> enterprise proxy + cert auth</p>
<div class="text-xs mt-2 text-gray-600">Dataflows Gen2, Semantic Models</div>
</div>

<div class="bg-teal-50 p-4 rounded-lg border border-teal-200">
<h3 class="text-teal-800">🏢 On-Premises Gateway</h3>
<p class="text-sm">Bridge to on-prem SQL Server, Oracle, SAP, file shares</p>
<div class="text-xs mt-2 text-gray-600">Dataflows Gen2, Semantic Models, Pipelines</div>
</div>

</div>

---

# Trusted Workspace Access

Secure access to **firewall-enabled ADLS Gen2** without opening the firewall.

**Prerequisites checklist:**

<v-clicks>

1. ✅ Workspace on a **Fabric F SKU** capacity (not Trial or P SKU)
2. ✅ **Workspace Identity** created and enabled
3. ✅ RBAC role on ADLS Gen2: `Storage Blob Data Contributor/Owner/Reader`
4. ✅ **Resource Instance Rule** on storage firewall (ARM/Bicep/PowerShell)
5. ✅ Storage account allows "trusted Microsoft services"

</v-clicks>

<div class="mt-4 p-3 bg-red-50 rounded-lg border border-red-300 text-sm">
⚠️ <strong>Troubleshooting:</strong> All 4 steps are required. Failure at any step <strong>silently blocks</strong> access — no error message, just empty results.
</div>

---

# Managed Private Endpoints & Managed VNets

```mermaid
flowchart LR
    subgraph Fabric["Microsoft Fabric"]
        subgraph MVNET["Managed VNet (auto)"]
            Spark["Spark Cluster"]
            MPE1["MPE → Azure SQL"]
            MPE2["MPE → ADLS Gen2"]
        end
    end

    SQL["Azure SQL DB\n🔒 Firewall"]
    ADLS["ADLS Gen2\n🔒 Private"]

    Spark --> MPE1 -->|"Private Link"| SQL
    Spark --> MPE2 -->|"Private Link"| ADLS
```

<div class="grid grid-cols-2 gap-4 mt-4">

<div>

**How it works:**
- Fabric creates a **Managed VNet** per workspace
- MPEs connect privately to Azure services
- All traffic on Microsoft backbone
- **Auto-provisioned** on first MPE creation

</div>

<div>

**Key limitations:**
- Starter Pools disabled (3-5 min startup)
- OneLake shortcuts don't support MPE yet
- Not available in all regions
- Cross-region migration not supported

</div>

</div>

---

# Data Gateways

<div class="grid grid-cols-2 gap-6 mt-4">

<div>

### On-Premises Gateway

| | Detail |
|---|---|
| **Install** | Windows server on-prem |
| **Protocol** | Secure outbound (no inbound ports) |
| **Sources** | Any accessible source |
| **Management** | Manual updates + HA |

### VNet Data Gateway

| | Detail |
|---|---|
| **Deploy** | Into customer Azure VNet |
| **Managed** | By Microsoft |
| **Sources** | Azure services in VNet |
| **New GA** | Enterprise proxy + cert auth ✅ |

</div>

<div>

```mermaid
flowchart TB
    Fabric["Microsoft Fabric"]
    OGW["On-Prem\nGateway"]
    VGW["VNet Data\nGateway"]
    SQL["SQL Server"]
    ASQL["Azure SQL MI"]

    Fabric --> OGW -->|"Secure Channel"| SQL
    Fabric --> VGW -->|"Within VNet"| ASQL
```

<div class="mt-4 p-3 bg-green-50 rounded border border-green-200 text-sm">
🆕 VNet Data Gateway now supports <strong>enterprise HTTP/HTTPS proxy</strong> and <strong>certificate authentication</strong> (GA 2026).
</div>

</div>

</div>

---

# Eventstream Private Network Support

<span class="text-orange-500 font-bold">Preview — Q1 2026</span>

Fabric Eventstreams can ingest data from **private networks** via:

<div class="grid grid-cols-3 gap-4 mt-4">

<div class="bg-blue-50 p-4 rounded-lg border border-blue-200 text-center">
  <div class="text-2xl mb-2">🌐</div>
  <div class="font-bold">Managed VNet</div>
  <div class="text-xs">Network isolation</div>
</div>

<div class="bg-green-50 p-4 rounded-lg border border-green-200 text-center">
  <div class="text-2xl mb-2">🔗</div>
  <div class="font-bold">Streaming Data Gateway</div>
  <div class="text-xs">Bridge to private sources</div>
</div>

<div class="bg-purple-50 p-4 rounded-lg border border-purple-200 text-center">
  <div class="text-2xl mb-2">🔒</div>
  <div class="font-bold">Managed PE</div>
  <div class="text-xs">Private connectivity</div>
</div>

</div>

<div class="mt-6">

**Supported:** Azure Event Hubs, IoT Hub, custom sources within a VNet

**Not yet supported:** Custom Endpoint as source/destination, Eventhouse direct ingestion

</div>

---

# Secure Outbound Connectors Matrix

| Method | Sources | Fabric Workloads |
|--------|---------|-----------------|
| **Trusted Workspace Access** | ADLS Gen2 (firewall) | Shortcuts, Pipelines, COPY INTO, Semantic Models |
| **Managed Private Endpoints** | Azure SQL, ADLS Gen2, Cosmos DB, Key Vault... | Spark Notebooks, Lakehouses, Eventstream |
| **VNet Data Gateway** | Azure services in a VNet | Dataflows Gen2, Semantic Models |
| **On-Premises Gateway** | SQL Server, Oracle, SAP, files... | Dataflows Gen2, Semantic Models, Pipelines |
| **Service Tags** | Azure SQL VM, SQL MI, REST APIs | Pipelines, network integration |

---
layout: section
---

# Outbound Protection & DEP
Preventing data exfiltration

---

# Outbound Access Policies

**Restrict outbound connections** to authorized destinations only.

<div class="grid grid-cols-2 gap-6 mt-4">

<div>

**How it works:**
1. Declare allowed destinations via **MPE** or **Data Connections**
2. Enable **Outbound Access Policy** on workspace
3. Any connection to undeclared destination → **Blocked**

**Status (April 2026):**

| Item Type | Status |
|-----------|--------|
| Lakehouse, Spark, Notebooks | **GA** |
| Pipelines, Warehouse, Mirrored DBs | **GA** |
| Power BI, Databases | **Planned** |

</div>

<div>

```mermaid
flowchart LR
    Fabric["Fabric WS"] --> Rules{"Outbound\nPolicy"}
    Rules -->|"MPE ✅"| Corp["Corporate\nADLS Gen2"]
    Rules -.->|"❌ Blocked"| Unknown["Unknown\nEndpoint"]
```

<div class="mt-4 p-3 bg-red-50 rounded border border-red-300 text-sm">
⚠️ <strong>Important:</strong> Declare <strong>all</strong> legitimate destinations before enabling the policy — otherwise you'll break existing connections.
</div>

</div>

</div>

---

# Data Exfiltration Protection (DEP)

Complete DEP = **Inbound + Outbound Protection**

```mermaid
flowchart LR
    Ext["External User\n(unauthorized)"] -.->|"Blocked"| InP["Inbound\nProtection"]
    Int["Internal User\n(authorized)"] -->|"Private Link"| InP
    InP --> Fabric["Fabric\nWorkspace"]
    Fabric --> OutP["Outbound\nPolicies"]
    OutP -->|"Approved dest."| Corp["Corporate\nADLS Gen2"]
    OutP -.->|"Blocked"| Unauth["Unauthorized\nDestination"]
```

### Advanced Exfiltration Controls (Layered Defense)

| Control | Mechanism |
|---------|-----------|
| **Purview Information Protection** | Sensitivity labels on Lakehouses, Warehouses, Reports |
| **Data Loss Prevention (DLP)** | Block export of "Highly Confidential" items |
| **Power BI Export Restrictions** | Disable CSV/Excel/PowerPoint export |
| **Endpoint DLP** | Prevent copy to USB/unauthorized cloud |
| **Defender Session Controls** | Monitor/block downloads in real time |

---
layout: section
---

# Data Security & Encryption
Protecting data at rest and in transit

---

# Encryption & Customer Managed Keys

<div class="grid grid-cols-2 gap-6 mt-4">

<div>

### Encryption Layers

| Type | Mechanism |
|------|-----------|
| **In transit** | TLS 1.2 / 1.3 |
| **At rest** | Microsoft-managed keys |
| **At rest (CMK)** | Customer-managed Key Vault keys |
| **Power BI** | BYOK (Bring Your Own Key) |

### CMK Status (April 2026)

| Items | Status |
|-------|--------|
| Lakehouse, Pipeline, Warehouse... | **GA** |
| Databases, Power BI | **Planned** |

</div>

<div>

### Multi-Geo & Data Residency

- **54 data centers** worldwide
- Data stays in the capacity's Azure region
- Metadata stored in tenant's home region
- **Data Residency compliant** by default

### Compliance Certifications

ISO 27001/27701, HIPAA, SOC 1&2, SOX, FedRAMP, PCI DSS, GDPR, HITRUST, K-ISMS, CSA STAR

</div>

</div>

---
layout: section
---

# DNS Configuration
The most common Private Link failure point

---

# DNS — Required Private Zones

<div class="grid grid-cols-2 gap-6 mt-4">

<div>

| DNS Zone | Used By |
|----------|---------|
| `privatelink.analysis.windows.net` | Power BI / Semantic Models |
| `privatelink.pbidedicated.windows.net` | Dedicated capacity |
| `privatelink.prod.powerapps.com` | Dataflows |
| `privatelink.blob.core.windows.net` | OneLake (Blob) |
| `privatelink.dfs.core.windows.net` | OneLake (DFS) |
| `privatelink.servicebus.windows.net` | Event Hubs |

</div>

<div>

### Architecture Patterns

| Pattern | Best For |
|---------|----------|
| **Centralized DNS Zone** | Multi-VNet, hub-spoke |
| **DNS Private Resolver** | Hybrid with on-prem DNS |
| **Conditional Forwarders** | Simple hybrid |

### IP Planning
- 1 Private IP per PE
- 1 PE per workspace per VNet
- Reserve at least a `/27` subnet

</div>

</div>

<div class="mt-3 p-3 bg-red-50 rounded-lg border border-red-300">
🔴 <strong>#1 failure cause:</strong> Forgetting to create or link Private DNS Zones. Always verify: <code>nslookup &lt;workspace&gt;.fabric.microsoft.com</code> → must return <code>10.x.x.x</code>
</div>

---

# DNS Best Practices Checklist

<v-clicks>

1. ✅ **Create all required Private DNS Zones** and link to every VNet with PEs
2. ✅ **Test before go-live** — `Resolve-DnsName <workspace>.pbidedicated.windows.net`
   - Expected: `10.x.x.x` private IP, **not** a public IP
3. ✅ **Hybrid DNS:** Configure conditional forwarders for `privatelink.*` zones → Azure DNS (`168.63.129.16`) via DNS Private Resolver
4. ✅ **Automate DNS records** — Use Azure Policy (`Deploy-DINE-PrivateDNSZoneGroup`) to auto-create records on PE creation
5. ✅ **Monitor for DNS drift** — Re-run resolution tests after infra changes (VNet peering, new PEs, zone re-linking)

</v-clicks>

<div class="mt-4 p-3 bg-amber-50 rounded-lg border border-amber-300 text-sm">
💡 A broken DNS zone link <strong>silently reverts</strong> traffic to the public path — no error, no warning, just bypassed Private Endpoints.
</div>

---
layout: section
---

# Monitoring & Auditing
Visibility into network security

---

# Monitoring Stack

<div class="grid grid-cols-2 gap-6 mt-4">

<div>

### Diagnostic Logging

| Source | Key Signals |
|--------|------------|
| **Entra Sign-in Logs** | MFA, CA hits, risky sign-ins |
| **Fabric Admin Audit** | Sharing, exports, gateways |
| **PE Metrics** | Bytes in/out, connections |
| **NSG Flow Logs** | Allow/deny on PE subnets |
| **Azure Firewall** | Rule hits, threat intel |

</div>

<div>

### Sentinel Integration

```mermaid
flowchart TB
    Logs["All Log Sources"] --> LA["Log Analytics"]
    LA --> Sentinel["Microsoft Sentinel"]
    LA --> Alerts["Azure Monitor Alerts"]
    Sentinel --> Play["Playbooks\n(auto-response)"]
```

**Analytics rules detect:**
- 🌍 Logins from unexpected geos
- 📤 Sudden data export spikes
- 🔑 Bulk permission changes
- 🕵️ Sign-ins bypassing CA

</div>

</div>

---

# Audit Best Practices

| Review | Frequency | Responsible |
|--------|-----------|-------------|
| IP Firewall rules accuracy | Monthly | Workspace admin |
| Outbound policy allowed destinations | Quarterly | Security team |
| Private Endpoint approvals | Quarterly | Azure subscription owner |
| Conditional Access effectiveness | Quarterly | Identity team |
| DNS zone records and VNet links | Semi-annually | Network team |
| Penetration testing | Annually | Security team |

<div class="mt-4 p-3 bg-blue-50 rounded-lg border border-blue-200 text-sm">
💡 <strong>Using NSG + Azure Firewall:</strong> Apply service tags (<code>PowerBI</code>, <code>DataFactory</code>, <code>SQL</code>) in NSG rules. Route outbound traffic through Azure Firewall for centralized logging. Use NAT Gateway for static outbound IP.
</div>

---
layout: section
---

# Testing & Validation
Verifying network security controls

---

# Connectivity & Performance Tests

<div class="grid grid-cols-2 gap-6 mt-4">

<div>

### Connectivity Validation

| Test | Expected |
|------|----------|
| DNS for PE | `10.x.x.x` (private IP) |
| Portal via PE | Portal loads correctly |
| IP Firewall block | HTTP 403 |
| MPE to Azure SQL | Query succeeds |
| Outbound policy block | Connection refused |

</div>

<div>

### Performance Considerations

- 📊 **Baseline first** — measure before enabling PL/MVNet
- ⏱️ **Spark startup:** 3-5 min with custom pools (vs seconds for Starter Pools)
- 📶 **PE throughput:** Up to 8 Gbps per PE
- 🌍 **Cross-region:** Co-locate PEs with capacities

</div>

</div>

<div class="mt-4 p-3 bg-green-50 rounded-lg border border-green-300 text-sm">
✅ <strong>Pro tip:</strong> Run <code>nslookup</code> from inside the VNet, not from your local machine — local DNS may not have the private zone.
</div>

---
layout: section
---

# Architecture Patterns
Real-world deployment scenarios

---

# Feature Dependencies

Understanding prerequisites before configuring features:

```mermaid
flowchart TD
    FSKU["F SKU Capacity"] --> TWA["Trusted WS Access"]
    FSKU --> MVNET["Managed VNet"]
    TS["Tenant Setting:\nWS Inbound Rules"] --> WSPL["WS Private Link"]
    TS --> IPFW["WS IP Firewall"]
    P1["Entra P1"] --> CA["Conditional Access"]
    MVNET --> MPE["Managed PE"]
    MPE --> OAP["Outbound Policies"]
    VNet["Customer VNet"] --> PE["Private Endpoints"] --> WSPL
    DNS["Private DNS"] --> WSPL
    WI["Workspace Identity"] --> TWA
    RBAC["RBAC on Storage"] --> TWA
```

<div class="text-sm mt-2">

| Chain | Steps |
|-------|-------|
| **WS Private Link** | Tenant setting → VNet + PE + DNS → WS admin disables public access |
| **Managed PE** | F SKU → Managed VNet (auto) → MPE → Source owner approves |
| **Trusted WS Access** | F SKU → WS Identity → RBAC → Resource Instance Rule |

</div>

---

# Scenario 1 — Regulated Enterprise
<span class="text-sm text-red-600">GDPR / HIPAA / PCI DSS</span>

<div class="grid grid-cols-2 gap-4 mt-4 text-sm">

<div>

| Layer | Recommendation |
|-------|---------------|
| **Inbound** | Tenant PL + Block Public Access |
| **Outbound** | MVNet + MPE + Outbound Policies |
| **Identity** | MFA (phishing-resistant) + PIM |
| **Data** | CMK + Purview labels + DLP |
| **DNS** | Centralized zones + Resolver |
| **Monitoring** | Full Sentinel integration |

</div>

<div>

**Key characteristics:**
- 🔒 Zero public internet traffic
- 🏥 All users on VPN/ExpressRoute
- 📋 Full audit trail
- 🔑 Customer-managed encryption
- 🌍 Multi-geo for residency

<div class="p-2 bg-red-50 rounded border border-red-200 text-xs mt-2">
⚠️ Most restrictive. Disables Copilot, Publish to Web, some exports.
</div>

</div>

</div>

---

# Scenario 2 — Mixed Sensitivity
<span class="text-sm text-blue-600">Data Platform Team</span>

<div class="grid grid-cols-2 gap-4 mt-4 text-sm">

<div>

| Layer | Recommendation |
|-------|---------------|
| **Inbound** | WS PL (sensitive) + IP FW (semi) + Public (BI) |
| **Outbound** | TWA + MPE + VNet Gateway |
| **Identity** | MFA all + device compliance for admins |
| **Data** | CMK on sensitive WS + labels |
| **Monitoring** | Audit logs + PE failure alerts |

</div>

<div>

**Architecture:**
```mermaid
flowchart TB
    WS1["WS: Data Eng\n🔒 Private Link"] 
    WS2["WS: Warehouse\n🔒 Private Link"]
    WS3["WS: Self-Service\n🔥 IP Firewall"]
    WS4["WS: BI\n🌐 Public + CA"]
```

<div class="p-2 bg-blue-50 rounded border border-blue-200 text-xs mt-2">
✅ <strong>Best balance</strong> of security and usability. Most common pattern.
</div>

</div>

</div>

---

# Scenario 3 & 4

<div class="grid grid-cols-2 gap-6 mt-4 text-sm">

<div>

### Scenario 3 — Startup (Cost-Optimized)

| Layer | Recommendation |
|-------|---------------|
| **Inbound** | Conditional Access + IP FW |
| **Outbound** | VNet GW or On-Prem GW |
| **Identity** | MFA for all |
| **Data** | Default encryption |
| **DNS** | N/A (no PL) |
| **Monitoring** | Entra + Admin logs |

<div class="p-2 bg-green-50 rounded border border-green-200 text-xs mt-2">
💰 Minimal cost. No VNet infrastructure.
</div>

</div>

<div>

### Scenario 4 — Multi-Region Global

| Layer | Recommendation |
|-------|---------------|
| **Inbound** | WS PL per region |
| **Outbound** | Regional MVNets + MPE |
| **Identity** | CA with named locations |
| **Data** | Regional Key Vaults + multi-geo |
| **DNS** | Per-region zones + resolver |
| **Monitoring** | Regional → global Sentinel |

<div class="p-2 bg-purple-50 rounded border border-purple-200 text-xs mt-2">
🌍 Data stays in-region. Cross-region correlation.
</div>

</div>

</div>

---
layout: section
---

# Feature Status & Roadmap
As of April 2026

---

# Feature Summary

| Feature | Level | Status | Use Case |
|---------|-------|--------|----------|
| Entra Conditional Access | Tenant | **GA** | Zero Trust, MFA |
| Private Link — Tenant | Tenant | **GA** | Full tenant isolation |
| Private Link — Workspace | Workspace | **GA** | Granular WS isolation |
| IP Firewall — Workspace | Workspace | **GA** | IP-based restriction |
| Trusted Workspace Access | Workspace | **GA** | ADLS Gen2 (firewall) |
| Managed Private Endpoints | Workspace | **GA** | Private Azure connections |
| Managed VNets | Workspace | **GA** | Spark isolation |
| VNet Data Gateway | Org | **GA** | Azure services in VNet |
| Outbound Access Policies | Workspace | **GA** | DEP |
| Customer Managed Keys | Workspace | **GA** | Dual-layer encryption |
| Eventstream Private Network | Workspace | **Preview** | Real-time private ingestion |
| Power BI Network Isolation | Workspace | **Planned** | WS-level PL/IPFW for PBI |
| Fabric DB Network Isolation | Workspace | **Planned** | WS-level PL/IPFW for DBs |

---

# Known Limitations by Item Type

| Item Type | WS Private Link | WS IP Firewall | Managed VNet | Outbound Policies | CMK |
|-----------|:---:|:---:|:---:|:---:|:---:|
| Lakehouse | ✅ | ✅ | ✅ | ✅ | ✅ |
| Warehouse | ✅ | ✅ | — | ✅ | ✅ |
| Notebook / Spark | ✅ | ✅ | ✅ | ✅ | ✅ |
| Pipeline / Dataflow | ✅ | ✅ | — | ✅ | ✅ |
| Eventstream | ✅ | ✅ | ✅ | ✅ | ✅ |
| Mirrored DB | ✅ | ✅ | — | ✅ | — |
| **Power BI Reports** | 🔜 | 🔜 | — | 🔜 | 🔜 |
| **Fabric Databases** | 🔜 | 🔜 | — | 🔜 | 🔜 |
| **Data Activator** | 🔜 | 🔜 | — | — | — |

<div class="mt-3 p-3 bg-amber-50 rounded-lg border border-amber-300 text-sm">
⚠️ Until Power BI and Fabric DB items are covered, protect them with <strong>tenant-level PL</strong> or <strong>Conditional Access</strong>.
</div>

---
layout: center
class: text-center
---

# Key Takeaways

<div class="grid grid-cols-2 gap-6 mt-6 text-left max-w-3xl mx-auto">

<div class="bg-purple-50 p-4 rounded-lg border border-purple-200">
  <div class="text-xl mb-2">🆔</div>
  <strong>Identity First</strong>
  <p class="text-sm">Start with Conditional Access, MFA, PIM — network controls complement but don't replace identity.</p>
</div>

<div class="bg-blue-50 p-4 rounded-lg border border-blue-200">
  <div class="text-xl mb-2">🏢</div>
  <strong>Workspace-Level Preferred</strong>
  <p class="text-sm">Use workspace PL/IPFW for sensitive workspaces. Tenant PL only when regulation mandates it.</p>
</div>

<div class="bg-green-50 p-4 rounded-lg border border-green-200">
  <div class="text-xl mb-2">🔄</div>
  <strong>Layered Defense</strong>
  <p class="text-sm">Combine inbound + outbound + data controls for full DEP. No single control is sufficient alone.</p>
</div>

<div class="bg-red-50 p-4 rounded-lg border border-red-200">
  <div class="text-xl mb-2">🌐</div>
  <strong>DNS is Critical</strong>
  <p class="text-sm">Private DNS Zones are the #1 failure point. Test resolution before go-live, monitor for drift.</p>
</div>

</div>

---
layout: center
class: text-center
---

# References

<div class="text-left max-w-2xl mx-auto text-sm">

- [Security Overview](https://learn.microsoft.com/en-us/fabric/security/security-overview)
- [Private Links Overview](https://learn.microsoft.com/en-us/fabric/security/security-private-links-overview)
- [Workspace-level Private Links](https://learn.microsoft.com/en-us/fabric/security/security-workspace-level-private-links-overview)
- [Managed VNets](https://learn.microsoft.com/en-us/fabric/security/security-managed-vnets-fabric-overview)
- [Managed Private Endpoints](https://learn.microsoft.com/en-us/fabric/security/security-managed-private-endpoints-overview)
- [Trusted Workspace Access](https://learn.microsoft.com/en-us/fabric/security/security-trusted-workspace-access)
- [IP Firewall Rules](https://learn.microsoft.com/en-us/fabric/security/security-ip-firewall-rules)
- [Conditional Access](https://learn.microsoft.com/en-us/fabric/security/security-conditional-access)
- [VNet Data Gateway](https://learn.microsoft.com/en-us/data-integration/vnet/overview)
- [Azure Private DNS Zones](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns)
- [Fabric Security Whitepaper](https://aka.ms/FabricSecurityWhitepaper)

</div>

---
layout: end
---

# Thank You

Network Security in Microsoft Fabric — April 2026

<div class="text-sm opacity-70 mt-4">
Questions? Reach out to your Fabric administrator or security team.
</div>
