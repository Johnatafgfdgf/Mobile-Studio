# Mobile Studio

Mobile-first Roblox creation environment prototyped inside Studio Lite.

## Goal

Build a touch-first editor with a real project model, responsive viewport, Explorer, Properties, Output, scripting tools, undo/redo and a publishing pipeline.

## Quick start

1. In Studio Lite, create a `LocalScript` under `StarterGui > StudioUI`.
2. Paste the contents of `loader.lua`.
3. Run Play/Test.

The loader checks whether the current Studio Lite runtime exposes a compatible HTTP + dynamic-code path. If it does, it loads `dist/MobileStudio.lua` directly from this repository. If Studio Lite blocks remote loading in that context, use the single-file fallback in `dist/MobileStudio.lua` while we wire a Studio-Lite-native bootstrap.

## Structure

- `loader.lua` — tiny bootstrap used in Studio Lite.
- `manifest.json` — release metadata.
- `dist/MobileStudio.lua` — single-file runnable build.
- `src/` — modular source used to evolve the editor.
- `docs/` — architecture and UX decisions.

## Current milestone

### v0.2.0 — responsive shell

- Roblox safe-area aware UI
- viewport-first mobile layout
- compact top command bar
- collapsible Explorer / Properties drawers
- collapsible Output tray
- responsive landscape / portrait behavior
- real Workspace-backed Explorer listing
- touch/click selection of BaseParts
- live Properties readout
- basic rename / anchored / collision editing
- create Part
- duplicate / delete selected object
- undo / redo for supported edits

Publishing is intentionally not enabled yet. API keys must never be embedded in this public repository.
