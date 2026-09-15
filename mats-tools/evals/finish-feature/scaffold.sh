#!/bin/bash
set -e
git init -q -b main
git config user.email eval@beispiel.de; git config user.name eval
git init -q --bare -b main .remote.git
printf ".remote.git\\n" >> .git/info/exclude
git remote add origin "$PWD/.remote.git"
printf '# Demo\n\nEin kleines Werkzeug.\n\n## Befehle\n\n- `demo hallo` — grüßt.\n' > README.md
git add -A; git commit -qm "feat: demo hallo"; git push -q -u origin main
printf '#!/bin/sh\ncase "$1" in hallo) echo Hallo;; tschuess) echo Tschüss;; esac\n' > demo.sh
