// Used by LightMap's copies of what stands on top of shadows (the sprites of
// anything that has a shadow, such as the player, held weapons, enemies and
// props, and the wall tiles): clears the "in shadow" mark under their shape,
// so a wall shadow doesn't darken the player standing in it. Drawn after the
// shadow marks (light_shadow_mask.gdshader).
//
// It reads the same copy of the light map the shadows read, taken before any
// shadow was drawn, and writes it back with full alpha.
shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D light_so_far : hint_screen_texture, filter_nearest;

void fragment() {
	if (texture(TEXTURE, UV).a < 0.5) {
		discard;
	}
	COLOR = vec4(texture(light_so_far, SCREEN_UV).rgb, 1.0);
}
