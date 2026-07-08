shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled;

// --- UNIFORMS (Zmienne sterujące w Inspektorze) ---
group_uniforms planter_settings;
uniform float model_height = 3.0;
uniform float dissolve_start : hint_range(0.0, 1.0) = 0.001;
uniform float dissolve_length : hint_range(0.0, 1.0) = 1.0;
uniform float gradient_bias : hint_range(0.1, 5.0) = 1.0;

group_uniforms noise_settings;
uniform float noise_speed = 1.0;
uniform float noise_strength = 0.1;
uniform float stretch_factor = 0.6;
uniform vec2 noise_direction = vec2(0.0, -1.0);
uniform sampler2D noise_texture : repeat_enable;

group_uniforms neon_and_fresnel;
uniform vec3 color : source_color = vec3(0.0, 0.5, 1.0);
uniform float power_factor = 2.0;
uniform float fresnel_factor = 2.0;
uniform float fresnel_amplification = 1.0;
uniform float fresnel_power = 1.0;

// --- VARYINGS (Przekazywanie danych z vertex do fragment) ---
varying float vert_height;
varying vec2 v_uv;

// --- FUNKCJE POMOCNICZE ---
// Funkcje muszą być zdefiniowane PRZED ich użyciem w fragment()
vec3 neon(float value, vec3 neon_color) {
    float ramp = clamp(value, 0.0, 1.0);
    vec3 output_color = vec3(0.0);
    ramp = ramp * ramp;
    output_color += pow(neon_color, vec3(4.0)) * ramp;
    ramp = ramp * ramp;
    output_color += neon_color * ramp;
    ramp = ramp * ramp;
    output_color += vec3(1.0) * ramp;
    return output_color;
}

float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

// --- VERTEX SHADER ---
void vertex() {
    vert_height = (VERTEX.y + (model_height / 2.0)) / model_height;
    v_uv = UV;
}

// --- FRAGMENT SHADER ---
void fragment() {
    // 1. Obliczanie poruszającego się szumu
    float time = TIME * noise_speed;
    vec2 moving_uv = v_uv + noise_direction * time;
    vec2 stretched_uv = vec2(moving_uv.x, moving_uv.y * stretch_factor);
    float noise_value = texture(noise_texture, stretched_uv).r * noise_strength;

    // 2. Obliczanie gradientu wysokości z uwzględnieniem szumu
    float gradient_height = vert_height - dissolve_start;
    gradient_height *= 1.0 / dissolve_length;
    gradient_height = clamp(pow(gradient_height, gradient_bias) + noise_value, 0.0, 1.0);

    // 3. Obliczanie efektu Fresnel (gładkie krawędzie płomienia)
    float fresnel_effect = 1.0 - fresnel(fresnel_factor, NORMAL, VIEW);
    fresnel_effect = pow(fresnel_effect * fresnel_amplification, fresnel_power);

    // 4. Przypisanie końcowych wartości do wyjścia shadera
    float final_alpha = mix(1.0, 0.0, gradient_height);
    
    ALPHA = final_alpha * fresnel_effect;
    ALBEDO = neon(pow(ALPHA, power_factor), color);
    EMISSION = ALBEDO * 2.0; // Dodane dla efektu świecenia (Glow)
}