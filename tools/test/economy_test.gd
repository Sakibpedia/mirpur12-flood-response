extends Node
## Supplies, team XP, skills, quests, persistence.
func _ready() -> void:
	var fails := 0
	var snap := {"supplies": Game.supplies, "boats": Game.boats, "pumps": Game.pumps,
		"medkits": Game.medkits, "score": Game.score, "level": Game.team_level,
		"xp": Game.xp, "sp": Game.skill_points, "skills": Game.skills.duplicate(true)}
	for i in range(1, 16):
		var d: Dictionary = Game.op_data(i)
		if int(d.get("target_rescues", 0)) <= 0: fails += 1
		if (d.get("quests", []) as Array).size() != 3: fails += 1
	Game.supplies = 1000
	if not Game.buy_boat(): fails += 1
	if not Game.buy_pump(): fails += 1
	if not Game.buy_medkit(): fails += 1
	if Game.boats < 4 or Game.pumps < 3: fails += 1
	Game.skill_points = 2
	if not Game.allocate_skill("navigation"): fails += 1
	if Game.speed_bonus() <= 1.0: fails += 1
	var lvl := Game.team_level
	if not Game.grant_quest("econ_q", 100, Game.xp_to_next() + 5): fails += 1
	if Game.team_level <= lvl: fails += 1
	Game.complete_operation(1, 10, 2, 1500)
	if Game.unlocked < 2: fails += 1
	if Game.rank() == "": fails += 1
	Game.save_game()
	Game.supplies = 0
	Game.load_game()
	if Game.supplies <= 0: fails += 1
	Game.supplies = snap["supplies"]; Game.boats = snap["boats"]; Game.pumps = snap["pumps"]
	Game.medkits = snap["medkits"]; Game.score = snap["score"]
	Game.team_level = snap["level"]; Game.xp = snap["xp"]
	Game.skill_points = snap["sp"]; Game.skills = snap["skills"]
	Game.save_game()
	if fails > 0:
		print("[ECON] FAIL %d checks" % fails)
		get_tree().quit(1)
	print("[ECON] PASS - 15 ops, supplies, XP/levels, skills, quests, save/reload")
	get_tree().quit(0)
