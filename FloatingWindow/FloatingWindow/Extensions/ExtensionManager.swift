import AppKit
import Combine
import SwiftUI

/// Type-erased wrapper so we can store heterogeneous extensions in an array
struct AnyFloatingExtension: Identifiable {
    let id: String
    let displayName: String
    let icon: String
    let preferredSize: CGSize
    private let _isEnabled: () -> Bool
    private let _setEnabled: (Bool) -> Void
    private let _makeHostingView: @MainActor () -> NSView

    var isEnabled: Bool {
        get { _isEnabled() }
        nonmutating set { _setEnabled(newValue) }
    }

    @MainActor
    init<E: FloatingExtension>(_ ext: E) {
        self.id = ext.id
        self.displayName = ext.displayName
        self.icon = ext.icon
        self.preferredSize = ext.preferredSize
        self._isEnabled = { ext.isEnabled }
        self._setEnabled = { ext.isEnabled = $0 }
        self._makeHostingView = {
            NSHostingView(rootView: ext.makeView().environmentObject(ext))
        }
    }

    @MainActor
    func makeHostingView() -> NSView {
        _makeHostingView()
    }
}

@MainActor
class ExtensionManager: ObservableObject {
    @Published var extensions: [AnyFloatingExtension] = []
    @Published var enabledExtensionIDs: Set<String> = []

    private var panels: [String: FloatingPanel] = [:]
    weak var panelController: FloatingPanelController?
    private var mainPanelObserver: AnyCancellable?

    init() {
        if let saved = UserDefaults.standard.array(forKey: "enabledExtensions") as? [String] {
            enabledExtensionIDs = Set(saved)
        }
    }

    func setPanelController(_ controller: FloatingPanelController) {
        self.panelController = controller
    }

    func register<E: FloatingExtension>(_ ext: E) {
        let wrapped = AnyFloatingExtension(ext)
        extensions.append(wrapped)
        if enabledExtensionIDs.contains(ext.id) {
            showExtension(id: ext.id)
        }
    }

    func toggleExtension(id: String) {
        if enabledExtensionIDs.contains(id) {
            hideExtension(id: id)
        } else {
            showExtension(id: id)
        }
    }

    func showExtension(id: String) {
        guard let ext = extensions.first(where: { $0.id == id }) else { return }

        enabledExtensionIDs.insert(id)
        persistEnabledState()

        if panels[id] != nil {
            panels[id]?.makeKeyAndOrderFront(nil)
            repositionAllExtensions()
            return
        }

        let size = ext.preferredSize
        let panel = FloatingPanel(contentRect: NSRect(x: 100, y: 100, width: size.width, height: size.height))
        panel.contentView = ext.makeHostingView()
        panel.title = ext.displayName

        panel.makeKeyAndOrderFront(nil)
        panels[id] = panel

        repositionAllExtensions()
        observeMainPanelChanges()
    }

    func hideExtension(id: String) {
        enabledExtensionIDs.remove(id)
        persistEnabledState()

        if let panel = panels[id] {
            panel.orderOut(nil)
        }
        panels.removeValue(forKey: id)
    }

    func isExtensionVisible(_ id: String) -> Bool {
        enabledExtensionIDs.contains(id)
    }

    /// Reposition all visible extension panels beneath the main image window
    func repositionAllExtensions() {
        guard let mainPanel = panelController?.currentPanel else { return }
        let mainFrame = mainPanel.frame

        // Stack extensions below the main window, matching its width
        var yOffset: CGFloat = mainFrame.origin.y
        let enabledExts = extensions.filter { enabledExtensionIDs.contains($0.id) }

        for ext in enabledExts {
            guard let panel = panels[ext.id] else { continue }
            let height = ext.preferredSize.height
            let minWidth = ext.preferredSize.width
            let panelWidth = max(mainFrame.width, minWidth)
            // Center the extension under the main window if it's wider
            let panelX = mainFrame.midX - panelWidth / 2
            yOffset -= height

            let newFrame = NSRect(
                x: panelX,
                y: yOffset,
                width: panelWidth,
                height: height
            )
            panel.setFrame(newFrame, display: true, animate: false)
        }
    }

    private func observeMainPanelChanges() {
        guard mainPanelObserver == nil else { return }

        // Observe main panel frame changes via polling notification
        mainPanelObserver = NotificationCenter.default.publisher(for: NSWindow.didMoveNotification)
            .merge(with: NotificationCenter.default.publisher(for: NSWindow.didResizeNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self else { return }
                if let window = notification.object as? NSWindow,
                   window === self.panelController?.currentPanel {
                    self.repositionAllExtensions()
                }
            }
    }

    private func persistEnabledState() {
        UserDefaults.standard.set(Array(enabledExtensionIDs), forKey: "enabledExtensions")
    }
}
