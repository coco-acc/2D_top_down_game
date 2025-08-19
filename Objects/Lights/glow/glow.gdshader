shader_type canvas_item;
render_mode unshaded, blend_add; // Unlit, adds light to the framebuffer

// Hot red-orange emission
uniform vec4 emission_color : source_color = vec4(1.0, 0.25, 0.0, 1.0);

uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;         // >1.0 to trigger bloom
uniform float fade_height : hint_range(0.0, 0.5) = 0.05;                // fade top & bottom
uniform float center_boost : hint_range(0.0, 1.0) = 0.35;               // brighter in the middle

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Vertical fade (top/bottom transparent, strongest at center)
    float fade = smoothstep(0.0, fade_height, UV.y) *
                 smoothstep(1.0, 1.0 - fade_height, UV.y);

    // Optional center emphasis to make the core hotter
    float center_y = 1.0 - abs(UV.y - 0.5) / 0.5; // 0 at edges, 1 at middle
    float boost = mix(1.0, 1.0 + center_boost, center_y);

    // Emission: push HDR values (>1.0) so Glow/bloom catches it
    vec3 emissive = tex.rgb * emission_color.rgb * emission_strength * boost;

    float alpha = tex.a * emission_color.a * fade;
    COLOR = vec4(emissive, alpha);
}
