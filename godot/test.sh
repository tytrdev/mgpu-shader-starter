#!/usr/bin/env bash
# Render one frame (256x256, iTime=0) headlessly and assert sampled pixels.
set -eu
cd "$(dirname "$0")"
res="${1:-256}"
command -v godot >/dev/null 2>&1 || { echo "godot not found"; exit 77; }
godot --headless --path . --script res://render.gd -- "$res" frame.png
python3 ../tools/png2ppm.py frame.png frame.ppm
python3 ../tools/assert_frame.py frame.ppm
