shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.03, 0.02, 0.06, 1.0);
uniform vec4 mist_color : source_color = vec4(0.15, 0.08, 0.25, 1.0);
uniform vec4 accent_color : source_color = vec4(0.4, 0.2, 0.6, 1.0);
uniform float mist_speed : hint_range(0.0, 1.0) = 0.15;
uniform float mist_density : hint_range(0.0, 1.0) = 0.4;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += amp * noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	vec3 color = bg_color.rgb;

	// Layer 1 — slow large mist
	float m1 = fbm(UV * 3.0 + vec2(TIME * mist_speed, TIME * mist_speed * 0.3));
	color += mist_color.rgb * smoothstep(0.4, 0.7, m1) * mist_density;

	// Layer 2 — faster smaller wisps
	float m2 = fbm(UV * 6.0 + vec2(-TIME * mist_speed * 1.5, TIME * mist_speed * 0.8));
	color += accent_color.rgb * smoothstep(0.5, 0.75, m2) * mist_density * 0.4;

	// Vignette
	vec2 centered = UV - 0.5;
	float vignette = 1.0 - dot(centered, centered) * 1.5;
	color *= vignette;

	COLOR = vec4(color, 1.0);
}
