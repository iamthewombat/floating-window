import Foundation

class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    var lastFolderPath: String? {
        get { defaults.string(forKey: "lastFolderPath") }
        set { defaults.set(newValue, forKey: "lastFolderPath") }
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
}
