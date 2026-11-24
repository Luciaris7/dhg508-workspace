shader_type canvas_item;
// Every world sprite uses this. It does two jobs:
//  1. Lighting: ambient * texture + up to 8 point lights (world space).
//     (Godot's Light2D does not reach custom shaders in this renderer, so the
//     lighting lives here.)
//  2. Flesh: living tissue over the opaque pixels when amount > 0 --
//     world-anchored, squirming, ridged veins pulsing on a heartbeat.

uniform vec2 cam_origin = vec2(0.0);       // world position of the screen's top-left
uniform vec3 ambient = vec3(1.0);
uniform vec4 l0 = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec3 c0 = vec3(0.0);
uniform vec4 l1 = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec3 c1 = vec3(0.0);
uniform vec4 l2 = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec3 c2 = vec3(0.0);
uniform vec4 l3 = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec3 c3 = vec3(0.0);
uniform vec4 l4 = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec3 c4 = vec3(0.0);
uniform vec4 l5 = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec3 c5 = vec3(0.0);
uniform vec4 l6 = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec3 c6 = vec3(0.0);
uniform vec4 l7 = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec3 c7 = vec3(0.0);
uniform float amount = 0.0;
uniform float beat_rate = 1.1;
uniform float unlit = 0.0;                  // 1 = ignore lighting (self-lit things)
// 1 = an object the player interacts with: the flesh only touches its edges,
// so it always stays recognisable (user, 2026-11-16).
uniform float protect = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return s;
}

varying vec2 wv;

void vertex() {
	wv = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

vec3 pl(vec2 w, vec4 L, vec3 c) {
	float k = clamp(1.0 - distance(w, L.xy) / L.z, 0.0, 1.0);
	return c * (k * k * (3.0 - 2.0 * k)) * L.w;
}

void fragment() {
	vec4 tex = COLOR;
	vec2 wpos = wv;
	vec3 base = tex.rgb;
	if (amount > 0.001 && tex.a > 0.01) {
		// The world is still the world: tissue grows up out of the ground in
		// patches, veins run over surfaces, colours sicken a little -- but the
		// shapes underneath stay readable.
		vec2 p = floor(wpos);
		float t = TIME;
		vec2 q = p * 0.085 + vec2(sin(t * 0.8 + p.y * 0.06), cos(t * 0.6 + p.x * 0.05)) * 0.35;
		float n = fbm(q) * 0.75 + fbm(p * 0.025) * 0.5;
		float ground = clamp((p.y - 70.0) / 85.0, 0.0, 1.0);          // creeping up from below
		float thr = 1.30 - amount * 0.62 - ground * 0.30 * amount;
		float cover = smoothstep(thr, thr + 0.05, n) * (1.0 - protect * 0.85);
		float m = fbm(q * 2.2 + 7.0);
		vec3 fl = mix(vec3(0.36, 0.06, 0.10), vec3(0.84, 0.38, 0.40), m);
		float r = abs(noise(p * 0.06 + vec2(t * 0.04, 3.0)) - 0.5);
		float vein = 1.0 - smoothstep(0.0, 0.03, r);
		float beat = pow(0.5 + 0.5 * sin(t * 6.2832 * beat_rate), 6.0);
		vec3 vcol = mix(vec3(0.24, 0.02, 0.06), vec3(0.62, 0.08, 0.14), beat);
		fl = mix(fl, vcol, vein * 0.92);
		float hl = step(0.80, fbm(q * 3.3 - vec2(t * 0.15, 0.0)));
		fl = mix(fl, vec3(0.92, 0.66, 0.62), hl * 0.55);
		float l = dot(tex.rgb, vec3(0.3, 0.59, 0.11));
		fl *= 0.45 + l * 1.1;
		vec3 sick = mix(tex.rgb, tex.rgb * vec3(1.06, 0.86, 0.86), amount * 0.6);
		// fine veins over what is not yet covered
		float thin = vein * smoothstep(0.35, 0.75, fbm(p * 0.04 + 11.0)) * amount * (1.0 - protect * 0.6);
		sick = mix(sick, vcol * (0.6 + l), thin * 0.7);
		base = mix(sick, fl, cover);
	}
	vec3 lit = ambient + pl(wpos, l0, c0) + pl(wpos, l1, c1) + pl(wpos, l2, c2) + pl(wpos, l3, c3) + pl(wpos, l4, c4) + pl(wpos, l5, c5) + pl(wpos, l6, c6) + pl(wpos, l7, c7);
	lit = mix(lit, vec3(1.0), unlit);
	COLOR = vec4(base * lit, tex.a);
}
