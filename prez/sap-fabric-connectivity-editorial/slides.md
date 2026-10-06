---
marp: true
theme: fabric-editorial
paginate: true
header: 'SAP × Microsoft Fabric · Connectivity Patterns'
footer: 'October 2026'
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _header: '' -->
<!-- _footer: '' -->

<div class="tag">Architecture Brief · October 2026</div>

# SAP to Microsoft Fabric.

## Eight connectivity patterns, plus BPS.<br>SAP ingestion, live queries and business solutions.

### fredgis · github.com/fredgis/fabric-foundry-kb/

---

# The Question

<div class="split">

<div>

Choose the data path before choosing the reporting tool:

**move the data, federate it, or stream it?**

Check freshness, source objects, extraction rights, and whether SAP Datasphere is available.

**BPS** adds a separate choice: deploy SAP connections, notebooks, pipelines, and business models as a packaged Fabric solution.

</div>

<div>

<div class="stat">
<div class="big">8</div>
<div class="label">connectivity patterns</div>
</div>

<div class="stat">
<div class="big">BPS</div>
<div class="label">business processing above connectivity</div>
</div>

<div class="stat">
<div class="big">06/10</div>
<div class="label">2026 source review, including FabCon Europe</div>
</div>

</div>

</div>

---

# Reference Architecture

![h:450](images/architecture.png)

_Five layers with BPS connections and processing. [Full-resolution diagram](images/architecture.png)._

---

# The Three Categories

<div class="cards">

<div class="card">
<div class="card-num">CATEGORY A</div>
<h3>Data Movement</h3>
<p>Land SAP data in <strong>OneLake</strong>. Choose full loads, watermark extraction, or delete-aware CDC.</p>
<p style="margin-top:8px"><span class="pill">M1 Batch</span> <span class="pill">M2 Mirroring</span> <span class="pill">M3 Copy CDC</span> <span class="pill">M7 Open Mirror</span></p>
</div>

<div class="card teal">
<div class="card-num">CATEGORY B</div>
<h3>Federation & Sharing</h3>
<p>M4 queries SAP. M5 exports to storage, then uses a shortcut. M8 remains a <strong>roadmap</strong> option.</p>
<p style="margin-top:8px"><span class="pill">M4 Semantic</span> <span class="pill">M5 Datasphere DP</span> <span class="pill">M8 BDC Connect</span></p>
</div>

<div class="card orange">
<div class="card-num">CATEGORY C</div>
<h3>Event-Driven</h3>
<p>Business events or replicated records feed <strong>Fabric RTI</strong>. Measure end-to-end latency.</p>
<p style="margin-top:8px"><span class="pill">M6 Eventstream</span></p>
</div>

</div>

---

<!-- _class: chapter -->

<div class="num">A</div>

# Data Movement.

---

# M1: Data Factory Connectors

<div class="split">

<div>

Seven dedicated SAP connector variants, plus OData where the source exposes a suitable API.

- **BW Application / Message Server**, **BW Open Hub Application / Message Server**, **HANA**, **SAP Table Application / Message Server**
- Support differs across Pipelines, Dataflow Gen2, and Copy Job
- Use **OPDG**, with NCo for RFC or the HANA ODBC driver

**Best for:** historical loads, daily refresh, predictable batch windows.

</div>

<div>

<div class="stat">
<div class="big">7</div>
<div class="label">dedicated SAP connector variants</div>
</div>

<div class="stat">
<div class="big">3</div>
<div class="label">authoring surfaces (Pipeline · DFG2 · Copy Job)</div>
</div>

<div class="stat">
<div class="big">GA</div>
<div class="label">classic connectors; add-on Preview is separate</div>
</div>

</div>

</div>

---

# M1 Option: Microsoft ABAP Add-On

<div class="split">

<div>

Copy Job starts extraction through OPDG. The SAP add-on writes **directly to OneLake staging**.

- Tables, views, and CDS SQL views
- Full loads or **watermark-based incremental** loads
- SAP Basis installs the Microsoft transports
- Both SAP and the gateway need outbound HTTPS to OneLake

**Hard deletes are not captured by a watermark.** Message Server is not supported.

</div>

<div>

<div class="stat">
<div class="big">PRE</div>
<div class="label">Preview, not the Datasphere CDC connector</div>
</div>

<div class="stat">
<div class="big">7.50</div>
<div class="label">NetWeaver baseline for ECC EhP 8 / BW 7.50</div>
</div>

<div class="stat">
<div class="big">No DS</div>
<div class="label">S/4HANA and BW/4HANA also supported</div>
</div>

</div>

</div>

---

# M2: Mirroring for SAP

<div class="split">

<div>

**SAP → Datasphere → ADLS Gen2 → Fabric mirroring.**

- Datasphere lands snapshots and deltas in ADLS
- Fabric reads the staging shortcut and maintains **Delta tables**
- SQL analytics endpoint is created automatically
- Direct Lake freshness also depends on model and report refresh

**Costs remain** for SAP outbound, staging, consumption, and optional extensions.

</div>

<div>

<div class="stat">
<div class="big">GA</div>
<div class="label">2026 · production-ready</div>
</div>

<div class="stat">
<div class="big">DS</div>
<div class="label">Datasphere Premium Outbound required</div>
</div>

<div class="stat">
<div class="big">0</div>
<div class="label">Fabric core replication compute charge</div>
</div>

</div>

</div>

---

# M3: Copy Job CDC for SAP

<div class="split">

<div>

**Datasphere Outbound is required.** Copy Job applies its staged changes on your schedule.

- Reads Datasphere files from **ADLS, S3, or GCS**
- Applies inserts, updates, and deletes
- Runs independently or within a pipeline
- September: SCD Type 2, audit columns, and workspace monitoring announced GA

**Best for:** controlled processing windows and orchestrated CDC. Check the destination's supported write modes.

</div>

<div>

<div class="stat">
<div class="big">GA</div>
<div class="label">Datasphere CDC source since May 2026</div>
</div>

<div class="stat">
<div class="big">DS</div>
<div class="label">Premium Outbound plus staging storage</div>
</div>

<div class="stat">
<div class="big">I/U/D</div>
<div class="label">different from the ABAP add-on's watermark</div>
</div>

</div>

</div>

---

# M7: Open Mirroring (Partner-led)

<div class="split">

<div>

A partner extracts SAP data; Fabric maintains the mirrored tables and SQL endpoint.

- **dab Nexus**, **Theobald**, **SNP**, **Simplement**, **Qlik**, **CData**, and others
- No SAP Datasphere licensing required
- The connector publishes **Parquet change files** in the landing zone
- Fabric converts and merges them into Delta tables

**Check:** source coverage, extraction mode, SAP rights, and partner licensing.

</div>

<div>

<div class="stat">
<div class="big">ISV</div>
<div class="label">product-specific SAP extraction</div>
</div>

<div class="stat">
<div class="big">~min</div>
<div class="label">near real-time</div>
</div>

<div class="stat">
<div class="big">No DS</div>
<div class="label">partner licensing still applies</div>
</div>

</div>

</div>

---

<!-- _class: chapter -->

<div class="num">B</div>

# Federation & Sharing.

---

# M4: Semantic Federation

<div class="split">

<div>

Power BI **DirectQuery** avoids a bulk SAP replica. Query results still leave SAP and may be cached.

- **DirectQuery** to SAP BW queries and InfoProviders
- **DirectQuery** to SAP HANA (calc views, native SQL)
- Source permissions apply to the **connection identity**
- Configure supported SSO for per-user SAP authorizations

**Check:** connector modeling limits and whether result transfer/caching is permitted.

</div>

<div>

<div class="stat">
<div class="big">DQ</div>
<div class="label">source executes the queries</div>
</div>

<div class="stat">
<div class="big">SAP</div>
<div class="label">authorizations depend on the connection identity</div>
</div>

<div class="stat">
<div class="big">BI</div>
<div class="label">primary use; SQL/ODBC is a separate interface</div>
</div>

</div>

</div>

---

# M5: Datasphere Data Products

<div class="split">

<div>

The SAP team prepares the dataset and **exports it to external storage**. Fabric reads it through a shortcut.

- Datasphere export produces files such as **Parquet**
- A shortcut avoids another copy of those exported files
- Plain Parquet needs processing into **Delta tables** for Direct Lake
- **OneLake → Datasphere** is also available as a replication-flow source, with Initial Only loading

**Best when:** the SAP team owns the published data product.

</div>

<div>

<div class="stat">
<div class="big">DS</div>
<div class="label">SAP Datasphere required</div>
</div>

<div class="stat">
<div class="big">Files</div>
<div class="label">exported outside SAP before the shortcut</div>
</div>

<div class="stat">
<div class="big">Delta</div>
<div class="label">required for Direct Lake consumption</div>
</div>

</div>

</div>

---

# M8: SAP BDC Connect (Roadmap)

<div class="split">

<div>

Planned **bidirectional sharing** between SAP Business Data Cloud and OneLake.

- The original announcement targeted Q3 2026
- An SAP employee's **31 August roadmap reply** now targets **end Q1 2027**, subject to change
- FabCon Europe did not confirm GA
- Sharing does not imply SAP writeback or automatic Copilot/Joule integration

**For production today:** use a released ingestion or query path.

</div>

<div>

<div class="stat">
<div class="big">⇄</div>
<div class="label">intended sharing model</div>
</div>

<div class="stat">
<div class="big">Plan</div>
<div class="label">not a confirmed public release</div>
</div>

<div class="stat">
<div class="big">Q1</div>
<div class="label">2027 target, subject to change</div>
</div>

</div>

</div>

---

<!-- _class: chapter -->

<div class="num">C</div>

# Event-Driven.

---

# M6: Event-Driven Integration

<div class="split">

<div>

Two SAP paths feed Fabric operational analytics.

- Business events: **Event Mesh → configured bridge → Event Grid namespace → Eventstream**
- Replicated records: **Datasphere → dedicated Eventstream Kafka endpoint**
- Route events to Eventhouse, Lakehouse, or Activator
- Define replay, deduplication, and delete handling

**Freshness is path-dependent.** There is no blanket sub-second end-to-end SLA.

</div>

<div>

<div class="stat">
<div class="big">GA</div>
<div class="label">Datasphere Eventstream source, September 2026</div>
</div>

<div class="stat">
<div class="big">2</div>
<div class="label">paths with different SAP prerequisites</div>
</div>

<div class="stat">
<div class="big">RTI</div>
<div class="label">Real-Time Intelligence target</div>
</div>

</div>

</div>

---

<!-- _class: chapter -->

<div class="num">D</div>

# Business Process Solutions.

---

# BPS: Connections, Notebooks and Models

<div class="split">

<div>

**BPS is a Fabric workload**, with more than a connection wizard.

- Configure the SAP source and required datasets
- Deploy notebooks and pipelines for extraction and processing
- Build **Silver and Gold** business models; Bronze is optional
- Use finance, sales, and procurement templates, including hierarchy and currency handling

It reuses supported extraction paths rather than introducing another transport protocol.

</div>

<div>

<div class="stat">
<div class="big">F2</div>
<div class="label">minimum Fabric capacity in the deployment guide</div>
</div>

<div class="stat">
<div class="big">F32+</div>
<div class="label">recommended capacity; size for the workload</div>
</div>

<div class="stat">
<div class="big">3</div>
<div class="label">business domains: finance, sales, procurement</div>
</div>

</div>

</div>

---

# BPS: Choose the SAP Connection

| Source | Supported BPS paths | Fabric processing |
|---|---|---|
| **S/4HANA 1909+** | ADF SAP CDC + SHIR (patch review); partner Open Mirroring; Datasphere through ADLS | Deployed notebooks, pipelines, Silver/Gold models |
| **ECC 6.0** | Partner Open Mirroring | ECC-specific processing and business models |
| **Salesforce** | Fabric pipelines | CRM data for supported business scenarios |

<div class="cards two">

<div class="card purple">
<div class="card-num">DEPLOYMENT CHECK</div>
<h3>BPS does not remove source restrictions</h3>
<p>ADF SAP CDC inherits the SAP Note 3255746 ODP RFC blocking risk. Datasphere and Open Mirroring require DD03ND type metadata. Check region, rights, and costs.</p>
</div>

<div class="card teal">
<div class="card-num">ARTIFACTS 1.0.5</div>
<h3>Processing and monitoring updates</h3>
<p>Contextual telemetry, selected-table orchestration, high-concurrency sessions, and ECC Record-to-Report views.</p>
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
<div class="step-content"><strong>No bulk SAP replica, but query results may leave SAP?</strong><span>→ M4 DirectQuery, with verified SSO, permissions, and caching rules</span></div>
</div>

<div class="step">
<div class="step-content"><strong>Operational events or replicated records for alerts?</strong><span>→ M6 Event Mesh bridge or the Datasphere Eventstream source</span></div>
</div>

<div class="step">
<div class="step-content"><strong>Need SAP finance, sales, or procurement models and processing?</strong><span>→ BPS, with its supported source connection and deployed notebooks/pipelines</span></div>
</div>

<div class="step">
<div class="step-content"><strong>No SAP Datasphere license available?</strong><span>→ M1 batch · M7 partner CDC · ABAP Preview; legacy ADF requires ODP patch review</span></div>
</div>

</div>

---

# Pattern Comparison

| | Movement | Freshness | Datasphere | Custom ETL | Status |
|---|:---:|:---:|:---:|:---:|:---:|
| **M1 · Batch ETL** | OneLake | Scheduled | ✘ | Required | GA / ABAP Preview |
| **M2 · Mirroring** | OneLake | Near real-time | ✔ | None | GA 2026 |
| **M3 · Copy Job CDC** | OneLake | Scheduled | ✔ | Minimal | GA |
| **M4 · Semantic Federation** | Query results | Query time | Optional | None | GA |
| **M5 · Datasphere Products** | Storage + shortcut | Scheduled | ✔ | DS-side | GA |
| **M6 · Event-Driven** | Events | Path-dependent | Option B | Routing | DS source GA |
| **M7 · Open Mirroring** | OneLake | Near real-time | ✘ | Partner | GA |
| **M8 · BDC Connect** | Planned sharing | Unconfirmed | BDC scope | Unconfirmed | Roadmap |

_BPS is a solution layer over supported ingestion paths, not a ninth transport._

---

# Network & Governance

<div class="two-col">

<div>

### Network posture

- **OPDG** for on-prem SAP behind firewalls
- An **OPDG host in Azure** still needs the SAP drivers
- **ABAP add-on:** SAP also needs outbound HTTPS to OneLake
- **SHIR** for the ADF SAP CDC path
- Pair with **Fabric Network Security** patterns (separate brief)

</div>

<div>

### Governance

- Validate SAP extraction rights and source-object coverage
- Reapply permissions at each storage and query boundary
- DirectQuery uses the configured identity; SSO is not automatic
- Confirm **BPS region support** and feature-specific preview access

</div>

</div>

---

# Costs: Separate Ingestion from Consumption

<div class="cards">

<div class="card green">
<div class="card-num">MIRRORING</div>
<h3>Core replication compute is free</h3>
<p>Mirrored storage has a capacity-based allowance. Optional CDF and other extended capabilities incur additional compute charges.</p>
</div>

<div class="card orange">
<div class="card-num">SOURCE AND TRANSPORT</div>
<h3>SAP and staging still have costs</h3>
<p>Include Datasphere Premium Outbound, ADLS/S3/GCS, gateway or SHIR hosts, and partner licenses where used.</p>
</div>

<div class="card purple">
<div class="card-num">FABRIC PROCESSING</div>
<h3>Size for the actual workload</h3>
<p>Copy Job, BPS notebooks, transformations, SQL, and Power BI consume resources. Scheduled CDC is not automatically cheaper than mirroring.</p>
</div>

</div>

---

# FabCon Europe: Released Updates

<div class="cards two">

<div class="card purple">
<div class="card-num">BARCELONA · SEPTEMBER 2026</div>
<h3>SAP Datasphere → Eventstream: GA</h3>
<p>A dedicated Kafka endpoint receives replication flows. Premium Outbound is required; no separate ADLS staging.</p>
</div>

<div class="card teal">
<div class="card-num">COPY JOB · GA</div>
<h3>History, audit and monitoring</h3>
<p>CDC, SCD Type 2, audit columns, and workspace monitoring. Check source/destination compatibility.</p>
</div>

<div class="card orange">
<div class="card-num">MIRRORING · GA ANNOUNCED</div>
<h3>Extended capabilities</h3>
<p>Optional paid CDF supports downstream change processing. The announcement does not establish SAP view mirroring support.</p>
</div>

<div class="card">
<div class="card-num">PIPELINES · GA</div>
<h3>Maintenance and retry back-off</h3>
<p>Orchestrate Lakehouse maintenance after loads and increase retry delays to reduce source pressure.</p>
</div>

</div>

---

# Preview and Roadmap Boundaries

<div class="cards two">

<div class="card orange">
<div class="card-num">ABAP ADD-ON · PREVIEW</div>
<h3>Full and watermark loads</h3>
<p>Requires supported SAP releases, imported transports, OPDG, and SAP outbound access. It is not delete-aware CDC.</p>
</div>

<div class="card teal">
<div class="card-num">COPY JOB · PREVIEW</div>
<h3>Eventstream source and destination</h3>
<p>Connect supported batch and streaming paths. Do not assume every connector combination is supported.</p>
</div>

<div class="card purple">
<div class="card-num">FABCON EUROPE · PREVIEW</div>
<h3>Dependencies and network isolation</h3>
<p>Pipeline-level dependencies and workspace Private Link for Eventstream need workload-specific evaluation.</p>
</div>

<div class="card">
<div class="card-num">BDC CONNECT · ROADMAP</div>
<h3>No confirmed GA at FabCon</h3>
<p>The SAP Community planning target is end Q1 2027, subject to change. Use released paths for production now.</p>
</div>

</div>

---

# Sources and Review Scope

<div class="two-col">

<div>

### SAP connection paths

- [Fabric connector matrix](https://learn.microsoft.com/fabric/data-factory/connector-overview)
- [SAP ABAP Add-On tutorial](https://learn.microsoft.com/fabric/data-factory/copy-job-tutorial-sap-abap)
- [Mirroring SAP](https://learn.microsoft.com/fabric/mirroring/sap)
- [Datasphere Outbound in Copy Job](https://learn.microsoft.com/fabric/data-factory/copy-job-tutorial-sap-datasphere)
- [Datasphere Eventstream source](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-source-sap-datasphere)

</div>

<div>

### BPS and release status

- [Business Process Solutions](https://learn.microsoft.com/azure/sap/business-process-solutions/about-business-process-solutions)
- [BPS release notes](https://learn.microsoft.com/azure/sap/business-process-solutions/release-notes)
- [September 2026 feature summary](https://community.fabric.microsoft.com/blog/fbc_fabricupdatesblogs/fabric-september-2026-feature-summary/5325825)
- [FabCon Europe announcement](https://aka.ms/FabCon-SQLCon-Barcelona)
- [SAP Community BDC roadmap reply](https://community.sap.com/t5/data-and-ai-professionals-q-a/sap-bdc-connect-for-microsoft-fabric-ga/qaq-p/14469254)

</div>

</div>

_Reviewed 6 October 2026. September release announcements postdate some Learn Preview labels._

---

<!-- _class: closing -->

# SAP connectivity,<br>with the business model in view.

## fredgis · github.com/fredgis/fabric-foundry-kb

Use released paths for production. Add BPS when its business models and processing match the requirement.
