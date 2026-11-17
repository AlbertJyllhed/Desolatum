// Hit flash for enemies that hide in the dark: the sprite is only drawn where
// the light map has light (same bands and dither as the rest of the lighting).
shader_type canvas_item;

#include "res://resources/shaders/stepped_light.gdshaderinc"

uniform float lerp_percent : hint_range(0.0, 1.0);

void vertex() {
	STEPPED_LIGHT_VERTEX;
}

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec4 final_color = mix(texture_color, vec4(1.0, 1.0, 1.0, texture_color.a), lerp_percent);
	float level = stepped_light_level(texture(light_map, SCREEN_UV).r, stepped_light_world_pos);
	final_color.a *= level > 0.0 ? 1.0 : 0.0;
	COLOR = final_color;
}
