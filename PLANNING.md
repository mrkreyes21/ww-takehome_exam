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

- As a reviewer, I want to search by name, email, or message, and filter by status (e.g., Unreviewed/Reviewed), so that I can focus only on the submissions I need to action.
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

* `Submission`: A `Codable`, `Identifiable` struct with custom decoding and presentation extensions.
* To handle the messy data, custom decoding and extension logic:
    * Generates a stable `UUID()` for SwiftUI `List` identity while preserving raw decoded record IDs (coercing Int/String).
    * Uses a multi-strategy date parser to handle ISO8601 strings (`2024-11-03T14:22:00Z`), slash dates (`2024/10/28`), and Unix Epoch timestamps (`1699012800`).
    * Sanitizes phone numbers by filtering invalid placeholders (`n/a`, `none`, `-`) and normalizing Philippine formats (`09XX`, `02XX`) to standard E.164 (`+63...`).
    * Normalizes legacy status strings (`Open`, `OPEN`, `pending`, `reviewed`, `new`) to typed `SubmissionStatus` enums.
    * Normalizes legacy service strings (`web dev`, `mobile`, `Mobile App`, empty/null) into standardized display categories (`Web Development`, `Mobile App Development`, `Other`, `General Inquiry`) with matching SF Symbols.

### Architecture / components / modules

* **Models:** `Submission`, `SubmissionStatus`
* **Services:**
* `DataLoadService`: Reads and decodes `submissions.json`.
* `ReviewStore`: An `ObservableObject` managing reviewed IDs, backed by `UserDefaults`.

* **ViewModels:**
* `SubmissionListViewModel`: Holds the search text, current filter state, layout mode, and computes the filtered list.

* **Views:**
* `SubmissionListView`: Wrapped in a `NavigationStack` utilizing `.searchable`, `.toolbar`, and layout switcher.
* `SubmissionRowView`: List row utilizing `.swipeActions`.
* `SubmissionDetailView`: Scrollable detail screen.
* `SubmissionTableView`: High-density spreadsheet grid view with sticky headers, bidirectional scrolling, and inline review actions.
* `DashboardSummaryView`: Space-efficient status distribution bar with in-card triage state switches (`All`/`Pending`/`Done`) and a horizontal status pills carousel (`New`, `Open`, `Pending`, `In Review`, `Closed`, `Reviewed`, `Unknown`), scrolling seamlessly with queue entries.

### State management / flow

* The `ReviewStore` will be injected via `.environmentObject()`. This ensures instant UI updates across the app when an item is reviewed without complex bindings.

### Implementation steps

1. **Setup & Models:** Scaffold Xcode project, add JSON, and write the custom `Submission` struct.
2. **Data Layer:** Implement `DataLoadService` and verify it survives the malformed JSON.
3. **State Layer:** Implement `ReviewStore` and `SubmissionListViewModel`.
4. **UI - List:** Build the `NavigationStack` list, applying native search and swipe actions.
5. **UI - Detail:** Build the detail view and integrate the toolbar review toggle.
6. **UI - Table:** Build the spreadsheet grid view for high-density horizontal scanning.
7. **Polish:** Test layout boundaries, check accessibility, and record the demo.

---

## 5. Testing Plan

Manual tests are required. Automated tests are optional. The test scenarios are defined using Gherkin syntax mapped to the required table format.

| Test Case | Steps | Expected Result | Tested? |
| --- | --- | --- | --- |
| **Scenario: Malformed ID and Duplicate Handling** | **Given** the app loads the local JSON containing records with missing, null, or duplicate IDs. **When** the app parses the data and renders the list view. | **Then** the app should not crash. **And** duplicate or missing ID records should render safely as distinct, selectable rows. | Yes |
| **Scenario: Messy Date Parsing** | **Given** a form submission contains a date formatted as a Unix Epoch integer or a non-standard string. **When** the user views the submission in the list or detail screen. | **Then** the date should be correctly parsed and displayed in a unified, human-readable format. **And** the app should not crash or display raw integers. | Yes |
| **Scenario: Empty Object Fallbacks** | **Given** the JSON dataset contains completely empty objects (e.g., `{}`). **When** the user scrolls through the submission list. | **Then** the app should render the item using sensible fallbacks like "Unknown Sender". **And** the layout should not break or throw a fatal error. | Yes |
| **Scenario: Review State Persistence** | **Given** the user marks a specific submission as "Reviewed". **When** the user force-quits the app and relaunches it. | **Then** that submission should remain visibly marked as "Reviewed" in the list view. | Yes |
| **Scenario: Dynamic Type Accessibility** | **Given** the user increases the system text size via iOS Settings (Accessibility). **When** the user navigates through the app's list and detail screens. | **Then** all text elements should scale proportionally. **And** no text should be clipped, truncated without purpose, or rendered unreadable. | Yes |
| **Scenario: Automated Unit Testing (Decoding, Normalization & Duplicates)** | **Given** the custom decoding engine processes irregular timestamps, Philippine phone formats, status enums, and duplicate contacts. **When** the unit test suite (`Tests/SubmissionTests.swift`) executes. | **Then** all 37 test cases must pass without assertions or crashes. | Yes |

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
    * *Remote Backend Sync:* Used local persistence via `UserDefaults` with two-way override tracking (`reviewedKeys` and `unreviewedOverrides`) rather than setting up an active REST API / WebSocket sync engine.
    * *Heavy Third-Party Charting Libraries:* Built custom, lightweight SwiftUI visual distribution bars and filter carousels to maintain zero external dependencies and guaranteed build stability.
    * *Complex Merge Conflict Resolution:* Generated stable local `UUID`s for list rendering safety while keeping remote ID tracking transparent.

* **What would you improve with more time?**
    * *Batch Triage Operations:* Multi-select actions to review or reassign multiple submissions simultaneously.
    * *Export and Reporting:* Capabilities to export filtered triage queues to CSV or JSON formats.
    * *Advanced Multi-Attribute Filters:* Combining service tags, date ranges, and status filters into customizable presets.
    * *Database Scalability:* Migrating from bundle JSON / `UserDefaults` to SwiftData / SQLite for datasets exceeding tens of thousands of records.

* **What would you ask the client before building this for production?**
    * *Duplicate Definition & Business Criteria:* What exact combination of attributes (e.g., matching email + timestamp window vs. normalized phone vs. remote record ID) constitutes a true duplicate submission versus a customer submitting legitimate follow-up inquiries across multiple days?
    * *Card Information Hierarchy & Clutter Minimization:* What minimum set of fields (e.g., name, status pill, service tag, and 2-line message preview) do triage agents actually need on the queue cards to make swift routing decisions without visual clutter, and which fields should remain strictly inside the detail screen?
    * *Dashboard Summary Value & Customization:* Is the high-level dashboard status distribution bar helpful for reviewers' daily triage workflow, or is a pure, distraction-free queue feed preferred? Should users have a toggle to collapse or hide the dashboard summary?
    * *Date-Only and Timestamp Fallback Behavior:* Legacy records often contain dates without timestamps (e.g., `2024/10/28`). We currently default to `12:00 AM` (start of day) — should we omit the time label entirely for date-only records, or use a specific business-hour default / timezone offset?
    * *Batch Review Workflow vs. Inspection Quality:* Would a multi-select batch review action be beneficial for handling high volume, or does batch-approving risk reviewers skipping thorough inspection of individual submission content?
    * *Role-Based Access Control (RBAC) & Permissions:* Should different team roles (e.g., Tier 1 Triage, Team Leads, Senior Engineers) have differentiated permissions to review, reassign, unreview, or close submissions?
    * *Audit Logging & Automated Dispatch:* Do we need an audit trail recording which agent reviewed a record and at what timestamp? Should reviewing an entry trigger automated webhooks or notifications (e.g., Slack alerts, CRM ticketing sync, customer auto-responses)?
    * *Data Retention & Privacy Compliance:* How should stale, closed, or spam submissions be archived? Are there specific data privacy / GDPR rules for masking or auto-purging personal phone numbers and emails after a defined retention window?

* **If you used AI tools, how did you use them and how did you validate output?**
    * **Learning Swift & SwiftUI:** Utilized Gemini AI as a learning accelerator to rapidly understand Swift 5.10 language fundamentals and SwiftUI declarative paradigms, as this is my first time developing natively on this tech stack.
    * **Prompt Engineering & Scaffolding:** Upon finishing the initial `PLANNING.md`, used Gemini to engineer a structured setup prompt, which was then fed into Antigravity to scaffold the base Xcode project and directory structure.
    * **State Management Architecture:** Consulted AI to map web-based state management concepts (e.g., Redux Toolkit) to native iOS architectures, discovering SwiftUI's `@ObservableObject` with `@Published private(set) var` and `@EnvironmentObject` patterns.
    * **Data Layer & Services:** Leveraged AI to construct the `DataLoadService` protocol and implement resilient parsing strategies within the custom `init(from decoder:)`.
    * **Automated Testing Code:** Utilized AI to generate and construct the unit test suite and test runner (`Tests/SubmissionTests.swift`), testing phone number E.164 normalization, multi-format date parsing, status normalization, duplicate detection, and malformed JSON resilience.
    * **UI Scaffolding & Manual Refinement:** Used Gemini for initial view screen boilerplate given my unfamiliarity with SwiftUI syntax, and subsequently improved, customized, and polished the UI components, animations, and layouts independently.
    * **Documentation & README:** Utilized AI to help structure, format, and draft the comprehensive project `README.md` documentation, detailing setup guides, architecture highlights, and workflow walk-throughs.
    * **Validation Strategy:** Thoroughly verified all AI-assisted outputs through Xcode 15/16 native compilation (`xcodebuild`), test suite executions, manual edge-case testing against the messy dataset, layout boundary stress checks, and simulator device verification.

---

## 8. Iterations

| Change | Reason |
| --- | --- |
| **Phone Sanitization & E.164 Normalization** | Filtered placeholder values (`n/a`, `none`, `nil`, `-`) and normalized Philippine phone numbers (`09XX`, `02XX`, `9XX`) to standard `+63...` E.164 format. |
| **Harmonized `ReviewStore` Initial State** | Automatically recognizes pre-reviewed items from the dataset while supporting two-way manual review/unreview overrides. |
| **Added `SubmissionTableView` (Spreadsheet Grid View)** | Created a bidirectional scrollable table view with sticky headers and inline review actions for high-density operations scanning. |
| **Service Name Normalization & Dynamic Icons** | Standardized inconsistent legacy service strings (`web dev`, `mobile`, `Mobile App`, `Mobile App Development`, `Other`, empty/null) into unified display titles (`Web Development`, `Mobile App Development`, `Other`, `General Inquiry`) with context-aware SF Symbols and search support. |
| **Capsule Pill Row UI Redesign** | Redesigned submission list rows into high-contrast capsule pill cards with prominent solid status pills (`REVIEWED`, `OPEN`, `NEW`, `PENDING`), sender info, service tags, and right-aligned timestamp formatting. |
| **Distribution Graph & Filter Carousel** | Redesigned status dashboard into a compact, space-efficient proportional distribution bar with in-card triage state switches (`All`/`Pending`/`Done`) and a horizontal status pills carousel (`New`, `Open`, `Pending`, `In Review`, `Closed`, `Reviewed`, `Unknown`), scrolling seamlessly with the entries. |
| **Likely Duplicate Surfacing** | Implemented multi-field duplicate detection comparing email, normalized phone, service, date, remote ID, and form version (excluding name) with single-line chip rendering in list rows and a linked duplicates section in the detail view. |
| **Accessibility & VoiceOver Enhancements** | Added comprehensive Dynamic Type scalable text sizing and VoiceOver accessibility labels, values, and traits across all rows, status distribution segments, filter pills, and navigation links. |
| **Unit Test Suite** | Created a complete standalone unit test suite (`Tests/SubmissionTests.swift`) covering decoding resilience, phone E.164 parsing, date parsing strategies, status normalization, and duplicate matching (38/38 passing). |