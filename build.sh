#!/bin/bash
set -e

# Configure
echo "Configuring..."
cmake -B build -S .

# Build
echo "Building..."
cmake --build build -j$(nproc)

echo "Build complete."
echo ""
echo "Unified binary: ./build/canvasdesk"
echo "  - Editor mode:  ./build/canvasdesk"
echo "  - Runtime mode: ./build/canvasdesk --runtime"
echo "  - Preview mode: ./build/canvasdesk --preview"
echo ""
echo "Legacy binaries (for testing):"
echo "  - Editor: ./build/src/editor/canvasdesk-editor"
echo "  - Runtime: ./build/src/app/canvasdesk-runtime"
