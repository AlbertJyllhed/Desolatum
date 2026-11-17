shader_type canvas_item;
render_mode unshaded;

// Turns a soft density map (the gas puffs drawn into a SubViewport) into
// one pixel-art cloud: flat colour bands plus a 1 px outline.
// Only the alpha channel of TEXTURE is used as density.
// GasVent reads edge_threshold to size the per-puff hitbox shapes, so the
// damage area matches what this shader draws.

uniform vec4 outline_color : source_color = vec4(0.05, 0.22, 0.08, 0.85);
uniform vec4 edge_color : source_color = vec4(0.16, 0.5, 0.2, 0.55);
uniform vec4 core_color : source_color = vec4(0.42, 0.8, 0.32, 0.7);
// Density above this is part of the cloud.
uniform float edge_threshold : hint_range(0.0, 1.0) = 0.15;
// Density above this is drawn in the lighter core colour.
uniform float core_threshold : hint_range(0.0, 1.0) = 0.5;
uniform bool show_outline = true;


void fragment() {
	float density = texture(TEXTURE, UV).a;

	if (density >= core_threshold) {
		COLOR = core_color;
	} else if (density >= edge_threshold) {
		COLOR = edge_color;
	} else if (show_outline) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float neighbour = max(
			max(texture(TEXTURE, UV + vec2(px.x, 0.0)).a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a),
			max(texture(TEXTURE, UV + vec2(0.0, px.y)).a, texture(TEXTURE, UV - vec2(0.0, px.y)).a)
		);
		COLOR = neighbour >= edge_threshold ? outline_color : vec4(0.0);
	} else {
		COLOR = vec4(0.0);
	}
}
