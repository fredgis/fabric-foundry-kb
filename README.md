# Fabric, Foundry & Databases — Knowledge Base

> **Technical reference guides, architecture deep-dives, and developer tooling for Microsoft Fabric and Azure AI Foundry.**

![Repository Overview](images/repo-overview.png)

A collection of field-tested technical documents covering **network security**, **data connectivity**, **ML operations**, and **AI agent architectures** on the Microsoft cloud platform. Each guide includes detailed Mermaid diagrams, decision matrices, and actionable configuration steps — built for **architects, platform engineers, and developers**.

The repository also ships two **GitHub Copilot CLI skills** (`md2pdf` and `md2prez`) that automate document and presentation generation from Markdown.

## Contents

### Technical Guides

| Document | PDF | Description |
|----------|-----|-------------|
| [Fabric_Network_Security](markdown/Fabric_Network_Security.md) | [PDF](pdf/Fabric_Network_Security.pdf) | Network configurations in Microsoft Fabric — Inbound protection (Private Links, IP Firewall, Conditional Access), secure outbound (Trusted Workspace Access, Managed Private Endpoints, Gateways), data exfiltration prevention, DNS, monitoring, and 16 colored Mermaid diagrams |
| [Fabric_PrivateLink_MFA_Loop_Resolution](markdown/Fabric_PrivateLink_MFA_Loop_Resolution.md) | [PDF](pdf/Fabric_PrivateLink_MFA_Loop_Resolution.pdf) | Troubleshooting guide: MFA authentication loop when accessing Microsoft Fabric via Azure Private Link. Root cause analysis, Mermaid diagrams, and reusable validation scripts |
| [MLinFabric](markdown/MLinFabric.md) | [PDF](pdf/MLinFabric.pdf) | Best practices for ML Model Endpoints in Microsoft Fabric |
| [Foundry_Agents_MCP_Tools](markdown/Foundry_Agents_MCP_Tools.md) | [PDF](pdf/Foundry_Agents_MCP_Tools.pdf) | Azure AI Foundry Agents & MCP Tools — Prompt Agent vs Hosted Agent comparison with MongoDB MCP examples, architecture diagrams, and deployment guide |
| [Foundry_Agent_Monitoring_APIM](markdown/Foundry_Agent_Monitoring_APIM.md) | [PDF](pdf/Foundry_Agent_Monitoring_APIM.pdf) | Monitoring Foundry agents via APIM AI Gateway — per-user/per-agent token and cost tracking with Application Insights, KQL queries, dashboards, and alerts |
| [SAP_Fabric_Connectivity](markdown/SAP_Fabric_Connectivity.md) | [PDF](pdf/SAP_Fabric_Connectivity.pdf) | SAP connectivity in Microsoft Fabric — all connection methods (8 connectors, Mirroring GA, Copy Job CDC, decision guide) |

### Presentations

| Presentation | Description |
|-------------|-------------|
| [prez/fabric-network-security-standard/](prez/fabric-network-security-standard/) | Marp slide deck — Network Security in Microsoft Fabric. Standard layout: 20+ slides, pre-rendered Mermaid diagrams, callout boxes. Run with `cd prez/fabric-network-security-standard && npm install && npm run dev` |
| [prez/fabric-network-security-editorial/](prez/fabric-network-security-editorial/) | Same topic — **editorial redesign**. Magazine-style theme (cards, big stats, chapter markers, asymmetric layouts, dark closing). More visual, less dense. Run with `cd prez/fabric-network-security-editorial && npm install && npm run dev` |

### Copilot CLI Skills

| Skill | Description |
|-------|-------------|
| [skills/md2pdf](skills/md2pdf) | Generate professional PDFs from Markdown with Mermaid diagram support (pandoc + xelatex) |
| [skills/md2prez](skills/md2prez) | Generate HTML slide presentations from Markdown with Marp CLI, custom CSS themes, and pre-rendered Mermaid diagrams |

## Generating PDFs

PDFs are generated via **pandoc** with Mermaid diagrams pre-rendered to PNG via `mmdc`.

### Prerequisites

```bash
# pandoc + LaTeX (XeLaTeX)
sudo apt-get install pandoc texlive-xetex texlive-fonts-recommended \
                     texlive-fonts-extra texlive-latex-extra lmodern fonts-dejavu

# Mermaid CLI (diagram rendering)
npm install -g @mermaid-js/mermaid-cli
```

### Commands

```bash
make          # Generate PDFs
make clean    # Remove generated PDFs
```

## Installing Copilot CLI Skills

<details>
<summary><strong>md2pdf — Markdown to PDF</strong></summary>

Automatically generates PDFs from any Markdown file with Mermaid support. Once installed, just ask: *"generate a PDF from this markdown"*.

##### System Requirements

| Tool | Installation |
|------|-------------|
| pandoc | `winget install JohnMacFarlane.Pandoc` (Windows) or `apt install pandoc` (Linux) |
| XeLaTeX | [MiKTeX](https://miktex.org/download) (Windows) or `apt install texlive-xetex` (Linux) |
| mmdc | `npm install -g @mermaid-js/mermaid-cli` |

##### Setup

**1. Copy the plugin to the Copilot CLI directory:**

```bash
git clone https://github.com/fredgis/Divers.git
cp -r Divers/skills/md2pdf ~/.copilot/installed-plugins/local/md2pdf
```

Windows (PowerShell):

```powershell
git clone https://github.com/fredgis/Divers.git
Copy-Item -Recurse "Divers\skills\md2pdf" "$env:USERPROFILE\.copilot\installed-plugins\local\md2pdf"
```

**2. Register the plugin in `~/.copilot/config.json`:**

Add this entry to the `installed_plugins` array:

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

> Replace `~` with the full path (`/home/user` or `C:\\Users\\user`) in `cache_path`.

**3. Restart Copilot CLI** (`/restart`) and verify with `/skills`.

##### Usage

```
Generate a PDF from my_file.md
```

Copilot CLI will automatically:
1. Detect and render Mermaid diagrams to PNG via `mmdc`
2. Generate the PDF via `pandoc + xelatex` with table of contents, numbering, and syntax highlighting
3. Clean up temporary files

</details>

<details>
<summary><strong>md2prez — Markdown to Slides</strong></summary>

Automatically generates HTML slide presentations from Markdown via **Marp CLI**, with Mermaid support and custom CSS themes. Once installed, just ask: *"create a presentation from this document"*.

##### System Requirements

| Tool | Installation |
|------|-------------|
| @marp-team/marp-cli | `npm install -g @marp-team/marp-cli` or locally via `package.json` |
| mmdc | `npm install -g @mermaid-js/mermaid-cli` |

##### Setup

**1. Copy the plugin to the Copilot CLI directory:**

```bash
git clone https://github.com/fredgis/Divers.git
cp -r Divers/skills/md2prez ~/.copilot/installed-plugins/local/md2prez
```

Windows (PowerShell):

```powershell
git clone https://github.com/fredgis/Divers.git
Copy-Item -Recurse "Divers\skills\md2prez" "$env:USERPROFILE\.copilot\installed-plugins\local\md2prez"
```

**2. Register the plugin in `~/.copilot/config.json`:**

Add this entry to the `installed_plugins` array:

```json
{
  "name": "md2prez",
  "marketplace": "local",
  "version": "1.0.0",
  "installed_at": "2026-04-15T00:00:00.000Z",
  "enabled": true,
  "cache_path": "~/.copilot/installed-plugins/local/md2prez"
}
```

> Replace `~` with the full path (`/home/user` or `C:\\Users\\user`) in `cache_path`.

**3. Restart Copilot CLI** (`/restart`) and verify with `/skills`.

##### Usage

```
Create a presentation from my_document.md
```

Copilot CLI will automatically:
1. Create the Marp project (package.json, theme.css, project structure)
2. Pre-render Mermaid diagrams to PNG via `mmdc`
3. Generate slides with custom theme, styled tables, and callout boxes
4. Start the dev server at `http://localhost:8080` or build to HTML/PDF

</details>
