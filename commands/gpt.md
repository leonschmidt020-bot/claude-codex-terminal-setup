---
description: Auftrag direkt an ChatGPT (Codex CLI, GPT-5.6) durchreichen
argument-hint: <Auftrag für ChatGPT>
---
Reiche den folgenden Auftrag an das Codex CLI weiter (OpenAI-GPT-Modell, konfiguriert in `~/.codex/config.toml`) und gib dessen Antwort wieder.

Auftrag: $ARGUMENTS

Vorgehen:
1. Führe im aktuellen Arbeitsverzeichnis aus: `codex exec --skip-git-repo-check "<Auftrag>"` (Auftrag wörtlich übergeben; Timeout großzügig wählen, mindestens 10 Minuten).
2. Lies vorab mit `sed -n 's/^model = "\(.*\)"/\1/p' ~/.codex/config.toml | head -1` aus, welches GPT-Modell konfiguriert ist.
3. Gib Codex' finale Antwort wieder, klar gekennzeichnet als **Antwort von ChatGPT (<modell>)**. Kurze Antworten wörtlich; lange Antworten: Kernpunkte zusammenfassen, Code aber vollständig zeigen. Antworte auf Deutsch, auch wenn Codex Englisch antwortet.
4. Hat Codex Dateien geändert: geänderte Dateien auflisten und kurz verifizieren (Syntax/Build), bevor du abschließt.
5. Bei Fehlern (z.B. „model is not supported"): Fehler melden und vorschlagen, das Modell in `~/.codex/config.toml` zu prüfen.

Wichtig: Du (Claude) fügst keine eigene inhaltliche Lösung hinzu — der Nutzer will hier bewusst die ChatGPT-Antwort. Eigene Anmerkungen nur als kurz gekennzeichnete Fußnote, wenn etwas sicherheitsrelevant falsch wäre.
