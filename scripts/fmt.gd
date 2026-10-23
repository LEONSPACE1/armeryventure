# Formato corto para números grandes: 950, 1.25K, 3.4M, 12B, 1.5aa...
class_name Fmt

const UNITS := ["K", "M", "B", "T"]


static func num(v: float) -> String:
	if v < 1000.0:
		return str(int(floor(v)))
	var e := int(floor(log(v) / log(1000.0)))
	if pow(1000.0, e + 1) <= v:
		e += 1
	e = maxi(e, 1)
	var m := v / pow(1000.0, e)
	var suffix: String
	if e <= UNITS.size():
		suffix = UNITS[e - 1]
	else:
		var i := e - UNITS.size() - 1
		suffix = char(97 + i / 26) + char(97 + i % 26)
	var text: String
	if m < 10.0:
		text = "%.2f" % (floor(m * 100.0) / 100.0)
	elif m < 100.0:
		text = "%.1f" % (floor(m * 10.0) / 10.0)
	else:
		text = str(int(m))
	return text + suffix
