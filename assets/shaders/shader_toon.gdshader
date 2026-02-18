shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_power : hint_range(0.0, 8.0) = 3.0;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.0;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.8;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.0;

void fragment() {
	ALBEDO = base_color.rgb;
	METALLIC = metallic_val;
	ROUGHNESS = roughness_val;

	// Rim lighting
	float rim = 1.0 - dot(NORMAL, VIEW);
	rim = pow(rim, rim_power);
	EMISSION = rim_color.rgb * rim * rim_intensity + base_color.rgb * emission_strength;
}
