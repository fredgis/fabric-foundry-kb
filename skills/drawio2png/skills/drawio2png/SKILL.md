---
name: drawio2png
description: Render a draw.io (.drawio) file to PNG without clipping. Use this skill whenever you need to export a draw.io diagram to PNG, ESPECIALLY for wide diagrams (multi-lane swimlanes, end-to-end architectures) where the draw.io desktop CLI clips elements beyond x≈1370px. Works by exporting to SVG (which is always complete) and rasterising it via Puppeteer.
---

# draw.io to PNG (clip-free)

Render any `.drawio` file to a PNG that includes the **entire** diagram, even when the content extends beyond the draw.io desktop CLI's PNG bounding-box bug (≈ x > 1370 px gets cropped).

## When to Use

Use this skill when the user asks to:
- Export a `.drawio` file to PNG
- Render a draw.io / mxGraph diagram for use in Markdown / PDF / slides
- Fix a clipped / truncated draw.io PNG export
- Generate a diagram image for a wide architecture (4+ lanes, multi-zone)

Always prefer this skill over a raw `drawio.exe -x -f png` call when the diagram is wider than ~1300 px or contains multiple swimlanes.

## The Bug This Skill Fixes

The draw.io desktop CLI (`drawio.exe -x -f png`) silently clips elements whose `x` coordinate exceeds roughly **1370 px**, producing a PNG that is **visually incomplete on the right side**. Lanes, nodes, and edges past that x-coordinate are cropped or missing entirely. The SVG export is unaffected — only PNG export is buggy.

**Workaround:** export to SVG (complete), then rasterise to PNG with Puppeteer.

## Prerequisites

| Tool | Install Command | Purpose |
|------|----------------|---------|
| draw.io Desktop | [https://github.com/jgraph/drawio-desktop/releases](https://github.com/jgraph/drawio-desktop/releases) | SVG export from `.drawio` |
| Node.js | `winget install OpenJS.NodeJS.LTS` | Run the Puppeteer renderer |
| Puppeteer | bundled with `@mermaid-js/mermaid-cli` (`npm install -g @mermaid-js/mermaid-cli`) — reuse via `NODE_PATH` | Headless Chromium for SVG rasterisation |

draw.io Desktop installs to: `C:\Program Files\draw.io\draw.io.exe` on Windows.

## Procedure

### Step 1 — Export the .drawio to SVG

The SVG export is always complete (no clipping bug):

```powershell
& "C:\Program Files\draw.io\draw.io.exe" -x -f svg INPUT.drawio
# → produces INPUT.svg next to the .drawio file
```

### Step 2 — Drop the renderer script next to the SVG

Save this as `svg2png.js`:

```javascript
const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
  const svgPath = path.resolve(process.argv[2]);
  const outPath = path.resolve(process.argv[3]);
  const scale = parseFloat(process.argv[4] || '2');
  let svg = fs.readFileSync(svgPath, 'utf8');
  // Force light scheme — drawio sometimes injects dark-mode hints
  svg = svg.replace(/color-scheme:[^;"]*;?/g, 'color-scheme: light only;');
  const m = svg.match(/viewBox="0 0 (\d+(?:\.\d+)?) (\d+(?:\.\d+)?)"/);
  const vw = parseFloat(m[1]);
  const vh = parseFloat(m[2]);
  const w = Math.ceil(vw * scale);
  const h = Math.ceil(vh * scale);
  const html = `<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;padding:0;background:white}svg{display:block}</style></head><body>${svg.replace(/<svg /, `<svg width="${w}" height="${h}" `)}</body></html>`;
  const tmp = path.join(__dirname, '_tmp.html');
  fs.writeFileSync(tmp, html);
  const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
  const page = await browser.newPage();
  await page.setViewport({ width: w, height: h, deviceScaleFactor: 1 });
  await page.goto('file:///' + tmp.replace(/\\/g, '/'));
  await new Promise(r => setTimeout(r, 800));
  await page.screenshot({ path: outPath, omitBackground: false, clip: { x: 0, y: 0, width: w, height: h } });
  await browser.close();
  fs.unlinkSync(tmp);
  console.log('OK', outPath, w + 'x' + h);
})().catch(e => { console.error(e); process.exit(1); });
```

### Step 3 — Render the SVG to PNG

Reuse the Puppeteer instance bundled with `@mermaid-js/mermaid-cli` (no extra install needed if mmdc is present):

```powershell
$env:NODE_PATH = "$env:APPDATA\npm\node_modules\@mermaid-js\mermaid-cli\node_modules"
node svg2png.js INPUT.svg OUTPUT.png 2
# Argument 3 = scale factor (2 = retina, 1 = native)
```

### Step 4 — Cleanup

```powershell
Remove-Item INPUT.svg, svg2png.js -Force -ErrorAction SilentlyContinue
```

## Verification

After rendering, **always view the PNG** to confirm no lanes, nodes, or edges are clipped. Compare the PNG width to `viewBox_width × scale`:

```powershell
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile((Resolve-Path "OUTPUT.png").Path)
"Width=$($img.Width) Height=$($img.Height)"
$img.Dispose()
```

If the dimensions match the SVG viewBox × scale, the export is complete.

## Options

- **Scale factor**: pass `1` for native, `2` for retina (default), `3` for poster prints
- **Background**: the renderer forces white; edit the inline `<style>` block to use `transparent` or another colour
- **Headless flag**: Puppeteer runs headless by default; for debugging add `headless: false` to `puppeteer.launch(...)`
- **Linux/macOS**: same workflow — replace `drawio.exe` with `drawio` (the Linux/macOS Desktop binary) and adjust `NODE_PATH` to your global npm location (`npm root -g`)

## When NOT to Use This Skill

- The diagram fits within ~1300 px wide — the standard `drawio.exe -x -f png -s 2 --crop -b 30` is faster and produces identical output
- The user only needs SVG (skip step 2-3, just keep the `.svg`)
- The user wants PDF — pass `-f pdf` to drawio CLI directly (no bbox bug for PDF)
