// qMD - Main content view
// NavigationSplitView with sidebar file tree and markdown detail view.
// Arrow keys handled by KeyboardHandler, Cmd+F opens find bar.

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var template = HTMLTemplate()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var keyboardHandler: KeyboardHandler?
    @State private var showSearchBar = false
    @State private var searchQuery = ""
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
                    Text("Cmd+O to open a file or folder")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(appState.windowTitle)
        .onAppear {
            if keyboardHandler == nil {
                keyboardHandler = KeyboardHandler(appState: appState)
            }
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
