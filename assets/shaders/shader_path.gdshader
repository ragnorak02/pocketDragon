shader_type spatial;

uniform vec4 stone_color : source_color = vec4(0.45, 0.38, 0.3, 1.0);
uniform vec4 mortar_color : source_color = vec4(0.3, 0.25, 0.2, 1.0);
uniform float tile_scale : hint_range(1.0, 20.0) = 8.0;
uniform float mortar_width : hint_range(0.01, 0.15) = 0.06;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.9;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = UV * tile_scale;

	// Offset every other row for brick pattern
	float row = floor(uv.y);
	if (mod(row, 2.0) > 0.5) {
		uv.x += 0.5;
	}

	vec2 grid = fract(uv);
	vec2 grid_id = floor(uv);

	// Mortar lines
	float mortar_x = smoothstep(0.0, mortar_width, grid.x) * smoothstep(0.0, mortar_width, 1.0 - grid.x);
	float mortar_y = smoothstep(0.0, mortar_width, grid.y) * smoothstep(0.0, mortar_width, 1.0 - grid.y);
	float mortar = mortar_x * mortar_y;

	// Per-stone color variation
	float variation = hash(grid_id) * 0.12;
	vec3 stone = stone_color.rgb + variation - 0.06;
	vec3 color = mix(mortar_color.rgb, stone, mortar);

	ALBEDO = color;
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
}
