shader_type spatial;
render_mode unshaded, depth_draw_opaque;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform vec3 shadow_color : source_color = vec3(0.0);
uniform float shadow_thickness = 1.0;

void fragment() {
    vec2 e = vec2(1.0 / VIEWPORT_SIZE.x, 1.0 / VIEWPORT_SIZE.y);

    vec3 col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    float center = texture(DEPTH_TEXTURE, SCREEN_UV).r;

    float diff = 0.0;
    for (float x = -shadow_thickness; x <= shadow_thickness; x++) {
        for (float y = -shadow_thickness; y <= shadow_thickness; y++) {
            if (x == 0.0 && y == 0.0) continue;
            float sample = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(x,y)*e).r;
            diff += abs(center - sample);
        }
    }

    diff = smoothstep(0.001, 0.01, diff); // tweak thresholds

    ALBEDO = mix(col, shadow_color, diff);
    ALPHA = diff;
}
