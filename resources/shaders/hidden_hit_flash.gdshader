// NOTE: Shader automatically converted from Godot Engine 4.2.1.stable's CanvasItemMaterial.
shader_type canvas_item;
render_mode blend_mix,light_only;

uniform float lerp_percent : hint_range(0.0, 1.0);

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec4 final_color = mix(texture_color, vec4(1.0, 1.0, 1.0, texture_color.a), lerp_percent);
	COLOR = final_color;
}