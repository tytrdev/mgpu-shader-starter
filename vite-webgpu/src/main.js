import shaderSrc from "./shader.wgsl?raw";

const canvas = document.getElementById("c");
if (!navigator.gpu) throw new Error("WebGPU not available");
const adapter = await navigator.gpu.requestAdapter();
const device = await adapter.requestDevice();
const ctx = canvas.getContext("webgpu");
const format = navigator.gpu.getPreferredCanvasFormat();
ctx.configure({ device, format, alphaMode: "opaque" });

const ubo = device.createBuffer({
  size: 48,
  usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
});

let pipeline, bind;
function build(src) {
  const module = device.createShaderModule({ code: src });
  pipeline = device.createRenderPipeline({
    layout: "auto",
    vertex: { module, entryPoint: "vs" },
    fragment: { module, entryPoint: "fs", targets: [{ format }] },
    primitive: { topology: "triangle-list" },
  });
  bind = device.createBindGroup({
    layout: pipeline.getBindGroupLayout(0),
    entries: [{ binding: 0, resource: { buffer: ubo } }],
  });
}
build(shaderSrc);

// iResolution vec3 @0, iTime @12, iMouse vec4 @16, iTimeDelta @32, iFrame @36
function writeUniforms(w, h, t, dt, frame, mouse) {
  const ab = new ArrayBuffer(48);
  const f = new Float32Array(ab);
  const i = new Int32Array(ab);
  f[0] = w; f[1] = h; f[2] = 1; f[3] = t;
  f[4] = mouse[0]; f[5] = mouse[1]; f[6] = mouse[2]; f[7] = mouse[3];
  f[8] = dt; i[9] = frame;
  device.queue.writeBuffer(ubo, 0, ab);
}

const mouse = [0, 0, 0, 0];
canvas.addEventListener("mousedown", (e) => { mouse[2] = e.offsetX; mouse[3] = canvas.height - e.offsetY; });
canvas.addEventListener("mouseup", () => (mouse[2] = mouse[3] = 0));
canvas.addEventListener("mousemove", (e) => {
  if (e.buttons & 1) { mouse[0] = e.offsetX; mouse[1] = canvas.height - e.offsetY; }
});

let frame = 0, last = 0;
function render(now) {
  const t = now * 0.001;
  const dt = last ? t - last : 0;
  last = t;
  const w = (canvas.width = canvas.clientWidth);
  const h = (canvas.height = canvas.clientHeight);
  writeUniforms(w, h, t, dt, frame++, mouse);

  const enc = device.createCommandEncoder();
  const pass = enc.beginRenderPass({
    colorAttachments: [{
      view: ctx.getCurrentTexture().createView(),
      loadOp: "clear", storeOp: "store", clearValue: { r: 0, g: 0, b: 0, a: 1 },
    }],
  });
  pass.setPipeline(pipeline);
  pass.setBindGroup(0, bind);
  pass.draw(3);
  pass.end();
  device.queue.submit([enc.finish()]);
  requestAnimationFrame(render);
}
requestAnimationFrame(render);

if (import.meta.hot) {
  import.meta.hot.accept("./shader.wgsl?raw", (m) => build(m.default));
}
