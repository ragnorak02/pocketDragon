shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec4 base_color : source_color = vec4(0.2, 0.5, 0.15, 1.0);
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform float wind_strength : hint_range(0.0, 0.5) = 0.15;
uniform float height_influence : hint_range(0.0, 2.0) = 1.0;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.2;

void vertex() {
	// Sway increases with height (top of tree sways more)
	float height_factor = clamp(VERTEX.y * height_influence, 0.0, 1.0);
	float sway = sin(TIME * wind_speed + MODEL_MATRIX[3].x * 0.5) * wind_strength * height_factor;
	float sway2 = cos(TIME * wind_speed * 0.7 + MODEL_MATRIX[3].z * 0.3) * wind_strength * 0.5 * height_factor;
	VERTEX.x += sway;
	VERTEX.z += sway2;
}

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
	// Subtle rim for depth
	float rim = 1.0 - dot(NORMAL, VIEW);
	rim = pow(rim, 3.0);
	EMISSION = base_color.rgb * rim * rim_intensity;
}
