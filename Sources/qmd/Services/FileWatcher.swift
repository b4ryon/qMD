// qMD - File system watcher
// Monitors files and directories for changes using DispatchSource.

import Foundation

class FileWatcher {
    private var fileSource: DispatchSourceFileSystemObject?
    private var dirSource: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?

    func watchFile(at url: URL, onChange: @escaping () -> Void) {
        stopWatchingFile()
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.debounce(action: onChange)
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        fileSource = source
    }

    func watchDirectory(at url: URL, onChange: @escaping () -> Void) {
        stopWatchingDirectory()
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.debounce(action: onChange)
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        dirSource = source
    }

    private func debounce(action: @escaping () -> Void) {
        debounceWorkItem?.cancel()
        let item = DispatchWorkItem(block: action)
        debounceWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: item)
    }

    func stopWatchingFile() {
        fileSource?.cancel()
        fileSource = nil
    }

    func stopWatchingDirectory() {
        dirSource?.cancel()
        dirSource = nil
    }

    func stopAll() {
        stopWatchingFile()
        stopWatchingDirectory()
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }
}
