shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_test_disabled, depth_draw_never;

uniform sampler2D projectile_texture : source_color;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float emission_strength = 1.5;

uniform float pulse_speed = 2.0;
uniform float pulse_strength = 0.05;

uniform float rotation_speed = 3.0;

void vertex() {
	// Pulsowanie
	float pulse = sin(TIME * pulse_speed) * pulse_strength;
	VERTEX.xz *= 1.0 + pulse;

	// Obrót wokół osi Y
	float angle = TIME * rotation_speed;
	float s = sin(angle);
	float c = cos(angle);

	vec2 v = VERTEX.xz;

	VERTEX.x = v.x * c - v.y * s;
	VERTEX.z = v.x * s + v.y * c;
}

void fragment() {
	vec4 tex = texture(projectile_texture, UV);

	vec3 color = tex.rgb * tint_color.rgb;

	ALBEDO = color;
	EMISSION = color * emission_strength;
	ALPHA = tex.a * tint_color.a;
}