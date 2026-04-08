# qMD

A simple, fast Markdown viewer for macOS.

qMD renders Markdown files with syntax highlighting, live reload, and a sidebar file tree for browsing folders. Built natively with Swift and SwiftUI.

## Features

- Folder browsing with recursive sidebar tree
- Syntax highlighting for code blocks
- Live reload on file save
- In-document search (Cmd+F)
- Dark and light mode (follows system appearance)
- GFM tables, task lists, and raw HTML
- Keyboard navigation (arrow keys to switch files and scroll)
- Drag and drop to open files or folders

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
| Cmd+O | Open file or folder |
| Cmd+F | Find in document |
| Left/Right arrow | Switch between files |
| Up/Down arrow | Scroll content |
| Escape | Close search bar |

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
