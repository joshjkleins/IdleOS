shader_type canvas_item;
// Completed upload goal bars (scripts/upload_section.gd). Uses the bar's own fill color, so rares stay gold.
// - data stream: faint stripes flowing left to right
// - glint: a bright band sweeps across every few seconds (offset per row so they don't move in lockstep)
// - pulse: a slow brightness breathe
// - flash: 1 -> 0 once when the goal is reached (driven from script)

uniform float offset = 0.0;
uniform float flash = 0.0;
uniform vec4 glint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec3 base = COLOR.rgb;
	float stripes = step(0.5, fract(UV.x * 28.0 - TIME * 1.6));
	vec3 col = base * (0.82 + 0.18 * stripes);
	col *= 0.9 + 0.25 * UV.x; // brighter toward the finished end
	float cycle = fract(TIME * 0.28 + offset);
	float center = cycle * 1.8 - 0.4;
	float band = 1.0 - smoothstep(0.0, 0.08, abs(UV.x - center));
	col = mix(col, glint_color.rgb, band * 0.75);
	col *= 1.0 + 0.08 * sin(TIME * 2.2 + offset * 6.2832);
	col = mix(col, vec3(1.0), clamp(flash, 0.0, 1.0));
	COLOR = vec4(col, COLOR.a);
}
