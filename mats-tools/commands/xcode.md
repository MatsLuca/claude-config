---
description: Öffnet das Xcode-Projekt (.xcworkspace bevorzugt, sonst .xcodeproj) aus dem aktuellen Verzeichnis in Xcode.
allowed-tools: Bash(find:*), Bash(open:*), Bash(pwd:*), Bash(ls:*)
---

Öffne das Xcode-Projekt des aktuellen Arbeitsverzeichnisses in Xcode.

## Vorgehen

Suche in **einem** Bash-Aufruf nach `.xcworkspace` und `.xcodeproj` Dateien (max. 3 Ebenen tief, ohne `build`, `DerivedData`, `node_modules`, `.git`, `Pods`):

```bash
find . -maxdepth 3 \( -name build -o -name DerivedData -o -name node_modules -o -name .git -o -name Pods \) -prune -o \( -name "*.xcworkspace" -o -name "*.xcodeproj" \) -print 2>/dev/null
```

## Auswahl

- **Genau ein Treffer** → direkt mit `open <pfad>` öffnen.
- **Mehrere Treffer**:
  - Bevorzuge `.xcworkspace` über `.xcodeproj` (CocoaPods/SPM-Workspaces erwarten das).
  - Bevorzuge flachere Pfade (weniger `/`) — typischerweise das Hauptprojekt im Wurzel-Ordner.
  - Bleibt es mehrdeutig: liste die Optionen kurz auf und frage den User welches geöffnet werden soll.
- **Kein Treffer**:
  - Falls `$ARGUMENTS` einen Pfad/Projektnamen enthält, gezielt danach suchen.
  - Sonst dem User melden, dass kein Xcode-Projekt im aktuellen Verzeichnis gefunden wurde.

## Öffnen

```bash
open "<gewählter pfad>"
```

Kurze Bestätigung melden (welche Datei geöffnet wurde), keine langen Erklärungen.
