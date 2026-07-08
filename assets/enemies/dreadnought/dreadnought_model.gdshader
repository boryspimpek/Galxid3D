shader_type spatial;
// bez render_mode unshaded!

uniform sampler2D albedo_texture : source_color;
uniform float red_threshold = 0.45;
uniform float glow_strength = 4.0;
uniform float dim_strength : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    vec3 color = tex.rgb;

    float redness = tex.r - max(tex.g, tex.b);
    float glow_mask = smoothstep(red_threshold - 0.05, red_threshold + 0.05, redness);

    // baza: przyciemniona tekstura, normalnie oświetlana i cieniowana
    ALBEDO = color * dim_strength;

    // glow: dodatkowa emisja tylko na czerwonych fragmentach, niezależna od cieni
    EMISSION = color * glow_strength * glow_mask;
}