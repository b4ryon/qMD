// qMD - File tree loader
// Recursively scans directories for Markdown files and builds a tree structure.

import Foundation

enum FileTreeLoader {
    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn"]

    static func loadTree(from url: URL) -> [FileNode] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var folders: [FileNode] = []
        var files: [FileNode] = []

        for item in contents {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

            if isDir {
                let children = loadTree(from: item)
                if !children.isEmpty {
                    folders.append(FileNode(
                        name: item.lastPathComponent,
                        url: item,
                        isFolder: true,
                        children: children
                    ))
                }
            } else if markdownExtensions.contains(item.pathExtension.lowercased()) {
                files.append(FileNode(
                    name: item.lastPathComponent,
                    url: item,
                    isFolder: false
                ))
            }
        }

        folders.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        files.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        return folders + files
    }

    static func flattenFiles(_ nodes: [FileNode]) -> [URL] {
        var result: [URL] = []
        for node in nodes {
            if node.isFolder, let children = node.children {
                result.append(contentsOf: flattenFiles(children))
            } else if !node.isFolder {
                result.append(node.url)
            }
        }
        return result
    }
}
