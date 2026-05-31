# zig-sokol

Zig + [sokol](https://github.com/floooh/sokol-zig) starter. Fullscreen triangle,
single fragment shader. Community/stretch tier.

The build forces the GL backend (`.gl = true`) so the shader can be supplied as
plain GLSL (no sokol-shdc step), `gl_FragCoord` keeps the bottom-left origin
matching Shadertoy, and the headless test can read pixels with `glReadPixels`.
The Shadertoy uniforms live in a `std140` uniform block.

## Setup

```sh
zig fetch --save git+https://github.com/floooh/sokol-zig.git
```

## Run

```sh
zig build run
```

## Test

Renders one frame (256x256, `iTime=0`), reads it back, writes a PPM, and asserts
against `../tools/ref.py`.

```sh
zig build test
```
