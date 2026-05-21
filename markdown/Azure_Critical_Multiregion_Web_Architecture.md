---
title: "Architecture Azure — Site Web Critique Multi-Régions"
subtitle: "Front Door, APIM, Backend, Data — Failover & Résilience Edge"
date: "2026"
---

> **Guide d'architecture** pour un site web Azure **critique**, distribué sur **plusieurs régions** (paired ou non-paired), avec séparation **Front / API / Back**, base de données distribuée, et résilience **edge** au-delà de Front Door.
>
> Public visé : architectes cloud, platform engineers, SRE, équipes responsables de SLA 99,99 %+.

---

## Objectifs & contraintes

Un site web **critique** se caractérise par :

| Dimension | Cible typique |
|---|---|
| Disponibilité | SLA composite **99,99 %+** end-to-end |
| RTO | < 5 minutes en cas de panne régionale |
| RPO | < 1 minute (idéalement 0 pour les écritures critiques) |
| Latence utilisateur | < 200 ms p95 perçue |
| Surface d'exposition | **aucune** IP publique sur les backends |
| Conformité | ISO 27001 / SOC 2 / RGPD / éventuellement PCI-DSS |
| Audit & traçabilité | Logs centralisés, immuables, ≥ 1 an |

Trois axes d'architecture en découlent :

1. **Topologie multi-régions** (au moins deux, parfois trois plaques)
2. **Couche edge résiliente** (au-delà du seul Front Door)
3. **Données distribuées** avec un modèle de cohérence assumé

> Le **maillon faible compte plus que le maillon fort** : il ne sert à rien de mettre du Premium partout sauf à l'entrée.

---

## Architecture de référence — vue à 8 couches

### Vue d'ensemble

```mermaid
flowchart TB
    L1["<b>1. Edge & routage global</b><br/>DNS · Front Door · WAF"]
    L2["<b>2. Topologie multi-régions</b><br/>Stamps · Availability Zones · Hub-Spoke"]
    L3["<b>3. Compute</b><br/>App Service · AKS · Container Apps"]
    L4["<b>4. Données</b><br/>Cosmos · HorizonDB · SQL · Redis · Storage"]
    L5["<b>5. Sécurité & identité</b><br/>Entra ID · Managed Identity · Key Vault · Private Endpoints"]
    L6["<b>6. Observabilité</b><br/>Monitor · App Insights · Sentinel"]
    L7["<b>7. DevOps & résilience</b><br/>IaC · Deployment Rings · Chaos Studio"]
    L8["<b>8. Gouvernance</b><br/>Policy · Management Groups · Cost · RBAC"]
    L1 --- L2 --- L3 --- L4 --- L5 --- L6 --- L7 --- L8

    classDef edge fill:#1e88e5,stroke:#0d47a1,color:#fff
    classDef compute fill:#43a047,stroke:#1b5e20,color:#fff
    classDef data fill:#fb8c00,stroke:#e65100,color:#fff
    classDef cross fill:#8e24aa,stroke:#4a148c,color:#fff
    classDef ops fill:#546e7a,stroke:#263238,color:#fff
    class L1,L2 edge
    class L3 compute
    class L4 data
    class L5,L6 cross
    class L7,L8 ops
```

### Détail par couche

#### Edge & routage global

- **Azure Front Door Premium** (anycast global, WAF managé, TLS 1.3, cache CDN)
- Routage **latency-based** + **priority failover** entre régions
- **Health probes** agressifs (10–30 s) sur endpoint `/health`
- **Azure DNS** + (optionnel) **Traffic Manager** en secours DNS
- **WAF** : règles OWASP managées + bot protection + rate limiting
- **DDoS Protection Standard** sur les VNets exposés

#### Topologie multi-régions

- **Pattern Active/Active** ou **Active/Passive** selon coût et besoin de write multi-région
- 2 à 3 régions (paired ou non-paired — voir section dédiée)
- **Availability Zones** dans chaque région (3 zones minimum)
- Pattern **deployment stamps** : chaque région est un stamp indépendant et autonome

#### Compute

- **Azure Container Apps** ou **AKS** (multi-zone, autoscale KEDA) pour microservices
- **App Service Premium v3** si stack PaaS classique (slots, zone-redundant)
- **Min 3 instances par zone**, autoscale CPU + custom metrics (queue depth, RPS)

#### Données

| Service | Usage |
|---|---|
| **Cosmos DB** | Catalogue, sessions, données multi-write global |
| **Azure SQL Hyperscale** | OLTP transactionnel ACID |
| **Azure HorizonDB** | PostgreSQL distribué, storage disaggregé (voir section dédiée) |
| **Redis Enterprise Active-Active** | Cache distribué, sessions, compteurs |
| **Storage GZRS / RA-GZRS** | Blobs, fichiers, exports |
| **Service Bus Premium** + **Event Hubs** | Messagerie async, eventing |

#### Sécurité & identité

- **Entra ID** + **Managed Identities** partout (zéro secret en clair)
- **Key Vault Premium** + HSM + Private Endpoints + réplication régionale
- **Private Endpoints** sur tous les PaaS — **pas d'IP publique** sauf Front Door
- **Hub-and-spoke VNet** avec Azure Firewall Premium + NSG + ASG
- **Defender for Cloud** (CSPM + workload protection)
- Rotation auto des secrets, scan SAST/DAST en CI

#### Observabilité

- **Application Insights** + **Log Analytics** (workspace régional + central)
- **Azure Monitor** : alertes multi-dimensionnelles, action groups
- **Distributed tracing** OpenTelemetry, W3C trace-context
- **SLO/SLI** par service, error budget tracking
- **Synthetic monitoring** depuis plusieurs régions externes

#### DevOps & résilience

- **IaC** : Bicep ou Terraform, **un seul code** pour tous les stamps
- **CI/CD** : GitHub Actions / Azure DevOps avec deployment rings (canary → 1 région → all)
- **Blue/Green** ou slot swap par région
- **Chaos Engineering** : Azure Chaos Studio (test failover régional mensuel)
- **Backups** geo-redundants, restore testé trimestriellement
- **Runbooks** automatisés (Azure Automation / Logic Apps)

#### Gouvernance

- **Management Groups** + **Azure Policy** (deny non-compliant, audit)
- **Landing Zones** (ALZ Microsoft) si plusieurs équipes
- **Cost Management** : budgets + alertes, tags obligatoires
- **Defender + Sentinel** pour SIEM/SOAR

---

## Le rôle d'APIM (et où ne pas le mettre)

### Pourquoi APIM dans une archi critique

| Fonction | Apport |
|---|---|
| Façade unifiée | Une seule surface d'API pour tous les backends |
| Sécurité | OAuth2/JWT validation, mTLS, IP filtering, subscription keys |
| Gouvernance | Versioning, deprecation, contrats OpenAPI, developer portal |
| Politiques | Rate limiting, quotas, throttling, transformation |
| Observabilité | Logs détaillés par API/produit/consommateur |
| Monétisation | Produits, plans, abonnements partenaires |
| Caching | Réponses cachées (réduction charge backend) |

### Choix de SKU & topologie

**APIM Premium** (obligatoire pour le critique) :

- **Multi-région** (gateway répliqué dans chaque plaque, sync auto)
- **Zone-redundant** dans chaque région
- **VNet injection** (mode Internal ou External+VNet)
- **SLA 99,99 %**

### APIM **n'est pas** un CDN pour le contenu statique

| Type de trafic | Caractéristiques | Outil adapté |
|---|---|---|
| HTML / JS / CSS / images | Statique, cacheable agressif | **Front Door + CDN** |
| Appels API (JSON/XML) | Auth, rate limit, contrats, versioning | **APIM** |

Mettre APIM **devant le front statique** apporterait :

- Latence inutile (~10–50 ms par hop)
- Coût (APIM facturé à la gateway unit, pas fait pour servir du statique massif)
- Aucun bénéfice fonctionnel (un `.js` n'a pas besoin de JWT validation)
- Cache moins efficace que le CDN Front Door (POPs partout dans le monde)

### Le bon pattern : deux chemins parallèles sous Front Door

```mermaid
flowchart TB
    U["👤 Utilisateurs"]
    FD["🛡️ <b>Front Door + WAF</b><br/>(entrée unique Internet)"]
    SWA["📄 <b>Frontend</b><br/>Static Web App / App Service<br/>HTML · JS · CSS"]
    APIM["🚪 <b>APIM Premium</b><br/>JWT / OAuth2 · Rate limit<br/>Cache · Transform"]
    BE["⚙️ <b>Backend</b><br/>AKS / Container Apps"]
    U --> FD
    FD -- "Host: app.xxx.com<br/>(statique, SPA)" --> SWA
    FD -- "Host: api.xxx.com<br/>(API JSON)" --> APIM
    APIM -- "Private Endpoint" --> BE

    classDef edge fill:#1e88e5,stroke:#0d47a1,color:#fff
    classDef front fill:#43a047,stroke:#1b5e20,color:#fff
    classDef api fill:#fb8c00,stroke:#e65100,color:#fff
    classDef back fill:#8e24aa,stroke:#4a148c,color:#fff
    class FD edge
    class SWA front
    class APIM api
    class BE back
```

Côté Front Door, deux origin groups :

- **Route 1** `app.contoso.com/*` → Static Web App / App Service (caching aggressive, WAF "browser")
- **Route 2** `api.contoso.com/*` → APIM (caching off, WAF "API" anti-injection)

### Policies APIM clés

```xml
<policies>
  <inbound>
    <cors allow-credentials="true">...</cors>
    <validate-jwt header-name="Authorization" require-scheme="Bearer">
      <openid-config url="https://login.microsoftonline.com/{tenant}/v2.0/.well-known/openid-configuration"/>
    </validate-jwt>
    <rate-limit-by-key calls="100" renewal-period="60"
                       counter-key="@(context.Subscription.Id)"/>
    <quota-by-key calls="1000000" renewal-period="2592000"
                   counter-key="@(context.Subscription.Id)"/>
    <cache-lookup vary-by-developer="false"/>
    <set-header name="x-correlation-id" exists-action="skip">
      <value>@(Guid.NewGuid().ToString())</value>
    </set-header>
  </inbound>
  <backend>
    <forward-request timeout="30"/>
  </backend>
  <outbound>
    <cache-store duration="60"/>
    <set-header name="x-powered-by" exists-action="delete"/>
  </outbound>
</policies>
```

### Pièges APIM à éviter

- APIM Developer/Basic en prod → pas de SLA suffisant, pas de VNet
- Single region APIM → SPOF malgré Front Door
- Policies trop lourdes → latence ajoutée (> 50 ms par appel)
- Secrets en clair dans les policies → toujours via **Named Values** liés à Key Vault
- Oublier la résolution DNS privée → APIM doit résoudre les backends en Private Endpoint

---

## Séparation Front / API / Back

### Tiers et responsabilités

| Front Door (Edge) | Frontend SWA (Présentation) | APIM (Contrat API) | Backend (Implémentation) |
|---|---|---|---|
| TLS termination | Sert HTML / JS / CSS | Valide JWT | Logique métier |
| WAF global | SPA routing | Rate limit | Accès DB |
| DDoS L3-L7 | Auth redirect OIDC | Quotas | Events |
| CDN cache | CSP headers | Transformation | Transactions |
| Geo-routing | — | Cache API | — |
| Health probes | — | Versioning | — |

### Flux d'authentification (OAuth2 PKCE)

Le SPA fait un **redirect OIDC vers Entra ID** (PKCE, pas de secret côté client), récupère un access token, et l'envoie sur les appels API :

```mermaid
sequenceDiagram
    autonumber
    participant B as 🌐 Browser (SPA)
    participant E as 🔐 Entra ID
    participant A as 🚪 APIM
    participant K as ⚙️ Backend
    B->>E: Redirect login (PKCE, sans secret)
    E-->>B: access_token (JWT)
    B->>A: GET /api/* + Bearer token
    A->>A: Validate JWT (signature, audience, scopes)
    A->>A: Rate limit / Quota
    A->>K: Forward (Private Endpoint)
    K-->>A: Response
    A-->>B: Response (cache possible)
```

### Schéma complet 4-tiers avec data layer

```mermaid
flowchart TB
    U["👤 Utilisateurs / B2B"]
    FD["🛡️ <b>Azure Front Door Premium</b><br/>WAF · DDoS · CDN"]

    subgraph R1["🌍 RÉGION 1"]
        direction TB
        FE1["<b>TIER 1 — Frontend</b><br/>Static Web App / App Service"]
        APIM1["<b>TIER 2 — APIM Premium</b><br/>JWT · Rate limit · Cache"]
        BE1["<b>TIER 3 — Backend</b><br/>AKS / Container Apps"]
        DATA1["<b>TIER 4 — Data</b><br/>HorizonDB · Cosmos · Redis · Storage · SB"]
        FE1 --> APIM1
        APIM1 -- PE --> BE1
        BE1 -- PE --> DATA1
    end

    subgraph R2["🌍 RÉGION 2"]
        direction TB
        FE2["<b>TIER 1 — Frontend</b><br/>Static Web App / App Service"]
        APIM2["<b>TIER 2 — APIM Premium</b><br/>(multi-region sync)"]
        BE2["<b>TIER 3 — Backend</b><br/>AKS / Container Apps"]
        DATA2["<b>TIER 4 — Data</b><br/>(geo-replication)"]
        FE2 --> APIM2
        APIM2 -- PE --> BE2
        BE2 -- PE --> DATA2
    end

    U --> FD
    FD --> FE1
    FD --> FE2
    APIM1 <-. "multi-region sync" .-> APIM2
    DATA1 <-. "geo-replication" .-> DATA2

    classDef edge fill:#1e88e5,stroke:#0d47a1,color:#fff
    classDef front fill:#43a047,stroke:#1b5e20,color:#fff
    classDef api fill:#fb8c00,stroke:#e65100,color:#fff
    classDef back fill:#8e24aa,stroke:#4a148c,color:#fff
    classDef data fill:#d81b60,stroke:#880e4f,color:#fff
    class FD edge
    class FE1,FE2 front
    class APIM1,APIM2 api
    class BE1,BE2 back
    class DATA1,DATA2 data
```

---

## Couche données : Azure HorizonDB et alternatives

### Qu'est-ce que HorizonDB

**Azure HorizonDB** est le service **PostgreSQL distribué cloud-native** de Microsoft, positionné face à Aurora / AlloyDB / Spanner. Architecture **storage-compute disaggregée**, scaling horizontal, compatible PostgreSQL.

### Quand HorizonDB est un excellent choix

| Critère | HorizonDB |
|---|---|
| Compatibilité PostgreSQL (extensions, drivers, ORM) | Natif |
| Scaling read massif | Replicas multiples low-latency |
| Storage élastique (pas de pré-provisioning) | Oui |
| Workloads OLTP transactionnels classiques | Oui |
| Backups continus, PITR | Oui |
| Couplage Entra ID / Managed Identity | Oui |

### Points de vigilance pour du critique multi-région

1. **Statut GA** : vérifier la disponibilité GA dans **les régions cibles** et le SLA contractuel
2. **Multi-région active/active** : HorizonDB privilégie **multi-zone + read replicas cross-region**. Le multi-write géo-distribué n'est pas son point fort — pour du write actif partout, **Cosmos DB** reste plus mature.
3. **Failover régional** : modes supportés (auto-failover groups ?) à valider pour un RTO < 5 min
4. **Écosystème outils** : monitoring, backup tiers, migration tooling encore en construction
5. **Coût** : modèle storage + compute séparés, à modéliser selon profil de charge

### Choix de datastore selon le profil

| Profil | DB recommandée |
|---|---|
| Lecture-intensive, écriture régionale, stack PostgreSQL | **HorizonDB** (read replicas cross-région) |
| Multi-write global, faible latence partout, schéma souple | **Cosmos DB** (multi-master) |
| OLTP fort, transactions ACID, stack SQL Server | **Azure SQL Hyperscale** + auto-failover groups |
| Analytique temps réel + transactionnel | **Fabric / Cosmos DB + Synapse Link** |

### Pattern hybride pragmatique

- **HorizonDB** pour le transactionnel principal (PostgreSQL)
- **Cosmos DB** pour catalogue / sessions / données multi-region active-active
- **Redis Enterprise A/A** pour cache distribué global, compteurs, sessions
- **Storage RA-GZRS** pour blobs et fichiers
- **Service Bus Premium** + **Event Hubs Geo-DR** pour la messagerie

> Pour du critique, prévoir un **POC HorizonDB dédié** : test failover régional réel + injection de panne + benchmark de charge **avant** engagement architectural.

---

## Multi-région non-pairée — failover et lectures multi-régions

### Pourquoi choisir des régions non-pairées

Exemple : **West Europe** (primaire) + **Sweden Central** (secondaire) — non pairées.

Motivations :

- **Conformité / résidence des données** (contraintes pays)
- **Latence utilisateurs** mieux distribuée
- **Diversité de risque** (ne pas dépendre du même cluster physique pairé)

### Conséquences à connaître

| Impact | Détail | Mitigation |
|---|---|---|
| Pas de mises à jour Azure séquentielles | Risque théorique de patch simultané | Tests réguliers, fenêtres de maintenance |
| Pas de GRS automatique sur Storage | GRS/RA-GRS impose la région pairée | **GZRS local + Object Replication custom** |
| Geo-replication SQL/Cosmos OK | Configurables vers n'importe quelle région | OK |
| Recovery prioritaire | Pas de garantie d'ordre de récupération Azure | Plan B documenté, runbooks testés |
| Latence inter-région plus élevée | À mesurer (typ. +5 à +15 ms) | Async replication, RPO > 0 assumé |

### Schéma Active/Passive (write) + Multi-Read

```mermaid
flowchart TB
    U["👤 Utilisateurs / B2B"]

    subgraph FDS["🛡️ AZURE FRONT DOOR PREMIUM + WAF + DDoS"]
        direction LR
        OG1["<b>Origin group 'frontend'</b><br/>P1 = WE active<br/>P2 = SE standby<br/>Probes /health 15s"]
        OG2["<b>Origin group 'api'</b><br/>P1 = WE APIM active<br/>P2 = SE APIM standby<br/>Probes /health 15s"]
    end

    subgraph WE["🌍 PRIMAIRE — WEST EUROPE (active write + read)"]
        direction TB
        FE_WE["<b>TIER 1</b> — Frontend (multi-AZ)"]
        APIM_WE["<b>TIER 2</b> — APIM Premium (multi-AZ)"]
        BE_WE["<b>TIER 3</b> — Backend AKS/ACA<br/>WRITES + READS"]
        subgraph D_WE["<b>TIER 4 — DATA</b>"]
            direction TB
            HZ_WE["HorizonDB / SQL HS<br/><b>PRIMARY R/W</b>"]
            CX_WE["Cosmos DB<br/>(write region)"]
            RD_WE["Redis Enterprise A/A"]
            ST_WE["Storage GZRS<br/>+ Object Replication"]
            SB_WE["Service Bus Premium<br/>+ Geo-DR alias"]
            KV_WE["Key Vault Premium HSM"]
        end
        FE_WE --> APIM_WE
        APIM_WE -- PE --> BE_WE
        BE_WE -- PE --> D_WE
    end

    subgraph SE["🌍 SECONDAIRE — SWEDEN CENTRAL (read + standby)"]
        direction TB
        FE_SE["<b>TIER 1</b> — Frontend (multi-AZ)"]
        APIM_SE["<b>TIER 2</b> — APIM gateway secondaire"]
        BE_SE["<b>TIER 3</b> — Backend AKS/ACA<br/>READS only (avant promotion)"]
        subgraph D_SE["<b>TIER 4 — DATA</b>"]
            direction TB
            HZ_SE["HorizonDB read replica<br/>(promotable)"]
            CX_SE["Cosmos DB read region"]
            RD_SE["Redis Enterprise A/A<br/>(CRDT convergence)"]
            ST_SE["Storage GZRS destination"]
            SB_SE["Service Bus secondary"]
            KV_SE["Key Vault Premium<br/>(read mirror)"]
        end
        FE_SE --> APIM_SE
        APIM_SE -- PE --> BE_SE
        BE_SE -- PE --> D_SE
    end

    U --> FDS
    OG1 ==>|active| FE_WE
    OG1 -.->|standby| FE_SE
    OG2 ==>|active| APIM_WE
    OG2 -.->|standby| APIM_SE
    APIM_WE <-. "multi-region sync" .-> APIM_SE
    HZ_WE -. "async replication" .-> HZ_SE
    CX_WE -. "geo-replication" .-> CX_SE
    RD_WE <-. "CRDT bidirectionnel" .-> RD_SE
    ST_WE -. "Object Replication" .-> ST_SE
    SB_WE -. "Geo-DR pairing" .-> SB_SE
    KV_WE <-. "mirror auto" .-> KV_SE

    classDef edge fill:#1e88e5,stroke:#0d47a1,color:#fff
    classDef active fill:#43a047,stroke:#1b5e20,color:#fff
    classDef standby fill:#fb8c00,stroke:#e65100,color:#fff
    class FDS,OG1,OG2 edge
    class FE_WE,APIM_WE,BE_WE,HZ_WE,CX_WE,RD_WE,ST_WE,SB_WE,KV_WE active
    class FE_SE,APIM_SE,BE_SE,HZ_SE,CX_SE,RD_SE,ST_SE,SB_SE,KV_SE standby
```

### Modes de fonctionnement

#### Mode nominal

- Front Door route 100 % vers la région primaire (priority 1, health OK)
- Écritures vers la région primaire uniquement
- Lectures critiques sur la primary DB
- Lectures non-critiques routées **localement** (Cosmos / Redis / read replica HorizonDB)
- Redis Active-Active : R/W local des deux côtés (CRDT, convergence)
- Réplication continue primaire → secondaire (RPO ~ secondes pour Redis/Cosmos, ~ minutes pour SQL)

#### Mode failover

```mermaid
sequenceDiagram
    autonumber
    participant FD as 🛡️ Front Door
    participant WE as 🌍 Région WE (down)
    participant SE as 🌍 Région SE
    participant Auto as 🤖 Automation Runbook
    participant Ops as 👥 Équipe Ops
    FD->>WE: Health probe /health
    WE--xFD: timeout (3x consécutifs)
    Note over FD: Détection KO en ≤ 30 s
    FD->>SE: Bascule trafic (priority 2)
    FD->>Auto: Trigger DR runbook
    par Promotion data tier
        Auto->>SE: SQL/HorizonDB → promote replica
    and
        Auto->>SE: Cosmos DB → repoint write region
    and
        Auto->>SE: Service Bus → switch geo-DR alias
    and
        Auto->>SE: Storage → toggle feature flag
    end
    Auto->>SE: Backend → R/W mode (App Configuration)
    Auto->>Ops: Notification Action Group
    Ops->>SE: Validation humaine
```

**RTO cible** : 5–10 min · **RPO** : 0–60 s (selon datastore)

#### Failback

```mermaid
sequenceDiagram
    autonumber
    participant SE as 🌍 Région SE (primaire temporaire)
    participant WE as 🌍 Région WE (rétablie)
    participant Ops as 👥 Équipe Ops
    participant FD as 🛡️ Front Door
    WE-->>Ops: Région rétablie
    SE->>WE: Re-synchronisation (reverse replication)
    Ops->>Ops: Validation cohérence (checksum)
    Note over Ops: Attente fenêtre planifiée hors heures de pointe
    Ops->>FD: Bascule priority 1 → WE
    FD->>WE: Trafic R/W vers WE
    SE->>SE: Redevient standby R/O
```

### Tableau des datastores multi-read

| Datastore | Multi-read | Multi-write | Promotion DR |
|---|---|---|---|
| HorizonDB / Azure SQL HS | Replica async | Non (1 primary) | Auto-failover-group, 30 s – 2 min |
| Cosmos DB | Natif partout | Optionnel (multi-master) | API call ou auto-failover |
| Redis Enterprise A/A | Partout | CRDT (conflict-free) | Aucune promotion |
| Storage GZRS | Lecture locale | Non (1 primary) | Manuel via Object Replication |
| Service Bus Premium | Non (1 primaire) | Non | Alias geo-DR, script |

> Le **Redis Active-Active** est l'allié principal en non-pairé : pas de promotion, pas de RPO, lecture/écriture locale partout. Idéal pour sessions, cache, compteurs, leaderboards.

### Pièges spécifiques au non-pairé

1. **Storage GRS/RA-GRS impossible** → GZRS local + Object Replication asynchrone (RPO ~15 min)
2. **Recovery Services Vault** : vérifier que les régions cibles supportent la réplication
3. **Quotas séparés par région** → réserver capacité (Capacity Reservations) dans les **deux**
4. **Latence inter-région plus élevée** → mesurer en amont, accepter RPO accru
5. **Patch Azure** : risque (faible) de fenêtre commune → demander maintenance différenciée via support
6. **DNS Private Zones** : à lier dans les deux VNets, sinon résolution Private Endpoint casse au failover

---

## Front Door Premium — justification

### Comparatif des SKU Front Door

| Fonctionnalité | Standard | Premium | Décisif pour critique ? |
|---|---|---|---|
| Anycast global, TLS, routing | Oui | Oui | — |
| Caching CDN | Oui | Oui | — |
| WAF managé | Custom rules only | **Managed rules OWASP + bot protection** | Oui |
| DRS (Default Rule Set Microsoft) | Non | Oui | Oui |
| Bot Manager Rule Set | Non | Oui | Oui |
| **Private Link vers les origines** | Non | Oui | **Critique** |
| Microsoft Threat Intelligence | Non | Oui | Oui |
| Rate limiting WAF | Oui | Oui | — |
| Geo-filtering | Oui | Oui | — |
| Custom domains + TLS managé | Oui | Oui | — |
| Security analytics & reports | Limité | Détaillé | Utile |
| SLA | 99,99 % | 99,99 % | — |
| Coût (base) | ~ 35 €/mois | ~ 330 €/mois | Delta |

### Les trois raisons qui justifient Premium

#### Private Link vers les origines (la plus importante)

- En **Standard** : Front Door appelle ton backend via **Internet public** (même si protégé par firewall/IP allowlist)
- En **Premium** : Front Door se connecte aux origines (App Service, APIM, Storage, Load Balancer) via **Private Link** → **aucune IP publique exposée**

```mermaid
flowchart LR
    subgraph STD["⚠️ Standard"]
        direction LR
        FD1["Front Door<br/>Standard"]
        INT["🌐 Internet public"]
        APP1["App Service<br/>IP publique exposée"]
        FD1 --> INT --> APP1
    end

    subgraph PRM["✅ Premium"]
        direction LR
        FD2["Front Door<br/>Premium"]
        PL["🔒 Private Link"]
        APP2["App Service<br/>0 IP publique"]
        FD2 ==> PL ==> APP2
    end

    classDef bad fill:#e53935,stroke:#b71c1c,color:#fff
    classDef good fill:#43a047,stroke:#1b5e20,color:#fff
    class FD1,INT,APP1 bad
    class FD2,PL,APP2 good
```

Sur du critique, exposer une IP publique sortie de backend = non-conforme à la plupart des politiques sécu (CIS, ISO 27001, PCI-DSS).

#### WAF managé OWASP + Bot Protection

- **Standard** : tu écris **toi-même** chaque règle (SQL injection, XSS, etc.)
- **Premium** :
  - **DRS 2.x** : règles OWASP **maintenues par Microsoft**, mises à jour automatiquement face aux nouvelles CVE
  - **Bot Manager Rule Set** : détecte bots malveillants vs bots légitimes
  - **Threat Intelligence** : blocage automatique des IPs/réseaux malveillants (feed MSFT)

#### Conformité & audit

- Rapports de sécurité détaillés (ISO, SOC 2, PCI)
- Visibilité sur attaques bloquées, top règles, géo des attaquants

### Quand Standard suffit

| Contexte | SKU |
|---|---|
| Site vitrine, blog, app non-critique | Standard |
| App SaaS avec sécu modérée | Standard + WAF custom |
| App critique, B2B, données sensibles, conformité | **Premium** |
| Backends qui doivent être **privés** | **Premium** (Private Link) |
| Forte volumétrie d'attaques | **Premium** (bot protection) |

### Coût comparé

- **Standard** : ~ 35 €/mois base + $0.01/GB sortant + WAF requests
- **Premium** : ~ 330 €/mois base + $0.01/GB sortant + WAF requests
- Delta : ~ +295 €/mois (≈ 3 500 €/an)

Un seul incident sécu (data leak, downtime, ransom) coûte **bien plus** que ce delta annuel. Pour la plupart des apps critiques, Premium = sweet spot.

---

## Résilience edge — si Front Door tombe

Front Door a un SLA 99,99 % mais peut tomber (incidents 2022, 2023, 2024). Sur du critique, ta couche edge ne doit pas être un SPOF.

### Stratégie 1 — Dual Edge Azure (recommandée pour la plupart)

Traffic Manager arbitre entre **Front Door** (chemin nominal) et **Application Gateway** régionaux (chemin de secours).

```mermaid
flowchart TB
    U["👤 Utilisateurs"]
    DNS["<b>Azure DNS + Traffic Manager</b><br/>Priority routing · TTL 30-60 s<br/>Probes HTTPS /health"]
    FD["<b>P1 — Front Door Premium</b><br/>(nominal)<br/>WAF · DDoS · CDN"]
    AG_WE["<b>P2 — AppGw v2 + WAF v2</b><br/>West Europe (fallback)<br/>zone-redundant"]
    AG_SE["<b>P3 — AppGw v2 + WAF v2</b><br/>Sweden Central (fallback)<br/>zone-redundant"]
    APIM_WE["APIM + Backend WE"]
    APIM_SE["APIM + Backend SE"]
    U --> DNS
    DNS ==>|"P1 — nominal"| FD
    DNS -.->|"P2 — FD KO"| AG_WE
    DNS -.->|"P3 — FD+WE KO"| AG_SE
    FD ==>|Private Link| APIM_WE
    FD ==>|Private Link| APIM_SE
    AG_WE -->|Private Endpoint| APIM_WE
    AG_SE -->|Private Endpoint| APIM_SE

    classDef dns fill:#1e88e5,stroke:#0d47a1,color:#fff
    classDef primary fill:#43a047,stroke:#1b5e20,color:#fff
    classDef fallback fill:#fb8c00,stroke:#e65100,color:#fff
    classDef back fill:#8e24aa,stroke:#4a148c,color:#fff
    class DNS dns
    class FD primary
    class AG_WE,AG_SE fallback
    class APIM_WE,APIM_SE back
```

#### Mode opératoire

1. Nominal : DNS → CNAME vers Front Door → backends via Private Link
2. Front Door KO : Traffic Manager bascule (~30–60 s health probes) → IP publique AppGw WE
3. Si WE aussi KO : bascule sur AppGw SE
4. Clients résolvent vers le nouvel endpoint après expiration TTL DNS (max 60 s configuré, **2–5 min réel**)

#### Limites

- **TTL DNS** : caches client/proxy plus longs que le TTL configuré
- **Pas de cache CDN** sur le chemin de secours → backends prennent toute la charge
- **WAF dupliqué** : règles à maintenir dans Front Door **et** AppGw (Bicep partagé)
- **IPs publiques exposées** sur AppGw → protégées par WAF + NSG + restrictions IP éventuelles
- Coût : ~ +500 à 800 €/mois pour 2 AppGw v2 WAF v2 zone-redundant

### Stratégie 2 — Multi-CDN (top mais cher)

Traffic Manager arbitre entre **Front Door** et un **CDN tiers** (Akamai, Cloudflare, Fastly).

```mermaid
flowchart TB
    U["👤 Utilisateurs"]
    TM["<b>Traffic Manager</b><br/>(priority routing)"]
    FD["<b>P1 — Front Door Premium</b><br/>(nominal)"]
    CF["<b>P2 — Cloudflare / Akamai</b><br/>WAF + CDN tiers"]
    O["<b>Origines</b><br/>APIM / AppGw / App Service<br/>IP allowlist + mTLS"]
    U --> TM
    TM ==>|nominal| FD
    TM -.->|fallback| CF
    FD ==>|Private Link| O
    CF -->|HTTPS + mTLS| O

    classDef dns fill:#1e88e5,stroke:#0d47a1,color:#fff
    classDef primary fill:#43a047,stroke:#1b5e20,color:#fff
    classDef thirdparty fill:#fb8c00,stroke:#e65100,color:#fff
    classDef back fill:#8e24aa,stroke:#4a148c,color:#fff
    class TM dns
    class FD primary
    class CF thirdparty
    class O back
```

#### Avantages

- Diversité fournisseur (Microsoft + tiers) → résilience à une panne Azure globale
- CDN de secours opérationnel mondialement
- Vrai zéro-SPOF edge

#### Inconvénients

- Complexité opérationnelle (deux WAF, deux configs, deux contrats)
- Coût : Cloudflare/Akamai = +500 à +5 000 €/mois selon volume
- Synchronisation des certificats, des règles WAF, des routes
- Exiger des origines compatibles (IP allowlist + mTLS) pour empêcher bypass

> Pattern utilisé par banques, e-commerce mondiaux, services gouvernementaux.

### Stratégie 3 — DNS direct vers AppGw (simple)

Pas de Front Door : Traffic Manager fait le routage géo entre AppGw par région.

```mermaid
flowchart TB
    U["👤 Utilisateurs"]
    TM["<b>Traffic Manager</b><br/>(performance routing)"]
    AG_WE["<b>AppGw v2 + WAF v2</b><br/>West Europe"]
    AG_SE["<b>AppGw v2 + WAF v2</b><br/>Sweden Central"]
    BE_WE["Backends WE"]
    BE_SE["Backends SE"]
    U --> TM
    TM -->|géo nearest| AG_WE
    TM -->|géo nearest| AG_SE
    AG_WE --> BE_WE
    AG_SE --> BE_SE

    classDef dns fill:#1e88e5,stroke:#0d47a1,color:#fff
    classDef gw fill:#fb8c00,stroke:#e65100,color:#fff
    classDef back fill:#8e24aa,stroke:#4a148c,color:#fff
    class TM dns
    class AG_WE,AG_SE gw
    class BE_WE,BE_SE back
```

#### Quand l'envisager

- Front Door sur-dimensionné (peu de trafic global, audience régionale)
- Forte contrainte de coût
- Audience géographiquement concentrée

#### Inconvénients

- Pas de cache CDN (perte 30–70 % d'accélération perçue)
- Pas de DDoS L7 mutualisé → AppGw + DDoS Protection Standard nécessaires
- TTL DNS = RTO de plusieurs minutes en cas de bascule
- Pas de routing intelligent (anycast)

### Le piège du DNS Azure SPOF

Traffic Manager dépend lui-même d'Azure DNS. Si paranoïaque :

- Azure DNS + DNS secondaire (NS1, Route 53, Dyn) via zone transfer (AXFR)
- Ou utiliser Cloudflare DNS / Route 53 comme primaire avec failover vers les endpoints Azure

```mermaid
flowchart LR
    B["🌐 Browser"]
    DNS["<b>Cloudflare DNS / Route 53</b><br/>(primaire indépendant d'Azure)"]
    TM["<b>Traffic Manager Azure</b>"]
    O["Origines Azure"]
    B --> DNS
    DNS -->|CNAME| TM
    TM --> O

    classDef ext fill:#fb8c00,stroke:#e65100,color:#fff
    classDef azure fill:#1e88e5,stroke:#0d47a1,color:#fff
    class DNS ext
    class TM,O azure
```

### Recommandation par niveau de criticité

| Niveau | Stratégie | Coût delta | RTO edge |
|---|---|---|---|
| Critique métier (banking, santé, e-commerce majeur) | Multi-CDN (Stratégie 2) | +500 à +5 000 €/mois | ~30–60 s |
| **Critique standard (B2B SaaS, réglementé)** | **Dual Edge Azure (Stratégie 1)** | +500 à +800 €/mois | ~1–3 min |
| Critique léger (interne, faible audience) | Traffic Manager + AppGw (Stratégie 3) | Base | ~3–5 min |

### Config Traffic Manager type (Stratégie 1)

```yaml
Profile name: tm-app-contoso
Routing method: Priority
DNS TTL: 30 s
Monitor:
  Protocol: HTTPS
  Port: 443
  Path: /health
  Interval: 10 s
  Tolerated failures: 3
  Timeout: 5 s
Endpoints:
  - name: front-door-primary
    type: Azure Endpoint (Front Door)
    priority: 1
  - name: appgw-we-backup
    type: External Endpoint
    target: appgw-we.contoso.com
    priority: 2
    location: West Europe
  - name: appgw-se-backup
    type: External Endpoint
    target: appgw-se.contoso.com
    priority: 3
    location: Sweden Central
```

---

## Opérabilité, tests et FinOps

### Tests de failover impératifs

- Couper Front Door (désactiver endpoint) → vérifier bascule Traffic Manager en < 2 min
- Couper AppGw région primaire → bascule vers AppGw secondaire
- Mesurer le **TTL effectif côté client** (browsers, proxies corporate, opérateurs)
- Tester l'attaque DDoS sur le chemin direct AppGw (capacité suffisante sans Front Door ?)
- Vérifier certificats TLS valides et auto-renouvelés
- Promotion HorizonDB / SQL chronométrée (auto-failover-group)
- Redis A/A : kill région primaire, vérifier R/W secondaire sans interruption
- Service Bus : bascule alias, perte de messages non-checkpointés ?
- App Configuration : feature flag region-primary appliqué
- **Runbook complet exécuté trimestriellement** (Chaos Studio)
- **Retour à la normale testé aussi** (souvent oublié)

### Observabilité indispensable

- Synthetic monitoring depuis 3+ régions externes
- Dashboards SLO/SLI par tier (Front Door, APIM, backend, data)
- Alertes corrélées (corrélation incident → bascule auto)
- Logs immuables centralisés (Sentinel SIEM)

### Modèle de coût approximatif (référence)

| Composant | Coût mensuel approx. (2 régions) |
|---|---|
| Front Door Premium | ~ 330 €/mois |
| APIM Premium (multi-région, 2 units) | ~ 5 000 €/mois |
| AKS (backend, 3 nodes/région) | ~ 1 500 €/mois |
| HorizonDB (primary + replica) | ~ 2 000 à 5 000 €/mois selon charge |
| Cosmos DB (2 régions, RU provisioned) | ~ 1 000 à 5 000 €/mois |
| Redis Enterprise A/A | ~ 1 500 €/mois |
| Application Gateway v2 WAF (x2) | ~ 600 €/mois |
| Storage RA-GZRS, Service Bus Premium, Key Vault, Monitor | ~ 500 à 1 000 €/mois |
| **Total ordre de grandeur** | **~ 12 000 à 20 000 €/mois** |

> À pondérer par le coût d'un incident critique (data leak, downtime e-commerce, atteinte à l'image), qui dépasse souvent l'année de plateforme.

---

## Récapitulatif & décisions clés

### Les décisions structurantes

1. **Front Door Premium** — pour Private Link, WAF managé, conformité
2. **APIM Premium multi-région** — façade API obligatoire, gateway sync auto
3. **Séparation Front / API / Back** — 2 routes parallèles sous Front Door, pas d'APIM devant le statique
4. **Datastore : pattern hybride** — HorizonDB (transactionnel PostgreSQL) + Cosmos DB (multi-write global) + Redis A/A (cache distribué)
5. **Multi-région non-pairée acceptable** si conformité l'exige, mais GRS Storage à remplacer par Object Replication
6. **Edge résiliente** — Dual Edge Azure (Traffic Manager → Front Door + Application Gateway) pour 99 % des cas critiques
7. **Tout via Private Endpoints** — zéro IP publique sauf Front Door (et AppGw en secours)
8. **Tests de bascule trimestriels** non négociables — Chaos Studio + runbooks Automation

### Anti-patterns à éviter

- APIM Developer/Basic ou single-region en prod critique
- APIM devant le contenu statique
- Backend exposé en IP publique (même via WAF) sur du critique
- Backups non testés en restore
- Failover non testé en conditions réelles
- DNS Azure unique comme primaire si paranoïa élevée
- Front Door Standard avec backends privés (impossible sans Private Link)

---

## Références

- [Azure Front Door Premium overview](https://learn.microsoft.com/azure/frontdoor/front-door-overview)
- [Azure Front Door Premium WAF managed rule sets](https://learn.microsoft.com/azure/web-application-firewall/afds/waf-front-door-drs)
- [Azure Front Door Private Link to origin](https://learn.microsoft.com/azure/frontdoor/private-link)
- [Azure API Management Premium multi-region deployment](https://learn.microsoft.com/azure/api-management/api-management-howto-deploy-multi-region)
- [Azure SQL auto-failover groups](https://learn.microsoft.com/azure/azure-sql/database/auto-failover-group-overview)
- [Azure Cosmos DB multi-region writes](https://learn.microsoft.com/azure/cosmos-db/how-to-multi-master)
- [Azure Cache for Redis Enterprise Active-Active](https://learn.microsoft.com/azure/azure-cache-for-redis/cache-how-to-active-geo-replication)
- [Azure Storage Object Replication](https://learn.microsoft.com/azure/storage/blobs/object-replication-overview)
- [Azure Service Bus Geo-disaster recovery](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-geo-dr)
- [Azure paired regions](https://learn.microsoft.com/azure/reliability/cross-region-replication-azure)
- [Azure Chaos Studio](https://learn.microsoft.com/azure/chaos-studio/chaos-studio-overview)
- [Mission-critical workloads on Azure (Well-Architected)](https://learn.microsoft.com/azure/well-architected/mission-critical/mission-critical-overview)
- [Azure Front Door + Traffic Manager (dual-edge pattern)](https://learn.microsoft.com/azure/architecture/guide/networking/global-web-applications/overview)
- [Azure HorizonDB documentation](https://learn.microsoft.com/azure/horizondb/) *(vérifier statut GA dans les régions cibles)*
