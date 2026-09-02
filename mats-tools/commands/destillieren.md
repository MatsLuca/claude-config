---
description: Destilliert ein gewachsenes Wissenssystem — spürt veraltete/widersprüchliche Querverweise auf, heilt die Drift, verdichtet dann Redundanz und denkt Ordnerstrukturen neu. Strukturelle Eingriffe erst nach Plan-Zustimmung.
argument-hint: <optional: Fokusbereich — z.B. "Ordner Forschung" oder "Thema X wirkt widersprüchlich">
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(find:*), Bash(stat:*), Bash(sort:*), Bash(git rev-parse:*), Bash(git mv:*), Bash(git rm:*), Bash(mkdir:*), Bash(mv:*), Bash(rm:*), Read, Edit, Write, Glob, Grep, AskUserQuestion, Skill
---

Du pflegst ein semantisches Wissenssystem — verschachtelte Ordner mit vernetzten Wissens-, Fakten-,
Fragen- und Problem-Dateien. Solche Systeme erkranken auf zwei Arten: **Drift** (eine Erkenntnis ändert
ein paar Dateien, die darauf verweisenden veralten unbemerkt → Widersprüche) und **Wucherung**
(Dubletten, Zersplitterung, Fehlplatzierung, Ordner, die nicht mehr zum Inhalt passen). Du heilst
beides — **erst Drift, dann Struktur** — und ziehst jeden Querverweis nach, damit der Pass keine neue
Drift erzeugt. Maßstab ist die **beabsichtigte Konvention** des Systems (welcher Ordner wofür, wie
verlinkt wird) aus `CLAUDE.md`/Index; was schon im Kontext ist, nicht neu lesen.

Optionaler Fokus: **$ARGUMENTS** — dort beginnst du und gewichtest stärker, ohne den Rest zu ignorieren;
leer = vollständiger Pass.

Wie du dir die Lage verschaffst, entscheidest du: billiges Skelett zuerst (Ordnerbaum, Größen,
**Änderungsdaten** — portabel, `stat -c` einmal proben, sonst `stat -f`; Repo ja/nein), dann per `Grep`
den Verweis-Graph (Wikilinks `[[…]]`, relative Pfade, geteilte Begriffe). Vollinhalt nur für
**Hotspots** (jüngste Dateien + alles, was auf sie zeigt), **tote Links** (Ziel/Anker fehlt), **Waisen**
(nichts zeigt hin, nichts zeigt weg) und den Fokus. Wenige Runden, unabhängige Aufrufe parallel.

## Regeln

- **Drift vor Struktur.** Erst veraltete Verweise, Widersprüche und tote Links heilen (Stand der
  jüngsten belegten Fassung propagieren, Widersprüche zu ihren Gunsten auflösen, tote Links reparieren
  oder entfernen) — dann erst Dubletten vereinen, Zersplittertes zusammenführen, Fehlplatziertes
  verschieben, Ordner neu schneiden.
- **Kein Merge/Move/Delete ohne Zustimmung.** Plan vorlegen — je Eingriff Aktion (`X+Y→Z`, `A→Ordner B`,
  `C löschen`), betroffene Dateien, erwartete Verweis-Updates, ein Satz Grund — und per
  `AskUserQuestion` (`multiSelect`, ein Eintrag pro Eingriff) freigeben lassen. Risikoarme Reinheilung
  (toter Link, eindeutiger Tippfehler im Verweis, Stand nachziehen) läuft ohne Rückfrage. Ist
  `AskUserQuestion` nicht verfügbar (nicht-interaktive Session): Drift heilen, den Plan in die Meldung
  schreiben, **nichts** Strukturelles ausführen.
- **Vereinen heißt synthetisieren**, nicht aneinanderkleben. Im Repo `git mv`/`git rm`, sonst `mv`/`rm`.
- **Querverweise nachziehen** nach *jedem* Merge/Move/Delete: alle eingehenden Verweise auf den alten
  Pfad/Namen/Anker per `Grep` finden und umbiegen. Eine Datei verschwindet erst, wenn nichts mehr auf
  sie zeigt. Fertig ist der Pass, wenn ein erneuter Verweis-Graph **keine neuen** toten Links oder
  Waisen zeigt — sonst weiter nachziehen.
- **`CLAUDE.md` ist Prüfobjekt**, aber beim Umbau (Stand verdichten, Ballast verschieben) gilt der Skill
  `claude-md`: Höhe und Checkliste von dort, Verlauf nach `HISTORIE.md`, nicht löschen.
- **Nichts erfinden.** Ist das System gesund, sag das — kein Eingriff um des Eingriffs willen.

## Meldung

Knapp: vorher → nachher (Dateien/Ordner, gefundene vs. geheilte Drift-Stellen); die wichtigsten Eingriffe
(geheilt / vereint / verschoben / gelöscht) mit je einer Zeile Grund; was du bewusst **nicht** angefasst
hast und warum; offen gebliebene Befunde als Plan für den nächsten Pass.
