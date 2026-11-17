// Pixel-perfect dissolve: whole texture pixels disappear one at a time, in a
// random order, with no blur. The order is picked per texture pixel, so it
// stays the same while the sprite moves or rotates. Driven by
// DissolveComponent (components/core/dissolve_component.gd).
shader_type canvas_item;

// 0 = fully visible, 1 = fully gone.
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
// Changes which pixels go first, so copies of one sprite dissolve differently.
uniform float seed = 0.0;

// A random 0..1 value for a texture pixel.
float pixel_random(vec2 pixel) {
	return fract(sin(dot(pixel, vec2(127.1, 311.7)) + seed * 17.13) * 43758.5453);
}

void fragment() {
	vec2 pixel = floor(UV / TEXTURE_PIXEL_SIZE);
	if (pixel_random(pixel) < dissolve_amount) {
		discard;
	}
	// COLOR keeps its default (texture x modulate).
}
