# vite-webgl2

Vite + WebGL2 starter. Fullscreen triangle, single fragment shader, HMR on the
shader file.

## Run

```sh
npm install
npm run dev
```

Edit `src/shader.frag`. The Shadertoy uniforms are wired in `src/main.js`.

## Test

Renders one offscreen frame (256x256, `iTime=0`) headlessly with Playwright,
reads the pixels back, and asserts against `../tools/ref.py`.

```sh
npm install
npx playwright install chromium
npm test
```
