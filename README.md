# FloatingWindow

A native macOS menu bar app that displays images in an always-on-top floating window with slideshow capability, a Pomodoro timer, and an extensible widget system.

## Features

### Image Display
- **Always-on-top floating window** that stays above all other apps
- **Folder-based browsing** — point to a folder and browse images
- **Arrow key navigation** — left/right arrows to cycle through images
- **Clipboard paste** — paste any image directly into the window
- **Aspect fill/fit** — toggle between fill and fit display modes
- **Size presets** — 25%, 33%, 50%, 66%, 75%, 100%, or custom percentage
- **Auto-resize** — window adjusts to match image aspect ratio

### Slideshow
- **Auto-rotate** through images in a folder (off by default)
- **Configurable interval** — 5s, 10s, 30s, 1 min, 5 min
- **Fixed window size** during rotation so the window doesn't jump around

### Extensions
- **Pomodoro Timer** — docks beneath the image window
  - 25 min focus / 5 min break (configurable)
  - Start, pause, skip, and reset controls
  - Sound notification when a timer completes
  - Tracks completed rounds
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
cd FloatingWindow
xcodebuild -project FloatingWindow.xcodeproj -scheme FloatingWindow -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/FloatingWindow-*/Build/Products/Debug/FloatingWindow.app
```

Or open `FloatingWindow/FloatingWindow.xcodeproj` in Xcode and press Cmd+R.

## Run Tests

```bash
cd FloatingWindow
xcodebuild test -project FloatingWindow.xcodeproj -scheme FloatingWindow -destination 'platform=macOS'
```

## Project Structure

```
FloatingWindow/
├── FloatingWindowApp.swift           — App entry point, MenuBarExtra
├── Models/
│   ├── AppState.swift                — Shared observable state
│   ├── SlideshowManager.swift        — Folder scanning, image rotation
│   └── SettingsStore.swift           — UserDefaults persistence
├── Windows/
│   ├── FloatingPanel.swift           — NSPanel subclass (always-on-top)
│   ├── FloatingPanelController.swift — Panel lifecycle, resizing
│   └── ImageContentView.swift        — SwiftUI image display
├── MenuBar/
│   └── MenuBarView.swift             — Menu bar dropdown UI
├── Extensions/
│   ├── ExtensionProtocol.swift       — Widget protocol
│   ├── ExtensionManager.swift        — Registry and panel management
│   └── Pomodoro/
│       ├── PomodoroExtension.swift   — Extension registration
│       ├── PomodoroState.swift       — Timer logic
│       └── PomodoroView.swift        — Timer UI
└── FloatingWindowTests/
    ├── SlideshowManagerTests.swift
    ├── AppStateTests.swift
    └── SettingsStoreTests.swift
```

## Adding Extensions

Create a class conforming to `FloatingExtension`:

```swift
class MyExtension: FloatingExtension {
    let id = "my-extension"
    let displayName = "My Extension"
    let icon = "star"              // SF Symbol name
    @Published var isEnabled = false
    let preferredSize = CGSize(width: 300, height: 100)

    func makeView() -> some View {
        Text("Hello from my extension")
    }
}
```

Register it in `FloatingWindowApp.swift`:

```swift
extensionManager.register(MyExtension())
```

The extension will appear as a toggle in the menu bar and float beneath the image window when enabled.
