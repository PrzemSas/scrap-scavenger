shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex    : source_color,       filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex    : hint_normal,         filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_tex : hint_default_white,  filter_linear_mipmap, repeat_enable;
uniform sampler2D ao_tex        : hint_default_white,  filter_linear_mipmap, repeat_enable;

uniform vec2  uv_scale      = vec2(5.0, 5.0);
uniform float brightness    = 1.7;
uniform float plate_size    = 3.2;
uniform float seam_width    = 0.055;

// ── Kolory ────────────────────────────────────────────────────────────────────
uniform vec4 col_seam    : source_color = vec4(0.04, 0.03, 0.02, 1.0);
uniform vec4 col_rust_a  : source_color = vec4(0.88, 0.28, 0.04, 1.0);  // jaskrawa rdza
uniform vec4 col_rust_b  : source_color = vec4(0.65, 0.18, 0.05, 1.0);  // ciemna rdza
uniform vec4 col_moss    : source_color = vec4(0.18, 0.52, 0.10, 1.0);  // żywy mech
uniform vec4 col_puddle  : source_color = vec4(0.06, 0.22, 0.48, 1.0);  // ciemnoniebieska kałuża
uniform vec4 col_oil_a   : source_color = vec4(0.05, 0.12, 0.35, 1.0);  // olej niebieski
uniform vec4 col_oil_b   : source_color = vec4(0.40, 0.05, 0.30, 1.0);  // olej fiolet
uniform vec4 col_warn    : source_color = vec4(0.95, 0.72, 0.02, 1.0);  // żółty pas
uniform vec4 col_paint   : source_color = vec4(0.55, 0.08, 0.06, 1.0);  // stara czerwona farba
uniform vec4 col_dirt    : source_color = vec4(0.38, 0.28, 0.16, 1.0);  // ziemia/piach

// ── Siła efektów ──────────────────────────────────────────────────────────────
uniform float str_rust    = 0.80;
uniform float str_moss    = 0.60;
uniform float str_puddle  = 0.65;
uniform float str_oil     = 0.55;
uniform float str_warn    = 0.50;
uniform float str_paint   = 0.40;
uniform float str_dirt    = 0.55;

// ── Noise ─────────────────────────────────────────────────────────────────────
float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1,0)), u.x),
		mix(hash21(i + vec2(0,1)), hash21(i + vec2(1,1)), u.x),
		u.y);
}

float fbm(vec2 p, int oct) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < oct; i++) {
		v += a * vnoise(p);
		p = p * 2.1 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

// ── Grid ──────────────────────────────────────────────────────────────────────
float seam_mask(vec2 uv) {
	vec2 g = fract(uv / plate_size);
	vec2 d = min(g, 1.0 - g);
	return 1.0 - smoothstep(0.0, seam_width, min(d.x, d.y));
}

float edge_ring(vec2 uv) {
	vec2 g = fract(uv / plate_size);
	vec2 d = min(g, 1.0 - g);
	float dist = min(d.x, d.y);
	return smoothstep(seam_width, seam_width * 4.5, dist)
	     * (1.0 - smoothstep(seam_width * 4.5, seam_width * 10.0, dist));
}

float plate_id(vec2 uv) {
	return hash21(floor(uv / plate_size));
}

// Żółty pas ostrzegawczy: paski równoległe do osi X
float warning_stripe(vec2 world_uv) {
	float stripe = fract(world_uv.x * 0.18 + world_uv.y * 0.04);
	float w = smoothstep(0.0, 0.05, stripe) * (1.0 - smoothstep(0.42, 0.50, stripe));
	// tylko w pewnych strefach (nie wszędzie)
	float zone = smoothstep(0.62, 0.75, fbm(world_uv * 0.05, 2));
	return w * zone;
}

// ── Fragment ──────────────────────────────────────────────────────────────────
void fragment() {
	vec2 uv = UV * uv_scale;

	vec3  base   = texture(albedo_tex,    uv).rgb * brightness;
	vec3  nrm    = texture(normal_tex,    uv).rgb;
	float rough0 = texture(roughness_tex, uv).r;
	float ao     = texture(ao_tex,        uv).r;

	float smask = seam_mask(uv);
	float ering = edge_ring(uv);
	float pid   = plate_id(uv);

	// Per-płyta bazowy odcień (ciepły/chłodny/zardzewiały)
	float plate_tone = pid;
	vec3 plate_base;
	if (plate_tone < 0.30) {
		plate_base = base * vec3(1.20, 1.05, 0.82);   // ciepło-rdzawy
	} else if (plate_tone < 0.60) {
		plate_base = base * vec3(0.88, 0.94, 1.10);   // chłodna stal
	} else {
		plate_base = base * vec3(1.05, 0.98, 0.88);   // neutralna
	}
	vec3 col = plate_base;

	// ── Rdza ─────────────────────────────────────────────────────────────────
	float rust_n = fbm(uv * 0.48 + vec2(3.1, 7.4), 4);
	rust_n = smoothstep(0.38, 0.70, rust_n);
	rust_n += smask * 0.35;   // więcej przy spoinach
	rust_n = clamp(rust_n, 0.0, 1.0);
	vec3 rust_col = mix(col_rust_a.rgb, col_rust_b.rgb, fbm(uv * 0.9, 2));
	col = mix(col, rust_col, rust_n * str_rust);

	// ── Mech ─────────────────────────────────────────────────────────────────
	float moss_n = fbm(uv * 0.42 + vec2(11.3, 2.7), 3);
	moss_n = smoothstep(0.52, 0.78, moss_n) * ering;
	col = mix(col, col_moss.rgb, moss_n * str_moss);

	// ── Stara farba (czerwone plamy) ──────────────────────────────────────────
	float paint_n = fbm(uv * 0.22 + vec2(6.6, 18.0), 3);
	paint_n = smoothstep(0.60, 0.80, paint_n) * (1.0 - smask);
	col = mix(col, col_paint.rgb, paint_n * str_paint);

	// ── Ziemia/gruz ───────────────────────────────────────────────────────────
	float dirt_n = fbm(uv * 0.15 + vec2(22.0, 4.5), 3);
	dirt_n = smoothstep(0.58, 0.78, dirt_n);
	col = mix(col, col_dirt.rgb, dirt_n * str_dirt * (1.0 - rust_n));

	// ── Żółte pasy ostrzegawcze ───────────────────────────────────────────────
	float warn = warning_stripe(uv);
	// zużycie: pasy przetarte przez czas
	float warn_wear = fbm(uv * 1.4, 2);
	warn *= smoothstep(0.2, 0.6, warn_wear);
	col = mix(col, col_warn.rgb, warn * str_warn);

	// ── Olej (irydescencja) ───────────────────────────────────────────────────
	float oil_n = fbm(uv * 0.26 + vec2(5.5, 14.1), 3);
	oil_n = smoothstep(0.60, 0.84, oil_n) * (1.0 - smask);
	float oil_hue = fbm(uv * 1.8, 2);
	vec3  oil_col = mix(col_oil_a.rgb, col_oil_b.rgb, oil_hue);
	col = mix(col, oil_col, oil_n * str_oil);

	// ── Kałuże ───────────────────────────────────────────────────────────────
	float puddle_n = fbm(uv * 0.16 + vec2(20.0, 33.0), 3);
	puddle_n = smoothstep(0.64, 0.82, puddle_n) * (1.0 - smask);
	vec3 puddle_col = mix(col_puddle.rgb, col_puddle.rgb * 1.4, fbm(uv * 0.6, 2));
	col = mix(col, puddle_col, puddle_n * str_puddle);

	// ── Spoiny: ciemne z rdzawymi żyłkami ────────────────────────────────────
	float seam_rust = fbm(uv * 2.2, 2) * smask;
	vec3 seam_col = mix(col_seam.rgb, col_rust_b.rgb * 0.65, seam_rust * 0.7);
	col = mix(col, seam_col, smask * 0.88);

	// Krawędź płyty — metaliczny blask
	col = mix(col, col * 1.4, ering * 0.25);

	// ── Roughness ─────────────────────────────────────────────────────────────
	float rough = rough0 * 0.72;
	rough = mix(rough, 0.97, smask * 0.90);
	rough = mix(rough, 0.06, puddle_n * str_puddle);
	rough = mix(rough, rough * 0.60, oil_n * str_oil * 0.5);
	rough = mix(rough, 0.85, moss_n * str_moss * 0.5);
	rough = mix(rough, 0.60, warn * str_warn * 0.4);

	// ── Metallic ─────────────────────────────────────────────────────────────
	float metallic = 0.28;
	metallic = mix(metallic, 0.02, smask * 0.9);
	metallic = mix(metallic, 0.88, puddle_n * str_puddle);
	metallic = mix(metallic, 0.70, oil_n * str_oil * 0.8);
	metallic = mix(metallic, 0.08, moss_n * str_moss);

	ALBEDO           = clamp(col, 0.0, 1.0);
	NORMAL_MAP       = nrm;
	NORMAL_MAP_DEPTH = 1.8;
	ROUGHNESS        = clamp(rough, 0.0, 1.0);
	METALLIC         = clamp(metallic, 0.0, 1.0);
	AO               = ao * mix(1.0, 0.65, smask);
	AO_LIGHT_AFFECT  = 0.5;
}
