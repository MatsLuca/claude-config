---
description: Zeigt strukturiert deine GitHub-Pushes (Commits) auf eigenen Repos innerhalb eines angegebenen Zeitraums.
argument-hint: <Zeitraum, z.B. "24 Stunden", "1 Tag", "eine Woche", "30 Tage", "3 Monate">
allowed-tools: Bash(gh search commits:*), Bash(gh api user:*), Bash(date:*), Bash(export PATH=*)
---

Du zeigst dem Nutzer, welche Commits er innerhalb des angegebenen Zeitraums auf seine **eigenen** GitHub-Repositories gepusht hat — gruppiert pro Repo, chronologisch, mit Commit-Subject.

Der Zeitraum kommt als Argument: **$ARGUMENTS**

## Schritt 1 — Zeitraum in einen `date -v`-Offset übersetzen

Interpretiere `$ARGUMENTS` (deutsch oder englisch, frei formuliert) und wähle den passenden macOS-`date -v`-Offset:

| Eingabe (Beispiele) | Offset-Flag |
|---|---|
| "Stunde", "1h", "60 min" | `-v-1H` |
| "24 Stunden", "ein Tag", "1 Tag", "today", "heute" | `-v-24H` |
| "2 Tage", "48h" | `-v-2d` |
| "Woche", "eine Woche", "7 Tage" | `-v-7d` |
| "2 Wochen", "14 Tage" | `-v-14d` |
| "Monat", "30 Tage" | `-v-1m` |
| "3 Monate", "Quartal" | `-v-3m` |
| "Jahr", "12 Monate" | `-v-1y` |

Zahl + Einheit verallgemeinern (z.B. "5 Tage" → `-v-5d`, "6 Stunden" → `-v-6H`). Einheiten: `H`=Stunden, `d`=Tage, `m`=Monate, `y`=Jahre.

Ist `$ARGUMENTS` leer, nimm standardmäßig **`-v-24H`** (letzte 24 Stunden) und erwähne das in der Antwort.

## Schritt 2 — Abfrage in EINEM Bash-Aufruf

Ersetze `<OFFSET>` durch das in Schritt 1 gewählte Flag und führe genau diesen Block aus:

```bash
export PATH="/opt/homebrew/bin:$PATH"
LOGIN=$(gh api user --jq .login)
SINCE=$(date -u <OFFSET> +%Y-%m-%dT%H:%M:%SZ)
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

## Schritt 3 — Ergebnis präsentieren

- Gibt das jq `KEINE_COMMITS` aus: melde knapp, dass im Zeitraum keine Pushes auf eigene Repos gefunden wurden.
- Andernfalls: gib das gruppierte Ergebnis sauber als Markdown wieder (die jq-Ausgabe ist bereits fertig formatiert — du kannst sie direkt übernehmen) und stelle eine **kurze Zusammenfassung** voran: „X Commits in Y Repos in den letzten <Zeitraum>“.
- Halte dich kurz; keine zusätzlichen Erklärungen, außer es gab eine Auffälligkeit (z.B. leeres Ergebnis, Auth-Fehler).
