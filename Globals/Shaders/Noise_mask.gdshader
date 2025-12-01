shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float threshold = 0.5;     // Controls how much of the piece is visible
uniform float scale = 4.0;         // Controls how "fine" the noise looks

void fragment() {
    vec4 tex_col = texture(TEXTURE, UV);
    float n = texture(noise_tex, UV * scale).r;

    // Discard (make transparent) pixels where noise is below the threshold
    if (n < threshold) {
        discard;
    }

    COLOR = tex_col;
}
