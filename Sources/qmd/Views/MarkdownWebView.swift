// qMD - WKWebView wrapper for rendering markdown
// Loads an HTML template and updates content via JavaScript calls.
// Wrapped in FindableWebContainer to suppress arrow key beeps.

import SwiftUI
import WebKit

// Container view that intercepts bare arrow keys to prevent system beeps.
class FindableWebContainer: NSView {
    override var acceptsFirstResponder: Bool { true }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let hasModifiers = !event.modifierFlags
            .intersection([.command, .option, .control])
            .isEmpty
        if !hasModifiers {
            switch event.keyCode {
            case 123, 124, 125, 126:
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let baseURL: URL?
    let fileURL: URL?
    let templateHTML: String
    let keyboardHandler: KeyboardHandler?
    let searchQuery: String
    let onNavigateToFile: ((URL) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> FindableWebContainer {
        let container = FindableWebContainer()

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.autoresizingMask = [.width, .height]

        container.addSubview(webView)
        container.webView = webView
        context.coordinator.webView = webView
        keyboardHandler?.webView = webView
        context.coordinator.currentBaseURL = baseURL
        context.coordinator.pendingMarkdown = markdown
        context.coordinator.onNavigateToFile = onNavigateToFile
        webView.loadHTMLString(templateHTML, baseURL: baseURL)
        return container
    }

    func updateNSView(_ container: FindableWebContainer, context: Context) {
        guard let webView = context.coordinator.webView else { return }
        keyboardHandler?.webView = webView
        container.webView = webView
        context.coordinator.onNavigateToFile = onNavigateToFile

        if context.coordinator.currentBaseURL != baseURL {
            context.coordinator.isLoaded = false
            context.coordinator.currentBaseURL = baseURL
            context.coordinator.pendingMarkdown = markdown
            context.coordinator.lastSearchQuery = ""
            context.coordinator.lastFileURL = fileURL
            webView.loadHTMLString(templateHTML, baseURL: baseURL)
            return
        }

        if context.coordinator.isLoaded {
            let preserveScroll = fileURL != nil && fileURL == context.coordinator.lastFileURL
            context.coordinator.renderInWebView(webView, markdown: markdown, preserveScroll: preserveScroll)
            context.coordinator.lastFileURL = fileURL
            context.coordinator.updateSearch(in: webView, query: searchQuery)
        } else {
            context.coordinator.pendingMarkdown = markdown
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var isLoaded = false
        var pendingMarkdown: String?
        var currentBaseURL: URL?
        var lastFileURL: URL?
        weak var webView: WKWebView?
        var lastSearchQuery = ""
        var onNavigateToFile: ((URL) -> Void)?
        private var lastRenderedHash: Int = 0
        private static let markdownExtensions: Set<String> = [
            "md", "markdown", "mdown", "mkd", "mkdn"
        ]

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            if let md = pendingMarkdown {
                renderInWebView(webView, markdown: md, preserveScroll: false)
                pendingMarkdown = nil
            }
        }

        func renderInWebView(_ webView: WKWebView, markdown: String, preserveScroll: Bool = false) {
            let hash = markdown.hashValue
            guard hash != lastRenderedHash else { return }
            lastRenderedHash = hash

            let base64 = Data(markdown.utf8).base64EncodedString()
            let preserve = preserveScroll ? "true" : "false"
            webView.evaluateJavaScript("renderMarkdown('\(base64)', \(preserve))") { _, error in
                if let error = error {
                    print("JS render error: \(error.localizedDescription)")
                }
            }
            lastSearchQuery = ""
        }

        func updateSearch(in webView: WKWebView, query: String) {
            guard query != lastSearchQuery else { return }
            lastSearchQuery = query

            if query.isEmpty {
                webView.evaluateJavaScript("clearSearch()") { _, _ in }
            } else {
                let escaped = query
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "'", with: "\\'")
                webView.evaluateJavaScript("highlightSearch('\(escaped)')") { _, _ in }
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                // In-document anchor links - let WebKit scroll as usual.
                if let fragment = url.fragment, !fragment.isEmpty {
                    decisionHandler(.allow)
                    return
                }
                // Local markdown file links open in-window via the callback,
                // pushing onto the navigation history.
                if url.isFileURL,
                   Self.markdownExtensions.contains(url.pathExtension.lowercased()),
                   FileManager.default.fileExists(atPath: url.path),
                   let handler = onNavigateToFile {
                    handler(url)
                    decisionHandler(.cancel)
                    return
                }
                // Everything else (http, non-markdown files) opens externally.
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

// Store webView reference on container for external access
extension FindableWebContainer {
    private static var webViewKey: UInt8 = 0

    var webView: WKWebView? {
        get { objc_getAssociatedObject(self, &Self.webViewKey) as? WKWebView }
        set { objc_setAssociatedObject(self, &Self.webViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
