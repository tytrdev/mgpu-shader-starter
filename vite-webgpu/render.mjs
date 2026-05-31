// Headless one-frame render to a binary PPM (P6) for validation.
// WebGPU is only exposed in a secure context, so we serve over localhost.
// Usage: node render.mjs [resolution] [outfile]
import http from "node:http";
import { readFileSync, writeFileSync } from "node:fs";
import { chromium } from "playwright";

const res = parseInt(process.argv[2] || "256", 10);
const out = process.argv[3] || "frame.ppm";
const shaderSrc = readFileSync(new URL("./src/shader.wgsl", import.meta.url), "utf8");

const server = http
  .createServer((_, r) => {
    r.setHeader("content-type", "text/html");
    r.end("<!doctype html><html><body></body></html>");
  })
  .listen(0);
await new Promise((r) => server.once("listening", r));
const url = `http://localhost:${server.address().port}/`;

const browser = await chromium.launch({
  channel: "chromium",
  args: ["--enable-unsafe-webgpu", "--enable-features=Vulkan"],
});
const page = await browser.newPage();
page.on("console", (m) => console.error("page:", m.text()));
await page.goto(url);

const result = await page.evaluate(
  async ({ shaderSrc, res }) => {
    if (!navigator.gpu) return { skip: "no navigator.gpu" };
    const adapter = await navigator.gpu.requestAdapter();
    if (!adapter) return { skip: "no adapter" };
    const device = await adapter.requestDevice();
    const format = "rgba8unorm";

    const tex = device.createTexture({
      size: [res, res],
      format,
      usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC,
    });
    const ubo = device.createBuffer({ size: 48, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
    const ab = new ArrayBuffer(48);
    const f = new Float32Array(ab);
    f[0] = res; f[1] = res; f[2] = 1; f[3] = 0;
    device.queue.writeBuffer(ubo, 0, ab);

    const module = device.createShaderModule({ code: shaderSrc });
    const pipeline = device.createRenderPipeline({
      layout: "auto",
      vertex: { module, entryPoint: "vs" },
      fragment: { module, entryPoint: "fs", targets: [{ format }] },
      primitive: { topology: "triangle-list" },
    });
    const bind = device.createBindGroup({
      layout: pipeline.getBindGroupLayout(0),
      entries: [{ binding: 0, resource: { buffer: ubo } }],
    });

    const bpr = Math.ceil((res * 4) / 256) * 256;
    const readback = device.createBuffer({ size: bpr * res, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });

    const enc = device.createCommandEncoder();
    const pass = enc.beginRenderPass({
      colorAttachments: [{ view: tex.createView(), loadOp: "clear", storeOp: "store", clearValue: { r: 0, g: 0, b: 0, a: 1 } }],
    });
    pass.setPipeline(pipeline);
    pass.setBindGroup(0, bind);
    pass.draw(3);
    pass.end();
    enc.copyTextureToBuffer({ texture: tex }, { buffer: readback, bytesPerRow: bpr }, [res, res]);
    device.queue.submit([enc.finish()]);
    await readback.mapAsync(GPUMapMode.READ);
    const bytes = new Uint8Array(readback.getMappedRange()).slice();
    return { bpr, bytes: Array.from(bytes) };
  },
  { shaderSrc, res }
);

await browser.close();
server.close();

if (result.skip) {
  console.error("skip:", result.skip);
  process.exit(77);
}

// WebGPU texture row 0 is the top; PPM is top-first too. No flip.
const { bpr, bytes } = result;
const rgb = Buffer.alloc(res * res * 3);
for (let row = 0; row < res; row++) {
  for (let x = 0; x < res; x++) {
    const si = row * bpr + x * 4;
    const di = (row * res + x) * 3;
    rgb[di] = bytes[si];
    rgb[di + 1] = bytes[si + 1];
    rgb[di + 2] = bytes[si + 2];
  }
}
writeFileSync(out, Buffer.concat([Buffer.from(`P6\n${res} ${res}\n255\n`), rgb]));
console.error(`wrote ${out}`);
