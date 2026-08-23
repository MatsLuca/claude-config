---
name: pdf-unterschrift
description: Setzt eine digitale (gescannte/fotografierte) Unterschrift sauber auf ein PDF-Formular — Freistellen mit transparentem Hintergrund, exakte Positionierung, druckfestes Einbrennen. Nutzen, wenn ein PDF "unterschrieben" werden soll, ohne zu drucken/scannen.
---

# Digitale Unterschrift auf PDF setzen

Erprobter Weg (Behördenformular, 07/2026). Ziel: sieht aus wie echt aufs
Papier unterschrieben, druckt in jedem Viewer identisch.

**Umgebung:** venv unter `_lokal/venv` neben dieser Datei (pypdf, reportlab, pillow, numpy) —
anlegen/aktualisieren mit `setup.sh` (einmalig pro Rechner). Aufruf:
`~/.claude/skills/pdf-unterschrift/_lokal/venv/bin/python`. Fehlt das venv → `setup.sh` ausführen.

## 0. Vorhandenes prüfen

Erst nach einem bereits freigestellten Master suchen (`*_freigestellt.png`, typisch in
Stammunterlagen-/Assets-Ordnern) — Freistellung nur einmal pro Person machen, Ergebnis
als wiederverwendbaren Master neben das Foto legen. **Bekannte Master je Person stehen in
`_lokal/NOTIZEN.md`** (lokal, nicht versioniert — dort zuerst nachsehen).

**Kein Master, aber ein bereits signiertes PDF der Person vorhanden?** Dann steckt die
Unterschrift dort oft als eingebettetes Bild mit Alpha-Maske — schneller als jedes
Freistellen: `pdfimages -list datei.pdf` (Bild+`smask`-Paar suchen), `pdfimages -png`
extrahieren, dann `img.putalpha(mask)` → fertiges RGBA, nur noch auf BBox croppen (+12px).
Achtung: So gewonnene Signaturen können getippte Font-Unterschriften sein (so 07/2026 passiert) —
kein Handschrift-Ersatz; echte Handschrift kommt per Scan-Freistellung (Schritt 1 + Linienentfernung).

## 1. Freistellen (Foto/Scan → transparentes PNG)

Nur nötig, wenn Schritt 0 nichts liefert. Pillow allein reicht nicht — Papier-Grain
braucht den Dichte-Filter (numpy). Kern-Rezept:

```python
a = np.asarray(Image.open(FOTO).convert("RGB")).astype(float)
lum = 0.299*a[:,:,0] + 0.587*a[:,:,1] + 0.114*a[:,:,2]
ink = lum < 125                                   # Tinten-Kandidaten
dens = np.asarray(Image.fromarray((ink*255).astype(np.uint8))
                  .filter(ImageFilter.BoxBlur(3)))/255.0
keep = ink & (dens > 0.30)                        # echte Striche haben Nachbarn, Grain nicht
alpha = np.clip((150 - lum) * 3.2, 0, 255); alpha[~keep] = 0   # weiche Kanten
rgba = np.dstack([np.clip(a*0.85,0,255).astype(np.uint8), alpha.astype(np.uint8)])
# dann: auf keep-BBox croppen (+12px Rand), Rest-Fragmente mit fill=(0,0,0,0) wegretuschieren
```

**Blaue Kuli-Tinte:** reine Luminanz greift zu schwach — Kriterium `ink = (B−R > 25) | (lum < 110)`, Alpha aus `max((B−R−10)·4, (170−lum)·2.5)`; Farbe danach uniform setzen (z. B. Tintenblau 20/30/110), sonst bleibt JPEG-Farbrauschen in den Strichen. Foto vorher mit `ImageOps.exif_transpose` drehen und **eng um die Unterschrift croppen**, bevor die BBox gesucht wird — dunkler Hintergrund/Karo-Papier im Bild liefert sonst eine BBox über das ganze Foto (so passiert 2026-08-20).

**⚠️ Pflicht: RGBA mit Alpha, NICHT weißer Hintergrund** — ein weißes Rechteck überdeckt
sonst Feldrahmen/Beschriftung des Formulars (ist genau so passiert).

## 2. Zielposition finden

- Formularfeld vorhanden? → Rect via pypdf: `page["/Annots"] → o["/T"], o["/Rect"]` (pt, y von unten).
- Nur gezeichnete Box (kein Feld)? → Seite mit `gs -sDEVICE=png16m -r110` rendern, Pixel
  messen, umrechnen: `pt = px * 72/dpi`, `y_pt = seitenhöhe_pt − y_px_von_oben * 72/dpi`.

## 3. Einsetzen (reportlab-Overlay + merge_page)

```python
c = canvas.Canvas(buf, pagesize=(w_pt, h_pt))
c.drawImage(png, x, y, width=h*iw/ih, height=h, mask="auto")   # Höhe fix ~40–48pt
c.save(); page.merge_page(PdfReader(buf).pages[0])
```

- Leichtes Überragen der Box (oben/unten wenige pt) wirkt natürlich — nicht zwängen.
- Datum daneben NICHT dem User im Viewer überlassen: von Hand in Acrobat/Vorschau gesetzte
  Feldwerte haben oft **keinen Appearance-Stream** → /V existiert, rendert/druckt aber leer.
  Datum stattdessen mit `update_page_form_field_values` setzen (pypdf erzeugt Appearance).
- BA-/Behörden-Radiobuttons: `/V`+`/AS` setzen erzeugt deren eigene „An"-Optik (roter Kreis)
  und rendert in manchen Viewern gar nicht → Kreuze/Punkte stattdessen als Linien ins
  Overlay zeichnen, Felder unangetastet lassen.

**⚠️ pypdf-Metadaten-Falle:** `PdfWriter` übernimmt Titel/Autor der Quelle NICHT —
nach dem Merge `writer.add_metadata({'/Title': …, '/Author': …})` aus dem Reader setzen
(ist 07/2026 real passiert: frisch gesetzter `pdftitle` war stillschweigend weg).
Interne Links/Named Destinations bleiben dagegen erhalten.

## 4. Verifizieren (immer!)

Ergebnis-Seite mit gs als PNG rendern und ansehen (Zoom auf die Unterschrift-Region —
Achtung, Pixelkoordinaten mit der tatsächlichen Render-dpi umrechnen):
Transparenz ok? Rahmen sichtbar? Datum gerendert? Erst dann ausliefern.
Metadaten gegenprüfen: `pdfinfo out.pdf` muss Title/Author zeigen.
Datei benennen wie `<Formular>_ausgefuellt+signiert_<YYYY-MM-DD>.pdf`, Skript im
Vorgangs-Ordner lassen (regenerierbar).
