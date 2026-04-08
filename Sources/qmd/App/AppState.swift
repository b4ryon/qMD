// qMD - Central application state
// Manages folder, file selection, content, and navigation.

import Foundation
import Observation

@Observable
class AppState {
    var folderURL: URL?
    var selectedFileURL: URL?
    var fileNodes: [FileNode] = []
    var flatFileList: [URL] = []
    var markdownContent: String = ""
    private let fileWatcher = FileWatcher()

    var currentBaseURL: URL? {
        folderURL ?? selectedFileURL?.deletingLastPathComponent()
    }

    var windowTitle: String {
        if let file = selectedFileURL {
            return file.lastPathComponent
        }
        return "qMD"
    }

    func handleOpen(url: URL) {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
            return
        }
        if isDir.boolValue {
            loadFolder(url)
        } else {
            loadSingleFile(url)
        }
    }

    func loadFolder(_ url: URL) {
        folderURL = url
        fileNodes = FileTreeLoader.loadTree(from: url)
        flatFileList = FileTreeLoader.flattenFiles(fileNodes)
        if let first = flatFileList.first {
            selectedFileURL = first
            loadFileContent()
            setupFileWatcher()
        } else {
            selectedFileURL = nil
            markdownContent = ""
        }
        setupDirectoryWatcher()
    }

    func loadSingleFile(_ url: URL) {
        let parentDir = url.deletingLastPathComponent()
        folderURL = parentDir
        fileNodes = FileTreeLoader.loadTree(from: parentDir)
        flatFileList = FileTreeLoader.flattenFiles(fileNodes)
        selectedFileURL = url
        loadFileContent()
        setupFileWatcher()
        setupDirectoryWatcher()
    }

    func selectFile(_ url: URL) {
        guard url != selectedFileURL else { return }
        selectedFileURL = url
        loadFileContent()
        setupFileWatcher()
    }

    func loadFileContent() {
        guard let url = selectedFileURL else {
            markdownContent = ""
            return
        }
        do {
            markdownContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            markdownContent = "Error: Unable to read file.\n\n\(error.localizedDescription)"
        }
    }

    func selectNext() {
        guard let current = selectedFileURL,
              let index = flatFileList.firstIndex(of: current),
              index + 1 < flatFileList.count else { return }
        selectFile(flatFileList[index + 1])
    }

    func selectPrevious() {
        guard let current = selectedFileURL,
              let index = flatFileList.firstIndex(of: current),
              index > 0 else { return }
        selectFile(flatFileList[index - 1])
    }

    func setupFileWatcherForCurrentFile() {
        setupFileWatcher()
    }

    private func setupFileWatcher() {
        guard let url = selectedFileURL else {
            fileWatcher.stopWatchingFile()
            return
        }
        fileWatcher.watchFile(at: url) { [weak self] in
            self?.loadFileContent()
        }
    }

    private func setupDirectoryWatcher() {
        guard let url = folderURL else {
            fileWatcher.stopWatchingDirectory()
            return
        }
        fileWatcher.watchDirectory(at: url) { [weak self] in
            self?.refreshTree()
        }
    }

    func refreshTree() {
        guard let folder = folderURL else { return }
        let previousSelection = selectedFileURL
        fileNodes = FileTreeLoader.loadTree(from: folder)
        flatFileList = FileTreeLoader.flattenFiles(fileNodes)
        if let prev = previousSelection, flatFileList.contains(prev) {
            selectedFileURL = prev
            loadFileContent()
        } else if let first = flatFileList.first {
            selectedFileURL = first
            loadFileContent()
        }
    }
}
