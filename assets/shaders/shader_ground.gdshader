shader_type spatial;

uniform vec4 grass_color : source_color = vec4(0.2, 0.38, 0.15, 1.0);
uniform vec4 dirt_color : source_color = vec4(0.35, 0.25, 0.15, 1.0);
uniform vec4 dark_grass_color : source_color = vec4(0.12, 0.28, 0.1, 1.0);
uniform float noise_scale : hint_range(1.0, 80.0) = 20.0;
uniform float detail_scale : hint_range(10.0, 200.0) = 60.0;
uniform float dirt_threshold : hint_range(0.0, 1.0) = 0.35;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.95;

// Simple hash-based noise
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
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
	vec2 uv = UV * noise_scale;
	float n = fbm(uv);
	float detail = fbm(UV * detail_scale) * 0.3;

	// Blend grass and dirt based on noise
	vec3 color = mix(grass_color.rgb, dirt_color.rgb, step(dirt_threshold, n));
	// Add dark grass variation
	color = mix(color, dark_grass_color.rgb, smoothstep(0.5, 0.7, n + detail));
	// Subtle detail variation
	color += (detail - 0.15) * 0.15;

	ALBEDO = color;
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
}
