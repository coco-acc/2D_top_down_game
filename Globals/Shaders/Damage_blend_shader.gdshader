shader_type spatial;

uniform sampler2D BaseTexture;
uniform sampler2D DamageTexture : hint_default_black;
uniform sampler2D NoiseTexture;
instance uniform float DamageAmount : hint_range(0, 100) = 0;
instance uniform float Treshold = 25.0;

void fragment() {
	vec4 damage_tex = texture(DamageTexture, UV);
	vec4 base_tex = texture(BaseTexture, UV);
	vec4 noise_tex = texture(NoiseTexture, UV);

	float scalar = noise_tex.x * DamageAmount;
	float smooth_step = smoothstep(scalar, DamageAmount, Treshold);

	vec3 output = mix(vec3(damage_tex.xyz), vec3(base_tex.xyz), vec3(smooth_step));

	ALBEDO = output;
}