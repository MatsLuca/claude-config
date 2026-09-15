#!/bin/bash
set -e
git init -q -b main
git config user.email eval@beispiel.de; git config user.name eval
git init -q --bare -b main .remote.git
printf ".remote.git\\n" >> .git/info/exclude
git remote add origin "$PWD/.remote.git"
printf '# CLAUDE.md — work (Projekt)\n\nNotizprojekt: ein Buch, Kapitel für Kapitel.\n\n## Aktueller Stand (2026-08-01)\n\n- Kapitel 1 steht in `kapitel1.md`.\n- [ ] Kapitel 2 schreiben\n' > CLAUDE.md
printf 'Kapitel 1\n' > kapitel1.md; printf 'Kapitel 2\n' > kapitel2.md
git add -A; git commit -qm "Kapitel 1+2"; git push -q -u origin main
