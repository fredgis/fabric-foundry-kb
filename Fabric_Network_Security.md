---
title: "Network Configurations in Microsoft Fabric"
subtitle: "Architecture, Security & Best Practices"
date: "April 2026"
---

## Overview

Microsoft Fabric is a unified SaaS platform for analytics and AI, bringing together Data Factory, Data Engineering, Data Science, Data Warehousing, Real-Time Intelligence and Power BI around a single data lake: **OneLake**.

Network security in Fabric is built around three fundamental pillars:

| Pillar | Objective | Key Features |
|--------|-----------|-------------|
| **Inbound Protection** | Control who accesses Fabric | Conditional Access, Private Links (tenant/workspace), IP Firewall |
| **Secure Outbound Access** | Connect Fabric to protected data sources | Trusted Workspace Access, Managed Private Endpoints, VNet/On-prem Gateways |
| **Outbound Protection** | Prevent data exfiltration | Outbound Access Policies, allowed destination rules |

Combining **Inbound + Outbound Protection** provides complete **Data Exfiltration Protection (DEP)**.

```mermaid
flowchart TB
    subgraph Internet["Internet / Public Network"]
        Users["Users"]
        ExtApps["Applications"]
    end

    subgraph Inbound["Inbound Protection"]
        CA["Entra Conditional Access"]
        TLPL["Private Link Tenant"]
        WSPL["Private Link Workspace"]
        IPFW["IP Firewall Workspace"]
    end

    subgraph Fabric["Microsoft Fabric Tenant"]
        direction TB
        subgraph WS1["Workspace A"]
            LH["Lakehouse"]
            WH["Warehouse"]
            NB["Notebook"]
            SJD["Spark Job"]
        end
        subgraph WS2["Workspace B"]
            SM["Semantic Model"]
            RPT["Report"]
            PL["Pipeline"]
        end
        OL["OneLake"]
    end

    subgraph Outbound["Secure Outbound Access"]
        TWA["Trusted Workspace Access"]
        MPE["Managed Private Endpoints"]
        VGW["VNet Data Gateway"]
        OGW["On-Prem Gateway"]
    end

    subgraph ExtData["External Data Sources"]
        ADLS["ADLS Gen2"]
        ASQL["Azure SQL DB"]
        OnPrem["On-Premises"]
    end

    subgraph OutProt["Outbound Protection"]
        OAP["Outbound Access Policies"]
    end

    Users --> CA --> Fabric
    Users --> TLPL --> Fabric
    Users --> WSPL --> Fabric
    Users --> IPFW --> Fabric
    ExtApps --> CA --> Fabric

    Fabric --> TWA --> ADLS
    Fabric --> MPE --> ASQL
    Fabric --> VGW --> ADLS
    Fabric --> OGW --> OnPrem
    Fabric --> OAP
    OAP -.->|Blocked| Internet

    style Internet fill:#fce4ec,stroke:#c62828,color:#000
    style Inbound fill:#e8eaf6,stroke:#283593,color:#000
    style Fabric fill:#e3f2fd,stroke:#0d47a1,color:#000
    style WS1 fill:#bbdefb,stroke:#1565c0,color:#000
    style WS2 fill:#bbdefb,stroke:#1565c0,color:#000
    style Outbound fill:#e8f5e9,stroke:#2e7d32,color:#000
    style ExtData fill:#fff3e0,stroke:#e65100,color:#000
    style OutProt fill:#ffebee,stroke:#b71c1c,color:#000
    style OL fill:#b3e5fc,stroke:#0277bd,color:#000
    style CA fill:#d1c4e9,stroke:#4527a0,color:#000
    style TLPL fill:#d1c4e9,stroke:#4527a0,color:#000
    style WSPL fill:#d1c4e9,stroke:#4527a0,color:#000
    style IPFW fill:#d1c4e9,stroke:#4527a0,color:#000
    style TWA fill:#c8e6c9,stroke:#2e7d32,color:#000
    style MPE fill:#c8e6c9,stroke:#2e7d32,color:#000
    style VGW fill:#c8e6c9,stroke:#2e7d32,color:#000
    style OGW fill:#c8e6c9,stroke:#2e7d32,color:#000
    style OAP fill:#ef9a9a,stroke:#b71c1c,color:#000
    style ADLS fill:#ffe0b2,stroke:#e65100,color:#000
    style ASQL fill:#ffe0b2,stroke:#e65100,color:#000
    style OnPrem fill:#ffe0b2,stroke:#e65100,color:#000
```

## Secure by Default

Microsoft Fabric is **secure by default** without any additional configuration:

- **Authentication**: Every interaction is authenticated via **Microsoft Entra ID**
- **Encryption in transit**: All traffic is encrypted using **TLS 1.2** minimum (TLS 1.3 negotiation when available)
- **Encryption at rest**: All data in OneLake is automatically encrypted
- **Microsoft backbone network**: Internal communications between Fabric experiences travel through the Microsoft private network, never over the public internet
- **Secure endpoints**: The Fabric backend is protected by a virtual network and is not directly accessible from the public internet

```mermaid
flowchart LR
    subgraph Fabric["Microsoft Fabric - Microsoft Backbone"]
        direction LR
        DF["Data Factory"] <-->|TLS 1.2+| DE["Data Engineering"]
        DE <-->|TLS 1.2+| DS["Data Science"]
        DS <-->|TLS 1.2+| DW["Data Warehouse"]
        DW <-->|TLS 1.2+| RTI["Real-Time Intelligence"]
        RTI <-->|TLS 1.2+| PBI["Power BI"]
        ALL["All experiences"] <-->|Private backbone| OL["OneLake"]
    end

    Client["Client (Browser/SSMS)"] -->|TLS 1.2+ / Entra ID| Fabric

    style Fabric fill:#e3f2fd,stroke:#0d47a1,color:#000
    style DF fill:#90caf9,stroke:#1565c0,color:#000
    style DE fill:#90caf9,stroke:#1565c0,color:#000
    style DS fill:#90caf9,stroke:#1565c0,color:#000
    style DW fill:#90caf9,stroke:#1565c0,color:#000
    style RTI fill:#90caf9,stroke:#1565c0,color:#000
    style PBI fill:#ffcc02,stroke:#e6a800,color:#000
    style OL fill:#b3e5fc,stroke:#0277bd,color:#000
    style ALL fill:#bbdefb,stroke:#1565c0,color:#000
    style Client fill:#f3e5f5,stroke:#6a1b9a,color:#000
```

## Inbound Protection

Inbound protection controls traffic entering Fabric from the internet or corporate networks.

### Entra Conditional Access

Microsoft Entra ID Conditional Access is the **Zero Trust** approach for securing access to Fabric. Access decisions are made at authentication time by evaluating contextual signals.

**Evaluated signals:**

| Signal | Policy examples |
|--------|----------------|
| Users and groups | Target specific populations |
| Location / IP | Allow only certain IP ranges or countries |
| Devices | Require compliant devices (Intune) |
| Applications | Apply rules per Fabric application |
| Sign-in risk | Block high-risk sign-ins |

**Possible decisions:** Block, Grant, Require MFA, Require compliant device.

**Prerequisites:** Microsoft Entra ID P1 license (often included in Microsoft 365 E3/E5).

> **Note:** Conditional Access policies apply to Fabric and related Azure services (Power BI, Azure Data Explorer, Azure SQL Database, Azure Storage). This may be considered too broad for some scenarios.

#### Zero Trust Identity Best Practices

As a SaaS service, Microsoft Fabric relies on **identity as the primary security perimeter**. Network controls complement but do not replace a robust identity strategy. The following practices should form the foundation of any Fabric security posture:

| Practice | Description |
|----------|-------------|
| **Phishing-resistant MFA** | Enforce multi-factor authentication using FIDO2 keys, Windows Hello for Business or certificate-based methods. Avoid SMS-based MFA where possible. |
| **Device Compliance** | Require managed or compliant devices (via Microsoft Intune) in Conditional Access policies to prevent access from untrusted endpoints. |
| **Privileged Identity Management (PIM)** | Use Entra PIM for just-in-time, time-limited elevation of Fabric admin and workspace admin roles. Avoid permanent high-privilege assignments. |
| **Service Principal Governance** | Audit and restrict Service Principal and Managed Identity access to Fabric APIs. Apply Conditional Access workload identity policies (Entra Workload ID Premium) to limit tokens to known IP ranges. |
| **Continuous Access Evaluation (CAE)** | Enable CAE so that revoked sessions, changed locations and risk events trigger near-real-time re-evaluation of Fabric access tokens. |

> **Recommendation:** Start with identity controls (MFA, Conditional Access, PIM) before layering network controls. This ensures baseline protection regardless of the user's network path.

```mermaid
flowchart LR
    User["User"] --> Signals["Signals\n- Identity\n- Location\n- Device\n- Application\n- Risk"]
    Signals --> Decision{"Entra\nConditional\nAccess"}
    Decision -->|Grant + MFA| Fabric["Microsoft Fabric"]
    Decision -->|Grant| Fabric
    Decision -->|Block| Blocked["Access Denied"]

    style User fill:#e1f5fe,stroke:#0277bd,color:#000
    style Signals fill:#fff9c4,stroke:#f9a825,color:#000
    style Decision fill:#d1c4e9,stroke:#4527a0,color:#000
    style Fabric fill:#c8e6c9,stroke:#2e7d32,color:#000
    style Blocked fill:#ef9a9a,stroke:#c62828,color:#000
```

### Tenant-Level Private Link

Tenant-level Private Link provides **perimeter-based protection** for the entire Fabric tenant.

**Concept:** An Azure Private Endpoint is created in the customer's VNet, establishing a private tunnel to Fabric via the Microsoft backbone. Fabric becomes inaccessible from the public internet.

**Two key settings:**

| Setting | Effect |
|---------|--------|
| **Azure Private Links** (enabled) | Traffic from the VNet to supported endpoints goes through the Private Link |
| **Block Public Internet Access** (enabled) | Fabric is no longer accessible from the public internet; only Private Link is allowed |

**Configuration scenarios:**

| Private Link | Block Public Access | Behavior |
|:---:|:---:|---|
| Yes | Yes | Access only via Private Endpoint. Unsupported endpoints blocked. |
| Yes | No | VNet traffic via Private Link. Public internet traffic allowed. |
| No | - | Standard access via public internet. |

**Considerations:**

- **All users** must connect through the private network (VPN, ExpressRoute)
- **Bandwidth** impact: static resources (CSS, images) also transit through the Private Endpoint
- Some features have **limitations** (Publish to Web disabled, Copilot not supported, Power BI PDF/PowerPoint export disabled)
- **Spark Starter Pools** are disabled (replaced by custom pools in the managed VNet)
- **Cross-tenant access is not supported:** a Private Endpoint cannot be used to reach a Fabric tenant different from the one associated with the Private Link Service. This limitation is by design and applies to both tenant-level and workspace-level Private Link.
- **Private DNS Zone required:** to resolve Fabric public FQDNs (e.g., `*.fabric.microsoft.com`, `*.pbidedicated.windows.net`, `*.analysis.windows.net`) to private IP addresses, an Azure Private DNS Zone must be created and linked to the VNet. Without proper DNS configuration, clients will continue resolving public IPs and bypass the Private Endpoint. Use Azure Private DNS Zones or configure conditional DNS forwarding from on-premises DNS servers.

```mermaid
flowchart TB
    subgraph OnPrem["On-Premises Network"]
        UserOP["Users"]
    end

    subgraph Azure["Azure"]
        subgraph VNet["Customer VNet"]
            PE["Private Endpoint\n(Private IP)"]
        end
        ER["ExpressRoute / VPN"]
    end

    subgraph Fabric["Microsoft Fabric Tenant"]
        WS1["Workspace A"]
        WS2["Workspace B"]
        OL["OneLake"]
    end

    Internet["Public Internet"]

    OnPrem -->|ExpressRoute/VPN| ER --> VNet
    PE -->|Azure Private Link\nMicrosoft Backbone| Fabric
    Internet -.->|Blocked if\nBlock Public Access| Fabric

    style OnPrem fill:#e0f2f1,stroke:#00695c,color:#000
    style Azure fill:#e8eaf6,stroke:#283593,color:#000
    style VNet fill:#c5cae9,stroke:#1a237e,color:#000
    style Fabric fill:#e3f2fd,stroke:#0d47a1,color:#000
    style Internet fill:#ffcdd2,stroke:#b71c1c,color:#000
    style PE fill:#b2dfdb,stroke:#00695c,color:#000
    style ER fill:#b39ddb,stroke:#4527a0,color:#000
    style WS1 fill:#90caf9,stroke:#1565c0,color:#000
    style WS2 fill:#90caf9,stroke:#1565c0,color:#000
    style OL fill:#b3e5fc,stroke:#0277bd,color:#000
    style UserOP fill:#e0f2f1,stroke:#00695c,color:#000
```

### Workspace-Level Private Link

Workspace-level Private Link offers **granular** control: specific workspaces are protected by Private Link while others remain publicly accessible.

**Key characteristics:**

- **1:1** relationship between a workspace and its Private Link Service
- A Private Link Service can have **multiple Private Endpoints** (from different VNets)
- A VNet can connect to **multiple workspaces** via separate Private Endpoints
- Public access can be restricted **independently** per workspace
- Public workspaces can be secured with Entra Conditional Access or IP Filtering

**Supported items (GA since September 2025):**
Lakehouse, Shortcut, Notebook, ML Experiment/Model, Pipeline, Warehouse, Dataflows, Eventstream, Mirrored DB. Access to workspace-level Private Link workspaces is available via both the Fabric portal and API.

> **Limitation — Unsupported item types:** Power BI reports/dashboards, Fabric databases, Data Activator, deployment pipelines, and default semantic models are **not yet covered** by workspace-level Private Link. These items remain accessible via public endpoints unless the entire tenant is secured with tenant-level Private Link or Microsoft Entra Conditional Access is used. Support for these item types is on the roadmap.

> **DNS configuration:** As with tenant-level Private Link, each workspace Private Endpoint requires a matching Azure Private DNS Zone record so that the workspace-specific FQDN resolves to the Private Endpoint's private IP. When connecting multiple VNets to multiple workspaces, plan the DNS zone topology carefully — a single centralized Private DNS Zone linked to all VNets is recommended over per-VNet zones to avoid resolution conflicts.

```mermaid
flowchart TB
    subgraph VNets["Azure Virtual Networks"]
        subgraph VNetA["VNet A"]
            PEA1["PE to WS1"]
        end
        subgraph VNetB["VNet B"]
            PEB1["PE to WS1"]
            PEB2["PE to WS2"]
            PEB3["PE to WS3"]
        end
    end

    subgraph Fabric["Fabric Tenant"]
        WS1["Workspace 1\nPublic Access: Disabled"]
        WS2["Workspace 2\nPublic Access: Disabled"]
        WS3["Workspace 3\nPublic + Private Access"]
        WS4["Workspace 4\nPublic Access Only"]
    end

    Internet["Internet"]

    PEA1 -->|Private Link| WS1
    PEB1 -->|Private Link| WS1
    PEB2 -->|Private Link| WS2
    PEB3 -->|Private Link| WS3
    Internet -->|Allowed| WS3
    Internet -->|Allowed| WS4
    Internet -.->|Blocked| WS1
    Internet -.->|Blocked| WS2

    style VNets fill:#e8eaf6,stroke:#283593,color:#000
    style VNetA fill:#c5cae9,stroke:#1a237e,color:#000
    style VNetB fill:#c5cae9,stroke:#1a237e,color:#000
    style Fabric fill:#e3f2fd,stroke:#0d47a1,color:#000
    style WS1 fill:#a5d6a7,stroke:#2e7d32,color:#000
    style WS2 fill:#a5d6a7,stroke:#2e7d32,color:#000
    style WS3 fill:#ffe082,stroke:#f9a825,color:#000
    style WS4 fill:#ef9a9a,stroke:#c62828,color:#000
    style Internet fill:#ffcdd2,stroke:#b71c1c,color:#000
    style PEA1 fill:#b2dfdb,stroke:#00695c,color:#000
    style PEB1 fill:#b2dfdb,stroke:#00695c,color:#000
    style PEB2 fill:#b2dfdb,stroke:#00695c,color:#000
    style PEB3 fill:#b2dfdb,stroke:#00695c,color:#000
```

> **Key difference from Tenant-Level Private Link:** Workspace-level Private Link allows you to protect only sensitive workspaces without impacting the entire tenant. This is the recommended approach for organizations that cannot force all users onto a private network.

### Workspace IP Firewall

The workspace IP firewall is the simplest solution to restrict access to a workspace from specific public IP ranges.

**Concept:** Only explicitly allowed IP addresses or IP ranges can access the workspace. No Azure network infrastructure is required.

**Supported items (GA since Q1 2026):**
Lakehouse, Shortcut, Notebook, ML Experiment/Model, Pipeline, Warehouse, Dataflows, Eventstream, Mirrored DB. Both API and UI configuration are supported.

> **Limitation — Unsupported item types:** Power BI reports/dashboards, Fabric databases, Data Activator, deployment pipelines, and default semantic models are **not covered** by workspace IP Firewall rules. Traffic to these items bypasses the IP firewall and remains accessible from any network unless the entire tenant is locked down with tenant-level Private Link or Microsoft Entra Conditional Access. Support for these items is on the roadmap.

> **Note — API access:** Even with strict IP firewall rules, the **Fabric REST API** remains accessible for rule management. Administrators can create, update and delete IP firewall rules via the API regardless of their client IP. This is by design to prevent accidental lockout, but it means API-level governance (Conditional Access, Service Principal restrictions) is essential to avoid unauthorized rule changes.

```mermaid
flowchart LR
    subgraph Allowed["Allowed IPs"]
        IP1["203.0.113.0/24\n(Paris Office)"]
        IP2["198.51.100.0/24\n(London Office)"]
    end

    subgraph Blocked["Unauthorized IPs"]
        IP3["Any other IP"]
    end

    FW{"IP Firewall\nRules"}

    subgraph Fabric["Fabric Workspace"]
        Items["Lakehouse\nWarehouse\nNotebook\n..."]
    end

    IP1 -->|Allowed| FW --> Items
    IP2 -->|Allowed| FW
    IP3 -.->|Blocked| FW

    style Allowed fill:#e8f5e9,stroke:#2e7d32,color:#000
    style Blocked fill:#ffebee,stroke:#c62828,color:#000
    style Fabric fill:#e3f2fd,stroke:#0d47a1,color:#000
    style FW fill:#fff9c4,stroke:#f9a825,color:#000
    style IP1 fill:#a5d6a7,stroke:#2e7d32,color:#000
    style IP2 fill:#a5d6a7,stroke:#2e7d32,color:#000
    style IP3 fill:#ef9a9a,stroke:#c62828,color:#000
    style Items fill:#90caf9,stroke:#1565c0,color:#000
```

### Inbound Options Comparison

| Criteria | Conditional Access | Private Link Tenant | Private Link Workspace | IP Firewall |
|----------|:-:|:-:|:-:|:-:|
| **Granularity** | Tenant (per policy) | Tenant | Workspace | Workspace |
| **Azure infrastructure required** | No | VNet + PE | VNet + PE per WS | No |
| **Complexity** | Low | High | Medium | Low |
| **Approach** | Zero Trust (identity) | Perimeter (network) | Perimeter (network) | IP-based |
| **User impact** | Transparent (MFA) | VPN/ER mandatory | VPN/ER for protected WS | None if IP allowed |
| **Additional cost** | Entra ID P1 | VNet + PE + ER/VPN | VNet + PE | None |
| **Status** | GA | GA | GA | GA |

## Secure Outbound Access

Secure outbound access allows Fabric to connect to data sources protected by firewalls or private networks.

### Trusted Workspace Access

Trusted Workspace Access allows specific Fabric workspaces to securely access **firewall-enabled ADLS Gen2 accounts**.

**Concept:** The Fabric workspace has a **workspace identity** (managed identity). **Resource Instance Rules** are configured on the storage account to authorize only specified workspaces.

**Prerequisites:**
- Workspace associated with a **Fabric F SKU** capacity (not supported on Trial)
- **Workspace Identity** created and configured as Contributor
- Authentication principal with Azure RBAC role on the storage account (Storage Blob Data Contributor/Owner/Reader)
- Resource Instance Rule configured via **ARM Template** or **PowerShell**

**Supported scenarios:**

| Method | Description |
|--------|-------------|
| **OneLake Shortcut** | ADLS Gen2 shortcut in a Lakehouse |
| **Pipeline** | Data copy from firewall-enabled ADLS Gen2 |
| **T-SQL COPY INTO** | Ingestion into a Warehouse |
| **Semantic Model** (import) | Model connected to ADLS Gen2 |
| **AzCopy** | High-performance load to OneLake |

```mermaid
flowchart LR
    subgraph Fabric["Microsoft Fabric"]
        WS["Workspace\n(with Workspace Identity)"]
    end

    subgraph Azure["Azure"]
        subgraph ADLS["ADLS Gen2\n(Firewall enabled)"]
            RIR["Resource Instance Rules\n- Tenant ID\n- Workspace ID"]
        end
    end

    WS -->|"Trusted Access\n(workspace identity)"| RIR
    RIR -->|"Allowed"| ADLS

    Internet["Internet"] -.->|"Blocked by Firewall"| ADLS

    style Fabric fill:#e3f2fd,stroke:#0d47a1,color:#000
    style WS fill:#90caf9,stroke:#1565c0,color:#000
    style Azure fill:#fff3e0,stroke:#e65100,color:#000
    style ADLS fill:#ffe0b2,stroke:#e65100,color:#000
    style RIR fill:#c8e6c9,stroke:#2e7d32,color:#000
    style Internet fill:#ffcdd2,stroke:#b71c1c,color:#000
```

### Managed Private Endpoints

Managed Private Endpoints enable secure, private connections to Azure data sources from Fabric workloads without exposing them to the public network.

**Concept:** Microsoft Fabric creates and manages Private Endpoints in a **managed VNet** dedicated to the workspace. Workspace admins specify the resource ID of the source, the target sub-resource, and a justification.

**Supported sources:** Azure Storage, Azure SQL Database, Azure Cosmos DB, Azure Key Vault, and many more.

**Supported items:**
- Data Engineering (Spark/Python Notebooks, Lakehouses, Spark Job Definitions)
- Eventstream

**Prerequisites:**
- Supported on Fabric Trial and all F SKU capacities
- Data Engineering workload must be available in both the tenant region AND the capacity region

**Limitations:**
- OneLake shortcuts do not yet support ADLS Gen2 / Blob Storage connections via MPE
- Cross-region workspace migration not supported
- FQDN-based creation (Private Link Service) only via REST API

```mermaid
flowchart LR
    subgraph Fabric["Microsoft Fabric"]
        subgraph MVNET["Managed VNet\n(managed by Microsoft)"]
            Spark["Spark Cluster\n(isolated)"]
            MPE1["Managed PE\nto Azure SQL"]
            MPE2["Managed PE\nto ADLS Gen2"]
        end
    end

    subgraph Azure["Azure (Customer)"]
        SQL["Azure SQL DB\n(Firewall enabled)"]
        ADLS["ADLS Gen2\n(Private)"]
    end

    Spark --> MPE1 -->|"Private Link\nMicrosoft Backbone"| SQL
    Spark --> MPE2 -->|"Private Link\nMicrosoft Backbone"| ADLS

    style Fabric fill:#e3f2fd,stroke:#0d47a1,color:#000
    style MVNET fill:#bbdefb,stroke:#1565c0,color:#000
    style Spark fill:#90caf9,stroke:#0d47a1,color:#000
    style MPE1 fill:#c8e6c9,stroke:#2e7d32,color:#000
    style MPE2 fill:#c8e6c9,stroke:#2e7d32,color:#000
    style Azure fill:#fff3e0,stroke:#e65100,color:#000
    style SQL fill:#ffe0b2,stroke:#e65100,color:#000
    style ADLS fill:#ffe0b2,stroke:#e65100,color:#000
```

### Managed Virtual Networks

Managed VNets are virtual networks created and managed by Fabric for each workspace. They provide network isolation for Spark workloads.

**Automatically provisioned when:**
1. **Managed Private Endpoints** are added to the workspace
2. The **Private Link** setting is enabled and a Spark job is executed

**Characteristics:**
- Complete Spark cluster isolation (dedicated network)
- No need to size subnets (managed by Fabric)
- **Starter Pools** are disabled (on-demand Custom Pools, 3-5 min startup)
- Not supported in Switzerland West and West Central US regions

### Data Gateways

#### On-Premises Data Gateway

A gateway installed on a server within the corporate network, acting as a bridge between on-premises data sources and Fabric.

| Characteristic | Detail |
|---------------|--------|
| **Installation** | Windows server in the internal network |
| **Protocol** | Secure outbound channel (no inbound port opening) |
| **Sources** | Any source accessible from the gateway server |
| **Management** | Manual (updates, high availability) |

#### VNet Data Gateway

A managed gateway deployed into a customer's Azure VNet, enabling connections to Azure services within the VNet without an on-premises gateway.

| Characteristic | Detail |
|---------------|--------|
| **Deployment** | Injection into an existing Azure VNet |
| **Management** | Managed by Microsoft |
| **Sources** | Azure services in the VNet or peered VNets |
| **Workloads** | Dataflows Gen2, Semantic Models |
| **Enterprise proxy & cert auth** | GA (2026) — supports enterprise proxy servers and certificate-based authentication for corporate network compliance |

```mermaid
flowchart TB
    subgraph Fabric["Microsoft Fabric"]
        DF["Dataflows Gen2"]
        SM["Semantic Models"]
        PL["Pipelines"]
    end

    subgraph OnPrem["On-Premises Network"]
        OPGW["On-Prem Gateway\n(Windows Server)"]
        SQLSrv["SQL Server"]
        Oracle["Oracle DB"]
        Files["File Shares"]
    end

    subgraph Azure["Azure VNet"]
        VGW["VNet Data Gateway\n(managed)"]
        ASQL["Azure SQL MI"]
        ADLS["ADLS Gen2"]
    end

    DF --> OPGW -->|Secure outbound channel| SQLSrv
    OPGW --> Oracle
    OPGW --> Files
    SM --> VGW -->|Connection within VNet| ASQL
    VGW --> ADLS

    style Fabric fill:#e3f2fd,stroke:#0d47a1,color:#000
    style DF fill:#90caf9,stroke:#1565c0,color:#000
    style SM fill:#90caf9,stroke:#1565c0,color:#000
    style PL fill:#90caf9,stroke:#1565c0,color:#000
    style OnPrem fill:#e0f2f1,stroke:#00695c,color:#000
    style OPGW fill:#80cbc4,stroke:#00695c,color:#000
    style SQLSrv fill:#b2dfdb,stroke:#00695c,color:#000
    style Oracle fill:#b2dfdb,stroke:#00695c,color:#000
    style Files fill:#b2dfdb,stroke:#00695c,color:#000
    style Azure fill:#e8eaf6,stroke:#283593,color:#000
    style VGW fill:#b39ddb,stroke:#4527a0,color:#000
    style ASQL fill:#ffe0b2,stroke:#e65100,color:#000
    style ADLS fill:#ffe0b2,stroke:#e65100,color:#000
```

### Eventstream Private Network Support

*Preview — Q1 2026*

Fabric Eventstreams can now ingest data from private networks via a **managed VNet** and a **streaming data gateway**, enabling secure real-time data ingestion without exposing source endpoints to the public internet. This allows organizations to stream events from Azure Event Hubs, IoT Hub, or custom sources within a VNet directly into Fabric, with traffic routed entirely through the Microsoft backbone.

Key points:
- Eventstreams leverage the workspace's managed VNet for network isolation
- A streaming data gateway bridges the private network to the Eventstream ingestion endpoint
- Supports managed private endpoints for source connectivity
- Custom Endpoint as source/destination and Eventhouse direct ingestion remain unsupported

### Service Tags

Azure Service Tags are automatically managed groups of IP addresses, usable in NSGs, Azure Firewall and user-defined routes.

| Tag | Service | Direction | Regional |
|-----|---------|-----------|----------|
| `Power BI` | Power BI and Microsoft Fabric | Inbound/Outbound | Yes |
| `DataFactory` | Azure Data Factory | Inbound/Outbound | Yes |
| `DataFactoryManagement` | On-premises pipeline | Outbound | No |
| `EventHub` | Azure Event Hubs | Outbound | Yes |
| `KustoAnalytics` | Real-Time Analytics | Inbound/Outbound | No |
| `SQL` | Warehouse | Outbound | Yes |
| `PowerQueryOnline` | Power Query Online | Inbound/Outbound | No |

> **Tip:** When using regional tags, add the tag for the tenant's home region **and** the capacity region (if different), as well as the corresponding paired regions.

#### Using Service Tags with Network Security Groups (NSG)

NSGs can leverage Fabric-related service tags to enforce fine-grained inbound and outbound rules on subnets hosting Private Endpoints, VNet Data Gateways, or on-premises gateway servers.

**Example NSG rules:**

| Priority | Direction | Source/Destination | Service Tag | Action | Purpose |
|----------|-----------|-------------------|-------------|--------|---------|
| 100 | Outbound | VNet | `PowerBI` | Allow | Allow traffic to Fabric/Power BI endpoints |
| 110 | Outbound | VNet | `DataFactory` | Allow | Allow pipeline orchestration traffic |
| 120 | Outbound | VNet | `SQL` | Allow | Allow Warehouse connectivity |
| 200 | Outbound | VNet | `Internet` | Deny | Block all other internet-bound traffic |

#### Centralizing Outbound Traffic with Azure Firewall

For organizations that require centralized egress control, logging and static IP addresses:

- Deploy an **Azure Firewall** (or third-party NVA) in a hub VNet and route traffic from spoke VNets (hosting Private Endpoints or VNet Data Gateways) through the firewall via User Defined Routes (UDR).
- Use **application rules** with service tag-based FQDN filtering to allow only Fabric-related traffic.
- A **NAT Gateway** attached to the firewall subnet provides a **static outbound IP** — useful when external partners or data sources require IP whitelisting.
- All outbound connections are logged in Azure Firewall Diagnostics, enabling centralized auditing and threat detection.

### Secure Outbound Connectors Matrix

| Connection Method | Supported Sources | Fabric Workloads |
|-------------------|-------------------|-----------------|
| **Trusted Workspace Access** | ADLS Gen2 (firewall) | Shortcuts, Pipelines, COPY INTO, Semantic Models |
| **Managed Private Endpoints** | Azure SQL, ADLS Gen2, Cosmos DB, Key Vault... | Spark Notebooks, Lakehouses, Spark Jobs, Eventstream |
| **VNet Data Gateway** | Azure services in a VNet | Dataflows Gen2, Semantic Models |
| **On-Premises Gateway** | SQL Server, Oracle, files, SAP... | Dataflows Gen2, Semantic Models, Pipelines |
| **Service Tags** | Azure SQL VM, SQL MI, REST APIs | Pipelines, network integration |

## Outbound Protection

### Outbound Access Policies

Outbound Access Policies allow you to **restrict outbound connections** from a Fabric workspace to unauthorized destinations.

**Objective:** Prevent malicious users from exfiltrating data to unapproved destinations.

**Characteristics:**
- **Workspace-level** control
- Destinations are allow-listed via **Managed Private Endpoints** or **Data Connections**
- Any connection to a destination not explicitly allowed is **blocked**

**Status (as of April 2026):**

| Item Type | Status |
|-----------|--------|
| Lakehouse, Spark Notebooks, Spark Jobs | **GA** (since Sept 2025) |
| Dataflows, Pipelines, Copy Jobs, Warehouse, Mirrored DBs | **GA** (since Nov 2025) |
| Power BI, Databases | Planned (roadmap) |

```mermaid
flowchart LR
    subgraph Fabric["Fabric Workspace"]
        direction TB
        LH["Lakehouse"]
        NB["Notebook"]
        PL["Pipeline"]
    end

    subgraph Rules["Outbound Rules"]
        direction TB
        Allow["Allowed Destinations\n(via MPE or Data Connections)"]
        Block["Everything Else"]
    end

    subgraph Destinations["Destinations"]
        Corp["Corporate ADLS Gen2\nAllowed"]
        Other["Unknown Public Endpoint\nBlocked"]
    end

    Fabric --> Rules
    Allow -->|MPE| Corp
    Block -.->|Blocked| Other

    style Fabric fill:#e3f2fd,stroke:#0d47a1,color:#000
    style LH fill:#90caf9,stroke:#1565c0,color:#000
    style NB fill:#90caf9,stroke:#1565c0,color:#000
    style PL fill:#90caf9,stroke:#1565c0,color:#000
    style Rules fill:#fff9c4,stroke:#f9a825,color:#000
    style Allow fill:#c8e6c9,stroke:#2e7d32,color:#000
    style Block fill:#ef9a9a,stroke:#c62828,color:#000
    style Destinations fill:#f5f5f5,stroke:#616161,color:#000
    style Corp fill:#a5d6a7,stroke:#2e7d32,color:#000
    style Other fill:#ef9a9a,stroke:#c62828,color:#000
```

### Data Exfiltration Protection (DEP)

Complete **DEP** is achieved by combining inbound AND outbound protection:

| Component | Role |
|-----------|------|
| **Inbound** (Private Link / IP Firewall / Conditional Access) | Controls **who** can access data and **from where** |
| **Outbound** (Outbound Access Policies) | Prevents authorized users from **exfiltrating** data to unapproved destinations |

### Advanced Data Exfiltration Controls

Network-level DEP should be complemented by **data-level** controls to achieve defense in depth:

| Control | Mechanism | Scope |
|---------|-----------|-------|
| **Microsoft Purview Information Protection** | Classify and label sensitive data (sensitivity labels). Labels flow with data across Fabric items (Lakehouses, Warehouses, Semantic Models, Reports). | Tenant |
| **Data Loss Prevention (DLP)** | Define policies in Microsoft Purview DLP to detect and block sharing or export of items containing sensitive information (e.g., prevent download of datasets labeled "Highly Confidential"). | Tenant |
| **Power BI Export Restrictions** | Disable or restrict exports to Excel, CSV, PowerPoint, PDF and printing via tenant settings. When tenant-level Private Link is enabled, several export options are automatically disabled. | Tenant |
| **Endpoint DLP** | Use Microsoft Purview Endpoint DLP on managed devices to prevent copy/paste of Fabric data to USB drives, unauthorized cloud apps or personal email. | Device |
| **Conditional Access — Session Controls** | Leverage Defender for Cloud Apps session policies to monitor, block or limit downloads of sensitive content from the Fabric web portal in real time. | Session |

> **Recommendation:** Combine **Outbound Access Policies** (network) with **Purview sensitivity labels + DLP policies** (data) for a layered approach. Network controls prevent unauthorized destinations; data controls prevent unauthorized actions even on authorized destinations.

```mermaid
flowchart TB
    subgraph DEP["Data Exfiltration Protection"]
        direction LR
        subgraph InP["Inbound Protection"]
            PL1["Private Link"]
            CA1["Conditional Access"]
            IPF["IP Firewall"]
        end
        subgraph OutP["Outbound Protection"]
            OAP["Outbound Access Policies"]
            MPE["Managed Private Endpoints\n(allowed destinations)"]
        end
    end

    ExtUser["External User\n(unauthorized)"] -.->|"Blocked by\nInbound Protection"| InP
    IntUser["Internal User\n(authorized)"] -->|"Access via\nPrivate Link"| InP
    InP -->|Data access| Fabric["Fabric Workspace"]
    Fabric --> OutP
    OutP -->|"Data to\napproved destination"| Corp["Corporate ADLS Gen2"]
    OutP -.->|"Exfiltration\nblocked"| Ext["Unauthorized Destination"]

    style DEP fill:#e8eaf6,stroke:#283593,color:#000
    style InP fill:#c5cae9,stroke:#1a237e,color:#000
    style OutP fill:#c5cae9,stroke:#1a237e,color:#000
    style PL1 fill:#d1c4e9,stroke:#4527a0,color:#000
    style CA1 fill:#d1c4e9,stroke:#4527a0,color:#000
    style IPF fill:#d1c4e9,stroke:#4527a0,color:#000
    style OAP fill:#ef9a9a,stroke:#c62828,color:#000
    style MPE fill:#c8e6c9,stroke:#2e7d32,color:#000
    style ExtUser fill:#ffcdd2,stroke:#b71c1c,color:#000
    style IntUser fill:#c8e6c9,stroke:#2e7d32,color:#000
    style Fabric fill:#90caf9,stroke:#0d47a1,color:#000
    style Corp fill:#a5d6a7,stroke:#2e7d32,color:#000
    style Ext fill:#ef9a9a,stroke:#c62828,color:#000
```

## Data Security

### Encryption

| Type | Mechanism | Detail |
|------|-----------|--------|
| **In transit** | TLS 1.2 / 1.3 | All client-to-Fabric and inter-experience traffic |
| **At rest** | Microsoft-managed keys (default) | Automatic encryption of all data in OneLake |
| **At rest (advanced)** | Customer Managed Keys (CMK) | Second layer of encryption with customer-managed Azure Key Vault keys |
| **Power BI** | BYOK | Bring Your Own Key for Power BI datasets |

### Customer Managed Keys (CMK)

CMK allows organizations to add an **additional encryption layer** with keys they manage themselves in Azure Key Vault.

**Status (as of April 2026):**

| Item Type | Status |
|-----------|--------|
| Lakehouse, Spark Job, Environment, Pipeline, Dataflow, API for GraphQL, ML Model/Experiment | **GA** (since Oct 2025) |
| Data Warehouse | **GA** (since Oct 2025) |
| Databases, Mirrored Experiences, Power BI | Planned (roadmap) |

## Data Residency and Multi-Geo

Microsoft Fabric supports **multi-geo** deployment with capacities spread across **54 data centers** worldwide.

**Characteristics:**
- Workspaces in different regions are still part of the same OneLake data lake
- The query execution layer, caches, and data remain in the Azure geography where they were created
- Some metadata and processing is stored at rest in the tenant's home geography
- **Data Residency compliant** by default

## DNS Configuration for Private Link

Proper DNS resolution is critical for Private Link deployments. Without correct DNS, clients resolve Fabric FQDNs to public IPs and bypass Private Endpoints entirely.

### Required Private DNS Zones

| DNS Zone | Used By |
|----------|---------|
| `privatelink.analysis.windows.net` | Power BI / Semantic Models |
| `privatelink.pbidedicated.windows.net` | Dedicated capacity endpoints |
| `privatelink.prod.powerapps.com` | Dataflows |
| `privatelink.blob.core.windows.net` | OneLake (ADLS Gen2 storage) |
| `privatelink.dfs.core.windows.net` | OneLake (DFS endpoint) |
| `privatelink.servicebus.windows.net` | Event Hubs / Eventstream |
| `privatelink.web.core.windows.net` | Fabric portal static content |

### DNS Architecture Patterns

| Pattern | Description | Best For |
|---------|-------------|----------|
| **Centralized Private DNS Zone** | Single zone linked to all VNets (hub-spoke topology). Managed in the hub subscription. | Multi-VNet environments with centralized IT |
| **Azure DNS Private Resolver** | Enables on-premises DNS servers to resolve Azure Private DNS Zones via conditional forwarding (forwarders pointing to 168.63.129.16 through the resolver's inbound endpoint). | Hybrid environments with on-premises DNS |
| **Conditional forwarders** | On-premises DNS forwards specific zones (e.g., `*.analysis.windows.net`) to Azure DNS. Requires VPN/ER connectivity. | Simple hybrid setups |

### IP Address Planning

When deploying multiple Private Endpoints (tenant-level + workspace-level), plan subnet sizing carefully:

- Each Private Endpoint consumes **one private IP** from the subnet
- Workspace-level Private Link requires **one PE per workspace** per VNet
- Reserve at least a `/27` (32 IPs) subnet for Fabric Private Endpoints to allow growth
- Use separate subnets for Fabric PEs and other Azure service PEs for clear NSG rule application

> **Common pitfall:** Forgetting to create or link Private DNS Zones is the most frequent cause of Private Link connectivity failures. Always verify with `nslookup` or `Resolve-DnsName` that Fabric FQDNs resolve to `10.x.x.x` (private IPs) rather than public IPs from the client's network.

## Monitoring, Logging and Auditing

Network security controls are only effective if monitored. Fabric integrates with Azure's monitoring ecosystem to provide visibility into access patterns, threats and configuration drift.

### Diagnostic Logging

| Log Source | Destination | Key Signals |
|------------|------------|-------------|
| **Microsoft Entra ID Sign-in Logs** | Log Analytics | Failed/successful sign-ins, MFA challenges, Conditional Access policy hits, risky sign-ins |
| **Fabric Admin Audit Logs** | Log Analytics / Event Hub | Workspace creation, sharing changes, data exports, gateway operations |
| **Azure Private Link Metrics** | Azure Monitor | Bytes in/out through Private Endpoints, connection counts, NAT port utilization |
| **NSG Flow Logs** | Storage Account / Traffic Analytics | Source/dest IPs, ports, protocols, allow/deny decisions on PE subnets |
| **Azure Firewall Logs** | Log Analytics | Application/network rule hits, threat intelligence matches, DNS queries |

### Azure Monitor Integration

- Create **alerts** on Fabric capacity metrics (CU utilization, throttling events) and network metrics (PE connection failures, dropped packets)
- Use **Workbooks** to visualize Private Endpoint traffic patterns, top source IPs and blocked connections
- Set up **diagnostic settings** on Private Link Scopes and NSGs to stream logs to a central Log Analytics workspace

### Microsoft Sentinel Integration

For security-focused organizations, integrate Fabric signals with **Microsoft Sentinel**:

- **Data connectors:** Ingest Entra ID sign-in/audit logs, Fabric admin audit logs, and NSG flow logs into Sentinel
- **Analytics rules:** Detect anomalies such as logins from unexpected geolocations, sudden data export spikes, bulk permission changes, or sign-ins bypassing Conditional Access
- **Automated response:** Use Sentinel playbooks (Logic Apps) to respond to alerts — e.g., disable a compromised service principal, notify the SOC, or quarantine a workspace
- **Hunting queries:** Proactively search for lateral movement between workspaces, unusual API call patterns or data exfiltration indicators

### Audit Best Practices

- Review IP Firewall and Outbound Access Policy rules **quarterly** to remove stale entries
- Monitor Entra Conditional Access policy evaluation logs for unexpected "Not Applied" results
- Track Private Endpoint approval/rejection events on target Azure resources
- Validate that DNS resolution returns private IPs periodically (regression detection)

## Testing and Validation

After deploying network security controls, validate that they work as intended and do not introduce unacceptable latency or block legitimate traffic.

### Connectivity Validation

| Test | Tool | Expected Result |
|------|------|----------------|
| DNS resolution for Private Endpoint | `nslookup <workspace>.fabric.microsoft.com` or `Resolve-DnsName` | Returns private IP (10.x.x.x) |
| Fabric portal access via PE | Browser from within VNet or VPN-connected client | Portal loads; no public IP fallback |
| IP Firewall block test | Access from an IP not in the allow list | HTTP 403 Forbidden |
| Managed PE to Azure SQL | Run a notebook query from Fabric against a firewall-enabled SQL DB | Query succeeds; SQL audit log shows private IP source |
| Outbound policy block test | Attempt to connect to a non-allowed destination from a notebook | Connection refused / timed out |

### Performance Validation

- **Baseline first:** Measure query and pipeline performance **before** enabling Private Link or Managed VNets to establish a reference point
- **Spark startup time:** Custom pools in a Managed VNet take 3–5 minutes to start (vs. seconds for Starter Pools). Factor this into SLAs and user expectations
- **Private Endpoint throughput:** Monitor PE metrics for saturation. A single PE supports up to 8 Gbps; for high-throughput scenarios, verify that bandwidth is not a bottleneck
- **Cross-region latency:** When capacities and Private Endpoints are in different regions (multi-geo), measure added latency and consider co-locating PEs with capacities

### Periodic Reviews

| Review | Frequency | Responsible |
|--------|-----------|-------------|
| IP Firewall rules accuracy | Monthly | Workspace admin |
| Outbound policy allowed destinations | Quarterly | Security team |
| Private Endpoint approvals on target resources | Quarterly | Azure subscription owner |
| Conditional Access policy effectiveness | Quarterly | Identity team |
| DNS zone records and VNet links | Semi-annually | Network team |
| Penetration testing (Fabric-adjacent infrastructure) | Annually | Security team |

## Compliance and Certifications

Microsoft Fabric supports a wide range of compliance standards:

| Certification | Date |
|--------------|------|
| **ISO 27001, 27701, 27017, 27018** | December 2023 |
| **HIPAA** | January 2024 |
| **Australian IRAP** | February 2024 |
| **SOC 1 & 2 Type 2, SOX, CSA STAR** | May 2024 |
| **HITRUST** | September 2024 |
| **FedRAMP** (Azure Commercial) | November 2024 |
| **PCI DSS** | January 2025 |
| **K-ISMS** | May 2025 |
| **GDPR, EUDB** | Supported |

Fabric is a core **Microsoft Online Service**.

## Decision Guide

```mermaid
flowchart TD
    Start["What is your\nnetwork security need?"] --> Q1{"Protect inbound\naccess to Fabric?"}

    Q1 -->|Yes| Q2{"What level\nof protection?"}
    Q1 -->|No| Q3{"Connect Fabric\nto protected sources?"}

    Q2 -->|"Entire tenant"| Q2a{"VNet infrastructure\navailable?"}
    Q2 -->|"Specific workspaces"| Q2b{"Type of\nrestriction?"}
    Q2 -->|"Identity only\n(Zero Trust)"| CA["Entra\nConditional Access"]

    Q2a -->|Yes| TLPL["Private Link\nTenant"]
    Q2a -->|No| CA

    Q2b -->|"Private network\n(VNet)"| WSPL["Private Link\nWorkspace"]
    Q2b -->|"Public IP\nranges"| IPFW["Workspace\nIP Firewall"]

    Q3 -->|Yes| Q4{"Source type?"}
    Q3 -->|No| Q5{"Prevent\nexfiltration?"}

    Q4 -->|"ADLS Gen2\n(firewall)"| TWA["Trusted\nWorkspace Access"]
    Q4 -->|"Azure SQL, Cosmos DB\netc. (private)"| MPE["Managed\nPrivate Endpoints"]
    Q4 -->|"Azure services\nin a VNet"| VGW["VNet\nData Gateway"]
    Q4 -->|"On-Premises"| OGW["On-Premises\nGateway"]

    Q5 -->|Yes| DEP["Outbound Access\nPolicies + Inbound\n= Full DEP"]
    Q5 -->|No| Done["Default configuration\nis sufficient"]

    style Start fill:#e3f2fd,stroke:#0d47a1,color:#000
    style Q1 fill:#fff9c4,stroke:#f9a825,color:#000
    style Q2 fill:#fff9c4,stroke:#f9a825,color:#000
    style Q2a fill:#fff9c4,stroke:#f9a825,color:#000
    style Q2b fill:#fff9c4,stroke:#f9a825,color:#000
    style Q3 fill:#fff9c4,stroke:#f9a825,color:#000
    style Q4 fill:#fff9c4,stroke:#f9a825,color:#000
    style Q5 fill:#fff9c4,stroke:#f9a825,color:#000
    style CA fill:#d1c4e9,stroke:#4527a0,color:#000
    style TLPL fill:#c5cae9,stroke:#1a237e,color:#000
    style WSPL fill:#c5cae9,stroke:#1a237e,color:#000
    style IPFW fill:#c5cae9,stroke:#1a237e,color:#000
    style TWA fill:#c8e6c9,stroke:#2e7d32,color:#000
    style MPE fill:#c8e6c9,stroke:#2e7d32,color:#000
    style VGW fill:#c8e6c9,stroke:#2e7d32,color:#000
    style OGW fill:#c8e6c9,stroke:#2e7d32,color:#000
    style DEP fill:#ef9a9a,stroke:#c62828,color:#000
    style Done fill:#e0e0e0,stroke:#616161,color:#000
```

## Feature Summary and Status

*Updated as of April 2026*

| Feature | Level | Direction | Status | Primary Use Case |
|---------|-------|-----------|--------|-----------------|
| **Entra Conditional Access** | Tenant | Inbound | **GA** | Zero Trust, MFA, IP filtering |
| **Private Link Tenant** | Tenant | Inbound | **GA** | Full tenant network isolation |
| **Private Link Workspace** | Workspace | Inbound | **GA** | Granular per-workspace network isolation |
| **Workspace IP Firewall** | Workspace | Inbound | **GA** | IP-based restriction without VNet infrastructure |
| **Trusted Workspace Access** | Workspace | Outbound | **GA** | Firewall-enabled ADLS Gen2 access |
| **Managed Private Endpoints** | Workspace | Outbound | **GA** | Private connection to Azure sources |
| **Managed VNets** | Workspace | Outbound | **GA** | Spark isolation + MPE support |
| **VNet Data Gateway** | Org | Outbound | **GA** | Managed connection to Azure services in VNet; enterprise proxy & cert auth support |
| **On-Premises Gateway** | Org | Outbound | **GA** | Connection to on-premises sources |
| **Service Tags** | NSG/Firewall | Both | **GA** | Azure network rules |
| **Outbound Access Policies** | Workspace | Outbound | **GA** | Data exfiltration prevention |
| **Customer Managed Keys** | Workspace | Data | **GA** | Dual-layer encryption |
| **Eventstream Private Network** | Workspace | Outbound | **Preview** | Secure real-time ingestion from private networks |
| **Power BI Network Isolation** | Workspace | Inbound | **Planned** | WS-level Private Link and IP Firewall for Power BI items |
| **Fabric Databases Network Isolation** | Workspace | Inbound | **Planned** | WS-level Private Link and IP Firewall for Fabric databases |

## References

- [Security overview - Microsoft Fabric](https://learn.microsoft.com/en-us/fabric/security/security-overview)
- [Private Links overview](https://learn.microsoft.com/en-us/fabric/security/security-private-links-overview)
- [Workspace-level Private Links](https://learn.microsoft.com/en-us/fabric/security/security-workspace-level-private-links-overview)
- [Managed VNets overview](https://learn.microsoft.com/en-us/fabric/security/security-managed-vnets-fabric-overview)
- [Managed Private Endpoints](https://learn.microsoft.com/en-us/fabric/security/security-managed-private-endpoints-overview)
- [Trusted Workspace Access](https://learn.microsoft.com/en-us/fabric/security/security-trusted-workspace-access)
- [Protect Inbound Traffic](https://learn.microsoft.com/en-us/fabric/security/protect-inbound-traffic)
- [Conditional Access in Fabric](https://learn.microsoft.com/en-us/fabric/security/security-conditional-access)
- [IP Firewall Rules in Fabric](https://learn.microsoft.com/en-us/fabric/security/security-ip-firewall-rules)
- [Service Tags](https://learn.microsoft.com/en-us/fabric/security/security-service-tags)
- [Information Protection in Fabric](https://learn.microsoft.com/en-us/fabric/governance/information-protection)
- [Data Loss Prevention in Fabric](https://learn.microsoft.com/en-us/fabric/governance/data-loss-prevention-overview)
- [Azure Private DNS Zones](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns)
- [Microsoft Sentinel — Entra ID connector](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/microsoft-entra-id)
- [Fabric Security Whitepaper](https://aka.ms/FabricSecurityWhitepaper)
- *End-to-end network security in Microsoft Fabric* -- Arthi Ramasubramanian Iyer & Rick Xu, FabCon 2025
