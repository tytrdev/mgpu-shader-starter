// Headless one-frame render to a binary PPM (P6) for validation.
// Usage: node render.mjs [resolution] [outfile]
import { readFileSync, writeFileSync } from "node:fs";
import { chromium } from "playwright";

const res = parseInt(process.argv[2] || "256", 10);
const out = process.argv[3] || "frame.ppm";
const vertSrc = readFileSync(new URL("./src/vertex.glsl", import.meta.url), "utf8");
const fragSrc = readFileSync(new URL("./src/shader.frag", import.meta.url), "utf8");

const browser = await chromium.launch();
const page = await browser.newPage();
page.on("console", (m) => console.error("page:", m.text()));

const pixels = await page.evaluate(
  ({ vertSrc, fragSrc, res }) => {
    const cv = new OffscreenCanvas(res, res);
    const gl = cv.getContext("webgl2", { antialias: false, preserveDrawingBuffer: true });
    const sh = (type, src) => {
      const s = gl.createShader(type);
      gl.shaderSource(s, src);
      gl.compileShader(s);
      if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s));
      return s;
    };
    const p = gl.createProgram();
    gl.attachShader(p, sh(gl.VERTEX_SHADER, vertSrc));
    gl.attachShader(p, sh(gl.FRAGMENT_SHADER, fragSrc));
    gl.linkProgram(p);
    if (!gl.getProgramParameter(p, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(p));
    gl.useProgram(p);
    gl.viewport(0, 0, res, res);
    gl.uniform3f(gl.getUniformLocation(p, "iResolution"), res, res, 1);
    gl.uniform1f(gl.getUniformLocation(p, "iTime"), 0);
    gl.uniform1f(gl.getUniformLocation(p, "iTimeDelta"), 0);
    gl.uniform1i(gl.getUniformLocation(p, "iFrame"), 0);
    gl.uniform4f(gl.getUniformLocation(p, "iMouse"), 0, 0, 0, 0);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    const buf = new Uint8Array(res * res * 4);
    gl.readPixels(0, 0, res, res, gl.RGBA, gl.UNSIGNED_BYTE, buf);
    return Array.from(buf);
  },
  { vertSrc, fragSrc, res }
);

await browser.close();

// readPixels is bottom-first; PPM is written top-first.
const rgb = Buffer.alloc(res * res * 3);
for (let row = 0; row < res; row++) {
  const src = (res - 1 - row) * res * 4;
  for (let x = 0; x < res; x++) {
    const di = (row * res + x) * 3;
    const si = src + x * 4;
    rgb[di] = pixels[si];
    rgb[di + 1] = pixels[si + 1];
    rgb[di + 2] = pixels[si + 2];
  }
}
writeFileSync(out, Buffer.concat([Buffer.from(`P6\n${res} ${res}\n255\n`), rgb]));
console.error(`wrote ${out}`);
