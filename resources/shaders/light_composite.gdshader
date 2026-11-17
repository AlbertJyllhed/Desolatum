// Drawn by LightMap over the whole view, above the world and below the UI.
// Bands the combined light from the light map and colours the scene with
// the palette, so every pixel is the darkness colour, the light colour or
// one of the steps in between. Unlit pixels (ceilings, blue in the light
// map) always get the darkness colour; glowing sprites (green 1.0) keep their
// own colour; glowing tiles (green 0.5) get the palette band their strength
// (red) snaps to. Pixels in the darkest band lose their own colour: their
// curved brightness snaps to light_dark_shades steps (no dither), coloured
// from black up to the darkness colour, so each biome's darkness gets its
// own small palette. Lit pixels marked "in shadow" (alpha below 0.75 in the
// light map, see light_shadow_mask.gdshader) get the second-dimmest lit band
// (the middle one with 3 bands), however bright the light is and however many
// shadows overlap. A shadow is never brighter than the light it's in.
shader_type canvas_item;
render_mode unshaded;

#include "res://resources/shaders/stepped_light.gdshaderinc"

// Number of shades in the darkest band, not counting black (0 = keep the
// scene's own colours there).
global uniform int light_dark_shades;
// Curve applied to a dark pixel's brightness before it is snapped: below 1
// lifts dark colours so the shades spread over the range the art uses
// (1 = no change).
global uniform float light_dark_curve;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void vertex() {
	STEPPED_LIGHT_VERTEX;
}

// A dark pixel as one of light_dark_shades steps from black to the darkness
// colour, picked by its curved brightness. No dither here: in-between
// brightness would turn textured areas like ceilings into a busy checker.
vec3 dark_shade(vec3 scene) {
	float shades = float(light_dark_shades);
	float brightness = dot(scene, vec3(0.299, 0.587, 0.114));
	brightness = pow(clamp(brightness, 0.0, 1.0), max(light_dark_curve, 0.01));
	float step_value = clamp(round(brightness * shades), 0.0, shades) / shades;
	return light_ambient_color.rgb * step_value;
}

void fragment() {
	vec3 scene = texture(screen_texture, SCREEN_UV).rgb;
	vec4 light = texture(light_map, SCREEN_UV);
	bool unlit = light.b > 0.5;
	bool glows = light.g > 0.75 && !unlit;
	bool tile_glows = light.g > 0.25 && light.g <= 0.75 && !unlit;
	bool shadowed = light.a < 0.75;
	float level = unlit ? 0.0 : stepped_light_level(light.r, stepped_light_world_pos);
	if (shadowed && level > 0.0) {
		// Every shadow in the light is the second-dimmest lit band, or the
		// band it's in if that is dimmer.
		level = min(level, 2.0 / float(max(light_bands, 1)));
	}
	if (tile_glows) {
		// A fixed band, no dither: the nearest band to the glow strength.
		float bands = float(max(light_bands, 1));
		level = clamp(round(light.r * bands), 1.0, bands) / bands;
	}
	vec3 lit = scene * light_palette(level);
	if (level <= 0.0 && light_dark_shades > 0) {
		lit = dark_shade(scene);
	}
	COLOR = vec4(glows ? scene : lit, 1.0);
}
