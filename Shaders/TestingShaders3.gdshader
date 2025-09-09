shader_type spatial;
render_mode unshaded, depth_draw_opaque;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

uniform vec3 shadow_color : source_color = vec3(0.0);
uniform float sensitivity = 80.0; // higher = more sensitive
uniform float thickness = 1.0;

void fragment() {
    vec2 e = vec2(thickness) / VIEWPORT_SIZE;

    float dC = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float dL = texture(DEPTH_TEXTURE, SCREEN_UV - vec2(e.x, 0.0)).r;
    float dR = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(e.x, 0.0)).r;
    float dU = texture(DEPTH_TEXTURE, SCREEN_UV - vec2(0.0, e.y)).r;
    float dD = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(0.0, e.y)).r;

    float dUL = texture(DEPTH_TEXTURE, SCREEN_UV - e).r;
    float dUR = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(e.x, -e.y)).r;
    float dDL = texture(DEPTH_TEXTURE, SCREEN_UV + vec2(-e.x, e.y)).r;
    float dDR = texture(DEPTH_TEXTURE, SCREEN_UV + e).r;

    // Sobel filter
    float gx = (dUL + 2.0*dL + dDL) - (dUR + 2.0*dR + dDR);
    float gy = (dUL + 2.0*dU + dUR) - (dDL + 2.0*dD + dDR);

    float edge_strength = sqrt(gx * gx + gy * gy) * sensitivity;

    edge_strength = clamp(edge_strength, 0.0, 1.0);

    vec3 col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    ALBEDO = mix(col, shadow_color, edge_strength);
    ALPHA = edge_strength;
}