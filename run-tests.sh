#!/usr/bin/env bash
# Render one frame per environment (256x256, iTime=0) and assert sampled
# pixels against tools/ref.py. Skips environments whose toolchain is absent.
set -u

root="$(cd "$(dirname "$0")" && pwd)"
export PYTHONPATH="$root/tools"
res=256
pass=0; fail=0; skip=0

assert() { python3 "$root/tools/assert_frame.py" "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

run() {
  name="$1"; fn="$2"
  [ -d "$root/$name" ] || return
  printf '== %s ==\n' "$name"
  "$fn"; rc=$?
  case $rc in
    0) echo "PASS $name"; pass=$((pass+1));;
    77) echo "SKIP $name"; skip=$((skip+1));;
    *) echo "FAIL $name"; fail=$((fail+1));;
  esac
}

t_vite_webgl2() {
  have npm || return 77
  cd "$root/vite-webgl2" || return 1
  [ -d node_modules ] || npm install >/dev/null 2>&1 || return 1
  npm run --silent render -- "$res" >/dev/null || return 1
  assert frame.ppm
}

t_vite_webgpu() {
  have npm || return 77
  cd "$root/vite-webgpu" || return 1
  [ -d node_modules ] || npm install >/dev/null 2>&1 || return 1
  npm run --silent render -- "$res" >/dev/null || return 1
  assert frame.ppm
}

t_glslviewer() {
  have glslViewer || return 77
  cd "$root/glslviewer" || return 1
  glslViewer shader.frag -w "$res" -h "$res" --headless -E screenshot,frame.png >/dev/null 2>&1 || return 1
  python3 "$root/tools/png2ppm.py" frame.png frame.ppm || return 1
  assert frame.ppm
}

t_godot() {
  have godot || return 77
  cd "$root/godot" || return 1
  godot --headless --path . --script res://render.gd -- "$res" >/dev/null 2>&1 || return 1
  python3 "$root/tools/png2ppm.py" frame.png frame.ppm || return 1
  assert frame.ppm
}

t_rust_wgpu() {
  have cargo || return 77
  cd "$root/rust-wgpu" || return 1
  cargo run --quiet --release -- "$res" frame.ppm >/dev/null 2>&1 || return 1
  assert frame.ppm
}

t_c_raylib() {
  have make || return 77
  cd "$root/c-raylib" || return 1
  make render RES="$res" >/dev/null 2>&1 || return 77
  assert frame.ppm
}

t_zig_sokol() {
  have zig || return 77
  cd "$root/zig-sokol" || return 1
  zig build render -- "$res" frame.ppm >/dev/null 2>&1 || return 1
  assert frame.ppm
}

run vite-webgl2 t_vite_webgl2
run vite-webgpu t_vite_webgpu
run glslviewer  t_glslviewer
run godot       t_godot
run rust-wgpu   t_rust_wgpu
run c-raylib    t_c_raylib
run zig-sokol   t_zig_sokol

echo
echo "pass=$pass fail=$fail skip=$skip"
[ "$fail" -eq 0 ]
