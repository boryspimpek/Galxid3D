shader_type spatial;
render_mode unshaded; // Ogień sam świeci w ciemności kosmosu

// Parametry kolorów (widoczne w Inspektorze)
uniform vec4 core_color : source_color = vec4(1.0, 0.9, 0.2, 1.0);  // Gorący środek (Żółty)
uniform vec4 fire_color : source_color = vec4(1.0, 0.3, 0.0, 1.0);  // Główny ogień (Pomarańczowy)
uniform vec4 smoke_color : source_color = vec4(0.4, 0.0, 0.0, 1.0); // Krawędzie/Dym (Ciemnoczerwony)

// Szybkość animacji ognia
uniform float speed : hint_range(1.0, 10.0) = 4.0;

// Funkcja generująca prosty szum pseudo-losowy (do animacji płomieni)
float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Płynny szum do deformacji i tekstury ognia
float smooth_noise(vec2 uv) {
    vec2 lv = fract(uv);
    vec2 id = floor(uv);
    
    lv = lv * lv * (3.0 - 2.0 * lv);
    
    float bl = noise(id);
    float br = noise(id + vec2(1.0, 0.0));
    float tl = noise(id + vec2(0.0, 1.0));
    float tr = noise(id + vec2(1.0, 1.0));
    
    return mix(mix(bl, br, lv.x), mix(tl, tr, lv.x), lv.y);
}

void vertex() {
    // --- DEFORMACJA KSZTAŁTU (Kula faluje jak ogień) ---
    // Przesuwamy szum w czasie w górę (czyli w kierunku osi Z w świecie gry)
    vec2 noise_uv = VERTEX.xz * 2.0 + vec2(0.0, TIME * speed);
    float n = smooth_noise(noise_uv);
    
    // Delikatnie wypychamy wierzchołki kuli na podstawie szumu, żeby nie była idealnie okrągła
    VERTEX += NORMAL * n * 0.15;
}

void fragment() {
    // Kąt patrzenia kamery (efekt Fresnela)
    float fresnel = 1.0 - dot(NORMAL, VIEW);
    
    // Dodajemy przesuwający się szum do fragmentów, żeby kolory się mieszały
    vec2 uv_scroll = UV * 1.5 + vec2(0.0, TIME * speed * 0.5);
    float n = smooth_noise(uv_scroll);
    
    // Łączymy pozycję na kuli (Fresnel) z wartością szumu
    float fire_mask = fresnel + n * 0.4;
    
    // --- CEL-SHADING (Ostre, komiksowe progi kolorów) ---
    vec3 final_color;
    if (fire_mask < 0.4) {
        final_color = core_color.rgb;   // Sam środek jest najgorętszy
    } else if (fire_mask < 0.8) {
        final_color = fire_color.rgb;   // Środek kuli to żywy ogień
    } else {
        final_color = smoke_color.rgb;  // Brzegi przechodzą w ciemną spaleniznę
    }
    
    ALBEDO = final_color;
}