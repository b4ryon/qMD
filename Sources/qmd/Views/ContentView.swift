// qMD - Main content view
// NavigationSplitView with sidebar file tree and markdown detail view.
// Owns a per-window AppState so each window browses its own directory.
// Arrow keys handled by KeyboardHandler, Cmd+F opens find bar.

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var appState = AppState()
    @State private var template = HTMLTemplate()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var keyboardHandler: KeyboardHandler?
    @State private var showSearchBar = false
    @State private var searchQuery = ""
    @State private var hostWindow: NSWindow?
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 350)
        } detail: {
            if appState.selectedFileURL != nil {
                VStack(spacing: 0) {
                    if showSearchBar {
                        SearchBarView(
                            query: $searchQuery,
                            isFocused: $searchFieldFocused,
                            onClose: { closeSearch() },
                            onNext: { navigateSearch(forward: true) },
                            onPrevious: { navigateSearch(forward: false) }
                        )
                    }
                    MarkdownWebView(
                        markdown: appState.markdownContent,
                        baseURL: appState.currentBaseURL,
                        templateHTML: template.html,
                        keyboardHandler: keyboardHandler,
                        searchQuery: searchQuery
                    )
                }
            } else {
                VStack(spacing: 12) {
                    Text("No file selected")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Open a Markdown file or folder")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                    Text("Cmd+O to open a file or folder, Cmd+N for a new window")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environment(appState)
        .navigationTitle(appState.windowTitle)
        .background(WindowAccessor(window: $hostWindow))
        .onAppear {
            if keyboardHandler == nil {
                keyboardHandler = KeyboardHandler(appState: appState, windowProvider: { hostWindow })
            }
        }
        .onOpenURL { url in
            appState.handleOpen(url: url)
        }
        .onChange(of: appState.selectedFileURL) { _, _ in
            if showSearchBar {
                searchQuery = ""
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            appState.handleOpen(url: url)
            return true
        }
        .background(FindShortcutHandler(onFind: { toggleSearch() }, onEscape: { closeSearch() }))
        .onReceive(NotificationCenter.default.publisher(for: QMDNotifications.openURLInKeyWindow)) { note in
            guard let window = hostWindow, window.isKeyWindow,
                  let url = note.userInfo?[QMDNotifications.openURLPayloadKey] as? URL else { return }
            appState.handleOpen(url: url)
        }
    }

    private func toggleSearch() {
        showSearchBar.toggle()
        if showSearchBar {
            searchFieldFocused = true
        } else {
            closeSearch()
        }
    }

    private func closeSearch() {
        showSearchBar = false
        searchQuery = ""
        searchFieldFocused = false
    }

    private func navigateSearch(forward: Bool) {
        guard let webView = keyboardHandler?.webView else { return }
        let js = forward ? "nextMatch()" : "prevMatch()"
        webView.evaluateJavaScript(js) { _, _ in }
    }
}

// Captures the hosting NSWindow so per-window code (keyboard handler, notification
// dispatch) can scope itself to this window rather than all windows in the app.
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if window !== nsView.window {
                window = nsView.window
            }
        }
    }
}

// Invisible view that catches Cmd+F via performKeyEquivalent
struct FindShortcutHandler: NSViewRepresentable {
    let onFind: () -> Void
    let onEscape: () -> Void

    func makeNSView(context: Context) -> FindShortcutNSView {
        let view = FindShortcutNSView()
        view.onFind = onFind
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: FindShortcutNSView, context: Context) {
        nsView.onFind = onFind
        nsView.onEscape = onEscape
    }

    class FindShortcutNSView: NSView {
        var onFind: (() -> Void)?
        var onEscape: (() -> Void)?

        override var acceptsFirstResponder: Bool { false }

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == .command && event.charactersIgnoringModifiers == "f" {
                onFind?()
                return true
            }
            if event.keyCode == 53 { // Escape
                onEscape?()
                return true
            }
            return super.performKeyEquivalent(with: event)
        }
    }
}

struct SearchBarView: View {
    @Binding var query: String
    var isFocused: FocusState<Bool>.Binding
    let onClose: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Find in document...", text: $query)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .onSubmit { onNext() }
                .onKeyPress(.escape) {
                    onClose()
                    return .handled
                }

            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(query.isEmpty)

            Button(action: onNext) {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
            .disabled(query.isEmpty)

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
