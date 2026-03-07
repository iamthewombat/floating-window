import Foundation

class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    var lastFolderPath: String? {
        get { defaults.string(forKey: "lastFolderPath") }
        set { defaults.set(newValue, forKey: "lastFolderPath") }
    }

    /// Store a security-scoped bookmark for sandbox-safe folder access across launches.
    var lastFolderBookmark: Data? {
        get { defaults.data(forKey: "lastFolderBookmark") }
        set { defaults.set(newValue, forKey: "lastFolderBookmark") }
    }

    /// Create and store a security-scoped bookmark for the given URL.
    func saveBookmark(for url: URL) {
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            lastFolderBookmark = bookmark
            lastFolderPath = url.path
        } catch {
            lastFolderPath = url.path
        }
    }

    /// Resolve the stored security-scoped bookmark to a URL. Caller must call stopAccessingSecurityScopedResource().
    func resolveBookmark() -> URL? {
        guard let bookmark = lastFolderBookmark else { return nil }
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                saveBookmark(for: url)
            }
            return url
        } catch {
            return nil
        }
    }

    var rotationInterval: TimeInterval {
        get {
            let val = defaults.double(forKey: "rotationInterval")
            return val > 0 ? val : 60
        }
        set { defaults.set(newValue, forKey: "rotationInterval") }
    }

    var aspectMode: String {
        get { defaults.string(forKey: "aspectMode") ?? "fill" }
        set { defaults.set(newValue, forKey: "aspectMode") }
    }

    var slideshowEnabled: Bool {
        get {
            if defaults.object(forKey: "slideshowEnabled") == nil { return false }
            return defaults.bool(forKey: "slideshowEnabled")
        }
        set { defaults.set(newValue, forKey: "slideshowEnabled") }
    }

    var shuffleEnabled: Bool {
        get { defaults.bool(forKey: "shuffleEnabled") }
        set { defaults.set(newValue, forKey: "shuffleEnabled") }
    }
}
