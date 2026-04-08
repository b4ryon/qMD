// qMD - Application-level keyboard handler
// Intercepts arrow keys globally via NSEvent monitor to ensure consistent
// behavior regardless of which view has focus. Left/right switch files,
// up/down scroll the markdown content via JavaScript.

import AppKit
import WebKit

class KeyboardHandler {
    private var monitor: Any?
    private weak var appState: AppState?
    weak var webView: WKWebView?

    init(appState: AppState) {
        self.appState = appState
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
