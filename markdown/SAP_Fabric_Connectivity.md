---
title: "SAP to Microsoft Fabric Connectivity"
subtitle: "Current architecture patterns, product status, and decision guide"
date: "September 2026"
abstract: |
  This whitepaper compares the supported ways to connect SAP data and events to Microsoft Fabric. It covers Fabric Data Factory connectors, the SAP ABAP Add-On for Copy Job, Mirroring for SAP through SAP Datasphere, Copy Job CDC through SAP Datasphere Outbound, semantic federation, governed data exchange, Eventstream, Open Mirroring partners, and SAP Business Data Cloud Connect.

  The September 2026 edition also addresses the SAP ODP RFC security change, current preview and GA boundaries, Direct Lake behavior, network requirements, licensing checkpoints, and a production selection process.
---

> **Scope.** Product status and technical claims were checked against Microsoft and SAP sources available on September 11, 2026. Preview features, partner capabilities, and planned release dates can change.
>
> **Important correction.** The current architecture has eight decision patterns, but Method 1 now contains two distinct extraction paths: the classic Fabric SAP connectors and the new Copy Job for SAP with Microsoft ABAP Add-On, which is in preview.

## Executive summary

Microsoft Fabric does not have one universal SAP connector. The right path depends on whether the requirement is batch extraction, change replication, source-side semantic queries, operational events, partner-managed CDC, or planned SAP Business Data Cloud sharing.

| Method | Current status | Data movement | Best fit |
| --- | --- | --- | --- |
| 1. Fabric Data Factory extraction | Classic connectors available; ABAP Add-On in Preview | Yes | Batch and watermark-based ingestion |
| 2. Mirroring through SAP Datasphere | GA | Yes, continuously merged into OneLake | Managed SAP replication with SAP Datasphere |
| 3. Copy Job CDC through SAP Datasphere | SAP source announced GA, but current Microsoft metadata conflicts | Yes | Controlled SAP delta replication through cloud staging |
| 4. Semantic federation | GA | No bulk replication | Live Power BI queries against SAP BW or SAP HANA |
| 5. SAP Datasphere governed exchange | Available building blocks | Depends on the chosen flow | SAP-owned data products and controlled exchange |
| 6. Event-driven integration | Available | Events or replicated changes | Operational analytics and alerting |
| 7. Open Mirroring partners | Open Mirroring available; partner scope varies | Yes | Near-real-time replication without SAP Datasphere |
| 8. SAP BDC Connect for Fabric | Planned for Q3 2026; public GA not confirmed on September 11 | Planned zero-copy sharing | Future governed SAP BDC and OneLake exchange |

### What changed since the June 2026 edition

| Change | Impact on this guide |
| --- | --- |
| Copy Job for SAP with Microsoft ABAP Add-On entered Preview on June 3, 2026 | Added as a first-class subpattern in Method 1 |
| Microsoft updated the Azure Data Factory SAP CDC guidance with the SAP Note 3255746 warning | The legacy ADF SAP CDC path is now treated as migration risk, not a strategic default |
| Microsoft announced SAP Datasphere as a GA CDC source, while the current connector page still labels CDC replication Preview | Method 3 now records the status conflict instead of claiming unconditional GA |
| SAP Datasphere added a Microsoft OneLake connection for replication-flow source objects | Method 5 now covers the Fabric-to-Datasphere direction accurately |
| Eventstream private-network connector support became GA in July 2026 | Method 6 now separates private pull patterns from the public custom Kafka endpoint |
| Mirrored Database Change Feed became an Eventstream source in Preview | The current source list does not name Mirrored SAP, so it is not presented as an SAP production route |
| Direct Lake documentation now distinguishes Direct Lake on OneLake from Direct Lake on SQL | The semantic-layer guidance no longer treats all Direct Lake models as equivalent |
| SAP BDC Connect was planned for Q3 2026, but no public GA confirmation was found by September 11 | Method 8 remains a planned architecture, not a production recommendation |
| The Open Mirroring partner page expanded its SAP-capable list | Method 7 now uses the current Microsoft-maintained partner list |
| SAP BW connector implementation 1.0 was deprecated | New SAP BW connections should use implementation 2.0 |

### Document color key

| Marker | PDF color | Method |
| --- | --- | --- |
| M1 | Amber | Fabric Data Factory extraction |
| M2 | Green | Mirroring through SAP Datasphere |
| M3 | Olive green | Copy Job CDC through SAP Datasphere |
| M4 | Blue | Semantic federation |
| M5 | Teal | SAP Datasphere governed exchange |
| M6 | Rust | Event-driven integration |
| M7 | Indigo | Open Mirroring partners |
| M8 | Magenta | SAP Business Data Cloud Connect |

### Revision history

| Version | Date | Change summary |
| --- | --- | --- |
| 1.0 | April 13, 2026 | Initial eight-pattern connectivity guide |
| 1.1 | May 15, 2026 | SAP Sapphire 2026 and BDC roadmap refresh |
| 1.2 | June 2, 2026 | Copy Job CDC status update |
| 2.0 | September 11, 2026 | Full source audit, architecture refresh, and PDF redesign |
| 2.1 | September 11, 2026 | Decision, security, data-contract, and operations hardening |

## Architecture map

```mermaid
flowchart TB
    subgraph SAP["SAP estate"]
        S4["SAP S/4HANA"]
        ECC["SAP ECC"]
        BW["SAP BW and BW/4HANA"]
        HANA["SAP HANA"]
        DS["SAP Datasphere"]
        BTP["SAP BTP and Event Mesh"]
        BDC["SAP Business Data Cloud"]
    end

    subgraph Move["Data movement"]
        M1["Method 1<br/>Fabric Data Factory extraction"]
        M2["Method 2<br/>Mirroring through Datasphere"]
        M3["Method 3<br/>Copy Job CDC through Datasphere"]
        M7["Method 7<br/>Open Mirroring partners"]
    end

    subgraph Federate["Federation and sharing"]
        M4["Method 4<br/>Semantic federation"]
        M5["Method 5<br/>Datasphere governed exchange"]
        M8["Method 8<br/>SAP BDC Connect"]
    end

    subgraph Events["Events"]
        M6["Method 6<br/>Event-driven integration"]
    end

    subgraph Fabric["Microsoft Fabric"]
        OL["OneLake"]
        LH["Lakehouse or Warehouse"]
        ES["Eventstream and Eventhouse"]
        PBI["Power BI semantic models"]
    end

    S4 & ECC & BW & HANA --> M1
    S4 & ECC & BW & DS --> M2
    S4 & ECC & BW & DS --> M3
    S4 & ECC & BW --> M7
    BW & HANA --> M4
    DS --> M5
    DS & BTP --> M6
    BDC --> M8

    M1 & M2 & M3 & M7 --> OL
    M5 --> OL
    M8 -.-> OL
    M6 --> ES
    OL --> LH --> PBI
    M4 -.-> PBI

    classDef sap fill:#0B6CA0,stroke:#003D66,color:#ffffff,font-weight:bold
    classDef movement fill:#D97706,stroke:#92400E,color:#ffffff,font-weight:bold
    classDef federation fill:#1565C0,stroke:#0D47A1,color:#ffffff,font-weight:bold
    classDef event fill:#C2410C,stroke:#7C2D12,color:#ffffff,font-weight:bold
    classDef fabric fill:#6A1B9A,stroke:#4A148C,color:#ffffff,font-weight:bold

    class S4,ECC,BW,HANA,DS,BTP,BDC sap
    class M1,M2,M3,M7 movement
    class M4,M5,M8 federation
    class M6 event
    class OL,LH,ES,PBI fabric
```

### End-to-end reference architecture

![SAP to Microsoft Fabric connectivity reference architecture](../images/SAP_Fabric_Connectivity_Architecture.png){width=100%}

> Editable source: [`images/SAP_Fabric_Connectivity_Architecture.drawio`](../images/SAP_Fabric_Connectivity_Architecture.drawio).

## Selection principles

Use four questions to narrow the design:

1. Must the data move into OneLake, or must it remain in SAP?
2. Is the requirement a full copy, watermark increment, source-native delta, or business event?
3. Which SAP-managed component is available: SAP Datasphere, SAP BTP, SAP BDC, or none?
4. Who will operate the integration: the Fabric team, the SAP team, or a partner product?

Do not select a method from freshness labels alone. "Near real-time" can mean seconds, minutes, or simply continuous operation. Measure end-to-end latency with the real source, network, staging layer, and destination.

## SAP eligibility matrix

System compatibility and object eligibility are separate checks. Use this matrix as the start of a project-specific inventory, then attach the exact SAP Notes and connector documentation used for approval.

| SAP edition and deployment | Release baseline | Object or container | Access mechanism | Load behavior to validate |
| --- | --- | --- | --- | --- |
| SAP S/4HANA on-premises | Source-specific; CDS replication-flow guidance starts at S/4HANA 1909 | Extraction-enabled CDS views in `CDS_EXTRACTION` | SAP Datasphere replication flow | Initial and Delta only when the object and key behavior support it |
| SAP S/4HANA Cloud | Validate the current cloud edition and communication scenario | Extraction-enabled CDS views in `CDS_EXTRACTION` | SAP S/4HANA Cloud connection | Initial or delta according to the exposed object |
| SAP S/4HANA Cloud or SAP BTP ABAP environment | Validate ABAP SQL Service support | CDS view entities in `SQL_SERVICE` | ABAP SQL Service | Federation or replication according to the published service |
| SAP ECC and SAP BW | Validate release, ODP 2.0 source, and required SAP Notes | BW/SAPI DataSources | SAP Datasphere replication flow | Initial or delta by DataSource; objects without a stable key can be Initial Only |
| SAP BW/4HANA | Validate the source container and object type | Supported BW/4HANA objects | Datasphere, Power BI BW connector, or partner path | Do not infer BW Open Hub support |
| SAP HANA | Any version for the Fabric HANA connector; validate views and drivers | Tables, analytic views, or calculation views | HANA connector, SQL, or DirectQuery | Full, watermark incremental, or query-time access depending on path |
| Microsoft ABAP Add-On | Microsoft states S/4HANA all versions and ECC 6.0 EhP 8 | Transparent, pool, and cluster tables; views; CDS SQL views | Copy Job through Application Server | Full or watermark incremental only; no delete-aware CDC |
| Classic SAP Table connector | SAP ECC 7.01+, S/4HANA, and supported Business Suite releases | Tables and views supported by the RFC connector | Pipeline or Copy Job through OPDG and NCo | Full or watermark incremental where documented |

The phrase "S/4HANA all versions" comes from the ABAP Add-On documentation. It does not prove support for every edition, hosting model, add-on installation path, custom object, or SAP patch level.

Sources: [SAP S/4HANA Cloud connections](https://help.sap.com/docs/SAP_DATASPHERE/be5967d099974c69b77f4549425ca4c0/a98e5ffdf47c44d9a845dca01a18bd82.html), [ABAP SQL Services](https://help.sap.com/docs/SAP_DATASPHERE/9f804b8efa8043539289f42f372c4862/4d7474595a5b41bb986616262ff44a3a.html), [SAP replication-flow source selection](https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Acquiring-Preparing-Modeling-Data/Acquiring-and-Preparing-Data-in-the-Data-Builder/add-the-source-for-a-replication-flow-7496380.md).

## Method 1: Fabric Data Factory extraction

Method 1 covers two related but different paths:

- the established Fabric connectors for SAP BW, SAP BW Open Hub, SAP HANA, SAP Table, and OData;
- Copy Job for SAP with Microsoft Data Integration ABAP Add-On, introduced in Preview in June 2026.

### Architecture

```mermaid
flowchart LR
    subgraph SAP["SAP systems"]
        A["SAP BW, HANA,<br/>ECC, or S/4HANA"]
    end

    subgraph Access["Extraction path"]
        OPDG["On-premises<br/>data gateway"]
        NCO["SAP .NET Connector<br/>or HANA client"]
        ADDON["Microsoft ABAP Add-On<br/>Preview"]
    end

    subgraph DF["Fabric Data Factory"]
        DFG2["Dataflow Gen2"]
        PIPE["Pipeline Copy activity"]
        CJ["Copy Job"]
    end

    subgraph Dest["Fabric destinations"]
        LH["Lakehouse"]
        WH["Warehouse"]
        SQL["SQL database"]
    end

    A --> OPDG
    OPDG --> NCO --> DFG2
    NCO --> PIPE
    NCO --> CJ
    A --> ADDON --> CJ
    DFG2 --> LH
    PIPE --> LH
    CJ --> LH
    CJ --> WH
    CJ --> SQL

    classDef sap fill:#0B6CA0,stroke:#003D66,color:#ffffff,font-weight:bold
    classDef access fill:#F59E0B,stroke:#B45309,color:#1a1a1a,font-weight:bold
    classDef fabric fill:#D97706,stroke:#92400E,color:#ffffff,font-weight:bold
    classDef dest fill:#6A1B9A,stroke:#4A148C,color:#ffffff,font-weight:bold

    class A sap
    class OPDG,NCO,ADDON access
    class DFG2,PIPE,CJ fabric
    class LH,WH,SQL dest
```

### Classic connector support matrix

The current Fabric connector overview lists these capabilities:

| Connector | Dataflow Gen2 source | Pipeline source | Copy Job source | Gateway |
| --- | :---: | :---: | :---: | --- |
| SAP BW Application Server | Yes | No | No | On-premises |
| SAP BW Message Server | Yes | No | No | On-premises |
| SAP BW Open Hub Application Server | No | Yes | Yes, full load | On-premises |
| SAP BW Open Hub Message Server | No | Yes | Yes, full load | On-premises |
| SAP HANA | Yes | Yes | Yes, full and watermark incremental | On-premises |
| SAP Table Application Server | No | Yes | Yes, full and watermark incremental | On-premises |
| SAP Table Message Server | No | Yes | Yes, full load | On-premises |
| OData | Yes | Yes | Yes, full load | None, on-premises, or virtual network |

The Fabric connector pages describe each connector as a source. They do not provide an SAP destination connector.

SAP BW Open Hub supports SAP BW 7.01 and later but not SAP BW/4HANA. For BW/4HANA, use a supported BW query path, SAP Datasphere, the ABAP Add-On where applicable, or a verified partner connector.

The Power Query SAP BW connector implementation 1.0 is deprecated. New connections use implementation 2.0. Existing estates should inventory connector versions before changing gateway or Power BI deployments.

### Classic connector prerequisites

- SAP BW and SAP Table paths use an on-premises data gateway and SAP Connector for Microsoft .NET.
- SAP HANA uses an on-premises data gateway and the required SAP HANA client components.
- OData can use a cloud, on-premises, or virtual network gateway path depending on endpoint exposure.
- The SAP technical account needs only the RFC, table, view, or query permissions required by the selected connector.
- Network ports depend on the SAP instance and listener configuration. Do not treat `33xx` or `30015` as universal values.

### Copy Job with SAP ABAP Add-On

The ABAP Add-On path is a separate Preview feature. Microsoft installs a proprietary data integration add-on in SAP. During a Copy Job run:

1. The on-premises data gateway connects to the SAP application server over RFC.
2. The add-on extracts data with ABAP SQL.
3. SAP writes the extracted data to OneLake staging over HTTPS.
4. Copy Job writes from staging to the configured destination.

Supported source systems and objects are narrower than the classic connector estate:

| Area | Current Preview support |
| --- | --- |
| SAP systems | SAP S/4HANA all versions; SAP ECC 6.0 EhP 8 on NetWeaver 7.50 |
| Unsupported baseline | SAP ECC EhP 7 and earlier |
| Objects | Transparent, pool, and cluster tables; views; CDS SQL views |
| Modes | Full copy and watermark-based incremental copy |
| Gateway topology | Application Server only; Message Server is not supported |

This feature does not provide log-based CDC. Incremental mode depends on a timestamp, date, or supported numeric watermark. Deletes that do not produce a later source record are not inherently captured.

Known Preview limits include:

- source names containing special characters such as `/` are unsupported;
- SAP-to-OneLake staging times out after 12 hours and each table after 24 hours end to end;
- invalid SAP date values can fail destination type conversion;
- date-only watermarks can reread rows during repeated daily runs;
- large SAP catalogs can exceed the UI list, requiring manual object entry.

### When to use Method 1

Use the classic connectors for established batch and watermark patterns where the source object is supported and the gateway model is acceptable.

Use the ABAP Add-On Preview only when its system version, deployment model, and operational limits fit the project. It is strategically important because it does not use the ODP RFC API, but it still needs a production readiness review while in Preview.

Sources: [Fabric connector overview](https://learn.microsoft.com/en-us/fabric/data-factory/connector-overview), [Copy Job with SAP ABAP Add-On](https://learn.microsoft.com/en-us/fabric/data-factory/copy-job-tutorial-sap-abap).

## Method 2: Mirroring for SAP through SAP Datasphere

Mirroring for SAP is a two-stage replication pattern:

```mermaid
flowchart LR
    subgraph SAP["SAP source"]
        SRC["S/4HANA, ECC,<br/>BW, BW/4HANA,<br/>or Datasphere"]
    end

    subgraph DS["SAP Datasphere"]
        RF["Replication Flow<br/>Initial and Delta"]
    end

    subgraph Stage["Azure storage"]
        ADLS["ADLS Gen2<br/>Parquet files"]
    end

    subgraph Fabric["Microsoft Fabric"]
        SC["Lakehouse shortcut"]
        MIR["Mirrored SAP database"]
        OL["OneLake Delta tables"]
        SQL["Read-only SQL<br/>analytics endpoint"]
    end

    SRC --> RF --> ADLS --> SC --> MIR --> OL --> SQL

    classDef sap fill:#0B6CA0,stroke:#003D66,color:#ffffff,font-weight:bold
    classDef ds fill:#2E7D32,stroke:#1B5E20,color:#ffffff,font-weight:bold
    classDef stage fill:#F59E0B,stroke:#B45309,color:#1a1a1a,font-weight:bold
    classDef fabric fill:#6A1B9A,stroke:#4A148C,color:#ffffff,font-weight:bold

    class SRC sap
    class RF ds
    class ADLS stage
    class SC,MIR,OL,SQL fabric
```

SAP Datasphere extracts an initial snapshot and subsequent changes into ADLS Gen2. Fabric points a Lakehouse shortcut at the storage path, creates a Mirrored SAP item, and continuously merges the files into Delta tables in OneLake.

### Status and supported scope

Mirroring for SAP through SAP Datasphere is generally available. Microsoft explicitly lists:

- SAP S/4HANA;
- SAP ECC;
- SAP BW/4HANA;
- SAP BW;
- SAP Datasphere itself.

The phrase "all sources supported by SAP Datasphere" should not be used to infer support for every SaaS application without checking the SAP replication-flow source matrix.

### Source and object eligibility

The SAP source name alone is not enough to establish support:

| Source area | Production check |
| --- | --- |
| SAP S/4HANA CDS extraction | Validate the S/4HANA release, required SAP Notes, and supported CDS extraction objects. Current SAP guidance starts CDS replication-flow support at S/4HANA 1909. |
| SAP ECC and SAP BW | Validate the ODP 2.0 BW/SAPI DataSources exposed to the replication flow. |
| SAP BW/4HANA | Validate the supported source container and object type rather than assuming BW Open Hub support. |
| SLT-backed extraction | Validate the SAP release, DMIS or SLT level, and source-table constraints. |
| Objects without a stable key | Expect Initial Only behavior unless the current source documentation states that delta replication is supported. |

Keep the required SAP Notes with the deployment record. They vary by SAP release and can change after security patches.

### Required configuration

- Fabric capacity or trial.
- SAP Datasphere with Premium Outbound Integration.
- An ADLS Gen2 target for the SAP Datasphere replication flow.
- A replication flow with **Group Delta = None** and **File Type = Parquet**.
- Load type **Initial and Delta** or **Initial Only**.
- A Lakehouse shortcut that points to the complete ADLS container path.
- A Mirrored SAP item that reads the shortcut path.

Mirroring ingests every object under the configured shortcut path. Add or remove objects through the SAP Datasphere Replication Flow, then clean the storage path when required. Use a separate container or root path for each approved replication scope, and put table additions and removals under change control. A shortcut that points too high in the hierarchy can widen the ingestion scope unintentionally.

General Fabric Mirroring limits apply to SAP mirrors. Current guidance documents up to 1,000 tables and up to 1 TB of captured changes per mirrored database per day. Treat these as platform guardrails, then validate the lower practical limit created by SAP Datasphere, ADLS throughput, file counts, and Fabric capacity.

Fabric no longer creates a default Power BI semantic model automatically for new mirrored items. Create and govern the semantic model explicitly.

### Cost and operations

Fabric does not charge CUs for background mirroring replication, but a running capacity is required. Mirroring storage is included up to 1 TB per purchased CU, after which storage is charged. Storage charges continue while capacity is paused. SQL, Power BI, Spark, and direct OneLake access consume capacity normally. SAP Datasphere Premium Outbound Integration has its own capacity and commercial model.

Monitoring is split:

- SAP Datasphere monitors extraction from SAP to ADLS;
- Fabric monitors ADLS-to-OneLake mirroring.

A delay must be traced across both stages.

### When to use Method 2

Use Mirroring when SAP Datasphere is available, continuous managed replication is preferred, and the architecture can accept ADLS staging plus Premium Outbound Integration.

Do not call it zero-copy. SAP Datasphere writes Parquet to ADLS, and Fabric creates Delta data in OneLake.

Sources: [Mirrored databases from SAP](https://learn.microsoft.com/en-us/fabric/mirroring/sap), [SAP mirroring tutorial](https://learn.microsoft.com/en-us/fabric/mirroring/sap-datasphere-tutorial), [SAP mirroring limitations](https://learn.microsoft.com/en-us/fabric/mirroring/sap-limitations), [Mirroring overview and cost](https://learn.microsoft.com/en-us/fabric/mirroring/overview), [Mirroring troubleshooting and limits](https://learn.microsoft.com/en-us/fabric/mirroring/troubleshooting).

## Method 3: Copy Job CDC through SAP Datasphere Outbound

This path uses the same SAP Datasphere extraction layer as Mirroring but gives Fabric a Copy Job that reads the staged change files and writes to a supported destination.

```mermaid
flowchart LR
    SAP["SAP source"] --> DS["SAP Datasphere<br/>Replication Flow"]
    DS --> STAGE["ADLS Gen2, S3,<br/>or Google Cloud Storage"]
    STAGE --> CJ["Fabric Copy Job<br/>CDC replication"]
    CJ --> LH["Lakehouse table"]
    CJ --> WH["Warehouse or SQL destination"]

    classDef sap fill:#0B6CA0,stroke:#003D66,color:#ffffff,font-weight:bold
    classDef ds fill:#2E7D32,stroke:#1B5E20,color:#ffffff,font-weight:bold
    classDef stage fill:#F59E0B,stroke:#B45309,color:#1a1a1a,font-weight:bold
    classDef copy fill:#558B2F,stroke:#33691E,color:#ffffff,font-weight:bold
    classDef dest fill:#6A1B9A,stroke:#4A148C,color:#ffffff,font-weight:bold

    class SAP sap
    class DS ds
    class STAGE stage
    class CJ copy
    class LH,WH dest
```

### Current status

Copy Job itself is generally available. Microsoft announced SAP Datasphere among the GA CDC sources in May 2026, and the current CDC matrix lists SAP Datasphere Outbound without a source-specific Preview marker.

The metadata is still inconsistent: the current Copy Job connector page labels the overall CDC replication section **Preview**, and the Fabric roadmap retains older Preview status. Record this conflict in the architecture decision. Do not describe the full SAP pattern as unconditionally production-ready.

### Behavior

1. SAP Datasphere extracts an initial snapshot and changed records.
2. It writes Parquet files to ADLS Gen2, Amazon S3, or Google Cloud Storage.
3. Copy Job reads the staged folders and applies inserts, updates, and deletes to a supported destination.

This is a Copy Job item, not a multi-source transformation pipeline. It does not perform arbitrary joins or business transformations between SAP and other systems.

### Requirements and limits

- SAP Datasphere Premium Outbound Integration.
- Source and target connections in SAP Datasphere.
- **Group Delta = None** and **File Type = Parquet**.
- Load type **Initial and Delta**.
- A supported Copy Job destination.
- Separate monitoring for the Datasphere replication flow and the Fabric Copy Job.

The current matrix shows `No` for SCD Type 2 on the SAP Datasphere Outbound source rows, but that column alone does not prove every possible SAP-source and destination combination. Treat SCD Type 2 as **support to confirm for the exact pair**, not as available by default.

Schema handling also needs attention. New columns are not automatically synchronized into an existing mapping, and incompatible type changes can fail the run.

### Data guarantee

Copy Job CDC is designed to reproduce the latest source state from captured net changes. It is not an immutable event log:

- the documented capture is net change only, so several updates to the same key between reads might be represented only by the resulting state;
- if a job mixes CDC-enabled and non-CDC tables, Copy Job can treat every selected table as watermark-based incremental copy;
- watermark mode does not capture a delete unless the source exposes another record that represents it;
- an SCD Type 2 destination can preserve versions only when the exact source-destination pair supports it and the project validates its behavior.

State the required guarantee before selecting the method:

| Requirement | Meaning | Method 3 fit |
| --- | --- | --- |
| Current state | Destination should match the latest source state | Primary use case |
| Version history | Preserve selected record versions over time | Confirm SCD Type 2 or implement history downstream |
| Every intermediate change | Retain each change in original order | Not guaranteed by net-change CDC |

Test several updates and a deletion for the same key between two runs. The acceptance result must show whether the destination preserves only the final state, a version history, or every individual change.

### When to use Method 3

Use this method when cloud staging is acceptable and the Fabric team needs explicit scheduling, destination choice, and Copy Job monitoring.

Choose Mirroring instead when the goal is a continuously managed SAP replica in OneLake. Choose the ABAP Add-On path when SAP Datasphere is unavailable and watermark-based extraction is sufficient.

Sources: [SAP Datasphere Outbound Copy Job tutorial](https://learn.microsoft.com/en-us/fabric/data-factory/copy-job-tutorial-sap-datasphere), [CDC in Copy Job](https://learn.microsoft.com/en-us/fabric/data-factory/cdc-copy-job), [Copy Job connectors](https://learn.microsoft.com/en-us/fabric/data-factory/copy-job-connectors).

## Method 4: semantic federation

Semantic federation keeps the primary data in SAP and sends queries from Power BI to the SAP engine.

```mermaid
flowchart LR
    BW["SAP BW or BW/4HANA"] -->|"DirectQuery through gateway"| PBI["Power BI semantic model"]
    HANA["SAP HANA"] -->|"DirectQuery through gateway"| PBI
    DS["SAP Datasphere or HANA Cloud"] -->|"HANA or ODBC client path"| PBI
    PBI --> REPORT["Power BI reports"]

    classDef sap fill:#0B6CA0,stroke:#003D66,color:#ffffff,font-weight:bold
    classDef pbi fill:#1565C0,stroke:#0D47A1,color:#ffffff,font-weight:bold
    classDef report fill:#6A1B9A,stroke:#4A148C,color:#ffffff,font-weight:bold

    class BW,HANA,DS sap
    class PBI pbi
    class REPORT report
```

### SAP BW DirectQuery

Power BI selects an InfoCube or BEx Query, then exposes the dimensions and key figures returned through the SAP public interface.

Important limits include:

- no Power Query Editor for shaping the BW model;
- no calculated columns or user-defined relationships;
- restricted DAX and visual behavior;
- SAP local calculations, hidden key figures, currency formatting, units, hierarchy versions, and some totals can differ from SAP front-end tools;
- reports must be tested against authoritative SAP outputs, especially for currencies and non-additive measures.

### SAP HANA DirectQuery

Power BI supports two distinct modes:

- **Multidimensional mode**, the default, uses one analytic or calculation view and preserves SAP-defined measures and hierarchies.
- **Relational mode** allows relationships, calculated columns, and multiple sources, but it can mis-handle non-additive SAP measures if the model aggregates them again.

The mode is chosen when the report connection is created and cannot be switched later.

### SAP Datasphere

SAP Datasphere separates analytical models from exposed views. Analytical models can be consumed through supported analytical interfaces, while exposed views can use an Open SQL schema through ODBC or JDBC.

Microsoft documents a Fabric notebook pattern that uses the SAP HANA ODBC driver against a Datasphere Open SQL schema. It requires:

- an exposed Datasphere view;
- a database user and Open SQL schema;
- SAP HANA Client 2.0 in the notebook environment;
- network allowlisting;
- secure credential handling.

This avoids a persistent OneLake copy, but query-result data still moves into the notebook runtime. It is a custom notebook connection, not Direct Lake.

### Security

Source-side SAP authorization is enforced only when the connection identity and single sign-on design preserve the intended user context. A fixed gateway credential does not automatically provide per-user SAP authorization.

### When to use Method 4

Use semantic federation when data must remain in SAP, SAP calculations must remain authoritative, and the SAP platform can carry interactive query load.

Avoid it for large Spark workloads, offline access, or reports that need unrestricted Power BI modeling.

Sources: [DirectQuery and SAP BW](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-directquery-sap-bw), [DirectQuery for SAP HANA](https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-directquery-sap-hana), [Extract SAP data from Fabric](https://learn.microsoft.com/en-us/azure/sap/workloads/extract-sap-data), [Gateway single sign-on overview](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-sso-overview).

## Method 5: SAP Datasphere governed data exchange

SAP Datasphere can act as the SAP-owned curation and exchange layer, but the direction and storage format matter.

Method 5 is an ownership and governance pattern, not a mutually exclusive transport. It is often combined with Method 2 for Mirroring, Method 3 for Copy Job CDC, or Method 6 for Kafka delivery. The distinction is that the SAP team owns the published object, quality rules, and release process before another Fabric mechanism moves or consumes it.

```mermaid
flowchart LR
    SAP["SAP source systems"] --> DS["SAP Datasphere<br/>models and data products"]
    DS -->|"Premium Outbound<br/>Replication Flow"| CLOUD["ADLS Gen2, S3,<br/>or Google Cloud Storage"]
    CLOUD --> SHORTCUT["OneLake shortcut"]
    SHORTCUT --> PREP["Convert or load<br/>to Delta tables"]
    PREP --> DL["Direct Lake or<br/>other Fabric workloads"]

    OL["Microsoft OneLake"] -->|"OneLake connection<br/>source only"| DS

    classDef sap fill:#0B6CA0,stroke:#003D66,color:#ffffff,font-weight:bold
    classDef ds fill:#00796B,stroke:#004D40,color:#ffffff,font-weight:bold
    classDef storage fill:#F59E0B,stroke:#B45309,color:#1a1a1a,font-weight:bold
    classDef fabric fill:#6A1B9A,stroke:#4A148C,color:#ffffff,font-weight:bold

    class SAP sap
    class DS ds
    class CLOUD storage
    class SHORTCUT,PREP,DL,OL fabric
```

### Datasphere outbound direction

Premium Outbound Integration is required when a replication flow targets non-SAP systems such as:

- Amazon S3;
- Google Cloud Storage;
- Azure Data Lake Storage Gen2;
- Google BigQuery;
- Apache Kafka or Confluent Kafka;
- SFTP.

Premium Outbound is capacity-based. SAP documentation describes blocks sized by transferred data volume. Confirm the commercial allocation with the SAP contract owner.

### Fabric consumption

A OneLake shortcut can expose files stored in ADLS Gen2, S3, or compatible locations without another physical copy into the Lakehouse Files area.

The shortcut does not turn arbitrary Parquet files into Delta tables. Direct Lake requires Delta tables. Use one of these paths:

- Mirroring for SAP, which converts staged data into managed Delta tables;
- Copy Job into a Lakehouse table;
- a Fabric transformation that writes a Delta table.

### OneLake to Datasphere direction

SAP Datasphere now provides a Microsoft OneLake connection. Current SAP documentation lists it as a **replication-flow source**, not a target. The supported load type is **Initial Only**. It does not support remote tables or data flows.

The connection uses OAuth 2.0 and can use SAP Cloud Connector as a TLS tunnel when the OneLake workspace is not publicly reachable.

This direction is useful when an SAP-owned process needs to ingest Fabric-managed files into Datasphere. It is not the same product as SAP BDC Connect.

### When to use Method 5

Use this pattern when the SAP data team owns curation and outbound governance, or when Datasphere must ingest selected OneLake data.

Do not describe the storage-mediated outbound flow as zero-copy end to end. SAP first creates files in the target storage, and Fabric may still need to create Delta tables.

Sources: [SAP Premium Outbound Integration](https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Acquiring-Preparing-Modeling-Data/Acquiring-and-Preparing-Data-in-the-Data-Builder/premium-outbound-integration-4e9c6ac.md), [SAP Microsoft OneLake connection](https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Integrating-data-and-managing-spaces/Integrating-Data-Via-Connections/microsoft-onelake-connections-057fa4b.md), [OneLake shortcuts](https://learn.microsoft.com/en-us/fabric/onelake/onelake-shortcuts), [Direct Lake overview](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-overview).

## Method 6: event-driven integration

There are two different event patterns. They should not be presented as one native connector.

### Pattern A: SAP Datasphere Replication Flow to Eventstream

Microsoft documents this path directly:

```mermaid
flowchart LR
    SAP["SAP source"] --> DS["SAP Datasphere<br/>Replication Flow"]
    DS -->|"Kafka SASL/TLS<br/>TCP 9093"| CE["Eventstream<br/>custom endpoint"]
    CE --> ES["Eventstream<br/>transform and route"]
    ES --> EH["Eventhouse"]
    ES --> LH["Lakehouse"]
    ES --> ACT["Activator"]

    classDef sap fill:#0B6CA0,stroke:#003D66,color:#ffffff,font-weight:bold
    classDef ds fill:#00796B,stroke:#004D40,color:#ffffff,font-weight:bold
    classDef event fill:#C2410C,stroke:#7C2D12,color:#ffffff,font-weight:bold
    classDef fabric fill:#6A1B9A,stroke:#4A148C,color:#ffffff,font-weight:bold

    class SAP sap
    class DS ds
    class CE,ES event
    class EH,LH,ACT fabric
```

The configuration requires:

- SAP Datasphere Premium Outbound Integration;
- an Eventstream custom endpoint source;
- the endpoint bootstrap server, topic, and connection string;
- `SASL_SSL` with `PLAIN`;
- `$ConnectionString` as the Kafka user name;
- the Eventstream connection string as the password;
- the Eventstream topic name as the Replication Flow target object name.

The Kafka protocol uses TCP 9093. Fabric Private Link does not support custom endpoint sources or destinations, so this is not a private-link inbound path.

### SAP Kafka message contract

SAP Datasphere sends one source record per Kafka message. The Kafka message key is the source primary-key values concatenated with `_`. The payload contains mapped source columns plus operation metadata.

| Operation | Meaning | Consumer behavior |
| --- | --- | --- |
| `L` | Initial-load row | Insert or replace the current row by key |
| `I` | Insert during delta processing for sources that distinguish inserts | Insert idempotently |
| `U` | Update after-image for sources that distinguish updates | Upsert the complete resulting row |
| `U` or `A` | Insert or update for SAP S/4HANA and other ABAP sources | Treat as an upsert; SAP Note 3044005 can change the emitted upsert code to `A` |
| `X` | Delete with primary-key fields only | Delete or tombstone the row by key; non-key payload fields are empty |
| `D` | Delete with a before image for supported sources | Delete by key and retain the before image only if the history model requires it |
| `M` | Archiving operation after initial load for supported ABAP sources | Define an explicit archive policy rather than assuming ordinary delete semantics |

The sequence field is empty for initial-load rows and is not populated for every source type, including ABAP. A downstream design cannot assume one global sequence number for SAP changes. Preserve Kafka partition ordering, select a stable partition key, and define how events from different partitions are reconciled.

The target contract must state:

- how `L`, `I`, `U`, and `A` rebuild the current row;
- how `X`, `D`, and `M` affect current state and history;
- how duplicate messages are detected or absorbed;
- whether the sink uses idempotent upsert, append-only history, or both;
- how replay starts from a known offset without applying a delete or update twice;
- how missing sequence values affect ordering and late-arriving records.

Receiving messages is not proof that the target table is correct. Test insert, repeated upsert, out-of-order delivery, duplicate delivery, delete, archive, and replay for the same business key.

### Lakehouse destination warning

An Eventstream Lakehouse destination creates a new table schema from the first record and projects later records onto that schema. Extra columns can be dropped, missing columns become null, and a record with no compatible fields can fail conversion. Microsoft warns that schema changes can lose columns or entire records and does not recommend this destination for variable-schema streams such as database CDC.

For SAP change records:

- normalize and validate the schema before the Lakehouse destination;
- prefer Eventhouse or a raw immutable landing path when operation payloads differ;
- separate delete messages that contain keys only from full-row upserts;
- test the first record deliberately so it cannot establish an incomplete target schema.

When a source and destination are published together, source ingestion can start before destination routing. Activate ingestion only after the route is ready, or resume from an earlier timestamp so initial records are not skipped.

### Pattern B: SAP business events through SAP BTP

SAP S/4HANA business events can be published through SAP Event Mesh or SAP Integration Suite. Azure Event Grid can receive events through a custom connector or webhook design, and Eventstream supports Azure Event Grid Namespace as a source.

The SAP Event Mesh connector to Azure Event Grid has appeared in SAP beta and community material rather than a current jointly documented GA reference architecture. Treat it as a custom integration that needs support confirmation from SAP and Microsoft.

SAP Event Mesh Lite is being discontinued. New designs should use a currently supported Event Mesh plan. SAP Integration Suite, advanced event mesh is a separate offering with its own migration process, not a renamed Lite plan.

### Private Kafka sources

If Eventstream must pull from a private Kafka cluster, use the GA Streaming Connector VNet injection pattern with VPN or ExpressRoute. This is different from the custom endpoint push path used by SAP Datasphere.

### When to use Method 6

Use Eventstream for operational records that need routing, filtering, windowing, Eventhouse analysis, or Activator actions.

Do not use events as a substitute for a complete historical dataset. Event payloads leave SAP and may be retained in Eventstream or downstream destinations, so data residency and personal-data controls still apply. Eventstream retains data for one day by default and can be configured for longer retention up to the documented limit. Pair the event stream with a batch or change-replication method when completeness and replay beyond event retention matter.

Sources: [Replicate SAP Datasphere data to Eventstream](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/replicate-data-with-replication-flow), [SAP Apache Kafka target format](https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Acquiring-Preparing-Modeling-Data/Acquiring-and-Preparing-Data-in-the-Data-Builder/apache-kafka-targets-for-replication-flows-6df55db.md), [Eventstream Lakehouse destination](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/add-destination-lakehouse), [Eventstream network security selection](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/choose-the-right-network-security-feature), [Azure Event Grid source](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/add-source-azure-event-grid), [Eventstream settings and retention](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/configure-settings), [SAP Event Mesh Lite lifecycle](https://help.sap.com/docs/SAP_EM/bf82e6b26456494cbdd197057c09979f/ef79898d432a4553b48186dc1d745945.html).

## Method 7: Open Mirroring partner solutions

Open Mirroring lets a data provider write change files to a Fabric mirrored database landing zone. Fabric validates and merges those changes into Delta tables in OneLake.

```mermaid
flowchart LR
    SAP["SAP ECC, S/4HANA,<br/>BW, or other supported source"] --> PARTNER["Partner extraction<br/>and CDC runtime"]
    PARTNER --> LAND["Open Mirroring<br/>landing zone"]
    LAND --> MIRROR["Fabric mirrored database"]
    MIRROR --> OL["OneLake Delta tables"]
    OL --> SQL["SQL analytics endpoint"]
    OL --> PBI["Power BI Direct Lake"]

    classDef sap fill:#0B6CA0,stroke:#003D66,color:#ffffff,font-weight:bold
    classDef partner fill:#4338CA,stroke:#312E81,color:#ffffff,font-weight:bold
    classDef fabric fill:#6A1B9A,stroke:#4A148C,color:#ffffff,font-weight:bold

    class SAP sap
    class PARTNER partner
    class LAND,MIRROR,OL,SQL,PBI fabric
```

### Current SAP-capable partner entries

The Microsoft-maintained partner page explicitly describes SAP support for:

| Partner | Microsoft-listed SAP scope |
| --- | --- |
| AecorSoft | SAP-certified replication into Fabric through Open Mirroring |
| ASAPIO | SAP-certified add-on with CDC, scheduled replication, and predefined data products |
| CData | SAP among more than 150 supported enterprise sources |
| dab | SAP-certified extraction from ECC and S/4HANA on-premises or Private Cloud Edition |
| Qlik | Log-based CDC including SAP among supported source families |
| Simplement | SAP-certified extraction from several SAP source systems |
| SNP | SNP Glue support for S/4HANA and Open Mirroring |
| Theobald | Xtract Universal support for S/4HANA, ECC, and BW |

The partner page also lists general-purpose Open Mirroring vendors that may support SAP through their own product matrices. Do not call every Open Mirroring partner an SAP partner.

### Publisher contract

Open Mirroring publishers do not write Delta tables directly. They write specification-compliant files into the landing zone:

- `_metadata.json` defines table metadata;
- Parquet or delimited files carry row data;
- `__rowMarker__` identifies inserts, updates, deletes, and upserts;
- update records must contain the complete resulting row;
- key columns must remain stable;
- uploads must be atomic so Fabric never reads partial files.

Fabric applies those changes and maintains the target Delta tables.

### Status note

Current Microsoft Learn treats base Open Mirroring as generally available because it is not marked Preview in the current source list. The roadmap still contains an older overall Preview record. Record the conflict and validate the selected partner release.

### Selection checks

- supported SAP product, release, and deployment model;
- extraction mechanism and response to SAP Note 3255746;
- SAP certification stated for the exact product and version;
- initial-load and delta behavior;
- delete handling and replay;
- source-system load;
- partner license and infrastructure;
- support ownership across SAP, the partner, and Microsoft.

### When to use Method 7

Use Open Mirroring when SAP Datasphere is unavailable or undesirable, and a partner product has a verified support matrix for the source.

The main trade-off is not technical capability alone. The organization accepts a partner runtime, partner licensing, and a three-party support boundary.

Sources: [Open Mirroring partner ecosystem](https://learn.microsoft.com/en-us/fabric/mirroring/open-mirroring-partners-ecosystem), [Open Mirroring overview](https://learn.microsoft.com/en-us/fabric/mirroring/open-mirroring), [Open Mirroring landing-zone format](https://learn.microsoft.com/en-us/fabric/mirroring/open-mirroring-landing-zone-format).

## Method 8: SAP Business Data Cloud Connect for Microsoft Fabric

SAP and Microsoft announced SAP Business Data Cloud Connect for Microsoft Fabric as a bidirectional, zero-copy data-product sharing capability between SAP BDC and Microsoft OneLake.

```mermaid
flowchart LR
    subgraph SAP["SAP Business Data Cloud"]
        DP["Governed SAP<br/>data products"]
        J["SAP Joule"]
    end

    CONNECT["SAP BDC Connect<br/>planned capability"]

    subgraph Fabric["Microsoft Fabric"]
        OL["Microsoft OneLake"]
        BI["Power BI and Fabric"]
        AI["Microsoft Foundry<br/>and Copilot"]
    end

    DP <-.-> CONNECT
    CONNECT <-.-> OL
    DP --> J
    OL --> BI
    OL --> AI

    classDef sap fill:#0B6CA0,stroke:#003D66,color:#ffffff,font-weight:bold
    classDef bridge fill:#AD1457,stroke:#880E4F,color:#ffffff,font-weight:bold
    classDef fabric fill:#6A1B9A,stroke:#4A148C,color:#ffffff,font-weight:bold

    class DP,J sap
    class CONNECT bridge
    class OL,BI,AI fabric
```

### Status on September 11, 2026

The joint announcement states that general availability was **planned for Q3 2026**. The SAP Sapphire 2026 update said delta sharing was coming in the second half of 2026.

No public Microsoft Learn setup guide, SAP Help configuration guide, or explicit GA announcement was found by September 11, 2026. This guide therefore classifies BDC Connect as **planned, with GA not publicly confirmed**.

Do not describe it as an available production service until the owning product documentation confirms:

- supported SAP data products;
- supported Fabric item types;
- identity and authorization flow;
- regional availability;
- read and publish semantics;
- lineage and audit behavior;
- quotas, latency, and consistency;
- commercial prerequisites.

### Confirmed product intent

The official announcement confirms:

- bidirectional, zero-copy sharing;
- SAP data products integrated into OneLake;
- OneLake datasets made available to SAP BDC;
- analytics and AI scenarios across Power BI, Fabric, Microsoft Foundry, Copilot, and SAP Joule.

Zero-copy does not mean that data bytes never cross the boundary or that consumers can write through to provider datasets. Current generic SAP BDC Connect guidance allows caching in some consumption scenarios.

SAP BDC is a separately entitled suite whose core components include SAP Datasphere. Generic BDC Connect uses capacity-unit metering, but Fabric-specific metering and entitlements remain undocumented. Current public SAP Help lists supported BDC Connect systems without Microsoft Fabric, which supports the decision to keep this method in planned status.

It does not yet provide enough implementation detail to infer an ORD requirement, an admin workflow, write consistency, or exact Fabric region support.

### When to use Method 8

Use Method 8 for architecture planning and vendor discussions. Do not use it as the sole committed production path until GA and technical documentation are public for the required region.

Sources: [SAP announcement](https://news.sap.com/2025/11/sap-bdc-connect-for-microsoft-fabric-business-insights-ai-innovation/), [Microsoft Fabric announcement](https://community.fabric.microsoft.com/t5/Fabric-Updates-Blog/SAP-and-Microsoft-accelerate-business-insights-and-AI-innovation/ba-p/5172482), [SAP Sapphire 2026 update](https://azure.microsoft.com/en-us/blog/advancing-enterprise-ai-new-sap-on-azure-announcements-from-sap-sapphire-2026/), [SAP BDC Connect provisioning](https://help.sap.com/docs/SAP_BUSINESS_DATA_CLOUD/f7acf8c9dad54e99b5ce5ebc633ed8e1/ccbd8fe7c2394009b546b73b1dd6c164.html), [SAP BDC entitlements](https://help.sap.com/docs/SAP_BUSINESS_DATA_CLOUD/f7acf8c9dad54e99b5ce5ebc633ed8e1/89e883e695724b53a140bef43bfb6ada.html).

## Legacy Azure Data Factory SAP CDC: review required

Azure Data Factory and Azure Synapse still document the SAP CDC connector and a direct sink into Fabric Lakehouse tables. The path uses:

- the SAP ODP framework;
- a self-hosted integration runtime;
- SAP Connector for Microsoft .NET;
- an ADLS Gen2 staging area;
- Mapping Data Flow;
- a Fabric Lakehouse linked service.

Microsoft updated the architecture guidance in August 2026 with an important warning: SAP Note 3255746 announces a security patch that blocks ODP RFC API calls from third-party clients, including the Azure Data Factory SAP CDC connector.

Microsoft names these alternatives:

- Mirroring for SAP through SAP Datasphere;
- SAP Business Data Cloud Connect when available;
- Copy Job for SAP with ABAP Add-On;
- SAP-certified partner solutions through Open Mirroring.

Existing ADF SAP CDC deployments need an impact assessment before the SAP patch is installed. Confirm the SAP Note version, patch state, allowed transition window, and chosen migration path with SAP. This document does not provide legal or licensing advice.

Sources: [ADF SAP CDC architecture](https://learn.microsoft.com/en-us/azure/data-factory/sap-change-data-capture-introduction-architecture), [ADF SAP CDC to Fabric](https://learn.microsoft.com/en-us/azure/data-factory/change-data-capture-from-sap-to-onelake-with-azure-data-factory).

## Direct Lake and the semantic layer

Direct Lake is a Power BI semantic-model storage mode for Delta tables in OneLake. It should not be described as a connector from SAP.

### Direct Lake on OneLake

- Reached general availability in March 2026.
- Can use Delta tables from more than one Fabric data source.
- Does not fall back to DirectQuery through a SQL analytics endpoint.
- Can combine with Import tables and, through supported tooling, DirectQuery tables.
- Loads required columns into memory and refreshes metadata through framing.

### Direct Lake on SQL

- Uses one Lakehouse or Warehouse SQL analytics endpoint.
- Can fall back to DirectQuery for SQL views or granular SQL security.
- Has different composite-model limits from Direct Lake on OneLake.

### Access-control boundaries

Direct Lake on OneLake does not use the SQL analytics endpoint for permission checks. SQL RLS or OLS therefore does not protect this path. Use OneLake security, item permissions, and the effective identity used by the Direct Lake connection.

RLS or OLS defined in a Power BI semantic model applies only to queries that pass through that model. It does not secure direct SQL, Spark, notebook, or OneLake API access. Conversely, SQL permissions do not automatically become OneLake security roles.

| Access path | Primary enforcement | Does not automatically inherit | Required negative test |
| --- | --- | --- | --- |
| Power BI through Direct Lake on OneLake | OneLake security plus semantic-model RLS/OLS | SQL endpoint RLS | User cannot query a forbidden company code through the report or DAX endpoint |
| Power BI through Direct Lake on SQL | SQL permissions, semantic-model rules, and fallback behavior | OneLake model-independent restrictions | Restricted SQL row remains blocked when a query falls back to DirectQuery |
| SQL analytics endpoint | SQL `GRANT`, RLS, OLS, and CLS | Semantic-model RLS/OLS | User cannot select the forbidden SAP company or client |
| Spark or notebook | Workspace, item, and OneLake permissions | SQL and semantic-model rules | Notebook read of the Delta path returns no forbidden rows |
| OneLake API or shortcut | OneLake security, item permissions, and shortcut identity | SQL and semantic-model rules | Direct file or table access is denied outside the approved perimeter |

### Persona test matrix

| Persona | Intended access | Access that must remain denied | Evidence to retain |
| --- | --- | --- | --- |
| Report viewer | Approved Power BI report and semantic model | SQL, Spark, and direct OneLake access | Report test using allowed and forbidden SAP company codes |
| SQL analyst | Approved SQL views or tables | Raw OneLake paths and unrelated semantic models | SQL query results plus denied OneLake request |
| Data engineer | Approved Lakehouse and notebook paths | Production report administration and unapproved SAP domains | Notebook test by client, company code, and source system |
| Service identity | Only the ingestion or framing paths it operates | Interactive use and unrelated workspaces | Role assignments, token identity, and denied cross-workspace test |
| Workspace administrator | Administrative access by design | None assumed | Privileged-access approval and audit log |

For SAP data, test at least company code, controlling area, plant, client or mandant, language, and source-system boundaries where they apply. A successful report test does not prove that direct OneLake or Spark access is secure.

For SAP architectures, Direct Lake is a consumption choice after data has become a supported Delta table. It is not available directly over arbitrary Parquet files or live SAP BW/HANA connections. Reports see the state from the most recent successful framing operation, so freshness measurement must include ingestion, Delta commit, framing, and report behavior.

Sources: [Direct Lake overview](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-overview), [Direct Lake security integration](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-security-integration).

## Network and security design

| Path | Main network components | Security focus |
| --- | --- | --- |
| Classic Fabric SAP connectors | On-premises data gateway, SAP NCo or HANA client | Gateway hardening, outbound Fabric access, SAP technical account |
| ABAP Add-On Preview | Gateway to SAP over RFC; SAP and gateway to OneLake over HTTPS | Add-on transport governance, SAP outbound access, OneLake identity |
| Mirroring and Copy Job through Datasphere | SAP to Datasphere; Datasphere to cloud storage; Fabric to storage | Storage identity, staging retention, separate monitoring boundaries |
| Semantic federation | Power BI gateway to SAP BW or HANA | SSO or fixed identity, source capacity, result correctness |
| Eventstream custom Kafka endpoint | SAP Datasphere to `*.servicebus.windows.net` on 9093 | Connection-string rotation, public endpoint policy |
| Open Mirroring partner | Partner-specific SAP connection and Fabric landing-zone access | Vendor runtime, secret storage, least privilege |
| SAP BDC Connect | Not yet publicly documented | Do not invent the identity or network model |

Workspace-level Private Link support is workload-specific. Current matrices support items such as Copy Job, Eventstream, Mirrored SAP, Open Mirroring, Lakehouse, SQL analytics endpoints, and shortcuts. Power BI semantic models are not supported in a workspace where workspace-level Private Link is enabled and public access is denied.

ADLS shortcuts do not use Fabric managed private endpoints. For a firewall-enabled ADLS account, evaluate trusted workspace access. That path requires a purchased Fabric capacity, workspace identity, Azure RBAC and ACL permissions, and a storage resource-instance rule.

Apply these controls across all production paths:

- use dedicated technical identities and rotate their secrets;
- restrict SAP authorizations to required objects;
- log gateway, storage, Copy Job, mirroring, and source-side failures;
- define who owns replay after partial failure;
- test schema drift and invalid SAP values;
- document data residency at every persisted copy or staging layer;
- avoid treating encrypted public traffic and private networking as equivalent controls.

Sources: [Fabric security feature availability](https://learn.microsoft.com/en-us/fabric/security/security-feature-availability), [Workspace Private Link support](https://learn.microsoft.com/en-us/fabric/security/security-workspace-level-private-links-support), [Create an ADLS Gen2 shortcut](https://learn.microsoft.com/en-us/fabric/onelake/create-adls-shortcut), [Trusted workspace access](https://learn.microsoft.com/en-us/fabric/security/security-trusted-workspace-access).

## Licensing and commercial checkpoints

| Topic | Methods | Check before approval |
| --- | --- | --- |
| SAP Datasphere Premium Outbound Integration | 2, 3, 5, 6A | Capacity blocks, transferred volume, source and target eligibility |
| SAP BTP and Event Mesh | 6B | Service entitlement and connector support |
| Partner licensing | 7 | Source coverage, runtime, support terms, and SAP certification |
| SAP BDC | 8 | Product availability, contract entitlement, and region |
| Fabric capacity | All Fabric paths | Ingestion, transformation, query, and concurrency load |
| SAP ODP RFC | Legacy ADF CDC and any partner using it | SAP Note 3255746 impact and migration plan |

Avoid categorical claims such as "always licensed" or "always prohibited" without the customer's SAP agreement and current SAP Notes. Product documentation and commercial rights are separate questions.

## Comparison matrix

| Method | Status | Freshness model | SAP Datasphere | Fabric landing | Main trade-off |
| --- | --- | --- | :---: | --- | --- |
| 1. Data Factory extraction | GA connectors; ABAP Add-On Preview | Batch or watermark | No | Lakehouse, Warehouse, SQL, other supported target | Gateway and source load |
| 2. Mirroring | GA | Continuous two-stage replication | Yes | Mirrored Delta tables in OneLake | Premium Outbound plus ADLS staging |
| 3. Copy Job CDC | SAP source announced GA; metadata conflict remains | Datasphere deltas plus Copy Job | Yes | Supported Copy Job destination | Two schedulers, SCD Type 2 pair confirmation, and status conflict |
| 4. Semantic federation | GA | Query time | Optional | No bulk landing | SAP query load and modeling limits |
| 5. Datasphere exchange | Available building blocks | Replication-flow schedule | Yes | Files, then Delta conversion or mirroring | Format and direction must be designed |
| 6. Event-driven | Available | Event or replication flow | Optional | Eventstream destinations | Completeness and public Kafka endpoint |
| 7. Open Mirroring | Current Learn treats base feature as GA; older roadmap says Preview | Partner CDC or schedule | No | Mirrored Delta tables in OneLake | Partner cost and support boundary |
| 8. SAP BDC Connect | Planned; GA not confirmed | Planned zero-copy sharing | No | OneLake integration | No public implementation guide yet |

## Decision guide

```mermaid
flowchart TD
    START{"What is the primary requirement?"}

    START -->|"Copy SAP data"| GUARANTEE{"Required data guarantee?"}
    START -->|"Continuous managed replica"| MIRRORDS{"Is SAP Datasphere available?"}
    START -->|"Live BI query"| FED["Method 4<br/>Semantic federation"]
    START -->|"Governed SAP exchange"| DSP["Method 5<br/>Datasphere exchange"]
    START -->|"Operational events"| EVENTS["Method 6<br/>Event-driven integration"]
    START -->|"Future BDC data-product sharing"| BDC["Method 8<br/>Validate GA first"]

    GUARANTEE -->|"Full or watermark is sufficient"| CLASSIC{"Does a classic connector support<br/>the edition, object, and scale?"}
    GUARANTEE -->|"Latest state from source deltas"| HASDS{"Is SAP Datasphere available?"}
    GUARANTEE -->|"Every intermediate change"| EVENTLOG["No default method here guarantees every change<br/>Validate a source event log or partner contract"]

    CLASSIC -->|"Yes"| DF["Method 1<br/>Classic connectors"]
    CLASSIC -->|"No"| ADDON{"Does the ABAP Add-On support<br/>the edition and object?"}
    ADDON -->|"Yes"| ABAP["Method 1<br/>ABAP Add-On Preview"]
    ADDON -->|"No"| OPEN["Method 7<br/>Open Mirroring partner"]

    HASDS -->|"Yes"| COPYCDC["Method 3<br/>GA announcement and metadata conflict"]
    HASDS -->|"No"| OPEN

    MIRRORDS -->|"Yes"| MIRROR["Method 2<br/>Mirroring through Datasphere"]
    MIRRORDS -->|"No"| OPEN

    classDef decision fill:#FFF3E0,stroke:#EF6C00,color:#1a1a1a,font-weight:bold
    classDef method fill:#E8EAF6,stroke:#3949AB,color:#1a1a1a,font-weight:bold
    classDef planned fill:#FCE4EC,stroke:#AD1457,color:#1a1a1a,font-weight:bold
    classDef gap fill:#FFEBEE,stroke:#C62828,color:#1a1a1a,font-weight:bold

    class START,GUARANTEE,CLASSIC,ADDON,HASDS,MIRRORDS decision
    class MIRROR,FED,EVENTS,OPEN,COPYCDC,DSP,DF,ABAP method
    class BDC planned
    class EVENTLOG gap
```

## Production readiness checklist

### Source and data contract

- Confirm the exact SAP release, deployment model, and source objects.
- Identify keys, delete semantics, late-arriving changes, and schema evolution.
- Reconcile representative outputs with an SAP-authoritative report.
- Define the acceptable source-system load window.
- Test amounts and currencies, units of measure, identifiers with leading zeros, invalid or initial dates, language-dependent text, client or mandant, company code, and source-system identifiers where they apply.
- List every SAP calculation, hierarchy, conversion, or local rule that must be rebuilt after extraction.

### Business consistency

- Identify related object sets such as sales-order headers and items, accounting headers and line items, or material and valuation records.
- Define when a set of tables is complete enough to publish to consumers.
- Prevent a report or downstream job from reading a partially advanced business snapshot.
- Reconcile record counts, control totals, and business totals across the related objects.
- Test a source transaction that changes more than one table and prove that consumers observe an accepted state.

### Platform status

- Record GA, Preview, or planned status for every required feature.
- Validate regional availability.
- Check current connector and partner versions.
- Recheck the owning documentation before go-live.

### Network and identity

- Prove DNS and port reachability from the production runtime.
- Use separate identities for extraction, staging, and consumption.
- Test secret and certificate rotation.
- Confirm whether a public endpoint, gateway path, or private route is permitted.

### Reliability and operations

- Test initial load, incremental run, restart, replay, and duplicate handling.
- Measure latency at SAP, staging, Fabric ingestion, and semantic consumption.
- Define monitoring ownership across every platform boundary.
- Document recovery after a partial batch or schema failure.
- Set staging retention and checkpoint retention long enough to cover the maximum supported interruption.
- Define when an incremental process must be abandoned and replaced with a full reload.
- Test several updates and a delete for the same key between two executions.
- Define how SAP archiving operations affect the target current state and history.
- Record the replay start point and prove that rerunning does not duplicate or resurrect deleted data.

### Measurable operating targets

Replace qualitative terms such as "near real-time" with project thresholds:

| Measure | Required target |
| --- | --- |
| End-to-end freshness | Maximum age from SAP commit to approved consumer visibility |
| Source or staging lag | Maximum acceptable queue, file, or replication-flow delay |
| Backlog | Maximum rows, files, messages, or offsets awaiting processing |
| Recovery time | Maximum time to return to the freshness target after an outage |
| Reconciliation | Expected difference between SAP control totals and Fabric output |
| Data loss tolerance | Explicitly zero, or a documented and approved exception |

### Governance and cost

- Record every persisted copy and its retention.
- Apply sensitivity labels and downstream access controls.
- Confirm Premium Outbound, partner, BTP, BDC, and Fabric capacity costs.
- Review SAP terms and SAP Note 3255746 with the SAP contract and Basis owners.

### Deployment and cost

- Document promotion across development, test, and production, including connection rebinding, gateway assignment, workspace identity, and SAP transport ownership.
- Price initial load, steady-state operation, and complete recovery separately.
- Include staging storage, network egress, Premium Outbound blocks, gateway hosts, partner licenses, Fabric capacity, Power BI licenses, and replay cost.
- Test deployment with the target network policy. Fabric deployment pipelines cannot connect to workspaces that use inbound access protection to deny public access.
- Define the alternative promotion mechanism for restricted workspaces, including approval and rollback evidence.

Source: [Fabric CI/CD network security](https://learn.microsoft.com/en-us/fabric/cicd/cicd-security).

## Recommendations by scenario

| Scenario | Preferred starting point |
| --- | --- |
| Established nightly SAP extraction | Method 1 classic connectors |
| Large table extraction without ODP RFC | Method 1 ABAP Add-On Preview, subject to production review |
| Continuous SAP replica with Datasphere | Method 2 Mirroring |
| Controlled SAP CDC through cloud staging | Method 3, with the GA and Preview metadata conflict documented as a production gate |
| Data must remain in SAP | Method 4 semantic federation |
| SAP team owns curated outbound datasets | Method 5 Datasphere exchange |
| Operational alerts and streaming analytics | Method 6 Eventstream |
| Near-real-time replication without Datasphere | Method 7 Open Mirroring partner |
| Future bidirectional SAP BDC and OneLake sharing | Method 8 after public GA confirmation |
| Existing ADF SAP CDC estate | Immediate SAP Note 3255746 impact assessment and migration plan |

## Appendix A: detailed change ledger since June 2026

This ledger covers product releases, status changes, support-matrix changes, lifecycle notices, security guidance, and documentation corrections identified after the June 2, 2026 baseline.

### Date semantics

The ledger separates three dates:

| Date | Meaning |
| --- | --- |
| Effective or first documented date | The first column in each ledger table. This is when behavior changed, or the earliest public documentation date when no product-effective date is published. |
| Source publication or update date | Stated in the first column when it differs materially, and recoverable from the linked Microsoft or SAP page metadata or repository commit. |
| KB verification date | September 11, 2026 for every row in this appendix. |

An updated documentation page does not make an older product restriction new. For example, default semantic-model creation ended for new items on September 5, 2025, existing default models were decoupled on November 30, 2025, and the source page was refreshed on August 19, 2026.

### Fabric Data Factory, connectors, and Eventstream

| Effective or first documented date | Area | Update | Guide impact and source |
| --- | --- | --- | --- |
| June 3 | SAP ABAP Add-On | Copy Job for SAP with Microsoft ABAP Add-On entered Preview. It supports S/4HANA and ECC EhP8, full copy, and watermark incremental copy. | Added to Method 1 with its limits. [Source](https://learn.microsoft.com/en-us/fabric/data-factory/copy-job-tutorial-sap-abap) |
| June 11 | Eventstream | Mirrored Database Change Feed became an Eventstream source in Preview, but the current supported list does not establish Mirrored SAP support. | Not presented as an SAP production route. [Source commit](https://github.com/MicrosoftDocs/fabric-docs/commit/5f747080468e9ac77483ab4015819bd00e38b2d2) |
| June 15 to 26 | Copy Job | The consolidated connector page continued to label CDC replication Preview despite the May announcement naming SAP Datasphere as a GA source. | Method 3 records a status conflict. [Source](https://learn.microsoft.com/en-us/fabric/data-factory/copy-job-connectors) |
| June 19 to 25 | SAP HANA connector | The canonical page became `connector-sap-hana-overview` and confirmed Dataflow, Pipeline, and Copy Job support. | Broken link replaced; DirectQuery removed from the Dataflow matrix. [Source](https://learn.microsoft.com/en-us/fabric/data-factory/connector-sap-hana-overview) |
| June 26 | Copy Job audit columns | Audit-column documentation expanded to most Copy Job connectors without an unambiguous GA promotion. | Treat extraction timestamp and run ID as connector-qualified fields. [Source commit](https://github.com/MicrosoftDocs/fabric-docs/commit/a5abfae944bc7908819f854c5a2cbcbb9b9c749e) |
| June 29 to 30 | Eventstream Kafka | Native Apache Kafka source became GA with TLS, mTLS, and private-network support through VNet injection. | Added as a distinct pull path, separate from the Datasphere push path. [Source](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/add-source-apache-kafka) |
| June 29 | Mirroring extensions | Change Data Feed and view capabilities remained source-specific and partly Preview. | Generic Mirroring extensions are not attributed automatically to SAP. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/extended-capabilities) |
| July 1 to 20 | Eventstream networking | Streaming Connector VNet injection became GA for private and on-premises sources. | Added to Method 6 as the private Kafka pull option. [Source](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/streaming-connector-private-network-support-overview) |
| July 9 | Copy Job SCD Type 2 | Destination support expanded to Fabric and Synapse Warehouse but remained Preview. The SAP Datasphere source rows show `No`, but the exact source-destination pair still requires confirmation. | Removed the unconditional SAP SCD Type 2 claim. [Source](https://learn.microsoft.com/en-us/fabric/data-factory/cdc-copy-job) |
| July 14 | Dataflow Gen2 AI Functions | AI functions gained separate AI and Dataflow billing implications and do not support the VNet gateway. | SAP text-enrichment scenarios must include cost, privacy, and network checks. [Source](https://github.com/MicrosoftDocs/fabric-docs/blob/main/docs/data-factory/dataflow-gen2-ai-functions.md) |
| July 27 | Data Factory monitoring | Workspace monitoring for pipelines remained Preview. | Kept separate from Copy Job monitoring. [Source](https://learn.microsoft.com/en-us/fabric/data-factory/workspace-monitoring) |
| July 21 to August 4 | SAP connector matrix | Both BW Open Hub variants and SAP Table Message Server gained documented Copy Job full-load support; HANA and Table Application Server support watermark incremental Copy Job. | Replaced the complete connector matrix. [Source](https://learn.microsoft.com/en-us/fabric/data-factory/connector-overview) |
| July and August | Connector URLs | SAP BW Open Hub and SAP Table documentation split into Application Server and Message Server pages; SAP HANA was renamed. | Replaced all obsolete connector links. [Source](https://learn.microsoft.com/en-us/fabric/data-factory/connector-overview) |
| July 31 | SAP BW connector | Power Query SAP BW implementation 1.0 was deprecated; new connections use implementation 2.0. | Added a migration warning. [Source](https://learn.microsoft.com/en-us/power-query/connectors/sap-bw/application-setup-and-connect) |
| August 19 | Open Mirroring status | Current Learn treats sources without a Preview label as GA, while an older roadmap card still says Preview. | Both statuses are disclosed. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/get-started-with-mirroring) |
| September 10 | Copy Job CDC matrix | SAP Datasphere Outbound for ADLS, S3, and GCS is listed as a CDC source. Fabric Lakehouse CDC and SCD Type 2 retain Preview boundaries. | Method 3 uses component-level status. [Source](https://learn.microsoft.com/en-us/fabric/data-factory/cdc-copy-job) |
| September 11 cutoff | Dataflow Variable Library | Variables can parameterize supported transformations but cannot change connection information. | Removed the SAP connection-string parameterization claim. [Source](https://github.com/MicrosoftDocs/fabric-docs/blob/main/docs/data-factory/dataflow-gen2-variable-library-integration.md) |
| September 11 cutoff | Dataflow destinations | Destination schemas have gateway, hierarchy-navigation, and Fast Copy prerequisites. | Kept as a general capability, not an SAP guarantee. [Source](https://github.com/MicrosoftDocs/fabric-docs/blob/main/docs/data-factory/dataflow-gen2-data-destinations-and-managed-settings.md) |
| September 11 cutoff | Pipeline schedules | Interval scheduling remained Preview and does not guarantee end-to-end freshness. | Removed the five-minute freshness implication. [Source](https://github.com/MicrosoftDocs/fabric-docs/blob/main/docs/data-factory/pipeline-runs.md) |
| September 11 cutoff | Pipeline Copilot | Expression generation exists, but Learn and roadmap status did not support an unconditional GA statement. | Status remains a live-roadmap check. [Source](https://github.com/MicrosoftDocs/fabric-docs/blob/main/docs/data-factory/copilot-fabric-data-factory-get-started.md) |
| September 11 cutoff | SSIS activity | Invoke SSIS Package remained Preview, uses OneLake-hosted packages, and excludes several private or custom component scenarios. | Removed the unrestricted lift-and-shift claim. [Source](https://github.com/MicrosoftDocs/fabric-docs/blob/main/docs/data-factory/invoke-ssis-package-activity.md) |

### Mirroring, OneLake, and Direct Lake

| Effective or first documented date | Area | Update | Guide impact and source |
| --- | --- | --- | --- |
| June 15 to September 9 | Direct Lake | Documentation now separates Direct Lake on OneLake from Direct Lake on SQL. | Added separate behavior and fallback sections. [Source](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-overview) |
| June 25 | Mirroring cost | A running capacity is required, but background Mirroring replication does not consume CUs. | Corrected the cost model. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/overview) |
| June 27 | SAP Mirroring | Microsoft documented the two-stage Datasphere-to-ADLS and ADLS-to-OneLake architecture. | Replaced the direct-stream architecture. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/sap) |
| July 1 | ADLS shortcut identity | Shortcut guidance expanded identity, RBAC, ACL, delegation, cross-tenant, and rotation requirements. | Added shortcut identity to production design. [Source](https://learn.microsoft.com/en-us/fabric/onelake/create-adls-shortcut) |
| July 1 | ADLS shortcut networking | ADLS shortcuts do not use Fabric managed private endpoints; firewall-enabled storage can use trusted workspace access. | Added the supported network pattern. [Source](https://learn.microsoft.com/en-us/fabric/onelake/create-adls-shortcut) |
| July 6 | SAP replication-flow matrix | Initial and Delta support became explicitly connection and object specific. Objects without a stable key can be Initial Only. | Added source and object eligibility checks. [Source](https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Acquiring-Preparing-Modeling-Data/Acquiring-and-Preparing-Data-in-the-Data-Builder/select-source-and-target-connections-for-replication-flows-1089119.md) |
| July 13 | Shortcut schema synchronization | Schema propagation guidance was revised and timing remains variable. | Removed unconditional schema-evolution claims. [Source commit](https://github.com/MicrosoftDocs/fabric-docs/commit/20a1f6be90e62b4a8c1bb7b9b4d17a5fa4c10554) |
| July 26 | Mirroring limits | General limits are 1,000 tables and 1 TB of captured changes per mirrored database per day. | Added platform guardrails to Method 2. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/troubleshooting) |
| August 11 | Files versus Tables | Raw Parquet under Lakehouse Files is not automatically a Direct Lake table. | Added the Delta conversion requirement. [Source](https://learn.microsoft.com/en-us/fabric/onelake/onelake-shortcuts) |
| August 13 | OneLake to Datasphere | Microsoft OneLake became a Datasphere replication-flow source with Initial Only support; it is not a target. | Added the current Fabric-to-Datasphere direction. [Source](https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Integrating-data-and-managing-spaces/Integrating-Data-Via-Connections/microsoft-onelake-connections-057fa4b.md) |
| August 14 | Trusted workspace access | Trusted workspace access became GA for firewall-enabled ADLS and requires purchased F capacity, workspace identity, RBAC, ACLs, and a resource-instance rule. | Added to secure staging designs. [Source](https://learn.microsoft.com/en-us/fabric/security/security-trusted-workspace-access) |
| Effective September 5 and November 30, 2025; source refreshed August 19, 2026 | Semantic-model lifecycle | New items stopped receiving automatic default semantic models, then existing default models were decoupled. | Added explicit semantic-model creation without presenting the restriction as a new August 2026 feature. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/get-started-with-mirroring) |
| August 28 | Mirroring operations | Storage is included up to 1 TB per purchased CU, storage remains billable while capacity is paused, and no fixed SAP freshness SLA was added. | Added exact cost and SLO guidance. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/overview) |
| September 9 | Direct Lake framing | Documentation clarified on-demand column loading, framing, automatic updates, refresh-failure suspension, fallback boundaries, and file guardrails. | Replaced "always latest" and "no memory cache" language. [Source](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-how-it-works) |
| September 9 | Direct Lake licensing | Direct Lake requires Fabric capacity, has SKU guardrails, and has F64 versus sub-F64 viewer-license implications. | Added capacity and consumer-license checks. [Source](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-overview) |

### Security, networking, licensing, and lifecycle

| Effective or first documented date | Area | Update | Guide impact and source |
| --- | --- | --- | --- |
| July 1 | Eventstream retention | Default retention is one day, configurable up to 90 days, with added OneLake storage cost beyond one day. | Added replay, residency, and cost decisions. [Source](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/configure-settings) |
| July 20 | Eventstream network selection | Guidance now separates internal traffic, inbound Private Link, managed private endpoints, and outbound VNet injection. | Added connection direction to event designs. [Source](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/choose-the-right-network-security-feature) |
| August 5 | Legacy ADF SAP CDC | Microsoft warned that SAP Note 3255746 can block ODP RFC calls from third-party clients, including ADF SAP CDC. | Reclassified the connector as migration risk. [Source](https://learn.microsoft.com/en-us/azure/data-factory/sap-change-data-capture-introduction-architecture) |
| August 5 | Fabric capacity | Microsoft reinforced F SKUs and documented retirement or consolidation of Power BI Premium per-capacity purchasing. | New capacity planning should use F SKUs. [Source](https://learn.microsoft.com/en-us/fabric/enterprise/licenses) |
| August 27 | Power BI SAP federation | Gateway SSO guidance clarified when per-user source identity is preserved. | Added explicit SSO versus stored-credential checks. [Source](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-sso-overview) |
| September 2 | Workspace Private Link | Current matrices support SAP Mirroring, Open Mirroring, Copy Job, Eventstream, shortcuts, and SQL endpoints in defined scopes, while semantic models remain unsupported in restricted workspaces. | Added workload-specific workspace design. [Source](https://learn.microsoft.com/en-us/fabric/security/security-workspace-level-private-links-support) |
| September 2 | Eventstream custom endpoint | Detailed Private Link matrices list custom endpoints as unsupported, while higher-level guidance conflicts. | Uses the conservative unsupported position. [Source](https://learn.microsoft.com/en-us/fabric/security/security-private-links-overview) |
| September 9 | Fabric security availability | Item-level Private Link, CMK, and outbound-access-protection availability was refreshed. | Replaced generic private-network claims with item checks. [Source](https://learn.microsoft.com/en-us/fabric/security/security-feature-availability) |
| September 9 | SAP Premium Outbound | SAP refreshed volume-block sizing and 360-day monitoring guidance. The published example uses one block per 20 GB transferred. | Added separate commercial sizing for Datasphere methods. [Source](https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Acquiring-Preparing-Modeling-Data/Acquiring-and-Preparing-Data-in-the-Data-Builder/premium-outbound-integration-4e9c6ac.md) |
| September 10 to 11 | Dataflow Gen2 pricing | Dataflow pricing changed, including tiered CI/CD standard-compute billing. | Capacity estimates must use the current Dataflow meter. [Source commit](https://github.com/MicrosoftDocs/fabric-docs/commit/45f6e2a4bc7bfb3413fa568e2560fd32b4c801df) |
| September 11 cutoff | SAP Event Mesh | Event Mesh Lite is being discontinued; the Default plan is recommended. Advanced Event Mesh has a separate migration process. | Added plan and entitlement checks. [Source](https://help.sap.com/docs/SAP_EM/bf82e6b26456494cbdd197057c09979f/ef79898d432a4553b48186dc1d745945.html) |
| September 11 cutoff | SAP BDC terminology | Current entitlement material uses Cloud ERP Intelligence and identifies Datasphere as a core BDC component. | Corrected the BDC and Datasphere relationship. [Source](https://help.sap.com/docs/SAP_BUSINESS_DATA_CLOUD/f7acf8c9dad54e99b5ce5ebc633ed8e1/89e883e695724b53a140bef43bfb6ada.html) |

### SAP BDC Connect, partners, and unresolved status

| Effective or first documented date | Area | Update | Guide impact and source |
| --- | --- | --- | --- |
| July 20 | SAP BDC Connect | SAP announced GA for Google BigQuery and updated BDC Azure locations. Fabric was absent from the current supported-system list. | Progress on another target is not treated as Fabric availability. [Source](https://help.sap.com/docs/SAP_BUSINESS_DATA_CLOUD/cbce6bb04a6e4546aa4a44e1daa55599/ab4b1ecedd244f068756dff01b7104d6.html) |
| August 5 | SAP BDC Connect for Fabric | Microsoft's SAP CDC page still described the Fabric integration as available later in 2026. | Confirms that public production availability was not established by August. [Source](https://learn.microsoft.com/en-us/azure/data-factory/sap-change-data-capture-introduction-architecture) |
| September 11 cutoff | Generic BDC Connect | Current SAP Help documents capacity-unit metering, region and hyperscaler compatibility, and possible caching. | Removed metadata-only, free, cross-region, and write-through assumptions. [Source](https://help.sap.com/docs/SAP_BUSINESS_DATA_CLOUD/f7acf8c9dad54e99b5ce5ebc633ed8e1/ccbd8fe7c2394009b546b73b1dd6c164.html) |
| September 11 cutoff | BDC Connect for Fabric | No public setup guide, supported-system entry, roadmap item, Preview announcement, or GA announcement was found. | Status remains planned Q3 2026 with public availability unconfirmed. [Source](https://news.sap.com/2025/11/sap-bdc-connect-for-microsoft-fabric-business-insights-ai-innovation/) |
| Partner page current at cutoff | SAP-capable partners | Current Microsoft entries include AecorSoft, ASAPIO, CData, dab, Qlik, Simplement, SNP, and Theobald. | Partner list and product names were replaced. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/open-mirroring-partners-ecosystem) |
| Partner page current at cutoff | Partner minimum versions | Microsoft identifies SNP Glue release 2502 and Theobald Xtract Universal version 2025.3.26.15 for Open Mirroring support. | Added version checks to procurement. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/open-mirroring-partners-ecosystem) |
| September 11 cutoff | Partner status | Microsoft-listed readiness does not prove every SAP release, runtime, certification version, latency, or license term. | Added exact product and support-contract validation. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/open-mirroring-partners-ecosystem) |
| September 11 cutoff | Copy Job CDC conflict | GA announcement and source matrix conflict with a Preview connector heading and Preview Lakehouse scope. | Full path is not labeled unconditionally GA. [Source](https://learn.microsoft.com/en-us/fabric/data-factory/copy-job-connectors) |
| September 11 cutoff | Open Mirroring conflict | Current Learn treats it as GA; the older roadmap card remains Preview. | Both statuses are disclosed. [Source](https://learn.microsoft.com/en-us/fabric/mirroring/get-started-with-mirroring) |
| September 11 cutoff | Eventstream Private Link conflict | Higher-level guidance says custom endpoints are supported, while detailed matrices say unsupported. | Detailed support matrix controls the conservative design. [Source](https://learn.microsoft.com/en-us/fabric/security/security-private-links-overview) |
| September 11 cutoff | BDC Connect conflict | Planned Q3 2026 GA had no public delivery confirmation by the cutoff. | Remains a planned method with a production gate. [Source](https://community.fabric.microsoft.com/t5/Fabric-Updates-Blog/SAP-and-Microsoft-accelerate-business-insights-and-AI-innovation/ba-p/5172482) |

## Appendix B: references

### Fabric SAP connectors and Copy Job

| Resource | Link |
| --- | --- |
| Fabric connector overview | <https://learn.microsoft.com/en-us/fabric/data-factory/connector-overview> |
| Copy Job connectors | <https://learn.microsoft.com/en-us/fabric/data-factory/copy-job-connectors> |
| Copy Job with SAP ABAP Add-On | <https://learn.microsoft.com/en-us/fabric/data-factory/copy-job-tutorial-sap-abap> |
| SAP HANA connector | <https://learn.microsoft.com/en-us/fabric/data-factory/connector-sap-hana-overview> |
| SAP Table Application Server | <https://learn.microsoft.com/en-us/fabric/data-factory/connector-sap-table-application-server-overview> |
| SAP Table Message Server | <https://learn.microsoft.com/en-us/fabric/data-factory/connector-sap-table-message-server-overview> |
| SAP BW Application Server | <https://learn.microsoft.com/en-us/fabric/data-factory/connector-sap-bw-application-server-overview> |
| SAP BW Message Server | <https://learn.microsoft.com/en-us/fabric/data-factory/connector-sap-bw-message-server-overview> |
| SAP BW connector setup and implementation lifecycle | <https://learn.microsoft.com/en-us/power-query/connectors/sap-bw/application-setup-and-connect> |
| SAP BW Open Hub Application Server | <https://learn.microsoft.com/en-us/fabric/data-factory/connector-sap-bw-open-hub-application-server-overview> |
| SAP BW Open Hub Message Server | <https://learn.microsoft.com/en-us/fabric/data-factory/connector-sap-bw-open-hub-message-server-overview> |
| OData connector | <https://learn.microsoft.com/en-us/fabric/data-factory/connector-odata-overview> |

### Mirroring and SAP Datasphere Outbound

| Resource | Link |
| --- | --- |
| Mirrored databases from SAP | <https://learn.microsoft.com/en-us/fabric/mirroring/sap> |
| SAP mirroring tutorial | <https://learn.microsoft.com/en-us/fabric/mirroring/sap-datasphere-tutorial> |
| SAP mirroring limitations | <https://learn.microsoft.com/en-us/fabric/mirroring/sap-limitations> |
| Mirroring overview and cost | <https://learn.microsoft.com/en-us/fabric/mirroring/overview> |
| Mirroring troubleshooting and limits | <https://learn.microsoft.com/en-us/fabric/mirroring/troubleshooting> |
| SAP Datasphere Outbound Copy Job tutorial | <https://learn.microsoft.com/en-us/fabric/data-factory/copy-job-tutorial-sap-datasphere> |
| CDC in Copy Job | <https://learn.microsoft.com/en-us/fabric/data-factory/cdc-copy-job> |
| SAP Premium Outbound Integration | <https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Acquiring-Preparing-Modeling-Data/Acquiring-and-Preparing-Data-in-the-Data-Builder/premium-outbound-integration-4e9c6ac.md> |
| SAP Microsoft OneLake connection | <https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Integrating-data-and-managing-spaces/Integrating-Data-Via-Connections/microsoft-onelake-connections-057fa4b.md> |
| SAP S/4HANA Cloud connections | <https://help.sap.com/docs/SAP_DATASPHERE/be5967d099974c69b77f4549425ca4c0/a98e5ffdf47c44d9a845dca01a18bd82.html> |
| SAP ABAP SQL Services | <https://help.sap.com/docs/SAP_DATASPHERE/9f804b8efa8043539289f42f372c4862/4d7474595a5b41bb986616262ff44a3a.html> |
| SAP replication-flow source selection | <https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Acquiring-Preparing-Modeling-Data/Acquiring-and-Preparing-Data-in-the-Data-Builder/add-the-source-for-a-replication-flow-7496380.md> |

### Power BI and OneLake

| Resource | Link |
| --- | --- |
| DirectQuery and SAP BW | <https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-directquery-sap-bw> |
| DirectQuery for SAP HANA | <https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-directquery-sap-hana> |
| Extract SAP data from Fabric notebooks | <https://learn.microsoft.com/en-us/azure/sap/workloads/extract-sap-data> |
| Gateway single sign-on overview | <https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-sso-overview> |
| Direct Lake overview | <https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-overview> |
| Direct Lake security integration | <https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-security-integration> |
| Direct Lake on OneLake GA announcement | <https://community.fabric.microsoft.com/blog/fbc_pbiupdatesblog/power-bi-march-2026-feature-summary/5173928> |
| OneLake shortcuts | <https://learn.microsoft.com/en-us/fabric/onelake/onelake-shortcuts> |

### Eventstream and Open Mirroring

| Resource | Link |
| --- | --- |
| SAP Datasphere to Eventstream tutorial | <https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/replicate-data-with-replication-flow> |
| SAP Apache Kafka target message format | <https://github.com/SAP-docs/sap-datasphere/blob/main/docs/Acquiring-Preparing-Modeling-Data/Acquiring-and-Preparing-Data-in-the-Data-Builder/apache-kafka-targets-for-replication-flows-6df55db.md> |
| Eventstream Lakehouse destination | <https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/add-destination-lakehouse> |
| Eventstream network security selection | <https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/choose-the-right-network-security-feature> |
| Azure Event Grid source | <https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/add-source-azure-event-grid> |
| Eventstream settings and retention | <https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/configure-settings> |
| Open Mirroring partner ecosystem | <https://learn.microsoft.com/en-us/fabric/mirroring/open-mirroring-partners-ecosystem> |
| Open Mirroring overview | <https://learn.microsoft.com/en-us/fabric/mirroring/open-mirroring> |
| Open Mirroring landing-zone format | <https://learn.microsoft.com/en-us/fabric/mirroring/open-mirroring-landing-zone-format> |
| SAP Event Mesh Lite lifecycle | <https://help.sap.com/docs/SAP_EM/bf82e6b26456494cbdd197057c09979f/ef79898d432a4553b48186dc1d745945.html> |

### SAP BDC Connect

| Resource | Link |
| --- | --- |
| SAP and Microsoft announcement | <https://news.sap.com/2025/11/sap-bdc-connect-for-microsoft-fabric-business-insights-ai-innovation/> |
| Microsoft Fabric announcement | <https://community.fabric.microsoft.com/t5/Fabric-Updates-Blog/SAP-and-Microsoft-accelerate-business-insights-and-AI-innovation/ba-p/5172482> |
| SAP Sapphire 2026 Microsoft update | <https://azure.microsoft.com/en-us/blog/advancing-enterprise-ai-new-sap-on-azure-announcements-from-sap-sapphire-2026/> |
| SAP BDC Connect provisioning and metering | <https://help.sap.com/docs/SAP_BUSINESS_DATA_CLOUD/f7acf8c9dad54e99b5ce5ebc633ed8e1/ccbd8fe7c2394009b546b73b1dd6c164.html> |
| SAP BDC entitlements | <https://help.sap.com/docs/SAP_BUSINESS_DATA_CLOUD/f7acf8c9dad54e99b5ce5ebc633ed8e1/89e883e695724b53a140bef43bfb6ada.html> |

### Legacy ADF SAP CDC

| Resource | Link |
| --- | --- |
| ADF SAP CDC architecture and SAP Note warning | <https://learn.microsoft.com/en-us/azure/data-factory/sap-change-data-capture-introduction-architecture> |
| ADF SAP CDC to Fabric Lakehouse | <https://learn.microsoft.com/en-us/azure/data-factory/change-data-capture-from-sap-to-onelake-with-azure-data-factory> |

### Fabric network security

| Resource | Link |
| --- | --- |
| Security feature availability | <https://learn.microsoft.com/en-us/fabric/security/security-feature-availability> |
| Workspace Private Link support | <https://learn.microsoft.com/en-us/fabric/security/security-workspace-level-private-links-support> |
| ADLS Gen2 shortcut networking | <https://learn.microsoft.com/en-us/fabric/onelake/create-adls-shortcut> |
| Trusted workspace access | <https://learn.microsoft.com/en-us/fabric/security/security-trusted-workspace-access> |
| CI/CD network security | <https://learn.microsoft.com/en-us/fabric/cicd/cicd-security> |

## Appendix C: glossary

| Term | Definition |
| --- | --- |
| ABAP | SAP application programming language and runtime |
| BDC | SAP Business Data Cloud |
| BTP | SAP Business Technology Platform |
| CDC | Change data capture |
| CDS | Core Data Services |
| Direct Lake | Power BI storage mode for supported Delta tables in OneLake |
| DQ | DirectQuery |
| NCo | SAP Connector for Microsoft .NET |
| ODP | SAP Operational Data Provisioning |
| OPDG | On-premises data gateway |
| RFC | SAP Remote Function Call |
| SHIR | Azure Data Factory self-hosted integration runtime |
| SLT | SAP Landscape Transformation Replication Server |

---

*Verified against public Microsoft and SAP sources available on September 11, 2026.*
