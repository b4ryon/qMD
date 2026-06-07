// qMD - Theme palette registry
// Defines named color schemes for the markdown viewer. Each theme is rendered
// as a CSS override block applied after style.css. The System theme keeps the
// existing prefers-color-scheme behavior - no overrides emitted.

import Foundation

enum ThemeAppearance: String {
    case system
    case dark
    case light
}

struct Theme: Identifiable, Hashable {
    let id: String
    let displayName: String
    let appearance: ThemeAppearance
    let bodyBg: String?
    let bodyFg: String?
    let linkColor: String?
    let blockquoteBorder: String?
    let blockquoteFg: String?
    let tableBorder: String?
    let tableAltBg: String?
    let hrColor: String?
    let codeBg: String?
    let preBg: String?
    let preBorder: String?
    let markBg: String?
    let markFg: String?

    static let system = Theme(
        id: "system",
        displayName: "System (Default)",
        appearance: .system,
        bodyBg: nil, bodyFg: nil, linkColor: nil,
        blockquoteBorder: nil, blockquoteFg: nil,
        tableBorder: nil, tableAltBg: nil, hrColor: nil,
        codeBg: nil, preBg: nil, preBorder: nil,
        markBg: nil, markFg: nil
    )

    static let midnight = Theme(
        id: "midnight",
        displayName: "Midnight",
        appearance: .dark,
        bodyBg: "#000000",
        bodyFg: "#e0e0e0",
        linkColor: "#3ea6ff",
        blockquoteBorder: "#333333",
        blockquoteFg: "#aaaaaa",
        tableBorder: "#2a2a2a",
        tableAltBg: "#0a0a0a",
        hrColor: "#222222",
        codeBg: "rgba(255,255,255,0.08)",
        preBg: "#0a0a0a",
        preBorder: "#222222",
        markBg: "rgba(255, 235, 59, 0.35)",
        markFg: "#f5e9b0"
    )

    static let daylight = Theme(
        id: "daylight",
        displayName: "Daylight",
        appearance: .light,
        bodyBg: "#ffffff",
        bodyFg: "#1a1a1a",
        linkColor: "#0066cc",
        blockquoteBorder: "#cccccc",
        blockquoteFg: "#666666",
        tableBorder: "#dddddd",
        tableAltBg: "#f7f7f7",
        hrColor: "#e0e0e0",
        codeBg: "rgba(0,0,0,0.06)",
        preBg: "#f5f5f5",
        preBorder: "#e0e0e0",
        markBg: "rgba(255, 224, 102, 0.65)",
        markFg: "#1f2328"
    )

    static let solarizedDark = Theme(
        id: "solarizedDark",
        displayName: "Solarized Dark",
        appearance: .dark,
        bodyBg: "#002b36",
        bodyFg: "#93a1a1",
        linkColor: "#268bd2",
        blockquoteBorder: "#073642",
        blockquoteFg: "#586e75",
        tableBorder: "#073642",
        tableAltBg: "#073642",
        hrColor: "#073642",
        codeBg: "rgba(7,54,66,0.6)",
        preBg: "#073642",
        preBorder: "#0e4b58",
        markBg: "rgba(181, 137, 0, 0.5)",
        markFg: "#fdf6e3"
    )

    static let solarizedLight = Theme(
        id: "solarizedLight",
        displayName: "Solarized Light",
        appearance: .light,
        bodyBg: "#fdf6e3",
        bodyFg: "#586e75",
        linkColor: "#268bd2",
        blockquoteBorder: "#eee8d5",
        blockquoteFg: "#93a1a1",
        tableBorder: "#eee8d5",
        tableAltBg: "#f5efd9",
        hrColor: "#eee8d5",
        codeBg: "rgba(238,232,213,0.7)",
        preBg: "#eee8d5",
        preBorder: "#e5dfc6",
        markBg: "rgba(181, 137, 0, 0.4)",
        markFg: "#073642"
    )

    static let dracula = Theme(
        id: "dracula",
        displayName: "Dracula",
        appearance: .dark,
        bodyBg: "#282a36",
        bodyFg: "#f8f8f2",
        linkColor: "#8be9fd",
        blockquoteBorder: "#44475a",
        blockquoteFg: "#bd93f9",
        tableBorder: "#44475a",
        tableAltBg: "#21222c",
        hrColor: "#44475a",
        codeBg: "rgba(68, 71, 90, 0.5)",
        preBg: "#21222c",
        preBorder: "#44475a",
        markBg: "rgba(241, 250, 140, 0.45)",
        markFg: "#282a36"
    )

    static let nord = Theme(
        id: "nord",
        displayName: "Nord",
        appearance: .dark,
        bodyBg: "#2e3440",
        bodyFg: "#d8dee9",
        linkColor: "#88c0d0",
        blockquoteBorder: "#3b4252",
        blockquoteFg: "#81a1c1",
        tableBorder: "#3b4252",
        tableAltBg: "#3b4252",
        hrColor: "#3b4252",
        codeBg: "rgba(59, 66, 82, 0.6)",
        preBg: "#3b4252",
        preBorder: "#4c566a",
        markBg: "rgba(235, 203, 139, 0.4)",
        markFg: "#eceff4"
    )

    static let tokyoNight = Theme(
        id: "tokyoNight",
        displayName: "Tokyo Night",
        appearance: .dark,
        bodyBg: "#1a1b26",
        bodyFg: "#a9b1d6",
        linkColor: "#7aa2f7",
        blockquoteBorder: "#414868",
        blockquoteFg: "#9aa5ce",
        tableBorder: "#414868",
        tableAltBg: "#16161e",
        hrColor: "#414868",
        codeBg: "rgba(65, 72, 104, 0.6)",
        preBg: "#16161e",
        preBorder: "#414868",
        markBg: "rgba(224, 175, 104, 0.4)",
        markFg: "#c0caf5"
    )

    static let all: [Theme] = [
        .system,
        .midnight,
        .daylight,
        .solarizedDark,
        .solarizedLight,
        .dracula,
        .nord,
        .tokyoNight
    ]

    static func byID(_ id: String) -> Theme {
        all.first { $0.id == id } ?? .system
    }
}
