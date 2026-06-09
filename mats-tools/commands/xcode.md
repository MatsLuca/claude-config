---
description: Öffnet das Xcode-Projekt (.xcworkspace bevorzugt, sonst .xcodeproj) aus dem aktuellen Verzeichnis in Xcode.
argument-hint: <optional - Projektname oder Pfad, falls mehrdeutig>
allowed-tools: Bash(find:*), Bash(open:*)
---

Öffne das Xcode-Projekt des aktuellen Arbeitsverzeichnisses in Xcode.

## Schritt 1 — Suchen

Suche in **einem** Bash-Aufruf nach `.xcworkspace` und `.xcodeproj` (max. 3 Ebenen tief, ohne `build`, `DerivedData`, `node_modules`, `.git`, `Pods`; `.xcodeproj`-Bundles werden geprunt, damit ihr eingebettetes `project.xcworkspace` nicht fälschlich als Workspace-Treffer zählt):

```bash
find . -maxdepth 3 \( -name build -o -name DerivedData -o -name node_modules -o -name .git -o -name Pods \) -prune -o -name "*.xcodeproj" -prune -print -o -name "*.xcworkspace" -print 2>/dev/null
```

## Schritt 2 — Auswählen

- **Genau ein Treffer** → direkt öffnen (Schritt 3).
- **Mehrere Treffer**:
  - Nennt `$ARGUMENTS` einen Projektnamen/Pfad, wähle den passenden Treffer direkt.
  - Sonst: `.xcworkspace` über `.xcodeproj` bevorzugen (CocoaPods/SPM-Workspaces erwarten das), dann flachere Pfade (weniger `/`) — typischerweise das Hauptprojekt im Wurzel-Ordner.
  - Bleibt es mehrdeutig: Optionen kurz auflisten und den User fragen, welches geöffnet werden soll.
- **Kein Treffer**:
  - Nennt `$ARGUMENTS` einen Pfad/Projektnamen, gezielt danach suchen.
  - Sonst dem User melden, dass kein Xcode-Projekt im aktuellen Verzeichnis gefunden wurde.

## Schritt 3 — Öffnen

```bash
open "<gewählter pfad>"
```

Kurze Bestätigung melden (welche Datei geöffnet wurde), keine langen Erklärungen.
