class_name NpcSystem
extends Node
# ============================================================
# NpcSystem — NPC 招募入队与被动加成查询 (npc 系统, 提前实施 Dev-S4 招募部分)
# 状态单一数据源: 存 config_id (npc.medic_01, 逻辑书 ID 规范); 姓名仅展示/旧档迁移
# 三选一锁定: recruit() 已有人时拒绝 (系统层锁定; UI 层 btn_recruit 另有一层判断)
# 被动加成查询 API 供 S2+ 消费 (如 food_gain_bonus_percent); 人口面板本期不接管
# 边界: 不做到访/交易/对话/主动技能结算 (仍属 Dev-S4 后续)
# ============================================================

signal recruited(npc_id: String)
# 队伍任意变动 (含 set_state/new_game/reset): 消费方 clamp 状态用, 不补差额
signal team_changed()

# 旧档姓名 → config_id 别名 (改名迁移兼容; find_npc_id_by_name 只认 CONF 现名)
const LEGACY_NAMES := {
	"唐文轩": "npc.veteran_01",
	"张睿": "npc.medic_01",
	"吴齐越": "npc.engineer_01",
}

# 队伍成员 config_id 列表; 本期招募规则锁定 ≤1 人 (recruit 拒绝第二个)
var _team: Array[String] = []


func _ready() -> void:
	# 接线 ShelterSystem (boot/测试均先建 ShelterSystem 后建本系统):
	# recruited → 招募差额并入 hp; team_changed → clamp
	var shelter := get_tree().root.get_node_or_null("ShelterSystem") as ShelterSystem
	if shelter != null:
		if not recruited.is_connected(shelter.on_companion_recruited):
			recruited.connect(shelter.on_companion_recruited)
		if not team_changed.is_connected(shelter.on_companion_team_changed):
			team_changed.connect(shelter.on_companion_team_changed)


# ---------------- 招募 ----------------

# 入队 (三选一): 校验 id 存在/recruit_allowed/未入队; 已有人时拒绝
func recruit(npc_id: String) -> bool:
	if _team.size() >= 1:
		return false
	if not ConfigManager.has_npc(npc_id):
		push_warning("NpcSystem.recruit: unknown npc id: %s" % npc_id)
		return false
	var data: Dictionary = ConfigManager.get_npc(npc_id)
	if not data.get("recruit_allowed", false):
		return false
	if _team.has(npc_id):
		return false
	_team.append(npc_id)
	recruited.emit(npc_id)
	team_changed.emit()
	return true


func is_recruited(npc_id: String) -> bool:
	return _team.has(npc_id)


# ---------------- 查询 ----------------

func get_picked_id() -> String:
	return _team[0] if not _team.is_empty() else ""


func get_picked_name() -> String:
	var picked_id := get_picked_id()
	if picked_id.is_empty():
		return ""
	var data: Dictionary = ConfigManager.get_npc(picked_id)
	return str(data.get("name", ""))


func get_team() -> Array:
	return _team.duplicate()


# 全队被动加成求和 (S2+ 消费入口): get_passive_bonus("food_gain_bonus_percent") == 20.0
func get_passive_bonus(field: String) -> float:
	var total := 0.0
	for npc_id in _team:
		var bonuses := _passive_bonuses_of(npc_id)
		if bonuses.has(field):
			total += float(bonuses[field])
	return total


# 全队被动加成合并字典 {field: float} (同名字段求和)
func get_passive_bonuses() -> Dictionary:
	var total := {}
	for npc_id in _team:
		var bonuses := _passive_bonuses_of(npc_id)
		for field in bonuses:
			var field_key := str(field)
			var current: float = float(total.get(field_key, 0.0))
			total[field_key] = current + float(bonuses[field])
	return total


# 主动技能原始数据 (只读, 本期不触发结算)
func get_active_skill_data(npc_id: String) -> Dictionary:
	var data: Dictionary = ConfigManager.get_npc(npc_id)
	if data.is_empty():
		return {}
	var active: Dictionary = data.get("active", {})
	return active


func _passive_bonuses_of(npc_id: String) -> Dictionary:
	var data: Dictionary = ConfigManager.get_npc(npc_id)
	var passive: Dictionary = data.get("passive", {})
	var bonuses: Dictionary = passive.get("bonuses", {})
	return bonuses


# ---------------- 存档 ----------------

# {picked: id, team: [id]} (login/settings 持久化; 另写 recruit.picked 姓名镜像)
func get_state() -> Dictionary:
	return {
		"picked": get_picked_id(),
		"team": _team.duplicate(),
	}


# 归一化: 兼容 {picked: "npc.medic_01"} 与旧档 {picked: "张睿"} (姓名→id 映射)
func set_state(data: Dictionary) -> void:
	_team.clear()
	var team_raw: Array = data.get("team", [])
	for item in team_raw:
		_append_member(str(item))
	if _team.is_empty():
		var picked: String = str(data.get("picked", ""))
		_append_member(picked)
	# 本期招募规则 ≤1 人, 只保留第一个
	if _team.size() > 1:
		_team.resize(1)
	team_changed.emit()


func new_game() -> void:
	_team.clear()
	team_changed.emit()


func reset() -> void:
	_team.clear()
	team_changed.emit()


func _append_member(value: String) -> void:
	var normalized := _normalize_id(value)
	if normalized.is_empty() or _team.has(normalized):
		return
	_team.append(normalized)


# npc.* 前缀 = config_id 直接用; 否则按姓名映射 (现名 find_npc_id_by_name, 旧名 LEGACY_NAMES)。失败置空 warning 不报错
func _normalize_id(value: String) -> String:
	if value.is_empty():
		return ""
	if value.begins_with("npc."):
		if ConfigManager.has_npc(value):
			return value
		push_warning("NpcSystem.set_state: unknown npc id 已忽略: %s" % value)
		return ""
	var mapped := ConfigManager.find_npc_id_by_name(value)
	if mapped.is_empty() and LEGACY_NAMES.has(value):
		mapped = str(LEGACY_NAMES[value])
	if mapped.is_empty():
		push_warning("NpcSystem.set_state: 旧档姓名无法映射 npc id, 已忽略: %s" % value)
	return mapped
