# TriageDesk

A native, zero-dependency iOS operations triage application built with **Swift 5.10** and **SwiftUI** (targeting iOS 16.0+). It parses legacy, irregular form submission data from a local JSON dataset and provides operations staff with a clean, responsive, and accessible interface to search, filter, inspect, and triage incoming submissions.

---

## Stack & Versions Built Against

- **Language**: Swift 5.10
- **UI Framework**: SwiftUI (iOS 16.0+ Deployment Target)
- **IDE / Build Tools**: Xcode 15.0+ / Xcode 16.0+ / Command Line Tools
- **Host OS**: macOS Sonoma / macOS Sequoia (Apple Silicon & Intel compatible)
- **Architecture**: MVVM (Model-View-ViewModel) with Service & Storage layers
- **External Dependencies**: **Zero third-party packages** (100% pure native `Foundation` & `SwiftUI`)

---

## Setup & Run Instructions

### 1. Running in Xcode (Simulator or Physical Device)
1. Clone or open the project folder in your terminal.
2. Open the Xcode project:
   ```bash
   open TriageDesk.xcodeproj
   ```
3. In Xcode's top toolbar, select your desired run destination (e.g., **iPhone 15 Pro**, **iPhone 16**, or physical device running iOS 16+).
4. Press **`Cmd + R`** (or click the **Run** button) to build and launch the application.

### 2. Building from Command Line
To build the iOS target directly via the terminal:
```bash
xcodebuild -scheme TriageDesk -destination "generic/platform=iOS" build CODE_SIGNING_ALLOWED=NO
```

### 3. Running Automated Unit Tests
A zero-dependency standalone test suite is included at `Tests/SubmissionTests.swift`. Execute it directly from the workspace root:
```bash
swift Tests/SubmissionTests.swift
```
*Expected Output: `38/38 unit tests passing with zero failures.`*

---

## Key Features & Architecture

```
TriageDesk/
├── Models/
│   ├── Submission.swift                 # Core Codable model with custom decoder
│   ├── SubmissionStatus.swift           # Status enum & badge styling
│   └── Submission+Extensions.swift      # Normalization, phone E.164, & duplicate logic
├── Services/
│   ├── DataLoadService.swift            # JSON loading protocol & bundle implementation
│   └── ReviewStore.swift                # UserDefaults review state persistence
├── ViewModels/
│   └── SubmissionListViewModel.swift    # Search, filter, layout & duplicate aggregation
└── Views/
    ├── SubmissionListView.swift         # Main navigation feed & search
    ├── DashboardSummaryView.swift       # Proportional distribution bar & filter carousel
    ├── SubmissionRowView.swift          # Capsule pill list row with swipe actions
    ├── SubmissionDetailView.swift       # Full detail view with duplicate links
    └── SubmissionTableView.swift        # High-density spreadsheet grid view
```

1. **Resilient JSON Decoding Engine**:
   - Custom `init(from decoder:)` gracefully handles missing fields, empty objects (`{}`), type mismatches (e.g., Integer vs. String IDs), and malformed payloads without crashing.
   - Multi-strategy date parser supporting ISO-8601 (`2024-11-03T14:22:00Z`), slash dates (`2024/10/28`), and Unix Epoch timestamps (`1699012800`).
   - Phone number sanitization filtering invalid placeholders (`n/a`, `none`, `-`) and standardizing Philippine numbers (`09XX`, `02XX`) into standard **E.164** format (`+63...`).
   - Normalization of legacy status strings (`Open`, `OPEN`, `pending`, `reviewed`, `new`) into typed `SubmissionStatus` enums.
   - Normalization of legacy service tags (`web dev`, `mobile`, `Mobile App`, `Other`) with context-aware SF Symbols.

2. **Unified Dashboard & Status Distribution**:
   - Compact proportional distribution bar visually representing all submission statuses (`New`, `Open`, `Pending`, `In Review`, `Closed`, `Reviewed`, `Unknown`).
   - In-card triage state switches (`All`, `Pending`, `Done`) and horizontal status filter pills carousel.
   - Embedded directly inside the scrollable list feed so it scrolls smoothly with queue entries.

3. **Dual Viewing Modes**:
   - **Queue View**: Capsule pill cards featuring solid status badges, sender contact details, service tags, and right-aligned timestamps with native swipe actions.
   - **Table View**: Spreadsheet-style high-density grid with sticky column headers, horizontal & vertical scrolling, and inline review toggles.

4. **Multi-Field Duplicate Detection**:
   - Multi-field detection comparing email, normalized E.164 phone, service category, timestamp, remote ID, and form version (excluding name), recognizing that the same person may legitimately submit multiple distinct inquiries over time.
   - Visual amber warning badges (`[2x Duplicate]`) with single-line chip formatting on queue rows and a dedicated linked duplicates section in the detail view.

5. **Two-Way Review State Persistence**:
   - `ReviewStore` backed by `UserDefaults` with two-way manual overrides (`reviewedKeys` and `unreviewedOverrides`), automatically preserving triage decisions across app launches.

6. **Accessibility & Dynamic Type**:
   - Full support for iOS **Dynamic Type** text scaling across all views.
   - Descriptive **VoiceOver** accessibility labels, values, and traits for all interactive rows, distribution bar segments, and filter pills.

---

## 📌 Assumptions Made

1. **UI Identity Safety**: Remote record IDs in irregular legacy datasets may be null, missing, or duplicated across records. To ensure absolute SwiftUI rendering safety, every `Submission` generates a stable local `UUID()` for `Identifiable` conformance while preserving the raw `remoteId` for display and duplicate tracking.
2. **Review State Persistence**: Since no live backend database was provided, `UserDefaults` is assumed sufficient for local operations state. Pre-existing `"reviewed"` statuses in the dataset are respected automatically upon load while allowing explicit two-way review/unreview overrides.
3. **Phone Number Standards**: Philippine phone formats (`09XX`, `02XX`, `9XX`) are normalized to international E.164 standard (`+63...`), while placeholder strings (`n/a`, `none`, `nil`, `-`) are sanitized to `nil`.
4. **Duplicate Submission Criteria**: A person submitting multiple inquiries at different times or with different requests is considered legitimate. Therefore, a duplicate is strictly defined when all core submission fields (email, phone, service, timestamp, remote ID, form version) match, regardless of slight variations in the name field (e.g., `"Daniel Tan"` vs `"Daniel Tan (dup)"`).
5. **Status Normalization**: Legacy status strings with inconsistent capitalization (`"OPEN"`, `"open"`, `"in_review"`, `"in review"`) are mapped to typed enum cases, with unknown strings safely falling back to `.unknown`.

---

## 💬 What I Would Ask the Client Before Building for Production

1. **Duplicate Criteria & Follow-up Inquiries**: What exact combination of attributes constitutes a true duplicate versus a customer legitimately submitting multiple separate inquiries across different days?
2. **Card Information Density**: What minimal set of fields (e.g., sender name, status pill, service tag, 2-line message preview) do triage agents need on the queue cards to make swift routing decisions without visual clutter?
3. **Dashboard Summary Preferences**: Is the high-level status distribution bar helpful for daily operations, or do reviewers prefer a distraction-free queue feed (or a toggle to collapse the summary)?
4. **Date-Only & Timestamp Fallback Behavior**: For legacy records with dates but no timestamps (e.g., `2024/10/28`), should we omit the time label entirely instead of assuming `12:00 AM` (start of day)?
5. **Batch Review Workflow vs. Review Integrity**: Would a multi-select batch review action be beneficial for high volume, or does batch-approving risk reviewers skipping thorough inspection of individual submissions?
6. **Role-Based Access Control (RBAC)**: Should different team roles (e.g., Tier 1 Triage, Team Leads, Senior Engineers) have differentiated permissions to review, reassign, unreview, or close submissions?
7. **Audit Logging & Automated Dispatch**: Do we need an audit trail recording which agent reviewed a record and at what timestamp? Should review actions trigger automated webhooks (e.g., Slack alerts, CRM ticketing sync)?
8. **Data Retention & Privacy Compliance**: How should stale, closed, or spam submissions be archived? Are there specific GDPR / data privacy requirements for masking or auto-purging personal phone numbers and emails after a defined retention window?

---

## ⚠️ Known Limitations & Future Improvements

If given additional time to extend this project, the following enhancements would be prioritized:

1. **Pagination & Infinite Scrolling**:
   - Implement cursor-based or offset pagination to load submissions in bounded batches (e.g., 25–50 records per page) with lazy scrolling triggers, optimizing memory overhead and rendering performance as queue sizes grow.
2. **Remote Backend Sync & Real-Time Updates**:
   - Replace local bundle JSON loading with a REST / GraphQL API client featuring background fetching and WebSocket sync for real-time multi-agent triage queues.
3. **Batch Triage Operations**:
   - Multi-select mode allowing reviewers to select multiple submissions simultaneously to mark as reviewed, change status, or reassign.
4. **Export & Reporting**:
   - Capability to export filtered triage queues and status distribution summaries into CSV or PDF reports.
5. **Scalable Database Architecture**:
   - Migrate from in-memory / `UserDefaults` storage to **SwiftData** / SQLite for handling datasets scaling to hundreds of thousands of records with indexing.
6. **Advanced Multi-Dimensional Filtering**:
   - Combine custom date range pickers, service tag checkboxes, and keyword filters into reusable custom filter presets.

---

## 🤖 AI Tool Usage Disclosure & Validation

In compliance with transparency guidelines, AI tools (**Gemini** and **Antigravity**) were utilized during development as follows:

- **Learning Swift & SwiftUI**: Utilized Gemini AI as an accelerated learning tutor to master Swift 5.10 syntax and SwiftUI declarative paradigms, as this was my first time developing natively on this tech stack.
- **Prompt Engineering & Scaffolding**: Structured the project requirements into prompt specifications used to scaffold the Xcode project structure.
- **State Management Architecture**: Consulted AI to map web state management concepts (e.g., Redux Toolkit) to native iOS architectures, discovering SwiftUI's `@ObservableObject` with `@Published private(set) var` and `@EnvironmentObject` patterns.
- **Data Layer & Custom Decoding**: Leveraged AI to construct the `DataLoadService` protocol and resilient parsing algorithms within custom `init(from decoder:)`.
- **Automated Testing Suite**: Utilized AI to construct the standalone unit test suite and test runner (`Tests/SubmissionTests.swift`), ensuring comprehensive test coverage across decoding edge cases, date formats, phone normalization, and duplicate detection.
- **UI Prototyping & Boilerplate**: Used Gemini for initial view scaffolding, followed by extensive manual UI design refinement, layout customization, animation tuning, and accessibility enhancements.
- **Documentation & README Drafting**: Utilized AI to assist in structuring, formatting, and drafting project documentation and the `README.md`.
- **Validation Strategy**:
  - **Automated Tests**: Verified all parsing, normalization, and duplicate detection rules with 38 unit tests via `swift Tests/SubmissionTests.swift`.
  - **Native Compilation**: Validated zero errors and zero warnings via `xcodebuild`.
  - **Dataset Stress Testing**: Verified stability against malformed JSON, empty objects, long text strings, and irregular formats.
  - **Accessibility & Device Testing**: Verified Dynamic Type font scaling and VoiceOver accessibility labels in the iOS Simulator.

---

## 🎯 What to Focus on During Review

When evaluating this project, please pay special attention to:

1. **Resilient Decoding & Normalization (`Submission.swift` & `Submission+Extensions.swift`)**:
   - How the custom `init(from decoder:)` seamlessly handles type mismatches (Int vs String IDs), empty payloads (`{}`), multi-format timestamps, placeholder phone stripping, and Philippine E.164 normalization without fatal errors.
2. **Clean MVVM Architecture & Separation of Concerns**:
   - Decoupled `DataLoadService`, centralized `ReviewStore` with two-way persistence, and reactive `SubmissionListViewModel` driving synchronized badge counts and filtered lists.
3. **Operations-Focused UI & Dashboard Design (`DashboardSummaryView.swift` & `SubmissionRowView.swift`)**:
   - The compact proportional status distribution bar with in-card triage state switches and horizontal filter carousel that scrolls seamlessly within the list feed.
   - Dual layout modes (Queue vs Table) and single-line chip layouts preventing phone numbers and tags from wrapping.
4. **Accessibility First (`VoiceOver` & `Dynamic Type`)**:
   - Thoughtful accessibility descriptions, labels, values, and traits integrated across all interactive cards, distribution bar segments, and filter pills.
5. **Standalone Unit Test Suite (`Tests/SubmissionTests.swift`)**:
   - 38 standalone, dependency-free unit tests verifying decoding resilience, date parsing strategies, phone sanitization, status normalization, and duplicate detection.
