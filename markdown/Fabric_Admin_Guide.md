---
title: "Guide d'administration de Microsoft Fabric"
subtitle: "Rôles, scopes, gouvernance et CI/CD"
date: "Mai 2026"
---

## Introduction

Ce document rassemble un panorama complet de l'administration de **Microsoft Fabric** : rôles disponibles, périmètres d'action, délégation des paramètres tenant, gestion par pays/business unit, accès programmatique via les Admin APIs, gouvernance des logs, restrictions de création d'artefacts et intégration CI/CD via GitLab.

Il s'adresse aux **Fabric Administrators**, **Capacity Administrators**, **Domain Administrators**, ainsi qu'aux **architectes data** et **équipes plateforme** qui conçoivent la gouvernance d'un tenant Fabric à l'échelle d'une organisation.

\newpage

## Section 1 — Rôles d'administration et périmètres

### 1.1 Hiérarchie des scopes

Microsoft Fabric s'appuie sur une hiérarchie de rôles d'administration, du plus large (tenant) au plus restreint (item) :

```
Tenant (Entra ID)
 └── Domain (regroupement logique de workspaces)
      └── Capacity (ressources de calcul F/P SKU)
           └── Workspace (conteneur d'items)
                └── Item (Lakehouse, Notebook, Report, etc.)
```

### 1.2 Rôles au niveau Tenant

Ces rôles proviennent de **Microsoft Entra ID** (anciennement Azure AD) ou de Microsoft 365.

| Rôle | Scope | Droits principaux |
|------|-------|-------------------|
| **Global Administrator** | Tout le tenant | Contrôle total sur Microsoft 365 / Entra, y compris Fabric. |
| **Fabric Administrator** (anciennement Power BI Administrator) | Tenant Fabric | Gère paramètres tenant, capacités, audits, métadonnées, politiques de gouvernance, exemptions, embedded tokens. Ne donne pas accès au contenu des workspaces par défaut. |
| **Power Platform Administrator** | Power Platform + Fabric | Inclut les droits du Fabric Administrator. |
| **Billing Administrator** | Facturation | Gère les achats et abonnements (capacités F SKU via Azure ou P SKU via M365). |
| **License Administrator** | Licences | Assigne licences Fabric / Power BI Pro / PPU aux utilisateurs. |

Pour accéder au contenu utilisateur, un Fabric Admin doit explicitement activer *Admin access to workspaces* ou prendre la propriété d'un workspace.

### 1.3 Domain Admin et Domain Contributor

Les **domaines** regroupent des workspaces par unité métier (Finance, RH, etc.) — clé pour OneLake et le data mesh.

| Rôle | Droits | Scope |
|------|--------|-------|
| **Domain Admin** | Créer/gérer le domaine, assigner des workspaces, déléguer paramètres tenant (endorsement, certification, featured content), définir Domain Contributors. | Un domaine spécifique |
| **Domain Contributor** | Assigner ses propres workspaces au domaine ; ne peut pas modifier les paramètres globaux du domaine. | Workspaces qu'il possède |

Configurable depuis **Admin portal → Domains**.

### 1.4 Capacity Admin

Une capacité (F2 à F2048, P1 à P5, EM, A SKU) héberge l'exécution des workloads.

| Rôle | Droits | Scope |
|------|--------|-------|
| **Capacity Admin** | Assigner/désassigner des workspaces à la capacité, configurer les workloads (Spark, SQL, Eventstream), définir les contributeurs, gérer notifications, surveiller via la Capacity Metrics app. | Une capacité spécifique |
| **Capacity Contributor** | Peut assigner ses propres workspaces à la capacité. | Capacité spécifique |

Pour les **F SKU**, les rôles Azure RBAC s'ajoutent :

- **Owner / Contributor** (Azure) : pause/resume, scale, suppression de la ressource.
- **Reader** : lecture des paramètres Azure.

### 1.5 Rôles Workspace

Quatre rôles, du plus puissant au plus limité :

| Rôle | Droits principaux | Cas d'usage |
|------|------------------|-------------|
| **Admin** | Tous les droits du Member + ajouter/retirer membres, supprimer/renommer le workspace, publier des apps, gérer la connexion au pipeline de déploiement. | Owner d'un projet |
| **Member** | Ajouter membres avec rôles inférieurs, publier/partager/mettre à jour les apps, CRUD sur tous les items, gérer datasets. | Lead développeur |
| **Contributor** | Créer, modifier, supprimer le contenu ; planifier refresh ; publier rapports ; ne peut pas publier d'app ni gérer les permissions. | Développeurs / data engineers |
| **Viewer** | Lire et interagir avec le contenu (rapports, requêter le SQL endpoint d'un Lakehouse en lecture seule). | Consommateurs |

Le workspace **My workspace** est personnel et n'a pas de rôles.

### 1.6 Permissions au niveau item

Chaque item (Lakehouse, Warehouse, Semantic model, Notebook, KQL DB) supporte des permissions granulaires :

- **Read / ReadAll / ReadData / Build / Share / Reshare / Execute / Write**
- Pour Lakehouse / Warehouse / SQL endpoint : permissions SQL (`GRANT SELECT`, `GRANT EXECUTE`), OneLake security (RBAC sur dossiers/tables), Row-Level / Column-Level / Object-Level Security.

### 1.7 Tableau synthétique des scopes

| Rôle | Niveau | Paramètres tenant | Accès contenu | Facturation |
|------|--------|------------------|---------------|-------------|
| Global Admin | Tenant | Oui | Oui (via takeover) | Oui |
| Fabric Admin | Tenant Fabric | Oui | Non (sauf takeover) | Non |
| Billing Admin | Tenant | Non | Non | Oui |
| Domain Admin | Domaine | Partiel (délégué) | Non | Non |
| Capacity Admin | Capacité | Non | Non | Partiel (Azure RBAC) |
| Workspace Admin | Workspace | Non | Oui (workspace) | Non |
| Workspace Member / Contributor / Viewer | Workspace | Non | Oui (selon rôle) | Non |

### 1.8 Bonnes pratiques

1. **Moindre privilège** : préférer Contributor à Member quand l'utilisateur n'a pas besoin de gérer les permissions.
2. **Délégation par domaine** : utiliser les Domain Admins pour décentraliser la gouvernance.
3. **Groupes Entra ID partout** : ne **jamais** référencer des comptes individuels dans les rôles workspace/capacity ni dans les tenant settings. Toujours passer par des **groupes de sécurité Entra ID**. Cela permet de **déléguer la gestion des accès au niveau Entra** (le Fabric Admin ne configure qu'une fois "tenant setting → groupe X" ; ensuite, qui est dans le groupe X est piloté par l'owner Entra, RH, IAM, Access Reviews, PIM, lifecycle workflows). Voir Section 3.10 pour le pattern complet.
4. **Séparation des rôles** : éviter qu'un même compte soit Fabric Admin + Capacity Admin + Workspace Admin.
5. **Audit** : activer les logs unifiés Microsoft 365 / Purview pour tracer les actions admin.

\newpage

## Section 2 — Mettre en place une administration par pays

### 2.1 Constat

Microsoft Fabric n'a **pas de rôle natif "Country Admin"**. Il faut donc modéliser cette segmentation via les briques existantes (domaines, capacités, workspaces, groupes Entra ID).

### 2.2 Option 1 — Domaines par pays (recommandée)

Approche la plus alignée avec la philosophie data mesh de Fabric.

**Mise en place :**

1. **Admin portal → Domains → Create domain** : créer un domaine par pays (`FR`, `DE`, `ES`, `IT`).
2. Optionnel : utiliser des **sous-domaines** (ex. domaine `EMEA` → sous-domaines `FR`, `DE`).
3. Assigner un **Domain Admin** par pays (idéalement un groupe Entra ID `grp-fabric-admin-FR`).
4. Assigner les workspaces du pays au domaine correspondant.

**Capacités du Domain Admin pays :**

- Gérer son domaine (nom, description, image).
- Assigner/retirer des workspaces.
- Déléguer certains paramètres tenant (endorsement, certification, featured content).
- Définir des Domain Contributors locaux.

**Limites :**

- Un workspace n'appartient qu'à un seul domaine à la fois.
- Le Domain Admin ne contrôle pas la capacité ni les permissions internes aux workspaces.

### 2.3 Option 2 — Capacités par pays

Pour isoler la facturation et les ressources de calcul.

**Mise en place :**

- Une capacité F SKU par pays (`cap-fabric-FR`, `cap-fabric-DE`).
- Un **Capacity Admin** par pays (groupe Entra).
- Les workspaces du pays sont assignés à la capacité correspondante.

**Avantages :**

- Isolation des coûts (chaque pays paie sa capacité via son abonnement Azure).
- Isolation de la performance (pas de noisy neighbor entre pays).
- Possibilité de pause/resume par pays selon les heures ouvrées locales.
- RBAC Azure (Owner/Contributor) pour gérer le cycle de vie de la capacité.

Cette option est souvent **combinée à l'Option 1**.

### 2.4 Option 3 — Workspaces avec admins locaux

Pour les organisations plus petites ou les pays avec peu de workloads.

- Convention de nommage : `ws-<pays>-<projet>` (ex. `ws-FR-finance`).
- Groupes Entra par pays : `grp-fabric-admin-FR`, `grp-fabric-member-FR`.
- Assignation des groupes en rôle Admin sur tous les workspaces du pays.

Limite : ne couvre pas les paramètres tenant ni l'endorsement.

### 2.5 Architecture cible recommandée (combinée)

```
Tenant
 +-- Fabric Admin global (équipe centrale gouvernance)
 |
 +-- Domain "France" -------- Domain Admin: grp-fabric-admin-FR
 |    +-- Capacity F64-FR --- Capacity Admin: grp-fabric-admin-FR
 |    +-- Workspaces:
 |         +-- ws-FR-finance  (Admin: grp-fabric-admin-FR)
 |         +-- ws-FR-rh
 |         +-- ws-FR-ventes
 |
 +-- Domain "Germany" ------- Domain Admin: grp-fabric-admin-DE
 |    +-- Capacity F32-DE
 |    +-- Workspaces ws-DE-*
 |
 +-- Domain "Spain" --------- Domain Admin: grp-fabric-admin-ES
      +-- Capacity F16-ES
      +-- Workspaces ws-ES-*
```

### 2.6 Tableau récapitulatif

| Besoin | Solution Fabric |
|--------|-----------------|
| Gouvernance des métadonnées / catalogage par pays | Domain par pays |
| Isolation des coûts / facturation par pays | Capacity F SKU par pays |
| Délégation certification / endorsement | Domain Admin avec délégation des tenant settings |
| Sécurité du contenu | Rôles Workspace + groupes Entra par pays |
| Résidence des données / souveraineté | Multi-Geo (capacités dans la région du pays) |

### 2.7 Souveraineté et résidence des données

Si le besoin est lié à la **souveraineté des données** (RGPD, lois locales) :

- **Multi-Geo capacities** : placer la capacité dans la région Azure du pays (France Central pour FR, Germany West Central pour DE).
- **Tenant settings** : configurer la région par défaut.
- **OneLake** : les données restent dans la région de la capacité hôte du workspace.

### 2.8 Étapes de mise en œuvre

1. Créer les **groupes Entra ID** par pays (`grp-fabric-admin-XX`, `grp-fabric-contrib-XX`).
2. Provisionner une **capacité F SKU** par pays dans la région cible.
3. Créer un **domaine** par pays et assigner le groupe admin pays.
4. Déléguer dans le domaine les paramètres tenant utiles (endorsement, featured content).
5. Créer les **workspaces** avec convention de nommage par pays, les assigner à la capacité + domaine du pays.
6. Affecter les groupes Entra aux rôles workspace selon les profils.
7. Activer **l'audit** (Purview / M365 logs) pour tracer les actions des admins pays.

\newpage

## Section 3 — Accès programmatique aux Admin APIs

### 3.1 Deux familles d'API

| Famille | Endpoint racine | Usage |
|---------|-----------------|-------|
| Power BI Admin REST API | `https://api.powerbi.com/v1.0/myorg/admin/...` | Historique, couvre workspaces, datasets, reports, activités, tenant settings. |
| Fabric Admin REST API | `https://api.fabric.microsoft.com/v1/admin/...` | Plus récente, items Fabric (Lakehouse, Notebook, KQL DB), domaines, labels, external data shares. |

Les deux coexistent — certaines fonctions ne sont disponibles que dans l'une ou l'autre.

### 3.2 Pré-requis côté identité

| Identité | Rôle requis |
|---------|-------------|
| **Utilisateur** | Fabric Administrator, Power Platform Administrator ou Global Administrator + licence Fabric/Power BI. |
| **Service Principal** | Voir section 3.3. |
| **Managed Identity** (Azure) | Supportée comme service principal depuis 2024. |

### 3.3 Activer un Service Principal

Méthode recommandée pour l'automatisation (CI/CD, scripts planifiés, Azure Functions).

#### Étape A — Créer l'app dans Entra ID

1. **Entra ID → App registrations → New registration**.
2. Créer un **client secret** ou un **certificat**.
3. Pas besoin de permissions API déléguées Power BI pour les Admin APIs en mode application.

#### Étape B — Créer un groupe de sécurité Entra

Créer un groupe (ex. `grp-fabric-admin-api`) et y ajouter le service principal. Ne jamais utiliser un groupe vide ou trop large.

#### Étape C — Activer dans le Fabric Admin portal

Admin portal → **Tenant settings → Developer settings** :

| Paramètre | À activer pour |
|-----------|----------------|
| Service principals can use Fabric APIs | Appels en lecture/écriture standards |
| Service principals can access read-only admin APIs | Appels aux `/admin/...` en GET |
| Service principals can access admin APIs used for updates | Pour les Admin APIs en POST/PATCH/DELETE |
| Allow service principals to create and use profiles | Si besoin de Profile API (multi-tenant ISV) |

Pour chacun, **restreindre au groupe** `grp-fabric-admin-api`.

#### Étape D — Donner le rôle Fabric Administrator

**Entra ID → Roles and administrators → Fabric Administrator** : ajouter le service principal comme membre. Requis pour certaines opérations sensibles.

### 3.4 Acquérir un token

| Audience | Scope |
|----------|-------|
| Power BI Admin API | `https://analysis.windows.net/powerbi/api/.default` |
| Fabric Admin API | `https://api.fabric.microsoft.com/.default` |

**Exemple PowerShell (MSAL) :**

```powershell
$tenantId     = "<tenant-guid>"
$clientId     = "<app-guid>"
$clientSecret = "<secret>"

$body = @{
  client_id     = $clientId
  client_secret = $clientSecret
  grant_type    = "client_credentials"
  scope         = "https://api.fabric.microsoft.com/.default"
}

$token = (Invoke-RestMethod `
  -Method POST `
  -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
  -Body $body).access_token

$headers = @{ Authorization = "Bearer $token" }

Invoke-RestMethod -Headers $headers `
  -Uri "https://api.fabric.microsoft.com/v1/admin/workspaces?type=Workspace"
```

**Exemple Python :**

```python
import msal, requests

app = msal.ConfidentialClientApplication(
    client_id, authority=f"https://login.microsoftonline.com/{tenant_id}",
    client_credential=client_secret)

token = app.acquire_token_for_client(
    scopes=["https://api.fabric.microsoft.com/.default"])["access_token"]

r = requests.get(
    "https://api.fabric.microsoft.com/v1/admin/workspaces",
    headers={"Authorization": f"Bearer {token}"})
print(r.json())
```

### 3.5 Endpoints fréquemment utilisés

#### Power BI Admin

| Endpoint | Usage |
|----------|-------|
| `GET /admin/groups` | Liste des workspaces |
| `POST /admin/workspaces/getInfo` | Scanner API — métadonnées détaillées (asynchrone) |
| `POST /admin/workspaces/modified` | Workspaces modifiés depuis X |
| `GET /admin/activityevents` | Audit (90 derniers jours) |
| `GET /admin/datasets`, `/reports`, `/dashboards` | Inventaire |
| `GET /admin/capacities` | Liste capacités |
| `POST /admin/groups/{id}/users` | Ajouter un user à un workspace (takeover) |

#### Fabric Admin

| Endpoint | Usage |
|----------|-------|
| `GET /v1/admin/workspaces` | Inventaire workspaces (Fabric + Power BI) |
| `GET /v1/admin/items?type=Lakehouse` | Tous les items d'un type |
| `GET /v1/admin/workspaces/{id}/users` | Permissions workspace |
| `GET /v1/admin/items/{id}/users` | Permissions item-level |
| `GET /v1/admin/domains` | Liste domaines |
| `POST /v1/admin/domains` | Créer un domaine |
| `GET /v1/admin/tenantsettings` | Lire les tenant settings |
| `GET /v1/admin/labels` | Sensitivity labels appliqués |
| `GET /v1/admin/externalDataShares` | Partages externes OneLake |

### 3.6 Limites et quotas

- **Throttling** : 200 req/h pour la plupart des Admin APIs en lecture.
- **Scanner API** : environ 500 workspaces par appel `getInfo`, max 16 appels parallèles.
- **Audit activityevents** : 200 appels/heure, fenêtre max 1 jour par appel, historique 90 jours.
- Toujours implémenter un **retry exponentiel** sur `429 Too Many Requests` (header `Retry-After`).

### 3.7 Outils prêts à l'emploi

| Outil | Description |
|-------|-------------|
| `MicrosoftPowerBIMgmt` (PowerShell) | `Connect-PowerBIServiceAccount -ServicePrincipal` puis `Invoke-PowerBIRestMethod`. |
| `Microsoft.PowerBI.Api` (.NET) | SDK officiel. |
| `msal` + `requests` (Python) | Pas de SDK officiel Python, utiliser `requests`. |
| Fabric CLI (`fab`) | Préfixe `fab admin ...` pour certaines opérations. |
| Microsoft Purview | Consomme les Admin APIs (Scanner) pour le catalogage. |

### 3.8 Bonnes pratiques sécurité

1. **Secrets dans Key Vault**, jamais dans le code.
2. Préférer **certificat** ou **Federated Identity Credentials** (workload identity) plutôt qu'un client secret.
3. **Restreindre les tenant settings** au groupe contenant le SP — pas à toute l'org.
4. **Conditional Access** : exiger une localisation/IP pour le service principal.
5. **Audit** : logger les appels via Entra ID sign-in logs + Purview unified audit log (`PowerBIAudit`).
6. **Rotation** des secrets (≤ 6 mois) et alerte sur expiration.
7. **Least privilege** : si seules les lectures sont nécessaires, activer uniquement *read-only admin APIs*.

### 3.9 Cas "admin par pays"

Pour donner aux admins d'un pays un accès Admin API limité à leur périmètre :

- **API au niveau Domain** : `GET /v1/admin/domains/{domainId}/workspaces` — un Domain Admin peut lister/gérer les workspaces de son domaine via les API Domain (sans être Fabric Admin global).
- **Service principal global + filtrage applicatif** : un SP global consomme les Admin APIs, puis votre middleware filtre par pays (basé sur le naming ou le domaine) avant d'exposer aux admins locaux.

Aujourd'hui, les Admin APIs globales (`/admin/*`) nécessitent toujours le rôle Fabric Administrator au niveau tenant — il n'y a pas de RBAC granulaire "Admin API scopé par domaine". Le filtrage doit donc se faire côté application.

## 3.10 Pattern fondamental — Déléguer la gestion d'accès via groupes Entra ID

Ce pattern est **le pilier de la gouvernance Fabric à l'échelle**. Il s'applique aux Admin APIs, aux tenant settings, aux rôles workspace, aux capacités et aux domaines.

### 3.10.1 Le problème à résoudre

Sans ce pattern, **chaque ajout/retrait d'un utilisateur** à une fonctionnalité Fabric impose au Fabric Admin de :

1. Ouvrir l'Admin portal.
2. Localiser le tenant setting concerné.
3. Modifier la liste des comptes autorisés.
4. Recommencer pour chaque autre setting concerné.

À 50, 500 ou 5 000 utilisateurs, cela devient ingérable, non auditable, et le Fabric Admin devient un goulot d'étranglement RH/IAM.

### 3.10.2 Le pattern recommandé

**Référencer uniquement des groupes de sécurité Entra ID** dans Fabric, **jamais des comptes individuels**. Le Fabric Admin n'intervient plus que pour configurer le **mapping setting → groupe** une seule fois. La gestion quotidienne du "qui a accès" est ensuite **entièrement pilotée au niveau Entra ID**, par les équipes IAM/RH/managers, **sans aucun droit sur Fabric**.

```
+----------------------------------------+
|   Fabric Tenant Settings (configuré    |
|   une seule fois par le Fabric Admin)  |
|                                        |
|   Setting "SP can use Fabric APIs"     |
|        -> grp-fabric-sp-api            |
|                                        |
|   Setting "Create workspaces"          |
|        -> grp-fabric-workspace-creators|
|                                        |
|   Setting "Publish to web"             |
|        -> grp-fabric-publish-web       |
+----------------+-----------------------+
                 |
                 v  (référence)
+----------------------------------------+
|     Entra ID Security Groups           |
|     (gestion délégée IAM/RH/manager)   |
|                                        |
|   grp-fabric-sp-api                    |
|     owner = Equipe Plateforme Data     |
|     membres = SP CI/CD + SP audit      |
|                                        |
|   grp-fabric-workspace-creators        |
|     owner = Lead Data FR/DE/ES         |
|     membres = data engineers          |
|                                        |
|   grp-fabric-publish-web               |
|     owner = DPO / Compliance           |
|     membres = utilisateurs autorisés   |
+----------------------------------------+
```

### 3.10.3 Bénéfices

| Bénéfice | Description |
|----------|-------------|
| **Single source of truth** | Entra ID devient la seule source d'autorisation. Plus de double-saisie. |
| **Pas de droit Fabric pour gérer les accès** | Les owners de groupes Entra ajoutent/retirent sans rôle Fabric Admin. |
| **Lifecycle automatisé** | Joiner/Mover/Leaver via Entra ID Lifecycle Workflows : un nouveau data engineer FR est automatiquement ajouté au bon groupe à son arrivée, retiré à son départ. |
| **Access Reviews** | Revues trimestrielles automatiques (PIM Access Reviews) : "tous les membres de `grp-fabric-publish-web` confirment leur besoin sous 14 j ou sont retirés". |
| **PIM (Privileged Identity Management)** | Activation just-in-time : un membre n'est admin Fabric que pour 4 h, sur demande approuvée, avec MFA. |
| **Audit centralisé** | Tous les changements de membership sont dans les Entra ID audit logs (`Add member to group`). |
| **Conditional Access** | Politiques d'accès conditionnel (MFA, IP, device compliant) appliquées au groupe. |
| **Dynamic groups** | Membership calculée automatiquement : `user.department -eq "Data Engineering FR"`. |
| **Provisioning RH** | Workday/SuccessFactors/SAP HR → Entra ID → Fabric. Aucune action manuelle. |
| **Délégation par pays** | Chaque pays a son owner de groupe sans toucher au tenant Fabric. |

### 3.10.4 Convention de nommage suggérée

Une convention claire évite l'explosion des groupes et facilite l'audit.

```
grp-fabric-<scope>-<role>[-<location>]
```

| Pattern | Exemple | Rôle |
|---------|---------|------|
| `grp-fabric-admin-tenant` | grp-fabric-admin-tenant | Fabric Administrators globaux |
| `grp-fabric-admin-domain-<pays>` | grp-fabric-admin-domain-fr | Domain Admins France |
| `grp-fabric-admin-capacity-<pays>` | grp-fabric-admin-capacity-fr | Capacity Admins France |
| `grp-fabric-sp-api-readonly` | grp-fabric-sp-api-readonly | SP pour lecture Admin APIs |
| `grp-fabric-sp-api-write` | grp-fabric-sp-api-write | SP pour écriture Admin APIs |
| `grp-fabric-sp-cicd-<env>` | grp-fabric-sp-cicd-prod | SP CI/CD par environnement |
| `grp-fabric-workspace-creators-<pays>` | grp-fabric-workspace-creators-fr | Création de workspaces FR |
| `grp-fabric-publish-web` | grp-fabric-publish-web | Autorisés à publier sur le web |
| `grp-fabric-export-data` | grp-fabric-export-data | Autorisés à exporter données |
| `grp-fabric-external-sharing` | grp-fabric-external-sharing | Partage avec externes B2B |
| `grp-fabric-copilot-users` | grp-fabric-copilot-users | Accès aux features Copilot |
| `grp-fabric-developer-mode` | grp-fabric-developer-mode | Mode développeur, .pbip, Git |

### 3.10.5 Tenant settings à câbler sur des groupes Entra

Les settings ci-dessous **doivent impérativement** être restreints à un groupe Entra (jamais "the entire organization") :

| Tenant setting | Groupe recommandé |
|---------------|-------------------|
| Service principals can use Fabric APIs | grp-fabric-sp-api |
| Service principals can access read-only admin APIs | grp-fabric-sp-api-readonly |
| Service principals can access admin APIs used for updates | grp-fabric-sp-api-write |
| Allow service principals to create and use profiles | grp-fabric-sp-profiles |
| Create workspaces (new workspace experience) | grp-fabric-workspace-creators |
| Allow Microsoft Entra B2B guest users to access Fabric | grp-fabric-b2b-allowed |
| Invite external users to your organization | grp-fabric-b2b-inviters |
| Share content with external users | grp-fabric-external-sharing |
| Publish to web | grp-fabric-publish-web |
| Allow specific users to turn on external data sharing | grp-fabric-external-data-shares |
| Export to Excel / CSV / PowerPoint / PDF | grp-fabric-export-data |
| Copilot and Azure OpenAI features | grp-fabric-copilot-users |
| Users can export items to Power BI Project files (.pbip) | grp-fabric-developer-mode |
| Users can synchronize workspace items with Git | grp-fabric-developer-mode |
| Embed content in apps | grp-fabric-embed |
| XMLA endpoints and Analyze in Excel | grp-fabric-xmla |
| Allow DirectQuery connections to Power BI datasets | grp-fabric-directquery |
| Users can apply sensitivity labels | grp-fabric-label-applier |
| Information protection / encryption | grp-fabric-mip |

### 3.10.6 Modèle de délégation des owners de groupes

Chaque groupe Entra a un (ou plusieurs) **owner** qui peut ajouter/retirer des membres sans aucun droit Fabric :

| Type de groupe | Owners suggérés | Justification |
|----------------|-----------------|---------------|
| `grp-fabric-admin-tenant` | Direction IT + sécurité | Approbation au plus haut niveau |
| `grp-fabric-admin-domain-<pays>` | Responsable Data pays | Décentralisation par pays |
| `grp-fabric-sp-*` | Équipe Plateforme Data | Maîtrise des SP et du CI/CD |
| `grp-fabric-publish-web` | DPO / Compliance | Risque RGPD/exposition publique |
| `grp-fabric-export-data` | Sécurité + DPO | Sensibilité des données |
| `grp-fabric-b2b-*` | Sécurité + Direction Légale | Contrats avec partenaires |
| `grp-fabric-copilot-users` | IA Officer + Compliance | Conformité IA / EU AI Act |
| `grp-fabric-workspace-creators-<pays>` | Lead Data pays | Connaissance des projets locaux |
| `grp-fabric-developer-mode` | Lead Engineering | Maîtrise du DevOps |

### 3.10.7 Groupes dynamiques (recommandé)

Pour les groupes dont l'appartenance est déterministe (lié au département, au pays, au job title), utiliser des **dynamic groups** Entra ID :

```
# grp-fabric-data-engineers-fr (dynamic)
(user.department -eq "Data Engineering") -and (user.country -eq "FR")

# grp-fabric-copilot-users (dynamic)
(user.extensionAttribute1 -eq "AI-approved") -and (user.accountEnabled -eq true)

# grp-fabric-workspace-creators-fr (dynamic)
(user.jobTitle -contains "Data") -and (user.officeLocation -eq "Paris")
```

Avantage : zéro action manuelle, la membership suit automatiquement la fiche utilisateur (mise à jour par RH).

### 3.10.8 Combiner avec Privileged Identity Management (PIM)

Pour les rôles sensibles (Fabric Administrator, Capacity Admin, accès SP write APIs), activer le groupe via **PIM for Groups** :

- L'utilisateur n'est **pas** membre permanent.
- Il **active** son appartenance pour une durée limitée (1 à 8 h).
- L'activation peut nécessiter : justification, MFA, approbation, ticket.
- Toutes les activations sont auditées.

```
Utilisateur ──► Demande PIM "grp-fabric-admin-tenant" pour 4h
                ├── Justification : "Incident INC0042"
                ├── MFA challenge
                ├── Approbation : Manager + Sécurité
                └── Active → membre 4h → expire automatiquement
```

### 3.10.9 Procédure de mise en place

1. **Inventaire** des tenant settings à configurer (cf. tableau 3.10.5).
2. **Création des groupes Entra** suivant la convention de nommage.
3. **Affectation des owners** (par groupe).
4. **Configuration unique** dans Admin portal : chaque setting → "Apply to specific security groups" → coller le groupe.
5. **Documentation** : page wiki listant `setting → groupe → owner → cas d'usage`.
6. **PIM** activé sur les groupes admin sensibles.
7. **Access Reviews** trimestriels sur les groupes "permissifs" (publish-web, export-data, b2b, copilot).
8. **Lifecycle Workflows** pour automatiser joiner/leaver.
9. **Audit** : alerte sur `Add member to group` pour les groupes admin (via Sentinel ou Logic App).

### 3.10.10 Anti-patterns à éviter

| À ne pas faire | Pourquoi |
|----------------|----------|
| Ajouter des comptes individuels directement aux tenant settings | Maintenance impossible, pas d'audit, le Fabric Admin devient un goulot |
| Utiliser "The entire organization" sur les settings sensibles | Risque RGPD, surface d'attaque maximale |
| Un seul méga-groupe `grp-fabric-all-permissions` | Pas de séparation des privilèges, pas de moindre privilège |
| Groupes nommés `groupe1`, `test-fabric`, `fabric-admin-2024-temp` | Pas de convention = perte de traçabilité |
| Owners = "IT générique" sans responsable identifié | Personne ne gouverne, les accès s'accumulent |
| Pas de date d'expiration ni d'Access Review | Accès "fantômes" qui survivent au turnover |
| Service principals membres permanents de groupes admin | Devrait passer par PIM aussi, ou par un groupe distinct read-only |
| Référencer un groupe Entra non monitoré dans l'audit | Une modification du groupe = changement Fabric invisible |

\newpage

## Section 4 — Délégation des tenant settings

### 4.1 Mécanique de délégation

- **Admin portal → Tenant settings** : certains paramètres affichent une case **Delegate to capacity admins** et/ou **Delegate to domain admins**.
- Une fois délégué, le Capacity/Domain Admin voit le paramètre dans son panneau (Capacity settings ou Domain settings) et peut l'activer/désactiver pour son scope, le restreindre à un groupe.
- La délégation est **descendante et restrictive** : le Fabric Admin pose un plafond, les admins inférieurs peuvent durcir mais pas relâcher.

### 4.2 Tenant settings délégables (Capacity et Domain)

| Catégorie | Tenant setting | Capacity | Domain |
|-----------|----------------|----------|--------|
| Help and support | Publish "Get Help" information | Oui | Oui |
| Workspace settings | Create workspaces (new workspace experience) | Oui | Oui |
| Workspace settings | Use datasets across workspaces | Oui | Oui |
| Workspace settings | Block users from reassigning personal workspaces | Oui | Oui |
| Export and sharing | Allow Entra ID guest users to access Fabric | Oui | Oui |
| Export and sharing | Invite external users to your organization | Oui | Oui |
| Export and sharing | Share content with external users | Oui | Oui |
| Export and sharing | Publish to web | Oui | Oui |
| Export and sharing | Copy and paste visuals | Oui | Oui |
| Export and sharing | Export to Excel / CSV / PowerPoint / PDF / images | Oui | Oui |
| Export and sharing | Print dashboards and reports | Oui | Oui |
| Export and sharing | Allow live connections | Oui | Oui |
| Export and sharing | Email subscriptions | Oui | Oui |
| Export and sharing | Featured content | Oui | Oui |
| Export and sharing | Allow specific users to turn on external data sharing | Oui | Oui |
| Discovery | Make promoted / certified content discoverable | Oui | Oui |
| Discovery | Discover content | Oui | Oui |
| Information protection | Allow users to apply sensitivity labels | Oui | Oui |
| Insights | Usage metrics for content creators | Oui | Oui |
| Insights | Per-user data in usage metrics | Oui | Oui |
| Content pack and apps | Publish / push apps to the entire organization | Oui | Oui |
| Integration settings | XMLA endpoints and Analyze in Excel | Oui | Oui |
| Integration settings | Use ArcGIS Maps for Power BI | Oui | Oui |
| Integration settings | Allow DirectQuery to Power BI datasets | Oui | Oui |
| R & Python visuals | Interact with and share R / Python visuals | Oui | Oui |
| Audit and usage | Create audit logs for internal activity auditing | Oui | Oui |
| Dashboard | Data classification for dashboards | Oui | Oui |
| Developer | Embed content in apps | Oui | Oui |
| Developer | Allow service principals to use Power BI APIs | Oui | Oui |
| Dataflows | Create and use dataflows | Oui | Oui |
| Datamarts | Create datamarts (Preview) | Oui | Oui |
| Template apps | Publish / install / create template apps | Oui | Oui |
| Q&A | Q&A in the new reading experience | Oui | Oui |
| OneLake | Users can access OneLake data with apps external to Fabric | Oui | Oui |
| Copilot | Copilot and Azure OpenAI features | Oui | Oui |
| Copilot | Data sent to Azure OpenAI can be processed outside region | Oui | Oui |
| Git integration | Synchronize workspace items with Git repositories | Oui | Oui |
| Git integration | Export items to Power BI Project files (.pbip) | Oui | Oui |

### 4.3 Settings délégables uniquement aux Domain Admins

| Catégorie | Tenant setting |
|-----------|----------------|
| Endorsement | Certification — qui peut certifier du contenu |
| Endorsement | Promote content |
| Discovery | Featured content (qui peut featurer du contenu dans OneLake catalog) |

Ces trois settings sont **les plus utiles à déléguer à un Domain Admin** par pays/BU : chaque domaine peut certifier/promouvoir son propre contenu sans intervention de l'équipe centrale.

### 4.4 Settings non délégables

Réservés au Fabric Admin / tenant uniquement :

- Service principals can access admin APIs.
- Allow Entra B2B guest users access to Fabric (paramètre racine).
- Customer-managed keys (BYOK).
- Auto-install Power BI app for Microsoft Teams.
- Allow connections to on-prem data gateways.
- Tenant-level audit log activation.
- Block public internet access.
- Trial / free license auto-provisioning.
- La plupart des paramètres **security-critical** (private links, IP allowlists, MFA enforcement).

### 4.5 Procédure d'activation

1. **Admin portal → Tenant settings**.
2. Localiser le paramètre.
3. Activer le paramètre pour le tenant (sinon la délégation est inutile).
4. Cocher **Delegate to capacity admins** et/ou **Delegate to domain admins**.
5. Apply.
6. Côté Capacity Admin : **Admin portal → Capacity settings → \<ma capacité\> → Delegated tenant settings**.
7. Côté Domain Admin : **Admin portal → Domains → \<mon domaine\> → Settings → Delegated settings**.

### 4.6 Recommandations pour le scénario "admin par pays"

Pour un Domain Admin pays, déléguer en priorité :

| Setting | Pourquoi |
|---------|----------|
| Certify / Promote / Featured content | Certification locale autonome |
| Export (CSV, Excel, PPT, PDF) | Conformité RGPD/locale par pays |
| Publish to web | Souvent à désactiver localement |
| External users / B2B sharing | Autoriser les partenaires locaux |
| Copilot & Azure OpenAI | Activer Copilot uniquement où la conformité est validée |
| OneLake external apps | Contrôle accès des outils tiers |
| Git integration | Mode DevOps pays par pays |
| Service principals can use Fabric APIs | Restriction au groupe SP local |

Pour un Capacity Admin pays, déléguer surtout :

- XMLA endpoints, DirectQuery, Dataflows, Datamarts.
- Export / sharing.
- Audit logs internes.

### 4.7 Audit via API

```text
GET https://api.fabric.microsoft.com/v1/admin/tenantsettings
GET https://api.fabric.microsoft.com/v1/admin/capacities/{capacityId}/delegatedTenantSettingOverrides
GET https://api.fabric.microsoft.com/v1/admin/domains/{domainId}/delegatedTenantSettingOverrides
```

### 4.8 Points d'attention

- La liste **évolue régulièrement** : vérifier la doc *Delegate Fabric settings to domain/capacity admins*.
- **Précédence** : si un setting est délégué à la fois au Capacity Admin et au Domain Admin et qu'un workspace est dans les deux, le réglage le plus **restrictif** s'applique.
- Un Domain/Capacity Admin **ne peut pas** activer un setting que le tenant a désactivé.
- Toute modification déléguée est tracée dans l'audit log (`UpdatedAdminFeatureSwitch`).

\newpage

## Section 5 — Logs d'utilisation et gouvernance

### 5.1 Sources de logs

| Source | Contenu | Rétention | Accès |
|--------|---------|-----------|-------|
| Microsoft 365 Unified Audit Log | Toutes activités utilisateurs/admins | 90 j (E3) / 1 an (E5) / 10 ans (add-on) | Compliance Center : rôle *Audit Logs* ou *Audit Reader* |
| Power BI / Fabric Activity Log | Sous-ensemble Fabric/Power BI du log M365 | 30 j (API) / 90 j (M365) | Fabric Admin via API ou portail |
| Capacity Metrics App | Consommation CU, throttling, opérations par item | 14 j détaillé / 30 j tendance | Capacity Admin / Fabric Admin |
| Workspace Usage Metrics (Power BI) | Vues, utilisateurs uniques, partages par rapport | 30 j rolling | Workspace Admin/Member/Contributor |
| Monitoring Hub | Exécutions Spark, pipelines, dataflows, refresh | 30 j | Selon rôle workspace |
| OneLake / Storage diagnostics | Lectures/écritures OneLake | Configurable | Fabric Admin + Azure Monitor |
| Purview Audit | Vue unifiée des logs | Selon licence Purview | Purview admin |
| Log Analytics workspace (par capacité) | Logs détaillés moteur AS / Semantic models | Configurable | Azure RBAC sur LA workspace |

### 5.2 Visibilité par rôle

#### Fabric Administrator (tenant)

- Activity log complet via API `GET /admin/activityevents`.
- Audit log M365 si rôle compliance approprié.
- Tous les Capacity Metrics.
- Tous les Usage Metrics workspace (via takeover si besoin).

#### Capacity Admin

- Capacity Metrics App pour sa capacité.
- Refresh history des datasets sur sa capacité.
- Pas d'accès à l'activity log tenant.
- Log Analytics si configuré pour sa capacité.

#### Domain Admin

- Vue de l'inventaire des items de son domaine (catalog/Hub).
- **Pas d'accès direct** à un "domain activity log" — il n'existe pas de filtre natif "audit log par domaine".
- Doit passer par une consommation custom (Fabric Admin export → filtrer par workspace → mapper au domaine).

#### Workspace Admin/Member

- Usage Metrics par rapport/dashboard.
- Monitoring Hub filtré sur son workspace.
- Refresh history de ses datasets.
- Pas d'accès à l'activity log tenant.

#### Utilisateur final (Viewer)

- Aucun accès aux logs.

### 5.3 Tenant settings liés aux logs

| Tenant setting | Capacity | Domain | Effet |
|----------------|----------|--------|-------|
| Create audit logs for internal activity auditing and compliance | Oui | Oui | Active/désactive l'envoi des logs Fabric vers M365 audit. |
| Usage metrics for content creators | Oui | Oui | Active la fonctionnalité Usage Metrics sur les rapports. |
| Per-user data in usage metrics | Oui | Oui | Affiche ou masque les identifiants des consommateurs (RGPD). |
| Azure Log Analytics connections for workspace administrators | Non | Non | Autorise les Workspace Admins à connecter leur workspace à un LA workspace. |
| Service principals can access read-only admin APIs | Non | Non | Conditionne l'accès programmatique aux Admin APIs. |

Les paramètres **Usage metrics for content creators** sont particulièrement utiles à déléguer aux Domain Admins par pays : chaque pays peut décider d'afficher ou non les noms des consommateurs (sensible RGPD).

### 5.4 APIs pour récupérer les logs

#### Activity Log (Power BI / Fabric)

```http
GET https://api.powerbi.com/v1.0/myorg/admin/activityevents
     ?startDateTime='2026-05-20T00:00:00'
     &endDateTime='2026-05-20T23:59:59'
```

- Rôle requis : Fabric Administrator ou SP avec *Service principals can access read-only admin APIs*.
- Limite : 1 jour par appel, 200 appels/h, 30 j de rétention.
- Renvoie : `UserId`, `Activity`, `WorkspaceId`, `ItemId`, `CapacityId`, `IP`, `SensitivityLabelId`.

#### Audit log M365

```powershell
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) `
  -RecordType PowerBIAudit -ResultSize 5000
```

- Rôle requis : *Audit Logs* (Exchange RBAC) ou *Audit Reader* (Purview).
- Rétention 90 j à 10 ans selon licence.
- `RecordType` : `PowerBIAudit`, `MicrosoftFabric`, `MicrosoftPurview`.

#### Capacity metrics

```http
GET /v1.0/myorg/admin/capacities/{capacityId}/refreshables
GET /v1.0/myorg/admin/capacities/{capacityId}/workloads
```

#### Log Analytics (Semantic Models)

À configurer dans **Admin portal → Tenant settings → Azure connections → Log Analytics**.

```kusto
PowerBIDatasetsWorkspace
| where TimeGenerated > ago(1d)
| where EventClass == "QueryEnd"
| summarize count(), avg(DurationMs) by Workspace, User
```

### 5.5 Architecture conseillée pour des logs par pays

Il n'existe pas de log scopé par domaine nativement. Pattern habituel :

```
Fabric Admin (SP global)
  +-- Pull horaire de l'Activity Log via API
       +-- Land dans un Lakehouse "audit-fabric"
            +-- Enrichissement : workspaceId -> domain -> pays
            +-- Sensitivity : pseudonymisation des UserId si besoin
            +-- Workspaces "audit-FR", "audit-DE" filtrés par pays
                 +-- Domain Admin pays = Viewer/Member
                      +-- Power BI report : activité, top users, exports
```

**Étapes clés :**

1. Service Principal "fabric-audit-collector" avec read-only admin APIs.
2. Notebook / pipeline Fabric déclenché toutes les heures :
   - `Get-ActivityEvents` pour J-1.
   - Join avec `GET /v1/admin/workspaces` → `domainId` → table de mapping pays.
3. Stocker dans un Lakehouse central + tables Delta partitionnées par `country`, `date`.
4. Row-Level Security sur le semantic model : `[Country] = USERPRINCIPALNAME() -> mapping`.
5. Workspace pays (`ws-FR-audit`) avec un rapport Power BI partagé aux Domain Admins locaux.

### 5.6 Points d'attention

- **Rétention** : 30 j sur l'API Activity → archiver obligatoirement dans OneLake pour un historique long.
- **RGPD** : les logs contiennent UPN et IP → prévoir purge / pseudonymisation, et déclarer le traitement.
- **Pas de rétro-actif** : activer le setting *Create audit logs for internal activity* dès le départ.
- **Throttling** : implémenter retry + checkpoint (`continuationToken`).
- **Capacity Metrics App** : rétention 14/30 j figée — pas d'API pour l'historiser, dériver de l'Activity Log ou de Log Analytics.
- **Workspace Usage Metrics report** : dataset par workspace, propriétaire = créateur, non auditable centralement.

### 5.7 TL;DR

| Besoin | Solution |
|--------|----------|
| Audit complet tenant | Fabric Admin + Activity Log API / M365 Audit |
| Vue par capacité | Capacity Admin + Capacity Metrics App + Log Analytics |
| Vue par domaine/pays | Non natif → pipeline d'enrichissement Lakehouse + RLS |
| Vue par workspace | Workspace Admin + Usage Metrics + Monitoring Hub |
| Historisation > 30/90 j | Export régulier via SP vers OneLake |
| RGPD / pseudonymisation | Désactiver "Per-user data in usage metrics" pour les pays sensibles |
| Logs query engine | Connecter chaque workspace à Log Analytics |

\newpage

## Section 6 — Restreindre la création d'artefacts

### 6.1 Constat : pas de blocklist granulaire native

Microsoft Fabric ne propose pas aujourd'hui un tenant setting du type *"Disable Lakehouse creation for group X"*.

| Type d'item | Tenant setting dédié pour bloquer la création ? |
|-------------|--------------------------------------------------|
| Dataflow Gen1/Gen2 | Oui — *Create and use dataflows* (délégable) |
| Datamart | Oui — *Create datamarts (Preview)* (délégable) |
| Template apps | Oui — *Create / publish / install template apps* |
| Power BI projects (.pbip) | Oui — *Users can export items to Power BI Project files* |
| Workspaces | Oui — *Create workspaces (new workspace experience)* (délégable) |
| Personal/My workspace | Oui — *Block users from reassigning personal workspaces* |
| Lakehouse / Warehouse / KQL DB / Eventstream / Notebook / Pipeline / ML model / Real-Time dashboard / Mirrored DB | **Non — pas de tenant setting dédié** |

Pour les items Fabric "data engineering / data science", la création se contrôle indirectement.

### 6.2 Levier 1 — Désactiver les expériences Fabric pour un groupe

Tenant setting : **Users can create Fabric items** (anciennement *Enable Microsoft Fabric*).

- Scope : tenant entier.
- Restriction possible à un groupe Entra (apply to / except specific security groups).
- Effet : tout sauf Power BI est désactivé. L'utilisateur ne voit plus les boutons "+ New Lakehouse / Notebook / Warehouse".
- C'est le seul vrai interrupteur global pour empêcher la création d'items Fabric non-Power BI.

Limite : c'est "tout ou rien" — on ne peut pas dire "Lakehouse oui, Warehouse non".

### 6.3 Levier 2 — Rôle workspace insuffisant

Seuls Admin / Member / Contributor peuvent créer des items. Viewer ne peut rien créer.

Donner Viewer au lieu de Contributor empêche la création — mais alors plus rien ne peut être créé.

### 6.4 Levier 3 — Workloads désactivés sur la capacité

Au niveau Capacity Admin : **Admin portal → Capacity settings → \<ma capacité\> → Workloads**.

Workloads typiques :

- Data Engineering (Lakehouse, Notebook, Spark Job)
- Data Warehouse (Warehouse, SQL endpoint)
- Data Science (ML model, ML experiment)
- Real-Time Intelligence (KQL DB, Eventstream, Eventhouse)
- Data Factory (Pipeline, Dataflow Gen2)
- Power BI

Granularité : par workload (pas par item individuel), et par capacité (pas par utilisateur).

Sur les F SKU récents, la granularité est moins exposée qu'à l'époque P SKU.

### 6.5 Levier 4 — Pas de capacité Fabric assignée au workspace

Un workspace en Pro / PPU (pas sur capacité Fabric) ne permet que les items Power BI. Les items Fabric (Lakehouse, Warehouse, Notebook) sont bloqués automatiquement.

Très efficace pour les workspaces "BI only".

### 6.6 Levier 5 — Restriction de la création de workspaces

Tenant setting : **Create workspaces (new workspace experience)** (délégable Capacity et Domain).

Si l'utilisateur ne peut pas créer de workspace, il ne peut créer d'items que dans les workspaces existants où il a un rôle Contributor+.

### 6.7 Levier 6 — Sensitivity labels et Information Protection

- Sensitivity labels avec encryption : empêche la consommation, pas la création.
- Information Protection policies : peuvent bloquer le downgrade d'un label, l'export, le partage externe — mais pas la création d'un type d'item.

### 6.8 Levier 7 — Détection plutôt que prévention

Quand aucun levier natif ne convient :

1. **Activity Log** → événement `CreateLakehouse`, `CreateWarehouse`, `CreateKQLDatabase`, `CreateMLModel`.
2. **Logic App / Fabric pipeline** déclenchée par règle Sentinel ou query Log Analytics horaire.
3. Si item interdit détecté :
   - **DELETE via Admin API** : `DELETE /v1/admin/items/{itemId}` (rôle Fabric Admin).
   - Notification à l'utilisateur + ticket gouvernance.

Pattern "policy as code" — la seule façon d'avoir une liste noire par type d'item aujourd'hui.

Exemple KQL :

```kusto
PowerBIActivity
| where Activity in ("CreateLakehouse","CreateWarehouse")
| where UserId !in (allowlist)
```

### 6.9 Recommandations par cas d'usage

| Objectif | Levier recommandé |
|----------|-------------------|
| Bloquer toute création d'items Fabric pour un groupe (BI only) | Tenant setting *Users can create Fabric items* restreint au groupe |
| Bloquer Lakehouse mais autoriser Warehouse | Pas natif → workspaces gouvernés + Audit & suppression automatisée |
| Bloquer Dataflow Gen2 | Tenant setting *Create and use dataflows* |
| Bloquer Datamart | Tenant setting *Create datamarts (Preview)* |
| Empêcher création de workspaces | Tenant setting *Create workspaces* limité à un groupe d'admins |
| Limiter par pays | Domain Admin + workspaces sur capacité dédiée pays avec workloads filtrés + audit |
| Bloquer un workload entier sur une capacité | Capacity settings → Workloads → off |
| Cantonner des utilisateurs à Power BI | Pas dans workspaces sur capacité Fabric + setting off pour leur groupe |

### 6.10 Application au scénario "admin par pays"

Pour qu'un Domain Admin pays puisse interdire un type d'item localement :

1. **Capacité dédiée pays** → Capacity Admin pays désactive les workloads non autorisés.
2. **Tenant setting délégué** : Create and use dataflows, Create datamarts, Create workspaces.
3. **Pipeline de détection** scopé par domaine.
4. **Politique documentée** + sensitivity labels + endorsement.

### 6.11 Synthèse

Seuls Dataflow, Datamart, Template app, Workspace, Power BI Project et Fabric items (en bloc) peuvent être bloqués nativement via tenant settings. Pour interdire spécifiquement **Lakehouse, Warehouse, Notebook, KQL DB, ML model**, il faut combiner :

1. Désactiver le workload sur la capacité (granularité = catégorie d'items).
2. Sinon, accepter le "detect & remediate" : audit log → suppression automatisée.

\newpage

## Section 7 — Intégration CI/CD avec GitLab

### 7.1 État des lieux des connecteurs Git

| Fournisseur Git | Connexion native Fabric | Statut |
|----------------|------------------------|--------|
| Azure DevOps Repos | Oui | GA |
| GitHub (Cloud + Enterprise) | Oui | GA |
| **GitLab** (SaaS ou self-hosted) | **Non** | Non supporté |
| Bitbucket | Non | Non supporté |

Pour utiliser GitLab, il faut **piloter le déploiement via API** (Fabric REST APIs ou Deployment Pipelines) depuis un pipeline GitLab CI/CD, sans passer par "Source control" dans l'UI Fabric.

### 7.2 Architecture cible recommandée

```
Développeurs
   |  git push
   v
GitLab Repo (fabric-items/)
   |
   +-- .gitlab-ci.yml
   v
GitLab CI/CD Runner
   |
   +-- Auth Entra ID (Service Principal Fabric)
   +-- Appels Fabric REST API :
   |    - Create/Update Items (via "Definition" JSON)
   |    - Deployment Pipelines API
   |    - Notebook / Lakehouse / Pipeline / Semantic Model
   v
Fabric Workspaces (Dev -> Test -> Prod)
```

### 7.3 Que stocker dans GitLab

| Item | Format export |
|------|---------------|
| Notebook | `.ipynb` ou `.py` |
| Semantic model (Power BI) | dossier `.pbip` (TMDL) |
| Report Power BI | dossier `.Report/` (PBIR) |
| Data Pipeline (Data Factory) | JSON via API `GET /items/{id}` |
| Dataflow Gen2 | `mashup.pq` + metadata |
| Lakehouse | Metadata seulement |
| KQL Database | Script `.kql` |
| Eventstream | JSON |
| Environment (Spark) | YAML libs + JSON config |
| Warehouse | Scripts SQL DDL/DML |

**Structure de repo conseillée :**

```
fabric-items/
  +-- workspaces/
  |   +-- dev/
  |       +-- notebooks/
  |       +-- pipelines/
  |       +-- semanticmodels/
  |       +-- reports/
  +-- env/
  |   +-- dev.json
  |   +-- test.json
  |   +-- prod.json
  +-- scripts/
  |   +-- deploy.ps1
  |   +-- auth.ps1
  +-- .gitlab-ci.yml
```

### 7.4 Authentification depuis GitLab vers Fabric

#### Option A — Service Principal Entra ID

1. App registration dans Entra ID + client secret (ou certificat).
2. Activer dans Admin portal → Tenant settings :
   - *Service principals can use Fabric APIs* → groupe `grp-fabric-cicd`.
   - *Service principals can access read-only admin APIs* (si besoin).
3. Ajouter le SP comme Admin dans les workspaces cibles (dev/test/prod).
4. Stocker `TENANT_ID`, `CLIENT_ID`, `CLIENT_SECRET` dans GitLab → Settings → CI/CD → Variables (masked + protected).

#### Option B — Workload Identity Federation (recommandé, sans secret)

Depuis 2024, Entra ID supporte les Federated Credentials pour GitLab :

1. App Entra ID → Certificates & secrets → Federated credentials → Add → Other issuer.
2. **Issuer** : `https://gitlab.com` (ou URL self-hosted).
3. **Subject identifier** : `project_path:my-group/my-project:ref_type:branch:ref:main`.
4. **Audience** : `api://AzureADTokenExchange`.
5. Dans `.gitlab-ci.yml`, utiliser `id_tokens:` pour obtenir un JWT GitLab puis l'échanger contre un token Entra — aucun secret stocké.

### 7.5 Exemple `.gitlab-ci.yml`

```yaml
stages:
  - validate
  - deploy-dev
  - deploy-test
  - deploy-prod

variables:
  TENANT_ID: $AZURE_TENANT_ID
  CLIENT_ID: $AZURE_CLIENT_ID
  FABRIC_API: "https://api.fabric.microsoft.com/v1"

.fabric-auth: &fabric-auth |
  TOKEN=$(curl -s -X POST \
    "https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token" \
    -d "grant_type=client_credentials" \
    -d "client_id=${CLIENT_ID}" \
    -d "client_secret=${CLIENT_SECRET}" \
    -d "scope=https://api.fabric.microsoft.com/.default" | jq -r .access_token)

validate-pbip:
  stage: validate
  image: mcr.microsoft.com/dotnet/sdk:8.0
  script:
    - dotnet tool install -g Microsoft.AnalysisServices.Tabular.TMDLBuilder
    - find . -name "*.pbip" -exec tmdl validate {} \;

deploy-dev:
  stage: deploy-dev
  image: mcr.microsoft.com/azure-cli
  variables:
    WORKSPACE_ID: $DEV_WORKSPACE_ID
  script:
    - *fabric-auth
    - ./scripts/deploy.sh "$WORKSPACE_ID" "$TOKEN" "./workspaces/dev"
  only: [main]

deploy-test:
  stage: deploy-test
  image: mcr.microsoft.com/azure-cli
  variables:
    WORKSPACE_ID: $TEST_WORKSPACE_ID
  script:
    - *fabric-auth
    - ./scripts/deploy.sh "$WORKSPACE_ID" "$TOKEN" "./workspaces/dev"
    - |
      curl -X POST "$FABRIC_API/deploymentPipelines/$PIPELINE_ID/deploy" \
        -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
        -d '{"sourceStageId":"'$DEV_STAGE'","targetStageId":"'$TEST_STAGE'","note":"GitLab CI"}'
  when: manual

deploy-prod:
  stage: deploy-prod
  extends: deploy-test
  variables:
    WORKSPACE_ID: $PROD_WORKSPACE_ID
  when: manual
  only: [tags]
```

#### Avec Workload Identity Federation

```yaml
deploy-prod:
  id_tokens:
    AZURE_ID_TOKEN:
      aud: api://AzureADTokenExchange
  script:
    - |
      TOKEN=$(curl -s -X POST \
        "https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token" \
        -d "grant_type=client_credentials" \
        -d "client_id=${CLIENT_ID}" \
        -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
        -d "client_assertion=${AZURE_ID_TOKEN}" \
        -d "scope=https://api.fabric.microsoft.com/.default" | jq -r .access_token)
    - ./scripts/deploy.sh "$PROD_WORKSPACE_ID" "$TOKEN" "./workspaces/dev"
```

### 7.6 Script `deploy.sh` — appels Fabric REST API

```bash
WORKSPACE_ID=$1
TOKEN=$2
DIR=$3

for nb in $DIR/notebooks/*.ipynb ; do
  NAME=$(basename "$nb" .ipynb)
  PAYLOAD=$(base64 -w0 "$nb")

  curl -X POST "$FABRIC_API/workspaces/$WORKSPACE_ID/notebooks" \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d @- <<EOF
{
  "displayName": "$NAME",
  "definition": {
    "format": "ipynb",
    "parts": [
      { "path": "notebook-content.ipynb",
        "payload": "$PAYLOAD",
        "payloadType": "InlineBase64" }
    ]
  }
}
EOF
done
```

#### Endpoints utiles

| Endpoint | Usage |
|----------|-------|
| `POST /workspaces/{id}/items` | Créer n'importe quel item via `definition` |
| `POST /workspaces/{id}/items/{itemId}/updateDefinition` | Mettre à jour |
| `GET /workspaces/{id}/items/{itemId}/getDefinition` | Récupérer pour versionner |
| `POST /deploymentPipelines/{id}/deploy` | Promouvoir Dev→Test→Prod |
| `POST /workspaces/{id}/jobs/instances?jobType=Pipeline` | Déclencher un pipeline |

### 7.7 Outils et alternatives

| Outil | Description |
|-------|-------------|
| `fabric-cicd` (Microsoft, Python) | Bibliothèque officielle qui parse un repo et déploie via API. `pip install fabric-cicd`. |
| Fabric CLI (`fab`) | `fab import`, `fab export` pour scripter depuis GitLab Runner. |
| Power BI Deployment Pipelines | Création des stages dans Fabric, déclenchés depuis GitLab. |
| Tabular Editor 3 CLI | Déploiement de semantic models. |
| **Azure DevOps relais** | Workaround : miroir GitLab → Azure DevOps Repos, puis Fabric Git Integration native. |
| **GitHub relais** | Idem, miroir vers GitHub. |

#### Pattern miroir Azure DevOps

```yaml
mirror-to-azdo:
  script:
    - git clone --mirror $CI_REPOSITORY_URL repo.git
    - cd repo.git
    - git push --mirror "https://$AZDO_PAT@dev.azure.com/org/proj/_git/fabric-mirror"
```

Puis Fabric → workspace → Source control → Azure DevOps → branche `main`. Les Sync/Update se font dans Fabric UI.

### 7.8 Workflow Git recommandé

1. **Branche par feature** (`feature/<jira>`) avec MR.
2. **Branche `main`** protégée → déploie automatiquement vers workspace **Dev**.
3. **Tag `v1.x.x`** → déploie vers **Test** puis **Prod** (manuel approuvé).
4. **Deployment Pipelines Fabric** orchestrent la promotion entre stages (paramètres : connexion, capacity binding).
5. **MR review** : check de format `.pbip` / `.ipynb` + tests Pester / pytest sur scripts.

### 7.9 Points d'attention

- **Pas de Sync bidirectionnel** : avec GitLab, les modifications faites dans l'UI Fabric ne reviennent pas automatiquement vers le repo. Solution : `GET /items/{id}/getDefinition` régulier + commit auto, ou interdire les modifications UI en Prod (workspace Viewer pour les devs).
- **Secrets / connections** : ne pas commit les chaînes de connexion ; utiliser Variable Libraries Fabric (preview) ou paramètres de Deployment Pipelines.
- **Items non versionnables** : données Lakehouse, KQL data, refresh history, sensitivity labels appliqués → restent dans Fabric, pas Git.
- **Limites API** : 200 req/h sur certains endpoints admin ; batcher.
- **Compatibilité .pbip** : activer le tenant setting *Users can export items to Power BI Project files*.

### 7.10 Récapitulatif

| Approche | Effort | Bidirectionnel | Recommandé pour |
|----------|--------|----------------|------------------|
| GitLab CI + Fabric REST API | Moyen | Non (push only) | Production CI/CD scriptée |
| GitLab CI + `fabric-cicd` | Faible | Non | La plupart des cas |
| GitLab → Azure DevOps mirror + Fabric Git | Faible | Oui (côté ADO) | Si miroir toléré |
| GitLab CI + Deployment Pipelines API | Faible | Non | Promotion entre stages |
| GitLab manuel + export/import UI | Élevé | Manuel | Petits projets |

\newpage

## Annexe — Synthèse globale

### A.1 Capacités d'administration par rôle

| Capacité | Global Admin | Fabric Admin | Capacity Admin | Domain Admin | Workspace Admin |
|----------|:------------:|:------------:|:--------------:|:------------:|:---------------:|
| Configurer tenant settings | Oui | Oui | Délégué | Délégué | Non |
| Créer/supprimer capacités | Oui | Partiel | Non | Non | Non |
| Assigner workspaces à capacité | Oui | Oui | Oui | Non | Non (sauf admin) |
| Assigner workspaces à domaine | Oui | Oui | Non | Oui | Non |
| Lire Activity Log tenant | Oui | Oui | Non | Non | Non |
| Lire Capacity Metrics | Oui | Oui | Oui (sa capacité) | Non | Non |
| Voir contenu workspace | Via takeover | Via takeover | Non | Non | Oui |
| Gérer rôles workspace | Via takeover | Via takeover | Non | Non | Oui |
| Certifier du contenu | Oui | Oui | Si délégué | Si délégué | Non |
| Bloquer création items Fabric | Oui (tenant) | Oui (tenant) | Workload off | Si délégué | Via rôle Viewer |
| Accéder aux Admin APIs | Oui | Oui | Non | Domain APIs uniquement | Non |
| Configurer Git integration | Oui | Oui | Si délégué | Si délégué | Oui (workspace) |

### A.2 Checklist de mise en place "admin par pays"

1. Définir la liste des pays et la convention de nommage.
2. Créer les **groupes Entra ID** par pays (admins, contributors, viewers, SP CI/CD, SP audit, publishers, exporters, Copilot users…) et **affecter des owners métier** (lead data pays, DPO, sécurité).
3. **Câbler tous les tenant settings sensibles** sur ces groupes Entra (jamais sur des comptes individuels, jamais sur "the entire organization") — cf. Section 3.10.5.
4. Provisionner les capacités F SKU dans les régions cibles.
5. Créer les domaines Fabric et assigner les Domain Admins **via groupes Entra**.
6. Déléguer les tenant settings utiles (endorsement, export, Copilot, dataflows).
7. Créer les workspaces avec convention de nommage, assigner capacité + domaine, et **rôles via groupes Entra**.
8. Déployer le service principal CI/CD et activer les tenant settings associés (restreints au groupe `grp-fabric-sp-cicd-*`).
9. Activer **PIM for Groups** sur les groupes admin sensibles (`grp-fabric-admin-tenant`, capacity admin, SP write APIs).
10. Configurer **Access Reviews** trimestriels sur les groupes permissifs (publish-web, export-data, b2b, copilot).
11. Brancher **Entra ID Lifecycle Workflows** pour automatiser joiner/mover/leaver.
12. Mettre en place le pipeline d'audit Activity Log → Lakehouse par pays, et alertes sur `Add member to group` pour les groupes admin Fabric.
13. Documenter la politique de gouvernance (catalogue d'items autorisés, sensibilité, RLS, mapping setting → groupe → owner).

### A.3 Références utiles

- Microsoft Learn — *Fabric admin overview*
- Microsoft Learn — *Domains in Fabric*
- Microsoft Learn — *Delegate Fabric settings to domain or capacity admins*
- Microsoft Learn — *Fabric REST API reference*
- Microsoft Learn — *Power BI Admin REST API*
- Microsoft Learn — *Microsoft Entra ID groups management*
- Microsoft Learn — *Privileged Identity Management (PIM) for Groups*
- Microsoft Learn — *Entra ID Lifecycle Workflows*
- Microsoft Learn — *Entra ID Access Reviews*
- Microsoft Learn — *Dynamic membership rules for groups*
- GitHub — *microsoft/fabric-cicd*
- Microsoft Learn — *Git integration in Microsoft Fabric*
- Microsoft Learn — *Deployment pipelines in Microsoft Fabric*

---

*Document généré à partir d'une session d'échanges sur l'administration de Microsoft Fabric.*
