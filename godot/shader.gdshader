shader_type canvas_item;

uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 uv = fragCoord/iResolution.xy;
	vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
	fragColor = vec4(col,1.0);
}

void fragment() {
	vec2 fragCoord = vec2(FRAGCOORD.x, iResolution.y - FRAGCOORD.y);
	vec4 c;
	mainImage(c, fragCoord);
	COLOR = c;
}
