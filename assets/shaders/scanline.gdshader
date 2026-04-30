shader_type canvas_item;

uniform float scanline_density : hint_range(100.0, 600.0) = 280.0;
uniform float scanline_strength : hint_range(0.0, 0.4) = 0.09;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;
uniform float flicker_speed : hint_range(0.0, 10.0) = 3.5;
uniform float flicker_strength : hint_range(0.0, 0.05) = 0.008;

void fragment() {
	// Linie skanowania: ciemne poziome paski co kilka pikseli
	float scan = sin(UV.y * scanline_density * 3.14159);
	float scan_alpha = max(0.0, -scan) * scanline_strength;

	// Winieta: ciemne brzegi ekranu
	vec2 uv_c = UV * 2.0 - 1.0;
	float vign = dot(uv_c * vec2(0.8, 1.0), uv_c * vec2(0.8, 1.0));
	vign = clamp(vign * vignette_strength, 0.0, 0.72);

	// Migotanie: subtelna zmiana jasności
	float flicker = max(0.0, sin(TIME * flicker_speed * 7.3) * flicker_strength
	                       + sin(TIME * flicker_speed * 2.1) * flicker_strength * 0.4);

	// Wynik: czarna nakładka z przezroczystością — im ciemniej, tym bardziej widoczna
	float alpha = clamp(scan_alpha + vign + flicker, 0.0, 0.86);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
