class_name Ephemeris
extends RefCounted
## Real planetary positions, offline. Truncated VSOP87 series exported from
## Astronomy Engine (MIT) are evaluated at runtime for Mercury..Neptune; the
## Moon comes from a daily table (1980-2120) with cubic interpolation.
## Output: geocentric ecliptic (J2000) longitude in degrees and distance in AU.

const NAMES := ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
const VSOP_INDEX := {"Mercury": 0, "Venus": 1, "Earth": 2, "Mars": 3, "Jupiter": 4, "Saturn": 5, "Uranus": 6, "Neptune": 7}
const LIGHT_DAYS_PER_AU := 0.0057755183

static var _vsop: Array = []
static var _moon := PackedFloat32Array()
static var _moon_start := 0.0
static var _moon_days := 0


static func _ensure() -> void:
	if not _vsop.is_empty():
		return
	_vsop = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/vsop.json"))
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/moon.json"))
	_moon_start = float(meta["start_ut"])
	_moon_days = int(meta["days"])
	var bytes := FileAccess.get_file_as_bytes("res://assets/data/moon.bin")
	_moon = bytes.to_float32_array()


## Days since J2000 (UT ~ TT here; the 69 s difference is far below the chart's resolution).
static func ut_from_unix(unix: float) -> float:
	return unix / 86400.0 + 2440587.5 - 2451545.0


static func _formula(f: Array, t: float, clamp_angle: bool) -> float:
	var tp := 1.0
	var coord := 0.0
	for series in f:
		var s := 0.0
		for term in series:
			s += float(term[0]) * cos(float(term[1]) + float(term[2]) * t)
		var inc := tp * s
		if clamp_angle:
			inc = fmod(inc, TAU)
		coord += inc
		tp *= t
	return coord


static func helio(body: String, ut: float) -> Vector3:
	_ensure()
	var m: Array = _vsop[VSOP_INDEX[body]]
	var t := ut / 365250.0
	var lon := _formula(m[0], t, true)
	var lat := _formula(m[1], t, false)
	var rad := _formula(m[2], t, false)
	var rc := rad * cos(lat)
	return Vector3(rc * cos(lon), rc * sin(lon), rad * sin(lat))


static func _moon_at(ut: float) -> Vector2:
	_ensure()
	var d := ut - _moon_start
	var i := int(floor(d))
	i = clampi(i, 1, _moon_days - 3)
	var f := clampf(d - i, 0.0, 1.0) if d >= 1.0 and d < _moon_days - 2 else clampf(d - i, -1.0, 2.0)
	var lons := []
	var dists := []
	for k in range(-1, 3):
		lons.append(float(_moon[(i + k) * 2]))
		dists.append(float(_moon[(i + k) * 2 + 1]))
	for k in range(1, 4):
		while lons[k] - lons[k - 1] > 180.0:
			lons[k] -= 360.0
		while lons[k] - lons[k - 1] < -180.0:
			lons[k] += 360.0
	var lon := _cubic(lons[0], lons[1], lons[2], lons[3], f)
	var dist := _cubic(dists[0], dists[1], dists[2], dists[3], f)
	return Vector2(fposmod(lon, 360.0), dist)


static func _cubic(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


## {name: Vector2(lon_deg, dist_au)} for the nine bodies.
static func positions(ut: float) -> Dictionary:
	var out := {}
	var earth := helio("Earth", ut)
	var sun := -earth
	out["Sun"] = Vector2(fposmod(rad_to_deg(atan2(sun.y, sun.x)), 360.0), sun.length())
	out["Moon"] = _moon_at(ut)
	for n in ["Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]:
		var g := helio(n, ut) - earth
		var g2 := helio(n, ut - g.length() * LIGHT_DAYS_PER_AU) - earth
		out[n] = Vector2(fposmod(rad_to_deg(atan2(g2.y, g2.x)), 360.0), g2.length())
	return out


## Elongation (deg) of the Galilean moons and Titan from their planet, as seen
## from Earth -- a circular-orbit approximation, for display only.
static func satellites(ut: float) -> Dictionary:
	var out := {}
	var jd := ut + 2451545.0
	# periods (days) and epoch phases at J2000 (approximate mean longitudes)
	var sats := {
		"Io": [1.769137786, 106.07719, 5.9],
		"Europa": [3.551181, 175.73161, 9.4],
		"Ganymede": [7.15455296, 120.55883, 15.0],
		"Callisto": [16.6890184, 84.44459, 26.4],
		"Titan": [15.945421, 0.0, 20.3],
	}
	for k in sats.keys():
		var a: Array = sats[k]
		var ang := deg_to_rad(float(a[1]) + 360.0 * (ut / float(a[0])))
		out[k] = Vector2(cos(ang), sin(ang) * 0.25) * float(a[2])
	return out
