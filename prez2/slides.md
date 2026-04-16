---
marp: true
theme: fabric-editorial
paginate: true
header: 'Microsoft Fabric · Network Security'
footer: 'April 2026'
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _header: '' -->
<!-- _footer: '' -->

<div class="tag">Architecture Brief · April 2026</div>

# Network Security<br>in Microsoft Fabric.

## Three pillars. Zero public exposure. One coherent architecture for enterprise-grade data platforms.

### fredgis · github.com/fredgis/Divers

---

<!-- _header: '' -->

# The Shift

## From "network perimeter" to "identity + data boundary"

<div class="split">

<div>

Fabric is **SaaS**. The public endpoint *is* the platform. You cannot put it behind a firewall and call it a day.

Network security becomes a **composition of controls** — each addressing a specific threat surface, none of them sufficient alone.

The goal is not to replicate on-premises isolation. The goal is **layered containment** that assumes breach at every tier.

</div>

<div>

<div class="stat">
<div class="big">3</div>
<div class="label">pillars of network defense</div>
</div>

<div class="stat">
<div class="big">0</div>
<div class="label">trust assumptions — Zero Trust by design</div>
</div>

<div class="stat">
<div class="big">1</div>
<div class="label">coherent DEP architecture — Data Exfiltration Protection</div>
</div>

</div>

</div>

---

# The Three Pillars

## Each answers a different question

<div class="cards">

<div class="card">
<div class="card-num">PILLAR 01</div>
<h3>Inbound Protection</h3>
<p><strong>Who</strong> can access Fabric? Identity-first, network-second.</p>
<p style="margin-top:8px"><span class="pill">Conditional Access</span> <span class="pill">Private Link</span> <span class="pill">IP Firewall</span></p>
</div>

<div class="card teal">
<div class="card-num">PILLAR 02</div>
<h3>Secure Outbound</h3>
<p><strong>How</strong> does Fabric reach protected sources? Private paths, not public ones.</p>
<p style="margin-top:8px"><span class="pill">Managed VNet</span> <span class="pill">MPE</span> <span class="pill">TWA</span> <span class="pill">Gateways</span></p>
</div>

<div class="card red">
<div class="card-num">PILLAR 03</div>
<h3>Exfiltration Protection</h3>
<p><strong>Where</strong> can data go? Allowlisted destinations only.</p>
<p style="margin-top:8px"><span class="pill">Outbound Policies</span> <span class="pill">Purview DLP</span></p>
</div>

</div>

> **Inbound + Outbound = DEP.** Combining both pillars produces Data Exfiltration Protection — the state where data cannot leave via any unauthorized path.

---

# End-to-End Flow

## The complete request path through a secured Fabric

![w:1050](images/flow.png)

Identity gate → network gate → workspace → managed VNet → private data path. Outbound policies kill anything that doesn't match a declared destination.

---

<!-- _class: chapter -->

<div class="num">01</div>

# Inbound Protection.

Controlling who — and from where — can reach the Fabric tenant.

---

# Conditional Access

## Identity is the primary perimeter

<div class="split">

<div>

<h3>Policies evaluate</h3>

- **User / Group** — restrict to business units
- **Location** — block untrusted countries
- **Device** — require Intune-compliant
- **Risk Level** — block risky sign-ins (P2)
- **Application** — per-client granularity

<h3>Enforcement</h3>

- MFA · phishing-resistant preferred
- Session controls · limit token lifetime
- Just-in-time elevation (PIM)

</div>

<div>

<h3>Requirements</h3>

| Component | Level |
|-----------|-------|
| Entra ID license | **P1** minimum |
| MFA | **Required** |
| Device compliance | Intune recommended |
| Risk-based CA | **P2** license |

> **Rule of thumb.** If Conditional Access isn't configured, nothing below matters. Identity is always first.

</div>

</div>

---

# Private Link — Tenant vs Workspace

## Two different tools. Pick based on isolation granularity.

<div class="cards two">

<div class="card">
<div class="card-num">TENANT-LEVEL</div>
<h3>All-or-Nothing</h3>
<p>A single Private Link service for the entire tenant. Blocks public access globally.</p>

<p style="margin-top:10px">
<span class="pill gray">Simpler to deploy</span>
<span class="pill red">Spark starter pools disabled</span>
<span class="pill red">Some features unsupported</span>
</p>

<p style="margin-top:8px; color:var(--muted); font-size:0.8em">
<strong>Use when:</strong> the entire tenant handles sensitive data.
</p>
</div>

<div class="card teal">
<div class="card-num">WORKSPACE-LEVEL · RECOMMENDED</div>
<h3>Surgical Isolation</h3>
<p>One Private Link service per workspace. Isolate only what needs to be isolated.</p>

<p style="margin-top:10px">
<span class="pill green">Per-workspace granularity</span>
<span class="pill green">Share a VNet across workspaces</span>
<span class="pill gray">Needs tenant admin to enable</span>
</p>

<p style="margin-top:8px; color:var(--muted); font-size:0.8em">
<strong>Use when:</strong> mixed sensitivity workspaces — the common case.
</p>
</div>

</div>

> Both require a **Private DNS Zone** (`privatelink.fabric.microsoft.com`). Forgetting it is the #1 reason Private Link "doesn't work" on first deployment.

---

# IP Firewall Rules

## The simplest public-access lockdown

<div class="split right-wide">

<div>

<h3>When to use</h3>

Allow Fabric on the public internet — but only from **declared IP ranges**. No Azure VNet infrastructure required.

<h3>Limitations</h3>

- Power BI items · **not yet supported**
- Fabric databases · **not yet supported**
- Fabric REST API · remains accessible (by design)
- Max **100 rules** per workspace

</div>

<div>

<h3>Supported items</h3>

<p>
<span class="pill green">Lakehouse</span>
<span class="pill green">Warehouse</span>
<span class="pill green">Notebook</span>
<span class="pill green">Pipeline</span>
<span class="pill green">Dataflow Gen2</span>
<span class="pill green">Eventstream</span>
<span class="pill green">Mirrored DB</span>
</p>

<h3>Combines with</h3>

<p>
<span class="pill">Private Link</span> +
<span class="pill">IP Firewall</span> → Private paths and allowed public IPs both permitted. Everything else denied.
</p>

<p style="margin-top:10px"><span class="pill green">GA</span> since early 2026</p>

</div>

</div>

---

# Tenant × Workspace Interaction

## The matrix that trips up every deployment

| Tenant Public | WS Private Link | WS IP Firewall | Portal Access | API Access |
|:-------------:|:---------------:|:--------------:|:-------------:|:----------:|
| Allowed | — | — | Public ✓ | Public ✓ |
| Allowed | ✓ | — | PL + Public | PL + Public |
| Allowed | — | ✓ | Allowed IPs only | Allowed IPs only |
| **Restricted** | ✓ | — | Tenant PL only | WS PL + Tenant PL |
| **Restricted** | — | — | Tenant PL only | Tenant PL only |

> **Non-obvious:** when tenant public access is **restricted**, workspace-level Private Link enables **API access only** — not full portal access. The portal requires a tenant-level Private Link.

<p style="margin-top:6px"><strong>Prerequisite:</strong> tenant admin must enable <em>workspace-level inbound network rules</em> before workspace admins can configure PL or IP Firewall.</p>

---

<!-- _class: chapter -->

<div class="num">02</div>

# Secure Outbound.

Reaching private data sources — without crossing the public internet.

---

# Managed VNet & Private Endpoints

## Fabric's default outbound path, once activated

<div class="split">

<div>

<h3>Managed Virtual Network</h3>

- **Microsoft-managed** VNet per workspace
- Activated on first Spark job execution
- All outbound traffic routed through it
- No configuration burden for the customer

<h3>Managed Private Endpoints (MPE)</h3>

- Private connections to Azure PaaS
- Traffic stays on Microsoft backbone
- Target service can **block all public access**

</div>

<div>

<h3>Supported targets</h3>

<p>
<span class="pill">Azure SQL DB</span>
<span class="pill">ADLS Gen2</span>
<span class="pill">Cosmos DB</span>
<span class="pill">Key Vault</span>
<span class="pill">Synapse</span>
<span class="pill">Purview</span>
<span class="pill">Event Hub</span>
</p>

> **MPE request flow.** Create MPE → target service admin approves → traffic flows on the private backbone. The approval step is intentional — it prevents rogue teams from bypassing security.

</div>

</div>

---

# Trusted Workspace Access (TWA)

## The shortcut to firewalled ADLS Gen2

<div class="split right-wide">

<div>

TWA lets a Fabric workspace reach **firewall-protected ADLS Gen2** *without* deploying a Private Endpoint.

Useful when MPE would be overkill — only one target storage, simple RBAC model.

<h3>When to choose TWA over MPE</h3>

- Target is **ADLS Gen2 only**
- No VNet infrastructure to manage
- Speed of deployment > network isolation purity

</div>

<div>

<h3>Prerequisites</h3>

<div class="steps">

<div class="step"><div class="step-content"><strong>Fabric F SKU capacity</strong><span>Trial and PPU do not qualify</span></div></div>

<div class="step"><div class="step-content"><strong>Workspace Identity enabled</strong><span>Generated by the workspace admin</span></div></div>

<div class="step"><div class="step-content"><strong>Storage RBAC</strong><span>Storage Blob Data Contributor on ADLS Gen2</span></div></div>

<div class="step"><div class="step-content"><strong>Resource Instance Rule</strong><span>Configured on the storage account firewall</span></div></div>

</div>

</div>

</div>

---

# Data Gateways

## When the source is not on Azure

<div class="cards two">

<div class="card">
<div class="card-num">ON-PREMISES DATA GATEWAY</div>
<h3>Bridge to corporate networks</h3>
<p>Software agent on a server inside your network. Encrypts outbound to the Fabric service.</p>

<p style="margin-top:10px">
✓ SQL Server, Oracle, SAP, Teradata<br>
✓ Clustering for HA<br>
✓ Kerberos SSO supported
</p>

<p style="margin-top:8px; color:var(--muted); font-size:0.8em">
Install on a VM close to the data source. Size for peak concurrent refreshes.
</p>
</div>

<div class="card teal">
<div class="card-num">VNET DATA GATEWAY</div>
<h3>Managed gateway in your Azure VNet</h3>
<p>No VM to maintain. Fully managed by Microsoft, deployed in your VNet.</p>

<p style="margin-top:10px">
✓ SQL on IaaS, private endpoints<br>
✓ <strong>Certificate authentication · GA</strong><br>
✓ <strong>Enterprise proxy support · GA</strong>
</p>

<p style="margin-top:8px; color:var(--muted); font-size:0.8em">
Preferred for new deployments when sources are reachable via VNet peering.
</p>
</div>

</div>

---

# Outbound Connector Matrix

## Which mechanism reaches which target?

| Target | MPE | TWA | On-Prem GW | VNet GW |
|--------|:---:|:---:|:----------:|:-------:|
| **ADLS Gen2** | ✓ | ✓ | — | ✓ |
| **Azure SQL** | ✓ | — | ✓ | ✓ |
| **Cosmos DB** | ✓ | — | — | ✓ |
| **Key Vault** | ✓ | — | — | — |
| **SQL Server (IaaS / on-prem)** | — | — | ✓ | ✓ |
| **Synapse Analytics** | ✓ | — | — | ✓ |
| **Azure Purview** | ✓ | — | — | — |
| **Event Hub / Service Bus** | ✓ | — | — | ✓ |
| **On-premises SAP / Oracle** | — | — | ✓ | — |

> **Decision heuristic.** If the target is Azure PaaS: prefer **MPE**. If it's on-premises: **On-Prem Gateway**. If it's in your Azure VNet: **VNet Gateway**. If it's ADLS Gen2 and you want speed: **TWA**.

---

<!-- _class: chapter -->

<div class="num">03</div>

# Exfiltration Protection.

The third pillar. Controlling where data goes — not just how it gets out.

---

# Outbound Access Policies

## The gate that turns Fabric into a closed circuit

![w:950](images/dep.png)

Traffic leaving the workspace must match a **declared destination** — either a Managed Private Endpoint or a Data Connection. Anything else: blocked by default.

---

# The Full DEP Picture

## Three controls that must combine

<div class="split">

<div>

<h3>Layer 1 · Inbound</h3>
Block unauthorized users. Private Link, IP Firewall, Conditional Access.

<h3>Layer 2 · Outbound</h3>
Block unauthorized destinations. Outbound Access Policies.

<h3>Layer 3 · Data</h3>
Block unauthorized *content*. Purview DLP labels, export restrictions.

</div>

<div>

<h3>Additional content controls</h3>

<p><span class="pill orange">Power BI exports</span> Disable Excel / CSV / PPTX exports on sensitive workspaces.</p>

<p><span class="pill orange">Endpoint DLP</span> Microsoft Purview + Intune to block copy to USB, personal cloud.</p>

<p><span class="pill orange">Sensitivity labels</span> Classify and auto-apply via Purview — labels travel with the data.</p>

<p><span class="pill orange">CMK</span> Customer Managed Keys for an additional encryption boundary.</p>

</div>

</div>

> **A DEP architecture without Layer 3 is incomplete.** Network controls stop data from leaving via unauthorized paths. DLP stops data from leaving via authorized paths but as unauthorized content.

---

<!-- _class: chapter -->

<div class="num">04</div>

# Operations.

DNS, monitoring, testing — the layers that make it actually work.

---

# DNS · The Silent Killer

## Misconfigured DNS is the #1 Private Link failure cause

![w:1050](images/dns.png)

Without the Private DNS Zone, clients resolve the public IP — which Private Link then blocks. The result: "it works from one machine but not another."

---

# Monitoring Stack

## Network security without visibility is theater

<div class="cards">

<div class="card">
<div class="card-num">DIAGNOSTICS</div>
<h3>Log Analytics</h3>
<p>Fabric diagnostic logs: access patterns, query performance, errors.</p>
</div>

<div class="card teal">
<div class="card-num">NETWORK</div>
<h3>Network Watcher</h3>
<p>VNet flow logs, connectivity tests, reachability checks for Private Endpoints.</p>
</div>

<div class="card red">
<div class="card-num">SECURITY</div>
<h3>Azure Sentinel</h3>
<p>SIEM correlation. Detect anomalous access patterns, failed CA evaluations.</p>
</div>

<div class="card green">
<div class="card-num">COMPLIANCE</div>
<h3>Microsoft Purview</h3>
<p>Data classification, sensitivity audit, DLP policy evaluation.</p>
</div>

<div class="card orange">
<div class="card-num">FIREWALL</div>
<h3>Azure Firewall</h3>
<p>Centralized outbound logging. Static egress IP for partner allowlists.</p>
</div>

<div class="card purple">
<div class="card-num">AUDIT</div>
<h3>Quarterly review</h3>
<p>Rotate IP rules, review PL config, re-validate CA policies against threat model.</p>
</div>

</div>

---

# Validation Checklist

## Never deploy a network config you haven't tested

<div class="steps">

<div class="step"><div class="step-content"><strong>Resolve DNS from a client</strong><span><code>nslookup workspace.fabric.microsoft.com</code> — must return a <strong>private IP (10.x)</strong>, not a public one.</span></div></div>

<div class="step"><div class="step-content"><strong>Test blocked public access</strong><span>Attempt from a non-allowed IP when rules are active — the connection must fail explicitly.</span></div></div>

<div class="step"><div class="step-content"><strong>Spark cold start timing</strong><span>First Spark job triggers Managed VNet activation — measure the latency impact in your setup.</span></div></div>

<div class="step"><div class="step-content"><strong>MPE approval flow</strong><span>Create a test MPE, verify the target service admin receives the approval request and can approve it.</span></div></div>

<div class="step"><div class="step-content"><strong>Exfiltration attempt</strong><span>Try to write to an undeclared destination from a notebook. The outbound policy must block it.</span></div></div>

</div>

---

<!-- _class: chapter -->

<div class="num">05</div>

# Recommendations.

What would I deploy in your context? Scenario-driven architectures.

---

# Zero Trust · Reference Posture

## The layered model you should start from

![w:950](images/zt.png)

<div class="two-col">

<div>

Identity is the primary perimeter. Network is the second. Data is the last line of defense. Each layer assumes the previous one can be breached.

</div>

<div>

> **Common pitfall.** Teams invest months in Private Link deployment while Conditional Access remains permissive. The weakest link dictates the security posture.

</div>

</div>

---

# Architectures by Scenario

## Stop debating features. Pick a blueprint.

<div class="cards">

<div class="card">
<div class="card-num">STANDARD ENTERPRISE</div>
<h3>Balanced · Default choice</h3>
<p>Conditional Access + Workspace Private Link + MPE + Outbound Policies.</p>
<p style="margin-top:6px; font-size:0.75em; color:var(--muted)">Protection for most mixed-sensitivity tenants.</p>
</div>

<div class="card green">
<div class="card-num">REGULATED · GDPR · PCI</div>
<h3>Maximum Control</h3>
<p>CA + WS PL + MPE + Outbound Policies + <strong>Purview DLP</strong> + <strong>CMK</strong>.</p>
<p style="margin-top:6px; font-size:0.75em; color:var(--muted)">All three DEP layers active. Audit-ready.</p>
</div>

<div class="card teal">
<div class="card-num">HYBRID DATA ESTATE</div>
<h3>On-premises integration</h3>
<p>CA + IP Firewall + <strong>VNet Gateway</strong> + <strong>On-Prem Gateway</strong>.</p>
<p style="margin-top:6px; font-size:0.75em; color:var(--muted)">For legacy sources that aren't cloud-native.</p>
</div>

<div class="card purple">
<div class="card-num">MULTI-TEAM ISOLATION</div>
<h3>Segregated workloads</h3>
<p>CA + <strong>Per-workspace PL</strong> + Per-workspace outbound + <strong>PIM</strong>.</p>
<p style="margin-top:6px; font-size:0.75em; color:var(--muted)">Different teams, different sensitivity. No shared blast radius.</p>
</div>

</div>

---

# Feature Roadmap

## What's GA · What's coming · What's blocked

| Feature | Status | Notes |
|---------|:------:|-------|
| Conditional Access | <span class="pill green">GA</span> | Since day one |
| Private Link (Tenant) | <span class="pill green">GA</span> | All-or-nothing scope |
| Private Link (Workspace) | <span class="pill green">GA</span> | **Recommended** default |
| IP Firewall | <span class="pill green">GA</span> | Early 2026 |
| Managed VNet / MPE | <span class="pill green">GA</span> | Core outbound path |
| Trusted Workspace Access | <span class="pill green">GA</span> | ADLS Gen2 only |
| Outbound Access Policies | <span class="pill green">GA</span> | End 2025 |
| VNet Data Gateway · Cert Auth + Proxy | <span class="pill green">GA</span> | New in April 2026 |
| Customer Managed Keys | <span class="pill green">GA</span> | All workloads |
| Eventstream Private Network | <span class="pill orange">Preview</span> | Early 2026 |
| **Power BI** network protection | <span class="pill red">Planned</span> | Expected late 2026 |
| **Fabric Database** network protection | <span class="pill red">Planned</span> | No ETA |

---

<!-- _class: closing -->
<!-- _paginate: false -->
<!-- _header: '' -->
<!-- _footer: '' -->

## Takeaways

# Three pillars.<br>Defense in depth.<br>Zero blind spots.

<p>Fabric's network security is not a single feature — it's an architecture. Start with identity, layer network controls, finish with data classification. Test every layer. Monitor the whole stack.</p>

<p style="margin-top:30px; color:rgba(255,255,255,0.5); font-size:0.85em">Source: github.com/fredgis/Divers/markdown/Fabric_Network_Security.md</p>
