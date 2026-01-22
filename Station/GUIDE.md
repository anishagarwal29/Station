# 🗺️ Station App - Architecture & Code Guide

Welcome to the Station codebase! This guide is designed to help you understand how the app works "under the hood" and provide a structured path for reviewing the code.

---

## 🏗️ High-Level Architecture

Station follows a simplified **MVVM (Model-View-ViewModel)** pattern, tailored for SwiftUI.

1.  **Views (The UI)**:
    -   These are the visual components (Screens, Cards, Buttons).
    -   They **observe** the Managers. When data changes, Views automatically update.
    -   *Key Concept*: "Blocks" (Small, reusable widgets like `ClassesBlock` or `AlertsBlock`).

2.  **Managers (The Brains)**:
    -   These act as the "ViewModels" and "Data Stores".
    -   They are **Singletons** or **Environment Objects** (shared across the whole app).
    -   They handle logic (sorting, filtering), persistence (saving to disk), and APIs (Calendar).
    -   *Examples*: `UpcomingManager`, `CalendarManager`, `SettingsManager`.

3.  **Models (The Data)**:
    -   Simple structures holding data.
    -   *Examples*: `UpcomingItem`, `CalendarEvent`.

---

## 📚 Recommended Review Order

To fully grasp the codebase, I recommend reading the files in this specific order. This path builds from the "Foundation" up to the "Features".

### 🟢 Phase 1: The Foundation
*Start here to see how the app launches and looks.*

1.  **`App/StationApp.swift`**
    -   **Why**: The Entry Point. See how we create the `Managers` and inject them into the app so every view can use them.
2.  **`Core/Theme.swift`**
    -   **Why**: The Design System. See how we centralized colors (Blue, Dark Mode) and fonts.
3.  **`Views/Tabs/MainTabView.swift`**
    -   **Why**: The Navigation. See how we switch between screens and the custom floating tab bar logic.

### 🟡 Phase 2: The Logic (Managers)
*Now let's see how data is handled before we look at the complex UIs.*

4.  **`Managers/SettingsManager.swift`**
    -   **Why**: The simplest Manager. See how we save user preferences to `UserDefaults` and use the `Singleton` pattern.
5.  **`Managers/CalendarManager.swift`**
    -   **Why**: See how we talk to the Apple `EventKit` framework to fetch read-only calendar events and deduplicate them.
6.  **`Managers/UpcomingManager.swift`**
    -   **Why**: Handles user-created data (Tasks). Logic for "CRUD" (Create, Read, Update, Delete) and auto-cleaning old items.

### 🔵 Phase 3: The Dashboard (Main Screen)
*See how the components come together.*

7.  **`Views/Dashboard/DashboardView.swift`**
    -   **Why**: The skeleton. See how we use `ScrollView` to hold different "Blocks".
8.  **`Views/Dashboard/ClassesBlock.swift`**
    -   **Why**: A simple block. See how it filters `CalendarManager` events for "Today".
9.  **`Views/Dashboard/AlertsBlock.swift`**
    -   **Why**: Complex Logic. This is the "Smart" block. Review the `currentAlertCandidates` logic to see how it decides what to yell at you about.

### 🟣 Phase 4: Key Features
*Deep dive into specific tabs.*

10. **`Views/Upcoming/UpcomingView.swift`**
    -   **Why**: Advanced Lists. See how we mix "Calendar Events" and "Manual Tasks" into one list, customized filter chips, and section headers.
11. **`Views/Resources/ResourcesView.swift`**
    -   **Why**: Grid Layouts. See `LazyVGrid` and how we launch URLs using `NSWorkspace`.

---

## 🔑 Key Concepts to Spot

While reading, look for these patterns:

-   **`@EnvironmentObject`**: How views get access to the Managers without passing them manually through every parent view.
-   **`didSet { save... }`**: In Managers, this ensures that the moment a variable changes, it's saved to disk.
-   **`prefix(2)`**: In Dashboard blocks, we often limit the list to just the top 2 items to keep the UI clean.
-   **Computed Properties (var x: Type { ... })**: Used heavily to filter raw data (e.g. "All Events") into specific views (e.g. "Today's Physics Class").

Happy Coding! 🚀
