shader_type spatial;

uniform vec4 stone_color : source_color = vec4(0.12, 0.1, 0.18, 1.0);
uniform vec4 stone_color_alt : source_color = vec4(0.08, 0.06, 0.12, 1.0);
uniform vec4 rune_color : source_color = vec4(0.5, 0.3, 0.8, 1.0);
uniform float rune_glow : hint_range(0.0, 3.0) = 1.5;
uniform float rune_speed : hint_range(0.0, 2.0) = 0.5;
uniform float tile_scale : hint_range(1.0, 20.0) = 6.0;

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
	vec2 uv = UV * tile_scale;
	vec2 grid = fract(uv);
	vec2 grid_id = floor(uv);

	// Stone tile pattern
	float edge = smoothstep(0.0, 0.04, grid.x) * smoothstep(0.0, 0.04, grid.y);
	edge *= smoothstep(0.0, 0.04, 1.0 - grid.x) * smoothstep(0.0, 0.04, 1.0 - grid.y);
	float tile_var = hash(grid_id) * 0.15;
	vec3 stone = mix(stone_color.rgb, stone_color_alt.rgb, tile_var);
	stone *= edge;

	// Rune lines — cross pattern radiating from center
	vec2 centered = UV - 0.5;
	float dist = length(centered);
	float angle = atan(centered.y, centered.x);

	// Concentric rings
	float rings = sin(dist * 30.0 - TIME * rune_speed) * 0.5 + 0.5;
	rings = smoothstep(0.88, 0.95, rings);

	// Radial lines
	float radial = sin(angle * 8.0) * 0.5 + 0.5;
	radial = smoothstep(0.92, 0.98, radial);

	// Combine rune pattern (only visible in inner area)
	float rune_mask = smoothstep(0.5, 0.15, dist);
	float rune = max(rings, radial) * rune_mask;

	// Pulsing glow
	float pulse = sin(TIME * rune_speed * 2.0) * 0.3 + 0.7;

	ALBEDO = stone + noise(UV * 40.0) * 0.03;
	ROUGHNESS = 0.85;
	METALLIC = 0.05;
	EMISSION = rune_color.rgb * rune * rune_glow * pulse;
}
