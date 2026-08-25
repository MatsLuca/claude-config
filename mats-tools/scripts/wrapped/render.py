#!/usr/bin/env python3
"""Rendert das Wrapped-JSON (aus aggregate.py) als teilbares PNG.

Weg: card.html + Daten -> temporaeres HTML -> Chrome headless --screenshot -> PNG
-> optional in die Zwischenablage. Chrome, weil das Layout dann in CSS lebt und
nicht in Zeichenbefehlen: Design aendern heisst card.html aendern.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(HERE, "card.html")
WIDTH, HEIGHT = 1080, 1250

# Farbwelten. Reihenfolge ist stabil: --theme waehlt per Name, sonst entscheidet
# der Zeitraum, damit derselbe Zeitraum immer dasselbe Bild ergibt.
THEMES = {
    "aurora":   "--bg0:#07070f; --bg1:#140b2e; --a1:#ff2d95; --a2:#ffd166; --a3:#22e5c8;",
    "ember":    "--bg0:#0d0503; --bg1:#2b0f06; --a1:#ff5722; --a2:#ffc93c; --a3:#ff2e63;",
    "deep":     "--bg0:#04060f; --bg1:#0a1a3d; --a1:#4d7cff; --a2:#7af8ff; --a3:#b48cff;",
    "moss":     "--bg0:#040b08; --bg1:#0c2a1c; --a1:#28e07a; --a2:#d9ff5c; --a3:#12c2b0;",
    "vhs":      "--bg0:#0a0410; --bg1:#2a0a3d; --a1:#ff00c8; --a2:#00f0ff; --a3:#ffe600;",
}

CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary",
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
]


def find_chrome() -> str:
    env = os.environ.get("CHROME_PATH")
    if env and os.path.exists(env):
        return env
    for name in ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser",
                 "brave-browser", "microsoft-edge"):
        found = shutil.which(name)
        if found:
            return found
    for path in CHROME_CANDIDATES:
        if os.path.exists(path):
            return path
    sys.exit("Kein Chrome/Chromium gefunden. Pfad ueber CHROME_PATH setzen.")


def pick_theme(data: dict, wanted: str | None) -> str:
    if wanted and wanted in THEMES:
        return wanted
    if wanted:
        sys.exit(f"Unbekanntes Theme '{wanted}'. Verfuegbar: {', '.join(THEMES)}")
    names = list(THEMES)
    seed = sum(ord(c) for c in data.get("period", {}).get("since", ""))
    return names[seed % len(names)]


def default_user() -> str:
    """Name oben rechts: bevorzugt der Git-Name, sonst der Login."""
    try:
        name = subprocess.run(["git", "config", "--global", "user.name"],
                              capture_output=True, text=True, timeout=5).stdout.strip()
        if name:
            return name
    except (OSError, subprocess.SubprocessError):
        pass
    return os.environ.get("USER") or ""


def to_clipboard(png: str) -> bool:
    if sys.platform == "darwin":
        script = (f'set the clipboard to (read (POSIX file "{png}") as {{«class PNGf»}})')
        done = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
        return done.returncode == 0
    if shutil.which("wl-copy"):
        with open(png, "rb") as handle:
            return subprocess.run(["wl-copy", "-t", "image/png"], stdin=handle).returncode == 0
    if shutil.which("xclip"):
        return subprocess.run(["xclip", "-selection", "clipboard", "-t", "image/png",
                               "-i", png]).returncode == 0
    return False


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("data", help="JSON von aggregate.py ('-' fuer stdin)")
    parser.add_argument("-o", "--out", help="Ziel-PNG (Default ~/Downloads/claude-wrapped-*.png)")
    parser.add_argument("--theme", help="Farbwelt: " + ", ".join(THEMES))
    parser.add_argument("--user", help="Name oben rechts auf der Karte")
    parser.add_argument("--scale", type=float, default=2.0, help="Device-Pixel-Ratio (Default 2)")
    parser.add_argument("--timeout", type=int, default=45,
                        help="Sekunden, die Chrome bekommt (Default 45)")
    parser.add_argument("--no-clipboard", action="store_true")
    parser.add_argument("--keep-html", action="store_true", help="HTML behalten (Design-Debugging)")
    args = parser.parse_args()

    raw = sys.stdin.read() if args.data == "-" else open(args.data).read()
    data = json.loads(raw)
    data["user"] = args.user or default_user()

    html = open(TEMPLATE).read()
    html = html.replace("/* __THEME__ */", ":root{" + THEMES[pick_theme(data, args.theme)] + "}")
    html = html.replace("__DATA__", json.dumps(data, ensure_ascii=False))

    out = args.out or os.path.join(
        os.path.expanduser("~"), "Downloads",
        "claude-wrapped-" + dt.datetime.now().strftime("%Y-%m-%d") + ".png")
    os.makedirs(os.path.dirname(out), exist_ok=True)

    tmp_dir = tempfile.mkdtemp(prefix="wrapped-")
    page = os.path.join(tmp_dir, "card.html")
    with open(page, "w") as handle:
        handle.write(html)

    cmd = [
        find_chrome(), "--headless=new", "--disable-gpu", "--hide-scrollbars",
        "--no-sandbox", "--no-first-run", "--no-default-browser-check",
        "--disable-extensions", "--disable-background-networking", "--disable-sync",
        "--use-mock-keychain", "--password-store=basic",
        f"--window-size={WIDTH},{HEIGHT}",
        f"--force-device-scale-factor={args.scale}",
        f"--user-data-dir={os.path.join(tmp_dir, 'profile')}",
        f"--screenshot={out}", f"file://{page}",
    ]
    # Headless Chrome schreibt das PNG zuverlaessig, beendet sich auf macOS aber
    # nicht immer von selbst - blindes Warten kostete 45 s pro Lauf. Also pollen:
    # sobald die Datei zweimal hintereinander dieselbe Groesse hat, ist der
    # Screenshot vollstaendig und der Prozess darf weg.
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    deadline = time.monotonic() + args.timeout
    last_size = -1
    while time.monotonic() < deadline:
        if os.path.exists(out):
            size = os.path.getsize(out)
            if size > 0 and size == last_size:
                break
            last_size = size
        if proc.poll() is not None:
            break
        time.sleep(0.25)

    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
    stderr = (proc.stderr.read() if proc.stderr else "") or ""

    if not os.path.exists(out) or os.path.getsize(out) == 0:
        sys.exit("Chrome hat kein Bild geschrieben:\n" + stderr[-1500:])

    copied = False if args.no_clipboard else to_clipboard(out)
    if args.keep_html:
        print(page, file=sys.stderr)
    else:
        shutil.rmtree(tmp_dir, ignore_errors=True)
    print(json.dumps({"png": out, "clipboard": copied,
                      "size_kb": round(os.path.getsize(out) / 1024)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
