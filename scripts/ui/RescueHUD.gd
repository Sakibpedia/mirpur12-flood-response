extends CanvasLayer
## Flood-response HUD: flood gauge, rescue counts, supplies, team skills and summary.

var op = null
var state: String = ""
var notice: String = ""
var notice_time: float = 0.0
var root: Control
var lbl_top: Label
var lbl_mid: Label
var lbl_bottom: Label
var lbl_notice: Label
var flood_fill: ColorRect
var panel: Panel
var lbl_panel: Label
var mini = null


func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var scrim := ColorRect.new()
	scrim.color = Color(0.02, 0.06, 0.08, 0.60)
	scrim.position = Vector2(0, 0)
	scrim.size = Vector2(1280, 132)
	root.add_child(scrim)
	var bottom := ColorRect.new()
	bottom.color = Color(0.02, 0.06, 0.08, 0.58)
	bottom.position = Vector2(0, 636)
	bottom.size = Vector2(1280, 84)
	root.add_child(bottom)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.10, 0.22, 0.28, 0.9)
	bar_bg.position = Vector2(24, 136)
	bar_bg.size = Vector2(320, 10)
	root.add_child(bar_bg)
	flood_fill = ColorRect.new()
	flood_fill.color = Color(0.25, 0.70, 0.85)
	flood_fill.position = Vector2(24, 136)
	flood_fill.size = Vector2(0, 10)
	root.add_child(flood_fill)
	lbl_top = _label(Vector2(24, 18), Vector2(900, 38), 24, Color(0.96, 0.85, 0.55))
	lbl_mid = _label(Vector2(24, 58), Vector2(900, 34), 19, Color(0.62, 0.90, 0.88))
	lbl_bottom = _label(Vector2(24, 650), Vector2(1000, 44), 18, Color(0.94, 0.95, 0.92))
	lbl_notice = _label(Vector2(280, 520), Vector2(720, 42), 21, Color(1.0, 0.86, 0.50))
	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -330
	panel.offset_top = -220
	panel.offset_right = 330
	panel.offset_bottom = 220
	panel.visible = false
	root.add_child(panel)
	lbl_panel = Label.new()
	lbl_panel.position = Vector2(24, 18)
	lbl_panel.size = Vector2(612, 400)
	panel.add_child(lbl_panel)
	var credit := _label(Vector2(930, 690), Vector2(330, 22), 13, Color(0.60, 0.68, 0.68))
	credit.text = "Made by S M Nazmuz Sakib  •  OSM contributors (ODbL)"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mini = FloodMini.new()
	mini.hud = self
	add_child(mini)


func _label(pos: Vector2, size: Vector2, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	root.add_child(l)
	return l


func refresh() -> void:
	if op == null:
		return
	var d: Dictionary = op.data
	var mins := int(op.time_left) / 60
	var secs := int(op.time_left) % 60
	lbl_top.text = "দল লেভেল %d (%d/%d XP) • অপারেশন %d/15 — %s | ৳%d | স্কোর %d" % [
		Game.team_level, Game.xp, Game.xp_to_next(), Game.operation,
		str(d.get("name_bn", "")), Game.supplies, op.score]
	lbl_mid.text = "বন্যা %d%% • সময় %02d:%02d • উদ্ধার %d/%d • আশ্রয় %d/%d • পাম্প %d • নৌকা %d • বহন %d/%d • %s" % [
		int(op.city.flood_level * 100.0), mins, secs, op.rescued,
		int(d.get("target_rescues", 0)), op.sheltered, int(d.get("target_shelters", 0)),
		Game.pumps, Game.boats, op.carrying, Game.carry_capacity(), Game.rank()]
	lbl_bottom.text = "WASD চলুন • E উদ্ধার/আশ্রয়/পাম্প • B নৌকা • Q দল • G কুয়েস্ট • S সরবরাহ • ESC বিরতি"
	lbl_notice.text = notice if notice_time > 0.0 else ""
	flood_fill.size.x = clampf(op.city.flood_level, 0.0, 1.0) * 320.0
	mini.queue_redraw()


func tick(delta: float) -> void:
	notice_time = maxf(0.0, notice_time - delta)


func notify(text: String) -> void:
	notice = text
	notice_time = 4.0


func blocking() -> bool:
	return state != ""


func close_panel() -> void:
	state = ""
	panel.visible = false


func open_team() -> void:
	state = "team"
	_refresh_panel()


func open_quests() -> void:
	state = "quests"
	_refresh_panel()


func open_supplies() -> void:
	state = "supplies"
	_refresh_panel()


func show_summary(success: bool, rescued: int, sheltered: int, score: int, reason: String) -> void:
	state = "summary"
	panel.visible = true
	lbl_panel.text = ("অপারেশন সফল" if success else "অপারেশন ব্যর্থ") + "\n\n"
	if reason != "":
		lbl_panel.text += reason + "\n\n"
	lbl_panel.text += "উদ্ধার %d • আশ্রয় %d • স্কোর %d\n" % [rescued, sheltered, score]
	lbl_panel.text += "পদমর্যাদা: %s • সরবরাহ ৳%d\n\n" % [Game.rank(), Game.supplies]
	lbl_panel.text += "[N] পরবর্তী অপারেশন   [R] আবার   [M] মেনু"


func _refresh_panel() -> void:
	panel.visible = state != ""
	if state == "team":
		lbl_panel.text = "উদ্ধার দল\n\nলেভেল %d  XP %d/%d  স্কিল পয়েন্ট %d\n" % [
			Game.team_level, Game.xp, Game.xp_to_next(), Game.skill_points]
		for i in Game.SKILL_NAMES.size():
			var s := str(Game.SKILL_NAMES[i])
			lbl_panel.text += "%s  %s  স্তর %d/5\n" % [s, str(Game.SKILL_BN.get(s, "")), Game.skill(s)]
		lbl_panel.text += "\n[1] নৌচালনা  [2] উদ্ধার  [3] সরবরাহ  [Q] বন্ধ"
	elif state == "quests":
		lbl_panel.text = "অপারেশন লক্ষ্য\n\n"
		for q in (op.data.get("quests", []) as Array):
			var quest: Dictionary = q
			var done := bool(op.quest_progress.get(str(quest["id"]), false))
			lbl_panel.text += "[%s] %s (%d)  ৳%d / +%d XP\n" % [
				"X" if done else " ", str(quest["text"]), int(quest["target"]),
				int(quest["reward"]), int(quest["xp"])]
		lbl_panel.text += "\n[G/ESC] বন্ধ"
	elif state == "supplies":
		lbl_panel.text = "সরবরাহ কেন্দ্র — ৳%d\n\n" % Game.supplies
		lbl_panel.text += "1  নৌকা  ৳180   (মোট %d)\n" % Game.boats
		lbl_panel.text += "2  পাম্প  ৳140   (মোট %d)\n" % Game.pumps
		lbl_panel.text += "3  ওষুধ  ৳70    (মোট %d)\n\n" % Game.medkits
		lbl_panel.text += "[S/ESC] বন্ধ"


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	var k: int = event.keycode
	if state == "team":
		if k >= KEY_1 and k <= KEY_3:
			var s := str(Game.SKILL_NAMES[k - KEY_1])
			Game.allocate_skill(s)
			_refresh_panel()
		if k == KEY_Q or k == KEY_ESCAPE:
			close_panel()
	elif state == "quests":
		if k == KEY_G or k == KEY_ESCAPE:
			close_panel()
	elif state == "supplies":
		if k == KEY_1: Game.buy_boat()
		elif k == KEY_2: Game.buy_pump()
		elif k == KEY_3: Game.buy_medkit()
		_refresh_panel()
		if k == KEY_S or k == KEY_ESCAPE:
			close_panel()
	elif state == "summary":
		if k == KEY_M:
			get_tree().change_scene_to_file("res://scenes/RescueMenu.tscn")
		elif k == KEY_R:
			op.retry()
		elif k == KEY_N and bool(Game.last_result.get("success", false)):
			op.next_op()


class FloodMini extends Node2D:
	var hud

	func _draw() -> void:
		if hud == null or hud.op == null:
			return
		var o = hud.op
		var c = o.city
		var center: Vector2 = o.hero.position
		var sc := 0.05
		var size := 210.0
		draw_rect(Rect2(1040, 18, size, size), Color(0.02, 0.08, 0.10, 0.9))
		draw_rect(Rect2(1040, 18, size, size), Color(0.80, 0.70, 0.38), false, 2.0)
		for b in c.render_buildings:
			var r: Rect2 = b["rect"]
			var rp := Rect2(Vector2(1040, 18) + (r.position - center) * sc + Vector2(size / 2.0, size / 2.0), r.size * sc)
			if rp.intersects(Rect2(1040, 18, size, size)):
				draw_rect(rp, Color(0.36, 0.34, 0.30, 0.85))
		for pts in c.flood_roads:
			var mp := PackedVector2Array()
			for p in pts:
				mp.append(Vector2(1040, 18) + (p - center) * sc + Vector2(size / 2.0, size / 2.0))
			draw_polyline(mp, Color(0.25, 0.60, 0.80, 0.8), 2.0)
		for s in o.shelters:
			var sp: Vector2 = Vector2(1040, 18) + (s - center) * sc + Vector2(size / 2.0, size / 2.0)
			if sp.x > 1040 and sp.x < 1040 + size and sp.y > 18 and sp.y < 18 + size:
				draw_circle(sp, 3.0, Color(0.30, 0.90, 0.70))
		for v in o.victims:
			if v == null or v.saved: continue
			var vp: Vector2 = Vector2(1040, 18) + (v.position - center) * sc + Vector2(size / 2.0, size / 2.0)
			if vp.x > 1040 and vp.x < 1040 + size and vp.y > 18 and vp.y < 18 + size:
				draw_circle(vp, 3.0, Color(1.0, 0.55, 0.25))
		draw_circle(Vector2(1040 + size / 2.0, 18 + size / 2.0), 4.0, Color(0.95, 0.90, 0.60))
