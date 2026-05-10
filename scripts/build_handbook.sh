#!/usr/bin/env bash
# Build the handbook into a single Markdown, then export DOCX + PDF.
#
# Requirements:
#   - pandoc        (brew install pandoc)        -> for .docx
#   - npx + node    (already available)          -> runs md-to-pdf for .pdf
#
# Output: dist/handbook.md, dist/handbook.docx, dist/handbook.pdf

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/handbook"
OUT="$ROOT/dist"
MD="$OUT/handbook.md"
DOCX="$OUT/handbook.docx"
PDF="$OUT/handbook.pdf"

AUTHOR_NAME="Rajeev Joshi"
GITHUB_USER="Rajeev02"
GITHUB_URL="https://github.com/Rajeev02"
GITHUB_PAGES="https://rajeev02.github.io"
LINKEDIN_URL="https://www.linkedin.com/in/rajeev-joshi/"

mkdir -p "$OUT"

# --- 1. Cover page + Table of Contents ---------------------------------------
cat > "$MD" <<EOF
---
title: "React Native Interview Prep — Handbook"
author: "${AUTHOR_NAME}"
date: "Generated build"
subtitle: "Senior & Staff Engineer Handbook"
toc: true
toc-depth: 2
numbersections: true
geometry: margin=1in
fontsize: 11pt
mainfont: "Helvetica"
monofont: "Menlo"
---

<div class="cover">
  <h1 class="cover-title">React Native Interview Prep</h1>
  <p class="cover-subtitle">Senior &amp; Staff Engineer Handbook</p>
  <p class="cover-author">${AUTHOR_NAME}</p>
  <ul class="cover-links">
    <li>Portfolio: <a href="${GITHUB_PAGES}">${GITHUB_PAGES}</a></li>
    <li>GitHub: <a href="${GITHUB_URL}">github.com/${GITHUB_USER}</a></li>
    <li>LinkedIn: <a href="${LINKEDIN_URL}">linkedin.com/in/rajeev-joshi</a></li>
  </ul>
</div>

# Table of Contents

EOF

# Build chapter order: natural numeric sort (S01..S31).
CHAPTERS=()
for f in $(ls "$SRC"/S*.md | sort); do
  CHAPTERS+=("$f")
done

# Append a clean Markdown index of every chapter (links to anchors).
for f in "${CHAPTERS[@]}"; do
  title="$(head -1 "$f" | sed -E 's/^#[[:space:]]*//')"
  # GitHub-style anchor: lowercase, spaces -> '-', strip non-alnum/dash.
  anchor="$(echo "$title" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9 -]//g' \
    | tr ' ' '-')"
  echo "- [${title}](#${anchor})" >> "$MD"
done

# --- 2. Concatenate all S*.md chapters --------------------------------------
# Each chapter starts on a new page via CSS (h1 { page-break-before: always }),
# so we don't need extra \newpage markers.
for f in "${CHAPTERS[@]}"; do
  name="$(basename "$f")"
  echo "Adding $name"
  {
    echo ""
    echo "<!-- ===== $name ===== -->"
    echo ""
    cat "$f"
    echo ""
  } >> "$MD"
done

echo "Combined Markdown -> $MD"

# --- 3. Build DOCX via pandoc -----------------------------------------------
if command -v pandoc >/dev/null 2>&1; then
  pandoc "$MD" \
    --from gfm \
    --to docx \
    --toc --toc-depth=2 \
    -o "$DOCX"
  echo "DOCX built  -> $DOCX"
else
  echo "WARN: pandoc not installed. Run: brew install pandoc"
fi

# --- 4. Build PDF via md-to-pdf (puppeteer, no LaTeX needed) -----------------
# md-to-pdf reads the Markdown and produces a styled PDF using headless Chromium.
CFG="$OUT/.md-to-pdf.config.json"
cat > "$CFG" <<'EOF'
{
  "stylesheet_encoding": "utf-8",
  "css": "body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;font-size:11pt;line-height:1.6;color:#1f2328;max-width:800px;margin:auto;} h1{border-bottom:2px solid #0969da;padding-bottom:6px;page-break-before:always;color:#0969da;} h1:first-of-type{page-break-before:avoid;} h2{border-bottom:1px solid #d0d7de;padding-bottom:4px;margin-top:1.6em;color:#24292f;} h3{margin-top:1.2em;color:#24292f;} a{color:#0969da;text-decoration:none;} a:hover{text-decoration:underline;} code,pre{font-family:Menlo,Consolas,monospace;font-size:9.5pt;} pre{background:#f6f8fa;padding:10px;border-radius:6px;overflow:auto;border:1px solid #d0d7de;} code{background:#eff1f3;padding:1px 4px;border-radius:3px;} table{border-collapse:collapse;width:100%;margin:1em 0;} th,td{border:1px solid #d0d7de;padding:6px 8px;text-align:left;font-size:10pt;} th{background:#f6f8fa;} blockquote{border-left:4px solid #0969da;color:#57606a;padding:6px 14px;background:#f6f8fa;margin:1em 0;border-radius:0 6px 6px 0;} ul,ol{padding-left:1.5em;} .cover{text-align:center;padding:120px 0 40px;page-break-after:always;} .cover-title{font-size:34pt;border:none;color:#0969da;margin:0 0 8px;page-break-before:avoid;} .cover-subtitle{font-size:14pt;color:#57606a;margin:0 0 60px;font-style:italic;} .cover-author{font-size:18pt;font-weight:600;color:#1f2328;margin:0 0 30px;} .cover-links{list-style:none;padding:0;font-size:11pt;line-height:2;} .cover-links a{color:#0969da;}",
  "pdf_options": {
    "format": "A4",
    "margin": { "top": "20mm", "right": "16mm", "bottom": "20mm", "left": "16mm" },
    "printBackground": true,
    "displayHeaderFooter": true,
    "headerTemplate": "<div style='font-size:8px;width:100%;text-align:center;color:#888;'>React Native Interview Prep — Rajeev Joshi · github.com/Rajeev02</div>",
    "footerTemplate": "<div style='font-size:8px;width:100%;text-align:center;color:#888;'><span class='pageNumber'></span> / <span class='totalPages'></span></div>"
  },
  "launch_options": { "args": ["--no-sandbox"] }
}
EOF

echo "Building PDF (downloads Chromium on first run, may take a while)..."
npx --yes md-to-pdf --config-file "$CFG" "$MD"
# md-to-pdf writes <input>.pdf next to the source, i.e. dist/handbook.pdf
echo "PDF built   -> $PDF"

echo ""
echo "Done. Files in $OUT:"
ls -lh "$OUT"
