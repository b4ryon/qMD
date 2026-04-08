// qMD - File tree node model
// Represents a file or folder in the sidebar tree.

import Foundation

struct FileNode: Identifiable, Hashable {
    let id: URL
    let name: String
    let url: URL
    let isFolder: Bool
    var children: [FileNode]?

    init(name: String, url: URL, isFolder: Bool, children: [FileNode]? = nil) {
        self.id = url
        self.name = name
        self.url = url
        self.isFolder = isFolder
        self.children = children
    }
}
