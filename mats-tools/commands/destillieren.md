---
description: Destilliert ein gewachsenes Wissenssystem — spürt veraltete/widersprüchliche Querverweise auf, heilt die Drift, verdichtet dann Redundanz und denkt Ordnerstrukturen neu. Strukturelle Eingriffe erst nach Plan-Zustimmung.
argument-hint: <optional: Fokusbereich — z.B. "Ordner Forschung" oder "Thema X wirkt widersprüchlich">
allowed-tools: Bash(pwd), Bash(echo:*), Bash(ls:*), Bash(find:*), Bash(stat:*), Bash(sort:*), Bash(git rev-parse:*), Bash(git mv:*), Bash(git rm:*), Bash(mkdir:*), Bash(mv:*), Bash(rm:*), Read, Edit, Write, Glob, Grep, AskUserQuestion
---

Du pflegst ein semantisches Wissenssystem — verschachtelte Ordner mit stark vernetzten Wissens-, Fakten-, Fragen- und Problem-Dateien. Solche Systeme erkranken auf zwei Arten: **Drift** (eine Erkenntnis ändert ein paar Dateien, die darauf verweisenden veralten unbemerkt → Widersprüche) und **Wucherung** (Redundanz, Zersplitterung, Ordnerstrukturen, die nicht mehr zum Inhalt passen). Du heilst beides in fester Reihenfolge — **erst Drift, dann Struktur** — und ziehst zum Schluss jeden Querverweis nach, damit der Pass keine neue Drift erzeugt.

Optionaler Fokus: **$ARGUMENTS**

**Token-effizient:** Erst billiges Skelett (Struktur + Verweis-Graph per Grep), Vollinhalt nur für Hotspots und den Fokusbereich nachladen. Niemals stumpf jede Datei tief lesen.

## Schritt 1 — System kartieren (eine Bash-Runde)

```bash
echo "=== WURZEL ===" && pwd && (git rev-parse --show-toplevel 2>/dev/null || echo "KEIN_REPO") && \
echo "=== KONTEXT ===" && (ls -1 CLAUDE.md README* 2>/dev/null || echo "(keiner)") && \
echo "=== STRUKTUR (Epoch + Bytes + Pfad, neueste zuerst) ===" && \
stat -c %Y . >/dev/null 2>&1 \
  && find . -type f \( -name '*.md' -o -name '*.txt' \) -not -path '*/.git/*' -exec stat -c '%Y %s %n' {} + | sort -rn \
  || find . -type f \( -name '*.md' -o -name '*.txt' \) -not -path '*/.git/*' -exec stat -f '%m %z %N' {} + | sort -rn
```

(Die `stat`-Probe wählt einmal die GNU- (Linux/Container) oder BSD-Variante (macOS) — beide liefern dasselbe Format.)

Das gibt dir Ordnerbaum, Dateigrößen und **Änderungsdaten** — letztere füttern die Hotspot-Auswahl in Schritt 3. Lies `CLAUDE.md`/Index gezielt, um die **beabsichtigte Konvention** des Systems zu verstehen (welcher Ordner wofür, wie verlinkt wird). Was schon im Kontext ist, nicht neu lesen.

Die `CLAUDE.md` selbst ist dabei Prüfobjekt: Wird sie in Schritt 4 umgebaut (Status verdichten, Ballast verschieben), gilt der Skill `claude-md` — Höhe (Router/Bereich/Projekt) und Checkliste von dort, Verlauf nach `HISTORIE.md`, nicht löschen.

## Schritt 2 — Fokus setzen

Ist `$ARGUMENTS` gesetzt, ist es deine Priorität: dort beginnst du, dort gewichtest du Befunde stärker — aber du ignorierst den Rest nicht. Ist es leer, ist es ein vollständiger Pflege-Pass über das ganze System.

## Schritt 3 — Verweis-Graph billig aufbauen

Statt alles zu lesen: per `Grep` die Vernetzung kartieren — Wikilinks (`[[…]]`), relative Pfade/Dateinamen, geteilte Schlüsselbegriffe/Überschriften. Daraus:
- **Hotspots** = zuletzt geänderte Dateien + alles, was auf sie verweist.
- **Tote Links** = Verweise auf Dateien/Anker, die es nicht (mehr) gibt.
- **Waisen** = Dateien, auf die nichts zeigt und die auf nichts zeigen.

## Schritt 4 — Befunde sammeln (Drift zuerst, dann Struktur)

**A — Drift / Inkonsistenz** (schützt die Wahrheit):
- Veraltete Verweise: Datei B referenziert einen Stand von A, den A nicht mehr hat.
- Widersprüche: zwei Dateien behaupten Unvereinbares über dasselbe.
- Tote/verwaiste Links aus Schritt 3.

**B — Wucherung / Redundanz** (verdichtet):
- Dubletten / Beinah-Dubletten — dieselbe Info mehrfach, leicht abweichend.
- Überzersplitterung — viele Mini-Dateien, die zusammengehören.
- Fehlplatzierung — Inhalt im falschen Ordner gemessen an der Konvention aus Schritt 1.
- Strukturbruch — die Ordnerhierarchie passt nicht mehr zum gewachsenen Inhalt (umformen, reduzieren, neu denken).

Jeder Befund braucht eine **konkrete Aktion** (zusammenführen X+Y→Z, verschieben A→Ordner B, löschen C, Verweis in D korrigieren) und eine kurze Begründung. Nichts erfinden, wo das System gesund ist — ehrlich melden, wenn wenig zu tun ist.

## Schritt 5 — Plan vorlegen, Zustimmung holen

Bevor du strukturell eingreifst (Vereinen, Verschieben, Löschen, Ordnerumbau): zeig den **Plan** in der Reihenfolge aus Schritt 4, jeweils Aktion + betroffene Dateien + erwartete Verweis-Updates. Hol das OK per `AskUserQuestion` — bei mehreren unabhängigen Eingriffen mit `multiSelect`, ein Eintrag pro Eingriff, damit der User selektiv zustimmen kann. Risikoarme Reinheilung (toter Link, eindeutiger Tippfehler im Verweis) darf ohne separate Rückfrage mitlaufen, aber kein Merge/Move/Delete ohne Zustimmung.

## Schritt 6 — Ausführen in fester Reihenfolge

1. **Drift heilen** — den aktuellen Stand in die abhängigen Dateien propagieren, Widersprüche zugunsten der belegten Fassung auflösen, tote Links reparieren oder entfernen.
2. **Verdichten & umbauen** — Dateien per `Edit`/`Write` zusammenführen (synthetisieren, nicht aneinanderkleben), verschieben und leere/tote Dateien entfernen (im Repo `git mv`/`git rm`, sonst `mv`/`rm` — gemäß `KEIN_REPO` aus Schritt 1), Ordner neu schneiden.
3. **Querverweise nachziehen (der entscheidende Loop)** — nach *jedem* Merge/Move/Delete: per `Grep` alle eingehenden Verweise auf den alten Pfad/Namen/Anker finden und auf das neue Ziel umbiegen. Eine Datei verschwindet erst, wenn nichts mehr auf sie zeigt.

## Schritt 7 — Gegenprüfen (bis sauber)

Verweis-Graph aus Schritt 3 neu ziehen: gibt es jetzt durch deine Eingriffe **neue** tote Links oder Waisen? Falls ja → zurück zu Schritt 6.3 und nachziehen. Erst wenn ein Durchlauf keine offenen Verweise mehr findet, ist der Pass fertig.

## Abschluss

Melde knapp:
- Zustand vorher → nachher (z.B. Dateien/Ordner-Zahl, gefundene vs. geheilte Drift-Stellen).
- Die wichtigsten Eingriffe (geheilt / vereint / verschoben / gelöscht) mit je einer Zeile Begründung.
- Was du bewusst **nicht** angefasst hast und warum — und falls Befunde offenblieben, was als Nächstes drankommt.
