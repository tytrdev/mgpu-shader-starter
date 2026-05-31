struct Uniforms {
    iResolution: vec3<f32>,
    iTime: f32,
    iMouse: vec4<f32>,
    iTimeDelta: f32,
    iFrame: i32,
};

@group(0) @binding(0) var<uniform> u: Uniforms;

@vertex
fn vs(@builtin(vertex_index) vi: u32) -> @builtin(position) vec4<f32> {
    let p = vec2<f32>(f32((vi << 1u) & 2u), f32(vi & 2u));
    return vec4<f32>(p * 2.0 - 1.0, 0.0, 1.0);
}

fn mainImage(fragCoord: vec2<f32>) -> vec4<f32> {
    let uv = fragCoord / u.iResolution.xy;
    let col = 0.5 + 0.5 * cos(u.iTime + uv.xyx + vec3<f32>(0.0, 2.0, 4.0));
    return vec4<f32>(col, 1.0);
}

@fragment
fn fs(@builtin(position) pos: vec4<f32>) -> @location(0) vec4<f32> {
    let fragCoord = vec2<f32>(pos.x, u.iResolution.y - pos.y);
    return mainImage(fragCoord);
}
