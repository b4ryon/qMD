// qMD - Per-window keyboard handler
// Intercepts arrow keys via a local NSEvent monitor. Because NSEvent monitors
// are app-wide, each handler checks that its owning window is the key window
// before acting, so arrow keys don't cross-fire between open windows.
// Left/right switch files, up/down scroll the markdown content via JavaScript.

import AppKit
import WebKit

class KeyboardHandler {
    private var monitor: Any?
    private weak var appState: AppState?
    private let windowProvider: () -> NSWindow?
    weak var webView: WKWebView?

    init(appState: AppState, windowProvider: @escaping () -> NSWindow? = { nil }) {
        self.appState = appState
        self.windowProvider = windowProvider
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleKeyDown(event) ?? event
        }
    }

    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        // Only respond if our owning window is the key window. Without this,
        // every open qMD window would react to arrow keys in parallel.
        let owner = windowProvider()
        if owner != nil, owner !== NSApp.keyWindow {
            return event
        }

        let hasModifiers = !event.modifierFlags
            .intersection([.command, .option, .control])
            .isEmpty

        if hasModifiers { return event }

        switch event.keyCode {
        case 123: // left arrow - previous file
            appState?.selectPrevious()
            return nil
        case 124: // right arrow - next file
            appState?.selectNext()
            return nil
        case 125: // down arrow - scroll down
            scrollWebView(by: 80)
            return nil
        case 126: // up arrow - scroll up
            scrollWebView(by: -80)
            return nil
        default:
            return event
        }
    }

    private func scrollWebView(by pixels: Int) {
        webView?.evaluateJavaScript("window.scrollBy(0, \(pixels))") { _, _ in }
    }
}
