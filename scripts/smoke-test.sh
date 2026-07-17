#!/bin/bash
# qMD - Launch smoke test for a built .app bundle.
# Guards against the v1.7.2 class of release bug: an app that builds fine but
# crashes at first launch on end-user machines because resources only resolve
# on the build machine. The bundle is copied OUTSIDE the repo before launch so
# that repo-relative or hardcoded .build paths cannot mask a broken bundle,
# then opened with a markdown document (the same LaunchServices flow that
# triggered the v1.7.2 crash) and required to stay alive.
#
# Usage: scripts/smoke-test.sh [path/to/qMD.app]   (default: ./qMD.app)

set -u

APP_SRC="${1:-qMD.app}"
APP_NAME="qmd"
ALIVE_SECONDS=5
FAIL=0

err() { echo "Error: $*" >&2; FAIL=1; }

if [ ! -d "$APP_SRC" ]; then
    echo "Error: app bundle not found: $APP_SRC" >&2
    exit 1
fi

echo "Smoke test: $APP_SRC"

# --- Static checks: bundle completeness -------------------------------------
BUNDLE_RES="$APP_SRC/Contents/Resources/qmd_qmd.bundle"
REQUIRED_FILES=(
    "$APP_SRC/Contents/Info.plist"
    "$APP_SRC/Contents/MacOS/$APP_NAME"
    "$APP_SRC/Contents/Resources/AppIcon.icns"
    "$BUNDLE_RES/qmd.welcome.png"
    "$BUNDLE_RES/web/markdown-it.min.js"
    "$BUNDLE_RES/web/highlight.min.js"
    "$BUNDLE_RES/web/github.min.css"
    "$BUNDLE_RES/web/github-dark.min.css"
    "$BUNDLE_RES/web/style.css"
)
for f in "${REQUIRED_FILES[@]}"; do
    [ -f "$f" ] || err "missing from bundle: $f"
done

# --- Static checks: binary hygiene -------------------------------------------
# SwiftPM's Bundle.module accessor embeds this fatalError string; its presence
# means resource lookup can trap at launch on user machines (v1.7.2 crash).
BIN="$APP_SRC/Contents/MacOS/$APP_NAME"
if strings "$BIN" | grep -q 'could not load resource bundle'; then
    err "binary contains SwiftPM's Bundle.module trap (resource_bundle_accessor fatalError)"
fi
if strings "$BIN" | grep -q "$HOME/.*/\.build"; then
    err "binary embeds an absolute .build path from this machine"
fi

if [ "$FAIL" -ne 0 ]; then
    echo "Smoke test FAILED (static checks)." >&2
    exit 1
fi
echo "[OK] bundle contents and binary hygiene"

# --- Dynamic check: launch outside the repo with a markdown document ---------
mkdir -p "$HOME/tmp"
STAGE=$(mktemp -d "$HOME/tmp/qmd-smoke-XXXXXX")
trap 'rm -rf "$STAGE"' EXIT

ditto "$APP_SRC" "$STAGE/qMD.app"
printf '# smoke test\n\nhello **world**\n\n- item\n' > "$STAGE/smoke.md"

CRASH_MARKER="$STAGE/crash-marker"
touch "$CRASH_MARKER"

open -n -a "$STAGE/qMD.app" "$STAGE/smoke.md" || { echo "Error: open failed" >&2; exit 1; }

# The app must stay alive for the full window; the v1.7.2 bug killed it
# within the first second of window creation.
sleep 2
PID=$(pgrep -f "$STAGE/qMD.app/Contents/MacOS/$APP_NAME" | head -1)
if [ -z "$PID" ]; then
    echo "Error: app process not found after launch" >&2
    exit 1
fi
sleep "$ALIVE_SECONDS"
if ! kill -0 "$PID" 2>/dev/null; then
    echo "Error: app died within ${ALIVE_SECONDS}s of launch" >&2
    exit 1
fi

kill "$PID" 2>/dev/null
sleep 1

NEW_CRASHES=$(find "$HOME/Library/Logs/DiagnosticReports" -name "${APP_NAME}-*" -newer "$CRASH_MARKER" 2>/dev/null | wc -l | tr -d ' ')
if [ "$NEW_CRASHES" -ne 0 ]; then
    echo "Error: crash report(s) written during smoke test:" >&2
    find "$HOME/Library/Logs/DiagnosticReports" -name "${APP_NAME}-*" -newer "$CRASH_MARKER" >&2
    exit 1
fi

echo "[OK] app launched with a markdown document and stayed alive"
echo "Smoke test PASSED."
