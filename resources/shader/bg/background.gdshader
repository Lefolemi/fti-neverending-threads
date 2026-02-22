shader_type canvas_item;

// --- EXPOSED TO SCRIPT ---
uniform vec4 tint_color : source_color = vec4(1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform vec2 velocity = vec2(0.0, 0.0); // Combined Direction & Speed
uniform float scale = 1.0;

// --- EFFECT: Liquid Warp ---
uniform float warp_strength = 0.0;
uniform float warp_speed = 1.5;

void fragment() {
    // 1. Zoom/Scale (Scale 1.0 = Original, 0.5 = Zoomed In, 2.0 = Tiled smaller)
    vec2 scaled_uv = UV / scale;

    // 2. The Liquid Warp Effect (Sine-based distortion)
    vec2 warp_offset;
    warp_offset.x = sin(scaled_uv.y * 5.0 + TIME * warp_speed) * warp_strength;
    warp_offset.y = cos(scaled_uv.x * 5.0 + TIME * warp_speed) * warp_strength;

    // 3. Simplified Motion Logic
    // No more separate 'speed' variable. Velocity vector handles both.
    vec2 motion = velocity * TIME;

    vec2 final_uv = scaled_uv + warp_offset + motion;

    // 4. Sample and Tint
    vec4 tex_color = texture(TEXTURE, final_uv);
    vec3 tinted_rgb = tex_color.rgb * tint_color.rgb;

    // 5. Final Output with Opacity
    COLOR = vec4(tinted_rgb, tex_color.a * opacity);
}