// qMD - Central application state
// Manages folder, file selection, content, and navigation.

import Foundation
import CoreGraphics
import Observation

@Observable
class AppState {
    var folderURL: URL?
    var selectedFileURL: URL? {
        didSet {
            guard oldValue != selectedFileURL else { return }
            recordNavigation()
        }
    }
    var fileNodes: [FileNode] = []
    var flatFileList: [URL] = []
    var markdownContent: String = ""
    var navigationHistory: [URL] = []
    var navigationIndex: Int = -1
    var fontScale: CGFloat = 1.0
    private var suppressHistoryPush = false
    private let fileWatcher = FileWatcher()

    private static let zoomStep: CGFloat = 1.1
    private static let zoomMin: CGFloat = 0.5
    private static let zoomMax: CGFloat = 3.0

    var canGoBack: Bool { navigationIndex > 0 }
    var canGoForward: Bool {
        navigationIndex >= 0 && navigationIndex < navigationHistory.count - 1
    }

    func zoomIn() {
        fontScale = min(fontScale * Self.zoomStep, Self.zoomMax)
    }

    func zoomOut() {
        fontScale = max(fontScale / Self.zoomStep, Self.zoomMin)
    }

    func resetZoom() {
        fontScale = 1.0
    }

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
        resetNavigationHistory()
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
        resetNavigationHistory()
        let parentDir = url.deletingLastPathComponent()
        folderURL = parentDir
        fileNodes = FileTreeLoader.loadTree(from: parentDir)
        flatFileList = FileTreeLoader.flattenFiles(fileNodes)
        selectedFileURL = url
        loadFileContent()
        setupFileWatcher()
        setupDirectoryWatcher()
    }

    // Opens a markdown file linked from the currently rendered document.
    // Resolves outside-folder targets too; the sidebar simply won't highlight
    // entries that aren't part of the current tree.
    func openLinkedFile(_ url: URL) {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
              !isDir.boolValue else { return }
        selectedFileURL = url
        loadFileContent()
        setupFileWatcher()
    }

    func goBack() {
        guard canGoBack else { return }
        navigationIndex -= 1
        navigateToHistoryEntry()
    }

    func goForward() {
        guard canGoForward else { return }
        navigationIndex += 1
        navigateToHistoryEntry()
    }

    private func navigateToHistoryEntry() {
        let target = navigationHistory[navigationIndex]
        suppressHistoryPush = true
        selectedFileURL = target
        suppressHistoryPush = false
        loadFileContent()
        setupFileWatcher()
    }

    private func recordNavigation() {
        guard !suppressHistoryPush, let url = selectedFileURL else { return }
        if navigationIndex < navigationHistory.count - 1 {
            navigationHistory = Array(navigationHistory.prefix(navigationIndex + 1))
        }
        if navigationHistory.last != url {
            navigationHistory.append(url)
            navigationIndex = navigationHistory.count - 1
        }
    }

    private func resetNavigationHistory() {
        suppressHistoryPush = true
        navigationHistory = []
        navigationIndex = -1
        suppressHistoryPush = false
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
        // Defense-in-depth: never try to read a directory as a Markdown file.
        // The sidebar disables selection on folder rows, but stale URLs from
        // external opens or watcher refreshes could still point at a folder.
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
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
        // Refresh re-assigns selection on disk-change events; treat it as
        // a stay-in-place navigation rather than a new history entry.
        suppressHistoryPush = true
        defer { suppressHistoryPush = false }
        if let prev = previousSelection, flatFileList.contains(prev) {
            selectedFileURL = prev
            loadFileContent()
        } else if let first = flatFileList.first {
            selectedFileURL = first
            loadFileContent()
        }
    }
}
