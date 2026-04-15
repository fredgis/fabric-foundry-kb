# Divers

Collection de documents techniques et guides de troubleshooting.

## Contenu

| Document | Description |
|----------|-------------|
| **[Fabric_PrivateLink_MFA_Loop_Resolution.md](Fabric_PrivateLink_MFA_Loop_Resolution.md)** | Troubleshooting guide: MFA authentication loop when accessing Microsoft Fabric via Azure Private Link. Root cause analysis, Mermaid diagrams, and reusable validation scripts. |
| **[Fabric_PrivateLink_MFA_Loop_Resolution.pdf](Fabric_PrivateLink_MFA_Loop_Resolution.pdf)** | Version PDF avec diagrammes Mermaid rendus, table des matières et coloration syntaxique |
| **[MLinFabric.md](MLinFabric.md)** | Bonnes pratiques pour les ML Model Endpoints dans Microsoft Fabric |
| **[MLinFabric.pdf](MLinFabric.pdf)** | Version PDF avec diagrammes Mermaid rendus, table des matières et coloration syntaxique |
| **[Foundry_Agents_MCP_Tools.md](Foundry_Agents_MCP_Tools.md)** | Azure AI Foundry Agents & MCP Tools — Prompt Agent vs Hosted Agent comparison with MongoDB MCP examples, architecture diagrams, and deployment guide |
| **[Foundry_Agents_MCP_Tools.pdf](Foundry_Agents_MCP_Tools.pdf)** | Version PDF avec diagrammes Mermaid rendus, table des matières et coloration syntaxique |
| **[skills/md2pdf](skills/md2pdf)** | Copilot CLI skill — Génération de PDF depuis Markdown avec support Mermaid (pandoc + xelatex). Installable dans `~/.copilot/installed-plugins/` |
| **[Foundry_Agent_Monitoring_APIM.md](Foundry_Agent_Monitoring_APIM.md)** | Monitoring des agents Foundry via APIM AI Gateway — tracking per-user/per-agent des tokens et coûts avec Application Insights, KQL queries, dashboards et alertes |
| **[Foundry_Agent_Monitoring_APIM.pdf](Foundry_Agent_Monitoring_APIM.pdf)** | Version PDF avec diagrammes Mermaid rendus, table des matières et coloration syntaxique |
| **[SAP_Fabric_Connectivity.md](SAP_Fabric_Connectivity.md)** | SAP Connectivity in Microsoft Fabric -- toutes les méthodes de connexion SAP vers Fabric (8 connecteurs, Mirroring GA, Copy Job CDC, decision guide). Annonces Ignite 2025 et FabCon 2026 |
| **[SAP_Fabric_Connectivity.pdf](SAP_Fabric_Connectivity.pdf)** | Version PDF avec 5 diagrammes Mermaid couleur, page de titre, table des matières, callouts stylés |
| **[Fabric_Network_Security.md](Fabric_Network_Security.md)** | Network Configurations in Microsoft Fabric — Inbound Protection (Private Links tenant/workspace, IP Firewall, Conditional Access), Secure Outbound (Trusted Workspace Access, Managed Private Endpoints, Gateways), Outbound Protection (Data Exfiltration Prevention), decision guide and 16 colored Mermaid diagrams |
| **[Fabric_Network_Security.pdf](Fabric_Network_Security.pdf)** | PDF version with rendered Mermaid diagrams, table of contents and syntax highlighting |
| **[prez/](prez/)** | Slidev presentation — Network Security in Microsoft Fabric. Run with `cd prez && npm install && npm run dev`. Covers all topics from the Fabric_Network_Security document in 35+ slides with Mermaid diagrams. |

## Générer les PDFs

Les PDFs sont générés via **pandoc** avec un filtre Lua qui convertit les blocs Mermaid en images PNG via `mmdc`.

### Prérequis

```bash
# pandoc + LaTeX (XeLaTeX)
sudo apt-get install pandoc texlive-xetex texlive-fonts-recommended \
                     texlive-fonts-extra texlive-latex-extra lmodern fonts-dejavu

# Mermaid CLI (pour le rendu des diagrammes)
npm install -g @mermaid-js/mermaid-cli
```

### Commandes

```bash
make          # Génère MLinFabric.pdf
make clean    # Supprime le PDF généré
```

## Installer la skill md2pdf dans GitHub Copilot CLI

La skill `md2pdf` permet à Copilot CLI de générer automatiquement des PDFs depuis n'importe quel fichier Markdown avec support Mermaid. Une fois installée, il suffit de demander "génère un PDF de ce markdown" et Copilot invoque la skill.

### Prérequis système

| Outil | Installation |
|-------|-------------|
| pandoc | `winget install JohnMacFarlane.Pandoc` (Windows) ou `apt install pandoc` (Linux) |
| XeLaTeX | [MiKTeX](https://miktex.org/download) (Windows) ou `apt install texlive-xetex` (Linux) |
| mmdc | `npm install -g @mermaid-js/mermaid-cli` |

### Installation

**1. Copier le plugin dans le répertoire Copilot CLI :**

```bash
# Cloner ce repo (ou copier le dossier skills/md2pdf)
git clone https://github.com/fredgis/Divers.git
cp -r Divers/skills/md2pdf ~/.copilot/installed-plugins/local/md2pdf
```

Sur Windows (PowerShell) :

```powershell
git clone https://github.com/fredgis/Divers.git
Copy-Item -Recurse "Divers\skills\md2pdf" "$env:USERPROFILE\.copilot\installed-plugins\local\md2pdf"
```

**2. Enregistrer le plugin dans `~/.copilot/config.json` :**

Ajouter cette entrée dans le tableau `installed_plugins` :

```json
{
  "name": "md2pdf",
  "marketplace": "local",
  "version": "1.0.0",
  "installed_at": "2026-03-17T00:00:00.000Z",
  "enabled": true,
  "cache_path": "~/.copilot/installed-plugins/local/md2pdf"
}
```

> ⚠️ Remplacer `~` par le chemin complet (`/home/user` ou `C:\\Users\\user`) dans `cache_path`.

**3. Redémarrer Copilot CLI :**

```
/restart
```

**4. Vérifier :**

```
/skills
```

La skill `md2pdf` devrait apparaître dans la liste.

### Utilisation

Une fois installée, demandez simplement :

```
Génère un PDF de mon_fichier.md
```

Copilot CLI invoquera automatiquement la skill qui :
1. Détecte et rend les diagrammes Mermaid en PNG via `mmdc`
2. Génère le PDF via `pandoc + xelatex` avec table des matières, numérotation et coloration syntaxique
3. Nettoie les fichiers temporaires


