shader_type canvas_item;

// Red edge vignette for the low health warning. Put it on a full-screen
// ColorRect in the HUD. The ColorRect's own color is ignored; the script
// (ui/low_health_warning.gd) drives `intensity` to fade and pulse it.
//
// The vignette is made of `steps` hard color bands. The innermost (faintest)
// band is 1 game pixel thick, the next 2, then 3, and so on, so the outermost
// (strongest) band at the screen edge is `steps` pixels thick. The total
// width is therefore 1 + 2 + ... + steps (4 steps = 10 px, 6 = 21 px).
//
// The edge distance is the same as the vignette in crt_overlay.gdshader:
// distance to the nearest edge of the rect in whole game pixels, so it stays
// pixel-perfect at 320x180.

/// The vignette color. Its alpha multiplies with the strength.
uniform vec4 color : source_color = vec4(0.75, 0.0, 0.05, 1.0);
/// 0 = invisible, 1 = full strength. Set from the script every frame.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
/// How opaque the outermost band gets at full intensity.
uniform float max_alpha : hint_range(0.0, 1.0) = 0.6;
/// Number of color bands. Also sets how far in the vignette reaches.
uniform int steps : hint_range(1, 16) = 4;

varying vec2 local_position;


void vertex() {
	local_position = VERTEX;
}


void fragment() {
	// Size of the rect in its own pixels (see crt_overlay.gdshader).
	vec2 rect_size = local_position / max(UV, vec2(0.0001));
	vec2 pixel = floor(local_position);

	vec2 to_edge = min(pixel, rect_size - 1.0 - pixel);
	int edge = int(min(to_edge.x, to_edge.y));

	int band_count = max(steps, 1);
	int total_width = band_count * (band_count + 1) / 2;

	float amount = 0.0;
	if (edge < total_width) {
		// Pixels counted from the inner edge of the vignette (0 = innermost).
		int from_inside = total_width - 1 - edge;
		// Walk outward band by band: band 1 is 1 px, band 2 is 2 px, ...
		int band = 1;
		int band_end = 1;
		while (from_inside >= band_end) {
			band += 1;
			band_end += band;
		}
		amount = float(band) / float(band_count);
	}

	COLOR = vec4(color.rgb, color.a * max_alpha * intensity * amount);
}
