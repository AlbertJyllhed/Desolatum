// The white rect LightMap draws into its light map viewport. It starts black,
// and each light mixes its falloff into the red channel, so red ends up as
// the combined light strength with shadows already applied. Glowing sprites
// add to the green channel (light_glow.gdshader).
shader_type canvas_item;

#define STEPPED_LIGHT_NO_MAP
#include "res://resources/shaders/stepped_light.gdshaderinc"

void fragment() {
	COLOR = vec4(0.0, 0.0, 0.0, 1.0);
}

void light() {
	LIGHT = vec4(1.0, 0.0, 0.0, stepped_light_solid(LIGHT_COLOR.a));
}
