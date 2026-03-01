# Floating Window App - Implementation Plan

## Context
Build a native macOS menu-bar app using Swift/SwiftUI that displays images in an always-on-top floating window with slideshow capability and an extensible widget system.

## Architecture
- **Menu-bar-only app** (`LSUIElement = YES`, no dock icon)
- **NSPanel subclass** for floating windows (always-on-top, minimal chrome, `hidesOnDeactivate = false`)
- **SwiftUI MenuBarExtra** for controls/settings
- **Protocol-based extension system** for add-on widgets (Pomodoro, Task List)

## Project Structure
```
FloatingWindow/
├── FloatingWindowApp.swift           -- @main, MenuBarExtra scene
├── Info.plist                        -- LSUIElement = YES
├── Models/
│   ├── AppState.swift                -- Observable shared state
│   ├── SlideshowManager.swift        -- Folder scan, timer rotation
│   └── SettingsStore.swift           -- UserDefaults persistence
├── Windows/
│   ├── FloatingPanel.swift           -- NSPanel subclass (always-on-top)
│   ├── FloatingPanelController.swift -- Panel lifecycle management
│   └── ImageContentView.swift        -- SwiftUI image display
├── MenuBar/
│   └── MenuBarView.swift             -- Menu bar dropdown UI
├── Extensions/
│   ├── ExtensionProtocol.swift       -- Widget protocol
│   ├── ExtensionManager.swift        -- Registry & panel lifecycle
│   ├── Pomodoro/
│   │   ├── PomodoroExtension.swift
│   │   ├── PomodoroView.swift
│   │   └── PomodoroState.swift
│   └── TaskList/
│       ├── TaskListExtension.swift
│       ├── TaskListView.swift
│       └── TaskItem.swift
└── Assets.xcassets
```

## Implementation Phases

### Phase 1: Project Skeleton & Floating Window
- [x] Create Xcode project structure
- [x] `FloatingPanel.swift` - NSPanel with `.titled, .resizable, .fullSizeContentView`, transparent titlebar, hidden buttons, `level = .floating`, `hidesOnDeactivate = false`
- [x] `FloatingPanelController.swift` - create/show/hide the panel
- [x] `ImageContentView.swift` - placeholder view
- [x] `FloatingWindowApp.swift` - MenuBarExtra with Show/Hide + Quit
- [x] **Verify**: App appears in menu bar only, floating window stays on top

### Phase 2: Image Display & Folder Selection
- [x] `AppState.swift` - shared observable state (currentImage, source, settings)
- [x] `SettingsStore.swift` - persist folder path, interval, aspect mode
- [x] Folder picker via NSOpenPanel from menu bar
- [x] `SlideshowManager.swift` - scan folder for image files, load first image
- [x] Wire image into `ImageContentView` with aspect fill/fit
- [ ] **Verify**: Pick folder, see image in floating window

### Phase 3: Slideshow & Clipboard
- [x] Timer-based rotation in SlideshowManager
- [x] Interval picker in menu bar (5s, 10s, 30s, 1m, 5m)
- [x] Previous/Next controls
- [x] Toggle auto-rotate on/off
- [x] Clipboard paste support (NSPasteboard → NSImage)
- [ ] **Verify**: Slideshow rotates, paste works, interval is adjustable

### Phase 4: Extension System
- [x] `ExtensionProtocol` - id, displayName, icon, isEnabled, makeView(), preferredSize
- [x] `ExtensionManager` - registry, panel creation/destruction
- [x] Extension toggle section in menu bar (dynamic from registry)
- [x] **Verify**: Can toggle extension panels on/off

### Phase 5: Pomodoro Timer Extension
- [x] `PomodoroState` - work/break timer, rounds, configurable durations (25/5 min defaults)
- [x] `PomodoroView` - timer display, progress bar, start/pause/skip/reset, settings panel
- [x] Register in ExtensionManager
- [x] Extension panels dock beneath main image window and follow it on move/resize
- [x] **Verify**: Pomodoro floats beneath image window

### Phase 6: Task List Extension
- [ ] `TaskItem` model (Codable, persisted to UserDefaults)
- [ ] `TaskListView` - add, check off, delete tasks
- [ ] Register in ExtensionManager
- [ ] **Verify**: Task list works, persists across restarts

### Phase 7: Polish
- [ ] Window frame persistence (save/restore position & size)
- [ ] Smooth image transitions (fade animation)
- [ ] Handle edge cases (empty folder, corrupt images, large images)
- [ ] App icon and menu bar icon

## Key Technical Decisions
- **Window style**: `.titled` + `titlebarAppearsTransparent` + hidden buttons (gives native resize handles while looking borderless)
- **`hidesOnDeactivate = false`**: Critical for staying visible when other apps are active
- **`.nonactivatingPanel`**: Prevents stealing focus from active app
- **Lazy image loading**: Only load current image, hold URLs in memory
- **No sandbox initially**: Simplifies folder access for direct distribution

## Verification
1. Build and run the Xcode project
2. Confirm menu bar icon appears, no dock icon
3. Show floating window → stays above all other apps
4. Select folder → images display, slideshow rotates
5. Paste image → displays in window
6. Resize window → image scales properly
7. Toggle extensions → Pomodoro and Task List float correctly
