// qMD - Sidebar file tree view
// Displays a recursive outline of Markdown files in the selected folder.

import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        Group {
            if appState.fileNodes.isEmpty {
                VStack(spacing: 8) {
                    Text("No files")
                        .foregroundStyle(.secondary)
                    Text("Open a folder to browse")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $state.selectedFileURL) {
                    OutlineGroup(appState.fileNodes, children: \.children) { node in
                        if node.isFolder {
                            Label(node.name, systemImage: "folder")
                        } else {
                            Label(node.name, systemImage: "doc.text")
                                .tag(node.url)
                        }
                    }
                }
                .listStyle(.sidebar)
                .onChange(of: appState.selectedFileURL) { oldValue, newValue in
                    if let url = newValue, url != oldValue {
                        appState.loadFileContent()
                        appState.setupFileWatcherForCurrentFile()
                    }
                }
            }
        }
    }
}
