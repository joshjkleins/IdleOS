shader_type canvas_item;
// 2026-11-02: a maxed-out skill's header card (level 99, every apt tier, Firmware installed). Applied to the card's
// PanelContainer (its stylebox only: the text on top stays clean). scripts/header_card.gd set_maxed().
// - a slow prismatic tint drifting across the card
// - a light sheen sweeping diagonally every few seconds
// - the border glows and breathes in the Firmware purple

uniform vec4 tint : source_color = vec4(0.753, 0.518, 0.988, 1.0);
uniform vec2 size = vec2(150.0, 48.0);
uniform float offset = 0.0;
varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec2 p = local / max(size, vec2(1.0));
	vec3 col = COLOR.rgb;
	vec3 hue = 0.5 + 0.5 * cos(6.2832 * (p.x * 0.7 - TIME * 0.12 + offset + vec3(0.0, 0.33, 0.67)));
	col += hue * 0.07;
	float band = fract(p.x * 0.55 - p.y * 0.25 - TIME * 0.3 - offset);
	float sheen = smoothstep(0.0, 0.1, band) * (1.0 - smoothstep(0.1, 0.24, band));
	col = mix(col, vec3(1.0), sheen * 0.10);
	float d = min(min(local.x, size.x - local.x), min(local.y, size.y - local.y));
	float edge = 1.0 - smoothstep(0.0, 2.5, d);
	col += tint.rgb * edge * (0.45 + 0.3 * sin(TIME * 1.8 + offset * 6.2832));
	COLOR = vec4(col, COLOR.a);
}
