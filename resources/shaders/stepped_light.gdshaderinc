// Shared code for the stepped light map (see systems/lighting/light_map.gd).
//
// All lights are drawn into one light map. The composite shader then snaps
// the combined light into light_bands steps with a 4x4 Bayer dither at each
// step, and colours the scene with a fixed palette that runs from the
// darkness colour to the light colour. Every pixel lands on one of those
// palette colours, so overlapping lights always match.
//
// Settings are global shader uniforms (Project Settings > Shader Globals):
//   light_bands         int      number of lit bands (default 4)
//   light_dither_width  float    0 = hard steps, 1 = fully dithered (default 0.5)
//   light_solid_radius  float    0..1, part of each light's radius at full
//                                strength; the bands fit in the rest (default 0)
//   light_color         color    the colour of all lights (default white)
//   light_ambient_color color    the darkness colour; LightMap copies the
//                                scene's CanvasModulate colour into it
//   light_map           sampler2D  set by LightMap at runtime

global uniform int light_bands;
global uniform float light_dither_width;
global uniform float light_solid_radius;
global uniform vec4 light_color;
global uniform vec4 light_ambient_color;
// Shaders drawn INTO the light map must not read it (Godot refuses to bind a
// texture that is being drawn to): they define STEPPED_LIGHT_NO_MAP first.
#ifndef STEPPED_LIGHT_NO_MAP
global uniform sampler2D light_map;
#endif

// World position of the pixel, for the world-locked dither pattern.
varying vec2 stepped_light_world_pos;

#define STEPPED_LIGHT_VERTEX stepped_light_world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy

// Bayer 4x4 threshold for a world pixel, between 0 and 1.
float stepped_light_bayer(vec2 world_pos) {
	const float BAYER[16] = {
		0.0, 8.0, 2.0, 10.0,
		12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0,
		15.0, 7.0, 13.0, 5.0
	};
	ivec2 cell = ivec2(mod(floor(world_pos), 4.0));
	return (BAYER[cell.y * 4 + cell.x] + 0.5) / 16.0;
}

// One light's falloff with the solid radius applied: full strength inside
// it, the rest of the falloff stretched over what's left.
float stepped_light_solid(float falloff) {
	return clamp(falloff / max(1.0 - clamp(light_solid_radius, 0.0, 1.0), 0.001), 0.0, 1.0);
}

// Snaps a 0..1 light strength into light_bands steps (0 stays dark).
float stepped_light_level(float strength, vec2 world_pos) {
	if (strength <= 0.0) {
		return 0.0; // no light at all never gets dithered up
	}
	float bands = float(max(light_bands, 1));
	float dither = (stepped_light_bayer(world_pos) - 0.5) * clamp(light_dither_width, 0.0, 1.0);
	return clamp(ceil(strength * bands + dither), 0.0, bands) / bands;
}

// Colour multiplier for a band level: darkness at 0, the light colour at 1.
vec3 light_palette(float level) {
	return mix(light_ambient_color.rgb, light_color.rgb, level);
}
