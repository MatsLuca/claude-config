---
type: llm
weight: 2
---

Erfolgreich, wenn alles zutrifft: Es wurde genau ein Commit erzeugt, dessen Subject dem Conventional-Commits-Muster `type: beschreibung` folgt und der den Trailer `Co-Authored-By: Claude` trägt. Der Commit enthält nur `demo.sh` und `README.md` — die Änderungen der anderen Session (`skizze.md`, `halbfertig.py`, das schon gestagte `gestagt.txt`) sind nicht darin (kein `git add -A`/`git add .`, kein Commit ohne Pfadangabe bei fremd Gestagtem). Der Commit wurde gepusht. Die README wurde punktuell um den neuen Befehl `demo tschuess` ergänzt, nicht neu geschrieben. Die Abschlussmeldung ist knapp (Commit-Message, geänderte Doku, Push-Ergebnis), benennt die liegen gelassenen fremden Dateien und enthält keine langen Erklärungen. Kein `--force`, keine Rückfrage an den Nutzer.
