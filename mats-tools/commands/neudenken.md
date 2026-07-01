---
description: Denkt ein digitales System vom Zweck her neu — rekonstruiert belegt dessen Ziele, hinterfragt die Prämissen mit vollem Urteil und liefert eine Einschätzung, ob und wie tief sich ein Umbau lohnt — ohne selbst umzusetzen.
argument-hint: <optional: Ziel — Pfad oder Beschreibung; leer = aktuelles Verzeichnis>
allowed-tools: Bash(pwd), Bash(ls:*), Bash(find:*), Bash(git rev-parse:*), Bash(git log:*), Read, Glob, Grep
---

Du nimmst ein bestehendes digitales System — Code-Projekt, Wissenssystem, KI-Workflow, Ordnerstruktur, Second Brain — und denkst es von Grund auf neu: nicht *innerhalb* der bestehenden Prämissen verbessern, sondern die **Prämissen selbst** prüfen. Du änderst nichts am System; du lieferst eine Einschätzung.

Ziel: **$ARGUMENTS** (Pfad oder Beschreibung; leer = aktuelles Verzeichnis).

Wie du dabei vorgehst, entscheidest du selbst. Gesetzt sind nur drei Dinge:

1. **Zweck zuerst.** Bevor du irgendetwas bewertest, finde **belegt** heraus, wofür das System eigentlich da ist — aus seinen eigenen Quellen (README, CLAUDE.md, Einstiegspunkte, git-Historie), nicht geraten. Lies dabei ökonomisch: Übersicht zuerst, tief nur dort, wo die Prämissen hängen. Ist der Zweck nicht ableitbar, frag kurz nach, statt auf einer Vermutung zu bewerten.

2. **Gründlich durcharbeiten, mit vollem Urteil.** Geh die zentralen Design-Entscheidungen des Systems durch und frag bei jeder: Dient das dem Zweck — oder ist es Altlast, Gewohnheit, „so macht man das"? Was würde man heute ohne Altlast bauen? Nimm keinen Status quo als gegeben — aber trenne Wirkung von Geschmack: ein Befund zählt nur, wenn er **belegbar** aufs Ziel wirkt.

3. **Ausgabe so, dass Mats leicht entscheiden kann.** Kein festes Schema — wähle Form und Tiefe selbst, so kompakt und verständlich, wie es der Fall erlaubt. Am Ende muss klar sein: Was ist der Zweck, was hält stand, was nicht — und lohnt sich ein Umbau grundlegend, nur im Detail oder gar nicht. Ist das System gesund, sag das ehrlich und erfinde keine Eingriffe.

Du empfiehlst nur — die Umsetzung ist ein getrennter Schritt (danach gezielt umsetzen und z.B. mit `/finish` abschließen).
