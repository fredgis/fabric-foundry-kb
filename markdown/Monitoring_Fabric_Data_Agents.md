---
title: "Monitoring Microsoft Fabric Data Agents"
subtitle: "Observability, Audit, Capacity and Enterprise Operations"
date: "August 2026"
---

> **Scope.** Current monitoring capabilities for Microsoft Fabric Data Agents, their maturity, known gaps, and a deployable enterprise observability architecture.
>
> **Status note.** Product statuses and pricing can change. Validate preview/GA status, licensing and regional availability against the linked Microsoft documentation before production deployment.

## Réponses directes aux questions de monitoring

**Q1 — Existe-t-il une API officielle aujourd'hui ?** Il n'existe **pas d'endpoint dédié** `/admin/activityevents` pour les Fabric Data Agents. Le monitoring officiel s'appuie sur trois canaux distincts, chacun couvrant une dimension différente : consommation CU (Capacity Metrics App, GA), prompts/réponses (Purview DSPM for AI, preview) et traces d'exécution (Foundry Observability via Application Insights, preview). [8](https://learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption) [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance) [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability)

**Q2 — Preview ou feature flag à activer ?** Oui — deux paramètres cumulatifs :

1. Dans le **Fabric Admin Portal**, activer le tenant setting *"Allow Microsoft Purview to secure AI interactions"* [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
2. Dans **Microsoft Purview**, activer la politique *"DSPM for AI – Capture interactions for Copilot experiences"* + activer *Purview Audit* [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)

**Q3 — Roadmap / timing ?** La fonctionnalité *"Data Agent Audit logs with Purview"* est disponible en **Public preview** depuis Q1 2026. Elle couvre notamment l'audit et l'investigation des interactions dans Microsoft Purview. Le statut produit doit être confirmé dans la documentation Microsoft Learn ; Fabric GPS est uniquement un tracker communautaire de la roadmap. [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)



## État détaillé des capacités actuelles

### Capacity Metrics App — la consommation CU **est** exposée (mais sous un autre nom)

**Les Data Agents apparaissent dans le Capacity Metrics App**, mais sous une nomenclature qui prête à confusion :

| Métrique                    | Valeur documentée                                            |
| --------------------------- | ------------------------------------------------------------ |
| **Item kind (Metrics App)** | `LlmPlugin` [8](https://learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption) [9](https://learn.microsoft.com/en-us/fabric/enterprise/fabric-operations) |
| **Operation Name**          | `AI Query` [8](https://learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption) [9](https://learn.microsoft.com/en-us/fabric/enterprise/fabric-operations) |
| **Type d'opération**        | Background job (donc lissage possible) [8](https://learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption) [9](https://learn.microsoft.com/en-us/fabric/enterprise/fabric-operations) |
| **Azure billing meter**     | `Copilot and AI` [9](https://learn.microsoft.com/en-us/fabric/enterprise/fabric-operations) |
| **Meter d'entrée**          | 100 CU-seconds / 1 000 tokens d'input [8](https://learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption) |
| **Meter de sortie**         | 400 CU-seconds / 1 000 tokens d'output [8](https://learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption) |
| **Meter cache**             | 10 CU-seconds / 1 000 tokens d'input mis en cache [8](https://learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption) |

**Exemple documenté** : une requête à 2 000 tokens input + 500 tokens output = (2 000 × 100 + 500 × 400) / 1 000 = 400 CU-seconds ≈ 6,67 CU-minutes [8](https://learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption). À noter : *l'exécution* des requêtes SQL/DAX/KQL générées est facturée séparément sur l'item cible (Warehouse, Semantic Model, KQL DB) [8](https://learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption).

> **Action pratique** : dans l'onglet *"matrix by item and operation"* du Metrics App, filtrer par item kind = `LlmPlugin` et operation = `AI Query` pour retrouver la consommation par capacité et par heure. [9](https://learn.microsoft.com/en-us/fabric/enterprise/fabric-operations)

### Microsoft Purview DSPM for AI — audit des prompts et réponses (Public Preview)

C'est le **seul canal officiel** aujourd'hui qui capture le contenu textuel des interactions Data Agent. La documentation Microsoft Learn *"Auditing data agent interactions in Microsoft Purview (preview)"* détaille précisément le mécanisme [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance) :

**Prérequis (3 activations cumulatives) :**

1. **Enable Purview Audit** — depuis *DSPM for AI (classic) > Overview > Get Started > Activate Microsoft Purview Audit* [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
2. **Enable DSPM for AI Policy** — activer *"DSPM for AI – Capture interactions for Copilot experiences"* (politique one-click) [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
3. **Enable Fabric Tenant Setting** — dans l'Admin Portal Fabric, activer *"Allow Microsoft Purview to secure AI interactions"* [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)

**Ce qui est capturé pour chaque interaction :**

- Timestamp [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
- User identity [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
- Application and agent details [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
- Associated resources and metadata [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
- **User prompt** (texte complet) [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
- **AI response** (texte complet, y compris code/queries générés) [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)

**Où consulter :** *Microsoft Purview Portal > DSPM for AI > Activity Explorer* → filtrer *Activity Type = "Copilot Interaction"* et *App = "Fabric-Data Agent"* [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance). Les enregistrements sont également écrits dans le **Microsoft 365 unified audit log** [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance).

**Schéma des records** (documentation Purview) : chaque record `CopilotInteraction` contient les attributs `AccessedResources`, `AgentId`, `AgentName`, `AgentVersion`, `AISystemPlugin`, `AppHost`, `AppIdentity`, `CapacityId`, `ClientRegion`, `Contexts`, `Messages` (ID prompt/réponse, flags JailbreakDetected), `ModelTransparencyDetails`, `Operation = CopilotInteraction`, `RecordType`, `Workload = Copilot` [5](https://learn.microsoft.com/en-us/purview/audit-copilot). Ces attributs sont exploitables via l'API Office 365 Management Activity, Microsoft Sentinel, ou export vers Fabric/Log Analytics.

**Licensing and retention** : les capacités disponibles, la durée de rétention et les fonctions avancées dépendent des licences Microsoft Purview et Microsoft 365. Vérifier les conditions actuelles avant de définir une politique de rétention ou d'export. [5](https://learn.microsoft.com/en-us/purview/audit-copilot)

#### Protection des données personnelles dans les traces

Les prompts et réponses peuvent contenir des données personnelles, des données métier sensibles ou du code généré. Les journaux Purview et Application Insights doivent donc être traités comme des données de production sensibles :

- limiter l'accès avec des rôles dédiés et le principe du moindre privilège ;
- éviter l'export systématique du texte intégral vers un Eventhouse ou un dashboard ;
- privilégier des métriques agrégées et pseudonymiser les identifiants utilisateurs ;
- appliquer une durée de rétention documentée et proportionnée au besoin d'audit ;
- filtrer ou supprimer les secrets, identifiants directs et données réglementées avant ingestion dans une plateforme d'observabilité secondaire ;
- documenter la finalité de collecte et les responsabilités de traitement avec les équipes privacy, sécurité et conformité.

### Microsoft Foundry Observability — tracing end-to-end (Public Preview)

Cette voie devient très intéressante si vous consommez le Fabric Data Agent **depuis un agent Foundry** (ce qui est de plus en plus la pratique en multi-agent). La doc *"Observability for Fabric data agents in Microsoft Foundry"* décrit précisément l'architecture [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability) :

**Principe** : le Data Agent Fabric envoie ses logs et traces à la ressource **Azure Monitor Application Insights** connectée au projet Foundry (une seule ressource par projet) [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability).

**Structure des traces** — chaque requête produit une hiérarchie de spans :

```
Request (trace)
└─ Foundry agent run
   └─ Fabric data agent (called as a tool)
      └─ Agent span            Overall run of the Fabric data agent
         ├─ Tool span          First data source the data agent queried
         └─ Tool span          Second data source the data agent queried
```

[7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability)

**Métadonnées disponibles par niveau** [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability) :

| Niveau                        | Émis par          | Métadonnées exemples                                         |
| ----------------------------- | ----------------- | ------------------------------------------------------------ |
| Foundry agent run             | Foundry           | Conversation ID, status, duration                            |
| Fabric data agent (tool call) | Foundry           | Agent display name, status, duration                         |
| Agent span                    | Fabric data agent | Agent display name, conversation ID, status, duration        |
| Tool span                     | Fabric data agent | **Data source name**, **reasoning step ID**, status, duration |

**Cas d'usage** [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability) :

- Latence — la durée par span identifie l'étape lente
- Qualité — les tool spans montrent quelles data sources ont été interrogées et dans quel ordre
- Échecs — le status par span pointe l'étape en erreur

**Accès** : lecture via Foundry Portal (traces sur 90 jours) ou requêtes KQL directes dans Application Insights (rétention selon config) [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability). Rôles requis : `Monitoring Reader` ou `Log Analytics Reader` sur la ressource AppInsights + `Foundry User` sur le projet [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability).

**Setup** : dans le projet Foundry, *Agents > Traces > Connect* → sélectionner ou créer une ressource Application Insights. Le tracing est automatique côté serveur, sans modification de code [2](https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/trace-agent-setup).

**Statut actuel (juillet 2026)** : *"Tracing is generally available for prompt and hosted agents. Workflow and external agents are in preview"* [2](https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/trace-agent-setup). Le tracing des Fabric Data Agents comme tools bénéficie de cette pipeline.

### Fabric Data Agent Python SDK — évaluation programmatique (Preview)

Publié sur PyPI sous `fabric-data-agent-sdk` [14](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-sdk). Deux couches :

- **Management plane (REST API Fabric)** : create/get/list/delete/publish/update Data Agent + datasources + fewshots [14](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-sdk) [19](https://learn.microsoft.com/en-us/rest/api/fabric/dataagent/items) [18](https://learn.microsoft.com/en-us/rest/api/fabric/dataagent/published).
- **Runtime** : requêtes via l'endpoint MCP publié [14](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-sdk) [20](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-mcp-server).

**Évaluation** avec `evaluate_data_agent()` [4](https://learn.microsoft.com/en-us/fabric/data-science/evaluate-data-agent) : chargement d'un dataset (question, expected_answer), exécution, stockage des résultats dans deux tables (*summary* + *steps* avec reasoning détaillé). C'est **la brique officielle pour mesurer précision et qualité** — mais ce n'est pas de la télémétrie de production, c'est de la validation avant déploiement.

### Fabric Data Agent REST API — public preview depuis Build 2026

Depuis juin/juillet 2026, une **REST API publique** est exposée sur `learn.microsoft.com/en-us/rest/api/fabric/dataagent/*` [19](https://learn.microsoft.com/en-us/rest/api/fabric/dataagent/items) [18](https://learn.microsoft.com/en-us/rest/api/fabric/dataagent/published). Elle couvre :

| Endpoint                                                 | Rôle                                                         |
| -------------------------------------------------------- | ------------------------------------------------------------ |
| Items (Create/Delete/Get/List/Publish/Update Data Agent) | Management plane [19](https://learn.microsoft.com/en-us/rest/api/fabric/dataagent/items) |
| Published (Datasources, Settings, Fewshots)              | Lecture de la config publiée [18](https://learn.microsoft.com/en-us/rest/api/fabric/dataagent/published) |

**Important** : cette API est **management-plane uniquement**. Elle ne retourne **pas** les prompts, réponses, temps d'exécution ou télémétrie runtime — pour cela il faut passer par Purview (contenu) ou Foundry AppInsights (traces).

## Ce qui **n'est pas** exposé (et pourquoi)

### Activity Events API / Fabric Audit Log

J'ai passé au crible la page officielle *"Operation list"* (audit logs Fabric) [17](https://learn.microsoft.com/en-us/fabric/admin/operation-list). Recherche exhaustive :

- **Aucune** opération portant "DataAgent" ou "data agent" comme mot-clé 
- **Seule** opération liée : `CopilotInteraction` — *"Request Copilot features in Fabric"* [17](https://learn.microsoft.com/en-us/fabric/admin/operation-list)

Autrement dit, les interactions Data Agent **ne créent pas** d'entrée dédiée dans le pipeline `/admin/activityevents` de Power BI/Fabric. Elles émettent un `CopilotInteraction` qui est routé vers le **Microsoft 365 unified audit log** (canal Purview), pas vers le pipeline Fabric admin. C'est confirmé par la doc *"Track user activities in Microsoft Fabric"* qui redirige vers le portail Purview pour tout accès aux audit logs [16](https://learn.microsoft.com/en-us/fabric/admin/track-user-activities).

**Confirmation communauté** (thread Microsoft Fabric Community, juin 2025) : *"As of now, there is no built-in feature in Microsoft Fabric that allows tenant administrators to directly view the full content of user prompts and the corresponding Data Agent responses."* [15](https://community.fabric.microsoft.com/t5/Fabric-platform/Fabric-Data-Agent-Logs/m-p/4721877) — cette réponse a été partiellement invalidée par la sortie de Purview DSPM for AI en Q1 2026, mais elle reste vraie pour les canaux Fabric-natifs.

### DMV XMLA ($SYSTEM.DISCOVER_SESSIONS)

Le moteur d'orchestration du Data Agent n'est pas une session Analysis Services. Seules les requêtes DAX générées puis exécutées sur un modèle sémantique peuvent ouvrir une session AS ; elles apparaissent alors comme des requêtes du modèle sémantique et non comme une trace complète du Data Agent. Les DMV XMLA ne constituent donc pas un canal d'observabilité de l'agent.

### Fabric Monitoring Hub

La documentation officielle liste explicitement les item types affichés dans le Monitoring Hub : *Copy Job, Dataflow Gen2, Dataflow Gen2 CI/CD, Datamart, Data Build Tool (dbt) Job, Digital Twin Builder Flow, Experiment, Graph model, Lakehouse, Map, Notebook, Pipeline, Semantic model, Snowflake database, Spark job definition, User data function* [13](https://learn.microsoft.com/en-us/fabric/admin/monitoring-hub). **Aucun Data Agent** — ce n'est pas un oubli, c'est un choix produit.

### Workspace Monitoring (Preview)

La doc *"What is workspace monitoring (preview)"* liste tous les workloads dont les événements sont ingérés dans l'Eventhouse du workspace : Real-Time hub, Data Engineering (GraphQL), Data Factory (Copy job, Pipeline), Real-Time Intelligence (Eventhouse, Eventstream), Mirroring, Power BI (Semantic models) [12](https://learn.microsoft.com/en-us/fabric/fundamentals/workspace-monitoring-overview). **Data Agent n'y figure pas**.

## Roadmap et annonces récentes

### Suivi de la fonctionnalité "Data Agent Audit logs with Purview"

La documentation Microsoft Learn constitue la source de vérité sur la disponibilité. Le site Fabric GPS peut être utilisé comme tracker communautaire complémentaire, mais il ne s'agit pas d'une publication Microsoft officielle. [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance) [11](https://www.fabric-gps.com/release/2e298f0f-3801-f111-8406-000d3a36696c)

- **Catégorie** : Conversational Analytics
- **Statut actuel** : Public preview · **Shipped**
- **Release Date** : Q1 2026

**Capabilités couvertes** [11](https://www.fabric-gps.com/release/2e298f0f-3801-f111-8406-000d3a36696c) :

- **Audit** : envoi des prompts/réponses + contexte utilisateur/système à Purview
- **eDiscovery** : contenu accessible pour les processus d'e-discovery
- **Data Lifecycle Management (DLM)** : gestion de rétention
- **Communications Compliance (CC)** : détection d'usages non éthiques
- **Classification** : classification via Purview et stockage conforme

### Concept produit — évolution de la posture de gouvernance

La doc *"Fabric data agent concepts"* (mise à jour 2026) mentionne explicitement dans la section *"Operational oversight"* [10](https://learn.microsoft.com/en-us/fabric/data-science/concept-data-agent) :

- **Logging and audit** : *"Monitor agent interactions through available logging and audit capabilities"*
- **Human-in-the-loop escalation**
- **Periodic review**

Et dans les limitations [10](https://learn.microsoft.com/en-us/fabric/data-science/concept-data-agent) : *"Agent interactions might be logged and discoverable through Microsoft Purview Audit and eDiscovery. Organizations should consider these governance controls when deploying agents for sensitive workloads."* — confirmant Purview comme le vecteur officiel.

### Build 2026 & Foundry Observability

L'annonce Build 2026 (blog Microsoft Foundry, 3 juin 2026 : *"From observability to ROI for AI agents on any framework"*) et la doc *"Set Up Tracing for AI Agents in Microsoft Foundry"* confirment [2](https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/trace-agent-setup) [6](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept) :

- Tracing serveur GA pour Prompt agents et Hosted agents
- OpenTelemetry sémantique multi-agent (Microsoft + Cisco Outshift) [6](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept)
- Extension aux Microsoft Agent Framework, LangChain, LangGraph, OpenAI Agents SDK [6](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept)
- Intégration Fabric Data Agents comme "tool" avec spans dédiés (documenté début juillet 2026) 

## Comparaison Fabric Data Agent vs Foundry Agents (monitoring)

| Dimension                      | Fabric Data Agent (natif)                                    | Fabric Data Agent via Foundry                                | Foundry Agents (Prompt/Hosted)                               |
| ------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Prompts/réponses (contenu)** | Purview DSPM for AI (preview) [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance) | Application Insights (preview) [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability) | Application Insights (GA) [6](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept) |
| **Traces d'exécution (spans)** | Non exposées                                                 | Agent span + Tool spans [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability) | Traces complètes [6](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept) |
| **Consommation tokens**        | AI Query op / LlmPlugin [9](https://learn.microsoft.com/en-us/fabric/enterprise/fabric-operations) | Capturée dans spans [6](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept) | Capturée dans spans [6](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept) |
| **Consommation CU**            | Capacity Metrics App (GA) [8](https://learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption) | Idem (via meter Fabric)                                      | N/A (facturation Azure OpenAI)                               |
| **Latence par étape**          | Non exposée                                                  | Duration par span [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability) | Duration par span [6](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept) |
| **Data sources queried**       | Non exposées                                                 | Tool spans / Data source name [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability) | Tool spans [6](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept) |
| **Rétention**                  | Purview Audit (jusqu'à 10 ans selon SKU)                     | 90 jours portal + AppInsights                                | 90 jours portal + AppInsights                                |
| **Coût de collecte**           | Inclus M365 E5 [5](https://learn.microsoft.com/en-us/purview/audit-copilot) | Coût AppInsights (data volume) [6](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept) | Coût AppInsights                                             |
| **Statut**                     | Public preview                                               | Public preview                                               | GA (Prompt/Hosted)                                           |

**Recommandation** : si l'observabilité runtime détaillée est un prérequis, envisager d'**orchestrer le Data Agent depuis un Foundry Agent** pour bénéficier du pipeline Application Insights + Foundry tracing, tout en tenant compte du statut preview de l'intégration. [7](https://learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability)

## Architecture de monitoring recommandée

### Architecture cible immédiate

```mermaid
flowchart TB
    FDA["Microsoft Fabric Data Agent"]
    PUR["Microsoft Purview DSPM for AI<br/>prompts, responses, audit<br/>(Public preview)"]
    APP["Foundry + Application Insights<br/>traces, latency, failures<br/>(Public preview for this integration)"]
    CAP["Fabric Capacity Metrics App<br/>CU consumption<br/>LlmPlugin / AI Query (GA)"]
    EVH["Fabric Eventhouse / Log Analytics<br/>controlled ingestion and retention"]
    PBI["Power BI monitoring dashboard<br/>adoption, quality, cost, incidents"]

    FDA --> PUR
    FDA --> APP
    FDA --> CAP
    PUR -->|"Minimized / governed export"| EVH
    APP --> EVH
    CAP --> EVH
    EVH --> PBI

    style FDA fill:#464feb,color:#ffffff,stroke:#2932b8
    style PUR fill:#e8e6ff,stroke:#7160c9
    style APP fill:#dcecff,stroke:#4d83bd
    style CAP fill:#dff5e6,stroke:#4f9c68
    style EVH fill:#fff2cc,stroke:#d6b656
    style PBI fill:#ffd335,stroke:#a88b00
```

### Checklist de mise en place

1. **[Prérequis M365]** Vérifier les licences Microsoft 365 et Purview requises pour l'audit, la rétention et les fonctions d'investigation. [5](https://learn.microsoft.com/en-us/purview/audit-copilot) [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
2. **[Fabric Admin]** Activer *"Allow Microsoft Purview to secure AI interactions"* dans les tenant settings [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
3. **[Purview]** Activer *Purview Audit* si non déjà actif + activer la one-click policy *"DSPM for AI – Capture interactions for Copilot experiences"* [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance)
4. **[Purview]** Valider dans *Activity Explorer* que les records `CopilotInteraction` avec App = `Fabric-Data Agent` apparaissent (compter 24h de propagation)
5. **[Capacity Metrics]** Vérifier la remontée des opérations `AI Query` sous `LlmPlugin` dans le Metrics App
6. **[Foundry — optionnel mais recommandé]** Si des agents multi-orchestrés sont prévus, connecter Application Insights au projet Foundry et exposer le Data Agent comme tool [2](https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/trace-agent-setup)
7. **[Ingestion contrôlée]** Via **Office 365 Management Activity API**, ingérer uniquement les champs nécessaires des records `CopilotInteraction` vers un Eventhouse Fabric, Log Analytics ou Sentinel. Éviter la duplication systématique des prompts et réponses complets.
8. **[Évaluation qualité]** Mettre en place un pipeline `fabric-data-agent-sdk` avec ground truth pour évaluer périodiquement l'accuracy [4](https://learn.microsoft.com/en-us/fabric/data-science/evaluate-data-agent)
9. **[Dashboarding]** Construire un Power BI report unifié avec 4 volets : adoption (users/jour), qualité (accuracy), coût (CU), incidents (erreurs Foundry ou signalements Purview)

### Points de vigilance

- **Preview status** : ni Purview DSPM for AI ni Foundry Observability (pour Fabric Data Agents) ne sont GA aujourd'hui pour cet usage — à cadrer contractuellement [3](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance) [2](https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/trace-agent-setup)
- **Résidence de données** : si `cross-geo processing` est activé, les prompts peuvent transiter hors zone [1](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-tenant-settings). Évaluer ce paramètre au regard des exigences RGPD et EU Data Boundary applicables.
- **Rétention conversation history** : jusqu'à 28 jours si non supprimée par l'utilisateur [1](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-tenant-settings)
- **Aucune granularité workspace ou capacité** dans les tenant settings — l'activation est tenant-wide

## Sources principales (documentation officielle & annonces)

| Source                                                       | URL                                                          |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| Auditing data agent interactions in Microsoft Purview (preview) | `learn.microsoft.com/en-us/fabric/data-science/data-agent-purview-governance` |
| Observability for Fabric data agents in Microsoft Foundry    | `learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-foundry-observability` |
| Data agent in Fabric consumption (CU)                        | `learn.microsoft.com/en-us/fabric/fundamentals/data-agent-consumption` |
| Fabric operations (LlmPlugin item)                           | `learn.microsoft.com/en-us/fabric/enterprise/fabric-operations` |
| Fabric data agent concepts (governance, ALM)                 | `learn.microsoft.com/en-us/fabric/data-science/concept-data-agent` |
| Fabric data agent Python SDK (preview)                       | `learn.microsoft.com/en-us/fabric/data-science/fabric-data-agent-sdk` |
| Evaluate your data agent (preview)                           | `learn.microsoft.com/en-us/fabric/data-science/evaluate-data-agent` |
| Configure Fabric data agent tenant settings                  | `learn.microsoft.com/en-us/fabric/data-science/data-agent-tenant-settings` |
| REST API DataAgent — Items                                   | `learn.microsoft.com/en-us/rest/api/fabric/dataagent/items`  |
| REST API DataAgent — Published                               | `learn.microsoft.com/en-us/rest/api/fabric/dataagent/published` |
| Data agent as MCP server (preview)                           | `learn.microsoft.com/en-us/fabric/data-science/data-agent-mcp-server` |
| Audit logs for Copilot and AI applications                   | `learn.microsoft.com/en-us/purview/audit-copilot`            |
| Set Up Tracing for AI Agents in Microsoft Foundry            | `learn.microsoft.com/en-us/azure/foundry/observability/how-to/trace-agent-setup` |
| Agent tracing overview (Foundry)                             | `learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept` |
| Track user activities in Microsoft Fabric                    | `learn.microsoft.com/en-us/fabric/admin/track-user-activities` |
| Operation list (Fabric audit logs)                           | `learn.microsoft.com/en-us/fabric/admin/operation-list`      |
| Workspace Monitoring Overview (preview)                      | `learn.microsoft.com/en-us/fabric/fundamentals/workspace-monitoring-overview` |
| Monitoring hub (Fabric)                                      | `learn.microsoft.com/en-us/fabric/admin/monitoring-hub`      |
| Community roadmap tracker — Data Agent Audit logs with Purview | `www.fabric-gps.com/release/2e298f0f-3801-f111-8406-000d3a36696c` |
| Microsoft Fabric Roadmap                                    | `roadmap.fabric.microsoft.com`                               |
| Build 2026 — Building agentic apps with Fabric               | `azure.microsoft.com/en-us/blog/microsoft-build-2026-building-agentic-apps-with-microsoft-fabric-and-microsoft-databases/` |
| Fabric Community — Can I monitor and govern Fabric data agents? | `community.fabric.microsoft.com/t5/Fabric-platform/Can-I-monitor-and-govern-Fabric-data-agents/m-p/4734661` |
| Fabric Community — Fabric Data Agent Logs                    | `community.fabric.microsoft.com/t5/Fabric-platform/Fabric-Data-Agent-Logs/m-p/4721877` |

## Synthèse

Le monitoring des Fabric Data Agents ne repose pas sur un canal Fabric unique. La couverture opérationnelle combine **Microsoft Purview DSPM for AI** pour le contenu auditable, **Foundry Observability** pour les traces lorsque l'agent est orchestré depuis Foundry, et la **Capacity Metrics App** pour la consommation CU sous `LlmPlugin` / `AI Query`. Cette architecture couvre l'adoption, l'audit, le coût et une partie du diagnostic runtime, avec des maturités différentes et plusieurs composants encore en preview. Une centralisation dans Eventhouse ou Log Analytics est possible, à condition d'appliquer une minimisation stricte des données et de ne pas répliquer les prompts et réponses complets par défaut.



