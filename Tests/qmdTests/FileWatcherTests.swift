// qMD - FileWatcher tests
// Validates file and directory monitoring with debounce.

import XCTest
import Foundation
@testable import qmd

final class FileWatcherTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let tmpBase = home.appendingPathComponent("tmp")
        try FileManager.default.createDirectory(at: tmpBase, withIntermediateDirectories: true)
        tempDir = tmpBase.appendingPathComponent("qmd_watch_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let dir = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    func testWatchFileDetectsChanges() throws {
        let watcher = FileWatcher()
        defer { watcher.stopAll() }

        let fileURL = tempDir.appendingPathComponent("watched.md")
        try "# Initial".write(to: fileURL, atomically: true, encoding: .utf8)

        let exp = self.expectation(description: "File change detected")

        watcher.watchFile(at: fileURL) {
            exp.fulfill()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? "# Modified".write(to: fileURL, atomically: true, encoding: .utf8)
        }

        waitForExpectations(timeout: 5.0)
    }

    func testStopWatching() throws {
        let watcher = FileWatcher()
        defer { watcher.stopAll() }

        let fileURL = tempDir.appendingPathComponent("stop.md")
        try "# Initial".write(to: fileURL, atomically: true, encoding: .utf8)

        var callCount = 0
        watcher.watchFile(at: fileURL) {
            callCount += 1
        }
        watcher.stopWatchingFile()

        try "# Modified".write(to: fileURL, atomically: true, encoding: .utf8)

        let exp = self.expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(callCount, 0)
    }

    func testStopAll() throws {
        let watcher = FileWatcher()

        let fileURL = tempDir.appendingPathComponent("all.md")
        try "# Test".write(to: fileURL, atomically: true, encoding: .utf8)

        var callCount = 0
        watcher.watchFile(at: fileURL) { callCount += 1 }
        watcher.watchDirectory(at: tempDir) { callCount += 1 }
        watcher.stopAll()

        try "# Changed".write(to: fileURL, atomically: true, encoding: .utf8)

        let exp = self.expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(callCount, 0)
    }

    func testWatchNonexistentFile() throws {
        let watcher = FileWatcher()
        defer { watcher.stopAll() }

        let fakeURL = tempDir.appendingPathComponent("nonexistent_\(UUID().uuidString).md")

        var callCount = 0
        watcher.watchFile(at: fakeURL) { callCount += 1 }

        let exp = self.expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exp.fulfill() }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(callCount, 0)
    }

    func testReplaceWatcher() throws {
        let watcher = FileWatcher()
        defer { watcher.stopAll() }

        let file1 = tempDir.appendingPathComponent("first.md")
        let file2 = tempDir.appendingPathComponent("second.md")
        try "# First".write(to: file1, atomically: true, encoding: .utf8)
        try "# Second".write(to: file2, atomically: true, encoding: .utf8)

        var file1Changes = 0
        watcher.watchFile(at: file1) { file1Changes += 1 }
        watcher.watchFile(at: file2) { /* replaced */ }

        try "# First Modified".write(to: file1, atomically: true, encoding: .utf8)

        let exp = self.expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(file1Changes, 0, "Old watcher should have been stopped")
    }
}
