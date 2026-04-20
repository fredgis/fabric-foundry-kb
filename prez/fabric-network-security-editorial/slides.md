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

### fredgis · github.com/fredgis/fabric-foundry-kb/

<!--
Welcome. In the next 40 minutes I will explain how to secure the network around Microsoft Fabric.

Fabric is a SaaS platform, so the public endpoint is the platform. We cannot put a firewall in front of it like a classic VM. We must compose controls on top.

I will cover three pillars: who can come in, how Fabric reaches private data, and where data can go out. By the end you will know which control to use, in which order, and what to test before go-live.
-->

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

<!--
Fabric is delivered as SaaS. The first big shift is that you do not own the network — Microsoft does. Your job is to compose controls on top of the platform.

There are three pillars of network defense. None of them is enough alone. The end state is one coherent DEP architecture — Data Exfiltration Protection.

Remember: secure by default already gives you TLS 1.2 minimum, Entra authentication on every call, and traffic on the Microsoft backbone between Fabric experiences. We add layers on top of that baseline.
-->

---

# The Three Pillars

![w:1050](images/pillars.png)

<!--
This is the mental model for the rest of the talk.

Pillar one — Inbound — controls who can enter the tenant. Pillar two — Secure Outbound — controls how Fabric reaches your private sources without crossing the public internet. Pillar three — Outbound Protection — controls where your data can go.

The first two pillars combined give you full DEP. Every feature we will discuss fits in one of these three boxes — keep this picture in mind.
-->

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

<!--
Each pillar answers a different question.

Pillar one: who can access Fabric? Tools are Conditional Access for identity, Private Link for network, and IP Firewall for trusted ranges.

Pillar two: how does Fabric reach private sources? Tools are the Managed VNet, Managed Private Endpoints, Trusted Workspace Access, and the two data gateways.

Pillar three: where can data go? Tools are Outbound Access Policies and Purview DLP.

If you cannot map a feature to one of these three questions, you do not need it yet.
-->

---

# End-to-End Flow

![w:960](images/flow.png)

<!--
This diagram shows the full flow in one picture.

A user signs in. Conditional Access checks identity, device and risk. The user reaches a workspace, either through a Private Endpoint or through an allowed IP.

The workspace runs a notebook or a pipeline. To read data, it uses its Managed VNet plus a Managed Private Endpoint, or Trusted Workspace Access for ADLS, or a gateway for on-prem.

On the way out, Outbound Access Policies block any destination that is not declared. This is the path we will follow for the rest of the session.
-->

---

# Reference Architecture

![h:560](images/architecture.png)

_Five layers · identity → inbound → workspace + Managed VNet → outbound targets → governance._

<!--
Same idea, but more detailed. Five layers from left to right.

Layer one: identity, with Entra and Conditional Access. Layer two: inbound protection — Private Link, IP Firewall. Layer three: the workspace itself, plus the Managed VNet that Fabric creates for you. Layer four: outbound targets, both Azure PaaS and on-prem sources. Layer five: governance — DNS, monitoring, Purview.

Use this image as a checklist. If one layer is missing in your design, you have a gap to close before go-live.
-->

---

<!-- _class: chapter -->

<div class="num">01</div>

# Inbound Protection.

Controlling who — and from where — can reach the Fabric tenant.

<!--
We start with pillar one — Inbound. The question is simple: who can reach my Fabric tenant, and from where?
-->

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

<!--
Conditional Access is the foundation of inbound. Before any network rule, you must control identity.

It evaluates signals at sign-in time: user and group, location, device compliance with Intune, sign-in risk, and the application. It can require MFA, force a session lifetime, or block.

Minimum license is Entra ID P1 — included in M365 E3 and E5. For risk-based policies you need P2.

One important note: Conditional Access policies for Fabric also apply to related services like Power BI, Azure Data Explorer and Azure SQL. Design with that scope in mind.

Rule of thumb: if Conditional Access is not configured, no other control matters — the attacker is already authenticated.
-->

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

<!--
Two flavors of Private Link in Fabric.

Tenant-level is all-or-nothing. One Private Endpoint protects the whole tenant. Simple to deploy, but you lose Spark starter pools, Copilot, Publish to Web, and several exports. All users must use VPN or ExpressRoute.

Workspace-level is the recommended choice. You apply Private Link only to sensitive workspaces — data engineering, warehouse — and leave the rest public, protected by Conditional Access. Multiple workspaces can share one VNet through separate endpoints.

Both options need a Private DNS Zone. Forgetting the DNS zone is the number one reason Private Link 'does not work' on first deployment: the client resolves the public IP, and Private Link then blocks the call. Always test with nslookup.
-->

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

<!--
IP Firewall is the simplest inbound control. You allow specific public IP ranges to reach a workspace. No VNet, no DNS zone, no infrastructure.

Limits to know: maximum 100 rules per workspace, no Power BI items yet, no Fabric databases yet. The Fabric REST API stays reachable to manage rules — that is by design, to prevent lockout, but it means you must protect the API itself with Conditional Access and Service Principal governance.

You can combine IP Firewall with Private Link on the same workspace: both private paths and allowed public IPs are accepted, everything else is denied. Useful for a hybrid pattern.

GA since early 2026 for Lakehouse, Warehouse, Notebook, Pipeline, Dataflow Gen2, Eventstream and Mirrored DB.
-->

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

<!--
This is the slide that confuses everyone — take a screenshot.

Two knobs interact. The tenant has a public access setting: Allowed or Restricted. The workspace has its own: nothing, Private Link or IP Firewall.

The non-obvious case: when tenant public access is Restricted, workspace-level Private Link gives API access only. The Fabric portal still requires tenant-level Private Link.

Also remember: a tenant admin must first enable the 'Workspace-level inbound network rules' setting before any workspace admin can configure Private Link or IP Firewall. The setting itself does not enforce anything — it just unlocks the capability.
-->

---

<!-- _class: chapter -->

<div class="num">02</div>

# Secure Outbound.

Reaching private data sources — without crossing the public internet.

<!--
Pillar two. Now Fabric needs to read data from your private sources — Azure SQL, ADLS, on-prem SAP. We must avoid the public internet on every path.
-->

---

# Outbound Architecture

![w:1050](images/outbound.png)

<!--
The outbound landscape. From Fabric workspaces, you have four exit doors.

Trusted Workspace Access for firewalled ADLS Gen2. Managed Private Endpoints for Azure PaaS, going through a Managed VNet. VNet Data Gateway for Azure services in your own VNet. On-Premises Gateway for SQL Server, Oracle, SAP and files behind your corporate firewall.

Each door solves a different problem. We will see when to pick which in the next slides.
-->

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

<!--
The Managed VNet is a virtual network that Microsoft creates and manages per workspace. You do not size subnets. It is provisioned automatically on the first Spark job, or when you create the first MPE.

All outbound Spark traffic is routed through it. Inside, you place Managed Private Endpoints to reach Azure PaaS — SQL DB, ADLS Gen2, Cosmos, Key Vault, Synapse, Purview, Event Hub. Traffic stays on the Microsoft backbone.

The MPE flow: you create the endpoint from Fabric, the target service admin must approve it, then traffic flows. The approval step is intentional — it stops a workspace from connecting to a resource without the owner knowing.

Note: Spark starter pools are disabled inside the Managed VNet. Custom pools take 3 to 5 minutes for cold start — factor that into your SLA. Also not yet supported in Switzerland West and West Central US.
-->

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

<!--
Trusted Workspace Access is for one specific case: ADLS Gen2 with the storage firewall enabled. It avoids deploying a Private Endpoint when you do not need a full VNet.

Pick TWA when the target is only ADLS Gen2, RBAC is simple, and you want speed over deep isolation.

Four prerequisites — all mandatory. F SKU capacity (Trial and PPU do not qualify). A workspace identity, generated by the admin. RBAC on the storage account, typically Storage Blob Data Contributor. And a Resource Instance Rule on the storage firewall, referencing the workspace resource ID.

That last one must be deployed via ARM, Bicep or PowerShell — the Azure portal does not support it natively. If TWA does not work, check the four steps in order.
-->

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

<!--
Two gateways, two worlds.

The On-Premises Data Gateway is an agent you install on a Windows Server inside your corporate network. It opens an outbound encrypted channel to Fabric — no inbound port to open. It supports SQL Server, Oracle, SAP, Teradata and many more. You can cluster it for high availability and use Kerberos for single sign-on.

The VNet Data Gateway is the Azure-native version. No VM to maintain — Microsoft manages it inside your VNet. Use it for SQL on IaaS, Azure SQL MI behind a private endpoint, Cosmos DB.

Two recent features now GA on the VNet gateway: certificate-based authentication, and enterprise proxy support. Both are essential for organisations with mandatory proxy inspection policies.
-->

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

<!--
This matrix tells you which exit door to use for each target.

Azure PaaS goes through Managed Private Endpoints. On-prem goes through the On-Premises Gateway. Azure services in your own VNet go through the VNet Gateway. ADLS Gen2 with firewall: TWA is the lightweight option.

Some targets only have one option — Key Vault is MPE only, SAP on-prem is gateway only.

Use this matrix as a decision table during architecture review. The heuristic at the bottom is the short version you can remember: Azure PaaS goes MPE, on-prem goes On-Prem Gateway, your VNet goes VNet Gateway, ADLS-only goes TWA.
-->

---

<!-- _class: chapter -->

<div class="num">03</div>

# Exfiltration Protection.

Controlling *where* data goes — not just how it gets out.

<!--
Pillar three. We have controlled who comes in and how we reach private data. Now: where can data go out?

An authenticated user, with valid network access, could still send data to an unknown destination. That is what we block here.
-->

---

# Outbound Access Policies

![w:820](images/dep.png)

<p style="margin-top:4px; font-size:0.85em">Traffic must match a <strong>declared destination</strong> — MPE or Data Connection. Anything else: blocked by default.</p>

<!--
Outbound Access Policies turn the workspace into a deny-by-default network.

You declare each legitimate destination, either as a Managed Private Endpoint or as a Data Connection. Anything else is blocked. This protects against malicious notebooks, compromised pipelines, and accidental connections to the wrong endpoint.

Status today: GA for Lakehouse, Spark Notebooks and Spark Jobs since September 2025. GA for Dataflows, Pipelines, Copy Jobs, Warehouse and Mirrored DBs since November 2025. Power BI and Fabric Databases are on the roadmap.

Important practical advice: declare all your destinations BEFORE you enable the policy. Otherwise you will break running production jobs.
-->

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

<!--
DEP — Data Exfiltration Protection — is not a single feature. It is the convergence of three layers.

Inbound blocks bad actors at the door. Outbound blocks bad paths to the outside. Data controls block bad content even on authorized paths.

Remove any one layer and DEP leaks. Network alone will not stop an authenticated user from emailing a spreadsheet. Sensitivity labels alone will not stop a rogue notebook from posting to an unknown endpoint.

You need all three, working together. This is the most important slide of pillar three.
-->

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

<!--
Layer three of DEP is data classification and content control.

Power BI export restrictions: disable Excel, CSV and PowerPoint exports on sensitive workspaces, via tenant settings. Some are auto-disabled when tenant Private Link is on.

Endpoint DLP: Purview plus Intune block copy-paste to USB drives, personal cloud apps or personal email — on managed devices.

Sensitivity labels: auto-apply via Purview. The label travels with the data into Lakehouses, Warehouses, Semantic Models and reports.

Customer Managed Keys: a second layer of encryption with your own keys in Azure Key Vault. Full control, including the ability to revoke. CMK is GA for Lakehouse, Warehouse, Spark, Pipelines, Dataflows, ML and GraphQL since October 2025.
-->

---

<!-- _class: chapter -->

<div class="num">04</div>

# Operations.

DNS, monitoring, testing — the layers that make it actually work.

<!--
The boring part — but the part where most projects fail. DNS, monitoring, testing. The layers that make all the previous slides actually work in production.
-->

---

# DNS · The Silent Killer

![w:880](images/dns.png)

<p style="margin-top:4px; font-size:0.85em">Without the Private DNS Zone, clients resolve the public IP — Private Link then blocks. The result: <em>"works from one machine but not another."</em></p>

<!--
DNS is the silent killer of Private Link.

Without the Private DNS Zone, the client resolves the public FQDN to a public IP. Private Link then refuses the call. The result is the famous 'it works from one machine, not another'.

You need one zone per FQDN family — analysis.windows.net for Power BI, pbidedicated.windows.net for capacity, blob and dfs core for OneLake, servicebus for Eventstream, web core for portal static content.

Link the zones to every VNet that hosts a Private Endpoint or from which users connect. For hybrid: configure conditional forwarders from on-prem DNS to Azure via the DNS Private Resolver, pointing to 168.63.129.16.

Always test with nslookup before go-live. The answer must be a 10.x.x.x private IP, not a public one.
-->

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

<!--
Six tools, six purposes.

Log Analytics collects diagnostic logs — sign-ins, audit events, query performance.

Network Watcher tests VNet flows and reachability of Private Endpoints.

Microsoft Sentinel correlates signals across sources to detect anomalies — failed Conditional Access, sudden export spikes, sign-ins from unusual countries, bypass attempts.

Purview owns classification, DLP and label audit.

Azure Firewall provides centralised egress logging and a static outbound IP — useful when external partners need to whitelist your address.

The audit step is human: review IP and Conditional Access rules every quarter, remove stale entries, validate the rules still match the business reality. A control you do not monitor is a control you do not have.
-->

---

# Validation Checklist

<div class="steps">

<div class="step"><div class="step-content"><strong>Resolve DNS from a client</strong><span><code>nslookup workspace.fabric.microsoft.com</code> must return a <strong>private IP (10.x)</strong>.</span></div></div>

<div class="step"><div class="step-content"><strong>Test blocked public access</strong><span>From a non-allowed IP the connection must fail explicitly.</span></div></div>

<div class="step"><div class="step-content"><strong>Spark cold start</strong><span>First Spark job activates the Managed VNet — measure latency.</span></div></div>

<div class="step"><div class="step-content"><strong>MPE approval flow</strong><span>Verify the target service admin receives and can approve the request.</span></div></div>

<div class="step"><div class="step-content"><strong>Exfiltration attempt</strong><span>Write to an undeclared destination. The policy must block it.</span></div></div>

</div>

<!--
Five tests, before and after every change.

One: resolve DNS from a client inside the VNet. nslookup must return a 10.x.x.x private IP.

Two: try to access from a non-allowed public IP. The connection must be denied with an explicit 403, not a timeout.

Three: Spark cold start. First job in a Managed VNet takes 3 to 5 minutes — measure it and tell your users.

Four: MPE approval. Make sure the target service admin actually receives the approval request and can act on it.

Five: exfiltration test. Try to write to a destination that is not declared in the Outbound Access Policy. The policy must block it.

If any of these five fails, do not promote to production.
-->

---

<!-- _class: chapter -->

<div class="num">05</div>

# Recommendations.

What would I deploy in your context? Scenario-driven blueprints.

<!--
Last pillar. We have all the tools. Now: which combinations work in real customer scenarios?
-->

---

# Zero Trust · Reference Posture

![w:900](images/zt.png)

<p style="margin-top:4px; font-size:0.85em">Identity is the primary perimeter. Network is the second. Data is the last line.</p>

<!--
Zero Trust applied to Fabric, in three lines.

Identity is the primary perimeter — Fabric is SaaS, the network alone is not enough.

Network is the second perimeter — Private Link, IP Firewall, Managed VNet, MPE.

Data is the last line — sensitivity labels, DLP, CMK.

Each line assumes the previous one can be breached. Start with identity controls before adding network. A weak identity story makes the network design pointless.
-->

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

<!--
Four blueprints from real projects.

Standard enterprise: Conditional Access, workspace Private Link, MPE, Outbound Access Policies. The default for most companies.

Regulated — GDPR, HIPAA, PCI: same baseline plus Purview DLP and Customer Managed Keys. The audit trail is a hard requirement.

Hybrid data estate: Conditional Access plus IP Firewall, plus both gateways — VNet for Azure, On-Premises for SAP and SQL Server.

Multi-team isolation: per-workspace Private Link, per-workspace outbound policies, PIM for elevation. Each team gets its own bubble.

Pick the closest match and adjust — you do not need to invent a new architecture.
-->

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

<!--
Status check, April 2026.

GA: Conditional Access, both flavors of Private Link, IP Firewall, Managed VNet, MPE, Trusted Workspace Access, Outbound Access Policies, VNet Gateway with cert and proxy, and CMK.

Preview: Eventstream private network.

Two big planned items: Power BI network protection and Fabric Database network protection. Until those ship, you must protect Power BI items either with tenant-level Private Link or with Conditional Access.

Plan a migration window when GA arrives — workspace-level controls will be more flexible than tenant-level once everything is supported.
-->

---

<!-- _class: closing -->
<!-- _paginate: false -->
<!-- _header: '' -->
<!-- _footer: '' -->

## Takeaways

# Three pillars.<br>Defense in depth.<br>Zero blind spots.

<p>Start with identity. Layer network controls. Finish with data classification. Test every layer. Monitor the whole stack.</p>

<p style="margin-top:30px; color:rgba(255,255,255,0.5); font-size:0.85em">Source: github.com/fredgis/Divers/markdown/Fabric_Network_Security.md</p>

<!--
Three pillars, defense in depth, zero blind spots.

Start with identity — Conditional Access with MFA. Layer network controls — Private Link, IP Firewall, Managed VNet, MPE. Finish with data classification — Purview labels, DLP, CMK. Test every layer before go-live, and monitor the whole stack continuously.

The full document is on GitHub, link is at the bottom of the slide. Thank you. I am ready for your questions.
-->
