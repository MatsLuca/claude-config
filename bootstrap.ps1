# bootstrap.ps1 — Frischen Windows-Rechner in einem Rutsch einrichten:
#   1. Claude Code installieren (falls noch nicht da)
#   2. Marketplace `claude-config` registrieren
#   3. Plugin `mats-tools` installieren (user-scope)
#
# Danach beim nächsten `claude`-Start: einloggen und als ersten Prompt
# "Führe das machine-setup durch." schicken (yolo-Alias, Status Line,
# Auto-Update, settings.json).
#
# Aufruf auf einem neuen Rechner (PowerShell):
#   irm https://raw.githubusercontent.com/MatsLuca/claude-config/master/bootstrap.ps1 | iex
#
# Idempotent: erneutes Ausführen schadet nicht.

$ErrorActionPreference = 'Stop'

$Marketplace = 'MatsLuca/claude-config'
$Plugin      = 'mats-tools@claude-config'
$InstallUrl  = 'https://claude.ai/install.ps1'

# ── Ausgabe-Helfer ────────────────────────────────────────────────────────────
function Log($m)  { Write-Host "*  $m" -ForegroundColor Blue }
function Ok($m)   { Write-Host "OK $m" -ForegroundColor Green }
function Warn($m) { Write-Host "!  $m" -ForegroundColor Yellow }
function Die($m)  { Write-Host "X  $m" -ForegroundColor Red; throw $m }

# ── 1. Voraussetzungen ────────────────────────────────────────────────────────
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Die 'git wird benoetigt (klont den Marketplace): https://git-scm.com/download/win'
}

# ── 2. Claude Code finden oder installieren ───────────────────────────────────
# Bevorzugt die echte Binärdatei (~\.local\bin), umgeht so PATH-Timing-Probleme
# direkt nach der Installation.
function Find-Claude {
    $candidates = @(
        (Get-Command claude -ErrorAction SilentlyContinue).Source,
        (Join-Path $env:USERPROFILE '.local\bin\claude.exe')
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    return $null
}

$claude = Find-Claude
if (-not $claude) {
    Log 'Claude Code nicht gefunden - installiere ...'
    Invoke-RestMethod $InstallUrl | Invoke-Expression
    $env:Path = "$(Join-Path $env:USERPROFILE '.local\bin');$env:Path"
    $claude = Find-Claude
    if (-not $claude) {
        Die "Installation lief durch, aber 'claude' ist nicht auffindbar. Oeffne ein neues Terminal und fuehre das Skript erneut aus."
    }
    Ok "Claude Code installiert: $claude"
} else {
    Ok "Claude Code vorhanden: $claude"
}

# ── 3. Marketplace + Plugin (idempotent) ──────────────────────────────────────
Log "Registriere Marketplace: $Marketplace"
& $claude plugin marketplace add $Marketplace
if ($LASTEXITCODE -ne 0) { Warn 'Marketplace evtl. bereits registriert - fahre fort.' }

Log "Installiere Plugin: $Plugin"
& $claude plugin install $Plugin --scope user
if ($LASTEXITCODE -ne 0) { Warn 'Plugin evtl. bereits installiert - fahre fort.' }

# ── 4. Fertig ─────────────────────────────────────────────────────────────────
Ok "Bootstrap abgeschlossen. Beim naechsten Start ist $Plugin aktiv."
Write-Host ''
Write-Host 'Naechster Schritt:'
Write-Host "  'claude' starten (beim ersten Mal ggf. einloggen) und als ersten Prompt schicken:"
Write-Host '      "Fuehre das machine-setup durch."'
