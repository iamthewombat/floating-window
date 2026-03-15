# FloatingWindow

A native macOS menu bar app that displays images in an always-on-top floating window with slideshow capability, an extensible widget system, and built-in productivity tools.

## Features

### Image Display
- **Always-on-top floating window** that stays above all other apps
- **Folder-based browsing** — select a folder and browse images
- **Arrow key navigation** — left/right arrows to cycle through images
- **Clipboard paste** — paste any image directly into the window
- **Aspect fill/fit** — toggle between fill and fit display modes
- **Size presets** — 25%, 33%, 50%, 66%, 75%, 100%, or custom percentage
- **Auto-resize** — window adjusts to match image aspect ratio
- **Smooth transitions** — 0.3s fade between images

### Slideshow
- **Auto-rotate** through images in a folder (off by default)
- **Shuffle mode** — randomise order with history-based back navigation
- **Configurable interval** — 5s, 10s, 30s, 1 min, 5 min
- **Fixed window size** during rotation so the window doesn't jump around

### Extensions
- **Pomodoro Timer** — 25 min focus / 5 min break (configurable), sound notifications, round tracking
- **Task List** — add, check off, delete tasks with persistence across restarts
- **Claude Usage** — embedded WebView showing your claude.ai usage stats
- **Plugin architecture** — add new extensions by conforming to `FloatingExtension` protocol

### Menu Bar
- Lives entirely in the menu bar (no dock icon)
- All controls accessible from the dropdown menu
- Settings persist across restarts

## Requirements

- macOS 15.0+
- Xcode 16.0+

## Build & Run

```bash
# Build release and install to /Applications
./build.sh

# Or build manually
cd FloatingWindow
xcodebuild -scheme FloatingWindow -configuration Debug build
```

Or open `FloatingWindow/FloatingWindow.xcodeproj` in Xcode and press Cmd+R.

## Run Tests

```bash
cd FloatingWindow
xcodebuild test -scheme FloatingWindow -destination 'platform=macOS'
```

78 tests across 5 suites: SlideshowManager, SettingsStore, AppState, PomodoroState, TaskListState.

---

## Architecture

### Overview

FloatingWindow is a menu-bar-only macOS app (`LSUIElement = YES`) built with SwiftUI and AppKit. It uses `NSPanel` subclasses for always-on-top floating windows and a protocol-based extension system for dockable widgets.

```
┌─────────────────────────────────────────────────────┐
│                    MenuBarExtra                     │
│                  (SwiftUI Scene)                    │
│                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  AppState   │  │ PanelController│ │ Extension  │ │
│  │ (Observable)│  │  (Lifecycle)  │  │  Manager   │ │
│  └──────┬──────┘  └──────┬───────┘  └─────┬──────┘ │
│         │                │                │         │
│         ▼                ▼                ▼         │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  Slideshow  │  │ FloatingPanel│  │ Extension  │ │
│  │  Manager    │  │  (NSPanel)   │  │  Panels    │ │
│  └─────────────┘  └──────────────┘  └────────────┘ │
└─────────────────────────────────────────────────────┘
```

### Key Design Decisions

**NSPanel over NSWindow** — `NSPanel` with `.nonactivatingPanel` style prevents the floating window from stealing focus from the user's active app. Combined with `hidesOnDeactivate = false` and `level = .floating`, the window stays visible above everything without interfering with normal workflow.

**Borderless with native resize** — Uses `.titled` + `titlebarAppearsTransparent` + hidden standard buttons. This gives native resize handles and drag behaviour while appearing borderless.

**Menu-bar-only app** — `LSUIElement = YES` in Info.plist hides the dock icon. All controls live in a `MenuBarExtra` SwiftUI scene.

**Protocol-based extensions** — The `FloatingExtension` protocol defines the interface for widgets. A type-erased `AnyFloatingExtension` wrapper allows heterogeneous storage in the `ExtensionManager` registry. Extension panels dock beneath the main image window and reposition on move.

**App Sandbox** — Enabled with minimal entitlements: outbound network (for WebView), user-selected read-only files. Folder access persists across launches via security-scoped bookmarks.

### Project Structure

```
FloatingWindow/
├── FloatingWindow.entitlements          — App Sandbox entitlements
├── FloatingWindowApp.swift              — @main, MenuBarExtra scene, extension registration
│
├── Models/
│   ├── AppState.swift                   — Central observable state (image, source, settings)
│   ├── SlideshowManager.swift           — Folder scanning, image loading, timer rotation
│   └── SettingsStore.swift              — UserDefaults persistence + security-scoped bookmarks
│
├── Windows/
│   ├── FloatingPanel.swift              — NSPanel subclass (always-on-top, keyboard nav)
│   ├── FloatingPanelController.swift    — Panel lifecycle, resize, frame persistence
│   └── ImageContentView.swift           — SwiftUI image display with fade transitions
│
├── MenuBar/
│   └── MenuBarView.swift                — Full menu bar UI (controls, settings, extensions)
│
├── Extensions/
│   ├── ExtensionProtocol.swift          — FloatingExtension protocol definition
│   ├── ExtensionManager.swift           — Registry, panel creation, docking logic
│   ├── Pomodoro/
│   │   ├── PomodoroExtension.swift      — Extension registration (id, icon, size)
│   │   ├── PomodoroState.swift          — Work/break timer, phases, configurable durations
│   │   └── PomodoroView.swift           — Timer display, progress bar, controls
│   ├── TaskList/
│   │   ├── TaskItem.swift               — TaskItem model + TaskListState (Codable, persisted)
│   │   ├── TaskListView.swift           — Add, check off, delete, clear completed
│   │   └── TaskListExtension.swift      — Extension registration
│   └── ClaudeUsage/
│       ├── ClaudeUsageView.swift        — WKWebView with domain-restricted navigation
│       └── ClaudeUsageExtension.swift   — Extension registration
│
├── Assets.xcassets/
│   └── AppIcon.appiconset/             — App icon (all macOS sizes)
│
└── FloatingWindowTests/
    ├── SlideshowManagerTests.swift       — 13 tests
    ├── SettingsStoreTests.swift          — 8 tests
    ├── AppStateTests.swift              — 8 tests
    ├── PomodoroStateTests.swift         — 21 tests
    └── TaskListStateTests.swift         — 17 tests
```

### Data Flow

```
User action (menu bar / keyboard)
        │
        ▼
    AppState (@Published properties)
        │
        ├──► SlideshowManager ──► loads image ──► AppState.currentImage
        │
        ▼
    Combine pipeline ($currentImage)
        │
        ├──► ImageContentView (SwiftUI, observes AppState)
        └──► FloatingPanelController (resize logic)
```

**AppState** is the single source of truth. It owns the `SlideshowManager` and publishes `currentImage` via Combine. `ImageContentView` observes it directly. `FloatingPanelController` subscribes to image changes to handle auto-resize (disabled during slideshow rotation).

### Extension System

Extensions conform to `FloatingExtension`:

```swift
protocol FloatingExtension: ObservableObject, Identifiable {
    var id: String { get }
    var displayName: String { get }
    var icon: String { get }                    // SF Symbol
    var isEnabled: Bool { get set }
    var preferredSize: CGSize { get }
    associatedtype ContentView: View
    @MainActor func makeView() -> ContentView
}
```

**Registration** — Extensions are registered in `FloatingWindowApp.setupExtensions()`. Each is wrapped in `AnyFloatingExtension` (type erasure) for storage in the manager's array.

**Panel lifecycle** — When toggled on, `ExtensionManager` creates a `FloatingPanel` for the extension, sets its content to `makeView()`, and positions it beneath the main window. Enabled state persists to UserDefaults.

**Docking** — Extension panels reposition when the main window moves or resizes (via `NSWindow.didMoveNotification` / `didResizeNotification`). Each panel maintains its own width and centers beneath the main window.

### Security

- **App Sandbox** enabled with outbound network + user-selected file read access
- **Security-scoped bookmarks** for persistent folder access across launches
- **WebView domain allowlist** — only `claude.ai` and `anthropic.com` load in the embedded browser; all other URLs open in the system browser
- **No hardcoded secrets**, no shell execution, no user-controlled JS injection
- **Image extension allowlisting** — only known image formats are loaded
- **Large image downsampling** — images over 4096px are downsampled via `CGImageSource` to prevent memory issues

### Adding an Extension

1. Create a directory under `Extensions/`
2. Implement the `FloatingExtension` protocol:

```swift
@MainActor
class MyExtension: FloatingExtension {
    let id = "my-extension"
    let displayName = "My Extension"
    let icon = "star"
    @Published var isEnabled = false
    let preferredSize = CGSize(width: 300, height: 100)

    func makeView() -> some View {
        Text("Hello from my extension")
    }
}
```

3. Register in `FloatingWindowApp.swift`:

```swift
extensionManager.register(MyExtension())
```

4. Add the source files to the Xcode project (`project.pbxproj`)

The extension automatically appears as a toggle in the menu bar and floats beneath the image window when enabled.
