shader_type canvas_item;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV) * COLOR;

    // Clamp to avoid bright values that trigger glow
    tex_color.rgb = min(tex_color.rgb, vec3(0.1));

    COLOR = tex_color;
}

void light() {
    // Do nothing → no light applied
    LIGHT = vec4(0.0);
}
