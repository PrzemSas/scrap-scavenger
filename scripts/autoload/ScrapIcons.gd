extends Node

const S := 48
var icons : Dictionary = {}

func _ready() -> void:
	_make("can",     Color("#2D5FA0"), _can)
	_make("bolt",    Color("#555555"), _bolt)
	_make("pipe",    Color("#404048"), _pipe)
	_make("cable",   Color("#A04808"), _cable)
	_make("battery", Color("#186818"), _battery)
	_make("chip",    Color("#0A6868"), _chip)
	_make("coil",    Color("#884010"), _coil)
	_make("motor",   Color("#182848"), _motor)
	_make("gear",    Color("#383838"), _gear)
	_make("gold",    Color("#906000"), _gold)
	_make("crystal", Color("#005870"), _crystal)

func get_icon(id: String) -> Texture2D:
	return icons.get(id, null)

# ── helpers ──────────────────────────────────────────────────────────────────

func _make(id: String, bg: Color, fn: Callable) -> void:
	var img := _bg(bg)
	fn.call(img)
	icons[id] = ImageTexture.create_from_image(img)

func _bg(c: Color) -> Image:
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var cr := 9
	var border := c.lightened(0.30)
	for y in S:
		for x in S:
			var p := _corner_check(x, y, cr)
			if p == 0:
				img.set_pixel(x, y, Color.TRANSPARENT)
			elif p == 1:
				img.set_pixel(x, y, border)
			else:
				img.set_pixel(x, y, c)
	return img

func _corner_check(x: int, y: int, cr: int) -> int:
	var corners := [[cr, cr], [S-cr-1, cr], [cr, S-cr-1], [S-cr-1, S-cr-1]]
	for c in corners:
		var dx: int = x - int(c[0]); var dy: int = y - int(c[1])
		if abs(dx) <= cr and abs(dy) <= cr:
			var d: int = dx*dx + dy*dy
			if d > cr*cr: return 0
			if d > (cr-2)*(cr-2): return 1
	if x < 2 or y < 2 or x >= S-2 or y >= S-2: return 1
	return 2

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < S and y < S:
		img.set_pixel(x, y, c)

func _rect(img: Image, x1:int, y1:int, x2:int, y2:int, c:Color) -> void:
	for y in range(y1, y2+1):
		for x in range(x1, x2+1):
			_px(img, x, y, c)

func _circ(img: Image, cx:int, cy:int, r:int, c:Color) -> void:
	for y in range(cy-r, cy+r+1):
		for x in range(cx-r, cx+r+1):
			if (x-cx)*(x-cx)+(y-cy)*(y-cy) <= r*r:
				_px(img, x, y, c)

func _ring(img: Image, cx:int, cy:int, ro:int, ri:int, c:Color) -> void:
	for y in range(cy-ro, cy+ro+1):
		for x in range(cx-ro, cx+ro+1):
			var d := (x-cx)*(x-cx)+(y-cy)*(y-cy)
			if d <= ro*ro and d >= ri*ri:
				_px(img, x, y, c)

func _diamond(img: Image, cx:int, cy:int, r:int, c:Color) -> void:
	for y in range(cy-r, cy+r+1):
		for x in range(cx-r, cx+r+1):
			if abs(x-cx)+abs(y-cy) <= r:
				_px(img, x, y, c)

# ── shape drawing ─────────────────────────────────────────────────────────────
const W := Color("#D8EEFF")
const WW := Color("#FFFFFF")
const DA := Color(0,0,0,0.25)

func _can(img: Image) -> void:
	# Aluminium can silhouette
	var w := W
	_rect(img, 17, 12, 30, 36, w)          # body
	_rect(img, 19,  9, 28, 13, w)          # top
	_rect(img, 19, 35, 28, 39, w)          # bottom
	_rect(img, 21,  7, 26, 10, WW)         # tab base
	_rect(img, 22,  5, 24,  8, WW)         # tab loop
	_rect(img, 17, 20, 30, 21, DA)         # label stripe

func _bolt(img: Image) -> void:
	# Hex bolt top-view
	var w := W
	for y in range(13, 35):
		for x in range(13, 35):
			var dx := x - 23.5; var dy := y - 23.5
			if absf(dx) < 9 and absf(dy) < 9 and absf(dx)+absf(dy) < 14.5:
				_px(img, x, y, w)
	_circ(img, 24, 24, 4, Color("#555555"))  # hole
	_ring(img, 24, 24, 4, 2, Color("#AAAAAA"))

func _pipe(img: Image) -> void:
	# Cross-section of steel pipe
	_ring(img, 24, 24, 16, 10, W)
	_circ(img, 24, 24, 10, Color("#1A1A22"))  # hollow center
	_ring(img, 24, 24, 10, 8, Color("#8899AA"))  # inner wall

func _cable(img: Image) -> void:
	# Copper cable coiling left-right
	var w := Color("#FFB860")
	for i in 20:
		var t := float(i) / 19.0
		var x := int(8 + t * 30)
		var y := int(24 + sin(t * PI * 2.5) * 11)
		_circ(img, x, y, 3, w)
	# copper ends
	_circ(img, 9,  24, 4, Color("#FF9020"))
	_circ(img, 39, 24, 4, Color("#FF9020"))

func _battery(img: Image) -> void:
	# AA battery
	var w := Color("#80FF80")
	_rect(img, 15, 11, 32, 37, w)          # body
	_rect(img, 20,  8, 27, 12, WW)         # + terminal
	_rect(img, 16, 22, 31, 23, Color("#186818"))  # label line
	_rect(img, 20, 15, 27, 20, WW)         # + symbol h
	_rect(img, 22, 13, 25, 22, WW)         # + symbol v

func _chip(img: Image) -> void:
	# CPU chip with legs
	var w := Color("#80FFFF")
	_rect(img, 14, 14, 33, 33, w)          # die
	_rect(img, 16, 16, 31, 31, Color("#0A6868"))  # center
	_rect(img, 18, 18, 29, 29, Color("#20B0B0"))  # inner
	# legs
	for i in range(3):
		var y := 18 + i * 5
		_rect(img, 8,  y, 14, y+2, Color("#AAAAAA"))  # left
		_rect(img, 33, y, 39, y+2, Color("#AAAAAA"))  # right

func _coil(img: Image) -> void:
	# Copper coil / spring
	var w := Color("#FFB040")
	for i in 5:
		var cy := 11 + i * 6
		_ring(img, 24, cy, 11, 8, w)
	_rect(img, 14, 10, 15, 36, w)   # left spine
	_rect(img, 33, 10, 34, 36, w)   # right spine

func _motor(img: Image) -> void:
	# Electric motor (front)
	var w := Color("#5060A0")
	_circ(img, 24, 24, 16, w)
	_circ(img, 24, 24, 11, Color("#182848"))
	# stator slots
	for i in 6:
		var angle := float(i) * TAU / 6.0
		var x := int(24 + cos(angle) * 13)
		var y := int(24 + sin(angle) * 13)
		_circ(img, x, y, 3, Color("#101828"))
	# rotor
	_circ(img, 24, 24, 5, Color("#7888C8"))
	_circ(img, 24, 24, 2, WW)

func _gear(img: Image) -> void:
	# Gear with 8 teeth
	_circ(img, 24, 24, 14, W)
	for i in 8:
		var angle := float(i) * TAU / 8.0
		var tx := int(24 + cos(angle) * 17)
		var ty := int(24 + sin(angle) * 17)
		_circ(img, tx, ty, 4, W)
	_circ(img, 24, 24, 7, Color("#383838"))
	_circ(img, 24, 24, 3, Color("#888888"))

func _gold(img: Image) -> void:
	# Gold coin
	var g := Color("#FFD700")
	var gl := Color("#FFEE60")
	_circ(img, 24, 24, 16, g)
	_ring(img, 24, 24, 16, 13, Color("#C89000"))
	_circ(img, 24, 24, 12, gl)
	# G letter hint
	_ring(img, 24, 24, 7, 4, g)
	_rect(img, 24, 21, 29, 24, gl)

func _crystal(img: Image) -> void:
	# Hexagonal forge crystal
	var c1 := Color("#00FFFF")
	var c2 := Color("#40D0FF")
	# top facet
	_diamond(img, 24, 14, 8, c1)
	# bottom facet
	_diamond(img, 24, 34, 8, c2)
	# middle band
	_rect(img, 16, 18, 31, 30, Color("#20A8C8"))
	# shine
	_rect(img, 18, 19, 21, 24, Color("#AAFFFF"))
	_rect(img, 19, 20, 20, 22, WW)
