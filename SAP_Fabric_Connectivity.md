# SAP Connectivity in Microsoft Fabric

**Last updated:** April 2026  
**Sources:** Official Microsoft Fabric documentation, Fabric November 2025 Feature Summary (Ignite 2025), Fabric March 2026 Feature Summary (FabCon 2026)

---

## Overview

Microsoft Fabric offers multiple ways to connect to SAP systems, ranging from traditional batch/ETL connectors in Data Factory to near real-time replication via Mirroring. The right approach depends on freshness requirements, SAP source system, and the desired analytics pattern.

```mermaid
graph TD
    subgraph SAP["SAP Systems"]
        S1[SAP S/4HANA<br/>on-prem & cloud]
        S2[SAP ECC]
        S3[SAP BW / BW4HANA]
        S4[SAP HANA DB]
        S5[SAP SuccessFactors<br/>Ariba · Concur]
    end

    subgraph Methods["Connection Methods"]
        M1[Data Factory Connectors<br/>Batch / ETL]
        M2[Mirroring for SAP<br/>Near Real-Time<br/>via SAP Datasphere]
        M3[Copy Job CDC<br/>Change Data Capture<br/>via SAP Datasphere]
    end

    subgraph Fabric["Microsoft Fabric"]
        F1[OneLake<br/>Delta Lake]
        F2[Lakehouse<br/>SQL Endpoint]
        F3[Power BI<br/>Semantic Models]
        F4[Notebooks<br/>& Pipelines]
    end

    S1 & S2 & S3 & S4 & S5 --> M1
    S1 & S2 & S3 & S5 --> M2
    S1 & S2 & S3 & S5 --> M3

    M1 --> F1
    M2 --> F1
    M3 --> F1
    F1 --> F2
    F2 --> F3
    F2 --> F4
```

---

## Method 1 — Data Factory Connectors (Batch / ETL)

Seven dedicated SAP connectors are available in Microsoft Fabric Data Factory for scheduled or on-demand data extraction.

### Connector Reference Table

| Connector | Dataflow Gen2 | Pipeline (Copy) | Copy Job | Gateway Required |
|-----------|:-------------:|:---------------:|:--------:|-----------------|
| **SAP BW Application Server** | ✅ Import + DirectQuery | ❌ | ❌ | On-premises *(SAP .NET Connector 3.0/3.1 required)* |
| **SAP BW Message Server** | ✅ Import + DirectQuery | ❌ | ❌ | On-premises *(SAP .NET Connector 3.0/3.1 required)* |
| **SAP BW Open Hub – App. Server** | ✅ | ✅ | ❌ | None / On-premises / VNet |
| **SAP BW Open Hub – Msg. Server** | ✅ | ✅ | ❌ | On-premises |
| **SAP HANA Database** | ✅ | ✅ Lookup + Copy | ✅ | On-premises (Basic / Windows auth) |
| **SAP Table – App. Server** | ❌ | ✅ | ✅ | None / On-premises |
| **SAP Table – Message Server** | ❌ | ✅ | ❌ | None / On-premises |

### When to Use

- **SAP BW connectors** — best for extracting data from BW InfoProviders, BEx queries, and Open Hub destinations. Support BW 7.3, 7.5, BW/4HANA 2.0.
- **SAP HANA** — direct read from HANA views, tables, and stored procedures. Supports Copy job for scalable ingestion.
- **SAP Table** — generic ABAP table/view extraction via RFC. Ideal for custom or standard SAP tables (e.g., `VBAK`, `MARA`, `KNA1`).

> ⚠️ **Limitation:** These connectors perform batch copies. They require manual watermark management or full reload for incremental patterns. No native CDC.

---

## Method 2 — Mirroring for SAP (Near Real-Time)

Mirroring for SAP provides **continuous, near real-time replication** of SAP data into Microsoft Fabric's OneLake, without any custom ETL pipeline to maintain.

```mermaid
sequenceDiagram
    participant SAP as SAP Application<br/>(S/4HANA, ECC, BW...)
    participant DS as SAP Datasphere<br/>Premium Outbound Integration
    participant MF as Fabric Mirroring Engine
    participant OL as OneLake<br/>(Delta Lake)
    participant SQL as Fabric SQL<br/>Analytics Endpoint

    SAP->>DS: Native SAP extraction<br/>(change detection)
    DS->>MF: Replication flows<br/>(inserts / updates / deletes)
    MF->>OL: Write Delta tables<br/>(near real-time)
    OL->>SQL: Auto-sync<br/>queryable immediately
    SQL-->>SAP: No impact on<br/>production systems
```

### Architecture

**Technology stack:**
- **SAP Datasphere Premium Outbound Integration** — acts as the bridge between SAP source systems and Fabric, leveraging SAP's native data extraction technologies (SLT, ODP, CDS Views).
- **Fabric Mirroring Engine** — continuously replicates change data into OneLake in Delta Lake format.
- **SQL Analytics Endpoint** — automatically created, allowing immediate SQL queries over mirrored tables.

### Supported SAP Sources

| SAP System | Deployment | Support |
|-----------|-----------|---------|
| SAP S/4HANA | On-premises | ✅ |
| SAP S/4HANA Cloud | Cloud (public + private) | ✅ |
| SAP ECC | On-premises | ✅ |
| SAP BW | On-premises | ✅ |
| SAP BW/4HANA | On-premises & cloud | ✅ |
| SAP SuccessFactors | SaaS | ✅ |
| SAP Ariba | SaaS | ✅ |
| SAP Concur | SaaS | ✅ |

### Key Benefits

- **No ETL code to maintain** — schema evolution is handled automatically
- **Near real-time freshness** — changes flow continuously into OneLake
- **End-to-end lineage** — full data governance and audit trail
- **Native Fabric integration** — SQL endpoint, Power BI, Notebooks, and Lakehouses all consume mirrored data directly
- **No impact on SAP production** — extraction runs through SAP Datasphere, not directly on the OLTP system

### Prerequisites

1. **SAP Datasphere** license with **Premium Outbound Integration** add-on
2. SAP Datasphere configured with replication flows pointing to the SAP source systems
3. Fabric capacity (F2 or higher recommended for production)
4. Network connectivity: SAP Datasphere → Fabric (outbound HTTPS)

---

## Method 3 — Copy Job CDC for SAP

Introduced at **Ignite 2025**, Copy Job now supports **Change Data Capture (CDC)** for SAP via Datasphere.

| Feature | Details |
|---------|---------|
| Change types captured | Inserts, Updates, Deletes |
| Watermark column needed | ❌ No |
| Manual refresh needed | ❌ No |
| Merge destination | Fabric Lakehouse |
| Monitoring | Run-level stats: load type, row counts per insert/update/delete |

> **Difference vs. Mirroring:** CDC in Copy Job runs on a scheduled trigger (not continuous streaming). It is best suited for near-real-time scenarios that need explicit orchestration control, while Mirroring is fully autonomous and continuous.

---

## Decision Guide

```mermaid
flowchart TD
    A[SAP Data Need] --> B{Freshness<br/>Requirement?}

    B -->|Daily / Weekly batch| C{Source type?}
    B -->|Near real-time| D{Autonomous<br/>or Orchestrated?}

    C -->|SAP BW InfoProvider<br/>or BEx Query| E[SAP BW Connectors<br/>Dataflow Gen2 / Pipeline]
    C -->|HANA Views / Tables| F[SAP HANA Connector<br/>Pipeline + Copy Job]
    C -->|ABAP Tables RFC| G[SAP Table Connector<br/>Pipeline + Copy Job]

    D -->|Autonomous<br/>continuous replication| H[Mirroring for SAP GA<br/>via SAP Datasphere]
    D -->|Orchestrated CDC<br/>with explicit control| I[Copy Job CDC for SAP<br/>via SAP Datasphere]

    E & F & G --> J[Fabric OneLake<br/>Delta Lake]
    H --> J
    I --> J
    J --> K[SQL Endpoint · Power BI<br/>Notebooks · Lakehouse]
```

---

## 📢 Key Announcements

### Ignite 2025 — November 2025

| Feature | Status | Coverage |
|---------|--------|---------|
| **Mirroring for SAP** | 🔵 **Preview** | S/4HANA, BW, BW/4HANA, SuccessFactors, Ariba |
| **Copy Job CDC for SAP** via Datasphere | ✅ **GA** | SAP via Datasphere → Lakehouse |

**What it meant:** For the first time, Fabric offered a near real-time, no-ETL path for SAP data. The preview validated the architecture with early adopters across the SAP customer base.

---

### FabCon 2026 — March 2026

| Feature | Status | What's New |
|---------|--------|-----------|
| **Mirroring for SAP** | ✅ **Generally Available** | Added SAP ECC + SAP Concur. Production-ready for enterprise. |

**What it means:** Mirroring for SAP is now a fully supported, enterprise-grade capability in Fabric. Organizations can confidently migrate from custom SAP-to-Fabric ETL pipelines to the native Mirroring approach.

> 📄 Official documentation: [Microsoft Fabric Mirrored Databases From SAP](https://learn.microsoft.com/fabric/mirroring/sap)

---

## Comparison Summary

| | Batch Connectors | Copy Job CDC | Mirroring for SAP |
|--|:---:|:---:|:---:|
| **Freshness** | Hourly to daily | Minutes (scheduled) | Near real-time (continuous) |
| **Custom ETL** | Yes (watermark logic) | Minimal | None |
| **SAP Datasphere needed** | ❌ | ✅ | ✅ |
| **Supported SAP sources** | BW, HANA, ABAP Tables | SAP via Datasphere | Full SAP landscape |
| **DirectQuery from Power BI** | BW only (Dataflow Gen2) | ❌ | Via SQL Endpoint |
| **CDC (insert/update/delete)** | ❌ | ✅ | ✅ (continuous) |
| **GA status** | ✅ All GA | ✅ GA | ✅ GA (March 2026) |

---

## References

1. [Fabric Data Factory Connector Overview](https://learn.microsoft.com/fabric/data-factory/connector-overview)
2. [Microsoft Fabric Mirrored Databases From SAP](https://learn.microsoft.com/fabric/mirroring/sap)
3. [SAP HANA Connector — Fabric](https://learn.microsoft.com/fabric/data-factory/connector-sap-hana-database-overview)
4. [SAP BW Open Hub Connector — Fabric](https://learn.microsoft.com/fabric/data-factory/connector-sap-bw-open-hub-overview)
5. [SAP Table Connector — Fabric](https://learn.microsoft.com/fabric/data-factory/connector-sap-table-overview)
6. [Fabric November 2025 Feature Summary (Ignite 2025)](https://blog.fabric.microsoft.com/en-us/blog/fabric-november-2025-feature-summary)
7. [Fabric March 2026 Feature Summary (FabCon 2026)](https://blog.fabric.microsoft.com/en-us/blog/fabric-march-2026-feature-summary)
8. [Mirroring Overview in Microsoft Fabric](https://learn.microsoft.com/fabric/mirroring/overview)
