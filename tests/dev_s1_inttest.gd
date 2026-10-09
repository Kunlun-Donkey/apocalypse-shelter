extends Node
# ============================================================
# 世界/室内场景导航验证 (headless):
#   godot --headless --path . res://tests/dev_s1_inttest.tscn
# 覆盖: 登录"开始新游戏" → Main (顶部资源条/等级 + 底部 6 功能按钮)
#       → 3 占位按钮提示 "后续版本开放: X"
#       → 招募面板 (Btn_Recruit 木板卡片: 陈少强/凪光/唐子涵, 每卡招募按钮+成功弹窗 + 一次性选人锁定)
#         已选状态归 NpcSystem (config_id), BtnRecruit 为姓名门面 (is_picked/get_picked_id/被动查询)
#       → 任务卷轴面板 (列表 任务1~10/详情/接受/放弃)
#       → "进入" → ShelterInterior (瓦片网格 TileGrid + 升级区)
#       → 卧室 CompanionSlot 同伴名牌 → NpcDetailPanel 详情 (Mask/Esc 关闭 + 空位守卫)
#       → 室内升级 30s 冷却 → BackButton 返回 Main
#       → 设置弹层 game_menu 段 (存读档 3 槽/返回标题, 含 quest.accepted +
#         npc.picked(config_id)/recruit.picked(姓名镜像) round-trip)
# 断言项数: 99 (原 94 → 99; 室内段 3→8: 一房一床 → 瓦片网格 TileGrid)
# ============================================================

var _failed := false


func _ready() -> void:
	_run()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		_failed = true
		printerr("FAIL: " + label)


func _find_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found := _find_by_name(child, target)
		if found != null:
			return found
	return null


func _abort() -> void:
	printerr("INTTEST: FAILED")
	get_tree().quit(1)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _run() -> void:
	await get_tree().process_frame
	# 自己脱离 current_scene, 防止 change_scene 时被一并释放
	get_tree().current_scene = null

	var err := ConfigManager.load_all()
	_check(err == OK, "配置加载 OK")
	if err != OK:
		printerr("CONFIG ERROR: " + ConfigManager.get_error_message())
		_abort()
		return

	# 模拟 Boot 创建 ShelterSystem (login/main 依赖 /root/ShelterSystem)
	var shelter := ShelterSystem.new()
	shelter.name = "ShelterSystem"
	get_tree().root.add_child.call_deferred(shelter)
	await get_tree().process_frame

	# 模拟 Boot 创建 NpcSystem (boot.gd npc=true 时挂 /root/NpcSystem, BtnRecruit 门面透传)
	var npc_sys := NpcSystem.new()
	npc_sys.name = "NpcSystem"
	get_tree().root.add_child.call_deferred(npc_sys)
	await get_tree().process_frame

	# 挂上登录界面 (模拟 Boot → Login)
	var login := (load("res://src/scenes/login.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(login)
	get_tree().current_scene = login
	await get_tree().process_frame

	var new_game := _find_by_name(login, "NewGameButton") as Button
	_check(new_game != null, "登录界面存在 开始新游戏 按钮")
	if new_game == null:
		_abort()
		return

	new_game.pressed.emit()
	await _settle()

	# 断言到达主界面 (底部 任务 按钮为新锚点)
	var main_scene := get_tree().current_scene
	var task_btn: Button = null
	if main_scene != null:
		task_btn = _find_by_name(main_scene, "TaskButton") as Button
	_check(task_btn != null, "点击后进入主界面 (存在 TaskButton)")
	if task_btn == null:
		_abort()
		return

	# 底部 6 功能按钮齐 (节点名 = 测试契约)
	_check(_find_by_name(main_scene, "WarehouseButton") != null, "主界面存在 WarehouseButton (仓库)")
	_check(_find_by_name(main_scene, "OutCityButton") != null, "主界面存在 OutCityButton (出城)")
	_check(_find_by_name(main_scene, "ExploreButton") != null, "主界面存在 ExploreButton (探索)")
	_check(_find_by_name(main_scene, "Btn_Recruit") != null, "主界面存在 Btn_Recruit (招募)")
	var enter := _find_by_name(main_scene, "EnterShelterButton") as Button
	_check(enter != null and enter.text == "进入", "主界面存在 EnterShelterButton (text=进入)")
	var level_label := _find_by_name(main_scene, "LevelLabel") as Label
	_check(level_label != null and level_label.text.begins_with("Lv1"), "顶部 LevelLabel 显示 Lv1")

	# 3 占位按钮点击 → StatusLabel "后续版本开放: X" (任务/招募/进入不是占位)
	var placeholders: Array = [
		["WarehouseButton", "仓库"],
		["OutCityButton", "出城"],
		["ExploreButton", "探索"],
	]
	for item: Array in placeholders:
		var btn := _find_by_name(main_scene, str(item[0])) as Button
		var ok := btn != null
		if ok:
			btn.pressed.emit()
			await get_tree().process_frame
			var status := _find_by_name(main_scene, "StatusLabel") as Label
			ok = status != null and status.text == "后续版本开放: %s" % str(item[1])
		_check(ok, "点 %s 占位提示 '后续版本开放: %s'" % [str(item[1]), str(item[1])])

	# ---- 招募面板 (Btn_Recruit 木板卡片三选一) ----
	var recruit_btn := _find_by_name(main_scene, "Btn_Recruit") as Button
	if recruit_btn == null:
		_abort()
		return
	var recruit_panel := _find_by_name(main_scene, "RecruitPanel") as Control
	_check(recruit_panel != null, "RecruitPanel 常驻场景 (Btn_Recruit 挂载)")
	if recruit_panel == null:
		_abort()
		return
	_check(not recruit_panel.visible, "招募面板默认隐藏")
	recruit_btn.pressed.emit()
	await _settle()
	_check(recruit_panel.visible, "点 Btn_Recruit 显示招募面板")
	recruit_btn.pressed.emit()
	await _settle()
	_check(not recruit_panel.visible, "再点 Btn_Recruit 关闭招募面板")
	recruit_btn.pressed.emit()
	await _settle()
	_check(recruit_panel.visible, "三击 Btn_Recruit 面板再次显示")

	_check(_find_by_name(recruit_panel, "RecruitBox") != null, "面板含 RecruitBox (1400×760 弹窗)")
	_check(_find_by_name(recruit_panel, "Mask") != null, "面板含全屏遮罩 Mask")
	var cards_ok := true
	var expect_names := ["陈少强", "凪光", "唐子涵"]
	var expect_titles := ["老兵", "医师", "工程师"]
	for i in range(3):
		var card := _find_by_name(recruit_panel, "NpcCard_%d" % (i + 1))
		var name_label := _find_by_name(recruit_panel, "NpcName_%d" % (i + 1)) as Label
		var title_label := _find_by_name(recruit_panel, "NpcTitle_%d" % (i + 1)) as Label
		if card == null or name_label == null or name_label.text != expect_names[i] \
				or title_label == null or title_label.text != expect_titles[i]:
			cards_ok = false
	_check(cards_ok, "3 张 NpcCard 姓名/职业 = 陈少强老兵/凪光医师/唐子涵工程师")

	# 属性条: TextureProgressBar max=10, 值按 NPC_DATA 字典
	var bar := _find_by_name(recruit_panel, "AttrBar_1_1") as TextureProgressBar
	_check(bar != null and bar.max_value == 10.0 and bar.value == 8.0, "陈少强 AttrBar_1_1 体力 8/10")
	bar = _find_by_name(recruit_panel, "AttrBar_2_3") as TextureProgressBar
	_check(bar != null and bar.max_value == 10.0 and bar.value == 9.0, "凪光 AttrBar_2_3 智慧 9/10")
	bar = _find_by_name(recruit_panel, "AttrBar_3_3") as TextureProgressBar
	_check(bar != null and bar.value == 10.0, "唐子涵 AttrBar_3_3 智慧 10/10")
	var fam := _find_by_name(recruit_panel, "Familiarity_1") as Label
	_check(fam != null and fam.text == "熟悉度: 35", "Familiarity_1 = 熟悉度: 35")
	var passive := _find_by_name(recruit_panel, "PassiveTitle_1") as Label
	_check(passive != null and passive.text == "【觅食专长】", "PassiveTitle_1 = 【觅食专长】")
	var active := _find_by_name(recruit_panel, "ActiveTitle_3") as Label
	_check(active != null and active.text == "【机械守卫】", "ActiveTitle_3 = 【机械守卫】")
	var desc2 := _find_by_name(recruit_panel, "Desc_2") as Label
	_check(desc2 != null and desc2.text.contains("外科医师"), "Desc_2 含凪光背景文案")
	_check(_find_by_name(recruit_panel, "Diamond_1") != null and _find_by_name(recruit_panel, "Diamond_3") != null, "每卡顶部有钻石 Diamond_N")

	# 每卡招募按钮+成功弹窗 (3 选 1 一次性锁定): 点 RecruitButton_2 招募 凪光
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	var btn1 := _find_by_name(recruit_panel, "RecruitButton_1") as Button
	var btn2 := _find_by_name(recruit_panel, "RecruitButton_2") as Button
	var btn3 := _find_by_name(recruit_panel, "RecruitButton_3") as Button
	_check(btn1 != null and btn2 != null and btn3 != null, "每卡含招募按钮 RecruitButton_1/2/3")
	if btn2 == null:
		_abort()
		return
	var card2 := _find_by_name(recruit_panel, "NpcCard_2") as Control
	if card2 == null:
		_abort()
		return
	# 整卡点击不再触发招募
	card2.gui_input.emit(click)
	await get_tree().process_frame
	_check(not BtnRecruit.is_picked("凪光"), "整卡点击不触发招募 (NpcCard_2 gui_input 不入队)")
	# 点招募按钮 → 入队 + 面板关闭 + 成功弹窗
	btn2.pressed.emit()
	await _settle()
	_check(not recruit_panel.visible, "点招募按钮后面板关闭")
	_check(BtnRecruit.is_picked("凪光") and BtnRecruit.get_picked_id() == "npc.medic_01", "BtnRecruit 入队 凪光 (get_picked_id = npc.medic_01)")
	var npc_root := get_tree().root.get_node_or_null("NpcSystem") as NpcSystem
	_check(npc_root != null and absf(npc_root.get_passive_bonus("casualty_reduce_percent") - 30.0) < 0.001, "NpcSystem 被动 casualty_reduce_percent = 30")
	# 成功弹窗 (挂在场景根)
	var success_panel := _find_by_name(main_scene, "RecruitSuccessPanel") as Control
	var success_label := _find_by_name(main_scene, "RecruitSuccessLabel") as Label
	_check(success_panel != null and success_label != null \
			and success_label.text == "成功招募 凪光！可在庇护所内查看详细信息", "成功弹窗 RecruitSuccessPanel 文案 = 成功招募 凪光！可在庇护所内查看详细信息")
	var success_ok := _find_by_name(main_scene, "RecruitSuccessOkButton") as Button
	if success_panel == null or success_ok == null:
		_abort()
		return
	success_ok.pressed.emit()
	await _settle()
	_check(_find_by_name(main_scene, "RecruitSuccessPanel") == null, "点 RecruitSuccessOkButton 后成功弹窗销毁")
	# 锁定后重开面板仍可查看三人
	recruit_btn.pressed.emit()
	await _settle()
	_check(recruit_panel.visible, "锁定后重开面板仍可查看 (Btn_Recruit 再开)")
	# 已选卡描边 / 未选卡无描边
	var card2_style := card2.get_theme_stylebox("panel") as StyleBoxFlat
	_check(card2_style != null and card2_style.border_color.a > 0.5, "已选卡显示深棕描边")
	var card1 := _find_by_name(recruit_panel, "NpcCard_1") as Control
	var card1_style: StyleBoxFlat = null
	if card1 != null:
		card1_style = card1.get_theme_stylebox("panel") as StyleBoxFlat
	_check(card1_style != null and card1_style.border_color.a < 0.5, "未选卡无描边")
	# 锁定后按钮状态: 文案 已招募 + 三按钮全禁用
	_check(btn2.text == "已招募" and btn1 != null and btn3 != null \
			and btn1.disabled and btn2.disabled and btn3.disabled, "锁定后 RecruitButton_2 文案 已招募 且三按钮全禁用")
	# 点遮罩关闭
	var mask := _find_by_name(recruit_panel, "Mask") as Control
	if mask == null:
		_abort()
		return
	mask.gui_input.emit(click)
	await get_tree().process_frame
	_check(not recruit_panel.visible, "点 Mask 遮罩关闭面板")

	# ---- 任务面板 (发黄卷轴: 左列表 任务1~10 + 右详情 + 接受/放弃) ----
	task_btn.pressed.emit()
	await _settle()
	var quest_panel := _find_by_name(main_scene, "TaskPanel")
	_check(quest_panel != null, "点 任务 弹出卷轴任务面板 TaskPanel")
	if quest_panel == null:
		_abort()
		return
	_check(_find_by_name(quest_panel, "ScrollBg") != null, "任务面板含卷轴底图 ScrollBg")
	var task_list := _find_by_name(quest_panel, "TaskList") as ItemList
	_check(task_list != null and task_list.item_count == 10, "任务列表 10 条 (任务1~10 占位)")
	var task_title := _find_by_name(quest_panel, "TaskTitle") as Label
	_check(task_title != null and task_title.text == "任务1", "默认选中第一条显示 任务1 详情")
	var accept_btn := _find_by_name(quest_panel, "AcceptButton") as Button
	var abandon_btn := _find_by_name(quest_panel, "AbandonButton") as Button
	_check(accept_btn != null and abandon_btn != null, "详情下有 接受任务/放弃任务 按钮")
	if accept_btn == null or abandon_btn == null or task_list == null:
		_abort()
		return

	accept_btn.pressed.emit()
	await get_tree().process_frame
	_check(task_list.get_item_text(0).contains("已接受"), "接受后列表项标记 已接受")
	_check(TaskPanel.is_accepted("quest.placeholder_01"), "接受后状态进入 TaskPanel.accepted")

	abandon_btn.pressed.emit()
	await get_tree().process_frame
	_check(task_list.get_item_text(0) == "任务1", "放弃后列表项清除 已接受 标记")
	_check(not TaskPanel.is_accepted("quest.placeholder_01"), "放弃后状态移除")

	accept_btn.pressed.emit()
	await get_tree().process_frame
	var quest_close := _find_by_name(quest_panel, "QuestCloseButton") as Button
	_check(quest_close != null, "任务面板含关闭按钮")
	if quest_close == null:
		_abort()
		return
	quest_close.pressed.emit()
	await _settle()
	_check(_find_by_name(main_scene, "TaskPanel") == null, "关闭按钮收起任务面板")

	if enter == null:
		_abort()
		return

	# 进入室内场景
	enter.pressed.emit()
	await _settle()

	var interior := get_tree().current_scene
	_check(interior != null and interior.name == "ShelterInterior", "点 进入 后 current_scene 切换到 ShelterInterior")
	if interior == null or interior.name != "ShelterInterior":
		_abort()
		return

	# 室内: 瓦片网格 TileGrid (2.5D 侧剖面拼贴)
	var tile_grid := _find_by_name(interior, "TileGrid") as GridContainer
	_check(tile_grid != null, "室内存在 TileGrid (GridContainer)")
	_check(
		ConfigManager.get_shelter_level(1).get("interior_grid", Vector2i(-1, -1)) == Vector2i(4, 3)
		and tile_grid != null
		and int(tile_grid.get_meta("grid_cols", -1)) == 4
		and int(tile_grid.get_meta("grid_rows", -1)) == 3,
		"CONF Lv1 interior_grid = (4, 3) 且 TileGrid meta grid_cols/grid_rows = 4/3"
	)
	var cell_0_0 := _find_by_name(interior, "TileCell_0_0") as TextureRect
	_check(
		cell_0_0 != null
		and str(cell_0_0.get_meta("tile_component", "")) == "tile_ceiling"
		and int(cell_0_0.get_meta("grid_col", -1)) == 0
		and int(cell_0_0.get_meta("grid_row", -1)) == 0,
		"TileCell_0_0 meta tile_component = tile_ceiling (grid 0/0)"
	)
	var cell_0_2 := _find_by_name(interior, "TileCell_0_2") as TextureRect
	_check(
		cell_0_2 != null
		and str(cell_0_2.get_meta("tile_component", "")) == "tile_floor"
		and int(cell_0_2.get_meta("grid_col", -1)) == 0
		and int(cell_0_2.get_meta("grid_row", -1)) == 2,
		"TileCell_0_2 meta tile_component = tile_floor (grid 0/2)"
	)
	var cell_0_1 := _find_by_name(interior, "TileCell_0_1") as TextureRect
	var cell_3_1 := _find_by_name(interior, "TileCell_3_1") as TextureRect
	_check(
		cell_0_1 != null and cell_3_1 != null
		and str(cell_0_1.get_meta("tile_component", "")) == "tile_wall_side_left"
		and int(cell_0_1.get_meta("grid_col", -1)) == 0 and int(cell_0_1.get_meta("grid_row", -1)) == 1
		and str(cell_3_1.get_meta("tile_component", "")) == "tile_wall_side_right"
		and int(cell_3_1.get_meta("grid_col", -1)) == 3 and int(cell_3_1.get_meta("grid_row", -1)) == 1,
		"侧墙 TileCell_0_1 = tile_wall_side_left / TileCell_3_1 = tile_wall_side_right"
	)
	var cell_2_1 := _find_by_name(interior, "TileCell_2_1") as TextureRect
	var cell_1_1 := _find_by_name(interior, "TileCell_1_1") as TextureRect
	_check(
		cell_2_1 != null and cell_1_1 != null
		and str(cell_2_1.get_meta("tile_component", "")) == "tile_wall_door"
		and int(cell_2_1.get_meta("grid_col", -1)) == 2 and int(cell_2_1.get_meta("grid_row", -1)) == 1
		and str(cell_1_1.get_meta("tile_component", "")) == "tile_wall_window"
		and int(cell_1_1.get_meta("grid_col", -1)) == 1 and int(cell_1_1.get_meta("grid_row", -1)) == 1,
		"门窗 TileCell_2_1 = tile_wall_door (cols/2) / TileCell_1_1 = tile_wall_window"
	)
	var cell_1_0 := _find_by_name(interior, "TileCell_1_0")
	_check(cell_1_0 is TextureRect, "TileCell_1_0 是 TextureRect (顶排瓦片)")
	_check(
		_find_by_name(interior, "RoomPanel_1") == null and _find_by_name(interior, "BedLabel") == null,
		"RoomPanel_1 / BedLabel 已删 (瓦片网格取代占位房间卡)"
	)

	# 室内: 卧室同伴名牌 CompanionSlot + NpcDetailPanel 详情 (已招募 凪光)
	var slot := _find_by_name(interior, "CompanionSlot") as Button
	_check(slot != null, "室内存在 CompanionSlot (同伴名牌)")
	if slot == null:
		_abort()
		return
	_check(slot.text == "同伴: 凪光 · 医师", "CompanionSlot 文案 = 同伴: 凪光 · 医师")
	_check(not slot.disabled, "已招募 CompanionSlot 可点 (disabled=false)")
	slot.pressed.emit()
	await get_tree().process_frame
	var d_box := _find_by_name(interior, "DetailBox")
	_check(d_box != null, "点 CompanionSlot 弹出 NpcDetailPanel (DetailBox)")
	if d_box == null:
		_abort()
		return
	var d_name := _find_by_name(interior, "DetailName") as Label
	_check(d_name != null and d_name.text == "凪光", "DetailName = 凪光")
	var d_title := _find_by_name(interior, "DetailTitle") as Label
	_check(d_title != null and d_title.text == "医师", "DetailTitle = 医师")
	var d_fam := _find_by_name(interior, "DetailFamiliarity") as Label
	_check(d_fam != null and d_fam.text.contains("35"), "DetailFamiliarity 含 35")
	var d_bar3 := _find_by_name(interior, "DetailAttrBar_3") as TextureProgressBar
	_check(d_bar3 != null and d_bar3.value == 9.0, "DetailAttrBar_3 智慧 9/10")
	var d_desc := _find_by_name(interior, "DetailDesc") as Label
	_check(d_desc != null and d_desc.text.contains("外科医师"), "DetailDesc 含外科医师文案")
	var d_passive := _find_by_name(interior, "DetailPassiveTitle") as Label
	_check(d_passive != null and d_passive.text == "【应急救护】", "DetailPassiveTitle = 【应急救护】")
	var d_active := _find_by_name(interior, "DetailActiveTitle") as Label
	_check(d_active != null and d_active.text == "【集中救治】", "DetailActiveTitle = 【集中救治】")

	# 关闭验证 (Mask 点击 + Esc 两布尔合并一条 _check): 点 Mask 关闭 → 重开 → Esc 关闭
	var d_mask := _find_by_name(interior, "DetailMask") as Control
	var close_ok := d_mask != null
	if close_ok:
		d_mask.gui_input.emit(click)
		await get_tree().process_frame
		close_ok = _find_by_name(interior, "DetailBox") == null
	if close_ok:
		slot.pressed.emit()
		await get_tree().process_frame
		d_box = _find_by_name(interior, "DetailBox")
		close_ok = d_box != null
	if close_ok:
		var d_panel: Node = _find_by_name(interior, "NpcDetailPanel")
		close_ok = d_panel != null
		if close_ok:
			var esc := InputEventKey.new()
			esc.keycode = KEY_ESCAPE
			esc.pressed = true
			d_panel._unhandled_input(esc)
			await get_tree().process_frame
			close_ok = _find_by_name(interior, "DetailBox") == null
	_check(close_ok, "Mask 点击关闭详情 + Esc 关闭详情 (NpcDetailPanel)")

	# 室内: 升级区 (自 main 迁入)
	var upgrade := _find_by_name(interior, "UpgradeButton") as Button
	_check(upgrade != null, "室内存在 UpgradeButton (升级只在室内)")
	if upgrade == null:
		_abort()
		return
	_check(_find_by_name(interior, "CooldownLabel") != null, "室内存在 CooldownLabel")
	var upgrade_status := _find_by_name(interior, "UpgradeStatusLabel") as Label
	_check(upgrade_status != null, "室内存在 UpgradeStatusLabel")

	# 点升级 → 30s 现实冷却
	upgrade.pressed.emit()
	await _settle()
	upgrade_status = _find_by_name(interior, "UpgradeStatusLabel") as Label
	_check(upgrade_status != null and upgrade_status.text == "开始升级...", "点升级后提示 开始升级...")
	upgrade = _find_by_name(interior, "UpgradeButton") as Button
	_check(upgrade != null and upgrade.disabled, "升级中按钮禁用")
	var cooldown := _find_by_name(interior, "CooldownLabel") as Label
	_check(cooldown != null and cooldown.text.begins_with("升级中"), "冷却倒计时显示 升级中")

	# BackButton 返回主界面
	var back := _find_by_name(interior, "BackButton") as Button
	_check(back != null, "室内存在 BackButton")
	if back == null:
		_abort()
		return
	back.pressed.emit()
	await _settle()

	var back_scene := get_tree().current_scene
	_check(back_scene != null and _find_by_name(back_scene, "TaskButton") != null, "返回后回到主界面 (存在 TaskButton)")

	# 设置弹层 game_menu 段 (存读档/返回标题)
	var settings_btn: Button = null
	if back_scene != null:
		settings_btn = _find_by_name(back_scene, "SettingsButton") as Button
	_check(settings_btn != null, "主界面存在 SettingsButton")
	if settings_btn == null:
		_abort()
		return
	settings_btn.pressed.emit()
	await _settle()

	var overlay := _find_by_name(back_scene, "SettingsOverlay")
	_check(overlay != null, "点设置弹出 SettingsOverlay")
	if overlay == null:
		_abort()
		return
	_check(_find_by_name(overlay, "SaveButton") != null, "游戏菜单含 SaveButton (保存进度)")
	_check(_find_by_name(overlay, "SlotOption") != null, "游戏菜单含 SlotOption (3 存档槽)")
	var slot_opt := _find_by_name(overlay, "SlotOption") as OptionButton
	_check(slot_opt != null and slot_opt.item_count == 3, "SlotOption 共 3 个槽位")
	_check(_find_by_name(overlay, "LoadButton") != null, "游戏菜单含 LoadButton (读取进度)")
	_check(_find_by_name(overlay, "MenuStatusLabel") != null, "游戏菜单含 MenuStatusLabel")
	_check(_find_by_name(overlay, "BackToTitleButton") != null, "游戏菜单含 BackToTitleButton (返回标题)")
	_check(_find_by_name(overlay, "FullscreenToggle") != null and _find_by_name(overlay, "VolumeSlider") != null, "设置原有 全屏/音量 保留")

	# 存读档 round-trip: quest.accepted (任务接受状态) 写入并恢复
	var slot_opt_menu := _find_by_name(overlay, "SlotOption") as OptionButton
	if slot_opt_menu != null:
		slot_opt_menu.select(2)  # 存档 3 (与 autotest 同槽, 测试专用)
	var save_btn := _find_by_name(overlay, "SaveButton") as Button
	_check(save_btn != null, "游戏菜单 SaveButton 可点")
	if save_btn == null:
		_abort()
		return
	save_btn.pressed.emit()
	await get_tree().process_frame
	var menu_status := _find_by_name(overlay, "MenuStatusLabel") as Label
	_check(menu_status != null and menu_status.text.begins_with("保存成功"), "保存进度成功 (快照含 quest/recruit)")
	TaskPanel.abandon("quest.placeholder_01")
	BtnRecruit.reset()
	var load_btn := _find_by_name(overlay, "LoadButton") as Button
	_check(load_btn != null, "游戏菜单 LoadButton 可点")
	if load_btn == null:
		_abort()
		return
	load_btn.pressed.emit()
	await get_tree().process_frame
	menu_status = _find_by_name(overlay, "MenuStatusLabel") as Label
	_check(menu_status != null and menu_status.text.begins_with("已读取"), "读取进度成功")
	_check(TaskPanel.is_accepted("quest.placeholder_01"), "读档恢复 已接受 任务状态")
	_check(BtnRecruit.is_picked("凪光"), "读档恢复 已招募 同伴状态 (凪光)")
	# 存档快照双字段: npc.picked = config_id (主) + recruit.picked = 姓名镜像 (旧字段)
	var save_data: Dictionary = SaveManager.load_game(3)
	var npc_part: Dictionary = save_data.get("npc", {})
	_check(str(npc_part.get("picked", "")) == "npc.medic_01", "存档快照 data.npc.picked = npc.medic_01 (config_id)")

	# ---- 空位块: BtnRecruit.reset() 清招募后重进室内 CompanionSlot 空位守卫 (收尾, 不污染存读档段) ----
	BtnRecruit.reset()
	var enter_again := _find_by_name(back_scene, "EnterShelterButton") as Button
	if enter_again == null:
		_abort()
		return
	enter_again.pressed.emit()
	await _settle()
	var interior2 := get_tree().current_scene
	if interior2 == null:
		_abort()
		return
	var slot2 := _find_by_name(interior2, "CompanionSlot") as Button
	_check(slot2 != null and slot2.text == "同伴: 空 (未招募)", "空位 CompanionSlot 文案 = 同伴: 空 (未招募)")
	_check(slot2 != null and slot2.disabled, "空位 CompanionSlot 禁用 (disabled=true)")
	var empty_ok := slot2 != null
	if empty_ok:
		slot2.pressed.emit()
		await get_tree().process_frame
		empty_ok = _find_by_name(interior2, "DetailBox") == null
	_check(empty_ok, "空位点 CompanionSlot 不弹详情 (空 id 守卫)")

	if _failed:
		printerr("INTTEST: FAILED")
		get_tree().quit(1)
	else:
		print("INTTEST: ALL PASSED")
		get_tree().quit(0)
