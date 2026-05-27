shader_type spatial;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float specular : hint_range(0.0, 1.0) = 0.5;

// --- TOON SETTINGS ---
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float shadow_softness : hint_range(0.0, 0.2) = 0.02;

// --- RIM LIGHT (opcjonalny efekt konturowy) ---
uniform bool rim_enabled = false;
uniform float rim_width : hint_range(0.0, 1.0) = 0.3;
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.1;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = albedo_color.rgb * tex.rgb;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = specular;
}

void light() {
    // --- 1. TOON DIFFUSE ---
    float diffuse = dot(NORMAL, LIGHT);
    float toon_diffuse = smoothstep(
        shadow_threshold - shadow_softness,
        shadow_threshold + shadow_softness,
        diffuse
    );
    vec3 diffuse_color = mix(line_color.rgb, LIGHT_COLOR, toon_diffuse);

    // --- 2. TOON SPECULAR ---
    vec3 half_vector = normalize(VIEW + LIGHT);
    // POPRAWKA: clamp żeby uniknąć NaN z pow() przy ujemnych wartościach
    float spec_dot = max(dot(NORMAL, half_vector), 0.0);

    // POPRAWKA: ograniczony zakres exponentu (8–512)
    float spec_exponent = mix(8.0, 512.0, 1.0 - roughness);
    float spec_intensity = pow(spec_dot, spec_exponent);
    float toon_specular = smoothstep(
        0.5 - shadow_softness,
        0.5 + shadow_softness,
        spec_intensity
    );

    // --- 3. RIM LIGHT ---
    vec3 rim_contribution = vec3(0.0);
    if (rim_enabled) {
        float rim = 1.0 - max(dot(NORMAL, VIEW), 0.0);
        float toon_rim = smoothstep(
            1.0 - rim_width - shadow_softness,
            1.0 - rim_width + shadow_softness,
            rim
        );
        // Rim widoczny tylko po jasnej stronie
        toon_rim *= step(rim_threshold, diffuse);
        rim_contribution = toon_rim * rim_color.rgb * LIGHT_COLOR;
    }

    // --- 4. FINALNE ŁĄCZENIE ---
    DIFFUSE_LIGHT += diffuse_color * ATTENUATION;
    SPECULAR_LIGHT += toon_specular * specular * LIGHT_COLOR * ATTENUATION;
    DIFFUSE_LIGHT += rim_contribution * ATTENUATION;
}