shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D emissive_tex : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_tex : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform vec4 emissive_color : source_color = vec4(1.0, 0.42, 0.05, 1.0);
uniform float emissive_base : hint_range(0.0, 4.0) = 1.2;
uniform float emissive_pulse_strength : hint_range(0.0, 4.0) = 1.8;
uniform float pulse_speed : hint_range(0.1, 8.0) = 1.6;
uniform float pulse_freq2 : hint_range(0.1, 8.0) = 3.7;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.72;
uniform vec2 uv_scale = vec2(2.0, 2.0);

void fragment() {
	vec2 uv = UV * uv_scale;

	vec3 base = texture(albedo_tex, uv).rgb;
	float emask = texture(emissive_tex, uv).r;
	float rough = texture(roughness_tex, uv).r;

	// Puls = suma dwóch sinusoid — jak bicie serca kuźni
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	pulse += sin(TIME * pulse_freq2 + 1.57) * 0.25;
	pulse = clamp(pulse, 0.0, 1.0);

	float emissive_strength = emissive_base + pulse * emissive_pulse_strength;

	ALBEDO = base;
	ROUGHNESS = rough * 0.65;
	METALLIC = metallic_val;
	EMISSION = emissive_color.rgb * emask * emissive_strength;
}
