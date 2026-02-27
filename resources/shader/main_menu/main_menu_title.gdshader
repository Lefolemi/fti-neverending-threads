shader_type canvas_item;

uniform vec4 ui_color : source_color;
uniform bool invert_mode;
uniform float speed : hint_range(0.1, 3.0) = 0.8;

void fragment() {
    vec4 mask = texture(TEXTURE, UV);
    
    // 1. Define the "Normal" Colors
    vec3 outline = ui_color.rgb * 0.2; // Darker version for outline
    vec3 base_body = ui_color.rgb + vec3(0.2); // Lighter version for body
    
    // 2. Animated Gradation (White part)
    float wave = sin((UV.y * 3.0) - (TIME * speed)) * 0.5 + 0.5;
    vec3 animated_body = mix(ui_color.rgb, base_body, wave * (1.0 - UV.y));
    
    // 3. Mix Outline and Body based on Sprite Mask
    float is_white = step(0.5, mask.r);
    vec3 final_rgb = mix(outline, animated_body, is_white);
    
    // 4. THE INVERSION
    // If invert_mode is true, we apply the literal negative: 1.0 - rgb
    if (invert_mode) {
        final_rgb = 1.0 - final_rgb;
    }
    
    COLOR = vec4(final_rgb, mask.a);
}