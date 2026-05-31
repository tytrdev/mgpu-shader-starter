# c-raylib

raylib starter. Single GLSL fragment shader drawn over a fullscreen rectangle.
Community tier: needs raylib installed (`brew install raylib`,
`pkg-config` aware).

The Shadertoy uniforms are custom shader uniforms set with `SetShaderValue`.
`gl_FragCoord` is bottom-left, matching the Shadertoy convention directly.

## Run

```sh
make run
```

## Test

Renders one frame (256x256, `iTime=0`) into a `RenderTexture2D`, reads it back
with `LoadImageFromTexture`, writes a PPM, and asserts against `../tools/ref.py`.
Render textures are stored bottom-first, so the rows are flipped on write.

```sh
make test
```
