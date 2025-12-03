#!/bin/bash
echo "Testing Window Management Detection"
echo "===================================="
echo ""
echo "Compositor: $XDG_CURRENT_DESKTOP"
echo "Session type: $XDG_SESSION_TYPE"
echo "Wayland display: $WAYLAND_DISPLAY"
echo ""
echo "Running CanvasDesk..."
echo "====================================

"

./build/canvasdesk --runtime 2>&1 | tee /tmp/canvasdesk-wm-test.log &
CANVASDESK_PID=$!

echo "CanvasDesk PID: $CANVASDESK_PID"
sleep 3

echo ""
echo "Stopping CanvasDesk..."
kill -TERM $CANVASDESK_PID 2>/dev/null
wait $CANVASDESK_PID 2>/dev/null

echo ""
echo "===================================="
echo "Log output:"
echo "===================================="
cat /tmp/canvasdesk-wm-test.log | grep -E "(WindowManager|Taskbar|Trying|available|Using|===|wlr|ext_foreign)"
