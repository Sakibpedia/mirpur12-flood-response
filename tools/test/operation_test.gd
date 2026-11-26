extends Node
## Playthrough-style test for one rescue operation (OP=1..15).
var op
var t := 0.0
var idx := 1
var reported := false
var fails := 0

func _ready() -> void:
	var env := OS.get_environment("OP")
	idx = int(env) if env != "" else 1
	Game.operation = idx
	op = (load("res://scenes/FloodOperation.tscn") as PackedScene).instantiate()
	add_child(op)

func _ck(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("[OP] FAIL O%d %s" % [idx, what])

func _process(delta: float) -> void:
	t += delta
	if t > 120.0:
		print("[OP] FAIL O%d timeout" % idx)
		get_tree().quit(1)
	if reported or t < 2.0 or op.get("running") != true:
		return
	reported = true
	var city = op.get("city")
	var victims: Array = op.get("victims")
	var shelters: Array = op.get("shelters")
	var odata: Dictionary = op.get("data")
	_ck(city.get("buildings").size() >= 1400, "city built")
	_ck(city.get("roads").size() >= 750, "real roads")
	_ck(victims.size() >= 10, "victims spawned (%d)" % victims.size())
	_ck(shelters.size() >= 20, "shelters available")
	Game.pumps = 3
	var target := int(odata.get("target_rescues", 5))
	for i in mini(target, victims.size()):
		var v = victims[i]
		op.get("hero").position = v.position
		op.call("interact")
		if int(op.get("carrying")) >= Game.carry_capacity():
			op.get("hero").position = shelters[0]
			op.call("interact")
	if int(op.get("carrying")) > 0:
		op.get("hero").position = shelters[0]
		op.call("interact")
	_ck(int(op.get("rescued")) >= target, "rescue target %d/%d" % [int(op.get("rescued")), target])
	_ck(int(op.get("sheltered")) >= int(odata.get("target_shelters", 1)), "shelter target")
	var flood_roads: Array = city.get("flood_roads")
	if flood_roads.size() > 0:
		var pts = flood_roads[0]
		op.get("hero").position = pts[mini(2, pts.size() - 1)]
		op.call("interact")
	_ck(int(op.get("pumped")) >= 1, "pump deployed")
	op.call("_check_quests")
	_ck(Game.quests_done.has(str((odata["quests"][0] as Dictionary)["id"])), "rescue quest rewarded")
	op.call("end_operation", true)
	_ck(op.get("ended") == true, "operation ended")
	if fails == 0:
		print("[OP] PASS O%d - %d victims, %d shelters, score %d" % [
			idx, int(op.get("rescued")), int(op.get("sheltered")), int(op.get("score"))])
		get_tree().quit(0)
	else:
		get_tree().quit(1)
