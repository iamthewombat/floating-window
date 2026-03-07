import XCTest
@testable import FloatingWindow

@MainActor
final class AppStateTests: XCTestCase {
    var appState: AppState!
    var tempDir: URL!

    override func setUp() async throws {
        // Clear settings to avoid cross-test pollution
        UserDefaults.standard.removeObject(forKey: "rotationInterval")
        UserDefaults.standard.removeObject(forKey: "slideshowEnabled")
        UserDefaults.standard.removeObject(forKey: "aspectMode")
        UserDefaults.standard.removeObject(forKey: "lastFolderBookmark")
        UserDefaults.standard.removeObject(forKey: "lastFolderPath")
        UserDefaults.standard.removeObject(forKey: "shuffleEnabled")

        appState = AppState()

        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Create test images
        for name in ["img1.png", "img2.png", "img3.png"] {
            let image = NSImage(size: NSSize(width: 100, height: 100))
            image.lockFocus()
            NSColor.green.drawSwatch(in: NSRect(x: 0, y: 0, width: 100, height: 100))
            image.unlockFocus()
            if let tiff = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let data = bitmap.representation(using: .png, properties: [:]) {
                try data.write(to: tempDir.appendingPathComponent(name))
            }
        }
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        UserDefaults.standard.removeObject(forKey: "rotationInterval")
        UserDefaults.standard.removeObject(forKey: "slideshowEnabled")
        UserDefaults.standard.removeObject(forKey: "aspectMode")
        UserDefaults.standard.removeObject(forKey: "lastFolderBookmark")
        UserDefaults.standard.removeObject(forKey: "lastFolderPath")
        UserDefaults.standard.removeObject(forKey: "shuffleEnabled")
    }

    func testInitialState() {
        XCTAssertNil(appState.currentImage)
        XCTAssertEqual(appState.imageSource, .none)
        XCTAssertEqual(appState.aspectMode, .fill)
        XCTAssertFalse(appState.slideshowEnabled)
    }

    func testSelectFolderUpdatesSource() {
        appState.selectFolder(tempDir)
        XCTAssertEqual(appState.imageSource, .folder(tempDir))
    }

    func testSelectFolderLoadsImage() {
        appState.selectFolder(tempDir)

        // Wait briefly for Combine pipeline
        let expectation = expectation(description: "image loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(self.appState.currentImage)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    func testSelectFolderStartsRotation() {
        appState.slideshowEnabled = true
        appState.selectFolder(tempDir)
        XCTAssertTrue(appState.slideshowManager.isRotating)
    }

    func testDisableSlideshowStopsRotation() {
        appState.slideshowEnabled = true
        appState.selectFolder(tempDir)
        XCTAssertTrue(appState.slideshowManager.isRotating)

        appState.slideshowEnabled = false
        XCTAssertFalse(appState.slideshowManager.isRotating)
    }

    func testRotationIntervalPersists() {
        appState.rotationInterval = 30
        XCTAssertEqual(SettingsStore.shared.rotationInterval, 30)
    }

    func testAspectModeDefault() {
        XCTAssertEqual(appState.aspectMode, .fill)
    }

    func testImageSourceNoneByDefault() {
        XCTAssertEqual(appState.imageSource, .none)
    }
}
