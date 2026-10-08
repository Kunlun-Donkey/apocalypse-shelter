extends Node
# ============================================================
# ConfigManager (autoload, 最先加载) — CONF-D v2 解析 + 系统开关注册表
# AGENTS.md §12.3: Godot ConfigFile 不接受不带引号的字符串值,
# 因此本类自己做"原始读取"(节/键/原始字符串), 类型转换按逻辑书 D2.3:
#   数组 [a, b] / 范围 10~30 / id:level / int / float / bool 自行解析
# 错误处理按逻辑书 D2.9: 配置坏了打印 CONFIG ERROR 并终止启动, 不静默。
# ============================================================

const SYSTEM_CONF_PATH := "res://configs/system.conf"
const RESOURCE_REGISTRY_PATH := "res://configs/resources/resource.conf"
const CONF_VERSION := 1

# path -> { section -> { key -> raw string } }
var _raw := {}
var _systems := {}        # 系统名 -> bool
var _dependencies := {}   # 系统名 -> Array[String]
var _engine := {}         # 引擎参数 key -> raw string
var _shelter_base := {}   # shelter.conf [base]/[visual] 解析结果
var _shelter_levels := {} # int -> level 字典 (解析后)
var _error := ""


func load_all() -> int:
	_error = ""
	_raw.clear()
	var err := _load_system_conf()
	if err != OK:
		return err
	if is_enabled("shelter"):
		err = _load_shelter_conf()
		if err != OK:
			return err
	return OK


func get_error_message() -> String:
	return _error


func is_enabled(system_name: String) -> bool:
	return _systems.get(system_name, false)


func get_enabled_systems() -> Array:
	var out: Array = []
	for key in _systems:
		if _systems[key]:
			out.append(key)
	return out


# ---------------- 发动机参数 (system.conf [engine]) ----------------

func get_engine_real_seconds_per_game_hour() -> float:
	var rate := _parse_float(_engine.get("real_seconds_per_game_hour", ""), 60.0)
	return rate if rate > 0.0 else 60.0


func get_engine_save_slots() -> int:
	return _parse_int(_engine.get("save_slots", ""), 3)


# ---------------- shelter 访问器 (S1 范围) ----------------

func get_shelter_base() -> Dictionary:
	return _shelter_base


func get_max_available_level() -> int:
	return _shelter_levels.size()


func get_shelter_level(level: int) -> Dictionary:
	return _shelter_levels.get(level, {})


func get_initial_state() -> Dictionary:
	return _shelter_base.get("initial_state", {})


# ---------------- 资源条展示 (纯 UI, 不建 ResourceSystem) ----------------
# S1 resource=false 零初始化纪律: 本函数只读 dormant CONF 做静态展示
# (名称/基础容量), 不做资源池/产消/容量结算; S2 ResourceSystem 开启后接管。
# 返回 [{key, name, base_capacity}], 仅收 storable 的 stock 资源 (排除 power 流转)。

func get_resource_display_items() -> Array:
	var out: Array = []
	if _load_raw(RESOURCE_REGISTRY_PATH) != OK:
		return out
	var files := parse_list(_section(RESOURCE_REGISTRY_PATH, "registry").get("files", ""))
	for file_rel in files:
		var path := "res://configs/" + str(file_rel).strip_edges()
		if _load_raw(path) != OK:
			continue
		var flow := _section(path, "flow")
		if not _parse_bool(flow.get("storable", ""), false):
			continue
		if str(flow.get("flow_type", "")).strip_edges() != "stock":
			continue
		var id := str(_section(path, "meta").get("id", "")).strip_edges()
		var key := id.substr(id.find(".") + 1) if id.contains(".") else id
		if key.is_empty():
			continue
		out.append({
			"key": key,
			"name": str(_section(path, "base").get("name", key)).strip_edges(),
			"base_capacity": _parse_int(flow.get("base_capacity", ""), 0),
		})
	return out


# ============================================================
# CONF-D v2 原始读取 + 类型解析
# ============================================================

func _load_raw(path: String) -> int:
	if not FileAccess.file_exists(path):
		return _fail("ConfigError: file not found: %s" % path)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("ConfigError: cannot open: %s" % path)
	var sections := {}
	var current := ""
	var line_no := 0
	var raw_lines := file.get_as_text().split("\n")
	while line_no < raw_lines.size():
		line_no += 1
		var line := _strip_comment(raw_lines[line_no - 1]).strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("[") and line.ends_with("]"):
			current = line.substr(1, line.length() - 2).strip_edges()
			if current.is_empty():
				return _fail("ConfigError: %s:%d empty section name" % [path, line_no])
			if not sections.has(current):
				sections[current] = {}
			continue
		var eq := line.find("=")
		if eq == -1:
			return _fail("ConfigError: %s:%d expected 'key = value', got: %s" % [path, line_no, line])
		if current == "":
			return _fail("ConfigError: %s:%d key outside any [section]: %s" % [path, line_no, line])
		var key := line.substr(0, eq).strip_edges()
		var value := line.substr(eq + 1).strip_edges()
		# 多行数组: 值以 "[" 开头但未闭合 → 续读后续行拼接直到 "]" (逻辑书 D2.3)
		while value.begins_with("[") and not value.ends_with("]") and line_no < raw_lines.size():
			line_no += 1
			var next := _strip_comment(raw_lines[line_no - 1]).strip_edges()
			if not next.is_empty():
				value = "%s %s" % [value, next]
		sections[current][key] = value
	_raw[path] = sections
	return OK


# 去掉行内注释: ';' 在行首或前面是空白 → 其后为注释 (逻辑书 D2.2)
func _strip_comment(line: String) -> String:
	var idx := 0
	while idx < line.length():
		if line[idx] == ";":
			if idx == 0 or line[idx - 1] == " " or line[idx - 1] == "\t":
				return line.substr(0, idx)
		idx += 1
	return line


func _section(path: String, section: String) -> Dictionary:
	return _raw.get(path, {}).get(section, {})


# id_list: "[a.b, c.d]" -> ["a.b", "c.d"]; "[]" -> []; 尾逗号空项忽略
static func parse_list(raw: String) -> Array:
	var text := raw.strip_edges()
	if text.begins_with("[") and text.ends_with("]"):
		text = text.substr(1, text.length() - 2).strip_edges()
	if text.is_empty():
		return []
	var out: Array = []
	for item in text.split(","):
		var entry := item.strip_edges()
		if not entry.is_empty():
			out.append(entry)
	return out


# id_ref_with_level: "building.generator:2" -> {id, level}; 无 ":level" 则 level=1
static func parse_id_level(raw: String) -> Dictionary:
	var text := raw.strip_edges()
	var idx := text.rfind(":")
	if idx == -1:
		return {"id": text, "level": 1}
	var level_text := text.substr(idx + 1).strip_edges()
	if not level_text.is_valid_int():
		return {"id": text, "level": 1}
	return {"id": text.substr(0, idx).strip_edges(), "level": level_text.to_int()}


# range: "10~30" -> {min, max}
static func parse_range(raw: String) -> Dictionary:
	var text := raw.strip_edges()
	var idx := text.find("~")
	if idx == -1:
		var v := _parse_float(text, 0.0)
		return {"min": v, "max": v}
	return {
		"min": _parse_float(text.substr(0, idx).strip_edges(), 0.0),
		"max": _parse_float(text.substr(idx + 1).strip_edges(), 0.0),
	}


static func _parse_int(raw: String, default_value: int) -> int:
	var text := raw.strip_edges()
	if text.is_valid_int():
		return text.to_int()
	if text.is_valid_float():
		return int(text.to_float())
	return default_value


static func _parse_float(raw: String, default_value: float) -> float:
	var text := raw.strip_edges()
	if text.is_valid_float() or text.is_valid_int():
		return text.to_float()
	return default_value


static func _parse_bool(raw: String, default_value: bool) -> bool:
	var text := raw.strip_edges().to_lower()
	if text == "true":
		return true
	if text == "false":
		return false
	return default_value


func _fail(message: String) -> int:
	_error = message
	return ERR_INVALID_DATA


# ============================================================
# system.conf: 开关 / 依赖 / 引擎参数
# ============================================================

func _load_system_conf() -> int:
	var err := _load_raw(SYSTEM_CONF_PATH)
	if err != OK:
		return err
	var meta := _section(SYSTEM_CONF_PATH, "meta")
	if meta.get("schema", "") != "system":
		return _fail("ConfigError: system.conf [meta] schema must be 'system'")
	if _parse_int(meta.get("config_version", ""), -1) != CONF_VERSION:
		return _fail("ConfigError: system.conf config_version mismatch (expect %d)" % CONF_VERSION)

	var system_section := _section(SYSTEM_CONF_PATH, "system")
	if system_section.is_empty():
		return _fail("ConfigError: system.conf missing [system] switches")
	for key in system_section:
		_systems[key] = _parse_bool(system_section[key], false)
	# CORE 恒开 (AGENTS.md §12.2): core/config/save/time/ui 不在开关表里
	for core_name in ["core", "config", "save", "time", "ui"]:
		_systems[core_name] = true

	var deps := _section(SYSTEM_CONF_PATH, "dependencies")
	for key in deps:
		_dependencies[key] = parse_list(deps[key])

	_engine = _section(SYSTEM_CONF_PATH, "engine")
	if not _engine.has("real_seconds_per_game_hour"):
		return _fail("ConfigError: system.conf [engine] missing core field real_seconds_per_game_hour")

	# [dependencies] 硬依赖校验 (逻辑书 D2.9 MissingDependency)
	for system_name in _systems:
		if not _systems[system_name]:
			continue
		for dep in _dependencies.get(system_name, []):
			if not _systems.get(dep, false):
				return _fail(
					"MissingDependency: %s requires %s.\nPlease enable: %s = true"
					% [system_name, dep, dep]
				)
	return OK


# ============================================================
# shelter.conf + shelter_levels.conf (仅 shelter 开启时加载)
# ============================================================

func _load_shelter_conf() -> int:
	const SHELTER_PATH := "res://configs/shelter/shelter.conf"
	var err := _load_raw(SHELTER_PATH)
	if err != OK:
		return err
	var meta := _section(SHELTER_PATH, "meta")
	if meta.get("schema", "") != "shelter":
		return _fail("ConfigError: shelter.conf [meta] schema must be 'shelter'")

	var base := _section(SHELTER_PATH, "base")
	var shelter_name: String = str(base.get("name", ""))
	if shelter_name.is_empty():
		return _fail("MissingData: shelter.conf [base] name is empty")
	var max_level := _parse_int(base.get("max_level", ""), -1)
	var mvp_max_level := _parse_int(base.get("mvp_max_level", ""), -1)
	var levels_file: String = str(base.get("levels_file", ""))
	if max_level < 1 or mvp_max_level < 1 or levels_file.is_empty():
		return _fail("MissingData: shelter.conf [base] needs max_level / mvp_max_level / levels_file")

	_shelter_base = {
		"id": meta.get("id", ""),
		"name": shelter_name,
		"description": base.get("description", ""),
		"location_id": base.get("location_id", ""),
		"max_level": max_level,
		"mvp_max_level": mvp_max_level,
		"levels_file": levels_file,
		"initial_state": _parse_initial_state(SHELTER_PATH),
	}

	# 视觉阶段 (字符串列表, 原样保留; 场景表现 S1 只用 lv1.png 背景)
	var visual := _section(SHELTER_PATH, "visual")
	_shelter_base["visual_stages"] = parse_list(visual.get("visual_stages", "[]"))

	return _load_shelter_levels("res://configs/" + levels_file, mvp_max_level)


func _parse_initial_state(path: String) -> Dictionary:
	var init := _section(path, "initial_state")
	return {
		"initial_buildings": parse_list(init.get("initial_buildings", "[]")),
		"initial_building_level": _parse_int(init.get("initial_building_level", ""), 1),
		"initial_resource_wood": _parse_int(init.get("initial_resource_wood", ""), 0),
		"initial_resource_steel": _parse_int(init.get("initial_resource_steel", ""), 0),
		"initial_resource_food": _parse_int(init.get("initial_resource_food", ""), 0),
		"initial_resource_water": _parse_int(init.get("initial_resource_water", ""), 0),
		"initial_population": _parse_int(init.get("initial_population", ""), 0),
		"starter_npcs": parse_list(init.get("starter_npcs", "[]")),
	}


# 等级表: 必须是 1..N 连续且 N >= mvp_max_level (MVP 可达等级齐全)
# S1 必填字段: name / population_cap / building_slots / storage_bonus /
# production_bonus_percent / defense / requirements_shelter_level
# upgrade_cost_* / income_* / requirements_buildings / unlocks_* 本期休眠不校验
func _load_shelter_levels(path: String, mvp_max_level: int) -> int:
	var err := _load_raw(path)
	if err != OK:
		return err
	var meta := _section(path, "meta")
	if meta.get("schema", "") != "shelter_levels":
		return _fail("ConfigError: shelter_levels.conf [meta] schema must be 'shelter_levels'")

	_shelter_levels.clear()
	var found_levels: Array = []
	for section in _raw[path]:
		if section.begins_with("level."):
			var level_no := _parse_int(section.substr(6), -1)
			if level_no < 1:
				return _fail("ConfigError: %s bad section [%s]" % [path, section])
			found_levels.append(level_no)
	if found_levels.is_empty():
		return _fail("ConfigError: %s has no [level.N] sections" % path)
	found_levels.sort()
	var highest: int = found_levels[found_levels.size() - 1]
	for n in range(1, highest + 1):
		if not found_levels.has(n):
			return _fail("ConfigError: %s missing [level.%d]" % [path, n])
	if highest < mvp_max_level:
		return _fail(
			"ConfigError: %s only defines up to [level.%d] but mvp_max_level = %d"
			% [path, highest, mvp_max_level]
		)

	for level_no in found_levels:
		var parsed := _parse_level(path, "level.%d" % level_no)
		if parsed.is_empty():
			return ERR_INVALID_DATA
		_shelter_levels[level_no] = parsed
	return OK


func _parse_level(path: String, section: String) -> Dictionary:
	var s := _section(path, section)
	var level_name: String = str(s.get("name", ""))
	if level_name.is_empty():
		_error = "MissingData: %s [%s] name is empty" % [path, section]
		return {}
	for required in [
		"population_cap", "building_slots", "storage_bonus",
		"production_bonus_percent", "defense", "requirements_shelter_level",
	]:
		if not s.has(required):
			_error = "MissingData: %s [%s] missing %s" % [path, section, required]
			return {}
	return {
		"name": level_name,
		"description": s.get("description", ""),
		"visual_stage": s.get("visual_stage", ""),
		"population_cap": _parse_int(s.get("population_cap", ""), -1),
		"building_slots": _parse_int(s.get("building_slots", ""), -1),
		"storage_bonus": _parse_int(s.get("storage_bonus", ""), 0),
		"production_bonus_percent": _parse_float(s.get("production_bonus_percent", ""), 0.0),
		"defense": _parse_int(s.get("defense", ""), 0),
		"requirements_shelter_level": _parse_int(s.get("requirements_shelter_level", ""), 0),
		# 休眠字段 (S2 起生效), 原样解析备用
		"income_wood_per_hour": _parse_float(s.get("income_wood_per_hour", ""), 0.0),
		"income_steel_per_hour": _parse_float(s.get("income_steel_per_hour", ""), 0.0),
		"upgrade_cost_wood": _parse_int(s.get("upgrade_cost_wood", ""), 0),
		"upgrade_cost_steel": _parse_int(s.get("upgrade_cost_steel", ""), 0),
		"upgrade_cost_food": _parse_int(s.get("upgrade_cost_food", ""), 0),
		"upgrade_cost_water": _parse_int(s.get("upgrade_cost_water", ""), 0),
		"requirements_buildings": parse_list(s.get("requirements_buildings", "[]")),
		"unlocks_buildings": parse_list(s.get("unlocks_buildings", "[]")),
		"unlocks_systems": parse_list(s.get("unlocks_systems", "[]")),
		"unlocks_locations": parse_list(s.get("unlocks_locations", "[]")),
	}
