# glslviewer

Raw fragment shader, no JS, no build. Edit `shader.frag` and
[glslViewer](https://github.com/patriciogonzalezvivo/glslViewer) hot-reloads it
on save.

glslViewer feeds its own `u_resolution`, `u_time`, `u_delta`, `u_frame`, and
`u_mouse`. The top of `shader.frag` maps those to the exact Shadertoy names
(`iResolution`, `iTime`, `iTimeDelta`, `iFrame`, `iMouse`) so the shader body is
identical to the other environments.

## Run

```sh
glslViewer shader.frag
```

## Test

Renders one headless frame (256x256, `iTime=0`) to a PNG, converts it to PPM,
and asserts against `../tools/ref.py`.

```sh
./test.sh
```
