extends Control
## Operation select for Mirpur 12 Flood Response.

func _ready() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/menu_bg.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.05, 0.08, 0.64)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var title := Label.new()
	title.text = "MIRPUR 12 — FLOOD RESPONSE"
	title.position = Vector2(60, 38)
	title.size = Vector2(1000, 66)
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.62, 0.88, 0.95))
	add_child(title)
	var sub := Label.new()
	sub.text = "মিরপুর ১২ • বন্যা উদ্ধার অভিযান • ১৫টি অপারেশন"
	sub.position = Vector2(62, 104)
	sub.size = Vector2(900, 34)
	sub.add_theme_font_size_override("font_size", 21)
	sub.add_theme_color_override("font_color", Color(0.70, 0.92, 0.90))
	add_child(sub)
	var info := Label.new()
	info.text = "৳ %d • স্কোর %d • দল লেভেল %d • পদমর্যাদা: %s • নৌকা %d • পাম্প %d • ওষুধ %d" % [
		Game.supplies, Game.score, Game.team_level, Game.rank(), Game.boats, Game.pumps, Game.medkits]
	info.position = Vector2(62, 148)
	info.size = Vector2(1150, 34)
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", Color(0.94, 0.95, 0.92))
	add_child(info)

	for i in Game.OP_COUNT:
		var idx := i + 1
		var b := Button.new()
		b.position = Vector2(62 + (i % 5) * 230, 215 + (i / 5) * 118)
		b.size = Vector2(214, 96)
		var locked: bool = idx > Game.unlocked
		var rec: Dictionary = Game.records.get(str(idx), {})
		var grade := str(rec.get("grade", ""))
		var mark := "[LOCKED]" if locked else ("[" + grade + "]" if grade != "" else "[OPEN]")
		b.text = "%02d  %s\n%s  %s" % [idx, str(Game.OP_BN[i]), str(Game.OP_NAMES[i]), mark]
		b.disabled = locked
		b.add_theme_font_size_override("font_size", 15)
		if not locked:
			b.pressed.connect(_start.bind(idx))
		add_child(b)

	var help := Label.new()
	help.text = "WASD চলুন • E উদ্ধার/আশ্রয়/পাম্প • B নৌকা • Q দল • G কুয়েস্ট • S সরবরাহ • ESC বিরতি"
	help.position = Vector2(62, 588)
	help.size = Vector2(1160, 36)
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_color_override("font_color", Color(0.84, 0.90, 0.90))
	add_child(help)
	var credit := Label.new()
	credit.text = "Made by S M Nazmuz Sakib   •   Map data © OpenStreetMap contributors (ODbL 1.0)   •   Real Mirpur 12 roads"
	credit.position = Vector2(62, 682)
	credit.size = Vector2(1160, 24)
	credit.add_theme_font_size_override("font_size", 14)
	credit.add_theme_color_override("font_color", Color(0.64, 0.72, 0.72))
	add_child(credit)


func _start(idx: int) -> void:
	Game.operation = idx
	Sfx.play("ui")
	get_tree().change_scene_to_file("res://scenes/FloodOperation.tscn")
