#!/usr/bin/env python3
"""Aggregiert die lokale Claude-Code-Nutzung eines Zeitraums zu einem JSON-Blob.

Liest ausschliesslich lokale Dateien unter ~/.claude:
  projects/*/*.jsonl   Transkripte  -> Tokens, Modelle, Tools, Skills, Projekte, Stunden
  cost-log/YYYY-MM/*   USD je Session (von Claude Code selbst geschrieben)
  history.jsonl        jeder Prompt mit Zeitstempel -> Streak ueber die ganze Historie
Optional (nur mit --limits): api.anthropic.com/api/oauth/usage fuer die Limit-Auslastung.

Ausgabe: ein JSON-Objekt auf stdout. Rendern macht render.py.
"""
from __future__ import annotations

import argparse
import collections
import datetime as dt
import glob
import json
import os
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
CLAUDE = os.environ.get("CLAUDE_CONFIG_DIR", os.path.join(HOME, ".claude"))

# USD je 1 Mio Token (Anthropic-Listenpreise). cache write 5m = 1.25x, 1h = 2x,
# cache read = 0.1x des Input-Preises.
PRICES = {
    "claude-fable-5":   (10.0, 50.0),
    "claude-mythos-5":  (10.0, 50.0),
    "claude-opus-5":    (5.0, 25.0),
    "claude-opus-4-8":  (5.0, 25.0),
    "claude-opus-4-7":  (5.0, 25.0),
    "claude-opus-4-6":  (5.0, 25.0),
    "claude-sonnet-5":  (2.0, 10.0),
    "claude-sonnet-4-6": (3.0, 15.0),
    "claude-haiku-4-5": (1.0, 5.0),
}
FALLBACK_PRICE = (5.0, 25.0)

# Wie lange dieselbe Arbeit ohne Claude gedauert haette.
#
# Gezaehlt wird pro *Auftrag* (ein getippter Prompt und alles, was daraus folgt),
# nicht pro Werkzeug-Aufruf. Das ist der Punkt: ohne Claude haette man dieselben
# Shell-Befehle nie getippt - man haette das Ziel anders erreicht, mit Editor,
# Finder, Suchmaschine, Ausprobieren. Ausserdem bleibt die Zahl so stabil, wenn
# ein Modell dieselbe Aufgabe mit 5 statt 50 Aufrufen loest.
#
# Ein Auftrag wird nach seinem Umfang eingestuft; Minuten je Klasse:
TASK_MINUTES = {
    "trivial": 1,    # "ja", "mach weiter", kurze Rueckfrage - ersetzt kaum Arbeit
    "klein": 6,      # kurz nachsehen, eine Datei oeffnen, Kleinigkeit korrigieren
    "mittel": 20,    # mehrere Dateien anfassen, eine echte Aenderung durchziehen
    "gross": 180,    # etwas von null bauen (~300 Zeilen) inkl. Recherche und Sackgassen
}


def task_class(calls: int, lines: int, files: int, web: int) -> str:
    """Umfang eines Auftrags aus dem, was daraufhin tatsaechlich passiert ist."""
    if lines > 200 or calls > 30:
        return "gross"
    if files or calls > 10:
        return "mittel"
    if calls > 2 or web:
        return "klein"
    return "trivial"


# Was ein Abo im Monat kostet (USD) - Basis fuer den "x-fach rausgeholt"-Vergleich.
PLANS = {"pro": 20.0, "max5": 100.0, "max20": 200.0, "team": 30.0}

PRETTY_MODEL = {
    "claude-fable-5": "Fable 5",
    "claude-mythos-5": "Mythos 5",
    "claude-opus-5": "Opus 5",
    "claude-opus-4-8": "Opus 4.8",
    "claude-opus-4-7": "Opus 4.7",
    "claude-opus-4-6": "Opus 4.6",
    "claude-sonnet-5": "Sonnet 5",
    "claude-sonnet-4-6": "Sonnet 4.6",
    "claude-haiku-4-5-20251001": "Haiku 4.5",
    "claude-haiku-4-5": "Haiku 4.5",
}


def price_for(model: str) -> tuple[float, float]:
    if model in PRICES:
        return PRICES[model]
    for key, val in PRICES.items():            # dated snapshots: claude-haiku-4-5-20251001
        if model and model.startswith(key):
            return val
    return FALLBACK_PRICE


def pretty_model(model: str) -> str:
    if model in PRETTY_MODEL:
        return PRETTY_MODEL[model]
    return (model or "?").replace("claude-", "").replace("-", " ").title()


def parse_ts(value: str) -> dt.datetime | None:
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (ValueError, AttributeError):
        return None


# ---------------------------------------------------------------- Transkripte

def scan_transcripts(since: dt.datetime, until: dt.datetime) -> dict:
    tok = collections.Counter()
    cost_by_model = collections.Counter()
    turns_by_model = collections.Counter()
    tools = collections.Counter()
    skills = collections.Counter()
    projects = collections.Counter()
    by_hour = collections.Counter()
    by_day = collections.Counter()
    files_touched = collections.Counter()
    extensions = collections.Counter()
    sessions: set[str] = set()
    prompts = 0
    subagents = 0
    tasks = collections.Counter()   # Auftraege je Umfangsklasse
    task = None                     # laufender Auftrag
    latest_night = None            # spaetester Turn in "Nachtstunden" (lokal 0-5 Uhr)
    day_span: dict[str, list] = {}  # Tag -> [erster, letzter] Turn (lokal)

    # mtime-Vorfilter: eine Datei, die lange vor dem Zeitraum zuletzt geschrieben
    # wurde, kann keine Zeilen darin haben. Spart bei 289 MB Transkripten viel I/O.
    cutoff = since.timestamp() - 86400

    for path in glob.glob(os.path.join(CLAUDE, "projects", "*", "*.jsonl")):
        try:
            if os.path.getmtime(path) < cutoff:
                continue
            handle = open(path, errors="ignore")
        except OSError:
            continue
        with handle:
            rows = []
            for line in handle:
                try:
                    rec = json.loads(line)
                except ValueError:
                    continue
                stamp = parse_ts(rec.get("timestamp", ""))
                if stamp is None or not (since <= stamp <= until):
                    continue
                rows.append((stamp, rec))
            rows.sort(key=lambda row: row[0])
            if task is not None:               # Auftrag endet an der Dateigrenze
                tasks[task_class(**task)] += 1
                task = None
            for stamp, rec in rows:
                local = stamp.astimezone()
                day = local.date().isoformat()
                by_hour[local.hour] += 1
                by_day[day] += 1
                span = day_span.setdefault(day, [local, local])
                span[0] = min(span[0], local)
                span[1] = max(span[1], local)
                if local.hour < 6 and (latest_night is None or local.hour > latest_night.hour
                                       or (local.hour == latest_night.hour
                                           and local.minute > latest_night.minute)):
                    latest_night = local
                if rec.get("sessionId"):
                    sessions.add(rec["sessionId"])
                if rec.get("cwd"):
                    projects[rec["cwd"]] += 1

                kind = rec.get("type")
                if kind == "assistant":
                    msg = rec.get("message", {}) or {}
                    usage = msg.get("usage", {}) or {}
                    model = msg.get("model") or "?"
                    turns_by_model[model] += 1
                    if rec.get("attributionSkill"):
                        skills[rec["attributionSkill"]] += 1

                    inp = usage.get("input_tokens", 0)
                    out = usage.get("output_tokens", 0)
                    cw = usage.get("cache_creation_input_tokens", 0)
                    cr = usage.get("cache_read_input_tokens", 0)
                    creation = usage.get("cache_creation", {}) or {}
                    cw1h = creation.get("ephemeral_1h_input_tokens", 0)
                    cw5m = creation.get("ephemeral_5m_input_tokens", cw - cw1h)
                    tok["input"] += inp
                    tok["output"] += out
                    tok["cache_write"] += cw
                    tok["cache_read"] += cr
                    tok["thinking"] += (usage.get("output_tokens_details") or {}).get(
                        "thinking_tokens", 0)
                    server = usage.get("server_tool_use") or {}
                    tok["web_search"] += server.get("web_search_requests", 0)
                    tok["web_fetch"] += server.get("web_fetch_requests", 0)

                    p_in, p_out = price_for(model)
                    cost_by_model[model] += (
                        inp * p_in + out * p_out
                        + cw5m * p_in * 1.25 + cw1h * p_in * 2.0
                        + cr * p_in * 0.1
                    ) / 1_000_000

                    content = msg.get("content")
                    if isinstance(content, list):
                        for block in content:
                            if not isinstance(block, dict):
                                continue
                            if block.get("type") != "tool_use":
                                continue
                            name = block.get("name", "?")
                            tools[name] += 1
                            if name == "Agent":
                                subagents += 1
                            if name in ("Edit", "Write", "NotebookEdit"):
                                data = block.get("input") or {}
                                target = data.get("file_path", "")
                                if target:
                                    files_touched[target] += 1
                                    ext = os.path.splitext(target)[1].lower()
                                    if ext:
                                        extensions[ext] += 1
                                # geschriebene Zeilen: bei Write der ganze Inhalt,
                                # bei Edit nur der neue Text
                                body = data.get("content") or data.get("new_string") or ""
                                lines = body.count("\n") + 1 if body else 0
                                tok["lines"] += lines
                                if task is not None:
                                    task["files"] += 1
                                    task["lines"] += lines
                            if task is not None:
                                task["calls"] += 1
                                if name in ("WebSearch", "WebFetch"):
                                    task["web"] += 1
                elif kind == "user":
                    # echte Tastatur-Prompts: kein Tool-Result, kein Meta-Einschub,
                    # nichts aus einem Subagenten - die zaehlen zum laufenden Auftrag
                    msg = rec.get("message", {}) or {}
                    if (not rec.get("isMeta")
                            and not rec.get("isSidechain")
                            and rec.get("promptSource") != "tool"
                            and isinstance(msg.get("content"), str)):
                        prompts += 1
                        if task is not None:
                            tasks[task_class(**task)] += 1
                        task = {"calls": 0, "lines": 0, "files": 0, "web": 0}

    if task is not None:
        tasks[task_class(**task)] += 1

    return dict(
        tok=tok, cost_by_model=cost_by_model, turns_by_model=turns_by_model,
        tools=tools, skills=skills, projects=projects, by_hour=by_hour, by_day=by_day,
        files=files_touched, extensions=extensions, sessions=sessions, prompts=prompts,
        subagents=subagents, latest_night=latest_night, day_span=day_span,
        tasks=tasks,
    )


# ------------------------------------------------------------------ cost-log

def scan_cost_log(since: dt.datetime, until: dt.datetime, session_ids: set[str]) -> float:
    """Summe der von Claude Code selbst protokollierten USD je Session.

    Nur Sessions, die im Zeitraum ueberhaupt aktiv waren; laeuft eine Session ueber
    den Rand hinaus, faellt ihr voller Betrag hinein - deshalb ist das eine Naeherung
    und nicht die Zahl, auf der die Prahlerei steht.
    """
    total = 0.0
    for month_dir in glob.glob(os.path.join(CLAUDE, "cost-log", "*")):
        if not os.path.isdir(month_dir):
            continue
        for path in glob.glob(os.path.join(month_dir, "*")):
            sid = os.path.basename(path)
            if sid not in session_ids:
                continue
            try:
                with open(path) as handle:
                    total += float(handle.read().strip() or 0)
            except (OSError, ValueError):
                continue
    return total


# --------------------------------------------------------------- history/streak

def scan_history() -> dict:
    """Aktive Tage aus history.jsonl -> laufender Streak + laengster Streak."""
    days: set[dt.date] = set()
    path = os.path.join(CLAUDE, "history.jsonl")
    try:
        handle = open(path, errors="ignore")
    except OSError:
        return {"streak_current": 0, "streak_best": 0, "days_total": 0}
    with handle:
        for line in handle:
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            ms = rec.get("timestamp")
            if isinstance(ms, (int, float)):
                days.add(dt.datetime.fromtimestamp(ms / 1000).date())

    if not days:
        return {"streak_current": 0, "streak_best": 0, "days_total": 0}

    ordered = sorted(days)
    best = run = 1
    for prev, cur in zip(ordered, ordered[1:]):
        run = run + 1 if (cur - prev).days == 1 else 1
        best = max(best, run)

    today = dt.date.today()
    current = 0
    cursor = today if today in days else today - dt.timedelta(days=1)
    while cursor in days:
        current += 1
        cursor -= dt.timedelta(days=1)
    return {"streak_current": current, "streak_best": best, "days_total": len(days)}


# -------------------------------------------------------------------- Kurs

FALLBACK_EUR = 0.92                # nur wenn Cache leer und Netz weg


def usd_eur_rate(timeout: int = 4) -> tuple[float, bool]:
    """USD->EUR. Teilt sich Datei und Quelle mit der Status Line, damit beide
    Zahlen zusammenpassen; hoechstens ein Abruf pro Tag. Zweiter Rueckgabewert
    sagt, ob der Kurs echt ist - sonst steht ein Naeherungszeichen auf der Karte."""
    cache = os.path.join(CLAUDE, ".usd_eur_rate")
    try:
        if os.path.exists(cache) and time.time() - os.path.getmtime(cache) < 86400:
            value = float(open(cache).read().strip())
            if value > 0:
                return value, True
    except (OSError, ValueError):
        pass
    try:
        raw = subprocess.run(
            ["curl", "-s", "--max-time", str(timeout),
             "https://open.er-api.com/v6/latest/USD"],
            capture_output=True, text=True, timeout=timeout + 2).stdout
        value = float((json.loads(raw).get("rates") or {})["EUR"])
        if value > 0:
            with open(cache, "w") as handle:
                handle.write(str(value))
            return value, True
    except (subprocess.SubprocessError, ValueError, KeyError, OSError):
        pass
    try:                                # abgelaufener Cache ist besser als geraten
        value = float(open(cache).read().strip())
        if value > 0:
            return value, False
    except (OSError, ValueError):
        pass
    return FALLBACK_EUR, False


# ------------------------------------------------------------------- Limits

def fetch_limits(timeout: int = 6) -> dict:
    """Aktuelle Limit-Auslastung vom OAuth-Usage-Endpoint (Momentaufnahme).

    Gleiche Quelle wie die Status Line. Schlaegt der Abruf fehl (offline, 429,
    kein Token), liefern wir {} - das Bild laesst den Block dann einfach weg,
    statt eine Zahl zu erfinden.
    """
    token = ""
    cred = os.path.join(CLAUDE, ".credentials.json")
    try:
        if os.path.exists(cred):
            with open(cred) as handle:
                token = (json.load(handle).get("claudeAiOauth") or {}).get("accessToken", "")
        elif sys.platform == "darwin":
            raw = subprocess.run(
                ["security", "find-generic-password", "-s", "Claude Code-credentials", "-w"],
                capture_output=True, text=True, timeout=timeout).stdout
            token = (json.loads(raw).get("claudeAiOauth") or {}).get("accessToken", "")
    except (OSError, ValueError, subprocess.SubprocessError):
        return {}
    if not token:
        return {}

    try:
        raw = subprocess.run(
            ["curl", "-s", "--max-time", str(timeout),
             "https://api.anthropic.com/api/oauth/usage",
             "-H", f"Authorization: Bearer {token}",
             "-H", "anthropic-beta: oauth-2025-04-20"],
            capture_output=True, text=True, timeout=timeout + 2).stdout
        payload = json.loads(raw)
    except (subprocess.SubprocessError, ValueError):
        return {}

    out = {}
    for limit in payload.get("limits") or []:
        pct = limit.get("percent")
        if pct is None:
            continue
        kind = limit.get("kind")
        if kind == "weekly_scoped":
            scope = ((limit.get("scope") or {}).get("model") or {}).get("display_name") or "Modell"
            out["scoped"] = {"label": f"{scope}-Woche", "percent": pct}
        elif kind in ("five_hour", "weekly", "seven_day"):
            label = {"five_hour": "5-Stunden-Fenster", "weekly": "Wochenlimit",
                     "seven_day": "7-Tage-Fenster"}[kind]
            out[kind] = {"label": label, "percent": pct}
    return out


# --------------------------------------------------------------------- main

def build(args) -> dict:
    until = dt.datetime.now(dt.timezone.utc)
    since = until - dt.timedelta(days=args.days)
    if args.since:
        since = dt.datetime.fromisoformat(args.since).astimezone(dt.timezone.utc)
    if args.until:
        until = dt.datetime.fromisoformat(args.until).astimezone(dt.timezone.utc)

    tx = scan_transcripts(since, until)
    tok = tx["tok"]
    api_cost = sum(tx["cost_by_model"].values())
    logged_cost = scan_cost_log(since, until, tx["sessions"])
    history = scan_history()

    rate, rate_live = usd_eur_rate()
    span_days = max(1, (until - since).days)
    plan_share = PLANS.get(args.plan, PLANS["max20"]) / 30.0 * span_days

    busiest_day, busiest_msgs = ("", 0)
    if tx["by_day"]:
        busiest_day, busiest_msgs = max(tx["by_day"].items(), key=lambda kv: kv[1])
    longest_day, longest_hours = ("", 0.0)
    for day, (first, last) in tx["day_span"].items():
        hours = (last - first).total_seconds() / 3600
        if hours > longest_hours:
            longest_day, longest_hours = day, hours

    def top(counter, n=5, key=lambda k: k):
        return [{"name": key(name), "count": count} for name, count in counter.most_common(n)]

    return {
        "period": {
            "since": since.astimezone().isoformat(timespec="minutes"),
            "until": until.astimezone().isoformat(timespec="minutes"),
            "days": span_days,
            "active_days": len(tx["by_day"]),
        },
        "volume": {
            "sessions": len(tx["sessions"]),
            "prompts": tx["prompts"],
            "tool_calls": sum(tx["tools"].values()),
            "subagents": tx["subagents"],
            "files_touched": len(tx["files"]),
            "lines_written": tok["lines"],
            # Schaetzung, keine Messung - Gewichte siehe TASK_MINUTES oben
            "tasks": dict(tx["tasks"]),
            "handwork_hours": round(sum(
                TASK_MINUTES[k] * n for k, n in tx["tasks"].items()) / 60, 1),
            "web_searches": tok["web_search"] + tok["web_fetch"],
        },
        "tokens": {
            "input": tok["input"], "output": tok["output"],
            "cache_write": tok["cache_write"], "cache_read": tok["cache_read"],
            "thinking": tok["thinking"],
            "total": tok["input"] + tok["output"] + tok["cache_write"] + tok["cache_read"],
        },
        "money": {
            "api_eur": round(api_cost * rate, 2),
            "logged_eur": round(logged_cost * rate, 2),
            "plan": args.plan,
            "plan_share_eur": round(plan_share * rate, 2),
            "leverage": round(api_cost / plan_share, 1) if plan_share else None,
            "usd_eur": round(rate, 4),
            "rate_live": rate_live,
            # Listenpreise sind in USD - fuer den Nachvollzug bleiben sie stehen
            "api_usd": round(api_cost, 2),
        },
        "models": [{"name": pretty_model(m), "turns": c,
                    "eur": round(tx["cost_by_model"][m] * rate, 2)}
                   for m, c in tx["turns_by_model"].most_common()
                   if not m.startswith("<")],
        # Bewusst ohne Namen: Projekt- und Dateinamen sind privat und haben auf
        # einem Bild, das in einem Gruppenchat landet, nichts zu suchen. Nur
        # Zaehlungen - und Werkzeugnamen, die bei allen gleich heissen.
        "tools": top(tx["tools"], 8),
        "skills": top(tx["skills"], 5),
        "projects_count": len(tx["projects"]),
        "extensions": top(tx["extensions"], 6),
        "rhythm": {
            "by_hour": [tx["by_hour"].get(h, 0) for h in range(24)],
            "by_day": sorted(tx["by_day"].items()),
            "peak_hour": max(tx["by_hour"], key=tx["by_hour"].get) if tx["by_hour"] else None,
            "latest_night": tx["latest_night"].strftime("%H:%M") if tx["latest_night"] else None,
            "busiest_day": busiest_day, "busiest_day_msgs": busiest_msgs,
            "longest_day": longest_day, "longest_day_hours": round(longest_hours, 1),
            **history,
        },
        "limits": fetch_limits() if args.limits else {},
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--days", type=int, default=7, help="Zeitraum in Tagen (Default 7)")
    parser.add_argument("--since", help="ISO-Datum, ueberschreibt --days")
    parser.add_argument("--until", help="ISO-Datum, Default jetzt")
    parser.add_argument("--plan", default="max20", choices=sorted(PLANS),
                        help="Abo fuer den Kosten-Vergleich (Default max20)")
    parser.add_argument("--limits", action="store_true",
                        help="Limit-Auslastung live abfragen (Netz noetig)")
    parser.add_argument("-o", "--out", help="Zieldatei statt stdout")
    args = parser.parse_args()

    data = build(args)
    text = json.dumps(data, indent=2, ensure_ascii=False)
    if args.out:
        with open(args.out, "w") as handle:
            handle.write(text)
        print(args.out)
    else:
        print(text)


if __name__ == "__main__":
    main()
