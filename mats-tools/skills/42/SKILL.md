---
name: "42"
description: Vor-Erörterung einer neuen Idee oder geplanten Aktion in Wellen — erst verstehen, dann Befund über das eigene System (was gibt es schon, wo passt es hin, was würde davon besser), dann Warum, Fertig-Bild, Grenzen, Preis, Übergabe; Ergebnis ist ein Fazit, eine Erkenntnis oder ein Plan, nie ein Bau. Laden, sobald eine Idee ohne Heimat auftaucht („ich hab da eine Idee", „lass uns mal über X nachdenken", halbgare Notiz, „sollte ich …?", „wäre es sinnvoll …") oder per /42 <idee> — nicht bei klaren Aufträgen, nicht bei Feature-Wünschen in einem Projekt mit CLAUDE.md, und sofort beenden bei „bau einfach" oder „ohne 42".
---

# 42 — Vor-Erörterung in Wellen

Zweck: ein Ausgleicher. An guten Tagen bringt der Nutzer Kontext, Detail und Struktur selbst mit,
an müden nicht. 42 liefert beides unabhängig von der Tagesform und kitzelt aus einer halbgaren
Idee das heraus, was drinsteckt: eine Synergie, die sonst übersehen würde, eine neue Idee, ein
Fazit. **Der Wert liegt im Befund (Phase 0 und 2), nicht im Fragenkatalog** — die Fragen sind
das Gerüst, der Befund das Fleisch. Fragenpools je Phase: `${CLAUDE_PLUGIN_ROOT}/skills/42/fragen.md`.

## Betriebsarten

**`/42 <idee>`**: die volle Welle, Bericht am Ende.
**Proaktiv**: nur bei etwas Neuem ohne Heimat — Phase 0 findet weder Ordner, Projekt noch
laufende Arbeit dazu. Dann kurz sagen „das klingt nach einer Idee ohne Heimat, ich fahre 42"
und loslegen. Ein Feature-Wunsch in einem Repo mit CLAUDE.md ist kein Fall für 42.
**Abbruch**: „bau einfach", „ohne 42" oder gleichwertig beendet 42 sofort, ohne Rückfrage,
ohne „bist du sicher". Der Nutzer entscheidet, wie lang er es aushält.

## Unverletzliche Regeln

- **Nie bauen.** 42 endet mit einem Ergebnis auf dem Tisch; Umsetzung ist ein anderer Schritt,
  meist ein anderes Werkzeug (Ausgänge unten).
- **Nie fragen, was nachschlagbar ist.** Ordner, Repos, CLAUDE.md-Dateien, Notizen, Memory,
  Chat-Archiv (falls vorhanden, z. B. `/claude-chats`) werden gelesen, nicht erfragt.
- **Kernfrage allein, dann höchstens zwei Nachfragen**, nie mehr als drei Fragen auf einmal.
  Nachfrage nur bei drei Auslösern: Antwort unter einem Satz, Widerspruch zum Befund, oder
  Unschärfe-Wörter („irgendwie", „eigentlich", „mal schauen").
- **Vermutung statt Frage, wo Recherche der Input ist** (Phasen 2, 4, 5, 6): „Ich vermute X.
  Stimmt das?" — korrigieren ist billiger als formulieren, und die Vermutung zeigt, was falsch
  verstanden wurde. **Offen fragen, wo der Kopf des Nutzers der Input ist** (Phasen 1, 3):
  keine Optionen vorgeben, sie würden die Antwort verbiegen.
- **Konkret statt Prinzip.** „Wann war das letzte Mal" schlägt „wie oft"; Beispiele schlagen
  Beschreibungen.
- **Urteilspflicht ohne Veto.** Phase 5 endet mit einem Satz, was Claude täte und warum. Der
  Satz stoppt nie den Fluss; „trotzdem" reicht, und es geht weiter. Das Urteil steht in der
  Übergabe-Notiz, damit später prüfbar ist, wer öfter recht hatte.
- **Einmal stoppen dürfen**: berührt die Idee etwas Unumkehrbares oder Außenwirksames (Geld,
  Versand an Dritte, Löschung), verlangt Phase 4 ein explizites „ja, weiter". Sonst nie.
- Antworten mit einem Wort sind gültig. 42 füllt auf, statt nachzubohren.
- **Was der Prompt schon beantwortet, wird nicht gefragt**, sondern als Vermutung zurückgespiegelt
  („Auslöser war also X, Fertig-Bild Y — stimmt?"); die Welle springt zur ersten offenen Stelle.
  Ein nackter Einzeiler und ein ausformulierter Absatz sind beide gültiger Input.

## Die Wellen

Reihenfolge ist Regel: jede Phase braucht die vorige. Gewichtung: **0 und 2 tragen**, 3 bis 6
bleiben dünn — dort reicht meist die Kernfrage. Fertig-Kriterium je Phase in Klammern.

0. **Verstehen, dann Befund** (keine Fragen aus dem Pool). Erst prüfen, ob die Idee semantisch
   trägt; wenn nicht, elementare Rückfragen, bis „du meinst also X" möglich ist. Dann Befund
   über das System: was existiert schon halb, wo würde es hingehören, welcher Situationstyp
   (Werkzeug · Projekt · Feature · Vorgang mit Außenwelt · Ordnung · Entscheidung). Befund
   vorlegen, Nutzer korrigiert. *(Fertig: Typ benannt, drei Fundstellen oder „nichts gefunden".)*
1. **Warum** (offen). Auslöser als Moment, nicht als Prinzip. *(Fertig: ein Auslöser oder das
   ehrliche „kein konkreter, nur ein Gefühl" — beides ist eine Antwort.)*
2. **Wo im System, dann Synergie** (Vermutung). Erste Hälfte: Typ und Ort bestätigen, Verhältnis
   zum Bestehenden. Zweite Hälfte, divergent: was im System würde davon besser, was könnte
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
Fragen. Messgröße für die Kalibrierung des Auslösers: bricht der Nutzer öfter als jedes dritte
Mal ab, triggert 42 zu weit.
