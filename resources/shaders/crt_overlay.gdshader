shader_type canvas_item;

// CRT effect for menus. Two ways to use it:
//
// 1. On a SubViewportContainer (stretch on) whose SubViewport (Transparent BG
//    on) holds the menu. The shader gets the menu on its own (TEXTURE) and the
//    game behind it (screen_texture). The background gets the full tint, the
//    menu keeps its own colors (see menu_tint_amount), and scanlines, flicker,
//    band and vignette go over both.
// 2. On a ColorRect on top of something, with menu_in_texture off. Then it
//    only sees the screen and tints everything under it.
//
// The game renders at 320x180, so every fragment is one game pixel and the
// scanlines are always whole pixels. Keep the node on whole-pixel positions
// so the lines start cleanly at its top edge.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

/// On: the node is a SubViewportContainer and its texture is the menu.
/// Off: the node is a plain overlay (e.g. a ColorRect) and only sees the screen.
uniform bool menu_in_texture = true;

group_uniforms color;
/// The CRT color. Its alpha multiplies with opacity.
uniform vec4 tint : source_color = vec4(0.35, 1.0, 0.55, 1.0);
/// How much the menu itself is tinted: 0 = it keeps its own colors,
/// 1 = it becomes the tint color like the background. Scanlines, flicker,
/// band and vignette apply either way.
uniform float menu_tint_amount : hint_range(0.0, 1.0) = 0.0;
/// 0 = the effect is invisible, 1 = fully replaces what is under it.
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
/// How bright pure black under the overlay becomes (faint screen glow).
uniform float black_level : hint_range(0.0, 0.5) = 0.05;
/// Multiplies the brightness of the CRT image.
uniform float brightness : hint_range(0.0, 3.0) = 1.2;

group_uniforms scanlines;
/// Length of one scanline cycle, in game pixels.
uniform int scanline_spacing : hint_range(1, 8) = 2;
/// How many pixel rows of each cycle are dark.
uniform int scanline_thickness : hint_range(0, 8) = 1;
/// How much the dark rows are darkened.
uniform float scanline_darkness : hint_range(0.0, 1.0) = 0.35;

group_uniforms flicker;
uniform bool flicker_enabled = true;
/// How much the brightness can drop during a flicker.
uniform float flicker_amount : hint_range(0.0, 0.5) = 0.04;
/// Flicker steps per second.
uniform float flicker_speed : hint_range(1.0, 60.0) = 20.0;

group_uniforms scrolling_band;
uniform bool band_enabled = true;
/// How much brighter the band makes the image.
uniform float band_strength : hint_range(0.0, 1.0) = 0.15;
/// Height of the band, in game pixels.
uniform float band_height : hint_range(1.0, 64.0) = 12.0;
/// Scroll speed, in game pixels per second.
uniform float band_speed : hint_range(1.0, 200.0) = 30.0;
/// Extra distance (in game pixels) the band travels below the rect before it
/// starts again at the top. Bigger = longer pause between bands.
uniform float band_gap : hint_range(0.0, 500.0) = 60.0;

group_uniforms vignette;
uniform bool vignette_enabled = true;
/// How dark the very edge gets.
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
/// How far in from each edge the darkening reaches, in game pixels.
uniform float vignette_width : hint_range(1.0, 64.0) = 10.0;

group_uniforms;

varying vec2 local_position;


void vertex() {
	local_position = VERTEX;
}


/// Turns a color into the single-color CRT version of it.
vec3 tint_color(vec3 color) {
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	return tint.rgb * mix(black_level, 1.0, luminance);
}


float hash(float n) {
	return fract(sin(n) * 43758.5453);
}


void fragment() {
	vec3 background = texture(screen_texture, SCREEN_UV).rgb;
	vec3 menu = vec3(0.0);
	float menu_alpha = 0.0;
	if (menu_in_texture) {
		// The SubViewport is drawn onto a transparent background, so its
		// colors come out already multiplied by alpha. Undo that.
		vec4 menu_sample = texture(TEXTURE, UV);
		menu_alpha = menu_sample.a;
		menu = menu_alpha > 0.0 ? menu_sample.rgb / menu_alpha : vec3(0.0);
	}

	// What the screen looks like without the effect: menu over background.
	vec3 under = mix(background, menu, menu_alpha);

	vec3 menu_color = mix(menu, tint_color(menu), menu_tint_amount);
	vec3 crt = mix(tint_color(background), menu_color, menu_alpha) * brightness;

	// Scanlines, counted from the top of the rect in whole pixels.
	int row = int(floor(local_position.y));
	int spacing = max(scanline_spacing, 1);
	if (row % spacing >= spacing - scanline_thickness) {
		crt *= 1.0 - scanline_darkness;
	}

	if (flicker_enabled) {
		crt *= 1.0 - flicker_amount * hash(floor(TIME * flicker_speed));
	}

	// Size of the rect in its own pixels. UV goes 0..1 across the rect, so
	// position / UV is the full size. (Screen-space derivatives would give the
	// wrong size when the rect is zoomed, e.g. in the editor.)
	vec2 rect_size = local_position / max(UV, vec2(0.0001));
	vec2 pixel = floor(local_position);

	if (band_enabled) {
		// The band starts above the top edge, scrolls down past the bottom,
		// then waits band_gap pixels' worth of travel before coming back.
		float cycle = rect_size.y + band_height + band_gap;
		float band_top = floor(mod(TIME * band_speed, cycle)) - band_height;
		float inside = (pixel.y - band_top) / band_height;
		if (inside >= 0.0 && inside <= 1.0) {
			crt *= 1.0 + band_strength * sin(inside * PI);
		}
	}

	if (vignette_enabled) {
		// Distance to the nearest edge of the rect, in whole pixels.
		vec2 to_edge = min(pixel, rect_size - 1.0 - pixel);
		float edge = min(to_edge.x, to_edge.y);
		crt *= 1.0 - vignette_strength * (1.0 - smoothstep(0.0, vignette_width, edge));
	}

	COLOR = vec4(mix(under, crt, opacity * tint.a), 1.0);
}
