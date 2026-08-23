---
name: standort
description: Liefert Mats' aktuellen Standort (Koordinaten + Adresse) vom Mac aus. Nutzen, sobald eine Antwort vom Ort abhängt — „was ist in meiner Nähe", „wo kann ich hier drucken/einkaufen/essen", „wie weit ist es bis …", Wegzeiten, Routen — ohne nach der Adresse zu fragen.
---

# Standort des Macs abfragen

**Werkzeug:** `CoreLocationCLI` (Homebrew-Cask `corelocationcli`, installiert 2026-08-20 als
`/Applications/CoreLocationCLI.app`, Symlink in `/opt/homebrew/bin`). Ortung über WLAN-Umfeld,
in der Stadt ±30–100 m — fürs Umfeld („nächster Copyshop") völlig ausreichend. Ortungsdienste-
Freigabe für CoreLocationCLI ist erteilt (Systemeinstellungen → Datenschutz → Ortungsdienste).

```bash
CoreLocationCLI --json          # volle Ausgabe inkl. Reverse-Geocoding
CoreLocationCLI -f "%latitude,%longitude ±%h_accuracy m — %address"
```

Relevante JSON-Felder: `latitude`, `longitude`, `h_accuracy` (m), `address` (mehrzeilig),
`subLocality` (Stadtteil), `postalCode`. Dauer 1–3 s; Timeout ≥ 30 s setzen.

## Danach

- Ergebnis **einmal knapp nennen** („du bist an der Musterstraße 12, Zentrum, ±35 m"), dann mit
  Koordinaten weiterarbeiten (Umkreissuche per WebSearch, Wegzeiten grob: 80 m/min zu Fuß).
- Bei Fehler `Location services are disabled or location access denied`: Ortungsdienste-Pane
  öffnen (`open "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"`),
  Haken bei CoreLocationCLI setzen lassen. Nach Homebrew-Updates kann der Haken verloren gehen
  (neues Bundle) → gleicher Fix.
- **Nicht** IP-Geolocation (`ipinfo.io`) als Ersatz nehmen — zeigt den Vodafone-Knoten
  (Hildesheim), nicht den Standort. pyobjc-CoreLocation aus dem Terminal scheitert an TCC
  (kCLError 1) — deshalb das signierte App-Bundle.

## Grenzen

Ortet den **Mac**, nicht das iPhone. Unterwegs ohne Mac gibt es keinen Wert; dann nach
Straße/Haltestelle fragen.
