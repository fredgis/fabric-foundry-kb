# Makefile – Génération du PDF depuis le Markdown avec rendu des diagrammes Mermaid
#
# Prérequis :
#   sudo apt-get install pandoc texlive-xetex texlive-fonts-recommended \
#                        texlive-fonts-extra texlive-latex-extra lmodern fonts-dejavu
#   npm install -g @mermaid-js/mermaid-cli
#
# Usage :
#   make          # Génère MLinFabric.pdf
#   make clean    # Supprime le PDF généré

SRC       = MLinFabric.md
OUT       = MLinFabric.pdf
FILTER    = filters/mermaid.lua
HEADER    = header.tex
ENGINE    = xelatex

# Pandoc flags
PANDOC_FLAGS = \
	--lua-filter=$(FILTER) \
	--pdf-engine=$(ENGINE) \
	--include-in-header=$(HEADER) \
	--toc \
	--toc-depth=3 \
	--number-sections \
	--highlight-style=tango \
	-V geometry:margin=2.5cm \
	-V fontsize:11pt \
	-V mainfont:"DejaVu Sans" \
	-V monofont:"DejaVu Sans Mono" \
	-V colorlinks:true \
	-V linkcolor:blue \
	-V urlcolor:blue \
	-V toccolor:black

.PHONY: all clean

all: $(OUT)

$(OUT): $(SRC) $(FILTER) $(HEADER)
	pandoc $(SRC) -o $(OUT) $(PANDOC_FLAGS)
	@echo "✅ $(OUT) généré avec succès"

clean:
	rm -f $(OUT)
