# vite-webgpu

Vite + WebGPU starter. Fullscreen triangle, single WGSL fragment shader, HMR on
the shader file. WGSL port of the canonical shader; output matches the WebGL2
starter pixel for pixel.

The WebGPU clip space puts the origin at the top-left, so the fragment stage
flips Y to match the bottom-left `fragCoord` convention used by Shadertoy.

## Run

```sh
npm install
npm run dev
```

Edit `src/shader.wgsl`. The Shadertoy uniforms are packed in `src/main.js`.

## Test

Renders one offscreen frame (256x256, `iTime=0`) headlessly with Playwright,
copies the texture to a buffer, maps it, and asserts against `../tools/ref.py`.
WebGPU is only exposed in a secure context, so the harness serves the page over
localhost.

```sh
npm install
npx playwright install chromium
npm test
```
