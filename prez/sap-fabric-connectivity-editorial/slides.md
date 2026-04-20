---
marp: true
theme: fabric-editorial
paginate: true
header: 'SAP × Microsoft Fabric · Connectivity Patterns'
footer: 'April 2026'
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _header: '' -->
<!-- _footer: '' -->

<div class="tag">Architecture Brief · April 2026</div>

# SAP to Microsoft Fabric.

## Eight integration patterns. One unified data estate.<br>From batch ETL to zero-copy AI.

### fredgis · github.com/fredgis/fabric-foundry-kb/

---

# The Question

<div class="split">

<div>

Every SAP-to-Fabric project starts with the same trade-off:

**move the data, federate it, or stream it?**

The right answer depends on freshness, governance ownership, source system, and whether SAP Datasphere is licensed.

Fabric exposes **eight** distinct patterns — picking wisely avoids re-platforming a year later.

</div>

<div>

<div class="stat">
<div class="big">8</div>
<div class="label">integration patterns in 2026</div>
</div>

<div class="stat">
<div class="big">3</div>
<div class="label">categories: movement · federation · events</div>
</div>

<div class="stat">
<div class="big">1</div>
<div class="label">copy of the data — OneLake</div>
</div>

</div>

</div>

---

# Reference Architecture

![h:490](images/architecture.png)

_Five layers · sources → connectivity → methods → Fabric storage → consumption._

---

# The Three Categories

<div class="cards">

<div class="card">
<div class="card-num">CATEGORY A</div>
<h3>Data Movement</h3>
<p>Land SAP data in <strong>OneLake</strong> as Delta tables. Best freshness for analytics & AI.</p>
<p style="margin-top:8px"><span class="pill">M1 Batch</span> <span class="pill">M2 Mirroring</span> <span class="pill">M3 Copy CDC</span> <span class="pill">M7 Open Mirror</span></p>
</div>

<div class="card teal">
<div class="card-num">CATEGORY B</div>
<h3>Federation & Zero-Copy</h3>
<p>Data <strong>stays in SAP</strong>. Fabric queries live or via shortcut.</p>
<p style="margin-top:8px"><span class="pill">M4 Semantic</span> <span class="pill">M5 Datasphere DP</span> <span class="pill">M8 BDC Connect</span></p>
</div>

<div class="card orange">
<div class="card-num">CATEGORY C</div>
<h3>Event-Driven</h3>
<p>Sub-second operational signals via <strong>SAP Event Mesh → Fabric RTI</strong>.</p>
<p style="margin-top:8px"><span class="pill">M6 Eventstream</span></p>
</div>

</div>

---

<!-- _class: chapter -->

<div class="num">A</div>

# Data Movement.

---

# M1 — Data Factory Connectors

<div class="split">

<div>

The **default**, mature path. Seven dedicated SAP connectors plus OData for SaaS sources.

- **SAP HANA**, **SAP BW Application Server**, **SAP BW Open Hub**, **SAP Table**, **SAP ECC**, **SAP S/4HANA**, **SAP Cloud for Customer**
- Built-in to **Pipelines**, **Dataflow Gen2**, and **Copy Job**
- On-prem SAP requires **OPDG + SAP .NET Connector (NCo)**

**Best for:** historical loads, daily refresh, predictable batch windows.

</div>

<div>

<div class="stat">
<div class="big">7</div>
<div class="label">native SAP connectors</div>
</div>

<div class="stat">
<div class="big">3</div>
<div class="label">authoring surfaces (Pipeline · DFG2 · Copy Job)</div>
</div>

<div class="stat">
<div class="big">GA</div>
<div class="label">since 2023 — proven at scale</div>
</div>

</div>

</div>

---

# M2 — Mirroring for SAP

<div class="split">

<div>

**Near real-time replication** of SAP data to OneLake — orchestrated through SAP Datasphere.

- Continuous CDC pushed to a managed **Delta Lake** in OneLake
- **No custom ETL.** Schema and table list configured once
- SQL Analytics Endpoint auto-provisioned
- Direct Lake semantic models read it instantly

**Trade-off:** requires **SAP Datasphere** licensing.

</div>

<div>

<div class="stat">
<div class="big">GA</div>
<div class="label">2026 · production-ready</div>
</div>

<div class="stat">
<div class="big">~min</div>
<div class="label">end-to-end latency</div>
</div>

<div class="stat">
<div class="big">0</div>
<div class="label">ETL code to write</div>
</div>

</div>

</div>

---

# M3 — Copy Job CDC for SAP

<div class="split">

<div>

A **lighter alternative** to Mirroring — scheduled deltas via the **Copy Job** experience, no Datasphere required.

- Uses **ODP** / **SAP SLT** to capture changes
- Configurable frequency (minutes → hours)
- Cheaper compute than continuous mirroring
- Ideal companion to multi-source Pipelines

**Best for:** mid-volume incremental loads, cost-conscious teams.

</div>

<div>

<div class="stat">
<div class="big">Preview</div>
<div class="label">FabCon 2026 announcement</div>
</div>

<div class="stat">
<div class="big">No DS</div>
<div class="label">SAP Datasphere not required</div>
</div>

<div class="stat">
<div class="big">CDC</div>
<div class="label">native delta capture</div>
</div>

</div>

</div>

---

# M7 — Open Mirroring (Partner-led)

<div class="split">

<div>

Same Mirroring **UX and SQL endpoint**, but the replication is driven by a **certified partner connector**.

- **dab Nexus**, **Theobald Xtract Universal**, **Fivetran**, others
- No SAP Datasphere licensing required
- Partner handles ODP / SLT / log-based capture
- Fabric handles storage, governance, BI

**Best for:** mid-market without Datasphere, or teams already invested in a partner tool.

</div>

<div>

<div class="stat">
<div class="big">3+</div>
<div class="label">certified partners GA</div>
</div>

<div class="stat">
<div class="big">~min</div>
<div class="label">near real-time</div>
</div>

<div class="stat">
<div class="big">No DS</div>
<div class="label">vendor-managed pipe</div>
</div>

</div>

</div>

---

<!-- _class: chapter -->

<div class="num">B</div>

# Federation & Zero-Copy.

---

# M4 — Semantic Federation

<div class="split">

<div>

Data **never leaves SAP**. Power BI queries SAP BW or HANA **live**.

- **Live Connection** to SAP BW (BEx queries, multi-providers)
- **DirectQuery** to SAP HANA (calc views, native SQL)
- Single sign-on with Entra ID
- SAP-side row-level security honored

**Best when:** governance, regulation, or contracts forbid copying SAP data.

</div>

<div>

<div class="stat">
<div class="big">0</div>
<div class="label">bytes copied</div>
</div>

<div class="stat">
<div class="big">SAP</div>
<div class="label">retains governance &amp; security</div>
</div>

<div class="stat">
<div class="big">BI</div>
<div class="label">Power BI consumption only</div>
</div>

</div>

</div>

---

# M5 — Datasphere Data Products

<div class="split">

<div>

The **SAP team owns the data product**. They publish governed datasets to cloud storage; Fabric mounts them.

- Datasphere **Premium Outbound** writes Delta to **ADLS / S3 / GCS**
- Fabric mounts via **OneLake Shortcut** — no copy
- SAP-side semantics, lineage, contracts preserved
- Fabric adds enrichment, ML, BI on top

**Best when:** SAP CoE drives "data as a product" governance.

</div>

<div>

<div class="stat">
<div class="big">DS</div>
<div class="label">SAP Datasphere required</div>
</div>

<div class="stat">
<div class="big">0</div>
<div class="label">copy in Fabric (shortcut)</div>
</div>

<div class="stat">
<div class="big">→</div>
<div class="label">SAP-owned governance</div>
</div>

</div>

</div>

---

# M8 — SAP BDC Connect for Fabric

<div class="split">

<div>

The **strategic 2026 milestone**: bi-directional **zero-copy** sharing between SAP Business Data Cloud and OneLake.

- Single source of truth across both platforms
- **Microsoft Copilot** + **SAP Joule** collaborate on the same data
- No replication, no schema drift
- Native BDC governance preserved

**Status:** Preview now · GA Q3 2026.

</div>

<div>

<div class="stat">
<div class="big">⇄</div>
<div class="label">bi-directional zero-copy</div>
</div>

<div class="stat">
<div class="big">AI</div>
<div class="label">Copilot + Joule cross-platform</div>
</div>

<div class="stat">
<div class="big">Q3</div>
<div class="label">2026 GA target</div>
</div>

</div>

</div>

---

<!-- _class: chapter -->

<div class="num">C</div>

# Event-Driven.

---

# M6 — Event-Driven Integration

<div class="split">

<div>

For **operational analytics** that can't wait for the next CDC cycle.

- **SAP Event Mesh** (BTP) emits CloudEvents
- **Azure Event Grid** bridges into Azure
- **Fabric Eventstream** lands them in **KQL DB** or **Lakehouse**
- **Activator** triggers reflexes (alerts, workflows, downstream calls)

**Best for:** order tracking, SLA monitoring, real-time inventory.

</div>

<div>

<div class="stat">
<div class="big">&lt;1s</div>
<div class="label">end-to-end latency</div>
</div>

<div class="stat">
<div class="big">BTP</div>
<div class="label">requires SAP BTP Event Mesh</div>
</div>

<div class="stat">
<div class="big">RTI</div>
<div class="label">Real-Time Intelligence target</div>
</div>

</div>

</div>

---

<!-- _class: chapter -->

<div class="num">04</div>

# How to Choose.

---

# Decision Heuristics

<div class="steps">

<div class="step">
<div class="step-content"><strong>Need data physically in OneLake (BI · ML · cross-source joins)?</strong><span>→ M1 (batch) · M2 (Mirroring + DS) · M3 (Copy Job CDC) · M7 (Partner)</span></div>
</div>

<div class="step">
<div class="step-content"><strong>Data must remain in SAP for governance or regulatory reasons?</strong><span>→ M4 (Semantic Federation) · M5 (Datasphere Data Products) · M8 (BDC Connect)</span></div>
</div>

<div class="step">
<div class="step-content"><strong>Sub-second operational events, alerting, reflexes?</strong><span>→ M6 (Event Mesh → Eventstream → Activator)</span></div>
</div>

<div class="step">
<div class="step-content"><strong>Cross-platform AI with Copilot and SAP Joule on one truth?</strong><span>→ M8 (BDC Connect, Q3 2026)</span></div>
</div>

<div class="step">
<div class="step-content"><strong>No SAP Datasphere license available?</strong><span>→ M1 + OPDG · M3 Copy Job CDC · M7 Open Mirroring (partner)</span></div>
</div>

</div>

---

# Pattern Comparison

| | Movement | Freshness | Datasphere | Custom ETL | Status |
|---|:---:|:---:|:---:|:---:|:---:|
| **M1 · Batch ETL** | OneLake | Hours / daily | ✘ | High | GA 2023 |
| **M2 · Mirroring** | OneLake | Near real-time | ✔ | None | GA 2026 |
| **M3 · Copy Job CDC** | OneLake | Minutes | ✘ | Minimal | Preview |
| **M4 · Semantic Federation** | None | Live query | ✘ | None | GA |
| **M5 · Datasphere Products** | Storage + shortcut | Scheduled | ✔ | DS-side | GA |
| **M6 · Event-Driven** | Events | Sub-second | ✘ | Routing | GA |
| **M7 · Open Mirroring** | OneLake | Near real-time | ✘ | Partner | GA |
| **M8 · BDC Connect** | Zero-copy | Live | ✘ | None | Preview |

---

# Network & Governance — Don't Skip

<div class="two-col">

<div>

### Network posture

- **OPDG** for on-prem SAP behind firewalls
- **VNet Data Gateway** when SAP runs in your Azure VNet
- **Private Link** to OneLake for inbound enterprise access
- Pair with **Fabric Network Security** patterns (separate brief)

</div>

<div>

### Governance

- **OneLake = single tenant copy** — federate, don't duplicate
- **Purview** lineage spans connectors, mirrors, shortcuts
- **Direct Lake** for BI freshness without re-import
- Decide **owner** early: Fabric team vs. SAP CoE

</div>

</div>

---

# Headline Announcements

<div class="cards two">

<div class="card purple">
<div class="card-num">IGNITE 2025</div>
<h3>Mirroring for SAP — GA</h3>
<p>Continuous near-real-time replication to OneLake via Datasphere reaches general availability.</p>
</div>

<div class="card teal">
<div class="card-num">IGNITE 2025</div>
<h3>Direct Lake — GA March 2026</h3>
<p>Power BI semantic models read OneLake Delta directly — Import speed, DirectQuery freshness.</p>
</div>

<div class="card orange">
<div class="card-num">FABCON 2026</div>
<h3>Copy Job CDC for SAP</h3>
<p>Scheduled incremental deltas via ODP / SLT — no Datasphere required.</p>
</div>

<div class="card">
<div class="card-num">FABCON 2026</div>
<h3>SAP BDC Connect — Preview</h3>
<p>Bi-directional zero-copy share between BDC and OneLake. GA target Q3 2026.</p>
</div>

</div>

---

<!-- _class: closing -->

# One platform.<br>Eight paths in.<br>Pick by freshness, governance, and AI ambition.

## fredgis · github.com/fredgis/fabric-foundry-kb/markdown/SAP_Fabric_Connectivity.md
