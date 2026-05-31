#ifdef GL_ES
precision highp float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform float u_delta;
uniform int u_frame;

#define iResolution vec3(u_resolution, 1.0)
#define iTime u_time
#define iTimeDelta u_delta
#define iFrame u_frame
#define iMouse vec4(u_mouse, 0.0, 0.0)

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord/iResolution.xy;
    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
    fragColor = vec4(col,1.0);
}

void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
