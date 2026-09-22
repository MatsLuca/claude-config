#!/bin/bash
set -e
printf '# CLAUDE.md — notizen (Projekt)\n\nNotizprojekt: ein Buch, Kapitel für Kapitel, je Kapitel eine Markdown-Datei. Gelesen wird am Handy.\n\n## Aktueller Stand (2026-08-01)\n\n- Kapitel 1 und 2 stehen.\n- [ ] Kapitel 3 skizzieren\n' > CLAUDE.md
printf '# Kapitel 1\n\nEs war einmal.\n' > kapitel1.md; printf '# Kapitel 2\n\nUnd dann.\n' > kapitel2.md
