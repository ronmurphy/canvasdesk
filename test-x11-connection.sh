#!/bin/bash
# Quick test to verify CanvasDesk can connect to X11
# Run this in your current session before logging out

echo "=== X11 Connection Test for CanvasDesk ==="
echo ""
echo "Current environment:"
echo "  DISPLAY: $DISPLAY"
echo "  XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
echo "  QT_QPA_PLATFORM: $QT_QPA_PLATFORM"
echo ""

# Test if X11 is accessible
if [ -z "$DISPLAY" ]; then
    echo "❌ ERROR: DISPLAY not set (not in an X11 or Xwayland session)"
    exit 1
fi

echo "✓ DISPLAY is set"
echo ""

# Try to connect with a simple X11 tool
if command -v xdpyinfo &> /dev/null; then
    echo "Testing X11 connection with xdpyinfo..."
    if xdpyinfo -display "$DISPLAY" &> /dev/null; then
        echo "✓ X11 connection successful"
        echo ""
        echo "Display info:"
        xdpyinfo -display "$DISPLAY" | head -10
    else
        echo "❌ Failed to connect to display $DISPLAY"
        exit 1
    fi
else
    echo "⚠ xdpyinfo not installed (install with: sudo pacman -S xorg-xdpyinfo)"
fi

echo ""
echo "=== Now testing CanvasDesk X11WindowManager ==="
echo ""

# Set Qt to use XCB (X11) platform
export QT_QPA_PLATFORM=xcb

# Get the canvasdesk binary path
CANVASDESK_BIN="$(dirname "$0")/build/canvasdesk"

if [ ! -f "$CANVASDESK_BIN" ]; then
    echo "❌ CanvasDesk binary not found at: $CANVASDESK_BIN"
    exit 1
fi

echo "Attempting to launch CanvasDesk in runtime mode..."
echo "NOTE: This will FAIL because another window manager (KWin/etc) is already running."
echo "But we should see X11 connection attempt in the output."
echo ""
echo "Press Ctrl+C to stop if it hangs..."
echo ""

# Run with timeout - it will fail to become WM but should connect to X11
timeout 5 "$CANVASDESK_BIN" --runtime 2>&1 | head -50

echo ""
echo "=== Test Complete ==="
echo ""
echo "Expected results:"
echo "  ✓ Should see X11 connection messages (not 'could not connect to display')"
echo "  ✓ Should see error about 'another window manager already running'"
echo "  ❌ Should NOT see Qt platform plugin errors"
echo ""
echo "If you saw the above, then X11 connection works!"
echo "Next step: Log out and select 'CanvasDesk' session from login screen"
