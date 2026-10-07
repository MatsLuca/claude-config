---
description: Schließt die Arbeit dieser Session ab — eigene Änderungen committen (README/CHANGELOG/Issues nur wenn betroffen), sichern und pushen; aus einem Worktree bringt es den Branch zurück in sein Ziel und räumt auf. Änderungen anderer Sessions bleiben liegen und werden benannt.
argument-hint: <optional: „alles" = auch fremde Änderungen mitnehmen · „knapp"/„voll" = Form erzwingen (sonst nach Inhalt) · „nach <branch>" = Worktree ohne Ziel dorthin zurückbringen>
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git rev-parse:*), Bash(git rev-list:*), Bash(git merge-base:*), Bash(git cherry:*), Bash(git symbolic-ref:*), Bash(git config:*), Bash(git remote:*), Bash(git ls-remote:*), Bash(git worktree list:*), Bash(git branch:*), Bash(git add:*), Bash(git commit:*), Bash(git fetch:*), Bash(git pull:*), Bash(git rebase:*), Bash(git merge:*), Bash(git push:*), Bash(git -C:*), Bash(gh issue list:*), Bash(gh issue view:*), Bash(gh issue comment:*), Bash(export PATH=*), Bash(echo:*), Bash(date:*), Bash(ls:*), Bash(sh:*), Read, Edit
---

Du schließt die Arbeit **dieser Session** ab: ihre Änderungen verstehen, committen, sichern — und steht die Session in einem Worktree, den Branch zurück in sein Ziel bringen und aufräumen. Überblick zuerst, wenige Runden, unabhängige Aufrufe parallel (`git status --short`, `git log @{u}..HEAD --oneline`, `git diff @{u} --stat`, die letzten Commits als Stil-Referenz, dazu die Lage aus „Wo stehst du?"); den vollen Diff nur gezielt, wo die Stat-Zeile nicht reicht. Untracked Dateien sind neu — kurz ansehen, wenn relevant.

## Nur die eigenen Änderungen

Oft arbeiten mehrere Claude-Sessions parallel im selben Ordner; ihre halbfertigen Dateien dürfen nicht in deinen Commit. **Eigen** ist, was diese Session selbst angelegt, geändert oder gelöscht hat (Edit/Write, per Bash erzeugt, von deinen Subagenten, dazu die Doku, die du gleich nachziehst) — das weißt du aus dem Verlauf, nicht aus dem Baum. Alles andere in `git status` ist **fremd**: nicht stagen, nicht committen, nicht anfassen, sondern in der Meldung benennen.

- Steht `alles` in `$ARGUMENTS` oder sagt Mats, das Fremde gehöre dazu → alles mitnehmen.
- Hat diese Session nichts geändert (frischer Aufruf) → die offenen Änderungen auflisten und einmal fragen, welche mitsollen; ohne Antwort nichts committen. Im Knapp-Modus nicht fragen, sondern nur benennen.
- Enthält eine eigene Datei zusätzlich Hunks, die nicht von dir stammen → die Datei nicht committen, benennen und fragen.
- Den Index teilen sich alle Sessions eines Ordners: eigene Pfade gezielt stagen (`git add -A -- <pfade>`, erfasst auch Löschungen) und nur sie committen (`git commit … -- <pfade>`); fremd Gestagtes bleibt gestagt.
- Bereits committete, noch nicht gepushte Commits sind abgeschlossene Arbeit — sie gehen mit raus; die Meldung nennt fremde darunter.

## Commit

- **README** nur anfassen, wenn die Änderung dort Dokumentiertes sichtbar verändert (Features, Commands, Setup, API) — punktuell per `Edit`, nicht neu schreiben. **CHANGELOG** nur ergänzen, wenn einer existiert, im Format der Datei; keinen anlegen.
- **Issues** nur, wenn das Projekt sie nutzt: `gh issue list --state open --limit 30 --json number,title` (PATH um `/opt/homebrew/bin` ergänzen); schlägt es fehl oder ist leer, entfällt der Schritt ohne Nachhaken. Erledigt die Arbeit ein Issue → `Closes #<N>` in die Message. Betroffen, aber nicht erledigt → Status-Kommentar nur anbieten; `gh issue comment` erst nach Zustimmung.
- **Message:** Conventional-Commits-Subject im Stil der letzten Commits, bei mehreren logischen Änderungen ein kurzer Body mit dem *Warum*, je Issue `Closes #<N>`, zuletzt `Co-Authored-By: Claude <noreply@anthropic.com>`. Per Heredoc.
- **Knapp-Modus** — **von selbst** in einem Wissensprojekt (das Repo enthält keinen Code, nur Notizen, Dokumente, Daten — ein Blick auf `git ls-files` genügt); in einem Code-Repo bleibt es beim vollen Abschluss, auch wenn diesmal nur Doku geändert wurde. `knapp` bzw. `voll` in `$ARGUMENTS` erzwingt die eine oder andere Form. Knapp heißt: keine Diff-Analyse, keine README/CHANGELOG/Issue-Pflege, keine Rückfrage; Message `Stand <YYYY-MM-DD HH:MM>` (Uhrzeit von `date`); Meldung **eine Zeile**; war nichts zu tun, lautet sie genau „Schon synchron." (mit liegen Gelassenem dahinter). Alles andere gilt unverändert.
- Nichts Eigenes offen → kein Commit (auch kein leerer); unpushte Commits werden trotzdem gesichert.

## Wo stehst du? (vor dem Sichern, ohne Netz)

- **Worktree:** `git rev-parse --git-dir` ≠ `git rev-parse --git-common-dir` → verlinkter Worktree; der Hauptordner ist die erste `worktree`-Zeile von `git worktree list --porcelain`. Detached HEAD → stoppen, melden.
- **Branch** `X` = `git symbolic-ref --short HEAD`. **Remote** `R` = `git config branch.<X>.remote`, sonst der einzige Remote, sonst `origin`; kein Remote → nur committen, melden.
- **Default-Branch** `D`: `git symbolic-ref --short refs/remotes/<R>/HEAD` ohne `<R>/` → sonst genau einer von lokal `main`/`master` → sonst `git ls-remote --symref <R> HEAD` (einziger Netzgriff hier) → sonst stoppen. Nie blind `main` annehmen.
- **Ziel** `T`: `git config branch.<X>.finishInto` — gesetzt beim Anlegen des Worktrees (Rezept: `${CLAUDE_PLUGIN_ROOT}/reference/worktrees.md`). Existiert T nicht als lokaler Branch → stoppen, melden (veraltete Angabe). Kein `finishInto`, aber `CLAUDE_CODE_REMOTE` gesetzt und X beginnt mit `claude/` → Cloud-Fall, Ziel D. Sonst **kein Ziel** — nie raten, wohin ein Branch gehört.

Daraus folgt genau ein Fall: X = D → Fall 1 · Ziel T im Worktree → Fall 2 (Ziel T, aber kein Worktree → wie Fall 4 sichern und melden, denn ein Rebase im geteilten Ordner träfe alle Sessions) · Cloud → Fall 3 · sonst Fall 4. Ohne Remote entfallen alle Netzschritte (Fetch, Angleichen, Push, Remote-Löschen); der Rest läuft lokal.

## Fall 1 — Default-Branch, kein Worktree (Alltag)

Erst `git push` (ohne Upstream `git push -u <R> <D>`). Nur wenn er abgelehnt wird (Remote weiter): `git pull --rebase --autostash <R> <D>`, dann erneut pushen. Rebase-Konflikt → sofort `git rebase --abort` (stellt die weggelegten fremden Änderungen wieder her), Ursache in einer Zeile, stoppen. *Warum Push zuerst:* im geteilten Ordner sehen während eines Rebase alle Sessions den Zwischenzustand — so selten wie möglich.

## Fall 2 — Worktree mit Ziel T

Umgebaut wird nur im Worktree; der Ordner, in dem T ausgecheckt ist, bekommt ausschließlich einen Fast-Forward. Schritte in dieser Reihenfolge, jeder erst nach Erfolg des vorigen. Die Befehle stehen hier wörtlich, weil jeder auf Datenverlust geprüft ist (Review + Wegwerf-Repos, 07.10.: `branch -f`, `worktree remove` und `rebase` verhalten sich in Randfällen anders als vermutet) — Abweichungen nur mit neuem Beleg:

1. `git fetch <R>`. Hat X einen Upstream `<R>/X` und dort Commits, die X fehlen (`git rev-list X..<R>/X`), → stoppen: dort liegt Arbeit von anderswo.
2. **T angleichen**, falls T einen Upstream hat: liegt T nur dahinter → in T's Ordner (aus `git worktree list --porcelain`) `git -C <T-Ordner> merge --ff-only <R>/T`; ist T nirgends ausgecheckt → `git fetch <R> T:T`. Haben T und `<R>/T` beide eigene Commits → stoppen: „erst im Hauptordner `/finish`".
3. **Rebase im Worktree:** steht `branch.<X>.finishBase`, dann `git rebase --onto T <finishBase>`, sonst `git rebase T`. Konflikt → `git rebase --abort`, stoppen; Worktree und Branch bleiben, nichts verloren. Danach `git log --oneline T..X` ansehen: steht dort ein Commit, der nicht aus dieser Arbeit stammt (Worktree von anderswo abgezweigt), → stoppen und die Liste zeigen.
4. **T vorspulen:** ist T ausgecheckt → `git -C <T-Ordner> merge --ff-only X`; sonst `git push . X:T`. Verweigert Git, weil eine fremde offene Änderung dort dieselbe Datei berührt → stoppen, Datei nennen (nichts wurde überschrieben). Kein Fast-Forward möglich, weil T sich inzwischen bewegt hat → genau ein weiterer Durchlauf ab Schritt 3, dann stoppen. Ein fehlschlagender Hook ist ein Stopp.
5. **T pushen**, nur wenn T einen Upstream hat: `git -C <T-Ordner> push` (T nirgends ausgecheckt: `git push <R> T`). Abgelehnt → melden; die Arbeit liegt sicher im lokalen T, Aufräumen entfällt.
6. **Aufräumen**, nur wenn `git merge-base --is-ancestor X T` gilt, `git status --porcelain` im Worktree leer ist (sonst: Worktree stehen lassen, Reste nennen — z. B. untracked `_brett/`) **und** unter den ignorierten Dateien (`git status --ignored --porcelain`) nur Wiederherstellbares liegt: Build-/Cache-Ordner (`build/`, `dist/`, `.build/`, `DerivedData/`, `.godot/`), `node_modules/`, `venv/`/`.venv/`, `__pycache__/`, `.DS_Store`. Liegt dort anderes (`.env`, lokale Daten, Exporte) → nicht aufräumen: die Arbeit ist in T, der Worktree bleibt, die Meldung nennt die Dateien und fragt, ob sie weg dürfen; auf „ja" dasselbe Aufräumen wie unten. `worktree remove` löscht ignorierte Dateien ohne Rückfrage mit — deshalb diese Prüfung.
   - hatte X einen Upstream und zeigt `git cherry T <R>/X` keine `+`-Zeile → `git push <R> --delete X`;
   - `sync.sh` (siehe unten) jetzt ausführen;
   - **zuletzt, als ein einziger Aufruf** — danach existiert der Ordner dieser Session nicht mehr: `git -C <Hauptordner> worktree remove <worktree> && git -C <Hauptordner> branch -d X`. Weigert sich `worktree remove` (offene Dateien, Submodule) oder `branch -d` → so lassen und melden.

## Fall 3 — Cloud-Session ohne finishInto (`CLAUDE_CODE_REMOTE`, Branch `claude/…`)

`git fetch <R>`, `git rebase <R>/<D>` (Konflikt → abort, stoppen), `git push <R> HEAD:<D>`. Blockt die Umgebung direkte Pushes auf D → `git push <R> HEAD:refs/heads/<X>-finish` und das melden (der alte Session-Branch ist nach dem Rebase nicht mehr fast-forward). Keine Branch-Löschung.

## Fall 4 — eigener Branch ohne Ziel

Nicht mergen, nichts rebasen: pushen (ohne Upstream `git push -u <R> X`). Abgelehnt → melden, kein Pull. Steht X in einem Worktree, fragt die Meldung: „<X> bleibt eigener Branch — soll er nach <D>?"; sonst nur der Hinweis, dass er eigener Branch bleibt.

**Ziel nachtragen** — nur im Worktree, auf Mats' „ja" oder mit `nach <T>` in `$ARGUMENTS` (das ist die Zustimmung vorab): T muss als lokaler Branch existieren. Dann `git config branch.<X>.finishInto <T>` und `git config branch.<X>.finishBase "$(git merge-base X T)"` setzen — der Abzweigpunkt, damit nur die Commits dieses Branches mitgehen — und im selben Lauf Fall 2 ab Schritt 1. Für einen Branch im geteilten Hauptordner nie (siehe oben).

## Was nie passiert

Kein `--force`, kein `branch -D`, kein `worktree remove --force`, kein `update-ref`/`branch -f` auf einen Ziel-Branch; kein `checkout`/`switch`/`stash` im Hauptordner (tauscht Dateien unter allen Sessions aus) — einzige Ausnahme ist der `--autostash`-Rebase aus Fall 1, und der nur nach abgelehntem Push. Liegt ein `index.lock` → nicht löschen, melden (eine andere Git-Aktion läuft).

## Nach erfolgreichem Push

Einmal `sh "${CLAUDE_PLUGIN_ROOT}/shell/sync.sh" --after-push` (in Fall 2 vor dem Aufräumen): im Marketplace-Repo von `mats-tools` zieht es den Plugin-Cache nach, überall sonst endet es still. Nur eine etwaige Ausgabe in die Meldung übernehmen.

## Meldung

Mats liest nur diese Meldung — sie muss den Abschluss belegen: Commit-Subject wörtlich mit Kurz-Hash (oder „kein Commit"), Doku-Änderung und Issues (falls), wohin gepusht und Ergebnis, in Fall 2 „<X> → <T> zurückgebracht, Worktree entfernt — Brett kann zu" bzw. was stehen blieb und warum; falls vorhanden eine Zeile „Liegen gelassen (andere Session): <Pfade>". Wenige Zeilen, im Knapp-Modus eine; ein bloßes „Fertig." ist keine Meldung.
