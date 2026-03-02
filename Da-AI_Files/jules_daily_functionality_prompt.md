TASK: Daily Functionality & Robustness Audit

REPOSITORY: https://github.com/DaRipper91/DaRipped_tiny_computer
BRANCH TO CREATE: daily-review/functionality-$(date +%Y-%m-%d)

## CONTEXT

This is a recurring daily task. Your role is to act as a senior quality assurance (QA) and systems engineer. Your mission is to perform a deep logical analysis of the `DaRipped_tiny_computer` codebase to find and fix potential bugs, logical errors, unhandled edge cases, and areas prone to instability. The goal is to make the application more robust and reliable.

## YOUR MANDATE

Your directive is to trace execution flows, challenge assumptions made in the code, and improve error handling. You are not just looking for crashes, but for any behavior that could be unexpected, incorrect, or fragile. The focus is on the correctness and resilience of the core logic.

## DAILY FUNCTIONALITY AUDIT CHECKLIST

Follow this checklist to guide your analysis. For each issue found, provide a detailed report on how to reproduce it (even if theoretical) and the exact code changes required to fix it.

### 1. Core Logic & State Machine Analysis (`lib/workflow.dart`)

-   **Error Handling:**
    -   Scan the entire file for `try...catch` blocks. Are there any empty `catch` blocks (`catch (e) {}`) that silently swallow exceptions? At a minimum, suggest adding a `debugPrint(e)` statement. For critical operations, suggest showing a `SnackBar` or `AlertDialog` to the user.
    -   Review the `pty.exitCode.then(...)` block. It currently checks for `code == -9` (Signal 9). Does it handle other common non-zero exit codes gracefully? What happens if a critical shell command fails during setup? Propose a more robust error-handling mechanism.
    -   Analyze the `Process.run` calls. Is the `exitCode` of the result checked? What happens if a command fails?

-   **State Consistency:**
    -   Analyze the `initForFirstTime` workflow. What would happen if the user backgrounded or killed the app halfway through the rootfs extraction? Would it resume correctly, or would it leave the app in a corrupted state? Suggest mechanisms for transactional setup (e.g., extracting to a temporary directory and renaming on success).
    -   Review all interactions with `G.prefs` (SharedPreferences). Are there any potential race conditions? For example, is it possible for a setting to be written from one part of the app while another part is reading it?

-   **Edge Cases:**
    -   What happens if the device is out of storage space during the `initForFirstTime` extraction? How is this error communicated to the user?
    -   What happens if a required asset (`assets.zip`, `patch.tar.gz`) is missing from the build? Does the app crash or show a helpful error?
    -   Examine the logic that reassembles the `xa*` chunks. What happens if a chunk is missing or corrupted?

### 2. Input & Data Validation

-   **User-Editable Fields (`lib/main.dart`):**
    -   Review the `TextFormField` widgets in `SettingPage` (e.g., Container Name, Startup Command).
    -   While some have validators (`validateBetween`), others do not. Does the app handle malicious or unexpected input in these fields gracefully? For example, what happens if a user puts quotes or special shell characters (`$`, `|`, `&&`) in the "Startup Command"? Propose adding input sanitization or more robust validation to prevent command injection vulnerabilities.

-   **Data Parsing:**
    -   The app uses `jsonDecode` to parse container info from SharedPreferences. Is this wrapped in a `try...catch` block? What happens if the stored JSON is corrupted? The app should handle this by resetting to default settings, not crashing.

### 3. Asynchronous Code & Lifecycle Management

-   **Process Management:**
    -   Review how the `proot`, `pulseaudio`, and `virgl_test_server` processes are managed.
    -   How are these processes cleaned up when the app is closed or backgrounded? Are there any scenarios where they could become orphaned (zombie) processes?
    -   The `G.audioPty?.kill()` call is present. Ensure every created `Pty` has a corresponding `kill()` call in the appropriate lifecycle method (e.g., in a `dispose` method).

-   **Cross-Reference with Documentation:**
    -   Read the `README.md` and the `extra/build-tiny-rootfs.md` files. Does the application's actual behavior (as seen in the code) match what is described in the documentation? For example, if the docs say a certain command is run, verify that it is present and correct in `workflow.dart`. Report any discrepancies.

## OUTPUT REQUIREMENTS

-   Create a pull request from the new branch to the main development branch.
-   The PR title should be: `fix: Daily Functionality & Robustness Audit for $(date +%Y-%m-%d)`.
-   The PR description must contain a "Functionality Audit Report" section with:
    -   A summary of your findings.
    -   A list of potential bugs or logical flaws. For each, describe the potential impact, steps to reproduce (if applicable), and your proposed fix.
-   Implement the fixes in separate, logical commits. Each commit message should clearly describe the bug being fixed and the solution.

## CONSTRAINTS

-   Do not introduce any new features. Focus strictly on fixing bugs and improving the robustness of existing functionality.
-   Do not change any UI/UX elements unless it is to display an error message that was previously missing.
-   All changes must pass `flutter analyze` with zero warnings or errors.
-   Ensure your fixes do not cause any regressions in existing, working functionality.
