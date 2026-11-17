// Used by LightMap's copy of the ceiling tiles: draws their shape (overhang
// included) into the light map's blue channel, which tells the composite to
// keep those pixels at the darkness colour, whatever light falls on them.
shader_type canvas_item;
render_mode blend_add, unshaded;

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(0.0, 0.0, alpha > 0.5 ? 1.0 : 0.0, 1.0);
}
