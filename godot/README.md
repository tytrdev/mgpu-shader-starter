# godot

Godot 4 `canvas_item` shader on a fullscreen `ColorRect`. Open the project and
run it (F5) for live preview; edits to `shader.gdshader` reload in the running
scene.

The Shadertoy uniforms are real shader `uniform`s, set each frame by
`uniforms.gd`. Godot's `FRAGCOORD` has a top-left origin, so the fragment stage
flips Y to match the bottom-left `fragCoord` convention.

## Run

```sh
godot --path . Main.tscn
```

Or open `project.godot` in the editor and press F5.

## Test

Renders one frame (256x256, `iTime=0`) to a `SubViewport`, saves a PNG, converts
it to PPM, and asserts against `../tools/ref.py`. Godot's `--headless` mode has
no GPU renderer, so the test opens a brief window to draw the frame.

```sh
./test.sh
```
