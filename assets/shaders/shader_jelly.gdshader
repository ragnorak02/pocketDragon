shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec4 base_color : source_color = vec4(0.3, 0.8, 0.3, 1.0);
uniform vec4 rim_color : source_color = vec4(0.5, 1.0, 0.5, 1.0);
uniform float rim_power : hint_range(0.0, 8.0) = 2.5;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float wobble_speed : hint_range(0.0, 10.0) = 3.0;
uniform float wobble_amount : hint_range(0.0, 0.3) = 0.08;
uniform float squash_amount : hint_range(0.0, 0.2) = 0.05;

void vertex() {
	float t = TIME * wobble_speed;
	// Lateral wobble
	VERTEX.x += sin(t + VERTEX.y * 4.0) * wobble_amount;
	VERTEX.z += cos(t * 0.8 + VERTEX.y * 3.0) * wobble_amount * 0.7;
	// Squash and stretch
	float squash = sin(t * 1.5) * squash_amount;
	VERTEX.y *= 1.0 + squash;
	VERTEX.x *= 1.0 - squash * 0.5;
	VERTEX.z *= 1.0 - squash * 0.5;
}

void fragment() {
	ALBEDO = base_color.rgb;
	METALLIC = 0.1;
	ROUGHNESS = 0.4;
	// Translucent jelly rim
	float rim = 1.0 - dot(NORMAL, VIEW);
	rim = pow(rim, rim_power);
	EMISSION = rim_color.rgb * rim * rim_intensity;
}
