#!/bin/sh
# limit-stats.sh — reicht ein kleineres Claude-Abo? Wertet das Limit-Log der
# Status Line aus (~/.claude/limit-log/*.tsv, eine Zeile/min: epoch, 5h-%,
# 5h-Reset, 7d-%, 7d-Reset, Fable-%).
#
#   sh limit-stats.sh [--faktor N] [--alle]
#
# --faktor N  Verhältnis des aktuellen Abos zum kleineren (Standard 5: Max 5x →
#             Pro; Max 20x → Max 5x wäre 4). Schwelle = 100/N %. Laut
#             claude.com/pricing gilt der Faktor fürs 5-h- *und* fürs Wochenfenster.
# --alle      jedes 5-h-Fenster einzeln listen, nicht nur die gerissenen.
#
# Portabel (macOS + Linux): Datumsformat per Probe auf GNU date, sonst BSD.
DIR="$HOME/.claude/limit-log"
F=5; ALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --faktor) F=$2; shift ;;
    --alle) ALL=1 ;;
    *) echo "usage: limit-stats.sh [--faktor N] [--alle]" >&2; exit 2 ;;
  esac; shift
done
ls "$DIR"/*.tsv >/dev/null 2>&1 || { echo "Noch kein Log in $DIR — die Status Line schreibt es während der Arbeit."; exit 0; }

if date -d @0 +%s >/dev/null 2>&1; then fmt() { date -d "@$1" "+$2"; }
else fmt() { date -r "$1" "+$2"; }; fi

# awk liefert Rohzeilen (Typ|Felder…), die Shell formatiert nur noch die Daten.
cat "$DIR"/*.tsv | sort -n | awk -F'\t' -v F="$F" -v ALL="$ALL" '
  $2 == "" || $3 == "" { next }
  {
    n++; if (!first) first = $1; last = $1
    day[int(($1 + 0) / 86400)] = 1
    w5 = int(($3 + 300) / 600) * 600          # Reset-Zeit auf 10 min gerundet = Fenster-ID
    if (!(w5 in p5)) { o5[++k5] = w5; p5[w5] = 0 }
    if ($2 + 0 > p5[w5]) p5[w5] = $2 + 0
    if (!(w5 in hit) && $2 + 0 >= 100 / F) hit[w5] = $1
    if ($5 != "") {
      w7 = int(($5 + 1800) / 3600) * 3600
      if (!(w7 in p7)) { o7[++k7] = w7; p7[w7] = 0 }
      if ($4 + 0 > p7[w7]) p7[w7] = $4 + 0
      if (!(w7 in hit7) && $4 + 0 >= 100 / F) hit7[w7] = $1
    }
    if ($6 != "" && $6 + 0 > fab) fab = $6 + 0
  }
  END {
    th = 100 / F; nd = 0; for (d in day) nd++
    print "META|" n "|" first "|" last "|" nd "|" th "|" fab
    over = 0
    for (i = 1; i <= k5; i++) {
      w = o5[i]; o = (p5[w] >= th)
      over += o
      if (o || ALL) print "W5|" w "|" p5[w] "|" (o ? hit[w] : "") "|" p5[w] * F
    }
    print "S5|" k5 "|" over
    over7 = 0
    for (i = 1; i <= k7; i++) {
      w = o7[i]; o = (p7[w] >= th); over7 += o
      # voll = Log lief schon vor Wochenbeginn und die Woche ist vorbei
      full = (first <= w - 7 * 86400 + 3600) ? (w <= last ? 1 : 2) : 0
      print "W7|" w "|" p7[w] "|" (o ? hit7[w] : "") "|" p7[w] * F "|" full
    }
    print "S7|" k7 "|" over7
  }' | while IFS='|' read -r t a b c d e f; do
  case "$t" in
    META)
      start=$b
      echo "Limit-Log: $a Messpunkte, $d Tage mit Arbeit, $(fmt "$b" %d.%m.%Y) bis $(fmt "$c" %d.%m.%Y)"
      echo "Schwelle für das 1/${F}-Abo: ${e} % des aktuellen Limits"
      [ -n "$f" ] && [ "$f" != 0 ] && echo "Fable-Wochenspitze: ${f} % — auf Pro gibt es Fable nur gegen Zusatz-Credits."
      echo; echo "5-Stunden-Fenster (gerissene; Spalten: Fenster-Ende, Spitze, kleineres Abo wäre bei …)" ;;
    W5)
      line="  $(fmt "$a" '%a %d.%m. %H:%M')   Spitze $(printf %.0f "$b") %  → $(printf '%.0f' "$d") % des kleinen Limits"
      if [ "$c" = "$start" ]; then line="$line, schon beim Log-Start drüber"
      elif [ -n "$c" ]; then line="$line, gestoppt ab $(fmt "$c" %H:%M) ($(( (a - c) / 60 )) min vor Reset)"; fi
      echo "$line" ;;
    S5) echo "  → $a Fenster mit Arbeit, davon $b über der Schwelle"; echo; echo "Wochenfenster" ;;
    W7)
      case "$e" in 1) v="voll gemessen" ;; 2) v="läuft noch" ;; *) v="Log begann mitten in der Woche" ;; esac
      line="  bis $(fmt "$a" '%d.%m.')   Spitze $(printf %.0f "$b") %  → $(printf '%.0f' "$d") % des kleinen Limits ($v)"
      if [ "$c" = "$start" ]; then line="$line, schon beim Log-Start drüber"
      elif [ -n "$c" ]; then line="$line, gestoppt ab $(fmt "$c" '%d.%m. %H:%M')"; fi
      echo "$line" ;;
    S7)
      echo "  → $a Wochen, davon $b über der Schwelle"; echo
      echo "Trägt das Urteil? Erst ab 2 voll gemessenen Wochen (≥ 14 Tage, besser 4 Wochen"
      echo "inkl. einer Phase mit viel Arbeit). Vorher zeigt die Liste nur eine Tendenz." ;;
  esac
done
