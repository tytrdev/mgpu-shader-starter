# mgpu-shader-starter

Minimal shader starter environments for a YouTube series on GLSL shaping
functions. Every environment renders one fullscreen quad with a single
fragment shader and exposes Shadertoy-compatible uniforms (`iResolution`,
`iTime`, `iTimeDelta`, `iFrame`, `iMouse`), so shader code from the videos is
copy-paste portable across stacks. They all produce the identical "hello
uv-gradient cos" image, so you can diff one stack against another.

The canonical output is the default Shadertoy shader:

```glsl
vec2 uv = fragCoord/iResolution.xy;
vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
fragColor = vec4(col,1.0);
```

## Environments

| Folder | Stack | Tier |
| --- | --- | --- |
| `vite-webgl2` | Vite + WebGL2 | first-class |
| `vite-webgpu` | Vite + WebGPU (WGSL) | first-class |
| `glslviewer` | raw `.frag` + glslViewer | first-class |
| `godot` | Godot 4 ColorRect shader | supported |
| `rust-wgpu` | wgpu (WGSL) | supported |
| `c-raylib` | raylib GLSL | community |
| `zig-sokol` | Zig + sokol | community |

## Run

| Folder | Run | Test |
| --- | --- | --- |
| `vite-webgl2` | `npm install && npm run dev` | `npm test` |
| `vite-webgpu` | `npm install && npm run dev` | `npm test` |
| `glslviewer` | `glslViewer shader.frag` | `./test.sh` |
| `godot` | open `project.godot`, run | `./test.sh` |
| `rust-wgpu` | `cargo run` | `cargo test` |
| `c-raylib` | `make run` | `make test` |
| `zig-sokol` | `zig build run` | `zig build test` |

## Validation

Correctness is defined once in `tools/ref.py`, which evaluates the shader
formula at a given pixel. `tools/assert_frame.py` reads a rendered frame
(256x256, `iTime=0`) and checks center + corner pixels against the reference
within +/- 2/255.

Run every environment present on this machine:

```sh
./run-tests.sh
```

It renders one frame per folder, asserts the sampled pixels, and prints
pass/fail/skip per folder. Environments whose toolchain is not installed are
skipped. Assumes a real local GPU. No CI.
