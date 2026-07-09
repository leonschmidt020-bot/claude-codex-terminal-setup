---
description: ChatGPT-Zusammenarbeit an/aus schalten und GPT-Modell für Codex wählen
argument-hint: [an|aus|sol|terra|luna|<modell-slug>]
---
Verwalte die ChatGPT/Codex-Integration. Argumente: "$ARGUMENTS"

**WENN KEINE ARGUMENTE übergeben wurden — WICHTIGSTE REGEL:** Rufe als ALLERERSTE Aktion sofort AskUserQuestion auf. KEIN Bash davor, KEIN Text davor, KEINE Statusermittlung davor — der Nutzer will das Menü ohne Wartezeit. Verwende in allen Feldern NUR einfache ASCII-Zeichen (keine typografischen Anführungszeichen, keine Gedankenstriche, keine Sonderzeichen — die verursachen Parse-Fehler). Zwei Fragen, beide multiSelect false:

1. Header "ChatGPT", Frage "ChatGPT-Zusammenarbeit an oder aus?":
   - "An (Empfohlen)" — Claude delegiert Bau-Auftraege an ChatGPT/Codex und verifiziert.
   - "Aus" — Claude baut alles selbst, Codex ruht. (Aktueller Zustand: siehe Statusline unten im Terminal.)
2. Header "GPT-Modell", Frage "Welches GPT-Modell soll Codex nutzen?":
   - "GPT-5.6 Sol" — Flagship, staerkstes Modell (Slug gpt-5.6-sol)
   - "GPT-5.6 Terra" — ausgewogen, schneller (Slug gpt-5.6-terra)
   - "GPT-5.6 Luna" — am schnellsten (Slug gpt-5.6-luna)
   - "GPT-5.5" — bewaehrter Vorgaenger (Slug gpt-5.5)

**WENN Argumente übergeben wurden**, kein Menü — direkt anwenden: `an`/`on` → einschalten; `aus`/`off` → ausschalten; `sol`/`terra`/`luna` → `gpt-5.6-<name>`; `5.5` → `gpt-5.5`; sonstige `gpt-*`-Slugs wörtlich.

**Anwenden (nach Menü-Antwort bzw. bei Direktargument):**
- An/Aus: `printf 'on'` bzw. `printf 'off'` nach `~/.claude/codex-collab`.
- Modellwechsel: In `~/.codex/config.toml` die Top-Level-Zeile `model = "..."` per `sed -i ''` ersetzen. Danach kurz verifizieren: `codex exec --skip-git-repo-check "Reply with exactly: OK"` (Timeout 120s). Bei „model is not supported": alten Wert zurückschreiben, Fehler melden (für ChatGPT-Account noch nicht freigeschaltet). Unverändertes Modell nicht neu verifizieren.
- Beides in möglichst wenigen Bash-Aufrufen bündeln.

**Abschluss:** Eine Bestätigungszeile (Modell + an/aus) und Hinweis, dass die Statusline es binnen ~5s zeigt.

**Verhaltensregel für dich (Claude), jederzeit:** Steht `~/.claude/codex-collab` auf `off`, delegiere KEINE Aufträge an Codex/ChatGPT — baue selbst. Ausnahme: Der Nutzer sagt ausdrücklich „mit ChatGPT/Codex". Bei `on` (oder fehlender Datei) gilt: Bau-Aufträge bevorzugt via Codex.
