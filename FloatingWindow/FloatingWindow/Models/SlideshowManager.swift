import AppKit
import Combine
import os.log

private let logger = Logger(subsystem: "com.floatingwindow.app", category: "SlideshowManager")

@MainActor
class SlideshowManager: ObservableObject {
    @Published var currentImage: NSImage?
    @Published var folderURL: URL?
    @Published var currentIndex: Int = 0
    @Published var isRotating: Bool = false
    @Published var shuffleEnabled: Bool = false

    private(set) var imageFiles: [URL] = []
    private var timer: Timer?
    private var history: [Int] = [] // indices visited, for "previous" in shuffle mode
    private let maxHistorySize = 100

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
            logger.error("Failed to scan folder: \(error.localizedDescription)")
            imageFiles = []
        }
    }

    /// Maximum pixel dimension before downsampling to save memory.
    private let maxPixelDimension: CGFloat = 4096

    func loadCurrentImage() {
        while !imageFiles.isEmpty {
            let url = imageFiles[currentIndex]
            if let image = loadImage(from: url) {
                currentImage = image
                return
            }
            // Corrupt or unreadable — remove and try next
            imageFiles.remove(at: currentIndex)
            if !imageFiles.isEmpty {
                currentIndex = currentIndex % imageFiles.count
            }
        }
        currentImage = nil
    }

    /// Loads an image from a URL, downsampling very large images to save memory.
    private func loadImage(from url: URL) -> NSImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        // Check dimensions to decide whether to downsample
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            // Fall back to simple loading if we can't read properties
            return NSImage(contentsOf: url)
        }

        let maxDim = max(width, height)
        if maxDim > maxPixelDimension {
            // Downsample large images
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelDimension,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                return NSImage(contentsOf: url)
            }
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }

        return NSImage(contentsOf: url)
    }

    func nextImage() {
        guard !imageFiles.isEmpty else { return }
        history.append(currentIndex)
        if history.count > maxHistorySize {
            history.removeFirst()
        }
        if shuffleEnabled && imageFiles.count > 1 {
            var next: Int
            repeat {
                next = Int.random(in: 0..<imageFiles.count)
            } while next == currentIndex
            currentIndex = next
        } else {
            currentIndex = (currentIndex + 1) % imageFiles.count
        }
        loadCurrentImage()
    }

    func previousImage() {
        guard !imageFiles.isEmpty else { return }
        if shuffleEnabled, let prev = history.popLast() {
            currentIndex = prev
        } else {
            currentIndex = (currentIndex - 1 + imageFiles.count) % imageFiles.count
        }
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
