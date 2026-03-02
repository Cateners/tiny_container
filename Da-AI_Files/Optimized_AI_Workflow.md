# Optimized AI Workflow for DaRipped_tiny_computer Arch Linux Conversion

## Context Overview

This document outlines an optimized strategy for leveraging various AI agents (Claude, Gemini, Jules) to complete the `DaRipped_tiny_computer` Arch Linux conversion project. This strategy takes into account agent capabilities, subscription tiers, rate limits, and the user's local development environment, including the ongoing setup of local LLMs.

**Project Goal:** Convert the `DaRipped_tiny_computer` Flutter Android application from a Debian Trixie proot container to an Arch Linux ARM proot container, optimized for the Google Pixel 9 (non-root, Shizuku + rish).

**Agent Status & Environment:**
- **Claude (Claude Code / claude-cli):** Pro features (messaging & coding) available. **Constraint:** Fast messaging limits require spaced-out interactions.
- **Gemini (gemini-cli - Desktop CachyOS & Termux Pixel 9):** Two separate accounts linked to GitHub, both on Pro subscription. Excellent for direct filesystem access and shell command execution.
- **Jules (Google Coding Bot):** Two accounts connected to GitHub, both on Pro subscription. Ideal for autonomous repo operations (cloning, branching, committing, PRs).
- **GitHub Copilot:** Available for code generation, PR creation/review, and issue resolution.
- **Local LLM Setup:** In progress on both CachyOS Desktop and Pixel 9 (non-rooted, with Shizuku and Rish). This will eventually offload smaller, iterative tasks.

---

## Strategic Approach

The conversion project involves distinct phases: extensive code modification, script generation, build configuration, and documentation. This plan aims to parallelize work where possible and manage agent-specific constraints.

1.  **Initial Research & Planning (Gemini/Claude/Copilot for initial review, User-driven):**
    *   The user will perform the initial high-level planning and create the detailed prompt documentation (`DaRipped_ArchLinux_Conversion_Prompts.md`).
    *   **Gemini (Desktop):** Can be used for quick file inspections, summarizing existing code, and generating initial lists of areas to change.
    *   **Claude:** Can perform a deep codebase analysis (`claude-cli` prompt) to generate a comprehensive report of all Debian-specific instances (commands, paths, strings) before any changes are made. This comprehensive report will be crucial for subsequent steps.
    *   **Copilot:** Can assist in generating initial code snippets for new functionalities or brainstorming architectural approaches.

2.  **Core Code & Script Generation (Primary: Claude; Secondary: Gemini/Copilot):**
    *   **Claude (Primary):** Due to its strength in multi-file edits and consistency, Claude will be the primary agent for significant code modifications in `lib/workflow.dart`, `lib/main.dart`, and `lib/l10n/`. The large `claude-cli` prompt is well-suited for this. **Important:** User must manage Claude's messaging limits by reviewing output and giving spaced prompts.
    *   **Gemini (Desktop):** Can handle smaller, well-defined script generation tasks (e.g., `extra/build-arch-rootfs.sh`, `extra/build-arch-rootfs.md`) and verify specific code sections. Can also assist in iteratively debugging Flutter build issues on the CachyOS desktop.
    *   **Copilot:** Can be tasked with generating specific functions, utility classes, or completing well-defined code blocks within the larger refactoring effort.
    *   **Jules (Future/Support):** Once the core code changes are stable, Jules could be tasked with creating branches and handling commit/PR workflows for specific feature increments, but likely later in the process.

3.  **Mobile-Specific Tasks & Validation (Primary: Gemini-Termux; Secondary: User):**
    *   **Gemini (Termux on Pixel 9):** This agent is uniquely positioned to handle on-device tasks like:
        *   Building the Arch Linux ARM rootfs directly on the Pixel 9 using `proot-distro` (as per "Prompt 3").
        *   Validating proot operation with the generated rootfs.
        *   Testing Shizuku/rish integration for process priority, faster I/O, and CPU affinity.
        *   Iterating on shell scripts intended to run within the proot container.
        *   Transferring rootfs chunks for APK bundling.
    *   **User:** Will oversee and perform manual verification steps on the Pixel 9.

4.  **Build Configuration & Documentation (Gemini/Jules/Copilot/User):**
    *   **Gemini (Desktop):** Update `pubspec.yaml`, `android/app/build.gradle`, `AndroidManifest.xml` as per "Prompt 2" or refined instructions. Also responsible for rewriting `README.md` and other documentation files.
    *   **Jules:** Can be used for the final commit and pull request creation once all changes are validated. Its autonomous nature makes it ideal for integrating a completed feature branch.
    *   **Copilot:** Can assist in drafting configuration changes, generating boilerplate for documentation sections, or creating PRs for specific build-related updates.

5.  **Local LLM Integration (Future):**
    *   As the local LLMs on CachyOS and Pixel 9 become operational, they can gradually take over smaller, iterative tasks currently assigned to Gemini/Claude/Copilot, reducing reliance on cloud-based agents for rapid, back-and-forth debugging or minor text manipulation. This will be particularly useful for managing Claude's rate limits.

---

## Agent-Specific Tasking & Considerations

### Claude (claude-cli)

*   **Strengths:** Deep codebase comprehension, multi-file consistency, complex refactoring.
*   **Optimal Use:** Initial comprehensive code analysis report, large-scale `workflow.dart` and `main.dart` refactoring, `l10n/` file updates across all locales.
*   **Constraint Management:** Plan interactions to accommodate fast messaging limits. Break down complex Claude tasks into smaller, distinct prompts. Review each output carefully before providing the next instruction. Avoid rapid back-and-forth debugging with Claude; use Gemini or Copilot for that.

### Gemini (gemini-cli - Desktop CachyOS)

*   **Strengths:** Direct filesystem access, shell command execution, iterative debugging, script generation, documentation updates.
*   **Optimal Use:** Initial file overviews, generating build scripts (`build-arch-rootfs.sh`), updating `pubspec.yaml` and Android build files, `README.md` and `extra/` documentation, Flutter `analyze` and `build` command execution for compilation checks, detailed `grep` searches for verification.
*   **Considerations:** Can be used for iterative code changes if Claude is rate-limited or for smaller, focused changes.

### Gemini (gemini-cli-termux - Mobile Pixel 9)

*   **Strengths:** On-device execution within Termux, `proot-distro` usage, Shizuku/rish integration testing, rootfs generation and testing.
*   **Optimal Use:** Executing "Prompt 3" in its entirety to build, configure, and test the Arch Linux ARM rootfs directly on the Pixel 9. Validating proot behavior and Shizuku/rish functionality in the target environment. Packaging rootfs chunks for transfer to the build machine.
*   **Considerations:** Resource constraints of the mobile device mean focusing on terminal-based operations and script execution rather than large-scale code editing.

### Jules (Google Coding Bot)

*   **Strengths:** Autonomous GitHub workflow (branching, committing, PRs), integrating complete feature sets.
*   **Optimal Use:** Finalizing the Arch Linux conversion into a coherent set of commits and opening a pull request. Can also be used for specific, well-defined sub-tasks (e.g., "implement Shizuku detection in `workflow.dart`") once the core conversion is stable.
*   **Considerations:** Less suitable for iterative debugging or open-ended exploration compared to Gemini, Claude, or Copilot. Provide clear, self-contained tasks.

### GitHub Copilot

*   **Strengths:** Efficient code generation for functions/modules, automated PR creation, PR review, issue resolution.
*   **Optimal Use:**
    *   **Code Generation:** Generating boilerplate, specific Dart functions (e.g., ShizukuHelper class methods), or smaller utility scripts.
    *   **PR Creation:** Creating pull requests based on a problem statement (e.g., `/create_pull_request_with_copilot`) or assigning it to an issue for a fix (e.g., `/assign_copilot_to_issue`).
    *   **Code Review:** Requesting an automated review on a pull request for initial feedback (e.g., `/request_copilot_review`).
*   **Considerations:** Best for well-defined coding tasks rather than open-ended architectural decisions. Can be a good alternative to Gemini for iterative code generation if Gemini is occupied with shell tasks.

---

## Workflow Summary

1.  **User/Gemini/Copilot:** Review `DaRipped_ArchLinux_Conversion_Prompts.md`.
2.  **Claude (Initial):** Deep code analysis and report generation (manage rate limits).
3.  **Gemini (Desktop)/Copilot:** Generate `build-arch-rootfs.sh` and `build-arch-rootfs.md` (Copilot can help with initial script drafting).
4.  **Claude (Core Conversion)/Copilot:** Make primary code changes in `workflow.dart`, `main.dart`, `l10n/` (spaced Claude interactions, user review; Copilot for specific function generation).
5.  **Gemini (Desktop)/Copilot:** Update `pubspec.yaml`, Android build files, rewrite `README.md` and `extra/` docs. Perform Flutter analysis and build checks (Copilot can assist with documentation boilerplate and config updates).
6.  **Gemini (Termux):** Execute on-device rootfs build and testing ("Prompt 3"). Transfer chunks.
7.  **Gemini (Desktop)/Copilot:** Final verification (grep for Debian artifacts, compile; Copilot for automated PR review).
8.  **Jules/Copilot:** Create feature branch, commit all changes, open PR (Jules for autonomous, Copilot for direct PR creation/issue resolution).

This phased approach leverages each AI's strengths while mitigating their weaknesses (like Claude's rate limits) and utilizing the local environments efficiently.
