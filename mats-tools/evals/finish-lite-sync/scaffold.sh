#!/bin/bash
set -e
git init -q -b main
git config user.email eval@beispiel.de; git config user.name eval
git init -q --bare -b main .remote.git
printf ".remote.git\\n" >> .git/info/exclude
git remote add origin "$PWD/.remote.git"
printf 'Notiz\n' > notiz.md
git add -A; git commit -qm "Basis"; git push -q -u origin main
printf 'Neue Zeile\n' >> notiz.md
