# Universal Agent Ruleset
# ─────────────────────────────────────────────────────────────────────────────
# This file is the single source of truth for how ALL AI agents and models
# must behave in ANY project owned by this author.
#
# It is automatically embedded into every project via `init-agent-rules.sh`.
# Do NOT edit per-project copies directly — edit THIS file, then re-run the
# bootstrap script to propagate changes.
# ─────────────────────────────────────────────────────────────────────────────

---

## START HERE — MANDATORY FIRST STEPS

Before writing a single line of code:

1. **Read `AGENT_REPORT.md`** (if it exists in this repo). It tells you exactly
   where the last agent stopped, what is done, and what to do next. Do not
   duplicate completed work.

2. **Read the full task spec or feature request.** Do not skim. Every detail
   matters. If a spec file is referenced, read it completely before starting.

3. **Explore the existing codebase:**
   - Map the top-level directory structure.
   - Find the primary entry point(s).
   - Identify the build/run/test commands (`package.json`, `Makefile`,
     `pyproject.toml`, `go.mod`, `Cargo.toml`, or equivalent).
   - Understand how state or data flows through the app (store, context,
     services, props, event bus, etc.).
   - Understand how data is persisted vs. kept ephemeral.
   - Identify naming conventions, file organization patterns, and how errors
     are handled.

4. **Run the baseline before touching anything:**
   - Run the build — note any pre-existing failures so you don't own them.
   - Run the linter.
   - Run the tests.

---

## PROTECTED FILES — NEVER MODIFY UNLESS EXPLICITLY ASKED

- Linter/formatter configs: `.eslintrc*`, `.prettierrc`, `ruff.toml`,
  `.pylintrc`, `.rubocop.yml`, `pyproject.toml` (formatting sections)
- Build/compiler configs: `vite.config.*`, `tsconfig*.json`, `webpack.config.*`,
  `go.mod`, `Cargo.toml`, `rollup.config.*`
- CI/CD configs: `.github/workflows/`, `Jenkinsfile`, `.circleci/`
- Lock files: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`,
  `Pipfile.lock`, `Cargo.lock` — updated by the package manager only
- Docs: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `LICENSE`
- Agent instruction files themselves: `CLAUDE.md`, `AGENTS.md`,
  `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`

---

## IMPLEMENTATION RULES

### Extend, don't rewrite
Integrate new features into the existing architecture. Do not replace working
code with a clean-room rewrite because you prefer a different style. Match the
existing naming conventions, file organization, and idioms exactly.

### Type safety
- **TypeScript:** strict mode; no `any` without an explicit comment explaining
  why; unused variables prefixed with `_`.
- **Python:** use type hints throughout; avoid `Any` from `typing` unless
  genuinely unavoidable.
- **Go / Rust / others:** use the type system fully; do not cast away safety.
- Prefer explicit, narrow types over loose or broad alternatives.

### No unnecessary dependencies
Only add a new package if the task explicitly requires it OR the feature
genuinely cannot be built reasonably without it. Document every new dependency
in your agent report.

### State and data mutations
- All mutations to shared state must go through the established mutation
  mechanism (store actions, reducers, setters, etc.). Never mutate shared state
  directly if the project defines a pattern to prevent that.
- If the project has an undo/redo system, every user-visible state change must
  flow through it.

### Error handling
- Handle errors explicitly. Do not silently swallow exceptions.
- Surface errors to the user through the project's established notification
  mechanism — never `window.alert()`, raw `console.log`, or unmapped throws.
- Validate all external inputs at boundaries: API responses, user input, URL
  params, file contents. Provide clear feedback on invalid data.

### Logging
- Do not leave `console.log` / `print` / debug statements in production paths.
- Use the project's existing logging mechanism.
- Use `console.warn` / `console.error` (or equivalent) sparingly and only when
  genuinely useful at runtime.

### No secrets
Never commit credentials, API keys, tokens, passwords, or personal data.
Ever. For any reason.

### Comments
- Only comment code that genuinely needs clarification.
- Prefer self-documenting names over comments that explain *what* the code does.
- Use comments to explain *why*, not *what*.

---

## UI / UX RULES (frontend projects)

1. Use the project's existing notification/toast system — never `window.alert()`
   or `window.confirm()`.
2. Live state changes must reflect immediately in any live preview or reactive UI.
3. Settings that should survive a reload must be persisted (localStorage,
   database, etc.) from day one — not retrofitted later.
4. All interactive elements must be keyboard-operable and have accessible labels
   where no visible text label is present.
5. Every list, gallery, or data table must have a clear empty-state message.
6. Long async operations must show a loading indicator.
7. On screens narrower than the design breakpoint, stack panels vertically.
8. Collapsible sections should remember their open/closed state.
9. Destructive actions require a confirmation step through the project's
   established confirmation mechanism.

---

## TESTING RULES

### Always
- Run the full build and linter after every meaningful change. Zero errors/warnings.
- Run the full test suite before finishing your turn. Zero regressions allowed.
- Remove all debug code, commented-out code, and stray TODO comments before
  wrapping up.

### For new logic
Add tests for:
- Functions with branching logic
- Data transformation functions
- Edge cases documented in the spec
- Any function called from three or more places

Test behavior, not implementation details.

### Manual verification checklist (adapt per feature)
- [ ] Happy path works end-to-end
- [ ] Data persists correctly (survives reload if expected to)
- [ ] Invalid input is rejected with a clear message
- [ ] Empty / zero / null edge cases handled gracefully
- [ ] No existing features broken
- [ ] Build passes — zero errors
- [ ] Lint passes — zero warnings/errors
- [ ] All existing tests pass

---

## IMPLEMENTATION ORDER (for any feature list)

Always implement in this sequence — most foundational first:

1. Data model / type / schema changes
2. Core logic and business rules
3. State management wiring
4. UI components
5. User feedback (toasts, loading, error states)
6. Tests
7. Accessibility (labels, keyboard navigation, focus)
8. Responsive / edge-case polish

Do not build UI before the data model is solid.

---

## AGENT REPORTING RULES

### File management
- Only two report files may exist at any time: `AGENT_REPORT.md` and
  `(OLD) AGENT_REPORT.md` — both in the project root.
- Before writing a new `AGENT_REPORT.md`, rename the existing one to
  `(OLD) AGENT_REPORT.md` (overwriting any previous old report).
- Creating or updating `AGENT_REPORT.md` is **not optional**. Do it before
  your turn ends, even if the task is incomplete.

### Required report format

```markdown
# Agent Report

## Summary
What was accomplished this turn. List every file created or modified and why.

## Feature / Task Status
- ✅ Feature name — fully implemented and tested
- 🔄 Feature name — partially done (describe what remains)
- ❌ Feature name — not started

## What the Next Agent Should Do First
Ordered, specific instructions. Include architectural decisions made that
future work must respect and any known constraints or gotchas.

## Blocking Issues
Any bugs, failures, or unresolved questions preventing progress.
If none, write "None."

## Build / Test Status
- Build: ✅ passing / ❌ failing (describe)
- Lint:  ✅ passing / ❌ failing (describe)
- Tests: ✅ all passing / ❌ N failing (list them)
```

### Reporting principles
- Be honest. If something is broken or incomplete, say so clearly.
- Do not mark a feature ✅ unless it is fully implemented, tested, and the
  build passes with it included.
- The next agent should be able to read your report in under 5 minutes and
  know exactly where to start.

---

## DEFINITION OF DONE

A task is complete when ALL of the following are true:

1. Every item in the task's acceptance criteria / testing checklist passes.
2. The project builds cleanly — zero type errors, zero lint errors.
3. All pre-existing tests still pass (no regressions).
4. `AGENT_REPORT.md` is present, up to date, and follows the format above.

---


## Project: DaRipped Tiny Computer

Flutter Android app that runs Arch Linux ARM (XFCE) on Android via proot + VNC

### Commands

```sh
# TODO: fill in build / run / test / lint commands for this project
# Example:
# npm run dev        # start dev server
# npm run build      # production build
# npm run lint       # lint
# npm test           # run tests
```

### Architecture

TODO: describe the high-level architecture, key directories, and data flow.

### Key Conventions

TODO: list any project-specific conventions agents must follow (naming patterns,
state management rules, restricted APIs, etc.).
