# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

This is an **early-stage Flutter scaffold** named `monolith` (Dart SDK `^3.11.1`). `lib/main.dart` currently holds only a placeholder `BeautifulMessageScreen`; none of the product features described in `backlog/` are implemented yet. Treat the `backlog/` directory as the spec for the actual product to be built — do not assume any of it exists in code.

The product (per `backlog/`) is **"The Sonic Monolith"**: a Spanish-language Flutter music app that searches YouTube Music, downloads audio locally, and plays it back offline. Privacy-first (100% local storage), no official YouTube API keys.

## Common Commands

```bash
flutter pub get                          # install/update dependencies
flutter run                              # run on the default connected device
flutter run -d chrome                    # run as web (web/ exists)
flutter run -d windows                   # run as Windows desktop
flutter test                             # run all tests
flutter test test/path/file_test.dart    # run a single test file
flutter test --name "substring"          # run tests matching name
flutter analyze                          # lint (uses analysis_options.yaml -> flutter_lints)
flutter build apk                        # Android release build
```

There is no `test/` directory yet — create one alongside `lib/` when adding tests.

## Planned Architecture (from backlog)

The user stories `US-001`..`US-009` describe a layered app with this dependency stack:

- **Search & metadata:** `youtube_explode_dart` against YouTube Music (no API keys). Returns `Video` objects.
- **Quality selection:** filter `AudioOnlyStreamInfo` by bitrate (128/256/320 kbps); formats MP3/M4A/Opus; show file size from stream `size` *before* download.
- **Download:** `dio` for streamed HTTP, `path_provider` for local storage paths. Real-time progress UI.
- **Playback engine:** `flutter_soloud` is the chosen audio engine for **all** local playback (US-007). Must support background playback and OS lock-screen / notification controls, target 60/120 FPS UI.
- **Library:** local-only metadata management, favorites, simple recommendations derived from local listening data.

When adding features, locate them by user-story ID (e.g., `US-002` = quality selection) — the user stories are the source of truth for acceptance criteria. Each story has an "Ambigüedad por resolver en refinamiento" section listing **open decisions that must be closed before implementation** (network resumption, file naming collisions, audio focus handling, etc.). Do not silently pick an answer; surface these to the user.

None of these dependencies are in `pubspec.yaml` yet — add them as you implement each story.

## Design System (Mandatory for any UI work)

The full spec is in `backlog/design/DESIGN.md` ("The Digital Curator" / Sonic Monolith). Key non-obvious rules that are easy to violate:

- **No-Line Rule:** No 1px solid borders to section content. Use background-color shifts (`surface_container_low` on `surface`) and whitespace instead. Borders for accessibility (e.g., inputs) use `outline_variant` at 15% opacity ("Ghost Border").
- **Divider Ban:** No horizontal lines between songs in lists — use a 16px vertical gap.
- **Palette:** Strict monochrome dark grays + muted whites. Background `#0e0e0e`, primary `#c6c6c7`, on-primary `#3f4041`. **Never** use Material's default purple/blue accents.
- **Elevation:** No traditional Material drop shadows. Use tonal layering (`surface_container_low` on `surface`). When a shadow is unavoidable, diffuse it: `0 20px 40px rgba(0,0,0,0.4)`, never pure black.
- **Typography:** Manrope. Display tracked at -2%. Spanish copy needs generous `1.5` line-height on `body-md`/`title-sm` (Spanish runs ~20–30% longer than English).
- **Glassmorphism:** Floating elements (mini-player, nav) at 70% opacity with 24px backdrop blur.
- **Buttons:** Fully rounded (`9999px`).
- **"Monolith" slider:** Thick `primary` line, remaining track in `outline_variant` at 20% opacity, no thumb/knob.
- **Language:** All user-facing copy is Spanish (`Biblioteca`, `Reproducción`, `Novedades`, `Buscador`, etc.).

A reference HTML mockup lives at `backlog/design/pantalla-de-carga.html`.

## Workflow Skills (`ai-specs/skills/`)

Two SKILL.md files describe project workflows that override default behavior when invoked:

- **`enrich-user-story/SKILL.md`** ("close-requirement"): When the user brings a vague task, do **not** start implementing. Ask code-grounded clarifying questions covering solution shape, expected output, behavior, actor, scope, success criteria — and only draft the formal requirement after the user explicitly confirms. Respond in the user's language. Note: the skill references `docs/agent_architecture.md`, which does not exist yet — flag this rather than fabricating content.
- **`write-pr-report/SKILL.md`**: Strict 150–300 word PR description format with fixed sections (Summary / What Changed / Validation / Reviewer Notes / Risks / Rollback). Forbids listing raw commands, mentioning planning artifacts (`tasks_for_AI`), or AI-style verbosity. Use direct verbs ("Adds", "Fixes") not "The implementation introduces…".

`.codex/{agents,commands,skills}` directories exist but are currently empty.

## Repository Conventions

- This directory is **not a git repository** — `git` commands will fail. Don't suggest commit/PR workflows until `git init` happens.
- User-facing language is Spanish; internal code/comments default to English.
- Lint baseline is `flutter_lints` only (`analysis_options.yaml`); no custom rules.
