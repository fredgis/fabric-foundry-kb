---
name: md2pdf
description: Generate a PDF from a Markdown file with Mermaid diagram support. Use this skill when the user asks to convert markdown to PDF, generate a PDF, or export a document. Handles Mermaid diagrams by rendering them to PNG first, then uses pandoc + xelatex for professional PDF output with table of contents, syntax highlighting, and proper typography.
---

# Markdown to PDF Generator

Generate professional PDFs from Markdown files with full Mermaid diagram support.

## When to Use

Use this skill when the user asks to:
- Generate a PDF from a Markdown file
- Export a document to PDF
- Convert .md to .pdf
- Create a printable version of a document

## Prerequisites

Ensure these tools are available (install if missing):

| Tool | Install Command | Purpose |
|------|----------------|---------|
| pandoc | `winget install JohnMacFarlane.Pandoc` | Markdown → LaTeX → PDF |
| MiKTeX (xelatex) | Download from miktex.org, install with `--unattended` | LaTeX PDF engine |
| mmdc | `npm install -g @mermaid-js/mermaid-cli` | Mermaid diagram rendering |

MiKTeX installs to: `%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64\`

## Procedure

### Step 1 — Add MiKTeX to PATH

```powershell
$env:PATH = "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64;$env:PATH"
```

### Step 2 — Add YAML frontmatter for the cover page

The cover page renders **title + subtitle + date** when these three fields are present at the top of the markdown. **Always include all three** — the cover looks unbalanced if subtitle is missing.

```markdown
---
title: "Network Configurations in Microsoft Fabric"
subtitle: "Architecture, Security & Best Practices"
date: "April 2026"
---
```

- `title` is the big bold line at the top of the cover (and is also reused in the page footer).
- `subtitle` is the muted gray line just below the title.
- `date` is the small gray line at the bottom — typically the **month + year**, e.g. `April 2026`. Avoid full ISO dates on covers.
- The repo's `header.tex` defines a custom `\subtitle{...}` command that pandoc's default LaTeX template invokes automatically when the `subtitle:` YAML field is set — no extra CLI flag is needed.
- If you only set `title` + `date`, the cover shows just those two lines. **Don't forget the subtitle.**

### Step 3 — Render Mermaid Diagrams to PNG

Extract all ` ```mermaid ` code blocks, render each to PNG via mmdc, replace with image references:

```powershell
$md = Get-Content "INPUT.md" -Raw
$counter = 0
$newMd = $md
$regex = [regex]'```mermaid\r?\n([\s\S]*?)```'
$mermaidMatches = $regex.Matches($md)

foreach ($m in $mermaidMatches) {
    $counter++
    $inputFile = "$env:TEMP\mermaid-$counter.mmd"
    $outputFile = ".\mermaid-$counter.png"
    $configFile = "$env:TEMP\puppeteer.json"
    Set-Content -Path $configFile -Value '{"args":["--no-sandbox","--disable-setuid-sandbox"]}'
    Set-Content -Path $inputFile -Value $m.Groups[1].Value -NoNewline
    & mmdc -i $inputFile -o $outputFile -p $configFile -b white -w 1200 -s 2
    if (Test-Path $outputFile) {
        $newMd = $newMd.Replace($m.Value, "![Diagram $counter](mermaid-$counter.png)")
    }
}
Set-Content -Path "RESOLVED.md" -Value $newMd
```

### Step 4 — Generate PDF with pandoc + xelatex

```powershell
pandoc RESOLVED.md -o OUTPUT.pdf `
    --pdf-engine=xelatex `
    --shift-heading-level-by=-1 `
    --toc `
    --toc-depth=3 `
    --number-sections `
    --highlight-style=tango `
    -V geometry:margin=2.5cm `
    -V fontsize:11pt `
    -V mainfont:"Segoe UI" `
    -V monofont:"Cascadia Mono" `
    -V colorlinks:true `
    -V linkcolor:blue `
    -V urlcolor:blue `
    -V toccolor:black
```

> **Note on `--shift-heading-level-by=-1`:** Documents in this repo start their content at `##` (level 2) because `#` is reserved for the YAML-driven title. Without the shift, pandoc 3.6+ maps `##` to `\subsection`, producing TOC entries like `0.1`, `0.2`… Shifting by `-1` makes `##` become `\section`, restoring proper `1`, `2`, `3`… numbering.

### Step 5 — Cleanup

```powershell
Remove-Item ".\mermaid-*.png" -Force -ErrorAction SilentlyContinue
Remove-Item "RESOLVED.md" -Force -ErrorAction SilentlyContinue
```

## Options

- If the repo contains a `header.tex`, add `--include-in-header=header.tex` for custom styling
- If the repo contains a Lua filter (`filters/mermaid.lua`), try `--lua-filter=filters/mermaid.lua` first — fall back to the 2-step PNG approach if pandoc crashes
- For Linux/macOS, use `DejaVu Sans` / `DejaVu Sans Mono` fonts instead of Segoe UI / Cascadia Mono
- Emoji characters in headings won't render in xelatex PDF — shows as warnings but doesn't break the build
