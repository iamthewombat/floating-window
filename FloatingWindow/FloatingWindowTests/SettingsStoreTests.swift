import XCTest
@testable import FloatingWindow

final class SettingsStoreTests: XCTestCase {
    var store: SettingsStore!

    override func setUp() {
        store = SettingsStore.shared
        // Clean up test keys
        UserDefaults.standard.removeObject(forKey: "rotationInterval")
        UserDefaults.standard.removeObject(forKey: "aspectMode")
        UserDefaults.standard.removeObject(forKey: "slideshowEnabled")
        UserDefaults.standard.removeObject(forKey: "lastFolderPath")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "rotationInterval")
        UserDefaults.standard.removeObject(forKey: "aspectMode")
        UserDefaults.standard.removeObject(forKey: "slideshowEnabled")
        UserDefaults.standard.removeObject(forKey: "lastFolderPath")
    }

    func testDefaultRotationInterval() {
        XCTAssertEqual(store.rotationInterval, 60)
    }

    func testSetAndGetRotationInterval() {
        store.rotationInterval = 30
        XCTAssertEqual(store.rotationInterval, 30)
    }

    func testDefaultAspectMode() {
        XCTAssertEqual(store.aspectMode, "fill")
    }

    func testSetAndGetAspectMode() {
        store.aspectMode = "fit"
        XCTAssertEqual(store.aspectMode, "fit")
    }

    func testDefaultSlideshowEnabled() {
        XCTAssertFalse(store.slideshowEnabled)
    }

    func testSetAndGetSlideshowEnabled() {
        store.slideshowEnabled = false
        XCTAssertFalse(store.slideshowEnabled)
    }

    func testLastFolderPathDefaultNil() {
        XCTAssertNil(store.lastFolderPath)
    }

    func testSetAndGetLastFolderPath() {
        store.lastFolderPath = "/Users/test/Pictures"
        XCTAssertEqual(store.lastFolderPath, "/Users/test/Pictures")
    }
}
