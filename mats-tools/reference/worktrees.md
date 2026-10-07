# Worktrees — parallel am selben Repo arbeiten

Mehrere Claude-Sessions im selben Repo-Ordner teilen sich Dateien, Index und ausgecheckten Branch. Für den
Alltag reicht das: jede Session committet nur ihre eigenen Pfade (`/finish`). Ein **Worktree** — ein zweiter
Ordner mit derselben Historie, aber eigenem Branch — lohnt sich, wenn

- zwei Sessions dieselben Dateien anfassen müssten,
- etwas ausprobiert wird, das vielleicht wieder wegfliegt,
- ein Projekt mit Build parallel umgebaut wird.

## Regel für den geteilten Ordner

Dort nie `git checkout`/`git switch` auf einen anderen Branch oder Commit, nie `git stash`: beides tauscht
Dateien unter allen Sessions aus (und `refs/stash` ist repo-weit geteilt — auch Worktrees vertauschen darüber
ihre Stände). Wer einen eigenen Stand braucht, nimmt einen Worktree.

## Anlegen

Ein Worktree startet vom letzten **Commit** des Ziel-Branches, nicht von offenen Dateien — was dort auf
der Platte noch uncommittet liegt, fehlt im Worktree. Also erst committen, worauf aufgebaut werden soll.
`<repo>` = Hauptordner, `<T>` = Ziel-Branch (meist der Default-Branch), `<thema>` = kurzer Name:

```bash
git -C <repo> worktree add ../<repo-name>_wt/<thema> -b <thema> <T>
git -C <repo> config --unset-all branch.<thema>.finishInto   # Rest eines früheren gleichnamigen Branches; Exit 5 = war keiner
git -C <repo> config branch.<thema>.finishInto <T>
git -C <repo> config branch.<thema>.finishBase "$(git -C <repo> rev-parse <T>)"
```

`finishInto` sagt `/finish`, wohin der Branch zurück soll — ohne diese Zeile sichert `/finish` den Branch
nur als er selbst und fragt. `finishBase` merkt den Abzweigpunkt, damit beim Zurückbringen nur die Commits
dieses Worktrees mitgehen. Beide Einträge verschwinden mit `git branch -d`.

Was nicht in Git liegt (virtuelle Umgebungen, `node_modules`, `.env`, Build-Ordner), fehlt im Worktree —
bei Bedarf verlinken oder neu erzeugen. Ein Build im Worktree ist ein eigener Test-Build; die „echte"
Fassung entsteht erst nach dem Zurückbringen im Hauptordner.

## Abschließen

`/finish` im Worktree: eigene Änderungen committen → Branch auf den aktuellen Ziel-Stand setzen (Rebase im
Worktree) → Ziel-Branch per Fast-Forward vorspulen → pushen → Worktree und Branch entfernen. Bei Konflikt,
fremder Änderung an derselben Datei oder fremden Commits hält es an, ohne etwas zu verlieren. Danach
existiert der Ordner der Session nicht mehr — die Session kann zu. Liegen im Worktree ignorierte Dateien, die
sich nicht neu erzeugen lassen (`.env`, lokale Daten), bleibt er stehen und `/finish` fragt erst.

## Aufräumen von Hand

`git worktree list` zeigt alle; ein vergessener, schon zurückgebrachter Worktree:
`git worktree remove <pfad>` und `git branch -d <thema>` (beide verweigern, wenn noch etwas offen oder
nicht zurückgebracht ist — dann erst nachsehen, nie `--force`/`-D` aus Gewohnheit). Vorsicht: ignorierte Dateien
löscht `worktree remove` kommentarlos mit — vorher `git -C <pfad> status --ignored` ansehen. Und ein sauberer
Worktree wird auch mit noch nicht zurückgebrachten Commits entfernt; der Branch bleibt dann aber, weil
`branch -d` ihn schützt.
