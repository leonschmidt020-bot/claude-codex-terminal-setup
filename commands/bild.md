---
description: Bild mit ChatGPT generieren, öffnet sich automatisch (Modus: schnell oder Qualität)
argument-hint: [schnell] <Motiv-Beschreibung>
---
Generiere ein Bild via Codex/ChatGPT. Argumente: "$ARGUMENTS"

**Modus bestimmen:** Beginnen die Argumente mit dem Wort `schnell`: **Schnell-Modus** (Override `-m gpt-5.6-luna`, quality medium/fast, Motiv = Rest der Argumente, Prompt kompakt). Sonst: **Qualitäts-Modus** (kein Modell-Override, im Prompt "highest quality, maximum detail" verlangen, Motiv detailliert ausschmücken: Stil, Licht, Komposition, Format).

**Mehrere Bilder (PARALLEL, nie nacheinander!):** Beginnt das Motiv mit `Nx` (z.B. `4x`) → N Varianten desselben Motivs; sind mehrere Motive mit `;` getrennt → ein Bild pro Motiv. Alle Läufe im SELBEN Bash-Befehl mit `&` starten und mit `wait` OHNE Argumente auf alle warten (zsh-Gotcha: nie `wait $pids` mit PID-String — schlägt fehl). Max. 6 parallel; mehr in Wellen. Parallel dauern N Bilder nur so lange wie das langsamste (gemessen: 3 Bilder in 69s). Danach ALLE neuen PNGs (find `-mmin`) durchnummeriert nach ~/Downloads kopieren und mit einem einzigen `open`-Aufruf alle öffnen.

**Statusline-Anzeige (immer!):** Ganz am ANFANG des Bash-Befehls die Status-Datei schreiben: `printf '%s|%s' "<N>" "<modus>" > ~/.claude/img-status` (N = Anzahl Bilder, modus = `schnell` oder `hoch`; die mtime der Datei = Startzeit und Zähl-Referenz für die Statusline). Ganz am ENDE des Befehls (nach open): `rm -f ~/.claude/img-status`. Die Statusline unten zeigt dann live „Bilder: 1/3 · ~62% · hoch".

**Ablauf — genau EIN Bash-Aufruf, IMMER mit `run_in_background: true` und timeout 570000:**
1. Baue aus dem Motiv einen englischen Bild-Prompt. Nur einfache ASCII-Zeichen, KEINE Apostrophe/Sonderzeichen (Quoting!). Beginne immer mit: `Use your image generation tool immediately, no questions.`
2. Befehlsmuster (Slug = kurzer Dateiname aus dem Motiv + Datum):
   `codex exec --skip-git-repo-check [-m gpt-5.6-luna] -c 'mcp_servers={}' "<PROMPT>" 2>/dev/null | tail -2; IMG=$(find ~/.codex/generated_images -name "*.png" -mmin -10 -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1); if [ -n "$IMG" ]; then cp "$IMG" ~/Downloads/<slug>.png && open ~/Downloads/<slug>.png && echo "BILD_GEOEFFNET"; else echo "KEIN_BILD"; fi`
   (WICHTIG: fürs Bild-Suchen `-mmin -10` verwenden, NIE `-newermt` mit relativer Zeit — das schlägt auf macOS/BSD-find fehl.)
3. Direkt nach dem Start dem Nutzer in 1–2 Sätzen sagen: läuft im Hintergrund, Bild öffnet sich automatisch in der Vorschau (Schnell-Modus ~1 Min, Qualitäts-Modus ~2–4 Min, je nach OpenAI-Serverlast). Turn beenden, NICHT im Vordergrund warten.
4. Bei der Task-Notification: Output prüfen. `BILD_GEOEFFNET` → Bild mit Read ansehen, in einem Satz bestätigen/beschreiben (+ Pfad ~/Downloads/<slug>.png nennen). `KEIN_BILD` → Fehlermeldung aus dem Task-Output zusammenfassen und einen erneuten Versuch anbieten.

**Referenzbild (Stil-Vorlage):** Mit `-i <pfad>` anhängen. ⚠️ `-i` ist variadisch und frisst nachfolgende Argumente — bei Nutzung von `-i` den Prompt IMMER via stdin pipen: `printf '%s' "<PROMPT>" | codex exec … -i "<ref>"` (nie als Positional-Argument dahinter).

**Erfolgskontrolle:** Die Status-Datei `~/.claude/img-status` dient zugleich als Zeitmarker: danach NUR Bilder öffnen, die `find -newer ~/.claude/img-status` liefert — nie blind „das neueste PNG" (öffnet sonst alte Testbilder). Codex-Output immer in eine Log-Datei schreiben (nie `>/dev/null 2>&1`) und bei KEIN_BILD die letzten Zeilen ausgeben. Erst NACH dem Auswerten/Kopieren die Status-Datei löschen.

**Regeln:** Den Nutzer niemals aktiv warten lassen. Bei ausdrücklichem Zielort im Motiv („…für die App", konkreter Pfad) das Bild zusätzlich dorthin kopieren. Läuft bereits eine Generierung, keine zweite parallel starten. Flat-/Vektor-Illustrationen: quality medium reicht (optisch gleich, ~doppelt so schnell) — high nur für fotorealistische/detailreiche Motive.
