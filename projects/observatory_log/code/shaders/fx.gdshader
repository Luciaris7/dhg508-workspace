shader_type canvas_item;
// Full-screen effects read from the already-composited screen.
// tear: Day 4's two-second episodes (Q-15: tearing smear, not a true blur).
// shake: whole-frame jolt for thunder and impacts.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float tear = 0.0;
uniform vec2 shake = vec2(0.0);
uniform float t = 0.0;
uniform float aberr = 0.0;

float h11(float x) { return fract(sin(x * 91.3458) * 47453.5453); }

void fragment() {
	vec2 uv = SCREEN_UV + shake;
	vec3 c;
	if (tear > 0.001) {
		float band = floor(uv.y * 60.0);
		float k = floor(t * 18.0);
		float h = h11(band * 1.7 + k * 13.1);
		float off = (h > 0.55 ? (h - 0.55) * 0.22 : 0.0) * tear * sign(h11(band + k) - 0.5);
		float wav = sin(uv.y * 40.0 + t * 9.0) * 0.004 * tear;
		vec2 tu = uv + vec2(off + wav, 0.0);
		c = texture(screen_tex, tu).rgb;
		vec3 s = vec3(0.0);
		for (int i = 1; i <= 8; i++) {
			s += texture(screen_tex, tu - vec2(float(i) * 0.0045 * tear, 0.0)).rgb;
		}
		c = mix(c, s / 8.0, 0.6 * tear);
		vec3 g = texture(screen_tex, tu + vec2(0.012, 0.006) * tear).rgb;
		c = mix(c, g, 0.28 * tear);
		c.r = mix(c.r, texture(screen_tex, tu + vec2(0.006 * tear, 0.0)).r, 0.7);
		c *= 1.0 - 0.18 * tear;
	} else {
		c = texture(screen_tex, uv).rgb;
	}
	if (aberr > 0.0) {
		c.r = texture(screen_tex, uv + vec2(aberr, 0.0)).r;
		c.b = texture(screen_tex, uv - vec2(aberr, 0.0)).b;
	}
	COLOR = vec4(c, 1.0);
}
