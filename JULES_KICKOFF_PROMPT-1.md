# Agent Kickoff Prompt — Starship Command Enhanced

I need you to implement a large set of new features into my existing
project: **Starship Command**, a visual drag-and-drop theme editor for the
[Starship shell prompt](https://starship.rs).

The full feature spec, implementation details, TypeScript code snippets, file
structure, and a testing checklist are all documented in:

```
JULES_STARSHIP_COMMAND_ENHANCED-1.md
```

There is also a reference UI prototype at:

```
StarshipCommand-Enhanced.jsx
```

Use both files as your source of truth throughout this task.

---

## Before You Write a Single Line of Code

1. **Read `AGENT_REPORT.md` first.** Then read `JULES_STARSHIP_COMMAND_ENHANCED-1.md` in full. Do not skim it.
   Every feature has exact specs, TypeScript types, and function signatures
   written out for you. Following them will save you from making assumptions.

2. **Read the existing `src/` directory.** Understand what already exists
   before you create anything new. Pay close attention to:
   - How the existing `ThemeConfig` (or equivalent) type is defined
   - How state is managed (local state, context, Zustand, etc.)
   - How `generateTOML` currently works
   - How xterm.js is initialized and updated
   - The drag-and-drop implementation used for the module builder
   - How the existing gallery themes are structured

3. **Read `StarshipCommand-Enhanced.jsx`.** This is a working prototype of the
   full enhanced UI. Use it as a visual and logical reference — the component
   names, data shapes, and logic patterns in it should guide your integration
   into the TypeScript codebase.

4. **Do not modify** any of the following — leave them exactly as they are:
   - `.eslintrc.cjs`
   - `.prettierrc`
   - `tailwind.config.js`
   - `vite.config.ts`
   - `tsconfig*.json`
   - `AGENTS.md`
   - `CONTRIBUTING.md`
   - `color_extractor.py` and its frontend integration

---

## What You Are Building

You are extending the existing app with 16 features. Implement them in this
priority order (most foundational first):

1. **Expand `ThemeConfig` type** — add `rightModules`, `rightPromptEnabled`,
   `promptStyle`, `separatorKey`, `promptChar`
2. **Right Prompt** — second drag-and-drop zone, feeds `right_format` in TOML
3. **Single / Multi-line prompt toggle** — controls `add_newline` and
   `$line_break` in TOML, updates live preview layout
4. **Undo / Redo** — `useHistory` hook wrapping the full config state, Ctrl+Z /
   Ctrl+Y keyboard shortcuts, toolbar buttons
5. **`generateTOML` rewrite** — handle all new config fields, produce a
   complete and valid `starship.toml` with correct separator glyphs inlined
6. **Nerd Font Icon Picker** — new tab, category browsing, search, sets prompt
   character which updates preview and TOML
7. **Separator & Shapes Picker** — new tab, visual card grid with live preview
   of each separator style in current accent colors
8. **Module search + tooltips** — filter available modules by name, tooltip
   descriptions on hover for every module
9. **Export panel** — Copy TOML (with 2s "✓ Copied!" feedback), Download
   `starship.toml`, Share URL (base64 config in URL hash)
10. **Contrast ratio checker** — WCAG AA/AAA live readout in the color section
11. **Gallery enhancements** — tag filtering, star/favorite with localStorage
    persistence, Fork button, saved named themes
12. **Random theme generator** — randomizes colors, prompt char, separator
13. **Toast notification system** — lightweight in-app toasts, no external lib
14. **Keyboard shortcuts legend** — collapsible panel listing all shortcuts
15. **Share URL decoder on load** — read `#theme=` hash on mount, restore config
16. **Responsive layout** — stack preview below editor on screens < 900px

Complete as many as you can, in order. Do not skip ahead. Each feature builds
on the last.

---

## Key Rules

- **Extend, don't rewrite.** Integrate new features into the existing
  architecture. Match the existing code style exactly.
- **TypeScript only** for all new `.ts` / `.tsx` files. No `any` types.
- **No new dependencies** unless absolutely unavoidable. Every feature in the
  spec can be built with React, existing deps, and browser APIs.
- **Every mutation to ThemeConfig must go through the history `push()`** so
  undo/redo works for everything.
- **The live preview must stay in sync** with every config change in real time.
- **Leave an agent report when done.** When your turn ends, you MUST create or update `AGENT_REPORT.md` (and rotate the old one to `(OLD) AGENT_REPORT.md`). Only these 2 report files should ever exist.
- **Test your TOML output.** The generated `starship.toml` must be valid and
  parseable by the Starship CLI. Cross-reference the
  [Starship configuration docs](https://starship.rs/config/) when in doubt.

---

## Definition of Done

You are done when:
1. All 35 items in the testing checklist at the bottom of `JULES_STARSHIP_COMMAND_ENHANCED-1.md` pass.
2. The app builds cleanly with `npm run build` (zero TypeScript errors, zero ESLint errors).
3. `AGENT_REPORT.md` is present and details exactly what was accomplished and what the next agent should do.

Good luck — the full spec is in `JULES_STARSHIP_COMMAND_ENHANCED-1.md`. Start there.
