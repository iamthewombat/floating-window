import AppKit
import Combine

@MainActor
class SlideshowManager: ObservableObject {
    @Published var currentImage: NSImage?
    @Published var folderURL: URL?
    @Published var currentIndex: Int = 0
    @Published var isRotating: Bool = false

    private(set) var imageFiles: [URL] = []
    private var timer: Timer?

    private let supportedExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "heic", "heif", "webp", "tiff", "tif", "bmp"
    ]

    func setFolder(_ url: URL) {
        folderURL = url
        scanFolder()
        if !imageFiles.isEmpty {
            currentIndex = 0
            loadCurrentImage()
        }
    }

    func scanFolder() {
        guard let folderURL else {
            imageFiles = []
            return
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.contentTypeKey],
                options: [.skipsHiddenFiles]
            )

            imageFiles = contents
                .filter { url in
                    supportedExtensions.contains(url.pathExtension.lowercased())
                }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        } catch {
            imageFiles = []
        }
    }

    func loadCurrentImage() {
        guard !imageFiles.isEmpty else {
            currentImage = nil
            return
        }
        let url = imageFiles[currentIndex]
        currentImage = NSImage(contentsOf: url)
    }

    func nextImage() {
        guard !imageFiles.isEmpty else { return }
        currentIndex = (currentIndex + 1) % imageFiles.count
        loadCurrentImage()
    }

    func previousImage() {
        guard !imageFiles.isEmpty else { return }
        currentIndex = (currentIndex - 1 + imageFiles.count) % imageFiles.count
        loadCurrentImage()
    }

    func startRotation(interval: TimeInterval) {
        stopRotation()
        guard imageFiles.count > 1 else { return }
        isRotating = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.nextImage()
            }
        }
    }

    func stopRotation() {
        timer?.invalidate()
        timer = nil
        isRotating = false
    }

    func stop() {
        stopRotation()
    }

    var imageCount: Int { imageFiles.count }

    var currentFileName: String? {
        guard !imageFiles.isEmpty else { return nil }
        return imageFiles[currentIndex].lastPathComponent
    }
}
