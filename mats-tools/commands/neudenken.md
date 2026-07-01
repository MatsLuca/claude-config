---
description: Denkt ein beliebiges digitales System mit vollem Urteil neu: rekonstruiert dessen Ziele, hinterfragt Prämissen und Ansätze gegen diese Ziele und liefert einen priorisierten Aufwertungs-Plan — ohne selbst umzusetzen.
argument-hint: <optional: Ziel — Pfad oder Beschreibung; leer = aktuelles Verzeichnis>
allowed-tools: Bash(pwd), Bash(ls:*), Bash(find:*), Bash(git rev-parse:*), Bash(git log:*), Read, Glob, Grep
---

Du nimmst ein bestehendes digitales System — Code-Projekt, Wissenssystem, KI-Workflow, Ordnerstruktur, Second Brain — und denkst es von Grund auf neu: nicht *innerhalb* der bestehenden Prämissen optimieren, sondern die **Prämissen selbst** prüfen. Ausgangspunkt ist immer der **Zweck** des Systems, nie sein aktueller Zustand. Nimm keinen Status quo als gegeben — aber trenne echte Wirkung von Geschmack: ein Befund zählt nur, wenn er das System *messbar* näher an seine Ziele bringt. Du lieferst einen **Plan**; du setzt nichts um.

Optionales Ziel: **$ARGUMENTS**

**Token-effizient:** Erst die billige Übersicht (Struktur + autoritative Quellen), Vollinhalt nur für die Teile nachladen, die die Prämissen tragen. Nie stumpf jede Datei tief lesen.

## Schritt 1 — Ziel & Typ bestimmen (eine Bash-Runde)

`$ARGUMENTS` auflösen: Pfad → dieses System; Beschreibung → das gemeinte System im aktuellen Kontext; leer → aktuelles Verzeichnis. Dann eine billige Übersicht:

```bash
echo "=== WURZEL ===" && pwd && (git rev-parse --show-toplevel 2>/dev/null || echo "KEIN_REPO") && \
echo "=== AUTORITATIVE QUELLEN ===" && (ls -1 CLAUDE.md README* AGENTS* package.json 2>/dev/null || echo "(keine)") && \
echo "=== STRUKTUR (oberste Ebene) ===" && ls -1F
```

Daraus den **Typ** ablesen (Code-Projekt / Wissenssystem / KI-Workflow / Ordnerstruktur) — er bestimmt, woran du das System gleich misst.

Fertig-Kriterium: du weißt, welches System du vor dir hast und welchem Typ es entspricht.

## Schritt 2 — Zweck & Ziele rekonstruieren

Bevor du irgendetwas bewertest, rekonstruiere, wofür das System *eigentlich* da ist: Ziele, Nutzer, was es optimiert, welche Randbedingungen galten. Lies die autoritativen Quellen aus Schritt 1 gezielt (nicht alles), plus die Einstiegspunkte, an denen die zentralen Entscheidungen hängen. Leite die Ziele aus **Belegen** ab, rate sie nicht.

Fertig-Kriterium: du kannst die Ziele des Systems in 1-3 Sätzen benennen — belegt, nicht angenommen. Ohne klare Ziele keine Bewertung; ist der Zweck nicht ableitbar, frag kurz nach, was das System erreichen soll.

## Schritt 3 — Prämissen challengen (der Kern)

Das ist die eigentliche Arbeit — **offenes Feld**, kein festes Rezept. Geh die zentralen Design-Entscheidungen des Systems durch und frag bei jeder:

- **Stimmt die Prämisse noch?** Wurde sie für die Ziele gewählt — oder ist sie ein Artefakt alter Grenzen (Tool-, Zeit-, Wissens-, Aufwands-Limits), die heute nicht mehr gelten?
- **Dient der Ansatz dem Ziel?** Oder gibt es einen grundlegend anderen Weg, der dasselbe Ziel besser, einfacher oder robuster erreicht?
- **Was würde man heute ohne Altlast bauen?** Vom Zielbild rückwärts denken, nicht vom Ist-Zustand vorwärts.

Nutze dein volles Urteil — nimm nichts als „so macht man das" hin. Aber jeder Befund braucht eine **Wirkung aufs Ziel**; Änderung um der Änderung willen ist kein Befund.

Fertig-Kriterium: eine Befund-Liste, nach **Hebelwirkung** sortiert — je Befund: die hinterfragte Prämisse/der Ansatz, warum fragwürdig, der bessere Weg, die erwartete Wirkung aufs Ziel.

## Schritt 4 — Plan liefern (nicht umsetzen)

Leg das Ergebnis strukturiert vor:

```
## Ziele des Systems
<1-3 Sätze, belegt>

## Befunde (nach Hebelwirkung)
1. **<Prämisse/Ansatz>** — <warum fragwürdig> → <besserer Weg> · Wirkung: <…>
2. …

## Aufwertungs-Plan
- **Quick Wins:** <klein, risikoarm>
- **Umbau:** <größere Eingriffe, je mit Reihenfolge/Abhängigkeit>
- **Bewusst gelassen:** <was gesund ist oder sich nicht lohnt — mit Grund>
```

Du planst nur — die Umsetzung ist ein getrennter Schritt (danach gezielt umsetzen und z.B. mit `/finish` abschließen). Ist das System gesund und wenig zu tun, sag das ehrlich und erfinde keine Eingriffe.

Fertig-Kriterium: der User hat einen priorisierten Plan, den er ohne Rückfrage umsetzen (lassen) könnte.
