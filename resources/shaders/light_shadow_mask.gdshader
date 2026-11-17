// Used by LightMap's copies of the shadows (sprites named "Shadow" and the
// wall shadow tiles): marks their shape as "in shadow" in the light map's
// alpha channel (0.5 instead of 1). The composite turns those lit pixels into
// the dimmest light band. Drawn after everything else in the light map except
// the shadow clearers (light_shadow_clear.gdshader).
//
// It reads what the light map holds so far and writes it back with the new
// alpha, instead of blending: every shadow reads the same copy, so where
// shadows overlap the mark is still 0.5 and nothing gets darker.
shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D light_so_far : hint_screen_texture, filter_nearest;

void fragment() {
	if (texture(TEXTURE, UV).a < 0.1) {
		discard;
	}
	COLOR = vec4(texture(light_so_far, SCREEN_UV).rgb, 0.5);
}
