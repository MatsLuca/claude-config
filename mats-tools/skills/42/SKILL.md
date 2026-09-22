---
name: "42"
description: Vor-Erörterung einer Idee oder geplanten Aktion — erst ein Befund über das eigene System (was gibt es schon, wo gehört es hin), dann in kurzen Wellen bis zu Preis und Urteil; Ergebnis ist Fazit, Erkenntnis oder Plan mit Notiz, nie ein Bau. Laden, sobald jemand eine Idee erörtern will statt einen Auftrag zu geben („ich hab da eine Idee", „erörter mal …", „lass uns mal über X nachdenken", „sollte ich …?", halbgare Notiz) — auch zu einem bestehenden Projekt — oder per /42 <idee>. Nicht bei klaren Aufträgen („bau X"); sofort beenden bei „bau einfach" oder „ohne 42".
---

# 42 — Vor-Erörterung in Wellen

Zweck: ein Ausgleicher. An guten Tagen bringt der Nutzer Kontext, Detail und Struktur selbst mit,
an müden nicht. 42 liefert beides unabhängig von der Tagesform und kitzelt aus einer halbgaren
Idee das heraus, was drinsteckt: eine Synergie, die sonst übersehen würde, eine neue Idee, ein
Fazit. **Der Wert liegt im Befund (Phase 0 und 2), nicht im Fragenkatalog** — die Fragen sind
das Gerüst, der Befund das Fleisch. Fragenpools je Phase: `${CLAUDE_PLUGIN_ROOT}/skills/42/fragen.md`.

## Betriebsarten

**`/42 <idee>`**: die volle Welle, Bericht am Ende.
**Proaktiv**: sobald der Nutzer eine Idee erörtern will statt einen Auftrag zu geben — mit oder
ohne Heimat im System; ob es eine gibt, klärt erst Phase 0. Kurz sagen, dass 42 läuft, ohne den
Befund vorwegzunehmen. Ein Auftrag („bau X") ist kein Fall für 42, auch wenn er groß ist.
**Abbruch**: „bau einfach", „ohne 42" oder gleichwertig beendet 42 sofort, ohne Rückfrage,
ohne „bist du sicher". Der Nutzer entscheidet, wie lang er es aushält.

## Unverletzliche Regeln

- **Nie bauen.** 42 endet mit einem Ergebnis auf dem Tisch; Umsetzung ist ein anderer Schritt,
  meist ein anderes Werkzeug (Ausgänge unten).
- **Nie fragen, was nachschlagbar ist.** Ordner, Repos, CLAUDE.md-Dateien, Notizen, Memory,
  Chat-Archiv (falls vorhanden, z. B. `/claude-chats`) werden gelesen, nicht erfragt.
- **Eine Frage je Antwort** — ein Fragezeichen, keine Kette: „Wann hast du dir das zuletzt
  gewünscht?" und Schluss; „… und wo warst du da gerade?" hängt schon die zweite an.
  Je Phase die Kernfrage, dann höchstens zwei Nachfragen, nur bei drei Auslösern: Widerspruch zum
  Befund, Unschärfe-Wörter („irgendwie", „eigentlich", „mal schauen") oder eine Antwort unter
  einem Satz — dann als Vermutung, die auffüllt, nicht als neue offene Frage. Ein Wort ist eine
  gültige Antwort.
- **Vermutung statt Frage, wo Recherche der Input ist** (Phasen 2, 4, 5, 6): „Ich vermute X.
  Stimmt das?" — korrigieren ist billiger als formulieren, und die Vermutung zeigt, was falsch
  verstanden wurde. **Offen fragen, wo der Kopf des Nutzers der Input ist** (Phasen 1, 3):
  keine Optionen vorgeben, sie würden die Antwort verbiegen.
- **Konkret statt Prinzip.** „Wann war das letzte Mal" schlägt „wie oft"; Beispiele schlagen
  Beschreibungen.
- **Alltagssprache.** 42 gleicht müde Tage aus: der Befund sagt, was es schon gibt und was das
  für die Idee heißt — Pfade, Zeilennummern und Technik gehören in die Notiz, nicht in die Antwort.
- **Urteilspflicht ohne Veto.** Phase 5 endet mit einem Satz, was Claude täte und warum. Der
  Satz stoppt nie den Fluss; „trotzdem" reicht, und es geht weiter. Das Urteil steht in der
  Übergabe-Notiz, damit später prüfbar ist, wer öfter recht hatte.
- **Einmal stoppen dürfen**: berührt die Idee etwas Unumkehrbares oder Außenwirksames (Geld,
  Versand an Dritte, Löschung), verlangt Phase 4 ein explizites „ja, weiter". Sonst nie.
- **Was der Prompt schon beantwortet, wird nicht gefragt**, sondern als Vermutung zurückgespiegelt
  („Auslöser war also X, Fertig-Bild Y — stimmt?"); die Welle springt zur ersten offenen Stelle.
  Ein nackter Einzeiler und ein ausformulierter Absatz sind beide gültiger Input.

## Die Wellen

Reihenfolge ist Regel: jede Phase braucht die vorige. Gewichtung: **0 und 2 tragen**, 3 bis 6
bleiben dünn. Die Phasen sind Fertig-Kriterien, keine Runden: tragen die Vermutungen (der Nutzer
stimmt knapp zu oder drängt weiter), dürfen 3 bis 6 gebündelt in einer Antwort kommen, mit einem
einzigen „stimmt das so?"; nach Widerspruch oder „zu schnell" wieder eine Phase je Antwort.
Fertig-Kriterium je Phase in Klammern.

0. **Verstehen, dann Befund** (keine Fragen aus dem Pool). Erst prüfen, ob die Idee semantisch
   trägt; wenn nicht, elementare Rückfragen, bis „du meinst also X" möglich ist. Dann Befund
   über das System: was existiert schon halb, wo würde es hingehören, welcher Situationstyp
   (Werkzeug · Projekt · Feature · Vorgang mit Außenwelt · Ordnung · Entscheidung). Befund
   vorlegen — ohne eigene Rückfrage, korrigieren darf der Nutzer immer —, in derselben Antwort
   die Frage von Phase 1. *(Fertig: Typ und Heimat benannt, drei Fundstellen oder „nichts gefunden".)*
1. **Warum** (offen). Auslöser als Moment, nicht als Prinzip. *(Fertig: ein Auslöser oder das
   ehrliche „kein konkreter, nur ein Gefühl" — beides ist eine Antwort.)*
2. **Wo im System, dann Synergie** (Vermutung). Erste Hälfte: Typ und Ort bestätigen, Verhältnis
   zum Bestehenden — steht die Heimat seit Phase 0 fest, reicht ein Satz. Zweite Hälfte, divergent: was im System würde davon besser, was könnte
   daraus noch werden. *(Fertig: Ort steht, mindestens eine Synergie oder „keine" benannt.)*
3. **Fertig-Bild** (offen). Ein echtes Beispiel: das geht rein, das kommt raus. Ein Prozess ist
   kein Fertig-Bild; nachfragen, bis etwas Zeigbares da ist. *(Fertig: ein Beispiel + ein
   Kriterium für die erste Woche.)*
4. **Grenzen und Rückweg** (Vermutung). Unumkehrbares, Daten, Regelkonflikte, Rückweg.
   *(Fertig: Liste vorgelegt, bestätigt oder ergänzt.)*
5. **Preis** (Vermutung, endet mit dem Urteilssatz). Größe in Abend / Wochenende / Monat, was
   bei Nichtstun passiert, was es verdrängt, wo es ausufert. *(Fertig: Größe bestätigt, Urteil
   gesagt, Nutzer hat getragen oder „trotzdem" gesagt.)*
6. **Übergabe** (Vermutung). Ergebnisform, nächster Schritt mit Werkzeug, Ort der Notiz,
   Wiedervorlage, was bewusst offen bleibt. *(Fertig: Notiz geschrieben, Nutzer hat „jetzt"
   oder „parken bis <Datum>" gesagt.)*

## Ergebnis und Ausgänge

Drei Ergebnisformen, entschieden in Phase 5/6: **Fazit** zur Idee (auch „lass es"),
**Erkenntnis** (Synergie, mentaler Shift), **Umsetzungsplan**. Die Übergabe-Notiz ist knapp
und lebt an dem Ort, den Phase 2 ergab (sonst cwd): Idee in einem Satz · Typ und Ort · Befund
und Synergien · Fertig-Bild · Grenzen · Preis und **Urteil** (wörtlich, plus was der Nutzer
entschied) · nächster Schritt · bewusst offen.

Ausgänge, wo vorhanden — 42 endet dort, wo sie beginnen:
- Werkzeug bauen → `plugin-dev` als Referenz, `/optimieren` als Maßstab
- Projekt anlegen / Ort klären → `/neues-projekt --einordnen`, Skill `claude-md`
- Feature in Code → Plan-Mode oder `feature-dev`
- System hinterfragen / entschlacken → `/neudenken`, `/destillieren`
- Frist → Termin oder Wiedervorlage des Nutzers
- Entscheidung ohne Bau → Fazit in der Notiz, fertig

## Abschluss

Melde: Ergebnisform, Ort der Notiz, Urteil in einem Satz, nächster Schritt. Kein Protokoll der
Fragen.
