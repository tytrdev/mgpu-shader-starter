import vertSrc from "./vertex.glsl?raw";
import fragSrc from "./shader.frag?raw";

const canvas = document.getElementById("c");
const gl = canvas.getContext("webgl2", { antialias: false });
if (!gl) throw new Error("WebGL2 not available");

function compile(type, src) {
  const s = gl.createShader(type);
  gl.shaderSource(s, src);
  gl.compileShader(s);
  if (!gl.getShaderParameter(s, gl.COMPILE_STATUS))
    throw new Error(gl.getShaderInfoLog(s));
  return s;
}

let program, loc;
function build(frag) {
  const p = gl.createProgram();
  gl.attachShader(p, compile(gl.VERTEX_SHADER, vertSrc));
  gl.attachShader(p, compile(gl.FRAGMENT_SHADER, frag));
  gl.linkProgram(p);
  if (!gl.getProgramParameter(p, gl.LINK_STATUS))
    throw new Error(gl.getProgramInfoLog(p));
  if (program) gl.deleteProgram(program);
  program = p;
  loc = {
    iResolution: gl.getUniformLocation(p, "iResolution"),
    iTime: gl.getUniformLocation(p, "iTime"),
    iTimeDelta: gl.getUniformLocation(p, "iTimeDelta"),
    iFrame: gl.getUniformLocation(p, "iFrame"),
    iMouse: gl.getUniformLocation(p, "iMouse"),
  };
}
build(fragSrc);

const mouse = [0, 0, 0, 0];
canvas.addEventListener("mousedown", (e) => {
  mouse[2] = e.offsetX;
  mouse[3] = canvas.height - e.offsetY;
});
canvas.addEventListener("mouseup", () => (mouse[2] = mouse[3] = 0));
canvas.addEventListener("mousemove", (e) => {
  if (e.buttons & 1) {
    mouse[0] = e.offsetX;
    mouse[1] = canvas.height - e.offsetY;
  }
});

let frame = 0;
let last = 0;
function render(now) {
  const t = now * 0.001;
  const dt = last ? t - last : 0;
  last = t;

  const w = (canvas.width = canvas.clientWidth);
  const h = (canvas.height = canvas.clientHeight);
  gl.viewport(0, 0, w, h);

  gl.useProgram(program);
  gl.uniform3f(loc.iResolution, w, h, 1);
  gl.uniform1f(loc.iTime, t);
  gl.uniform1f(loc.iTimeDelta, dt);
  gl.uniform1i(loc.iFrame, frame++);
  gl.uniform4f(loc.iMouse, mouse[0], mouse[1], mouse[2], mouse[3]);
  gl.drawArrays(gl.TRIANGLES, 0, 3);

  requestAnimationFrame(render);
}
requestAnimationFrame(render);

if (import.meta.hot) {
  import.meta.hot.accept("./shader.frag?raw", (m) => build(m.default));
}
