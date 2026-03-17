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
