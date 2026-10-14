shader_type canvas_item;
uniform float amount = 0.0;
void fragment() {
	float radius = length((UV - vec2(0.5)) * vec2(1.0, 0.8));
	float edge = smoothstep(0.24, 0.58, radius);
	COLOR = vec4(0.65, 0.07, 0.025, edge * amount);
}
