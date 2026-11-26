extends Node2D
## One flood-rescue operation in real Mirpur 12.

var data: Dictionary = {}
var city = null
var hud = null
var hero = null
var actors: Array = []
var victims: Array = []
var shelters: Array = []
var quest_progress: Dictionary = {}
var rescued: int = 0
var sheltered: int = 0
var pumped: int = 0
var score: int = 0
var time_left: float = 150.0
var running: bool = true
var ended: bool = false
var paused: bool = false
var boat_mode: bool = false
var carrying: int = 0
var rng := RandomNumberGenerator.new()
var _think: float = 0.0
var _hint: float = 0.0
var cam: Camera2D = null
var marker = null


func _ready() -> void:
	rng.seed = int(Time.get_unix_time_from_system()) + Game.operation * 131
	data = Game.op_data(Game.operation)
	city = load("res://scripts/world/City2D.gd").new()
	city.flood_level = clampf(0.20 + float(Game.operation) * 0.02, 0.2, 0.6)
	add_child(city)
	_build_shelters()
	hero = _spawn("rescuer", "rescuer", city.extraction)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	hero.add_child(cam)
	cam.make_current()
	marker = FloodMarker.new()
	marker.op = self
	add_child(marker)
	hud = load("res://scripts/ui/RescueHUD.gd").new()
	hud.op = self
	add_child(hud)
	_spawn_victims(int(data.get("target_rescues", 5)) * 2 + 4)
	for q in (data.get("quests", []) as Array):
		quest_progress[str((q as Dictionary)["id"])] = false
	time_left = float(data.get("time_limit", 150.0))
	running = true
	hud.notify("অপারেশন: %s — %d জন উদ্ধারের লক্ষ্য" % [
		str(data.get("name_bn", "")), int(data.get("target_rescues", 5))])


func _build_shelters() -> void:
	shelters = []
	for s in city.shelters:
		if shelters.size() >= 24:
			break
		shelters.append(s["pos"])


func _spawn(kind: String, team: String, pos: Vector2):
	var a = load("res://scripts/world/Actor2D.gd").new()
	add_child(a)
	a.setup(kind, pos, team, self)
	actors.append(a)
	return a


func _spawn_victims(n: int) -> void:
	for i in n:
		var p: Vector2 = city.random_road_point(2000 + i * 17)
		var v = _spawn("victim", "victim", p)
		v.carrying = false
		v.saved = false
		victims.append(v)


func _process(delta: float) -> void:
	if not running or ended or paused:
		return
	time_left -= delta
	city.flood_level = clampf(city.flood_level + float(data.get("flood_rate", 0.004)) * delta, 0.0, 1.0)
	if city.flood_level >= 0.99:
		end_operation(false, "বন্যা নিয়ন্ত্রণের বাইরে চলে গেছে")
		return
	if time_left <= 0.0:
		end_operation(false, "সময় শেষ")
		return
	_handle_input(delta)
	_think += delta
	if _think > 0.35:
		_think = 0.0
		_check_quests()
	hud.tick(delta)
	hud.refresh()


func _handle_input(delta: float) -> void:
	if hud != null and hud.blocking():
		return
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
	var flooded: bool = bool(city.is_flooded(hero.position))
	var spd := 120.0 * Game.speed_bonus()
	if flooded and not boat_mode:
		spd *= 0.45
	if boat_mode:
		spd *= 1.15
	if Input.is_key_pressed(KEY_SHIFT): spd *= 1.3
	hero.speed = spd
	hero.move(dir, delta, city)
	if Input.is_key_pressed(KEY_B) and _hint <= 0.0:
		_hint = 0.25
		if boat_mode or Game.boats > 0:
			boat_mode = not boat_mode
			hud.notify("নৌকা মোড: " + ("চালু" if boat_mode else "বন্ধ"))
		else:
			hud.notify("নৌকা নেই — সরবরাহ কেনুন (Q)")
	if Input.is_key_pressed(KEY_E) and _hint <= 0.0:
		_hint = 0.30
		interact()
	_hint = maxf(0.0, _hint - delta)


func interact() -> void:
	var victim := _nearest_victim()
	if victim != null and hero.position.distance_to(victim.position) < 46.0:
		if carrying >= Game.carry_capacity():
			hud.notify("একসাথে আর বেশি মানুষ বহন করা যাবে না")
			return
		victim.carrying = true
		victim.saved = true
		carrying += 1
		rescued += 1
		score += 120
		Game.add_xp(12)
		victim.visible = false
		hud.notify("উদ্ধার করা হয়েছে — আশ্রয়কেন্দ্রে নিন")
		return
	if carrying > 0:
		var sh := _nearest_shelter()
		if sh != Vector2.ZERO and hero.position.distance_to(sh) < 55.0:
			var n := carrying
			sheltered += n
			score += 200 * n
			carrying = 0
			Game.earn(40 * n)
			Sfx.play("medal")
			hud.notify("নিরাপদ আশ্রয়ে পৌঁছে দেওয়া হয়েছে")
			return
	# Pump a flooded segment.
	if Game.pumps > 0 and city.is_flooded(hero.position):
		Game.pumps -= 1
		pumped += 1
		city.flood_level = maxf(0.05, city.flood_level - 0.12 - 0.03 * float(Game.pump_bonus()))
		score += 150
		Game.save_game()
		Sfx.play("bomb")
		hud.notify("পাম্প চালু — পানি কমছে")
		return
	hud.notify("কাছে কোনো উদ্ধারযোগ্য বস্তু নেই")


func _nearest_victim() -> Node:
	var best = null
	var bd := 1.0e9
	for v in victims:
		if v == null or v.saved or not v.alive:
			continue
		var d: float = v.position.distance_to(hero.position)
		if d < bd:
			bd = d
			best = v
	return best


func _nearest_shelter() -> Vector2:
	var best := Vector2.ZERO
	var bd := 1.0e9
	for s in shelters:
		var d: float = (s as Vector2).distance_to(hero.position)
		if d < bd:
			bd = d
			best = s
	return best


func _check_quests() -> void:
	for q in (data.get("quests", []) as Array):
		var quest: Dictionary = q
		var qid := str(quest["id"])
		if bool(quest_progress.get(qid, false)):
			continue
		var ok := false
		match str(quest["type"]):
			"rescue": ok = rescued >= int(quest["target"])
			"shelter": ok = sheltered >= int(quest["target"])
			"pump": ok = pumped >= int(quest["target"])
		if ok:
			quest_progress[qid] = true
			if Game.grant_quest(qid, int(quest["reward"]), int(quest["xp"])):
				hud.notify("অপারেশন লক্ষ্য পূর্ণ: %s" % str(quest["text"]))


func end_operation(success: bool = true, reason: String = "") -> void:
	if ended:
		return
	ended = true
	running = false
	var ok: bool = success and rescued >= int(data.get("target_rescues", 0)) and \
		sheltered >= int(data.get("target_shelters", 0))
	if ok:
		Game.complete_operation(Game.operation, rescued, sheltered, score)
	else:
		Game.fail_operation(Game.operation, reason if reason != "" else "লক্ষ্য পূর্ণ হয়নি")
	Game.save_game()
	hud.show_summary(ok, rescued, sheltered, score, reason)


func retry() -> void:
	get_tree().change_scene_to_file("res://scenes/FloodOperation.tscn")


func next_op() -> void:
	Game.save_game()
	get_tree().change_scene_to_file("res://scenes/FloodOperation.tscn")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_ESCAPE and running:
		if hud != null and hud.blocking():
			hud.close_panel()
		else:
			paused = not paused
			hud.notify("বিরতি — ESC দিয়ে ফিরুন")
	elif event.keycode == KEY_Q and running and not paused and hud != null and not hud.blocking():
		hud.open_team()
	elif event.keycode == KEY_G and running and not paused and hud != null and not hud.blocking():
		hud.open_quests()
	elif event.keycode == KEY_S and running and not paused and hud != null and not hud.blocking():
		hud.open_supplies()


class FloodMarker extends Node2D:
	var op

	func _draw() -> void:
		if op == null or op.hud == null:
			return
		var v = op._nearest_victim()
		if v != null:
			draw_circle(v.position, 22.0, Color(1.0, 0.75, 0.30, 0.20))
			draw_circle(v.position, 22.0, Color(1.0, 0.75, 0.30), false, 2.0)
		for victim_node in op.victims:
			if victim_node != null and not victim_node.saved and victim_node.visible:
				draw_circle(victim_node.position, 9.0, Color(1.0, 0.55, 0.25, 0.55))
		for s in op.shelters:
			draw_circle(s, 12.0, Color(0.30, 0.90, 0.70, 0.55))
