extends Node
## Mirpur 12 Flood Response - global campaign state, supplies, team skills and saves.

signal state_changed

const OP_COUNT := 15
const SAVE_PATH := "user://mirpur12_flood.cfg"
const OP_NAMES := [
	"Kachabazar Waterline", "Road 7 Rescue", "Milk Vita Crossing",
	"Begum Rokeya Sarani", "Kalshi Embankment", "Avenue 2 Evacuation",
	"DOHS Link Flood", "School Shelter Run", "Clinic Supply Drop",
	"Road 12 Deep Water", "Tube Well Rescue", "Market Boat Lift",
	"Night Pumping", "Bridge Clearance", "Mirpur Final Flood",
]
const OP_BN := [
	"কাচাবাজার জলরেখা", "রোড ৭ উদ্ধার", "মিল্ক ভিটা ক্রসিং",
	"বেগম রোকেয়া সরণি", "কালশী বাঁধ", "অ্যাভিনিউ ২ সরিয়ে নেওয়া",
	"ডিওএইচএস লিংক বন্যা", "স্কুল আশ্রয়কেন্দ্র", "ক্লিনিকে ওষুধ সরবরাহ",
	"রোড ১২ গভীর পানি", "টিউবওয়েল উদ্ধার", "বাজার নৌকা অপারেশন",
	"রাত্রিকাল পাম্পিং", "ব্রিজ পরিষ্কার", "মিরপুর চূড়ান্ত বন্যা",
]
const SKILL_NAMES := ["navigation", "rescue", "logistics"]
const SKILL_BN := {"navigation": "নৌচালনা", "rescue": "উদ্ধার দক্ষতা", "logistics": "সরবরাহ"}

var operation: int = 1
var unlocked: int = 1
var score: int = 0
var supplies: int = 500
var boats: int = 3
var pumps: int = 2
var medkits: int = 3
var team_level: int = 1
var xp: int = 0
var skill_points: int = 0
var skills: Dictionary = {"navigation": 0, "rescue": 0, "logistics": 0}
var records: Dictionary = {}
var quests_done: Dictionary = {}
var settings: Dictionary = {"sfx": true}
var last_result: Dictionary = {}


func _ready() -> void:
	load_game()


func op_data(idx: int) -> Dictionary:
	var i: int = clampi(idx, 1, OP_COUNT) - 1
	return {
		"index": i + 1,
		"name": OP_NAMES[i],
		"name_bn": OP_BN[i],
		"target_rescues": 5 + i * 2,
		"target_shelters": 1 + i / 5,
		"flood_rate": 0.004 + float(i) * 0.0006,
		"time_limit": 150.0 + float(i) * 4.0,
		"reward": 200 + i * 60,
		"quests": [
			{"id": "o%d_rescue" % (i + 1), "type": "rescue", "target": 4 + i,
				"reward": 90 + i * 12, "xp": 50 + i * 8, "text": "মানুষ উদ্ধার করুন"},
			{"id": "o%d_shelter" % (i + 1), "type": "shelter", "target": 1 + i / 6,
				"reward": 110 + i * 10, "xp": 55 + i * 10, "text": "নিরাপদ আশ্রয়ে পৌঁছে দিন"},
			{"id": "o%d_pump" % (i + 1), "type": "pump", "target": 1 + i / 4,
				"reward": 100 + i * 12, "xp": 45 + i * 8, "text": "পানি নিষ্কাশন করুন"},
		],
	}


func xp_to_next() -> int:
	return 150 + team_level * 80


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		team_level += 1
		skill_points += 1
		state_changed.emit()
	save_game()


func allocate_skill(name: String) -> bool:
	if skill_points <= 0 or not skills.has(name) or int(skills[name]) >= 5:
		return false
	skills[name] = int(skills[name]) + 1
	skill_points -= 1
	save_game()
	state_changed.emit()
	return true


func skill(name: String) -> int:
	return int(skills.get(name, 0))


func speed_bonus() -> float:
	return 1.0 + 0.10 * float(skill("navigation"))


func carry_capacity() -> int:
	return 1 + skill("rescue")


func pump_bonus() -> int:
	return skill("logistics")


func grant_quest(qid: String, reward: int, xp_reward: int) -> bool:
	if quests_done.has(qid):
		return false
	quests_done[qid] = true
	supplies += reward
	add_xp(xp_reward)
	save_game()
	state_changed.emit()
	return true


func spend(cost: int) -> bool:
	if supplies < cost:
		return false
	supplies -= cost
	save_game()
	state_changed.emit()
	return true


func earn(amount: int) -> void:
	supplies += amount
	save_game()
	state_changed.emit()


func buy_boat() -> bool:
	if not spend(180): return false
	boats += 1
	save_game()
	return true


func buy_pump() -> bool:
	if not spend(140): return false
	pumps += 1
	save_game()
	return true


func buy_medkit() -> bool:
	if not spend(70): return false
	medkits += 1
	save_game()
	return true


func complete_operation(idx: int, rescued: int, sheltered: int, score_delta: int) -> void:
	var d := op_data(idx)
	score += score_delta
	supplies += int(d.get("reward", 0))
	if rescued >= int(d.get("target_rescues", 0)) and sheltered >= int(d.get("target_shelters", 0)):
		var grade := "A" if score_delta >= 1200 else "B"
		records[str(idx)] = {"score": score_delta, "rescued": rescued,
			"sheltered": sheltered, "grade": grade}
		if idx >= unlocked and idx < OP_COUNT:
			unlocked = idx + 1
		operation = clampi(idx + 1, 1, OP_COUNT)
		last_result = {"success": true, "grade": grade, "reward": int(d.get("reward", 0))}
	else:
		last_result = {"success": false, "reason": "লক্ষ্য পূর্ণ হয়নি"}
	add_xp(70 + idx * 14)
	save_game()
	state_changed.emit()


func fail_operation(idx: int, reason: String) -> void:
	last_result = {"success": false, "reason": reason}
	state_changed.emit()


func total_score() -> int:
	var t := 0
	for r in records.values():
		t += int((r as Dictionary).get("score", 0))
	return t


func rank() -> String:
	var s := total_score()
	if s >= 18000: return "Chief Coordinator"
	if s >= 10000: return "Senior Rescuer"
	if s >= 5000: return "Responder"
	return "Volunteer"


func save_game() -> void:
	var cf := ConfigFile.new()
	cf.set_value("progress", "operation", operation)
	cf.set_value("progress", "unlocked", unlocked)
	cf.set_value("progress", "score", score)
	cf.set_value("progress", "records", records)
	cf.set_value("supplies", "supplies", supplies)
	cf.set_value("supplies", "boats", boats)
	cf.set_value("supplies", "pumps", pumps)
	cf.set_value("supplies", "medkits", medkits)
	cf.set_value("team", "level", team_level)
	cf.set_value("team", "xp", xp)
	cf.set_value("team", "skill_points", skill_points)
	cf.set_value("team", "skills", skills)
	cf.set_value("team", "quests_done", quests_done)
	cf.set_value("settings", "values", settings)
	cf.save(SAVE_PATH)


func load_game() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	operation = clampi(int(cf.get_value("progress", "operation", 1)), 1, OP_COUNT)
	unlocked = clampi(int(cf.get_value("progress", "unlocked", 1)), 1, OP_COUNT)
	score = int(cf.get_value("progress", "score", 0))
	records = cf.get_value("progress", "records", {})
	supplies = int(cf.get_value("supplies", "supplies", 500))
	boats = int(cf.get_value("supplies", "boats", 3))
	pumps = int(cf.get_value("supplies", "pumps", 2))
	medkits = int(cf.get_value("supplies", "medkits", 3))
	team_level = int(cf.get_value("team", "level", 1))
	xp = int(cf.get_value("team", "xp", 0))
	skill_points = int(cf.get_value("team", "skill_points", 0))
	skills = cf.get_value("team", "skills", {"navigation": 0, "rescue": 0, "logistics": 0})
	quests_done = cf.get_value("team", "quests_done", {})
	settings = cf.get_value("settings", "values", settings)
