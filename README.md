# Divers

## Contenu

- **MLinFabric.md** — Document de bonnes pratiques pour les ML Model Endpoints dans Microsoft Fabric
- **MLinFabric.pdf** — Version PDF avec diagrammes Mermaid rendus, table des matières et coloration syntaxique

## Générer le PDF

Le PDF est généré via **pandoc** avec un filtre Lua qui convertit les blocs Mermaid en images PNG via `mmdc`.

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