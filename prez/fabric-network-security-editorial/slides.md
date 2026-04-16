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

<div class="split">

<div>

Fabric is **SaaS**. The public endpoint *is* the platform.

Network security becomes a **composition of controls** — each addressing a threat surface, none of them sufficient alone.

The goal: **layered containment** that assumes breach at every tier.

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
<div class="label">coherent DEP architecture</div>
</div>

</div>

</div>

---

# The Three Pillars

![w:1050](images/pillars.png)

---

# Each Pillar Answers a Different Question

<div class="cards">

<div class="card">
<div class="card-num">PILLAR 01</div>
<h3>Inbound Protection</h3>
<p><strong>Who</strong> can access Fabric?</p>
<p style="margin-top:8px"><span class="pill">Conditional Access</span> <span class="pill">Private Link</span> <span class="pill">IP Firewall</span></p>
</div>

<div class="card teal">
<div class="card-num">PILLAR 02</div>
<h3>Secure Outbound</h3>
<p><strong>How</strong> does Fabric reach private sources?</p>
<p style="margin-top:8px"><span class="pill">Managed VNet</span> <span class="pill">MPE</span> <span class="pill">TWA</span> <span class="pill">Gateways</span></p>
</div>

<div class="card red">
<div class="card-num">PILLAR 03</div>
<h3>Exfiltration Protection</h3>
<p><strong>Where</strong> can data go?</p>
<p style="margin-top:8px"><span class="pill">Outbound Policies</span> <span class="pill">Purview DLP</span></p>
</div>

</div>

---

# End-to-End Flow

![w:960](images/flow.png)

---

<!-- _class: chapter -->

<div class="num">01</div>

# Inbound Protection.

Controlling who — and from where — can reach the Fabric tenant.

---

# Conditional Access

<div class="split">

<div>

<h3>Policies evaluate</h3>

- **User / Group** · per business unit
- **Location** · untrusted countries
- **Device** · Intune compliance
- **Risk level** · P2 licence
- **App** · per-client granularity

<h3>Enforce</h3>

<p><span class="pill">MFA</span> <span class="pill">Session lifetime</span> <span class="pill">PIM</span></p>

</div>

<div>

<h3>Requirements</h3>

| Component | Level |
|-----------|-------|
| Entra ID | **P1** |
| MFA | **Required** |
| Device compliance | Intune |
| Risk-based CA | **P2** |

> **Rule of thumb.** If CA isn't configured, nothing below matters.

</div>

</div>

---

# Private Link — Tenant vs Workspace

<div class="cards two">

<div class="card">
<div class="card-num">TENANT-LEVEL</div>
<h3>All-or-Nothing</h3>
<p>Single service for the entire tenant.</p>

<p style="margin-top:10px">
<span class="pill gray">Simpler deploy</span>
<span class="pill red">Spark starter pools off</span>
<span class="pill red">Some features unsupported</span>
</p>
</div>

<div class="card teal">
<div class="card-num">WORKSPACE-LEVEL · RECOMMENDED</div>
<h3>Surgical Isolation</h3>
<p>One service per workspace. Isolate only what needs it.</p>

<p style="margin-top:10px">
<span class="pill green">Per-workspace scope</span>
<span class="pill green">Share a VNet</span>
<span class="pill gray">Tenant admin toggle</span>
</p>
</div>

</div>

> Both require a **Private DNS Zone** (`privatelink.fabric.microsoft.com`). Forgetting it is the #1 reason PL "doesn't work" on first deployment.

---

# IP Firewall Rules

<div class="split right-wide">

<div>

Allow Fabric on the public internet — but only from **declared IP ranges**. No VNet needed.

**Limits**

- No Power BI items yet
- No Fabric databases yet
- REST API always reachable
- Max **100 rules** per WS

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

<p><span class="pill">Private Link</span> + <span class="pill">IP Firewall</span> → private paths and allowed public IPs both permitted. Everything else denied.</p>

<p style="margin-top:10px"><span class="pill green">GA</span> since early 2026</p>

</div>

</div>

---

# Tenant × Workspace Interaction

<div class="split right-wide">

<div>

Two knobs, combined:

- **Tenant** `Allowed` or `Restricted`
- **Workspace** `None`, `PL`, or `IP Firewall`

<p style="margin-top:10px; font-size:0.85em"><strong>Non-obvious:</strong> when tenant public access is <em>restricted</em>, workspace-level PL enables <strong>API access only</strong>. Portal needs tenant-level PL.</p>

</div>

<div>

![w:560](images/interaction.png)

</div>

</div>

---

<!-- _class: chapter -->

<div class="num">02</div>

# Secure Outbound.

Reaching private data sources — without crossing the public internet.

---

# Outbound Architecture

![w:1050](images/outbound.png)

---

# Managed VNet & Private Endpoints

<div class="split">

<div>

<h3>Managed VNet</h3>

- **Microsoft-managed** per workspace
- Activated on first Spark job
- All outbound routed through it

<h3>Managed Private Endpoints</h3>

- Private connections to Azure PaaS
- Traffic on Microsoft backbone
- Target service can block public access

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

> **MPE flow.** Create → target admin approves → private traffic flows. Approval is intentional — prevents bypass.

</div>

</div>

---

# Trusted Workspace Access

<div class="split right-wide">

<div>

TWA reaches **firewalled ADLS Gen2** *without* deploying a Private Endpoint.

Useful when MPE is overkill — single target, simple RBAC.

<h3>Pick TWA over MPE when</h3>

- Target is **ADLS Gen2 only**
- No VNet infra desired
- Speed > isolation purity

</div>

<div>

<h3>Prerequisites</h3>

<div class="steps">

<div class="step"><div class="step-content"><strong>F SKU capacity</strong><span>Trial / PPU don't qualify</span></div></div>

<div class="step"><div class="step-content"><strong>Workspace Identity</strong><span>Generated by admin</span></div></div>

<div class="step"><div class="step-content"><strong>Storage RBAC</strong><span>Storage Blob Data Contributor</span></div></div>

<div class="step"><div class="step-content"><strong>Resource Instance Rule</strong><span>On the storage firewall</span></div></div>

</div>

</div>

</div>

---

# Data Gateways

<div class="cards two">

<div class="card">
<div class="card-num">ON-PREMISES DATA GATEWAY</div>
<h3>Bridge to corporate networks</h3>
<p>Agent on a server inside your network. Encrypts outbound to Fabric.</p>

<p style="margin-top:10px">
✓ SQL Server, Oracle, SAP, Teradata<br>
✓ Clustering for HA<br>
✓ Kerberos SSO supported
</p>
</div>

<div class="card teal">
<div class="card-num">VNET DATA GATEWAY</div>
<h3>Managed gateway in your VNet</h3>
<p>No VM to maintain. Fully managed, deployed in your VNet.</p>

<p style="margin-top:10px">
✓ SQL on IaaS, private endpoints<br>
✓ <strong>Certificate auth · GA</strong><br>
✓ <strong>Enterprise proxy · GA</strong>
</p>
</div>

</div>

---

# Outbound Connector Matrix

| Target | MPE | TWA | On-Prem GW | VNet GW |
|--------|:---:|:---:|:----------:|:-------:|
| **ADLS Gen2** | ✓ | ✓ | — | ✓ |
| **Azure SQL** | ✓ | — | ✓ | ✓ |
| **Cosmos DB** | ✓ | — | — | ✓ |
| **Key Vault** | ✓ | — | — | — |
| **SQL Server IaaS / on-prem** | — | — | ✓ | ✓ |
| **Synapse** | ✓ | — | — | ✓ |
| **Purview** | ✓ | — | — | — |
| **Event Hub / Service Bus** | ✓ | — | — | ✓ |
| **SAP / Oracle on-prem** | — | — | ✓ | — |

> **Heuristic.** Azure PaaS → MPE. On-prem → On-Prem GW. Your VNet → VNet GW. ADLS only → TWA.

---

<!-- _class: chapter -->

<div class="num">03</div>

# Exfiltration Protection.

Controlling *where* data goes — not just how it gets out.

---

# Outbound Access Policies

![w:820](images/dep.png)

<p style="margin-top:4px; font-size:0.85em">Traffic must match a <strong>declared destination</strong> — MPE or Data Connection. Anything else: blocked by default.</p>

---

# The Full DEP Picture

<div class="split">

<div>

![w:540](images/depfull.png)

</div>

<div>

Data Exfiltration Protection isn't a single feature — it's the **convergence of three layers**.

- **Inbound** blocks *bad actors* at the door
- **Outbound** blocks *bad paths* to the outside
- **Data** blocks *bad content* even on authorized paths

<p style="margin-top:10px; font-size:0.9em"><strong>Remove any one layer and DEP leaks.</strong> Network alone won't stop an authenticated user emailing a spreadsheet. Labels alone won't stop a rogue notebook posting to an unknown endpoint.</p>

</div>

</div>

---

# Content Controls · Layer 3

<div class="cards">

<div class="card orange">
<div class="card-num">EXPORTS</div>
<h3>Power BI Export Restrictions</h3>
<p>Disable Excel / CSV / PPTX exports on sensitive workspaces.</p>
</div>

<div class="card">
<div class="card-num">ENDPOINT</div>
<h3>Endpoint DLP</h3>
<p>Purview + Intune to block copy to USB or personal cloud.</p>
</div>

<div class="card teal">
<div class="card-num">CLASSIFY</div>
<h3>Sensitivity Labels</h3>
<p>Auto-apply via Purview — labels travel with the data.</p>
</div>

<div class="card green">
<div class="card-num">ENCRYPT</div>
<h3>Customer Managed Keys</h3>
<p>Additional encryption boundary with full key control.</p>
</div>

</div>

---

<!-- _class: chapter -->

<div class="num">04</div>

# Operations.

DNS, monitoring, testing — the layers that make it actually work.

---

# DNS · The Silent Killer

![w:880](images/dns.png)

<p style="margin-top:4px; font-size:0.85em">Without the Private DNS Zone, clients resolve the public IP — Private Link then blocks. The result: <em>"works from one machine but not another."</em></p>

---

# Monitoring Stack

<div class="cards">

<div class="card">
<div class="card-num">DIAGNOSTICS</div>
<h3>Log Analytics</h3>
<p>Access patterns, query perf, errors.</p>
</div>

<div class="card teal">
<div class="card-num">NETWORK</div>
<h3>Network Watcher</h3>
<p>VNet flows, connectivity tests, PE reachability.</p>
</div>

<div class="card red">
<div class="card-num">SECURITY</div>
<h3>Azure Sentinel</h3>
<p>SIEM correlation. Anomalous access, failed CA.</p>
</div>

<div class="card green">
<div class="card-num">COMPLIANCE</div>
<h3>Microsoft Purview</h3>
<p>Classification, DLP, sensitivity audit.</p>
</div>

<div class="card orange">
<div class="card-num">FIREWALL</div>
<h3>Azure Firewall</h3>
<p>Centralized egress logging. Static egress IP.</p>
</div>

<div class="card purple">
<div class="card-num">AUDIT</div>
<h3>Quarterly review</h3>
<p>Rotate IPs, re-validate CA policies.</p>
</div>

</div>

---

# Validation Checklist

<div class="steps">

<div class="step"><div class="step-content"><strong>Resolve DNS from a client</strong><span><code>nslookup workspace.fabric.microsoft.com</code> must return a <strong>private IP (10.x)</strong>.</span></div></div>

<div class="step"><div class="step-content"><strong>Test blocked public access</strong><span>From a non-allowed IP the connection must fail explicitly.</span></div></div>

<div class="step"><div class="step-content"><strong>Spark cold start</strong><span>First Spark job activates the Managed VNet — measure latency.</span></div></div>

<div class="step"><div class="step-content"><strong>MPE approval flow</strong><span>Verify the target service admin receives and can approve the request.</span></div></div>

<div class="step"><div class="step-content"><strong>Exfiltration attempt</strong><span>Write to an undeclared destination. The policy must block it.</span></div></div>

</div>

---

<!-- _class: chapter -->

<div class="num">05</div>

# Recommendations.

What would I deploy in your context? Scenario-driven blueprints.

---

# Zero Trust · Reference Posture

![w:900](images/zt.png)

<p style="margin-top:4px; font-size:0.85em">Identity is the primary perimeter. Network is the second. Data is the last line.</p>

---

# Architectures by Scenario

<div class="cards">

<div class="card">
<div class="card-num">STANDARD ENTERPRISE</div>
<h3>Balanced · Default choice</h3>
<p>CA + Workspace PL + MPE + Outbound Policies.</p>
</div>

<div class="card green">
<div class="card-num">REGULATED · GDPR · PCI</div>
<h3>Maximum Control</h3>
<p>CA + WS PL + MPE + Outbound Policies + <strong>Purview DLP</strong> + <strong>CMK</strong>.</p>
</div>

<div class="card teal">
<div class="card-num">HYBRID DATA ESTATE</div>
<h3>On-prem integration</h3>
<p>CA + IP Firewall + <strong>VNet Gateway</strong> + <strong>On-Prem Gateway</strong>.</p>
</div>

<div class="card purple">
<div class="card-num">MULTI-TEAM ISOLATION</div>
<h3>Segregated workloads</h3>
<p>CA + <strong>Per-workspace PL</strong> + Per-workspace outbound + <strong>PIM</strong>.</p>
</div>

</div>

---

# Feature Roadmap

| Feature | Status | Notes |
|---------|:------:|-------|
| Conditional Access | <span class="pill green">GA</span> | Since day one |
| Private Link (Tenant) | <span class="pill green">GA</span> | All-or-nothing |
| Private Link (Workspace) | <span class="pill green">GA</span> | **Recommended** |
| IP Firewall | <span class="pill green">GA</span> | Early 2026 |
| Managed VNet / MPE | <span class="pill green">GA</span> | Core outbound |
| Trusted Workspace Access | <span class="pill green">GA</span> | ADLS Gen2 only |
| Outbound Access Policies | <span class="pill green">GA</span> | End 2025 |
| VNet GW · Cert + Proxy | <span class="pill green">GA</span> | April 2026 |
| Customer Managed Keys | <span class="pill green">GA</span> | All workloads |
| Eventstream Private Network | <span class="pill orange">Preview</span> | Early 2026 |
| **Power BI** network protection | <span class="pill red">Planned</span> | Late 2026 |
| **Fabric Database** network protection | <span class="pill red">Planned</span> | No ETA |

---

<!-- _class: closing -->
<!-- _paginate: false -->
<!-- _header: '' -->
<!-- _footer: '' -->

## Takeaways

# Three pillars.<br>Defense in depth.<br>Zero blind spots.

<p>Start with identity. Layer network controls. Finish with data classification. Test every layer. Monitor the whole stack.</p>

<p style="margin-top:30px; color:rgba(255,255,255,0.5); font-size:0.85em">Source: github.com/fredgis/Divers/markdown/Fabric_Network_Security.md</p>
