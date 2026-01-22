The user wants a comprehensive guide to understanding the codebase, specifically a "Map" of how the app works and a recommended order to review the files.

This request takes precedence over the ongoing commenting task ("First can u create...").

**Plan:**
1.  **Create `GUIDE.md`**: A new markdown file in the project root.
2.  **Define Architecture**: Explain the MVVM-like pattern, "Managers" as single sources of truth, and the "Block" UI structure.
3.  **Define Review Order**: Create a 7-step learning path:
    *   **Level 1: The Foundation** (App entry, Theme, Main Tabs)
    *   **Level 2: The Brains** (Managers & Persistence)
    *   **Level 3: The Dashboard** (Layout & Blocks)
    *   **Level 4: Features** (Upcoming, Resources, Settings)
4.  **Explain Key Concepts**: Briefly touch on `ObservableObject`, `UserDefaults`, `EventKit`, and `LazyVGrid` so the user knows what to look for.

I will create this file immediately. No existing code will be modified in this step.
