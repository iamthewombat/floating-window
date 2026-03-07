import AppKit
import Combine

enum ImageSource: Equatable {
    case none
    case folder(URL)
    case clipboard
    case singleImage(URL)
}

enum AspectMode: String, CaseIterable {
    case fill = "fill"
    case fit = "fit"
}

@MainActor
class AppState: ObservableObject {
    @Published var currentImage: NSImage?
    @Published var imageSource: ImageSource = .none
    @Published var aspectMode: AspectMode = .fill
    @Published var imageScale: Double = 0.5 // 0 means auto, otherwise percentage as decimal

    @Published var slideshowEnabled: Bool = false {
        didSet { updateRotation() }
    }

    @Published var rotationInterval: TimeInterval = 60 {
        didSet {
            SettingsStore.shared.rotationInterval = rotationInterval
            updateRotation()
        }
    }

    @Published var shuffleEnabled: Bool = false {
        didSet {
            SettingsStore.shared.shuffleEnabled = shuffleEnabled
            slideshowManager.shuffleEnabled = shuffleEnabled
        }
    }

    let slideshowManager = SlideshowManager()

    private var cancellables = Set<AnyCancellable>()
    private var securityScopedURL: URL?

    init() {
        // Restore saved settings
        let store = SettingsStore.shared
        rotationInterval = store.rotationInterval
        shuffleEnabled = store.shuffleEnabled
        slideshowEnabled = store.slideshowEnabled
        if let modeStr = AspectMode(rawValue: store.aspectMode) {
            aspectMode = modeStr
        }

        // When slideshow manager produces a new image, update currentImage
        slideshowManager.$currentImage
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentImage)

        // Restore last folder from security-scoped bookmark
        if let url = store.resolveBookmark() {
            if url.startAccessingSecurityScopedResource() {
                securityScopedURL = url
                selectFolder(url)
            }
        }
    }

    func selectFolder(_ url: URL) {
        // Release previous security-scoped access
        if let prev = securityScopedURL, prev != url {
            prev.stopAccessingSecurityScopedResource()
            securityScopedURL = nil
        }
        imageSource = .folder(url)
        slideshowManager.setFolder(url)
        updateRotation()
    }

    func pasteFromClipboard() {
        guard let image = NSImage(pasteboard: .general) else { return }
        slideshowManager.stop()
        imageSource = .clipboard
        currentImage = image
    }

    private func updateRotation() {
        if slideshowEnabled, case .folder = imageSource {
            slideshowManager.startRotation(interval: rotationInterval)
        } else {
            slideshowManager.stopRotation()
        }
        SettingsStore.shared.slideshowEnabled = slideshowEnabled
    }
}
