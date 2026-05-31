# rust-wgpu

wgpu starter. Fullscreen triangle, single WGSL fragment shader (same port as
`vite-webgpu`), windowed live preview via winit. Output matches the other
environments pixel for pixel.

`@builtin(position)` has a top-left origin, so the fragment stage flips Y to
match the bottom-left `fragCoord` convention. The window uses a non-sRGB surface
format so the displayed colors match the raw shader output.

## Run

```sh
cargo run
```

## Test

Renders one frame (256x256, `iTime=0`) to an offscreen texture, copies it to a
buffer, maps it, writes a PPM, and asserts against `../tools/ref.py`.

```sh
cargo test
```

A headless one-shot render is also available:

```sh
cargo run --release -- 256 frame.ppm
```
