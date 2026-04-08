// qMD - FileTreeLoader tests
// Validates directory scanning, filtering, sorting, and flattening.

import XCTest
import Foundation
@testable import qmd

final class FileTreeLoaderTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let tmpBase = home.appendingPathComponent("tmp")
        try FileManager.default.createDirectory(at: tmpBase, withIntermediateDirectories: true)
        tempDir = tmpBase.appendingPathComponent("qmd_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let dir = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    private func createFile(in dir: URL, path: String, content: String = "# Test") throws {
        let url = dir.appendingPathComponent(path)
        let parent = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func testLoadTreeWithMarkdownFiles() throws {
        try createFile(in: tempDir, path: "alpha.md")
        try createFile(in: tempDir, path: "beta.md")
        try createFile(in: tempDir, path: "gamma.md")

        let nodes = FileTreeLoader.loadTree(from: tempDir)

        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(nodes[0].name, "alpha.md")
        XCTAssertEqual(nodes[1].name, "beta.md")
        XCTAssertEqual(nodes[2].name, "gamma.md")
    }

    func testFilterNonMarkdownFiles() throws {
        try createFile(in: tempDir, path: "readme.md")
        try createFile(in: tempDir, path: "notes.txt")
        try createFile(in: tempDir, path: "image.png")
        try createFile(in: tempDir, path: "data.json")

        let nodes = FileTreeLoader.loadTree(from: tempDir)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].name, "readme.md")
    }

    func testSupportedExtensions() throws {
        try createFile(in: tempDir, path: "file.md")
        try createFile(in: tempDir, path: "file.markdown")
        try createFile(in: tempDir, path: "file.mdown")
        try createFile(in: tempDir, path: "file.mkd")
        try createFile(in: tempDir, path: "file.mkdn")

        let nodes = FileTreeLoader.loadTree(from: tempDir)

        XCTAssertEqual(nodes.count, 5)
    }

    func testCaseInsensitiveExtension() throws {
        try createFile(in: tempDir, path: "upper.MD")
        try createFile(in: tempDir, path: "mixed.Markdown")

        let nodes = FileTreeLoader.loadTree(from: tempDir)

        XCTAssertEqual(nodes.count, 2)
    }

    func testFoldersSortedBeforeFiles() throws {
        try createFile(in: tempDir, path: "zebra.md")
        try createFile(in: tempDir, path: "subdir/alpha.md")

        let nodes = FileTreeLoader.loadTree(from: tempDir)

        XCTAssertEqual(nodes.count, 2)
        XCTAssertTrue(nodes[0].isFolder)
        XCTAssertFalse(nodes[1].isFolder)
    }

    func testAlphabeticalSorting() throws {
        try createFile(in: tempDir, path: "charlie.md")
        try createFile(in: tempDir, path: "alpha.md")
        try createFile(in: tempDir, path: "bravo.md")

        let nodes = FileTreeLoader.loadTree(from: tempDir)

        XCTAssertEqual(nodes.map(\.name), ["alpha.md", "bravo.md", "charlie.md"])
    }

    func testRecursiveSubdirectories() throws {
        try createFile(in: tempDir, path: "top.md")
        try createFile(in: tempDir, path: "sub1/a.md")
        try createFile(in: tempDir, path: "sub1/sub2/b.md")

        let nodes = FileTreeLoader.loadTree(from: tempDir)

        XCTAssertEqual(nodes.count, 2)
        let sub1 = nodes.first(where: { $0.name == "sub1" })
        XCTAssertNotNil(sub1)
        XCTAssertEqual(sub1?.children?.count, 2)
    }

    func testEmptySubdirectoriesExcluded() throws {
        try createFile(in: tempDir, path: "test.md")
        let emptyDir = tempDir.appendingPathComponent("empty_dir")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        let nodes = FileTreeLoader.loadTree(from: tempDir)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].name, "test.md")
    }

    func testHiddenFilesExcluded() throws {
        try createFile(in: tempDir, path: ".hidden.md")
        try createFile(in: tempDir, path: "visible.md")

        let nodes = FileTreeLoader.loadTree(from: tempDir)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].name, "visible.md")
    }

    func testEmptyDirectory() throws {
        let nodes = FileTreeLoader.loadTree(from: tempDir)

        XCTAssertTrue(nodes.isEmpty)
    }

    func testNonexistentDirectory() {
        let fakeDir = URL(fileURLWithPath: "/nonexistent/path/\(UUID().uuidString)")
        let nodes = FileTreeLoader.loadTree(from: fakeDir)

        XCTAssertTrue(nodes.isEmpty)
    }

    func testFlattenFiles() throws {
        try createFile(in: tempDir, path: "a.md")
        try createFile(in: tempDir, path: "sub/b.md")
        try createFile(in: tempDir, path: "sub/deep/c.md")

        let nodes = FileTreeLoader.loadTree(from: tempDir)
        let flat = FileTreeLoader.flattenFiles(nodes)

        XCTAssertEqual(flat.count, 3)
        XCTAssertTrue(flat.allSatisfy { $0.pathExtension == "md" })
    }

    func testFlattenDepthFirstOrder() throws {
        try createFile(in: tempDir, path: "z.md")
        try createFile(in: tempDir, path: "aaa/a.md")
        try createFile(in: tempDir, path: "aaa/bbb/b.md")

        let nodes = FileTreeLoader.loadTree(from: tempDir)
        let flat = FileTreeLoader.flattenFiles(nodes)
        let names = flat.map { $0.lastPathComponent }

        // bbb folder sorts before a.md file within aaa/, so b.md comes first
        XCTAssertEqual(names, ["b.md", "a.md", "z.md"])
    }

    func testFlattenEmptyTree() {
        let flat = FileTreeLoader.flattenFiles([])
        XCTAssertTrue(flat.isEmpty)
    }

    func testMarkdownExtensionsSet() {
        XCTAssertTrue(FileTreeLoader.markdownExtensions.contains("md"))
        XCTAssertTrue(FileTreeLoader.markdownExtensions.contains("markdown"))
        XCTAssertTrue(FileTreeLoader.markdownExtensions.contains("mdown"))
        XCTAssertTrue(FileTreeLoader.markdownExtensions.contains("mkd"))
        XCTAssertTrue(FileTreeLoader.markdownExtensions.contains("mkdn"))
        XCTAssertFalse(FileTreeLoader.markdownExtensions.contains("txt"))
    }
}
