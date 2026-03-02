TASK: Daily Code Performance Audit for DaRipped_tiny_computer

REPOSITORY: https://github.com/DaRipper91/DaRipped_tiny_computer
BRANCH TO CREATE: daily-review/performance-$(date +%Y-%m-%d)

## CONTEXT

This is a recurring daily task. Your goal is to act as a senior performance engineer and proactively identify and fix performance bottlenecks in the `DaRipped_tiny_computer` Flutter application. The project's main objective is to convert from a Debian to an Arch Linux ARM container, and performance is critical for the target Pixel 9 device.

## YOUR MANDATE

Your primary directive is to find code that is slow, inefficient, or resource-intensive, and refactor it for optimal performance without changing the core functionality. Focus on CPU, memory, and I/O operations.

## DAILY PERFORMANCE AUDIT CHECKLIST

Follow this checklist to guide your analysis. For each finding, provide a detailed explanation of the issue and the proposed solution.

### 1. Core Logic Analysis (`lib/workflow.dart`)

-   **Shell Process Efficiency:**
    -   Review all calls to `Pty.start`, `Process.run`, and custom `Util.execute` functions.
    -   Are there any shell commands being run in tight loops?
    -   Can any complex shell command chains (`cat xa* | tar ...`) be optimized? For instance, would passing file paths directly to `tar` be more efficient if possible?
    -   Identify any synchronous I/O operations (`.createSync`, etc.) that could block the main thread and suggest asynchronous alternatives.

-   **File Operations:**
    -   Analyze the rootfs extraction process in `initForFirstTime`. Is the process of copying split asset files and then piping them to `tar` the most efficient method?
    -   Look for redundant file reads/writes or opportunities to cache file content in memory if it's accessed frequently.

### 2. UI & Rendering Analysis (`lib/main.dart`)

-   **Widget Build Optimization:**
    -   Scan all `build` methods in `lib/main.dart`. Identify any that contain expensive computations, I/O, or complex object creation. Propose moving this logic out of the `build` method.
    -   Look for opportunities to use `const` constructors for widgets to prevent unnecessary rebuilds.
    -   Check if `ValueListenableBuilder` or other state management widgets are scoped too broadly, causing large parts of the UI to rebuild when only a small piece of data has changed.
    -   For lists (like the command lists), verify that `ListView.builder` is used instead of a simple `Column` or `ListView` with a direct list of children, which is inefficient for long lists.

-   **Asset & Resource Management:**
    -   Analyze the initial loading process. Are there any large assets loaded synchronously on startup that could be loaded lazily or in the background?
    -   Check the `assets.zip` and `patch.tar.gz` files. Suggest optimizations if they contain uncompressed or unnecessarily large files.

### 3. Asynchronous Operations & State Management

-   **Futures & Async Gaps:**
    -   Scan the entire `lib/` directory for any `Future`s that are not handled with `await` or `.then()`. This can lead to race conditions and unpredictable behavior.
    -   Identify any `async` functions that perform long-running operations without yielding to the event loop, potentially causing UI jank. Suggest adding `await Future.delayed(Duration.zero)` where appropriate.

-   **State & Preferences (`G.prefs`):**
    -   Review all interactions with `SharedPreferences`. Are there any instances where preferences are read or written repeatedly in a hot path? Suggest caching these values in a global variable (`G` class) on startup.

## OUTPUT REQUIREMENTS

-   Create a pull request from the new branch to the main development branch.
-   The PR title should be: `perf: Daily Performance Audit & Optimizations for $(date +%Y-%m-%d)`.
-   The PR description must contain a "Performance Audit Report" section with:
    -   A summary of your findings.
    -   A detailed list of identified bottlenecks, each with the file path, line number, a clear explanation of the problem, and the reasoning for your proposed solution.
-   Implement safe, non-breaking optimizations in separate, logical commits. Each commit message should clearly describe the optimization being made.

## CONSTRAINTS

-   Do NOT introduce any functional changes. The app's behavior must remain identical.
-   Do NOT modify any user-facing UI layouts unless it is a direct result of a performance optimization (e.g., replacing a `Column` with a `ListView.builder`).
-   All changes must pass `flutter analyze` with zero warnings or errors.
-   Focus on small, atomic improvements that are easy to review and verify.
