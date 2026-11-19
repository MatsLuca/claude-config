---
name: "42"
description: Erörtert eine Idee, Entscheidung oder ein Vorhaben, bevor gebaut wird — erst ein Befund über das eigene System (was gibt es schon, wo gehört es hin), dann die offenen Entscheidungen, bis nichts mehr still angenommen ist; endet mit Urteil und Notiz, gebaut wird erst auf „jetzt". Laden, sobald jemand erörtern will statt beauftragen („lass uns erörtern", „ich hab da eine Idee", „sollte ich …?", „interview mich dazu", halbgare Notiz) — auch zu einem bestehenden Projekt — oder per /42 <idee>. Nicht bei klaren Aufträgen („bau X"); „bau einfach" oder „ohne 42" beendet sofort.
---

# 42 — Erörtern, bevor gebaut wird

Zweck: ein Ausgleicher. An guten Tagen bringt der Nutzer Kontext und Struktur selbst mit, an
müden nicht; 42 liefert beides unabhängig von der Tagesform. **Der Wert liegt im Befund** — was
es schon gibt, was das für die Idee heißt, was daraus noch werden kann. Die Fragen sind das Gerüst.

Springt 42 von selbst an: in einem Halbsatz sagen, dass erst erörtert wird.

## Regeln

- **Befund zuerst.** Vor der ersten Frage lesen, was nachschlagbar ist (Ordner, Repos,
  CLAUDE.md-Dateien, Notizen, Memory, Chat-Archiv), und vorlegen: was existiert schon halb — im
  eigenen System und, wo es naheliegt, fertig draußen —, wo gehört die Idee hin, welche Art ist
  sie (Werkzeug · Projekt · Feature · Vorgang mit Außenwelt · Ordnung · Entscheidung). Ist unklar,
  was gemeint ist, erst klären, bis „du meinst also X" stimmt. Die erste Frage steht in derselben
  Antwort. *(Fertig: Art und Heimat benannt, drei Fundstellen oder ein ehrliches „nichts gefunden".)*
- **Fakten sucht Claude, Entscheidungen trifft der Nutzer.** Taucht mitten im Lauf eine
  Faktenfrage auf, sucht ein Subagent im Hintergrund; nur die Äste dahinter warten, der Rest
  läuft weiter.
- **Vermutung, wo Recherche der Input ist** — „Ich vermute X. Stimmt das?", so gestellt, dass
  „ja" sie annimmt. **Offen, wo der Kopf des Nutzers der Input ist** (Auslöser, Fertig-Bild):
  ohne Optionen, eine Frage je Antwort, ein Fragezeichen. Ein Wort ist eine gültige Antwort.
- **Bündeln, sobald die Vermutungen tragen** (knappes Ja, Drängen): alle entscheidbaren in
  einer Antwort, mit einem einzigen „stimmt das so?". Nach Widerspruch oder „zu schnell" wieder
  einzeln.
- **Was der Prompt schon beantwortet, wird zurückgespiegelt** („Auslöser war also X — stimmt?"),
  und es geht an der ersten offenen Stelle weiter.
- **Konkret.** Der letzte Fall schlägt „wie oft", ein Beispiel schlägt eine Beschreibung.
- **Alltagssprache.** Der Befund sagt, was es gibt und was das heißt; Pfade und Technik stehen
  in der Notiz.
- **Begriffe schärfen.** Ein unscharfes oder doppelt belegtes Wort sofort klären („meinst du A
  oder B?"). Hat das System eine Begriffsliste, gilt sie; ein neu geklärtes Wort kommt hinein.
- **Gebaut wird auf „jetzt".** Bis dahin entstehen Befund, Skizze und Notiz. Sagt der Nutzer
  „jetzt", „bau" oder „mach", baut dieselbe Session weiter — die Notiz ist ihr Auftrag, ein
  zweites Ja braucht es nicht. Nur Unumkehrbares oder Außenwirksames (Geld, Versand an Dritte,
  Löschung) verlangt einmal ein ausdrückliches „ja, weiter".
- **Abbruch.** „Bau einfach" oder „ohne 42" beendet 42 sofort und ohne Rückfrage.

## Der Baum

Eine Idee ist ein Baum offener Entscheidungen. **Entscheidbar** ist ein Ast, dessen
Voraussetzungen stehen: gefragt wird Entscheidbares, der Rest wartet. Jede Antwort verschiebt
den Baum — neu ansehen, was jetzt entscheidbar ist, weiter.

Sechs **Pflichtäste** hat jede Idee; dazu kommen ihre eigenen (bei einem Paket für andere etwa:
was sie bekommen, was verborgen bleibt, wie es zu ihnen kommt).

1. **Warum** (offen). Der Auslöser als Moment. *(Fertig: ein Auslöser oder das ehrliche „nur ein
   Gefühl" — beides ist eine Antwort.)*
2. **Ort und Synergie** (Vermutung). Ersetzt, erweitert oder steht daneben; was im System davon
   besser würde, was daraus noch werden könnte. *(Fertig: Ort steht, eine Synergie oder „keine".)*
3. **Fertig-Bild** (offen). Ein echtes Beispiel: das geht rein, das kommt raus. *(Fertig: etwas
   Zeigbares und ein Kriterium für die erste Woche.)*
4. **Grenzen und Rückweg** (Vermutung). Unumkehrbares, Daten, Regelkonflikte, Rückweg.
   *(Fertig: Liste vorgelegt, bestätigt oder ergänzt.)*
5. **Preis** (Vermutung). Was es verdrängt, was es dauerhaft an Pflege kostet, wo es ausufert,
   was bei Nichtstun passiert. Größe in Bauschritten, die je eine Session schafft.
   *(Fertig: bestätigt, Urteil gesagt.)*
6. **Übergabe** (Vermutung). Ergebnisform, nächster Schritt, Ort der Notiz, wer gefragt oder
   informiert werden muss. *(Fertig: Notiz geschrieben, Nutzer sagt „jetzt" oder „parken bis <Datum>".)*

**Tiefe nach Größe.** Kleine Idee (ein Baustein, ein Ort): Befund und Warum, danach die übrigen
Äste gebündelt. Große Idee (mehrere Bausteine, mehrere Sessions, andere Menschen betroffen) oder
„interview mich": zuerst die **Etappen** als nummerierte Liste zeigen — die Äste dieser Idee in
der Reihenfolge ihrer Abhängigkeit —, dann eine Etappe je Antwort. Jede schließt mit „Etappe n
steht: …" in einem Satz, bevor die nächste beginnt.

**Vier Wege, einen Ast zu klären:**
- **Gespräch** — der Standard.
- **Recherche** — Claude oder ein Subagent; das Ergebnis kommt als Nachtrag zum Befund.
- **Zeigen** — wo „wie soll es aussehen oder sich anfühlen" die Frage ist: eine Wegwerf-Skizze
  vorlegen (Seite, Bild, Beispielausgabe) und darauf reagieren lassen.
- **Handgriff** — was nur der Nutzer kann (Zugang, Gerät, Anruf): als kurze Liste mitgeben.

Hängt ein Ast am Wissen eines Dritten, spricht der für sich selbst: die Fragen an ihn sammeln
und als Fragebogen oder Nachrichtenentwurf mitgeben — das Wichtigste zuerst, je Frage eine
Sache, ein Satz Kontext vorweg. Der Ast steht bis zur Antwort als „noch nicht entscheidbar" in
der Notiz.

**Fertig** ist die Erörterung, wenn jeder Ast entschieden, bewusst draußen oder als noch nicht
entscheidbar benannt ist — nichts ist still angenommen.

## Urteil

Vor der Übergabe ein Satz, was Claude täte und warum: trägt die Idee, gibt es sie schon, passt
sie zum Bestehenden. Der Satz stoppt nie den Fluss; „trotzdem" reicht, und es geht weiter. Will
der Nutzer mehr, als Claude vorschlägt, gilt sein Umfang — Claude nennt dann die Reihenfolge, in
der es am sichersten gelingt. Das Urteil steht wörtlich in der Notiz, damit später prüfbar ist,
wer öfter recht hatte.

## Notiz und Ausgänge

Die Notiz ist knapp und lebt an dem Ort, den Ast 2 ergab (sonst cwd): Idee in einem Satz · Art
und Ort · Befund und Synergien · Fertig-Bild · Entscheidungen, je eine Zeile · Grenzen · Preis
und **Urteil** (wörtlich, plus was der Nutzer entschied) · nächster Schritt · noch nicht
entscheidbar (woran es hängt) · bewusst draußen. Bei einer großen Idee ist sie die Karte für
die folgenden Sessions.

Ergebnisformen: **Fazit** (auch „lass es"), **Erkenntnis** (Synergie, neuer Blick), **Plan**.
Ausgänge, wo vorhanden:
- „jetzt" → dieselbe Session baut, die Notiz ist der Auftrag
- „parken bis <Datum>" → Termin oder Wiedervorlage des Nutzers
- Fragen an Dritte → Fragebogen oder Nachrichtenentwurf
- Projekt anlegen, Ort klären → `/neues-projekt --einordnen`, Skill `claude-md`
- System hinterfragen, entschlacken → `/neudenken`, `/destillieren`

## Abschluss

Melde: Ergebnisform, Ort der Notiz, Urteil in einem Satz, nächster Schritt.
