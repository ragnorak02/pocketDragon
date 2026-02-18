shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 color_inner : source_color = vec4(0.4, 0.6, 1.0, 1.0);
uniform vec4 color_outer : source_color = vec4(0.2, 0.3, 0.8, 1.0);
uniform float swirl_speed : hint_range(0.0, 5.0) = 2.0;
uniform float distortion : hint_range(0.0, 1.0) = 0.4;
uniform float glow_strength : hint_range(0.0, 5.0) = 2.5;
uniform float alpha_val : hint_range(0.0, 1.0) = 0.7;

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
	vec2 centered = UV - 0.5;
	float dist = length(centered);
	float angle = atan(centered.y, centered.x);

	// Swirl distortion
	float swirl_angle = angle + TIME * swirl_speed + dist * 6.0;
	vec2 swirl_uv = vec2(cos(swirl_angle), sin(swirl_angle)) * dist + 0.5;

	// Layered noise for energy turbulence
	float n1 = noise(swirl_uv * 6.0 + TIME * 0.5);
	float n2 = noise(swirl_uv * 12.0 - TIME * 0.8);
	float energy = n1 * 0.6 + n2 * 0.4;

	// Radial falloff — stronger at center
	float radial = smoothstep(0.5, 0.0, dist);
	energy *= radial;

	vec3 color = mix(color_outer.rgb, color_inner.rgb, energy);
	float pulse = sin(TIME * 2.5) * 0.15 + 0.85;

	ALBEDO = color * 0.3;
	EMISSION = color * glow_strength * energy * pulse;
	ALPHA = energy * alpha_val * radial;
}
