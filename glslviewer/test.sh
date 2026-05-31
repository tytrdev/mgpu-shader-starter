#!/usr/bin/env bash
# Render one headless frame (256x256, iTime=0) and assert sampled pixels.
set -eu
cd "$(dirname "$0")"
res="${1:-256}"
command -v glslViewer >/dev/null 2>&1 || { echo "glslViewer not found"; exit 77; }
glslViewer shader.frag -w "$res" -h "$res" -s 0 --headless -o frame.png
python3 ../tools/png2ppm.py frame.png frame.ppm
python3 ../tools/assert_frame.py frame.ppm
