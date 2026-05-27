shader_type spatial;
render_mode ambient_light_disabled;

// --- TWOJE TEKSTURY I KOLORY ---
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // DODANE: Jednolity kolor
uniform sampler2D albedo_texture : source_color, hint_default_white; // MODYFIKACJA: Dodany hint_default_white
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float clearcoat : hint_range(0.0, 1.0) = 0.0;
uniform float clearcoat_roughness : hint_range(0.0, 1.0) = 0.2;
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float shadow_softness : hint_range(0.0, 1.0) = 0.02;
uniform float ambient_fill : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	
	ALBEDO = albedo_color.rgb * tex.rgb;
	METALLIC = metallic;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = ALBEDO * ambient_fill;
}

void light() {
	// --- 1. OSTRY CIEŃ (TOON DIFFUSE) ---
	float ndotl = max(dot(NORMAL, LIGHT), 0.0);
	float toon_diffuse = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, ndotl);
	vec3 lit_color = ALBEDO * LIGHT_COLOR;
	vec3 shadow_color = ALBEDO * line_color.rgb;
	vec3 diffuse_color = mix(shadow_color, lit_color, toon_diffuse);
	
	// --- 2. CLEARCOAT (prosty dodatkowy highlight) ---
	vec3 half_vector = normalize(VIEW + LIGHT);
	float cc_ndoth = max(dot(NORMAL, half_vector), 0.0);
	float cc_exponent = mix(32.0, 1024.0, 1.0 - clearcoat_roughness);
	float cc_spec = pow(cc_ndoth, cc_exponent) * clearcoat;
	
	// --- 3. FINALNE ŁĄCZENIE ---
	// Dodajemy kolor rozproszony (planeta)
	DIFFUSE_LIGHT += diffuse_color * ATTENUATION;
	SPECULAR_LIGHT += cc_spec * LIGHT_COLOR * ATTENUATION;
}