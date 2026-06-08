# RemoteRecruitJobSearch
Browse available jobs, search for jobs, and view job details.

---

## Setup Instructions

1. Clone the repository:
   ```
   git clone https://github.com/Sj12091996/RemoteRecruitJobSearch.git
   ```
2. Open `RemoteRecruit.xcodeproj` in Xcode.
3. Select a simulator or device.
4. Hit Run (⌘R). No API key or additional setup needed.

> The app uses the free [Remotive.io](https://remotive.com/api/remote-jobs) public API — no authentication required.

---

## What it does

- Browse available remote jobs
- Search by title or company
- Tap into a job for full details and a link to apply

---

## Architecture


The app follows MVVM (Model-View-ViewModel) with a simple, pragmatic structure:

```
RemoteRecruit/
├── App/
│   └── RemoteRecruitApp.swift        # App entry point
├── Models/
│   └── Job.swift                     # Decodable Job model
├── Services/
│   └── JobService.swift              # API layer + protocol
├── ViewModels/
│   ├── JobDetailViewModel.swift        # Job list state & search logic
│   └── JobListViewModel.swift      # Detail screen data
├── Views/
│   ├── JobListView.swift             # Job list + search UI
│   ├── JobRowView.swift              # Single job row
│   ├── JobDetailView.swift           # Job detail screen
│   └── Components/
│       └── StateViews.swift          # Loading, empty, error states
└── Tests/
    └── RemoteRecruitTests.swift      # Unit tests
```

### Key Decisions

- SwiftUI — modern declarative UI, fits perfectly with ObservableObject/StateObject.
- async/await — clean and readable async code without the overhead of Combine for this use case.
- Protocol-based DI — `JobServiceProtocol` allows easy mocking in tests without any third-party frameworks.
- ViewState enum — single source of truth for UI state (loading, success, empty, error). Keeps views simple.
- Debounced search — uses `Task.sleep` to avoid firing an API request on every keystroke.

---

## Testing

Unit tests cover:
- `JobListViewModel` — loading, search, error, retry, empty state
- `JobDetailViewModel` — data mapping, fallback values

To run tests: `⌘U` in Xcode.

Business logic coverage is **~75%+**, focusing on ViewModel and Service layers.

---

## Notes

- Salary and location can come back empty from the API; the app shows sensible fallbacks.
- Job descriptions come in as HTML — stripped before display using `NSAttributedString`.
- No pagination for now; the API returns a manageable list by default.

## Assumptions

- The Remotive.io API is publicly available and doesn't require authentication.
- Salary and location fields may be empty; the app handles these gracefully with fallback text.
- HTML in job descriptions is stripped before display using `NSAttributedString`.
- Search is handled server-side via the Remotive API's `?search=` query param.
- No pagination implemented — the API returns a reasonable number of results by default.

---

## Requirements

- Xcode 13.2+
- iOS 15.2+
- Swift 5+
