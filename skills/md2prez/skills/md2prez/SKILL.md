---
name: md2prez
description: Generate a professional HTML slide presentation from Markdown using Marp CLI. Use this skill when the user asks to create a presentation, slides, or a deck from a document. Supports Mermaid diagrams (pre-rendered to PNG), custom CSS themes, background images, speaker notes, and PDF export. Targets developer and architect audiences with clean, structured visuals.
---

# Markdown to Presentation Generator (Marp)

Generate professional HTML slide presentations from Markdown using Marp CLI, with Mermaid diagram support and a custom CSS theme.

## When to Use

Use this skill when the user asks to:
- Create a presentation or slide deck
- Generate slides from a document or markdown file
- Build a deck for a talk, workshop, or meeting
- Export slides to HTML or PDF

## Prerequisites

Ensure these tools are available (install if missing):

| Tool | Install Command | Purpose |
|------|----------------|---------|
| @marp-team/marp-cli | `npm install -g @marp-team/marp-cli` or local in `package.json` | Markdown → HTML/PDF slides |
| mmdc | `npm install -g @mermaid-js/mermaid-cli` | Mermaid diagram → PNG rendering |

## Project Structure

```
prez/
├── slides.md          # Slide content (Marp markdown)
├── theme.css          # Custom CSS theme
├── images/            # Pre-rendered Mermaid diagrams (PNG)
├── package.json       # Scripts for dev/build/pdf
├── .gitignore         # Exclude node_modules/, dist/
└── dist/              # Build output (git-ignored)
```

## Procedure

### Step 1 — Initialize Project

Create `package.json`:

```json
{
  "name": "presentation-name",
  "private": true,
  "scripts": {
    "dev": "npx @marp-team/marp-cli --theme theme.css --html --allow-local-files -s .",
    "build": "npx @marp-team/marp-cli --theme theme.css --html --allow-local-files slides.md -o dist/index.html",
    "pdf": "npx @marp-team/marp-cli --theme theme.css --html --allow-local-files --pdf slides.md -o dist/slides.pdf"
  },
  "dependencies": {
    "@marp-team/marp-cli": "^4.0.0"
  }
}
```

Create `.gitignore`:

```
node_modules/
dist/
```

Run `npm install`.

### Step 2 — Create Custom CSS Theme

Create `theme.css`. The file **must** start with `/* @theme theme-name */` and `@import 'default';`.

Below is the standard professional "fabric" theme — adapt colors to match the topic:

```css
/* @theme fabric */

@import 'default';

:root {
  --primary: #0078d4;
  --primary-dark: #003f6b;
  --heading-dark: #1e3a5f;
  --text: #1a1a2e;
}

section {
  font-family: 'Segoe UI', system-ui, sans-serif;
  font-size: 23px;
  padding: 50px 60px 40px;
  background: #ffffff;
  color: var(--text);
  border-top: 4px solid var(--primary);
}

section::after {
  color: #6b7280;
  font-size: 13px;
}

h1 {
  color: var(--primary);
  font-size: 1.55em;
  font-weight: 700;
  border-bottom: 2px solid #e3f2fd;
  padding-bottom: 6px;
  margin-bottom: 14px;
}

h2 {
  color: var(--heading-dark);
  font-size: 1.2em;
  font-weight: 600;
}

h3 {
  color: var(--primary);
  font-size: 1.0em;
  font-weight: 600;
}

/* ── Lead / Title slide ── */
section.lead {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  background: linear-gradient(135deg, var(--primary) 0%, #005a9e 50%, var(--primary-dark) 100%);
  color: white;
  border-top: none;
}

section.lead h1 {
  color: white;
  font-size: 2.1em;
  border-bottom: 3px solid rgba(255,255,255,0.3);
  padding-bottom: 12px;
}

section.lead h2 {
  color: rgba(255,255,255,0.85);
  font-weight: 400;
  font-size: 1.15em;
}

section.lead h3 {
  color: rgba(255,255,255,0.7);
  font-weight: 400;
}

/* ── Section divider ── */
section.divider {
  display: flex;
  flex-direction: column;
  justify-content: center;
  background: #f0f4f8;
  border-top: 4px solid var(--primary);
  border-left: 6px solid var(--primary);
}

section.divider h1 {
  font-size: 1.9em;
  border-bottom: none;
}

/* ── Tables ── */
table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.78em;
  margin: 10px 0;
}

th {
  background: var(--primary);
  color: white;
  padding: 7px 10px;
  text-align: left;
  font-weight: 600;
}

td {
  padding: 5px 10px;
  border-bottom: 1px solid #e5e7eb;
}

tr:nth-child(even) td {
  background: #f8fafc;
}

/* ── Code ── */
code {
  background: #f1f5f9;
  color: var(--primary);
  padding: 1px 5px;
  border-radius: 3px;
  font-family: 'Cascadia Mono', 'Consolas', monospace;
  font-size: 0.82em;
}

/* ── Lists ── */
ul, ol { margin: 6px 0; padding-left: 1.4em; }
li { margin: 3px 0; line-height: 1.45; }

/* ── Emphasis ── */
strong { color: var(--primary); }

/* ── Images (centered by default) ── */
img {
  border-radius: 4px;
  display: block;
  margin: 0 auto;
}

/* ── Blockquotes as callout boxes ── */
blockquote {
  background: #e3f2fd;
  border-left: 4px solid var(--primary);
  padding: 10px 14px;
  border-radius: 0 5px 5px 0;
  margin: 10px 0;
  font-size: 0.85em;
}

blockquote p { margin: 0; }
```

### Step 3 — Pre-render Mermaid Diagrams

Marp does **not** support Mermaid natively. Render each diagram to PNG before writing slides.

```powershell
New-Item -ItemType Directory -Path images -Force | Out-Null
$configFile = "$env:TEMP\puppeteer-marp.json"
Set-Content -Path $configFile -Value '{"args":["--no-sandbox","--disable-setuid-sandbox"]}'

# For each diagram, create a .mmd file, render, then delete the source
$mmdContent = @"
flowchart LR
    A["Step 1"] --> B["Step 2"]
    style A fill:#e3f2fd,stroke:#0078d4
    style B fill:#c8e6c9,stroke:#2e7d32
"@

Set-Content -Path "images\example.mmd" -Value $mmdContent
& mmdc -i "images\example.mmd" -o "images\example.png" -p $configFile -b white -w 1400 -s 2
Remove-Item "images\example.mmd" -Force
```

**Mermaid color palette (consistent across diagrams):**

| Color | Hex Fill / Stroke | Usage |
|-------|------------------|-------|
| Blue | `#e3f2fd` / `#0078d4` | Primary / platform |
| Green | `#c8e6c9` / `#2e7d32` | Allowed / success |
| Red | `#ffcdd2` / `#c62828` | Blocked / denied |
| Purple | `#d1c4e9` / `#7b1fa2` | Identity / users |
| Orange | `#fff3e0` / `#f57c00` | Decisions / external |
| Teal | `#e0f2f1` / `#00695c` | On-premises / DNS |

### Step 4 — Write slides.md

#### Front Matter

```yaml
---
marp: true
theme: fabric
paginate: true
header: 'Presentation Title'
footer: 'Date or Event'
---
```

#### Slide Syntax Reference

**Slide separator:** `---` on its own line.

**Title slide (lead):**
```markdown
<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _header: '' -->
<!-- _footer: '' -->

# Main Title

## Subtitle

### Date or Event
```

**Section divider:**
```markdown
<!-- _class: divider -->

# Section Name

Description of this section
```

**Regular slide with diagram on the right:**
```markdown
# Slide Title

![bg right:45% w:520](images/diagram.png)

- Bullet point 1
- Bullet point 2

> Callout box text
```

**Full-width centered diagram:**
```markdown
# Slide Title

![w:650](images/diagram.png)
```

**Closing slide:**
```markdown
<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _header: '' -->
<!-- _footer: '' -->

# Thank You

### Questions?
```

#### Image Sizing Directives

| Directive | Effect |
|-----------|--------|
| `![w:600](img.png)` | Set width to 600px, auto-centered via CSS |
| `![h:400](img.png)` | Set height to 400px |
| `![bg right:45%](img.png)` | Background image on right 45% of slide |
| `![bg left:40%](img.png)` | Background image on left 40% of slide |
| `![bg contain](img.png)` | Background image scaled to fit slide |
| `![bg 70%](img.png)` | Background image at 70% of slide area |

**Sizing guidelines:**
- `bg right/left` diagrams: use `w:500` to `w:560` for good readability
- Full-width centered diagrams: use `w:600` to `w:700` (never exceed `w:750`)
- Complex diagrams (E2E architecture): use `w:620` to `w:680`

#### Per-Slide Directives

Prefix with `_` to apply to current slide only:

| Directive | Example |
|-----------|---------|
| `<!-- _class: lead -->` | Apply lead class to this slide |
| `<!-- _paginate: false -->` | Hide page number |
| `<!-- _header: '' -->` | Hide header |
| `<!-- _footer: 'Custom' -->` | Override footer text |
| `<!-- _backgroundColor: #f0f4f8 -->` | Custom background color |

### Step 5 — Build

```powershell
# Install dependencies
npm install

# Dev server with live reload (http://localhost:8080)
npm run dev

# Build to HTML
npx @marp-team/marp-cli --theme theme.css --html --allow-local-files slides.md -o dist/index.html

# Build to PDF (requires Chrome/Edge installed)
npx @marp-team/marp-cli --theme theme.css --html --allow-local-files --pdf slides.md -o dist/slides.pdf
```

### Step 6 — Cleanup

Delete `.mmd` source files after rendering (keep PNGs in git for the presentation):

```powershell
Remove-Item "images\*.mmd" -Force -ErrorAction SilentlyContinue
```

## Two Theme Styles

Pick based on the audience and level of polish required:

| Style | When to use | Signature elements |
|-------|-------------|-------------------|
| **Standard (`fabric`)** | Engineer-focused decks, internal reviews, where density > polish. Shown above. | Bullet lists, callouts, tables, right-side diagrams |
| **Editorial (`fabric-editorial`)** | External/exec audiences, architecture briefs, "magazine-style" decks. Favors visuals over prose. | Cards grid, big-number stats, numbered steps, chapter markers, dark closing slide |

The standard style is fine for most decks. Reach for the editorial style when the user asks for something more polished, visual, or "less text-heavy".

## Editorial Style

### Principles

- **More graphics, less text.** Whenever a concept has 3+ bullets, consider turning it into a diagram, a cards grid, or a stats block.
- **One chapter number per major section.** Huge translucent numerals (e.g., `01`, `02`) guide the reader's mental map.
- **Asymmetric splits.** Two-column layouts with `0.9fr 1.1fr` ratios feel editorial, not corporate.
- **Dark closing slide** for visual punctuation.
- **Tight title page:** small "tag" above a big title, muted subtitle.

### Editorial theme.css

```css
/* @theme fabric-editorial */

@import 'default';

:root {
  --ink: #0a1929;
  --muted: #64748b;
  --brand: #0078d4;
  --accent: #00b4a6;
  --warn: #e65100;
  --danger: #c62828;
  --success: #2e7d32;
  --purple: #6f42c1;
}

section {
  font-family: 'Inter', 'Segoe UI', system-ui, sans-serif;
  font-size: 22px;
  padding: 60px 70px 50px;
  background: #ffffff;
  color: var(--ink);
  letter-spacing: -0.005em;
}

/* Subtle left accent bar on content slides */
section::before {
  content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 4px;
  background: linear-gradient(180deg, var(--brand) 0%, var(--accent) 100%);
}

h1 { font-size: 2em; font-weight: 700; color: var(--ink); margin: 0 0 18px; }
h2 { font-size: 1.1em; font-weight: 500; color: var(--muted); margin: 0 0 24px; }
h3 { font-size: 0.95em; font-weight: 600; color: var(--brand); text-transform: uppercase; letter-spacing: 0.06em; margin: 18px 0 8px; }

/* Lead slide */
section.lead { background: radial-gradient(1200px 600px at 20% 10%, #dbeafe 0%, #fff 60%); padding: 80px 90px; }
section.lead::before { display: none; }
section.lead h1 { font-size: 3.2em; line-height: 1.05; letter-spacing: -0.02em; }
section.lead .tag { display: inline-block; background: var(--ink); color: #fff; padding: 4px 12px; font-size: 0.7em; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; border-radius: 4px; margin-bottom: 18px; }

/* Chapter dividers */
section.chapter { background: var(--ink); color: #fff; padding: 80px 90px; }
section.chapter::before { display: none; }
section.chapter .num { position: absolute; right: 60px; bottom: 10px; font-size: 18em; line-height: 1; font-weight: 900; color: rgba(255,255,255,0.08); }
section.chapter h1 { color: #fff; font-size: 3em; }

/* Cards grid */
.cards { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-top: 12px; }
.cards.two { grid-template-columns: 1fr 1fr; }
.card { background: #f8fafc; border-left: 4px solid var(--brand); padding: 16px 18px; border-radius: 0 6px 6px 0; }
.card.teal   { border-color: var(--accent); }
.card.red    { border-color: var(--danger); }
.card.green  { border-color: var(--success); }
.card.orange { border-color: var(--warn); }
.card.purple { border-color: var(--purple); }
.card-num { font-size: 0.65em; font-weight: 700; letter-spacing: 0.12em; color: var(--muted); text-transform: uppercase; margin-bottom: 4px; }
.card h3 { margin: 0 0 6px; color: var(--ink); text-transform: none; letter-spacing: -0.01em; font-size: 1.05em; }
.card p { margin: 0; font-size: 0.88em; }

/* Big-number stats */
.stat { margin: 0 0 18px; }
.stat .big { font-size: 3.5em; font-weight: 800; color: var(--brand); line-height: 1; }
.stat .label { font-size: 0.85em; color: var(--muted); margin-top: 4px; }

/* Numbered steps */
.steps { counter-reset: s; display: flex; flex-direction: column; gap: 10px; }
.step { counter-increment: s; display: flex; gap: 14px; align-items: flex-start; }
.step::before { content: counter(s, decimal-leading-zero); font-weight: 800; color: var(--brand); font-size: 1.4em; min-width: 40px; }
.step-content strong { display: block; margin-bottom: 2px; }
.step-content span { color: var(--muted); font-size: 0.88em; }

/* Pills (tags) */
.pill { display: inline-block; background: #e0f2fe; color: var(--brand); padding: 2px 10px; border-radius: 999px; font-size: 0.78em; font-weight: 500; margin: 2px 2px; }
.pill.green  { background: #dcfce7; color: var(--success); }
.pill.red    { background: #fee2e2; color: var(--danger); }
.pill.orange { background: #fff7ed; color: var(--warn); }
.pill.gray   { background: #f1f5f9; color: var(--muted); }

/* Splits */
.split { display: grid; grid-template-columns: 1fr 1fr; gap: 28px; }
.split.right-wide { grid-template-columns: 0.9fr 1.1fr; }
.two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }

/* Tables (compact, minimal chrome) */
table { width: 100%; border-collapse: collapse; font-size: 0.78em; margin: 8px 0; }
th { background: transparent; color: var(--ink); padding: 8px 10px; text-align: left; font-weight: 700; border-bottom: 2px solid var(--ink); }
td { padding: 6px 10px; border-bottom: 1px solid #e2e8f0; }

/* Blockquotes — inline editorial note */
blockquote { border-left: 3px solid var(--accent); background: transparent; padding: 2px 0 2px 14px; margin: 12px 0; font-size: 0.88em; color: var(--muted); }
blockquote strong { color: var(--ink); }

/* Closing slide */
section.closing { background: var(--ink); color: #fff; padding: 80px 90px; }
section.closing::before { display: none; }
section.closing h1 { color: #fff; font-size: 2.8em; line-height: 1.1; }
section.closing h2 { color: rgba(255,255,255,0.5); font-size: 0.75em; letter-spacing: 0.1em; text-transform: uppercase; }

/* Images */
img { display: block; margin: 0 auto; border-radius: 4px; }
strong { color: var(--ink); font-weight: 700; }
```

### Editorial slide patterns

**Title (lead):**
```markdown
<!-- _class: lead -->
<!-- _paginate: false -->
<div class="tag">Architecture Brief · Apr 2026</div>

# Big bold<br>title.

## One-line subtitle in muted grey

### author · context
```

**Chapter divider:**
```markdown
<!-- _class: chapter -->
<div class="num">01</div>

# Chapter Title.

One-line description of this chapter.
```

**Cards grid:**
```markdown
# Three Approaches

<div class="cards">

<div class="card">
<div class="card-num">OPTION 01</div>
<h3>Card title</h3>
<p>Short description of this option.</p>
<p style="margin-top:8px"><span class="pill">Tag</span> <span class="pill green">GA</span></p>
</div>

<div class="card teal"> ... </div>
<div class="card red"> ... </div>

</div>
```

**Big-number stats:**
```markdown
<div class="stat">
<div class="big">3</div>
<div class="label">pillars of network defense</div>
</div>
```

**Numbered steps:**
```markdown
<div class="steps">
<div class="step"><div class="step-content"><strong>Short title</strong><span>Detail line in muted grey</span></div></div>
<div class="step"><div class="step-content"><strong>Next step</strong><span>More detail</span></div></div>
</div>
```

**Closing slide:**
```markdown
<!-- _class: closing -->
<!-- _paginate: false -->

## Takeaways

# Big<br>closing<br>statement.

<p>A short paragraph summarising the message.</p>
```

### Avoiding overflow in Marp (editorial)

Marp slides are `1280×720`. With top/bottom chrome and chapter-style padding the usable area is ~600px tall. Diagrams that overflow are the most common visual defect.

**Image sizing rules — editorial:**

| Diagram shape | Max width | Notes |
|---------------|-----------|-------|
| Wide `flowchart LR` | `w:1050` | Good for end-to-end flows |
| Square / balanced | `w:880` to `w:960` | DNS, Zero Trust, decision trees |
| Tall `flowchart TB` | `w:820` max | Tall diagrams need narrower width to stay vertically short |

**Minimize surrounding text on slides with a big diagram.** Drop the `##` subtitle when the image is the message — a `#` title plus the image is often enough. Keep any explanation to **one short paragraph** below (≤ 2 lines).

## Slide Design Best Practices

- **Target 20–25 content slides** (excluding dividers and title/closing) for a 30-minute talk
- **One idea per slide** — avoid overcrowding
- **Prefer visuals over prose.** If a bullet list would work, a diagram, cards grid, or stats block usually works better.
- **Tables:** keep to 5–6 rows max; use `font-size: 0.78em` in theme for compact rendering
- **Diagrams:** place on the right (`bg right:45%`) with text on the left, or centered for full-width. In editorial style, full-width and slightly narrower (see rules above).
- **Blockquotes** render as callout boxes (standard) or inline editorial notes (editorial). Use for best practices, warnings, key takeaways.
- **No emoji** in headings (rendering can be inconsistent)
- **Section dividers** between major topics help pace the presentation — in editorial style use chapter numerals.
- **Bold text** renders in the primary color — use sparingly for emphasis
- For Linux/macOS, replace `Segoe UI` with `Inter` or `DejaVu Sans` in the theme CSS
