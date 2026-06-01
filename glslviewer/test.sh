#!/usr/bin/env bash
# Render one headless frame at iTime=0 and assert sampled pixels.
# `sequence,A,B` renders at simulation seconds (deterministic), unlike a
# startup screenshot which captures whatever wall-clock time has elapsed.
set -eu
cd "$(dirname "$0")"
res="${1:-256}"
command -v glslViewer >/dev/null 2>&1 || { echo "glslViewer not found"; exit 77; }

rm -f 00000.png frame.ppm
glslViewer shader.frag -w "$res" -h "$res" --headless --noncurses -E "sequence,0,0" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 100); do
  [ -f 00000.png ] && break
  sleep 0.1
done
sleep 0.2
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true

[ -f 00000.png ] || { echo "no frame produced"; exit 1; }
python3 ../tools/png2ppm.py 00000.png frame.ppm
python3 ../tools/assert_frame.py frame.ppm
