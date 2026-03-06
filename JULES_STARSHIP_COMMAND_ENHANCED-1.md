# AGENT TASK: Starship Command Enhanced — Full Feature Enhancement
# Repository: https://github.com/DaRipper91/Starship_Command_ENHANCED

---

## BEFORE ANYTHING ELSE

- **Read the `AGENT_REPORT.md` file** (if it exists) to understand the current state of the project and what was last completed.
- **Leave an agent report** in `AGENT_REPORT.md` when you are done with your turn, detailing what you did and what should be done next.

## CONTEXT & OVERVIEW

Starship Command is a visual, no-code drag-and-drop editor for creating
[Starship shell prompt](https://starship.rs) themes. It is built with:

- **React + TypeScript** (Vite)
- **Tailwind CSS** for styling
- **xterm.js** for the live terminal preview
- **@hello-pangea/dnd** or similar for drag-and-drop

The existing features include:
- Live terminal preview via xterm.js
- Drag-and-drop module builder (left prompt only)
- Color picker with presets
- Image-to-theme color extraction (color_extractor.py)
- Theme gallery (basic)
- TOML export

---

## YOUR MISSION

Implement ALL of the features listed below into the existing codebase. Do not
rewrite the app from scratch — extend and integrate into the existing
architecture. Maintain existing TypeScript types and conventions.

Read the existing src/ directory structure before starting. Follow existing
naming conventions, file organization, and import patterns.

---

## FEATURE LIST WITH FULL IMPLEMENTATION SPECS

---

### FEATURE 1: UNDO / REDO HISTORY

**Goal:** Full undo/redo for all config changes, with keyboard shortcuts.

**Implementation:**

Create `src/hooks/useHistory.ts`:

```typescript
import { useState, useCallback } from 'react';

export function useHistory<T>(initial: T) {
  const [history, setHistory] = useState<T[]>([initial]);
  const [index, setIndex] = useState(0);

  const current = history[index];

  const push = useCallback((newState: T) => {
    setHistory(h => {
      const trimmed = h.slice(0, index + 1);
      return [...trimmed, newState];
    });
    setIndex(i => i + 1);
  }, [index]);

  const undo = useCallback(() => setIndex(i => Math.max(0, i - 1)), []);
  const redo = useCallback(() =>
    setIndex(i => Math.min(history.length - 1, i + 1)), [history.length]);

  return {
    current,
    push,
    undo,
    redo,
    canUndo: index > 0,
    canRedo: index < history.length - 1,
  };
}
```

In the main App/store, wrap the entire theme config state with useHistory.
Every mutation to the config (module reorder, color change, separator change,
prompt char change, etc.) must call `push(newConfig)` instead of setState
directly.

Add keyboard listeners in App.tsx:
```typescript
useEffect(() => {
  const handler = (e: KeyboardEvent) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'z') { e.preventDefault(); undo(); }
    if ((e.ctrlKey || e.metaKey) && e.key === 'y') { e.preventDefault(); redo(); }
  };
  window.addEventListener('keydown', handler);
  return () => window.removeEventListener('keydown', handler);
}, [undo, redo]);
```

Add Undo / Redo buttons to the toolbar with disabled state when at boundaries.

---

### FEATURE 2: MODULE SEARCH / FILTER

**Goal:** A search input above the available modules pool that filters by name
in real time.

**Implementation:**

In `src/components/ModuleBuilder.tsx` (or wherever the available modules list
is rendered), add:

```typescript
const [search, setSearch] = useState('');
const filteredModules = ALL_MODULES.filter(m =>
  m.id.toLowerCase().includes(search.toLowerCase())
);
```

Render a styled search `<input>` above the available modules pool. The input
should use the existing Tailwind dark theme styling. The filter applies only to
the "available to add" pool, NOT to modules already in the active prompt order.

---

### FEATURE 3: MODULE DOCUMENTATION TOOLTIPS

**Goal:** Hovering over any module (in both the active order chips and the
available pool) shows a tooltip with a brief description of what that Starship
module does.

**Implementation:**

Create `src/data/moduleDescriptions.ts`:

```typescript
export const MODULE_DESCRIPTIONS: Record<string, string> = {
  username: "Shows the current user's username. Useful for multi-user or SSH environments.",
  hostname: "Displays the machine hostname. Great for SSH or container contexts.",
  directory: "Shows the current working directory with configurable truncation.",
  git_branch: "Displays the active git branch name with a configurable symbol.",
  git_status: "Shows git repo status: staged, unstaged, ahead/behind counts.",
  git_commit: "Shows the current commit hash (short SHA).",
  git_state: "Shows transient git states like MERGING, REBASING, CHERRY-PICKING.",
  git_metrics: "Shows added/deleted line counts since last commit.",
  nodejs: "Displays Node.js version when in a JS/TS project.",
  python: "Displays Python version when in a Python project.",
  rust: "Displays Rust toolchain version when in a Rust project.",
  golang: "Displays Go version when in a Go project.",
  java: "Displays Java version when in a Java project.",
  ruby: "Displays Ruby version when in a Ruby project.",
  php: "Displays PHP version when in a PHP project.",
  kotlin: "Displays Kotlin version when in a Kotlin project.",
  swift: "Displays Swift version in Swift projects.",
  elixir: "Displays Elixir/OTP version in Elixir projects.",
  package: "Shows the package version from package.json, Cargo.toml, etc.",
  docker_context: "Shows the active Docker context.",
  kubernetes: "Shows the active Kubernetes context and namespace.",
  terraform: "Shows the active Terraform workspace.",
  aws: "Shows the AWS profile and region from environment variables.",
  gcloud: "Shows the active Google Cloud project and region.",
  azure: "Shows the active Azure subscription.",
  cmd_duration: "Shows how long the last command took to execute.",
  time: "Displays the current local time.",
  battery: "Shows battery charge level and charging status.",
  memory_usage: "Shows current RAM usage percentage.",
  env_var: "Displays the value of a specified environment variable.",
  custom: "A fully custom module — define your own command and format.",
  shell: "Indicates the current shell (bash, zsh, fish, etc.).",
  shlvl: "Shows the shell nesting level ($SHLVL).",
  status: "Shows the exit code of the last command when non-zero.",
  jobs: "Shows the number of background jobs running.",
  character: "The prompt character (❯ by default). Changes color on error.",
};
```

Create a reusable `<Tooltip>` component in `src/components/ui/Tooltip.tsx` that
shows on hover using CSS positioning (no external library needed). Apply it to
every module chip and every available-module button.

---

### FEATURE 4: EXPORT — COPY TOML TO CLIPBOARD

**Goal:** A "Copy TOML" button in the Export panel that copies the generated
starship.toml text to the clipboard with visual feedback.

**Implementation:**

In the export panel component, add:

```typescript
const [copied, setCopied] = useState(false);

const handleCopy = async () => {
  await navigator.clipboard.writeText(generatedTOML);
  setCopied(true);
  setTimeout(() => setCopied(false), 2000);
};
```

Button label toggles: "Copy TOML" → "✓ Copied!" for 2 seconds.

---

### FEATURE 5: EXPORT — DOWNLOAD starship.toml

**Goal:** A "Download" button that triggers a file download of the generated
TOML as `starship.toml`.

**Implementation:**

```typescript
const handleDownload = () => {
  const blob = new Blob([generatedTOML], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'starship.toml';
  a.click();
  URL.revokeObjectURL(url);
};
```

Show a helper note: "Place this file at ~/.config/starship.toml to apply it."

---

### FEATURE 6: EXPORT — SHAREABLE URL

**Goal:** A "Share" button that encodes the full theme config into the URL hash
so it can be shared with others who can open it and get the exact same config.

**Implementation:**

```typescript
const handleShare = () => {
  const encoded = btoa(JSON.stringify(themeConfig));
  const url = `${window.location.origin}${window.location.pathname}#theme=${encoded}`;
  navigator.clipboard.writeText(url);
  // Show a toast/notification: "Shareable URL copied!"
};
```

On app load, check `window.location.hash` for a `#theme=` value and decode it:

```typescript
useEffect(() => {
  const hash = window.location.hash;
  if (hash.startsWith('#theme=')) {
    try {
      const decoded = JSON.parse(atob(hash.replace('#theme=', '')));
      // validate and apply decoded config
      push(decoded);
    } catch { /* ignore malformed */ }
  }
}, []);
```

---

### FEATURE 7: CONTRAST RATIO CHECKER

**Goal:** In the color picker section, display the WCAG contrast ratio between
the background and foreground colors in real time, with a pass/fail indicator.

**Implementation:**

Create `src/utils/contrast.ts`:

```typescript
function relativeLuminance(hex: string): number {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  const toLinear = (c: number) =>
    c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  return 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
}

export function contrastRatio(hex1: string, hex2: string): number {
  const l1 = relativeLuminance(hex1);
  const l2 = relativeLuminance(hex2);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}
```

In the color picker panel, show:
- The ratio as "X.X:1"
- Pass/fail for WCAG AA (4.5:1 for normal text, 3:1 for large text)
- Pass/fail for WCAG AAA (7:1)
- A colored badge (green = pass, red = fail)

---

### FEATURE 8: THEME GALLERY — TAG FILTERING

**Goal:** The Theme Gallery tab should support filtering themes by tags (e.g.,
"dark", "light", "colorful", "minimal", "powerline", "retro").

**Implementation:**

Add a `tags: string[]` field to the theme gallery data type. Update all existing
gallery themes to have appropriate tags.

Render a row of filter pill buttons above the grid. Clicking a tag filters the
displayed themes. An "All" pill shows everything. Allow multiple tag selection
(AND logic preferred, OR also acceptable).

---

### FEATURE 9: THEME GALLERY — FAVORITE / STAR THEMES

**Goal:** Each theme card in the gallery has a star/heart button. Favorited
themes are persisted to localStorage and shown at the top of the gallery or in
a "Favorites" section.

**Implementation:**

```typescript
const [favorites, setFavorites] = useState<Set<string>>(() => {
  const stored = localStorage.getItem('starship-favorites');
  return new Set(stored ? JSON.parse(stored) : []);
});

const toggleFavorite = (themeId: string) => {
  setFavorites(prev => {
    const next = new Set(prev);
    next.has(themeId) ? next.delete(themeId) : next.add(themeId);
    localStorage.setItem('starship-favorites', JSON.stringify([...next]));
    return next;
  });
};
```

Show a ☆/★ button on each theme card. Favorites appear in a separate section
"Your Favorites" at the top of the gallery view.

---

### FEATURE 10: SAVE NAMED THEMES LOCALLY

**Goal:** A "Save Theme" button in the toolbar that prompts the user for a name
and saves the current full config to localStorage. Saved themes appear in a
"My Themes" panel and can be reloaded.

**Implementation:**

```typescript
interface SavedTheme {
  id: string;
  name: string;
  createdAt: number;
  config: ThemeConfig;
}

// Load saved themes from localStorage on mount
const [savedThemes, setSavedThemes] = useState<SavedTheme[]>(() => {
  const raw = localStorage.getItem('starship-saved-themes');
  return raw ? JSON.parse(raw) : [];
});

const saveTheme = (name: string) => {
  const theme: SavedTheme = {
    id: crypto.randomUUID(),
    name,
    createdAt: Date.now(),
    config: currentConfig,
  };
  const updated = [...savedThemes, theme];
  setSavedThemes(updated);
  localStorage.setItem('starship-saved-themes', JSON.stringify(updated));
};

const deleteTheme = (id: string) => {
  const updated = savedThemes.filter(t => t.id !== id);
  setSavedThemes(updated);
  localStorage.setItem('starship-saved-themes', JSON.stringify(updated));
};
```

Add a modal/dialog for naming the theme. Show saved themes in the Gallery tab
under "My Themes" with load and delete buttons.

---

### FEATURE 11: RANDOM THEME GENERATOR

**Goal:** A "🎲 Random" button in the toolbar that randomizes colors, the
prompt character, and the separator style.

**Implementation:**

```typescript
const RANDOM_PALETTES = [
  { bg: '#1e1e2e', fg: '#cdd6f4', accent: '#cba6f7', accent2: '#89dceb' },
  { bg: '#282828', fg: '#ebdbb2', accent: '#fabd2f', accent2: '#8ec07c' },
  { bg: '#1a1b26', fg: '#c0caf5', accent: '#7aa2f7', accent2: '#9ece6a' },
  { bg: '#2e3440', fg: '#eceff4', accent: '#88c0d0', accent2: '#a3be8c' },
  { bg: '#282a36', fg: '#f8f8f2', accent: '#bd93f9', accent2: '#50fa7b' },
  { bg: '#0d1117', fg: '#e6edf3', accent: '#58a6ff', accent2: '#3fb950' },
  { bg: '#fdf6e3', fg: '#657b83', accent: '#268bd2', accent2: '#2aa198' },
  { bg: '#002b36', fg: '#839496', accent: '#2aa198', accent2: '#859900' },
];

const RANDOM_PROMPT_CHARS = ['❯', '➜', '▶', '➤', 'λ', '»', '⚡', '→', '', ''];

const generateRandom = () => {
  const palette = RANDOM_PALETTES[Math.floor(Math.random() * RANDOM_PALETTES.length)];
  const char = RANDOM_PROMPT_CHARS[Math.floor(Math.random() * RANDOM_PROMPT_CHARS.length)];
  const separatorKeys = Object.keys(SEPARATOR_SHAPES);
  const separator = separatorKeys[Math.floor(Math.random() * separatorKeys.length)];
  push({ ...currentConfig, colors: palette, promptChar: char, separator });
};
```

---

### FEATURE 12: FORK THEME FROM GALLERY

**Goal:** Each gallery theme card has a "Fork" button that loads that theme's
config into the editor as the current working config, letting the user customize
from that base.

**Implementation:**

The gallery `ThemeCard` component accepts an `onFork: (theme: GalleryTheme) => void` prop.

When clicked:
- Map the gallery theme's color palette into the full ThemeConfig shape
- Call `push(mergedConfig)` so it's undoable
- Switch the active tab to "Modules" or "Style"
- Show a toast: "Forked from [Theme Name]"

---

### FEATURE 13: RIGHT PROMPT (right_format)

**Goal:** Enable a second module builder for Starship's `right_format` config
key. Users should be able to add, remove, and reorder modules for the right-side
prompt independently of the left prompt.

**Implementation:**

Update `ThemeConfig` type:

```typescript
interface ThemeConfig {
  leftModules: ModuleItem[];
  rightModules: ModuleItem[];   // NEW
  rightPromptEnabled: boolean;  // NEW
  // ... rest of existing fields
}
```

In the Module Builder panel, add a toggle "Enable Right Prompt" at the top.
When enabled, render a second drag-and-drop zone alongside or below the left
zone, labeled "Right Prompt →".

The available modules pool should show modules not yet in EITHER zone (or allow
the same module in both — up to you, but preventing duplicates within each zone
is required).

Update `generateTOML()` to include:

```toml
right_format = """
$cmd_duration\
$time\
"""
```

...based on `rightModules` when `rightPromptEnabled` is true.

Update the live terminal preview to show right-aligned content in the preview
pane when `rightPromptEnabled` is true.

---

### FEATURE 14: SINGLE LINE vs MULTI-LINE PROMPT

**Goal:** A toggle in the layout settings that switches between single-line
(all modules on one line) and multi-line (modules on line 1, cursor on line 2)
prompt styles.

**Implementation:**

Add `promptStyle: 'singleline' | 'multiline'` to `ThemeConfig`.

In `generateTOML()`:
- Multi-line: `add_newline = true` and add `$line_break` before `$character` in
  the format string.
- Single-line: `add_newline = false` and no `$line_break`.

In the terminal preview component, visually show the difference:
- Multi-line: segments row, then cursor on its own line below.
- Single-line: segments and cursor all on the same row.

Render a segmented control: `[ ── Single Line ]  [ ┐ Multi-Line ]`

---

### FEATURE 15: NERD FONT ICON PICKER

**Goal:** A dedicated "Nerd Fonts" tab or panel section that lets users browse
and insert Nerd Font icons. Used for: the prompt character (success/error
symbol), module symbols, and any custom decorators in the TOML.

**Implementation:**

Create `src/data/nerdFontIcons.ts` with categorized icon maps:

```typescript
export const NERD_FONT_CATEGORIES: Record<string, string[]> = {
  'Git':            ['\ue702', '\uf418', '\uf7a1', '\uf7a0', '\uf7a2', '\udb80\udda2', '\udb8a\ude2c', '\udb80\udd98'],
  'Folders':        ['\ue5ff', '\uf115', '\uf07b', '\uf07c', '\udb80\udecb', '\udb80\udccd', '\udb80\udccc', '\udb80\udcd0'],
  'Arrows':         ['\ue0b0', '\ue0b2', '\ue0b4', '\ue0b6', '❯', '➜', '➤', '▶', '→', '⟶', '⚡'],
  'Stars/Sparks':   ['★', '✦', '✧', '✨', '⭐', '🌟', '💫'],
  'Shells':         ['\ue691', '\ue692', '\ue693', '\ue77d', '\udb82\udec3'],
  'Dev/Code':       ['\ue64b', '\ue738', '\uf121', '\ue60e', '\uf1d0', '\uf017', '\udb80\udd20', '\udb80\udcf7', '\udb82\udcde'],
  'OS':             ['\uf179', '\uf17c', '\uf17d', '\uf462', '\uf83f', '\udb80\udc36'],
  'Powerline Solid':  ['\ue0b0', '\ue0b1', '\ue0b2', '\ue0b3', '\ue0b4', '\ue0b5'],
  'Powerline Thin': ['\ue0b8', '\ue0b9', '\ue0ba', '\ue0bb', '\ue0bc', '\ue0bd'],
  'Circles':        ['●', '◉', '○', '◎', '⬤', '\ue0b6', '\ue0b7'],
  'Triangles':      ['▶', '◀', '▲', '▼', '◤', '◥', '◣', '◢'],
  'Blocks':         ['█', '▓', '▒', '░', '▌', '▐', '▀', '▄'],
  'Special':        ['∞', '≡', '≈', 'λ', 'Ω', 'π', 'μ', 'Σ'],
};
```

Create `src/components/NerdFontPicker.tsx`:
- Category tabs or pills at the top to filter by category
- A search input that searches across ALL categories
- A grid of icon buttons — clicking one sets the prompt character AND copies
  the character to clipboard
- A "Current Prompt Char" preview showing the selected icon large
- A text input to manually type or paste any character

The prompt character selected here must update `themeConfig.promptChar` which
feeds into:
1. The TOML generator (success_symbol / error_symbol in `[character]`)
2. The live terminal preview

---

### FEATURE 16: SEPARATOR & SHAPES PICKER

**Goal:** A dedicated "Separators" tab or section letting users pick the segment
separator style for both left and right prompt sides independently.

**Implementation:**

Create `src/data/separators.ts`:

```typescript
export interface SeparatorSet {
  key: string;
  label: string;
  leftOuter: string;  // after last left segment (pointing right)
  leftInner: string;  // between left segments
  rightOuter: string; // before first right segment (pointing left)
  rightInner: string; // between right segments
}

export const SEPARATOR_PRESETS: SeparatorSet[] = [
  {
    key: 'powerline',
    label: 'Powerline Solid',
    leftOuter: '\ue0b0',
    leftInner: '\ue0b1',
    rightOuter: '\ue0b2',
    rightInner: '\ue0b3',
  },
  {
    key: 'powerline-thin',
    label: 'Powerline Thin',
    leftOuter: '\ue0b4',
    leftInner: '\ue0b5',
    rightOuter: '\ue0b6',
    rightInner: '\ue0b7',
  },
  {
    key: 'round',
    label: 'Round',
    leftOuter: '\ue0b4',
    leftInner: '\ue0b5',
    rightOuter: '\ue0b6',
    rightInner: '\ue0b7',
  },
  {
    key: 'flame',
    label: 'Flame',
    leftOuter: '\ue0c0',
    leftInner: '\ue0c1',
    rightOuter: '\ue0c2',
    rightInner: '\ue0c3',
  },
  {
    key: 'pixel',
    label: 'Pixel / Lego',
    leftOuter: '\ue0c4',
    leftInner: '\ue0c5',
    rightOuter: '\ue0c6',
    rightInner: '\ue0c7',
  },
  {
    key: 'diagonal-forward',
    label: 'Diagonal /',
    leftOuter: '\ue0be',
    leftInner: '/',
    rightOuter: '\\',
    rightInner: '\ue0bf',
  },
  {
    key: 'none',
    label: 'None (space only)',
    leftOuter: ' ',
    leftInner: ' ',
    rightOuter: ' ',
    rightInner: ' ',
  },
];
```

Create `src/components/SeparatorPicker.tsx`:
- A visual card grid where each card previews how that separator looks using
  the current accent colors
- The preview shows: `[segment1] SEP [segment2] SEP> ... <SEP [right1] <SEP [right2]`
- Clicking a card sets `themeConfig.separatorKey`
- Also show a "Custom" option with manual text inputs for all 4 separator chars

Update `generateTOML()` to include each module's format with the correct
separator glyphs inlined, e.g.:
```toml
[directory]
format = "[$path]($style)[$read_only]($read_only_style)"
```

And stitch them together with the separator characters in the top-level
`format` string.

Update the xterm.js / live preview to render separators accurately with the
correct colors.

---

## TOML GENERATOR — COMPLETE SPEC

The TOML generator (`src/utils/generateTOML.ts`) must produce valid, complete,
ready-to-use Starship config. Here is the full expected output structure:

```toml
# Generated by Starship Command Enhanced
# https://starship.rs

"$schema" = "https://starship.rs/config-schema.json"

add_newline = true   # (false for singleline mode)

format = """
[SEP_OUTER](fg:#COLOR_BG0 bg:accent)\
[$username](bold fg:accent bg:accent)\
[SEP_OUTER](fg:accent bg:accent2)\
[$directory](bold fg:accent2 bg:surface)\
[SEP_OUTER](fg:surface)\
$git_branch\
$git_status\
$line_break\
$character
"""

# right_format only if rightPromptEnabled = true
right_format = """
$cmd_duration\
$time\
"""

[palette.custom]
accent = "#cba6f7"
accent2 = "#89dceb"
surface = "#313244"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vicmd_symbol = "[❮](bold green)"

[username]
show_always = true
style_user = "bold fg:accent"
style_root = "bold red"
format = "[$user]($style) "

[directory]
style = "bold fg:accent2"
truncation_length = 3
truncate_to_repo = true
format = "[$path]($style)[$read_only]($read_only_style) "

[git_branch]
symbol = " "
style = "bold fg:accent"
format = "on [$symbol$branch]($style) "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold red"

[cmd_duration]
min_time = 500
format = "took [$duration]($style) "
style = "bold yellow"

[time]
disabled = false
format = "🕙[$time]($style) "
time_format = "%H:%M"
style = "bold dimmed white"
```

IMPORTANT: The separator glyphs must be correctly inserted between module
segments in the top-level `format` string. Each segment that has a background
color needs the appropriate glyph in the correct fg/bg colors to create the
"powerline" visual effect.

---

## FILE STRUCTURE TO CREATE / MODIFY

```
src/
  hooks/
    useHistory.ts              (NEW — undo/redo)
  data/
    moduleDescriptions.ts      (NEW — tooltip text)
    nerdFontIcons.ts           (NEW — icon categories)
    separators.ts              (NEW — separator presets)
    galleryThemes.ts           (MODIFY — add tags, more themes)
  utils/
    contrast.ts                (NEW — WCAG contrast calculation)
    generateTOML.ts            (MODIFY — right_format, separators, line_break)
    shareUrl.ts                (NEW — encode/decode config from URL hash)
  components/
    NerdFontPicker.tsx         (NEW)
    SeparatorPicker.tsx        (NEW)
    ModuleTooltip.tsx          (NEW — tooltip wrapper)
    ThemeCard.tsx              (MODIFY — add tags, star, fork button)
    ModuleBuilder.tsx          (MODIFY — add search, right prompt zone)
    ColorPicker.tsx            (MODIFY — add contrast checker)
    ExportPanel.tsx            (MODIFY — add copy, download, share buttons)
    PromptLayoutToggle.tsx     (NEW — singleline/multiline + right prompt toggle)
    SaveThemeDialog.tsx        (NEW — modal for naming and saving)
    Toolbar.tsx                (MODIFY — add undo, redo, random, save buttons)
    TerminalPreview.tsx        (MODIFY — show right prompt, separators, multiline)
  App.tsx                      (MODIFY — wire everything together)
```

---

## STATE SHAPE (ThemeConfig)

Expand the existing config/state type to:

```typescript
interface ModuleItem {
  id: string;
  enabled: boolean;
  // future: per-module overrides like custom symbol, style
}

interface ThemeColors {
  bg: string;
  fg: string;
  accent: string;
  accent2: string;
  surface?: string;
}

interface ThemeConfig {
  leftModules: ModuleItem[];
  rightModules: ModuleItem[];
  rightPromptEnabled: boolean;
  promptStyle: 'singleline' | 'multiline';
  promptChar: string;
  promptCharError?: string;
  colors: ThemeColors;
  separatorKey: string;      // key into SEPARATOR_PRESETS
  paletteName?: string;
}
```

---

## UI / UX REQUIREMENTS

1. **Tab Navigation**: The main editor panel uses tabs:
   - Modules (drag-and-drop builder, left + right zones)
   - Style (colors + contrast checker)
   - Nerd Fonts (icon picker + prompt char setter)
   - Separators (shape picker)
   - Gallery (community themes + saved themes)
   - Export (TOML preview + copy/download/share buttons)

2. **Sticky Preview**: The live terminal preview panel stays sticky on the
   right side of the screen as the user scrolls through the editor tabs.

3. **Responsive**: On screens narrower than 900px, stack the preview below
   the editor instead of side-by-side.

4. **Collapsible Sections**: Sections within each tab are collapsible
   (chevron toggle) and remember their open/closed state in sessionStorage.

5. **Toast Notifications**: Use a lightweight in-app toast system (no external
   lib required — a simple fixed-position div with opacity animation) for:
   - "✓ Copied to clipboard"
   - "✓ Theme saved: [Name]"
   - "✓ Forked from [Theme Name]"
   - "✓ Random theme applied"
   - "⚠ URL config is malformed"

6. **Keyboard Shortcuts Legend**: A collapsible "Keyboard Shortcuts" panel in
   the sidebar listing all shortcuts.

---

## WHAT NOT TO CHANGE

- The Image-to-Theme feature (color_extractor.py + frontend integration) —
  keep it as-is, just ensure it still feeds into the updated ThemeConfig shape.
- The existing xterm.js integration — extend it to show right prompt and
  separators, but don't replace or reconfigure the core terminal setup.
- The project's existing Tailwind config, ESLint config, Prettier config, Vite
  config, TypeScript configs — do not modify any of these.
- The AGENTS.md and CONTRIBUTING.md files.

---

## TESTING CHECKLIST (manual)

After implementing, verify all of the following work correctly:

- [ ] Ctrl+Z and Ctrl+Y undo/redo any config change
- [ ] Undo/Redo buttons are disabled at history boundaries
- [ ] Module search filters the available pool in real time
- [ ] Hovering a module chip shows a tooltip with description
- [ ] Hovering an available module shows a tooltip with description
- [ ] "Copy TOML" button copies text and shows "✓ Copied!" for 2 seconds
- [ ] "Download" button downloads a valid `starship.toml` file
- [ ] "Share URL" creates a URL that when opened restores the exact config
- [ ] Contrast ratio updates live as colors change
- [ ] WCAG AA badge shows green/red correctly
- [ ] Gallery tag filter buttons hide/show themes correctly
- [ ] Favoriting a theme persists after page refresh
- [ ] Saving a named theme persists after page refresh
- [ ] Loaded saved themes restore the full config
- [ ] "Random" button produces a visually different theme each click
- [ ] "Fork" button on gallery card loads that theme into the editor
- [ ] Enabling Right Prompt shows the second module zone
- [ ] Modules added to right zone appear in right_format in TOML
- [ ] Disabling Right Prompt hides the right zone and removes right_format
- [ ] Single-line mode shows modules and cursor on same line in preview
- [ ] Multi-line mode shows modules on line 1, cursor on line 2 in preview
- [ ] Multi-line TOML has add_newline = true and $line_break
- [ ] Single-line TOML has add_newline = false and no $line_break
- [ ] Nerd Font picker icon grid renders icons correctly
- [ ] Clicking an icon sets the prompt character
- [ ] Prompt character updates in live preview immediately
- [ ] Prompt character appears in generated TOML's [character] block
- [ ] Separator picker shows visual preview of each style
- [ ] Selecting a separator updates the live preview
- [ ] Separator glyphs appear correctly in generated TOML format string

---

## REFERENCE IMPLEMENTATION

A reference prototype of the full enhanced UI has been built as a standalone
React component. The key data structures, component names, and logic patterns
from that prototype should be used as a guide when integrating into the
TypeScript codebase. Key patterns to replicate:

**useHistory hook** — wraps the entire ThemeConfig, returns current/push/undo/redo/canUndo/canRedo.

**generateTOML function** — reads leftModules, rightModules, rightPromptEnabled,
promptStyle, promptChar, colors, separatorKey and produces a complete TOML string.

**ModuleBuilder component** — renders two zones (left/right) when rightPromptEnabled
is true, each with drag-to-reorder chips, remove buttons, and a filtered available
pool below.

**NerdFontPicker component** — category pill tabs + search input + icon grid +
large preview of current promptChar.

**SeparatorPicker component** — card grid with live color-accurate preview of
each separator style.

**TerminalPreview component** — renders left segments with colored backgrounds
and separator glyphs, right-aligned right segments when enabled, and shows
multiline vs singleline layout correctly.

**ThemeGallery component** — tag filter pills + theme cards with fork button +
favorites section + saved themes section.

**TOMLPanel component** — displays generated TOML in a scrollable code block
with Copy, Download, and Share URL buttons.

---

## PRIORITY ORDER

Implement in this order if time-constrained:

1. ThemeConfig type expansion (rightModules, rightPromptEnabled, promptStyle, separatorKey, promptChar)
2. Right Prompt support (UI + TOML)
3. Single/Multi-line toggle (UI + TOML)
4. useHistory hook + Undo/Redo
5. generateTOML.ts complete rewrite to handle all new config fields
6. Nerd Font Picker tab
7. Separator Picker tab
8. Module search + tooltips
9. Export panel (copy + download + share URL)
10. Contrast checker
11. Gallery enhancements (tags, favorites, fork, saved themes)
12. Random theme generator
13. Toast notification system
14. Keyboard shortcuts legend
15. Share URL decoder on load
16. Responsive layout for mobile

---

## AGENT REPORTING RULES
- **Maximum 2 report files**: Only `AGENT_REPORT.md` and `(OLD) AGENT_REPORT.md` should exist.
- **Rotate reports**: Before creating a new `AGENT_REPORT.md`, rename the existing one to `(OLD) AGENT_REPORT.md` (overwriting any previous old report).
- **Required Format**:
  - **Summary**: What was accomplished.
  - **Status**: Which features are 100% done, partial, or not started.
  - **Next Steps**: Clear instructions for the next agent.
  - **Blocking Issues**: Any bugs or limitations found.
