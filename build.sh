#!/bin/bash
set -e

# Configure
echo "Configuring..."
cmake -B build -S .

# Build
echo "Building..."
cmake --build build -j$(nproc)

echo "Build complete."
