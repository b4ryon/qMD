# qMD

A simple, fast Markdown viewer for macOS.

qMD renders Markdown files with syntax highlighting, live reload, and a sidebar file tree for browsing folders. Built natively with Swift and SwiftUI.

## Features

- Folder browsing with recursive sidebar tree
- Syntax highlighting for code blocks
- Live reload on file save (scroll position is preserved across reloads)
- In-document search (Cmd+F)
- 8 built-in color themes: System (default), Midnight, Daylight, Solarized Dark, Solarized Light, Dracula, Nord, Tokyo Night. Theme applies to both the rendered Markdown and the surrounding window chrome, persists across launches, and propagates to all open windows.
- Obsidian-style `==highlight==` syntax rendered as a yellow marker, including across inline code, bold/italic, and links
- Multi-window support (Cmd+N), with each window remembering its own folder and zoom
- In-window navigation history for Markdown-to-Markdown links, with back/forward arrows (Cmd+[ / Cmd+]) above the document
- Per-window font zoom (Cmd++ / Cmd+- / Cmd+0)
- GFM tables, task lists, and raw HTML
- Keyboard navigation (arrow keys to switch files and scroll)
- Drag and drop to open files or folders
- Welcome screen with branding when no document is open

## Requirements

- macOS 14.0 (Sonoma) or later

## Install

Download the `.pkg` installer for your architecture from the [Releases](https://github.com/b4ryon/qmd/releases) page and run it. The app installs to `/Applications`.

Alternatively, download the `.zip`, extract it, and drag `qMD.app` to your Applications folder.

### Determining your Mac's architecture

- **Apple Silicon** (M1, M2, M3, M4): download the `arm64` package
- **Intel**: download the `x86_64` package

To check: Apple menu > About This Mac > Chip. If it says "Apple M...", use arm64. Otherwise use x86_64.

## Build from source

```bash
git clone https://github.com/b4ryon/qmd.git
cd qmd
make build
make run
```

## Keyboard shortcuts

| Key | Action |
|---|---|
| Cmd+N | New window |
| Cmd+O | Open file or folder |
| Cmd+F | Find in document |
| Cmd+[ / Cmd+] | Back / Forward (link history) |
| Cmd++ / Cmd+- / Cmd+0 | Make text bigger / smaller / actual size |
| Left/Right arrow | Switch between files |
| Up/Down arrow | Scroll content |
| Escape | Close search bar |

Themes can be picked from the **View > Theme** submenu.

## License

Released under the [MIT License](LICENSE).

## Unsigned app notice

qMD is not signed with an Apple Developer certificate. On first launch, macOS Gatekeeper will block the app. To open it:

0. Right-click (or Control-click) on `qMD.app`
1. Select "Open" from the context menu
2. Click "Open" in the dialog that appears

This only needs to be done once. Alternatively, run from the terminal:

```bash
xattr -cr /Applications/qMD.app
```
