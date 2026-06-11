---
description: Zeigt strukturiert deine GitHub-Pushes (Commits) auf eigenen Repos innerhalb eines angegebenen Zeitraums.
argument-hint: <Zeitraum, z.B. "24 Stunden", "1 Tag", "eine Woche", "30 Tage", "3 Monate">
allowed-tools: Bash(gh search commits:*), Bash(gh api user:*), Bash(date:*), Bash(jq:*), Bash(echo:*), Bash(export PATH=*)
---

Du zeigst dem Nutzer, welche Commits er innerhalb des angegebenen Zeitraums auf seine **eigenen** GitHub-Repositories gepusht hat — gruppiert pro Repo, chronologisch, mit Commit-Subject.

Der Zeitraum kommt als Argument: **$ARGUMENTS**

## Schritt 1 — Zeitraum übersetzen (beide Schreibweisen)

Interpretiere `$ARGUMENTS` (deutsch oder englisch, frei formuliert) und wähle die passende Dauer — als GNU-Ausdruck (Linux/Container) **und** BSD-Offset (macOS); welcher greift, entscheidet die Probe im Block von Schritt 2:

| Eingabe (Beispiele) | `<DAUER>` (GNU) | `<OFFSET>` (BSD) |
|---|---|---|
| "Stunde", "1h", "60 min" | `1 hour` | `-v-1H` |
| "24 Stunden", "ein Tag", "1 Tag", "today", "heute" | `24 hours` | `-v-24H` |
| "2 Tage", "48h" | `2 days` | `-v-2d` |
| "Woche", "eine Woche", "7 Tage" | `7 days` | `-v-7d` |
| "2 Wochen", "14 Tage" | `14 days` | `-v-14d` |
| "Monat", "30 Tage" | `1 month` | `-v-1m` |
| "3 Monate", "Quartal" | `3 months` | `-v-3m` |
| "Jahr", "12 Monate" | `1 year` | `-v-1y` |

Zahl + Einheit verallgemeinern (z.B. "5 Tage" → `5 days` / `-v-5d`). GNU-Einheiten: `hours`/`days`/`months`/`years`; BSD-Einheiten: `H`/`d`/`m`/`y`. Wochen in Tage umrechnen (×7, z.B. "3 Wochen" → `21 days` / `-v-21d`).

Ist `$ARGUMENTS` leer, nimm standardmäßig **die letzten 24 Stunden** (`24 hours` / `-v-24H`) und erwähne das in der Antwort.

## Schritt 2 — Abfrage in EINEM Bash-Aufruf

Ersetze `<DAUER>` und `<OFFSET>` durch die in Schritt 1 gewählten Werte und führe genau diesen Block aus:

```bash
export PATH="/opt/homebrew/bin:$PATH"
LOGIN=$(gh api user --jq .login)
date -u -d @0 >/dev/null 2>&1 \
  && SINCE=$(date -u -d "<DAUER> ago" +%Y-%m-%dT%H:%M:%SZ) \
  || SINCE=$(date -u <OFFSET> +%Y-%m-%dT%H:%M:%SZ)
echo "User: $LOGIN | Zeitraum-Start (UTC): $SINCE"
echo "================================================"
gh search commits --author=@me --owner="$LOGIN" --committer-date=">=$SINCE" \
  --sort=committer-date --order=desc --limit 200 --json repository,sha,commit \
| jq -r '
  if length==0 then "KEINE_COMMITS" else
  ( group_by(.repository.fullName)
    | sort_by(.[0].commit.committer.date) | reverse
    | .[]
    | "## \(.[0].repository.name)\(if .[0].repository.isPrivate then " 🔒" else "" end)  —  \(length) Commit\(if length==1 then "" else "s" end)",
      ( sort_by(.commit.committer.date) | reverse | .[]
        | "- `\(.commit.committer.date[0:16] | sub("T";" "))`  \(.sha[0:7])  \(.commit.message | split("\n")[0])" ),
      "" )
  end'
```

Hinweise:
- `--author=@me --owner="$LOGIN"` beschränkt auf von dir verfasste Commits in deinen eigenen Repos (inkl. privater).
- Repos sind nach jüngstem Commit absteigend sortiert, Commits innerhalb eines Repos ebenfalls neueste zuerst.
- `🔒` markiert private Repos.
- Die Commit-Suche von GitHub indexiert primär den Default-Branch; Commits auf Nebenbranches können fehlen — bei Bedarf erwähnen.
- `--limit 200` deckelt die Treffer: kommen genau 200 Commits zurück, ist die Liste womöglich abgeschnitten (relevant bei langen Zeiträumen wie "Jahr") — dann auf mögliche Unvollständigkeit hinweisen und einen kürzeren Zeitraum vorschlagen.

## Schritt 3 — Ergebnis präsentieren

- Gibt das jq `KEINE_COMMITS` aus: melde knapp, dass im Zeitraum keine Pushes auf eigene Repos gefunden wurden.
- Andernfalls: gib das gruppierte Ergebnis sauber als Markdown wieder (die jq-Ausgabe ist bereits fertig formatiert — du kannst sie direkt übernehmen) und stelle eine **kurze Zusammenfassung** voran: „X Commits in Y Repos in den letzten <Zeitraum>“.
- Schlägt `gh` mit einem Auth-Fehler fehl (nicht eingeloggt): schlage dem User vor, `! gh auth login` einzugeben — nicht selbst weiterprobieren.
- Halte dich kurz; keine zusätzlichen Erklärungen, außer es gab eine Auffälligkeit (z.B. leeres Ergebnis, Auth-Fehler).
