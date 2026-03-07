import AppKit
import Combine
import SwiftUI

@MainActor
class FloatingPanelController: ObservableObject {
    @Published var isVisible: Bool = false

    private(set) var panel: FloatingPanel?
    private var appState: AppState?

    var currentPanel: FloatingPanel? { panel }
    private var imageCancellable: AnyCancellable?
    private var frameObservers: [NSObjectProtocol] = []

    func setAppState(_ appState: AppState) {
        self.appState = appState
        observeImageChanges()
    }

    func togglePanel() {
        if isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        if panel == nil {
            let defaultRect = NSRect(x: 200, y: 200, width: 400, height: 400)
            let p = FloatingPanel(contentRect: defaultRect)

            let contentView: ImageContentView
            if let appState {
                contentView = ImageContentView(appState: appState)
            } else {
                contentView = ImageContentView(appState: AppState())
            }
            let hostingView = NSHostingView(rootView: contentView)
            p.contentView = hostingView

            // Restore saved frame if available
            if let frameString = UserDefaults.standard.string(forKey: "floatingPanelFrame") {
                let savedFrame = NSRectFromString(frameString)
                if savedFrame.width > 0 && savedFrame.height > 0 {
                    p.setFrame(savedFrame, display: false)
                }
            }

            // Wire up arrow key navigation
            p.onLeftArrow = { [weak self] in
                self?.appState?.slideshowManager.previousImage()
            }
            p.onRightArrow = { [weak self] in
                self?.appState?.slideshowManager.nextImage()
            }

            panel = p
            observeFrameChanges(p)
        }

        panel?.makeKeyAndOrderFront(nil)
        isVisible = true
    }

    func hidePanel() {
        if let frame = panel?.frame {
            UserDefaults.standard.set(NSStringFromRect(frame), forKey: "floatingPanelFrame")
        }
        panel?.orderOut(nil)
        isVisible = false
    }

    /// Resize the panel to a specific scale of the current image's native size
    func resizeToScale(_ scale: Double) {
        guard let panel, let image = appState?.currentImage else { return }
        let imageSize = image.size
        guard imageSize.width > 0 && imageSize.height > 0 else { return }

        let newWidth = imageSize.width * scale
        let newHeight = imageSize.height * scale

        let oldFrame = panel.frame
        let newX = oldFrame.midX - newWidth / 2
        let newY = oldFrame.midY - newHeight / 2

        let newFrame = NSRect(x: newX, y: newY, width: newWidth, height: newHeight)
        panel.setFrame(newFrame, display: true, animate: true)
    }

    private func observeImageChanges() {
        imageCancellable = appState?.$currentImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                guard let self, let image, let panel = self.panel, self.isVisible else { return }
                // When auto-rotate is on, keep the window at its current size
                // so images don't cause the window to jump around
                if self.appState?.slideshowEnabled == true { return }
                let scale = self.appState?.imageScale ?? 0.5
                self.resizePanelToFit(panel, image: image, scale: scale)
            }
    }

    private func observeFrameChanges(_ panel: FloatingPanel) {
        frameObservers.forEach { NotificationCenter.default.removeObserver($0) }
        frameObservers.removeAll()

        let saveFrame = { [weak panel] (_: Notification) in
            guard let frame = panel?.frame else { return }
            UserDefaults.standard.set(NSStringFromRect(frame), forKey: "floatingPanelFrame")
        }

        frameObservers.append(
            NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: panel, queue: .main, using: saveFrame)
        )
        frameObservers.append(
            NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: panel, queue: .main, using: saveFrame)
        )
    }

    private func resizePanelToFit(_ panel: FloatingPanel, image: NSImage, scale: Double) {
        let imageSize = image.size
        guard imageSize.width > 0 && imageSize.height > 0 else { return }

        let newWidth = imageSize.width * scale
        let newHeight = imageSize.height * scale

        let oldFrame = panel.frame
        let centerX = oldFrame.midX
        let centerY = oldFrame.midY

        let newX = centerX - newWidth / 2
        let newY = centerY - newHeight / 2

        let newFrame = NSRect(x: newX, y: newY, width: newWidth, height: newHeight)
        panel.setFrame(newFrame, display: true, animate: true)
    }
}
