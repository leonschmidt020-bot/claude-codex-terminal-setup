# Claude × ChatGPT Terminal-Setup

Claude Code und ChatGPT (Codex CLI) als Team im selben Terminal: Claude als Haupt-Agent, GPT-5.6 als Build-Engine und Bildgenerator — mit Statusline, Umschalt-Befehlen und paralleler Bild-Pipeline.

Gebaut von Joel + Claude (Fable 5) + ChatGPT (GPT-5.6 Sol) am 09./10.07.2026. Diese Anleitung enthält alle Stolperfallen, die wir dabei gelöst haben.

## Was du am Ende hast

1. **Statusline** unten im Claude-Code-Terminal: `Modell: Fable 5 (max) · Codex: gpt-5.6-sol ● aktiv · Kontext: 18%` — zeigt live dein Claude-Modell, das konfigurierte GPT-Modell, ob Codex gerade arbeitet (grüner Punkt) und die Kontext-Auslastung.
2. **`/gpt <Auftrag>`** — reicht einen Prompt direkt an ChatGPT durch, Claude gibt die Antwort gekennzeichnet wieder.
3. **`/gptmodel [an|aus|sol|terra|luna|5.5]`** — Picker bzw. Direktbefehl: ChatGPT-Zusammenarbeit an/aus + GPT-Modell wechseln (mit automatischem Verify).
4. **`/bild [schnell] [Nx] <Motiv>`** — Bildgenerierung über ChatGPT: läuft im Hintergrund, öffnet sich automatisch, kann N Bilder **parallel** (3 Bilder in ~69s statt 3×2min!), unterstützt Referenzbilder für Stil-/Personen-Treue.

## Voraussetzungen

- **Claude Code** (CLI/Desktop) — Statusline & Commands sind Claude-Code-Features
- **Codex CLI** (kommt mit der Codex-Desktop-App, `codex --version` ≥ 0.144) — eingeloggt per ChatGPT-Konto (`codex login`)
- ChatGPT-Abo (Plus/Pro) — Pro empfohlen
- `jq` (macOS: vorinstalliert unter /usr/bin/jq)

## Installation (5 Minuten)

```bash
# 1. Statusline-Script
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

# 2. Slash-Commands
mkdir -p ~/.claude/commands
cp commands/*.md ~/.claude/commands/

# 3. Zusammenarbeit-Schalter initialisieren
printf 'on' > ~/.claude/codex-collab
```

Dann in `~/.claude/settings.json` den Block aus `settings-snippet.json` einfügen (auf oberster Ebene, bestehende Keys nicht ersetzen!):

```json
"statusLine": {
  "type": "command",
  "command": "/Users/DEIN_USER/.claude/statusline.sh",
  "refreshInterval": 5
}
```

Claude Code neu starten → Statusline erscheint.

## GPT-5.6 in Codex aktivieren (das große Gotcha!)

In `~/.codex/config.toml` ganz oben:

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "high"
```

⚠️ **Die Slugs heißen `gpt-5.6-sol` (Flagship), `gpt-5.6-terra` (balanced), `gpt-5.6-luna` (schnell).** Der nackte Slug `gpt-5.6` gibt mit ChatGPT-Account-Login einen irreführenden 400-Fehler („not supported when using Codex with a ChatGPT account") — genau wie `gpt-5.6-sol-pro` (App-only) und `gpt-5.5-pro`. Verify-Einzeiler:

```bash
codex exec --skip-git-repo-check -m gpt-5.6-sol "Reply with exactly: OK"
```

⚠️ `xhigh` als Effort wird zwar akzeptiert, hing aber am GA-Tag minutenlang → `high` nehmen und später testen.

## Wie die Bild-Pipeline funktioniert (Kern-Patterns)

**Basis-Aufruf** (so macht es der /bild-Command intern):

```bash
MARKER="/tmp/img-marker-$$"; touch "$MARKER"
printf '%s' "Use your image generation tool immediately, no questions. <MOTIV>" \
  | codex exec --skip-git-repo-check -c 'mcp_servers={}' > /tmp/img-log.txt 2>&1
IMG=$(find ~/.codex/generated_images -name "*.png" -newer "$MARKER" -print0 | xargs -0 ls -t | head -1)
[ -n "$IMG" ] && cp "$IMG" ~/Downloads/bild.png && open ~/Downloads/bild.png
```

**Die Gotchas, die uns Stunden gekostet haben:**

| Gotcha | Fix |
|---|---|
| Bilder landen NIE im cwd — Codex-Sandbox blockt fremde Pfade | Immer aus `~/.codex/generated_images/` abholen und selbst kopieren |
| Referenzbild `-i bild.png` **frisst den Prompt** (variadisches Flag) → Codex wartet ewig auf stdin | Bei `-i` den Prompt IMMER pipen: `printf '%s' "PROMPT" \| codex exec -i ref.png` |
| „Neuestes PNG der letzten X Minuten" öffnet alte Testbilder | Marker-File + `find -newer "$MARKER"` |
| `find -newermt "-5 minutes"` schlägt auf macOS still fehl | `find -mmin -5` verwenden |
| `wait $pids` mit PID-String schlägt in zsh fehl („job not found") | `wait` OHNE Argumente (wartet auf alle Kinder) |
| Fehler unsichtbar bei `>/dev/null 2>&1` | Output immer in Log-Datei, bei Misserfolg `tail` zeigen |
| Lange Prompts inline = Quoting-Hölle, Codex hängt ohne Session-Log | Prompt in Datei bzw. via `printf \| stdin` übergeben |
| Ein Bild dauert 1–4 min (OpenAI-Renderzeit, nicht fixbar — die ChatGPT-App streamt nur früher eine Vorschau) | **Parallelisieren!** N Läufe mit `&` starten — N Bilder dauern wie 1 |
| Approval-Pflichten blocken MCP-Tools in `codex exec` still („user cancelled MCP tool call") | `-c 'approval_policy="never"'` für den Lauf |

**Parallel-Beispiel** (3 Bilder gleichzeitig):

```bash
for MOTIV in "icon rocket" "icon bolt" "icon trophy"; do
  printf '%s' "Use your image generation tool immediately. One square image: $MOTIV" \
    | codex exec --skip-git-repo-check -c 'mcp_servers={}' >/dev/null 2>&1 &
done
wait   # ohne Argumente!
```

**Qualitäts-Faustregel:** Flat-/Vektor-Illustrationen → im Prompt „quality medium, speed matters" (halbe Zeit, optisch gleich). Fotorealistisch → „highest quality, maximum detail". Referenzbilder machen Stil-Matching dramatisch besser — Personen-Gesichter werden „ähnlich", nie 100% identisch.

## Statusline-Detail

`statusline.sh` bekommt von Claude Code Session-JSON auf stdin (`.model.display_name`, `.effort.level`, `.context_window.used_percentage`), liest das Codex-Modell aus `~/.codex/config.toml` (nur Top-Level, stoppt vor der ersten `[section]`) und zeigt den grünen „● aktiv"-Punkt nur, wenn ein ECHTES codex-Binary läuft — Pattern `(^|/)codex (exec|e) `, mit Ausschluss von Notify-Prozessen (`SkyComputerUse`), sonst gibt es Dauer-Fehlalarm. Steht `~/.claude/codex-collab` auf `off`, zeigt sie gedimmt `Codex: aus`.

## Was Codex sonst noch kann (alles per Zuruf an Claude)

- **Office-Dateien**: PowerPoint / Excel / Word über die Codex-Plugins `presentations` / `spreadsheets` / `documents`
- **Code-Review als Zweitmeinung**: `codex review`
- **Browser-Steuerung**: eigene MCP-Server (playwright/chrome-devtools) — Approval-Gotcha oben beachten
- **Rescue**: bei festgefahrenen Bugs GPT als frischen Blick draufwerfen lassen

Viel Spaß! — Joel, Claude & GPT 🤝
