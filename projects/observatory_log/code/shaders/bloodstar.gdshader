shader_type canvas_item;
// The blood star. A lit sphere of tissue, slowly turning, veins pulsing on a
// heartbeat, a corona of red light. Eyes are drawn on top by script.

uniform float beat_rate = 0.9;
uniform float spin = 0.02;
uniform vec2 light_dir = vec2(-0.5, -0.6);
uniform float glow = 1.0;
uniform float alpha = 1.0;

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
	for (int i = 0; i < 5; i++) {
		s += a * noise(p);
		p *= 2.07;
		a *= 0.5;
	}
	return s;
}

void fragment() {
	vec2 p = (UV * 2.0 - 1.0) * 1.4;
	float r2 = dot(p, p);
	float t = TIME;
	float beat = pow(0.5 + 0.5 * sin(t * 6.2832 * beat_rate), 5.0);
	if (r2 > 1.0) {
		float halo = exp(-(sqrt(r2) - 1.0) * 9.0) * glow * (0.55 + 0.25 * beat);
		COLOR = vec4(0.65, 0.06, 0.08, halo * alpha);
	} else {
		float z = sqrt(1.0 - r2);
		vec3 n = vec3(p, z);
		float lon = atan(n.x, n.z) + t * spin;
		float lat = asin(clamp(n.y, -1.0, 1.0));
		vec2 sp = vec2(lon * 3.0, lat * 3.0);
		float f = fbm(sp * 1.6);
		vec3 base = mix(vec3(0.30, 0.04, 0.07), vec3(0.72, 0.16, 0.18), f);
		float rid = abs(fbm(sp * 2.4 + vec2(5.2, 1.3)) - 0.5);
		float vein = 1.0 - smoothstep(0.0, 0.03, rid);
		float rid2 = abs(noise(sp * 6.0 + 9.0) - 0.5);
		float vein2 = 1.0 - smoothstep(0.0, 0.05, rid2);
		vec3 vc = mix(vec3(0.16, 0.01, 0.04), vec3(0.95, 0.22, 0.20), beat);
		base = mix(base, vc, vein * 0.95);
		base = mix(base, vc * 0.8, vein2 * 0.45);
		float wet = step(0.78, fbm(sp * 4.0 + 2.0));
		base = mix(base, vec3(0.90, 0.55, 0.52), wet * 0.35);
		vec3 L = normalize(vec3(light_dir, 0.7));
		float dif = clamp(dot(n, L), 0.0, 1.0);
		float rim = pow(1.0 - z, 3.0);
		vec3 c = base * (0.25 + dif * 0.95) + vec3(0.9, 0.1, 0.1) * rim * 0.9 * glow;
		COLOR = vec4(c, alpha);
	}
}
