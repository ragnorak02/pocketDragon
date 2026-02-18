shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 ring_color : source_color = vec4(0.5, 0.3, 0.7, 1.0);
uniform float rotation_speed : hint_range(0.0, 3.0) = 0.8;
uniform float glow_strength : hint_range(0.0, 4.0) = 2.0;
uniform float pattern_count : hint_range(2.0, 16.0) = 6.0;
uniform float alpha_val : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	vec2 centered = UV - 0.5;
	float dist = length(centered);
	float angle = atan(centered.y, centered.x) + TIME * rotation_speed;

	// Rune segments around the ring
	float segments = sin(angle * pattern_count) * 0.5 + 0.5;
	segments = smoothstep(0.3, 0.7, segments);

	// Ring mask — only show near the edge of the cylinder disc
	float ring_mask = smoothstep(0.3, 0.38, dist) * smoothstep(0.5, 0.42, dist);

	// Inner glow
	float inner_glow = smoothstep(0.4, 0.1, dist) * 0.3;

	float pattern = segments * ring_mask + inner_glow;
	float pulse = sin(TIME * 1.5) * 0.15 + 0.85;

	ALBEDO = ring_color.rgb * 0.3;
	EMISSION = ring_color.rgb * pattern * glow_strength * pulse;
	ALPHA = pattern * alpha_val;
}
