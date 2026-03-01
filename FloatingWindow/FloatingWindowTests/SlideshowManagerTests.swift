import XCTest
@testable import FloatingWindow

@MainActor
final class SlideshowManagerTests: XCTestCase {
    var manager: SlideshowManager!
    var tempDir: URL!

    override func setUp() async throws {
        manager = SlideshowManager()

        // Create a temp directory with test images
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Create dummy image files (1x1 pixel PNGs)
        for name in ["a.png", "b.jpg", "c.jpeg", "d.heic"] {
            let image = NSImage(size: NSSize(width: 1, height: 1))
            image.lockFocus()
            NSColor.red.drawSwatch(in: NSRect(x: 0, y: 0, width: 1, height: 1))
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
    }

    func testScanFolderFindsImages() {
        manager.setFolder(tempDir)
        XCTAssertEqual(manager.imageCount, 4)
    }

    func testScanFolderIgnoresNonImages() throws {
        try "hello".write(to: tempDir.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)
        try "{}".write(to: tempDir.appendingPathComponent("data.json"), atomically: true, encoding: .utf8)

        manager.setFolder(tempDir)
        XCTAssertEqual(manager.imageCount, 4)
    }

    func testScanFolderIgnoresHiddenFiles() throws {
        let image = NSImage(size: NSSize(width: 1, height: 1))
        image.lockFocus()
        NSColor.blue.drawSwatch(in: NSRect(x: 0, y: 0, width: 1, height: 1))
        image.unlockFocus()
        if let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let data = bitmap.representation(using: .png, properties: [:]) {
            try data.write(to: tempDir.appendingPathComponent(".hidden.png"))
        }

        manager.setFolder(tempDir)
        XCTAssertEqual(manager.imageCount, 4)
    }

    func testSetFolderLoadsFirstImage() {
        manager.setFolder(tempDir)
        XCTAssertNotNil(manager.currentImage)
        XCTAssertEqual(manager.currentIndex, 0)
    }

    func testNextImageAdvances() {
        manager.setFolder(tempDir)
        let firstName = manager.currentFileName

        manager.nextImage()
        XCTAssertEqual(manager.currentIndex, 1)
        XCTAssertNotEqual(manager.currentFileName, firstName)
    }

    func testNextImageWrapsAround() {
        manager.setFolder(tempDir)
        for _ in 0..<manager.imageCount {
            manager.nextImage()
        }
        XCTAssertEqual(manager.currentIndex, 0)
    }

    func testPreviousImageGoesBack() {
        manager.setFolder(tempDir)
        manager.nextImage()
        manager.nextImage()
        XCTAssertEqual(manager.currentIndex, 2)

        manager.previousImage()
        XCTAssertEqual(manager.currentIndex, 1)
    }

    func testPreviousImageWrapsToEnd() {
        manager.setFolder(tempDir)
        XCTAssertEqual(manager.currentIndex, 0)

        manager.previousImage()
        XCTAssertEqual(manager.currentIndex, manager.imageCount - 1)
    }

    func testEmptyFolderHandledGracefully() throws {
        let emptyDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: emptyDir) }

        manager.setFolder(emptyDir)
        XCTAssertEqual(manager.imageCount, 0)
        XCTAssertNil(manager.currentImage)
        XCTAssertNil(manager.currentFileName)
    }

    func testNextImageNoOpOnEmpty() throws {
        let emptyDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: emptyDir) }

        manager.setFolder(emptyDir)
        manager.nextImage() // Should not crash
        manager.previousImage() // Should not crash
        XCTAssertEqual(manager.currentIndex, 0)
    }

    func testImagesSortedAlphabetically() {
        manager.setFolder(tempDir)
        XCTAssertEqual(manager.currentFileName, "a.png")
        manager.nextImage()
        XCTAssertEqual(manager.currentFileName, "b.jpg")
        manager.nextImage()
        XCTAssertEqual(manager.currentFileName, "c.jpeg")
        manager.nextImage()
        XCTAssertEqual(manager.currentFileName, "d.heic")
    }

    func testStartAndStopRotation() {
        manager.setFolder(tempDir)
        XCTAssertFalse(manager.isRotating)

        manager.startRotation(interval: 5)
        XCTAssertTrue(manager.isRotating)

        manager.stopRotation()
        XCTAssertFalse(manager.isRotating)
    }

    func testStopClearsRotation() {
        manager.setFolder(tempDir)
        manager.startRotation(interval: 5)
        XCTAssertTrue(manager.isRotating)

        manager.stop()
        XCTAssertFalse(manager.isRotating)
    }
}
