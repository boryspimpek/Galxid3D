// NOTE: Zoptymalizowany i ożywiony shader dla lasera przestrzennego (Godot 4.6+)
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded; // Wyłączyłem culling, żeby laser był widoczny z obu stron quada

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

// Parametry kontrolujące ożywienie lasera
uniform float scroll_speed : hint_range(-10.0, 10.0) = 2.0;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.015;
uniform float distortion_frequency : hint_range(0.0, 100.0) = 30.0;
uniform float distortion_speed : hint_range(0.0, 50.0) = 15.0;

uniform float pulse_speed : hint_range(0.0, 20.0) = 8.0;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.2;

uniform float core_glow_speed : hint_range(0.0, 50.0) = 25.0;

void vertex() {
	// Tradycyjne skalowanie/offset UV, jeśli potrzebne w inspektorze
	UV = UV * vec2(1.0, 1.0); 
}

void fragment() {
	vec2 base_uv = UV;

	// 1. Losowe błyskawice / zniekształcenie krawędzi (Deformacja UV)
	// Modulujemy oś X (szerokość) w zależności od pozycji Y i czasu
	float distortion = sin(base_uv.y * distortion_frequency + TIME * distortion_speed) * distortion_strength;
	// Dodatkowa, szybsza warstwa szumu dla efektu "bzyczenia" prądu
	distortion += cos(base_uv.y * (distortion_frequency * 1.5) - TIME * (distortion_speed * 1.3)) * (distortion_strength * 0.4);
	
	base_uv.x += distortion;

	// 2. Przesuwanie tekstury w pionie (Scroll UV)
	base_uv.y -= TIME * scroll_speed;

	// Pobranie tekstury z bazowym, zmodyfikowanym UV
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	
	// Przypisanie koloru bazowego
	vec3 final_rgb = albedo.rgb * albedo_tex.rgb;

	// 3. Przepływające jaśniejsze segmenty (Core Glow)
	// Tworzy efekt fali energii idącej wzdłuż promienia
	float energy_wave = sin(UV.y * 20.0 - TIME * core_glow_speed) * 0.5 + 0.5;
	// Nakładamy rozjaśnienie głównie na środek lasera (tam gdzie tekstura jest najjaśniejsza)
	final_rgb += energy_wave * albedo_tex.rgb * 0.4;

	// 4. Globalne pulsowanie jasności/energii
	float pulse = sin(TIME * pulse_speed) * pulse_intensity;
	final_rgb += vec3(pulse) * albedo_tex.rgb;

	// Wyjście
	ALBEDO = final_rgb;
	
	// Spłaszczamy alphę i bierzemy pod uwagę deformację
	ALPHA = albedo.a * albedo_tex.a;
}