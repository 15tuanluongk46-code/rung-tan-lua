shader_type canvas_item;
uniform vec4 edge_color : source_color = vec4(0.055, 0.10, 0.12, 1.0);
uniform float rim_strength = 0.12;
varying vec4 canvas_tint;
void vertex() { canvas_tint = COLOR; }
void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float adjacent = max(max(texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a,
		texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0)).a),
		max(texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a,
		texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a));
	if (base.a < 0.1 && adjacent > 0.5) {
		COLOR = edge_color * canvas_tint;
	} else {
		float upper_edge = 1.0 - texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
		COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.84, 0.56), upper_edge * rim_strength);
	}
}
