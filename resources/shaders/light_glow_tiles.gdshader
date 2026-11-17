// Used by LightMap's copy of the glowing tiles (tile custom data "glows"),
// such as ore on the ceiling. Unlike the sprite glow it replaces what is
// already in the light map instead of adding to it: the ceiling below has set
// the blue "always dark" channel, and these pixels must glow anyway. The copy
// keeps the tiles' z index, so it is drawn after the ceiling mask.
//
// Green 0.5 marks a dimmed tile glow (sprite glow is green 1.0), and red holds
// how bright it is. The composite snaps that to a palette band.
shader_type canvas_item;
render_mode blend_mix, unshaded;

// 0..1, set by LightMap (tile_glow_strength).
uniform float glow_strength = 1.0;

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(glow_strength, 0.5, 0.0, alpha > 0.5 ? 1.0 : 0.0);
}
