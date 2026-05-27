shader_type spatial;

render_mode cull_back, depth_draw_opaque;

uniform sampler2D albedo_texture;

uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_smoothness : hint_range(0.001, 0.5) = 0.08;

uniform vec3 shadow_color : source_color = vec3(0.12, 0.12, 0.18);

uniform float rim_strength : hint_range(0.0, 2.0) = 0.5;
uniform float rim_size : hint_range(0.1, 8.0) = 3.0;
uniform vec3 rim_color : source_color = vec3(0.4, 0.6, 1.0);

uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float specular : hint_range(0.0, 1.0) = 0.0;

uniform float brightness : hint_range(0.0, 1.5) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

vec3 adjust_color(vec3 color, float sat, float bright) {
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(luma);
    return mix(gray, color, sat) * bright;
}

void fragment() {
    vec3 tex = texture(albedo_texture, UV).rgb;

    tex = adjust_color(tex, saturation, brightness);

    ALBEDO = tex;

    ROUGHNESS = roughness;
    SPECULAR = specular;
}

void light() {

    float NdotL = dot(NORMAL, LIGHT);

    float toon = smoothstep(
        shadow_threshold - shadow_smoothness,
        shadow_threshold + shadow_smoothness,
        NdotL
    );

    vec3 color = mix(shadow_color, ALBEDO, toon);

    float rim = pow(
        1.0 - max(dot(NORMAL, VIEW), 0.0),
        rim_size
    );

    color += rim * rim_strength * rim_color;

    DIFFUSE_LIGHT += color * LIGHT_COLOR;
}