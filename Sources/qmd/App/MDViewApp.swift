// qMD - Main application entry point
// Configures the SwiftUI app with multi-window support, menus, and file opening.
// Each main window owns its own AppState so multiple directories can be browsed
// side by side. The About panel is a dedicated Window scene, and menu-driven
// Open/New Window commands are dispatched to the focused window via NotificationCenter.

import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum QMDNotifications {
    static let openURLInKeyWindow = Notification.Name("qmd.openURLInKeyWindow")
    static let openURLPayloadKey = "url"
    static let zoomInKeyWindow = Notification.Name("qmd.zoomInKeyWindow")
    static let zoomOutKeyWindow = Notification.Name("qmd.zoomOutKeyWindow")
    static let zoomResetKeyWindow = Notification.Name("qmd.zoomResetKeyWindow")
}

@main
struct MDViewApp: App {
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
        }
        .commands {
            AppCommands()
        }

        Window("About qMD", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}

struct AppCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About qMD") {
                openWindow(id: "about")
            }
        }
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                openWindow(id: "main")
            }
            .keyboardShortcut("n", modifiers: [.command])

            Button("Open...") {
                openFileOrFolder(openWindow: openWindow)
            }
            .keyboardShortcut("o", modifiers: [.command])
        }
        // View > zoom controls. Routed via NotificationCenter so only the
        // focused main window (not the About window) handles the shortcut.
        CommandMenu("View") {
            Button("Make Text Bigger") {
                NotificationCenter.default.post(
                    name: QMDNotifications.zoomInKeyWindow, object: nil
                )
            }
            .keyboardShortcut("+", modifiers: [.command])

            Button("Make Text Smaller") {
                NotificationCenter.default.post(
                    name: QMDNotifications.zoomOutKeyWindow, object: nil
                )
            }
            .keyboardShortcut("-", modifiers: [.command])

            Button("Actual Size") {
                NotificationCenter.default.post(
                    name: QMDNotifications.zoomResetKeyWindow, object: nil
                )
            }
            .keyboardShortcut("0", modifiers: [.command])
        }
    }

    private func openFileOrFolder(openWindow: OpenWindowAction) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.message = "Open a Markdown file or folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        // If no main window exists, spawn one and hand it the URL.
        let hasMainWindow = NSApp.windows.contains { window in
            window.isVisible && window.identifier?.rawValue.contains("main") == true
        }
        if !hasMainWindow {
            openWindow(id: "main")
        }
        NotificationCenter.default.post(
            name: QMDNotifications.openURLInKeyWindow,
            object: nil,
            userInfo: [QMDNotifications.openURLPayloadKey: url]
        )
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            WelcomeImageView(maxWidth: 280, cornerRadius: 10)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            Text("qMD")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.7.7")
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
                    Text("Cmd+N")
                        .fontWeight(.medium)
                    Spacer()
                    Text("New window")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Cmd+O")
                        .fontWeight(.medium)
                    Spacer()
                    Text("Open file or folder")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Cmd+[ / Cmd+]")
                        .fontWeight(.medium)
                    Spacer()
                    Text("Back / Forward")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Cmd++ / Cmd+- / Cmd+0")
                        .fontWeight(.medium)
                    Spacer()
                    Text("Bigger / Smaller / Actual size")
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
