shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4  albedo          : source_color             = vec4(0.90, 0.40, 0.05, 1.0);
uniform vec4  emission_color  : source_color             = vec4(1.00, 0.52, 0.08, 1.0);
uniform float emission_base   : hint_range(0.0, 10.0)   = 3.5;
uniform float pulse_strength  : hint_range(0.0,  8.0)   = 2.5;
uniform float speed_a         : hint_range(0.1, 12.0)   = 3.5;
uniform float speed_b         : hint_range(0.1, 12.0)   = 7.1;
uniform float speed_c         : hint_range(0.1, 12.0)   = 1.8;
uniform float roughness_val   : hint_range(0.0,  1.0)   = 0.08;
uniform float phase_offset    : hint_range(0.0,  6.28)  = 0.0;

void fragment() {
    // Trzy sinusoidy o różnych częstotliwościach — oddech ognia
    float p = sin(TIME * speed_a + phase_offset)             * 0.45
            + sin(TIME * speed_b + phase_offset * 1.3 + 1.2) * 0.30
            + sin(TIME * speed_c + phase_offset * 0.7 + 2.8) * 0.25;
    p = clamp(p * 0.5 + 0.5, 0.0, 1.0);

    ALBEDO     = albedo.rgb;
    ROUGHNESS  = roughness_val;
    METALLIC   = 0.0;
    EMISSION   = emission_color.rgb * (emission_base + p * pulse_strength);
}
