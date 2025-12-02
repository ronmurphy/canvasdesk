#!/bin/bash
cd src/editor
./canvasdesk-editor &
EDITOR_PID=$!
sleep 2
# Editor should be running, now close it
kill $EDITOR_PID 2>/dev/null
wait $EDITOR_PID 2>/dev/null || true
