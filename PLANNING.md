# Feature Planning Document: Submissions Triage

## 1. Feature Overview

### Feature name

TriageDesk

### Overview

A native iOS application that reads a snapshot of irregular, legacy form submission data from a local JSON file. It provides operations staff with a clean, unified mobile interface to browse, filter, read, and mark these submissions as reviewed.

### User / customer perspective

The operations team struggles with messy data coming from years of inconsistent form versions. This app solves the problem by acting as a robust parser and a clean, readable dashboard. It transforms chaotic records into a reliable triage workflow.

### Developer perspective

I am implementing this using Swift and SwiftUI with an MVVM architecture. To ensure the app feels familiar and highly accessible, I am strictly adhering to Apple's Human Interface Guidelines (HIG), utilizing default native components (`NavigationStack`, standard toolbars, native dropdown menus). The primary technical challenge will be handling the malformed JSON. I will handle this via a resilient data model using a custom `init(from decoder:)`.

### QA perspective

**What could go wrong:** The app could crash during JSON decoding if strict types fail, or SwiftUI could crash if IDs are missing or duplicated. Long text could break the layout.
**What should be tested:** Decoding edge cases, empty objects, layout boundary testing (massive strings), UI state transitions, and the persistence of the local "Reviewed" state.

---

## 2. User Stories

- As a reviewer, I want to view a summarized list of all form submissions, so that I can quickly gauge the volume and basic details of incoming requests.
    - *Acceptance Criterion 1:* Reads `submissions.json` from the bundle and displays a list.
    - *Acceptance Criterion 2:* Each row shows primary info (Name, Date, Status).
    - *Acceptance Criterion 3:* If data is missing or empty, it displays a sensible fallback instead of crashing.

- As a reviewer, I want to search by name and filter by status (e.g., Unreviewed/Reviewed), so that I can focus only on the submissions I need to action.
    - *Acceptance Criterion 1:* A native search bar filters the list based on the name or email field.
    - *Acceptance Criterion 2:* A native toolbar menu allows me to filter submissions by their review status.

- As a reviewer, I want to tap on a submission to see its full details, so that I can read all the inconsistent fields associated with that specific record.
    - *Acceptance Criterion 1:* Tapping a row navigates to a Detail Screen.
    - *Acceptance Criterion 2:* The detail screen renders all available data without breaking the layout on long strings.

- As a reviewer, I want to mark a submission as "Reviewed", so that my team knows it has been handled.
    - *Acceptance Criterion 1:* A "Mark as Reviewed" action exists via native swipe actions on the list row and a toolbar button on the detail screen.
    - *Acceptance Criterion 2:* The list UI updates immediately, and the state persists locally.

---

## 3. Requirements Review

### Functional requirements

* Load local JSON data from the app bundle.
* Parse malformed data without crashing.
* Display a list of submissions with key summaries.
* Provide text search and status filtering.
* Display a detail view for individual submissions.
* Toggle and persist a "Reviewed" state locally.

### Non-functional requirements

* **Maintainability:** Strict separation of concerns using MVVM. Data fetching/decoding logic decoupled from SwiftUI views.
* **Reliability:** Zero crashes caused by unexpected JSON structures.
* **Accessibility:** Support for iOS Dynamic Type (scalable fonts) and Dark Mode.
* **Usability:** A familiar, native iOS interface.

### Requirements I would clarify or challenge

* *Duplicate detection (Stretch Goal):* Without knowing the business logic for defining a "true" duplicate in production, I will handle UI safety by generating local `UUID`s for the list, but keep duplicate flagging simple.
* *Reviewed State Persistence:* I will use `UserDefaults` to persist the reviewed state across app launches, as in-memory would reset every time the app closes.

---

## 4. Technical Plan

### Technology stack

* **Stack:** Swift 5.10, SwiftUI
* **Target:** iOS 16.0+ (Xcode 15+)
* **Architecture:** MVVM (Model - View - ViewModel)
* **Packages:** None. Native `Foundation` and `SwiftUI` only.

### Data model / data handling

* `Submission`: A `Codable`, `Identifiable` struct.
* To handle the messy data, I anticipate needing a custom `init(from decoder: Decoder)` to:
* Assign a fresh `UUID()` to `self.id` to guarantee SwiftUI `List` stability.
* Use multiple `DateFormatter` configurations to handle varying date formats.
* Coerce mismatched types (like ints passed as strings) safely.



### Architecture / components / modules

* **Models:** `Submission`, `SubmissionStatus`
* **Services:**
* `DataLoadService`: Reads and decodes `submissions.json`.
* `ReviewStore`: An `ObservableObject` managing reviewed IDs, backed by `UserDefaults`.


* **ViewModels:**
* `SubmissionListViewModel`: Holds the search text, current filter state, and computes the filtered list.


* **Views:**
* `SubmissionListView`: Wrapped in a `NavigationStack` utilizing `.searchable` and `.toolbar`.
* `SubmissionRowView`: List row utilizing `.swipeActions`.
* `SubmissionDetailView`: Scrollable detail screen.



### State management / flow

* The `ReviewStore` will be injected via `.environmentObject()`. This ensures instant UI updates across the app when an item is reviewed without complex bindings.

### Implementation steps

1. **Setup & Models:** Scaffold Xcode project, add JSON, and write the custom `Submission` struct.
2. **Data Layer:** Implement `DataLoadService` and verify it survives the malformed JSON.
3. **State Layer:** Implement `ReviewStore` and `SubmissionListViewModel`.
4. **UI - List:** Build the `NavigationStack` list, applying native search and swipe actions.
5. **UI - Detail:** Build the detail view and integrate the toolbar review toggle.
6. **Polish:** Test layout boundaries, check accessibility, and record the demo.

---

## 5. Testing Plan

Manual tests are required. Automated tests are optional. The test scenarios are defined using Gherkin syntax mapped to the required table format.

| Test Case | Steps | Expected Result | Tested? |
| --- | --- | --- | --- |
| **Scenario: Malformed ID and Duplicate Handling** | **Given** the app loads the local JSON containing records with missing, null, or duplicate IDs. **When** the app parses the data and renders the list view. | **Then** the app should not crash. **And** duplicate or missing ID records should render safely as distinct, selectable rows. | No |
| **Scenario: Messy Date Parsing** | **Given** a form submission contains a date formatted as a Unix Epoch integer or a non-standard string. **When** the user views the submission in the list or detail screen. | **Then** the date should be correctly parsed and displayed in a unified, human-readable format. **And** the app should not crash or display raw integers. | No |
| **Scenario: Empty Object Fallbacks** | **Given** the JSON dataset contains completely empty objects (e.g., `{}`). **When** the user scrolls through the submission list. | **Then** the app should render the item using sensible fallbacks like "Unknown Sender". **And** the layout should not break or throw a fatal error. | No |
| **Scenario: Review State Persistence** | **Given** the user marks a specific submission as "Reviewed". **When** the user force-quits the app and relaunches it. | **Then** that submission should remain visibly marked as "Reviewed" in the list view. | No |
| **Scenario: Dynamic Type Accessibility** | **Given** the user increases the system text size via iOS Settings (Accessibility). **When** the user navigates through the app's list and detail screens. | **Then** all text elements should scale proportionally. **And** no text should be clipped, truncated without purpose, or rendered unreadable. | No |

---

## 6. Timebox Plan

* **0.0 - 1.0 hr:** Planning document, repository setup, architecture scaffolding.
* **1.0 - 2.5 hrs:** Core data models and the custom `Decoder` (the most critical part).
* **2.5 - 4.5 hrs:** ViewModels, ReviewStore, and building the UI using native components.
* **4.5 - 5.5 hrs:** Search, toolbar filtering, and state transitions.
* **5.5 - 6.5 hrs:** Edge-case testing, layout boundary checks, and accessibility checks.
* **6.5 - 7.5 hrs:** Code cleanup, README documentation, and recording the demo video.

---

## 7. Risks, Trade-offs, and Follow-up

* **What did you intentionally skip?**
* **What would you improve with more time?**
* **What would you ask the client before building this for production?**
* **If you used AI tools, how did you use them and how did you validate output?**

---

## 8. Iterations

| Change | Reason |
| --- | --- |
| N/A | No major plan changes yet. Initial planning phase. |