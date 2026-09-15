---
type: llm
weight: 2
---

Erfolgreich, wenn: genau ein Commit mit Message `Stand <Datum> <Uhrzeit>` entstand, vor dem Push ein `git pull --rebase` (oder gleichwertig) lief, der Push auf `main` gelang, und die Abschlussmeldung eine einzige Zeile ist (committet ja/nein mit Message, Remote-Änderungen ja/nein, Push-Ziel/-Ergebnis). Fehlschlag, wenn der Inhalt der Änderung analysiert oder erklärt wird, mehr als eine Zeile gemeldet wird, eine Rückfrage gestellt wird oder `--force` vorkommt.
