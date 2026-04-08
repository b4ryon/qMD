// qMD - Main application entry point
// Configures the SwiftUI app with window, menus, and file opening support.

import SwiftUI
import UniformTypeIdentifiers

@main
struct MDViewApp: App {
    @State private var appState = AppState()
    @State private var showAbout = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onOpenURL { url in
                    appState.handleOpen(url: url)
                }
                .sheet(isPresented: $showAbout) {
                    AboutView()
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About qMD") {
                    showAbout = true
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    openFileOrFolder()
                }
                .keyboardShortcut("o")
            }
        }
    }

    private func openFileOrFolder() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.message = "Open a Markdown file or folder"
        if panel.runModal() == .OK, let url = panel.url {
            appState.handleOpen(url: url)
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("qMD")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.6")
                .font(.body)
                .foregroundStyle(.secondary)

            Text("by b4ryon")
                .font(.callout)
                .foregroundStyle(.secondary)

            Link("github.com/b4ryon/qmd", destination: URL(string: "https://github.com/b4ryon/qmd")!)
                .font(.callout)

            Text("A simple, fast Markdown viewer for macOS")
                .font(.body)
                .multilineTextAlignment(.center)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Keyboard shortcuts:")
                    .font(.headline)
                    .padding(.bottom, 2)
                HStack {
                    Text("Left / Right arrow")
                        .fontWeight(.medium)
                    Spacer()
                    Text("Switch files")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Up / Down arrow")
                        .fontWeight(.medium)
                    Spacer()
                    Text("Scroll content")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Cmd+O")
                        .fontWeight(.medium)
                    Spacer()
                    Text("Open file or folder")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.callout)
            .padding(.horizontal)

            Divider()

            Text("Supports CommonMark, GFM tables, task lists, syntax highlighting")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Text("Released under the MIT License")
                .font(.caption2)
                .foregroundStyle(.quaternary)

            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 360)
    }
}
