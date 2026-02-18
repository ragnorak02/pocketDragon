shader_type spatial;
render_mode diffuse_toon;

uniform vec4 color_base : source_color = vec4(0.35, 0.32, 0.3, 1.0);
uniform vec4 color_dark : source_color = vec4(0.2, 0.18, 0.16, 1.0);
uniform vec4 color_highlight : source_color = vec4(0.5, 0.48, 0.42, 1.0);
uniform float noise_scale : hint_range(1.0, 30.0) = 8.0;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.95;

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
	vec2 uv = UV * noise_scale;
	float n1 = noise(uv);
	float n2 = noise(uv * 2.3 + 5.0);
	float combined = n1 * 0.6 + n2 * 0.4;

	vec3 color = mix(color_dark.rgb, color_base.rgb, smoothstep(0.3, 0.5, combined));
	color = mix(color, color_highlight.rgb, smoothstep(0.65, 0.8, combined));

	ALBEDO = color;
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
}
