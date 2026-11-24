shader_type canvas_item;
// The station's monitor, seen in first person: scanlines, a soft vignette,
// a faint flicker, and the Day 7 blackout. Not quantised -- it is a screen.

uniform vec2 res = vec2(640.0, 360.0);
uniform float scan = 0.10;
uniform float vignette = 0.32;
uniform float blackout = 0.0;
uniform float flicker = 0.015;
uniform float red = 0.0;
uniform float bright = 1.0;

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb * bright;
	float sub = fract(UV.y * res.y);
	c *= 1.0 - scan * step(0.5, sub);
	vec2 d = UV - 0.5;
	c *= clamp(1.0 - dot(d, d) * vignette * 2.0, 0.0, 1.0);
	c *= 1.0 - flicker * (0.5 + 0.5 * sin(TIME * 47.0));
	float l = dot(c, vec3(0.3, 0.59, 0.11));
	c = mix(c, vec3(l * 1.2, l * 0.25, l * 0.25), red);
	c *= 1.0 - blackout;
	COLOR = vec4(c, 1.0);
}
