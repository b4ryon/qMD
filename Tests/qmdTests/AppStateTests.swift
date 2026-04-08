// qMD - AppState tests
// Validates state management, file selection, navigation, and folder loading.

import XCTest
import Foundation
@testable import qmd

final class AppStateTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let tmpBase = home.appendingPathComponent("tmp")
        try FileManager.default.createDirectory(at: tmpBase, withIntermediateDirectories: true)
        tempDir = tmpBase.appendingPathComponent("qmd_state_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let dir = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    @discardableResult
    private func createFile(in dir: URL, name: String, content: String = "# Test") throws -> URL {
        let url = dir.appendingPathComponent(name)
        let parent = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testInitialState() {
        let state = AppState()
        XCTAssertNil(state.folderURL)
        XCTAssertNil(state.selectedFileURL)
        XCTAssertTrue(state.fileNodes.isEmpty)
        XCTAssertTrue(state.flatFileList.isEmpty)
        XCTAssertEqual(state.markdownContent, "")
    }

    func testWindowTitleDefault() {
        let state = AppState()
        XCTAssertEqual(state.windowTitle, "qMD")
    }

    func testWindowTitleWithFile() throws {
        let url = try createFile(in: tempDir, name: "readme.md")
        let state = AppState()
        state.selectedFileURL = url
        XCTAssertEqual(state.windowTitle, "readme.md")
    }

    func testLoadFolder() throws {
        try createFile(in: tempDir, name: "alpha.md", content: "# Alpha")
        try createFile(in: tempDir, name: "beta.md", content: "# Beta")

        let state = AppState()
        state.loadFolder(tempDir)

        XCTAssertEqual(state.folderURL, tempDir)
        XCTAssertEqual(state.fileNodes.count, 2)
        XCTAssertEqual(state.flatFileList.count, 2)
        XCTAssertNotNil(state.selectedFileURL)
        XCTAssertFalse(state.markdownContent.isEmpty)
    }

    func testLoadFolderSelectsFirst() throws {
        try createFile(in: tempDir, name: "aaa.md", content: "# AAA")
        try createFile(in: tempDir, name: "bbb.md", content: "# BBB")

        let state = AppState()
        state.loadFolder(tempDir)

        XCTAssertEqual(state.selectedFileURL?.lastPathComponent, "aaa.md")
        XCTAssertEqual(state.markdownContent, "# AAA")
    }

    func testLoadEmptyFolder() throws {
        let state = AppState()
        state.loadFolder(tempDir)

        XCTAssertEqual(state.folderURL, tempDir)
        XCTAssertTrue(state.fileNodes.isEmpty)
        XCTAssertTrue(state.flatFileList.isEmpty)
        XCTAssertNil(state.selectedFileURL)
        XCTAssertEqual(state.markdownContent, "")
    }

    func testLoadSingleFile() throws {
        let url = try createFile(in: tempDir, name: "test.md", content: "# Hello")

        let state = AppState()
        state.loadSingleFile(url)

        XCTAssertEqual(state.selectedFileURL, url)
        XCTAssertEqual(state.markdownContent, "# Hello")
        XCTAssertEqual(state.folderURL?.path, tempDir.path)
        XCTAssertFalse(state.fileNodes.isEmpty)
    }

    func testSelectFile() throws {
        try createFile(in: tempDir, name: "a.md", content: "# A")
        let url2 = try createFile(in: tempDir, name: "b.md", content: "# B")

        let state = AppState()
        state.loadFolder(tempDir)
        state.selectFile(url2)

        XCTAssertEqual(state.selectedFileURL, url2)
        XCTAssertEqual(state.markdownContent, "# B")
    }

    func testSelectSameFileNoOp() throws {
        let url = try createFile(in: tempDir, name: "test.md", content: "# Test")

        let state = AppState()
        state.loadFolder(tempDir)

        let contentBefore = state.markdownContent
        state.selectFile(url)

        XCTAssertEqual(state.markdownContent, contentBefore)
    }

    func testSelectNext() throws {
        try createFile(in: tempDir, name: "a.md", content: "# A")
        try createFile(in: tempDir, name: "b.md", content: "# B")
        try createFile(in: tempDir, name: "c.md", content: "# C")

        let state = AppState()
        state.loadFolder(tempDir)
        XCTAssertEqual(state.selectedFileURL?.lastPathComponent, "a.md")

        state.selectNext()
        XCTAssertEqual(state.selectedFileURL?.lastPathComponent, "b.md")

        state.selectNext()
        XCTAssertEqual(state.selectedFileURL?.lastPathComponent, "c.md")
    }

    func testSelectNextAtEnd() throws {
        try createFile(in: tempDir, name: "a.md")
        try createFile(in: tempDir, name: "b.md")

        let state = AppState()
        state.loadFolder(tempDir)
        state.selectNext()
        state.selectNext()

        XCTAssertEqual(state.selectedFileURL?.lastPathComponent, "b.md")
    }

    func testSelectPrevious() throws {
        try createFile(in: tempDir, name: "a.md", content: "# A")
        try createFile(in: tempDir, name: "b.md", content: "# B")
        try createFile(in: tempDir, name: "c.md", content: "# C")

        let state = AppState()
        state.loadFolder(tempDir)
        state.selectNext()
        state.selectNext()

        state.selectPrevious()
        XCTAssertEqual(state.selectedFileURL?.lastPathComponent, "b.md")

        state.selectPrevious()
        XCTAssertEqual(state.selectedFileURL?.lastPathComponent, "a.md")
    }

    func testSelectPreviousAtStart() throws {
        try createFile(in: tempDir, name: "a.md")
        try createFile(in: tempDir, name: "b.md")

        let state = AppState()
        state.loadFolder(tempDir)
        state.selectPrevious()

        XCTAssertEqual(state.selectedFileURL?.lastPathComponent, "a.md")
    }

    func testSelectNextNoSelection() {
        let state = AppState()
        state.selectNext()
        XCTAssertNil(state.selectedFileURL)
    }

    func testSelectPreviousNoSelection() {
        let state = AppState()
        state.selectPrevious()
        XCTAssertNil(state.selectedFileURL)
    }

    func testHandleOpenFile() throws {
        let url = try createFile(in: tempDir, name: "test.md", content: "# File")

        let state = AppState()
        state.handleOpen(url: url)

        XCTAssertEqual(state.selectedFileURL, url)
        XCTAssertEqual(state.markdownContent, "# File")
    }

    func testHandleOpenDirectory() throws {
        try createFile(in: tempDir, name: "doc.md", content: "# Doc")

        let state = AppState()
        state.handleOpen(url: tempDir)

        XCTAssertEqual(state.folderURL, tempDir)
        XCTAssertNotNil(state.selectedFileURL)
    }

    func testHandleOpenNonexistent() {
        let fakeURL = URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString).md")

        let state = AppState()
        state.handleOpen(url: fakeURL)

        XCTAssertNil(state.selectedFileURL)
    }

    func testCurrentBaseURLFromFolder() throws {
        try createFile(in: tempDir, name: "test.md")

        let state = AppState()
        state.loadFolder(tempDir)

        XCTAssertEqual(state.currentBaseURL, tempDir)
    }

    func testCurrentBaseURLWithoutFolder() throws {
        let url = try createFile(in: tempDir, name: "test.md")

        let state = AppState()
        state.selectedFileURL = url

        XCTAssertEqual(state.currentBaseURL?.path, tempDir.path)
    }

    func testLoadInvalidFileContent() {
        let state = AppState()
        state.selectedFileURL = URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString).md")
        state.loadFileContent()

        XCTAssertTrue(state.markdownContent.hasPrefix("Error:"))
    }

    func testLoadNoSelectionContent() {
        let state = AppState()
        state.selectedFileURL = nil
        state.loadFileContent()

        XCTAssertEqual(state.markdownContent, "")
    }

    func testRefreshTreePreservesSelection() throws {
        try createFile(in: tempDir, name: "original.md", content: "# Original")

        let state = AppState()
        state.loadFolder(tempDir)
        let selectedBefore = state.selectedFileURL

        try createFile(in: tempDir, name: "new.md", content: "# New")
        state.refreshTree()

        XCTAssertEqual(state.flatFileList.count, 2)
        XCTAssertEqual(state.selectedFileURL, selectedBefore)
    }

    func testRefreshTreeDeletedSelection() throws {
        let doomed = try createFile(in: tempDir, name: "doomed.md", content: "# Doomed")
        try createFile(in: tempDir, name: "survivor.md", content: "# Survivor")

        let state = AppState()
        state.loadFolder(tempDir)
        state.selectFile(doomed)

        try FileManager.default.removeItem(at: doomed)
        state.refreshTree()

        XCTAssertEqual(state.flatFileList.count, 1)
        XCTAssertEqual(state.selectedFileURL?.lastPathComponent, "survivor.md")
    }

    func testUtf8FileContent() throws {
        let content = "# Unicode Test\n\nJapanese: \u{65E5}\u{672C}\u{8A9E}\nGerman: Umlaute"
        let url = try createFile(in: tempDir, name: "unicode.md", content: content)

        let state = AppState()
        state.loadSingleFile(url)

        XCTAssertEqual(state.markdownContent, content)
    }
}
