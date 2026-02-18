shader_type canvas_item;

uniform vec4 bg_dark : source_color = vec4(0.04, 0.02, 0.08, 1.0);
uniform vec4 bg_mid : source_color = vec4(0.08, 0.04, 0.16, 1.0);
uniform vec4 star_color : source_color = vec4(0.7, 0.6, 0.9, 1.0);
uniform vec4 energy_color : source_color = vec4(0.4, 0.2, 0.7, 1.0);
uniform float star_density : hint_range(0.0, 1.0) = 0.04;
uniform float energy_speed : hint_range(0.0, 2.0) = 0.3;

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

void fragment() {
	// Gradient background
	vec3 bg = mix(bg_dark.rgb, bg_mid.rgb, UV.y * 0.5 + 0.2);

	// Drifting energy wisps
	vec2 energy_uv = UV * 3.0 + vec2(TIME * energy_speed * 0.3, TIME * energy_speed * 0.1);
	float e1 = noise(energy_uv);
	float e2 = noise(energy_uv * 2.0 + 10.0);
	float energy = smoothstep(0.55, 0.75, e1 * 0.6 + e2 * 0.4);
	bg += energy_color.rgb * energy * 0.15;

	// Stars
	vec2 star_uv = UV * 80.0;
	vec2 star_id = floor(star_uv);
	float star_hash = hash(star_id);
	float star = step(1.0 - star_density, star_hash);
	// Twinkling
	float twinkle = sin(TIME * (2.0 + star_hash * 3.0) + star_hash * 6.28) * 0.5 + 0.5;
	float star_brightness = star * twinkle * (0.5 + star_hash * 0.5);
	bg += star_color.rgb * star_brightness;

	COLOR = vec4(bg, 1.0);
}
