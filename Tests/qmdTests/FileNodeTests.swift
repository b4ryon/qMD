// qMD - FileNode model tests
// Validates FileNode creation, identity, and hashability.

import XCTest
import Foundation
@testable import qmd

final class FileNodeTests: XCTestCase {

    func testFileNodeCreation() {
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let node = FileNode(name: "test.md", url: url, isFolder: false)

        XCTAssertEqual(node.name, "test.md")
        XCTAssertEqual(node.url, url)
        XCTAssertFalse(node.isFolder)
        XCTAssertNil(node.children)
    }

    func testFolderNodeCreation() {
        let folderURL = URL(fileURLWithPath: "/tmp/docs")
        let childURL = URL(fileURLWithPath: "/tmp/docs/readme.md")
        let child = FileNode(name: "readme.md", url: childURL, isFolder: false)
        let folder = FileNode(name: "docs", url: folderURL, isFolder: true, children: [child])

        XCTAssertTrue(folder.isFolder)
        XCTAssertEqual(folder.children?.count, 1)
        XCTAssertEqual(folder.children?.first?.name, "readme.md")
    }

    func testNodeIdentity() {
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let node = FileNode(name: "test.md", url: url, isFolder: false)

        XCTAssertEqual(node.id, url)
    }

    func testNodeHashability() {
        let url1 = URL(fileURLWithPath: "/tmp/a.md")
        let url2 = URL(fileURLWithPath: "/tmp/b.md")
        let node1 = FileNode(name: "a.md", url: url1, isFolder: false)
        let node2 = FileNode(name: "b.md", url: url2, isFolder: false)

        var set = Set<FileNode>()
        set.insert(node1)
        set.insert(node2)
        XCTAssertEqual(set.count, 2)
    }

    func testNodeEquality() {
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let node1 = FileNode(name: "test.md", url: url, isFolder: false)
        let node2 = FileNode(name: "test.md", url: url, isFolder: false)

        XCTAssertEqual(node1, node2)
    }

    func testEmptyChildren() {
        let url = URL(fileURLWithPath: "/tmp/empty")
        let folder = FileNode(name: "empty", url: url, isFolder: true, children: [])

        XCTAssertTrue(folder.isFolder)
        XCTAssertNotNil(folder.children)
        XCTAssertEqual(folder.children?.count, 0)
    }

    func testNestedFolderStructure() {
        let root = URL(fileURLWithPath: "/tmp/root")
        let sub = URL(fileURLWithPath: "/tmp/root/sub")
        let fileURL = URL(fileURLWithPath: "/tmp/root/sub/deep.md")

        let deepFile = FileNode(name: "deep.md", url: fileURL, isFolder: false)
        let subFolder = FileNode(name: "sub", url: sub, isFolder: true, children: [deepFile])
        let rootFolder = FileNode(name: "root", url: root, isFolder: true, children: [subFolder])

        XCTAssertEqual(rootFolder.children?.count, 1)
        XCTAssertEqual(rootFolder.children?.first?.children?.count, 1)
        XCTAssertEqual(rootFolder.children?.first?.children?.first?.name, "deep.md")
    }
}
