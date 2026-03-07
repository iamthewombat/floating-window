import SwiftUI

@main
struct FloatingWindowApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var panelController = FloatingPanelController()
    @StateObject private var extensionManager = ExtensionManager()

    var body: some Scene {
        MenuBarExtra("FloatingWindow", systemImage: "photo.on.rectangle") {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(panelController)
                .environmentObject(extensionManager)
                .onAppear {
                    setupExtensions()
                }
        }
    }

    private func setupExtensions() {
        guard extensionManager.extensions.isEmpty else { return }
        extensionManager.setPanelController(panelController)
        extensionManager.register(PomodoroExtension())
        extensionManager.register(TaskListExtension())
    }
}
