import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var panelController: FloatingPanelController
    @EnvironmentObject var extensionManager: ExtensionManager

    private let sizePresets: [(String, Double)] = [
        ("25%", 0.25),
        ("33%", 0.33),
        ("50%", 0.50),
        ("66%", 0.66),
        ("75%", 0.75),
        ("100%", 1.0),
    ]

    private let intervalOptions: [(String, TimeInterval)] = [
        ("5 seconds", 5),
        ("10 seconds", 10),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
    ]

    var body: some View {
        // Window visibility
        Button(panelController.isVisible ? "Hide Window" : "Show Window") {
            panelController.togglePanel()
        }
        .keyboardShortcut("f", modifiers: [.command, .shift])

        Divider()

        // Image source section
        Text("Image Source")
            .font(.caption)

        Button("Choose Folder...") {
            chooseFolder()
        }

        if case .folder(let url) = appState.imageSource {
            Text(url.lastPathComponent)
                .font(.caption2)
                .foregroundColor(.secondary)

            if appState.slideshowManager.imageCount > 0 {
                Text("\(appState.slideshowManager.imageCount) images")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }

        Button("Paste from Clipboard") {
            appState.pasteFromClipboard()
        }

        if appState.slideshowManager.imageCount > 1 {
            Divider()

            // Navigation
            Button("Previous") {
                appState.slideshowManager.previousImage()
            }
            Button("Next") {
                appState.slideshowManager.nextImage()
            }

            if let name = appState.slideshowManager.currentFileName {
                Text(name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Slideshow controls
            Text("Slideshow")
                .font(.caption)

            Toggle("Auto-rotate", isOn: $appState.slideshowEnabled)

            if appState.slideshowEnabled {
                Picker("Interval", selection: $appState.rotationInterval) {
                    ForEach(intervalOptions, id: \.1) { label, value in
                        Text(label).tag(value)
                    }
                }
            }
        }

        Divider()

        // Display mode
        Text("Display")
            .font(.caption)

        Picker("Aspect", selection: $appState.aspectMode) {
            Text("Fill").tag(AspectMode.fill)
            Text("Fit").tag(AspectMode.fit)
        }
        .pickerStyle(.inline)

        // Size presets
        if appState.currentImage != nil {
            Menu("Size") {
                ForEach(sizePresets, id: \.1) { label, scale in
                    Button {
                        appState.imageScale = scale
                        panelController.resizeToScale(scale)
                    } label: {
                        HStack {
                            Text(label)
                            if abs(appState.imageScale - scale) < 0.001 {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Button("Custom...") {
                    promptCustomSize()
                }
            }
        }

        if !extensionManager.extensions.isEmpty {
            Divider()

            Text("Extensions")
                .font(.caption)

            ForEach(extensionManager.extensions) { ext in
                Button {
                    extensionManager.toggleExtension(id: ext.id)
                } label: {
                    HStack {
                        Image(systemName: ext.icon)
                        Text(ext.displayName)
                        Spacer()
                        if extensionManager.isExtensionVisible(ext.id) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func promptCustomSize() {
        let alert = NSAlert()
        alert.messageText = "Custom Size"
        alert.informativeText = "Enter a percentage (e.g. 40 for 40%):"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 100, height: 24))
        input.stringValue = "\(Int(appState.imageScale * 100))"
        alert.accessoryView = input
        alert.window.level = .floating

        if alert.runModal() == .alertFirstButtonReturn {
            if let value = Double(input.stringValue), value > 0, value <= 400 {
                let scale = value / 100.0
                appState.imageScale = scale
                panelController.resizeToScale(scale)
            }
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder with images"
        panel.level = .floating

        if panel.runModal() == .OK, let url = panel.url {
            panelController.setAppState(appState)
            if !panelController.isVisible {
                panelController.showPanel()
            }
            appState.selectFolder(url)
            SettingsStore.shared.lastFolderPath = url.path
        }
    }
}
