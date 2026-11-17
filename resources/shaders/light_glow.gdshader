// Used by LightGlowComponent: draws the glowing sprite's shape into the light
// map's green channel, which tells the composite to leave it unlit.
shader_type canvas_item;
render_mode blend_add, unshaded;

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(0.0, alpha > 0.5 ? 1.0 : 0.0, 0.0, 1.0);
}
