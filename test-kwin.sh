#!/bin/bash
# Test script to check KWin Plasma Window Management protocol

echo "================================"
echo "Testing CanvasDesk with KWin"
echo "================================"
echo ""
echo "Environment:"
echo "  WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
echo "  XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
echo "  DESKTOP_SESSION: $DESKTOP_SESSION"
echo ""
echo "Running CanvasDesk..."
echo "================================"
echo ""

# Run with all debug output
QT_LOGGING_RULES="*.debug=true" ./build/canvasdesk --runtime

echo ""
echo "================================"
echo "Test completed"
echo "================================"
