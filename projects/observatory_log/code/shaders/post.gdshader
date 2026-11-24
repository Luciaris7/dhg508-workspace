shader_type canvas_item;
// World / minigame / ending post-process.
// Grade -> vignette -> fade -> 4x4 Bayer dither -> nearest of the 32-colour
// palette -> flash. This is what makes every frame "direction A": cold, dark,
// few colours, dithered gradients, regardless of what was drawn.

uniform sampler2D palette : filter_nearest;
uniform vec2 res = vec2(320.0, 180.0);
uniform float quantize = 1.0;
uniform float dither = 0.085;
uniform vec3 grade = vec3(1.0);
uniform vec3 lift = vec3(0.0);
uniform float sat = 1.0;
uniform float contrast = 1.0;
uniform float vignette = 0.28;
uniform float fade = 0.0;
uniform vec3 fade_col = vec3(0.0);
uniform float flash = 0.0;
uniform vec3 flash_col = vec3(1.0);
uniform float grain = 0.02;
uniform float scan = 0.0;
uniform float red_shift = 0.0;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = y * 4 + x;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[i] + 0.5) / 16.0;
}

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 px = floor(UV * res);
	vec2 suv = (px + 0.5) / res;
	vec3 c = texture(TEXTURE, suv).rgb;

	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, sat);
	c = (c - 0.5) * contrast + 0.5;
	c = c * grade + lift;
	c.r += red_shift * (0.25 + l * 0.6);
	c.gb *= 1.0 - red_shift * 0.55;

	vec2 d = suv - 0.5;
	d.x *= 1.25;
	c *= clamp(1.0 - dot(d, d) * vignette * 2.4, 0.0, 1.0);
	c += (h21(px + floor(TIME * 12.0)) - 0.5) * grain;
	c = mix(c, fade_col, fade);

	vec3 outc = c;
	if (quantize > 0.5) {
		vec3 cd = c + (bayer4(px) - 0.5) * dither;
		float best = 1e9;
		for (int i = 0; i < 32; i++) {
			vec3 p = texelFetch(palette, ivec2(i, 0), 0).rgb;
			vec3 e = cd - p;
			float dd = e.r * e.r * 2.0 + e.g * e.g * 4.0 + e.b * e.b * 3.0;
			if (dd < best) {
				best = dd;
				outc = p;
			}
		}
	}
	outc = mix(outc, flash_col, flash);
	if (scan > 0.0) {
		float sub = fract(UV.y * res.y);
		outc *= 1.0 - scan * step(0.5, sub);
	}
	COLOR = vec4(outc, 1.0);
}
