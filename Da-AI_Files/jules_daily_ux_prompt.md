TASK: Daily UX/UI Design & Accessibility Review

REPOSITORY: https://github.com/DaRipper91/DaRipped_tiny_computer
BRANCH TO CREATE: daily-review/ux-design-$(date +%Y-%m-%d)

## CONTEXT

This is a recurring daily task. Your goal is to act as a lead UX/UI designer with a focus on accessibility. Your mission is to analyze the `DaRipped_tiny_computer` Flutter application and propose concrete improvements to make the user experience more intuitive, consistent, and accessible for everyone. The target device is a Google Pixel 9, so consider mobile-first design principles.

## YOUR MANDATE

Your directive is to methodically review the app's UI code, identify areas of friction or inconsistency, and implement improvements. Your changes should make the app easier to use, more visually appealing, and compliant with accessibility standards.

## DAILY UX/UI AUDIT CHECKLIST

Follow this checklist to guide your analysis. For each suggested change, provide a clear rationale based on established UX principles.

### 1. Layout & Consistency Analysis (`lib/main.dart`)

-   **Visual Harmony:**
    -   Review all layouts. Are padding, margins, and spacing consistent across different screens (e.g., `TerminalPage`, `SettingPage`, `InfoPage`)?
    -   Check for consistent use of `Card`, `ExpansionPanelList`, and `ListTile` widgets. Propose refactoring to a shared style or custom widget if you find significant inconsistencies.
    -   Analyze the use of `ThemeData`. Are colors, fonts, and button styles being pulled from the app's theme (`Theme.of(context)`) or are they hardcoded? Replace hardcoded values with theme-based ones.

-   **Clarity & Readability:**
    -   Evaluate the visual hierarchy. Is it clear what the most important actions or information on each screen are?
    -   Assess font sizes and weights. Is text easily readable on a device with the Pixel 9's screen density (~420 DPI)?
    -   Check the layout of `SettingPage`. Could complex settings be better organized using sub-headers or dividers for clarity?

### 2. User Interaction & Feedback

-   **Feedback on Action:**
    -   Identify any user actions (button presses, toggle switches) that trigger a background process without providing immediate visual feedback.
    -   For actions that take time (e.g., saving settings, running a command), suggest adding a loading indicator (`CircularProgressIndicator`) or a temporary "Saving..." state to inform the user.
    -   Review the use of `SnackBar` messages. Are they used effectively to confirm actions (e.g., "Share link copied")? Suggest adding them where confirmation is needed but currently missing.

-   **Intuitive Controls:**
    -   Analyze the terminal's virtual keyboard (`TerminalPage`). Is the layout logical? Are the buttons large enough for easy tapping on a mobile device?
    -   Review the long-press gesture for editing/deleting shortcut commands. Is this discoverable? Suggest adding a visual hint or an explicit "Edit" button.

### 3. Accessibility (A11y)

-   **Screen Reader Support:**
    -   Inspect all `IconButton`, `OutlinedButton`, and other interactive widgets that use only an `Icon`. Do they have a `tooltip` property set? This is crucial for screen readers. If not, add one.
    -   Suggest wrapping key UI sections or custom-painted widgets with `Semantics` widgets to provide context for accessibility services.

-   **Content & Sizing:**
    -   Check for minimum touch target sizes. All buttons and interactive elements should meet the 48x48dp minimum recommendation.
    -   Verify that the UI respects the system's font size settings. Text should wrap correctly and not overflow if the user has a larger font size enabled in their device settings. Use `MediaQuery.of(context).textScaler` to test this.

### 4. Internationalization & Localization (`lib/l10n/`)

-   **Hardcoded Strings:**
    -   Scan the entire `lib/` directory for any user-facing strings that are hardcoded in the Dart code.
    -   For every hardcoded string found, move it to the `intl_en.arb` file and replace the original code with a call to `AppLocalizations.of(context)!.yourStringKey`.
    -   Ensure that new strings added to `intl_en.arb` also have placeholder translations in the other `.arb` files (`intl_zh.arb`, `intl_zh_Hant.arb`).

## OUTPUT REQUIREMENTS

-   Create a pull request from the new branch to the main development branch.
-   The PR title should be: `ux: Daily UI/UX & Accessibility Improvements for $(date +%Y-%m-%d)`.
-   The PR description must contain a "UX/UI Audit Report" section with:
    -   A summary of the identified issues.
    -   A detailed list of proposed changes, each with the file path, a screenshot or code snippet of the "before" state, and a clear justification for the improvement based on UX/accessibility principles.
-   Implement the improvements in separate, logical commits (e.g., `fix: add tooltips for accessibility`, `style: unify padding in settings page`).

## CONSTRAINTS

-   Do not make any changes to the core application logic in `workflow.dart` unless it is directly required for a UI feedback mechanism.
-   Prioritize changes that have the highest impact on usability and accessibility.
-   All changes must pass `flutter analyze` with zero warnings or errors.
-   Ensure the UI remains responsive and does not degrade in performance.
