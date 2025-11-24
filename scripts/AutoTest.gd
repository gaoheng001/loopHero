# AutoTest.gd
# 统一无头测试入口：支持命令行标签与阶段过滤（e2e/full/phaseX）
extends SceneTree
## 动态加载测试模块，避免编译期预载失败

func _init():
	print("[AutoTest] 启动统一无头测试入口...")

	# 解析命令行参数
	var args = OS.get_cmdline_args()
	var tags: PackedStringArray = PackedStringArray()
	var scenario := "e2e"  # 可选: e2e / full
	for i in range(args.size()):
		var a = args[i]
		if a.begins_with("--tags="):
			tags = a.substr(7).split(",")
		elif a == "--tags" and i + 1 < args.size():
			tags = args[i + 1].split(",")
		elif a.begins_with("--scenario="):
			scenario = a.substr(11)
		elif a == "--scenario" and i + 1 < args.size():
			scenario = args[i + 1]
	# 环境变量兜底（在某些环境下命令行参数无法透传）
	if tags.size() == 0:
		var env_tags = OS.get_environment("AUTOTEST_TAGS")
		if env_tags != "":
			tags = env_tags.split(",")
	if scenario == "e2e":
		var env_scenario = OS.get_environment("AUTOTEST_SCENARIO")
		if env_scenario != "":
			scenario = env_scenario
	print("[AutoTest] 参数解析: scenario=%s, tags=%s" % [scenario, str(tags)])

	# 加载主场景
	var main_scene: PackedScene = load("res://scenes/MainGame.tscn")
	var main_instance = main_scene.instantiate()

	# 添加到场景树并设置为当前场景
	root.add_child(main_instance)
	current_scene = main_instance
	print("[AutoTest] 主场景已加载并设置为当前场景")

	# 等待两帧保证所有节点初始化完成
	await process_frame
	await process_frame

	var all_passed := true

	# 如果是完整场景验证，先跑 e2e 启动流程
	if scenario == "full" and tags.size() == 0:
		all_passed = await _run_e2e_start(main_instance) and all_passed
		var ui_ok = await _run_ui_time_updates(main_instance)
		_write_summary("ui_time_updates", ui_ok)
		all_passed = all_passed and ui_ok
		var loop_ok = await _run_loop_completion(main_instance)
		_write_summary("loop_completion", loop_ok)
		all_passed = all_passed and loop_ok

	# 根据标签选择阶段测试
	if (tags.find("phase2") != -1) or (scenario == "full"):
		print("[AutoTest] 执行 Phase2 测试模块")
		var phase2_script = load("res://scripts/tests/Phase2Tests.gd")
		var ok = await phase2_script.new().run(self, main_instance)
		all_passed = all_passed and ok

	# 增强版 Phase2 测试，保持向后兼容
	if (tags.find("phase2_enhanced") != -1):
		print("[AutoTest] 执行 Phase2 增强测试模块")
		var phase2_enhanced_script = load("res://scripts/tests/Phase2EnhancedTests.gd")
		if phase2_enhanced_script:
			# 期望该脚本提供 Node 并实现 run(tree, main_instance)
			var runner = phase2_enhanced_script.new()
			if runner and runner.has_method("run"):
				var ok2 = await runner.run(self, main_instance)
				all_passed = all_passed and ok2
			else:
				print("[AutoTest][WARN] Phase2EnhancedTests 未提供可调用的 run 方法，跳过")

	# 若无标签（默认），执行简单 e2e 启动验证
	if tags.size() == 0 and scenario == "e2e":
		all_passed = await _run_e2e_start(main_instance) and all_passed

	# 独立标签运行新增检查
	if tags.find("ui_time") != -1:
		var ui_only = await _run_ui_time_updates(main_instance)
		_write_summary("ui_time_updates", ui_only)
		all_passed = all_passed and ui_only
	if tags.find("loop_completion") != -1:
		var loop_only = await _run_loop_completion(main_instance)
		_write_summary("loop_completion", loop_only)
		all_passed = all_passed and loop_only
	if tags.find("ui_day_card") != -1:
		var day_ok = await _run_day_change_selection_state(main_instance)
		_write_summary("day_change_selection", day_ok)
		all_passed = all_passed and day_ok
	if tags.find("loop_label") != -1:
		var label_ok = await _run_loop_label_sync(main_instance)
		_write_summary("loop_label_sync", label_ok)
		all_passed = all_passed and label_ok

	# 新增标签：选择后恢复移动、刷新按钮断言、怪物生成与战斗恢复
	if tags.find("selection_resume") != -1:
		var sel_ok = await _run_selection_resume_after_choice(main_instance)
		_write_summary("selection_resume", sel_ok)
		all_passed = all_passed and sel_ok
	if tags.find("ui_refresh") != -1:
		var refresh_ok = await _run_refresh_button_assertions(main_instance)
		_write_summary("ui_refresh", refresh_ok)
		all_passed = all_passed and refresh_ok
	if tags.find("monster_spawn") != -1:
		var monster_ok = await _run_monster_spawn_and_battle_resume(main_instance)
		_write_summary("monster_spawn_battle_resume", monster_ok)
		all_passed = all_passed and monster_ok

	# 第三阶段演示标签：队伍整体回合战斗（Adventure & Mining 风格）
	if tags.find("team_battle_demo") != -1:
		var team_ok = await _run_team_battle_demo(main_instance)
		_write_summary("team_battle_demo", team_ok)
		all_passed = all_passed and team_ok

	# UI 演示标签：通过 BattleWindow 显示队伍战斗进度与回合日志
	if tags.find("team_battle_ui") != -1:
		var ui_team_ok = await _run_team_battle_ui_demo(main_instance)
		_write_summary("team_battle_ui_demo", ui_team_ok)
		all_passed = all_passed and ui_team_ok

	print("[AutoTest] 测试完成，结果:", all_passed)
	quit(0 if all_passed else 1)

func _run_e2e_start(main_instance) -> bool:
	# 触发开始循环（优先调用根控制器的入口方法）
	paused = false
	if main_instance.has_method("_on_start_button_pressed"):
		print("[AutoTest] 触发 MainGameController._on_start_button_pressed()")
		main_instance._on_start_button_pressed()
	else:
		var start_button = main_instance.get_node_or_null("UI/MainUI/BottomPanel/ControlsContainer/StartButton")
		if start_button:
			print("[AutoTest] 触发 StartButton pressed 信号")
			start_button.emit_signal("pressed")
		else:
			print("[AutoTest] 警告: 未找到开始按钮或入口方法，e2e 启动可能无法继续")

	# e2e 成功标准：任一关键流程触发（移动开启 或 战斗开始 或 卡牌选择窗口可见）
	var card_selection = main_instance.get_node_or_null("UI/CardSelectionWindow")
	var loop_manager = main_instance.get_node_or_null("LoopManager")
	var battle_manager = main_instance.get_node_or_null("BattleManager")

	var visible_seen := false
	var movement_seen := false
	var battle_seen := false

	var elapsed := 0.0
	while elapsed < 10.0:
		await create_timer(0.5).timeout
		elapsed += 0.5

		# 卡牌选择窗口可见（部分场景不会触发，此项非必需）
		if card_selection and card_selection.visible:
			visible_seen = true

		# 移动（is_moving 为真 或 step_count > 0）视为流程已开始
		if loop_manager and (loop_manager.is_moving or (loop_manager.step_count > 0)):
			movement_seen = true

		# 战斗流程触发（active）视为成功
		if battle_manager and battle_manager.is_battle_active():
			battle_seen = true

		if visible_seen or movement_seen or battle_seen:
			break

	print("[AutoTest] e2e 状态: visible=%s, movement=%s, battle=%s" % [str(visible_seen), str(movement_seen), str(battle_seen)])
	# 额外等待1秒以确保日志/状态输出完整
	await create_timer(1.0).timeout
	return visible_seen or movement_seen or battle_seen

func _run_ui_time_updates(main_instance) -> bool:
	# 验证：步数进度条与天数标签是否随 LoopManager 时间系统实时更新
	var loop_manager = main_instance.get_node_or_null("LoopManager")
	var day_label = main_instance.get_node_or_null("UI/MainUI/TopPanel/TimeContainer/DayLabel")
	var step_progress_bar = main_instance.get_node_or_null("UI/MainUI/TopPanel/TimeContainer/StepProgressBar")
	var step_label_time = main_instance.get_node_or_null("UI/MainUI/TopPanel/TimeContainer/StepLabel")

	if not loop_manager:
		print("[AutoTest][UI] 未找到 LoopManager，跳过 UI 时间更新检查")
		return false

	# 若未开始移动，触发一次开始循环
	if not loop_manager.is_moving:
		if main_instance.has_method("_on_start_button_pressed"):
			main_instance._on_start_button_pressed()
		else:
			var start_button = main_instance.get_node_or_null("UI/MainUI/BottomPanel/ControlsContainer/StartButton")
			if start_button:
				start_button.emit_signal("pressed")

	var ok_progress := false
	var ok_day_label := false

	var last_steps_in_day := -1
	var last_day := -1
	var elapsed := 0.0
	while elapsed < 10.0:
		await create_timer(0.5).timeout
		elapsed += 0.5

		var time_info: Dictionary = loop_manager.get_time_info()
		var current_day: int = int(time_info.get("current_day", 1))
		var steps_in_day: int = int(time_info.get("steps_in_current_day", 0))
		var steps_per_day: int = int(time_info.get("steps_per_day", 20))

		# 检查进度条与标签是否匹配时间系统
		if step_progress_bar and step_progress_bar.value == steps_in_day and step_progress_bar.max_value == steps_per_day:
			if last_steps_in_day != -1 and steps_in_day != last_steps_in_day:
				ok_progress = true
			last_steps_in_day = steps_in_day

		if day_label and day_label.text == "第" + str(current_day) + "天":
			if last_day != -1 and current_day != last_day:
				ok_day_label = true
			last_day = current_day

		if step_label_time and step_label_time.text == "步数: " + str(steps_in_day) + "/" + str(steps_per_day):
			# 步数标签与进度一致时，进一步增强进度判断
			if last_steps_in_day != -1 and steps_in_day != last_steps_in_day:
				ok_progress = true

		# 提前退出：两项均已满足
		if ok_progress and ok_day_label:
			break

	print("[AutoTest][UI] 时间显示检查: progress=%s, day_label=%s" % [str(ok_progress), str(ok_day_label)])
	return ok_progress and ok_day_label

func _run_loop_completion(main_instance) -> bool:
	# 验证：英雄完成一整圈后 LoopManager 是否达到环完成条件
	var loop_manager = main_instance.get_node_or_null("LoopManager")
	if not loop_manager:
		print("[AutoTest][Loop] 未找到 LoopManager，跳过循环完成检查")
		return false

	# 确保在移动中
	if not loop_manager.is_moving:
		if main_instance.has_method("_on_start_button_pressed"):
			main_instance._on_start_button_pressed()
		else:
			var start_button = main_instance.get_node_or_null("UI/MainUI/BottomPanel/ControlsContainer/StartButton")
			if start_button:
				start_button.emit_signal("pressed")

	var seen_index_gt_zero := false
	var loop_completed_inferred := false
	var elapsed := 0.0
	while elapsed < 30.0:
		await create_timer(0.5).timeout
		elapsed += 0.5
		var idx: int = int(loop_manager.current_tile_index)
		var steps: int = int(loop_manager.step_count)
		if idx > 0:
			seen_index_gt_zero = true
		# 当索引曾经>0后又回到0，并且步数>0，推断完成一圈
		if seen_index_gt_zero and idx == 0 and steps > 0:
			loop_completed_inferred = true
			break

	print("[AutoTest][Loop] 循环完成推断: ", loop_completed_inferred)
	return loop_completed_inferred

func _write_summary(name: String, ok: bool, extra: String = "") -> void:
	# 将摘要写入项目根的 test_output.txt
	var path := "user://test_output.txt"
	var existing := ""
	if FileAccess.file_exists(path):
		var rf = FileAccess.open(path, FileAccess.READ)
		if rf:
			existing = rf.get_as_text()
			rf.close()
	var wf = FileAccess.open(path, FileAccess.WRITE)
	var suffix := (" " + extra) if extra != "" else ""
	var line := "[" + name + "] ok=" + str(ok) + suffix + "\n"
	if wf:
		wf.store_string(existing + line)
		wf.close()
	# 同步打印到控制台，避免文件路径不可写导致信息丢失
	print(line)

func _run_day_change_selection_state(main_instance) -> bool:
	# 验证：调用控制器的 _on_day_changed 后，LoopManager 进入暂停并 selection_active 为真
	var loop_manager = main_instance.get_node_or_null("LoopManager")
	var card_selection = main_instance.get_node_or_null("UI/CardSelectionWindow")
	if not loop_manager:
		print("[AutoTest][Day] 未找到 LoopManager，跳过")
		return false

	# 触发一次开始循环，确保环境正常
	if not loop_manager.is_moving:
		if main_instance.has_method("_on_start_button_pressed"):
			main_instance._on_start_button_pressed()

	# 获取当前天数，模拟到下一天
	var info: Dictionary = loop_manager.get_time_info()
	var next_day: int = int(info.get("current_day", 1)) + 1
	if main_instance.has_method("_on_day_changed"):
		main_instance._on_day_changed(next_day)

	# 等待 UI 响应
	await create_timer(0.5).timeout

	var paused_ok: bool = (loop_manager.is_moving == false)
	var selection_ok: bool = (loop_manager.selection_active == true)
	var visible_note: bool = (card_selection and card_selection.visible)
	print("[AutoTest][Day] paused=", paused_ok, " selection=", selection_ok, " visible=", visible_note)
	return paused_ok and selection_ok

func _run_loop_label_sync(main_instance) -> bool:
	# 验证：调用 GameManager.complete_loop 后底部 LoopLabel 与 loop_number 同步
	var game_manager = main_instance.get_node_or_null("GameManager")
	var loop_label = main_instance.get_node_or_null("UI/MainUI/BottomPanel/StatusContainer/LoopLabel")
	if not game_manager or not loop_label:
		print("[AutoTest][LoopLabel] 缺少必要节点，跳过")
		return false

	# 启动并完成一轮
	if main_instance.has_method("_on_start_button_pressed"):
		main_instance._on_start_button_pressed()
	await create_timer(0.2).timeout
	game_manager.complete_loop()
	await create_timer(0.2).timeout

	var expected_text := "循环: " + str(game_manager.loop_number)
	var ok: bool = (loop_label.text == expected_text)
	print("[AutoTest][LoopLabel] text=", loop_label.text, " expected=", expected_text, " ok=", ok)
	return ok

func _run_selection_resume_after_choice(main_instance) -> bool:
	# 验证：天数变化弹出选择后，选择地形卡在 headless 下自动放置并恢复移动
	var loop_manager = main_instance.get_node_or_null("LoopManager")
	var card_selection = main_instance.get_node_or_null("UI/CardSelectionWindow")
	var card_manager = main_instance.get_node_or_null("CardManager")
	if not loop_manager or not card_selection or not card_manager:
		print("[AutoTest][SelectResume] 缺少必要节点")
		return false

	# 确保移动已开始
	if not loop_manager.is_moving:
		if main_instance.has_method("_on_start_button_pressed"):
			main_instance._on_start_button_pressed()
		await create_timer(0.2).timeout

	# 触发到下一天以弹出选择窗口
	var info: Dictionary = loop_manager.get_time_info()
	var next_day: int = int(info.get("current_day", 1)) + 1
	if main_instance.has_method("_on_day_changed"):
		main_instance._on_day_changed(next_day)

	# 等待选择窗口状态与卡池准备
	var elapsed := 0.0
	var pool_ready := false
	while elapsed < 5.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
		if loop_manager.selection_active and card_selection.available_cards.size() > 0:
			pool_ready = true
			break

	if not pool_ready:
		print("[AutoTest][SelectResume] 卡池未准备或未进入选择状态")
		return false

	# 优先选择地形卡（自动放置更稳定）
	var terrain_card: Dictionary = {}
	for c in card_selection.available_cards:
		var t = c.get("type")
		var is_terrain := false
		if typeof(t) == TYPE_STRING:
			is_terrain = (t == "terrain")
		elif typeof(t) == TYPE_INT:
			# CardManager 使用枚举表示地形卡类型
			is_terrain = (t == CardManager.CardType.TERRAIN)
		if is_terrain:
			terrain_card = c
			break
	if terrain_card.is_empty():
		terrain_card = card_selection.available_cards[0]

	# 执行选择（headless 下会自动触发 selection_closed 与自动放置）
	card_selection._select_card(terrain_card)

	# 等待恢复移动与解除选择状态
	var resumed := false
	var selection_cleared := false
	elapsed = 0.0
	while elapsed < 5.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
		resumed = loop_manager.is_moving
		selection_cleared = (loop_manager.selection_active == false)
		if resumed and selection_cleared:
			break

	print("[AutoTest][SelectResume] resumed=", resumed, " selection_cleared=", selection_cleared)
	return resumed and selection_cleared

func _run_refresh_button_assertions(main_instance) -> bool:
	# 验证：刷新按钮禁用/启用与价格递增的核心断言
	var gm = main_instance.get_node_or_null("GameManager")
	var csw = main_instance.get_node_or_null("UI/CardSelectionWindow")
	if not gm or not csw:
		print("[AutoTest][UIRefresh] 缺少必要节点")
		return false

	# 打开选择窗口
	if not csw.visible and csw.has_method("show_card_selection"):
		csw.show_card_selection(1)
		await create_timer(0.2).timeout

	# 资源置零，按钮应禁用
	if gm.has_method("reset_resources"):
		gm.reset_resources()
	var cur = gm.get_resource_amount("spirit_stones")
	if cur > 0:
		gm.spend_resources("spirit_stones", cur)
	await create_timer(0.2).timeout

	var rb = csw.refresh_button
	var disabled_zero: bool = (rb != null) and rb.disabled

	# 增加资源，按钮应启用
	gm.add_resources("spirit_stones", 200)
	await create_timer(0.4).timeout
	var enabled_after: bool = (rb != null) and (rb.disabled == false)

	# 记录价格并执行一次刷新，检查递增
	var price_regex = RegEx.new()
	price_regex.compile("\\((\\d+)\\)")
	var m = price_regex.search(rb.text if rb else "")
	var p0: int = 0
	if m:
		p0 = m.get_string(1).to_int()
	if rb and not rb.disabled:
		rb.pressed.emit()
		await create_timer(0.4).timeout
	var m2 = price_regex.search(rb.text if rb else "")
	var p1: int = p0
	if m2:
		p1 = m2.get_string(1).to_int()

	var ok: bool = (disabled_zero and enabled_after and p1 > p0)
	print("[AutoTest][UIRefresh] disabled_zero=", disabled_zero, " enabled_after=", enabled_after, " price ", p0, "->", p1, " ok=", ok)
	return ok

var __spawn_signal_seen := false
func _on__auto_monsters_spawned(_positions: Array):
	__spawn_signal_seen = true

func _run_monster_spawn_and_battle_resume(main_instance) -> bool:
	# 验证：天数变化生成怪物，战斗结束后恢复移动
	var loop_manager = main_instance.get_node_or_null("LoopManager")
	var battle_manager = main_instance.get_node_or_null("BattleManager")
	var card_manager = main_instance.get_node_or_null("CardManager")
	# 兼容队伍战斗：不强制要求 BattleManager 存在
	if not loop_manager or not card_manager:
		print("[AutoTest][MonsterBattle] 缺少必要节点 (LoopManager/CardManager)")
		return false

	# 连接怪物生成信号
	__spawn_signal_seen = false
	if not loop_manager.is_connected("monsters_spawned", Callable(self, "_on__auto_monsters_spawned")):
		loop_manager.connect("monsters_spawned", Callable(self, "_on__auto_monsters_spawned"))

	# 统计初始怪物数量（遍历一定范围内的瓦片）
	var initial_monsters := 0
	for i in range(0, 64):
		var m = loop_manager.get_monster_at_tile(i)
		if not m.is_empty():
			initial_monsters += 1

	# 触发到下一天
	# 在无头测试中，直接调用怪物生成函数，避免依赖自然步进触发天数变化
	if loop_manager.has_method("_spawn_monsters_for_new_day"):
		loop_manager._spawn_monsters_for_new_day()
	await create_timer(0.6).timeout

	# 重新统计怪物数量或至少收到信号
	var after_monsters := 0
	for i in range(0, 64):
		var m2 = loop_manager.get_monster_at_tile(i)
		if not m2.is_empty():
			after_monsters += 1
	var spawn_ok := (__spawn_signal_seen or after_monsters > initial_monsters)

	# 确保移动开启
	if not loop_manager.is_moving:
		if main_instance.has_method("_on_start_button_pressed"):
			main_instance._on_start_button_pressed()
	await create_timer(0.2).timeout

	# 在当前位置放置一个敌人卡牌以触发战斗
	var enemy_card = card_manager.get_card_by_id("yaokou_camp")
	var tile_idx: int = int(loop_manager.get_current_tile_index())
	loop_manager.place_card_at_tile(tile_idx, enemy_card)

	# 等待战斗开始与结束
	var seen_start := false
	var seen_end := false
	# BattleWindow / TeamBattleManager 兼容检测
	var battle_window = main_instance.get_node_or_null("UI/BattleWindow")
	var elapsed := 0.0
	while elapsed < 10.0:
		await create_timer(0.25).timeout
		elapsed += 0.25
		var bm_active := false
		if battle_manager and battle_manager.has_method("is_battle_active"):
			bm_active = battle_manager.is_battle_active()

		var tbm_active := false
		# 优先从 BattleWindow.team_battle_manager 读取战斗活跃状态，其次尝试 BattleWindow 提供的方法
		if battle_window:
			if battle_window.team_battle_manager:
				if battle_window.team_battle_manager.has_method("is_battle_active"):
					tbm_active = battle_window.team_battle_manager.is_battle_active()
				else:
					var prop = battle_window.team_battle_manager.get("battle_active")
					if typeof(prop) == TYPE_BOOL:
						tbm_active = prop
			elif battle_window.has_method("is_battle_active"):
				tbm_active = battle_window.is_battle_active()

		if bm_active or tbm_active:
			seen_start = true
		else:
			if seen_start:
				seen_end = true
				break

	# 战斗结束后等待窗口关闭信号触发移动恢复（MainGameController 中有 2s 延迟隐藏）
	var resume_wait := 0.0
	while resume_wait < 5.0 and not loop_manager.is_moving:
		await create_timer(0.25).timeout
		resume_wait += 0.25

	# 战斗结束后应恢复移动
	var resumed: bool = loop_manager.is_moving
	# 若未在轮询中捕捉到结束，结合当前状态与恢复移动判断结束
	var end_ok := seen_end
	if battle_manager and battle_manager.has_method("is_battle_active"):
		end_ok = end_ok or (not battle_manager.is_battle_active())
	if battle_window:
		if battle_window.team_battle_manager:
			if battle_window.team_battle_manager.has_method("is_battle_active"):
				end_ok = end_ok or (not battle_window.team_battle_manager.is_battle_active())
			else:
				var prop2 = battle_window.team_battle_manager.get("battle_active")
				if typeof(prop2) == TYPE_BOOL:
					end_ok = end_ok or (not prop2)
		elif battle_window.has_method("is_battle_active"):
			end_ok = end_ok or (not battle_window.is_battle_active())
	end_ok = end_ok or resumed

	var ok_all: bool = spawn_ok and seen_start and end_ok and resumed
	print("[AutoTest][MonsterBattle] spawn_ok=", spawn_ok, " battle start/end=", seen_start, "/", end_ok, " resumed=", resumed, " ok=", ok_all)
	return ok_all

func _run_team_battle_demo(main_instance) -> bool:
	# 验证：最小整体回合战斗流程可运行并产生胜负结果（队伍风格）
	var TeamBattleManagerScript = load("res://scripts/TeamBattleManager.gd")
	var tbm = TeamBattleManagerScript.new()
	main_instance.add_child(tbm)

	var finished_result := ""
	var finished_stats := {}
	var finished_ok := false

	# 构建演示队伍（简单数值，确保可打出结果）
	var heroes := [
		{"name": "战士", "current_hp": 40, "max_hp": 40, "attack": 12, "defense": 4},
		{"name": "盗贼", "current_hp": 30, "max_hp": 30, "attack": 10, "defense": 3},
		{"name": "法师", "current_hp": 25, "max_hp": 25, "attack": 14, "defense": 2},
	]
	var enemies := [
		{"name": "枯骨", "current_hp": 28, "max_hp": 28, "attack": 9, "defense": 2},
		{"name": "蛛母幼体", "current_hp": 32, "max_hp": 32, "attack": 11, "defense": 3},
	]

	tbm.start_battle(heroes, enemies, {})
	tbm.run_to_completion(100)
	var hero_alive := 0
	var enemy_alive := 0
	for h in tbm.hero_team:
		var hp_h = (h.get("current_hp") if h.has("current_hp") else 0)
		if int(hp_h) > 0:
			hero_alive += 1
	for e in tbm.enemy_team:
		var hp_e = (e.get("current_hp") if e.has("current_hp") else 0)
		if int(hp_e) > 0:
			enemy_alive += 1
	finished_result = ("heroes_win" if enemy_alive == 0 else ("enemies_win" if hero_alive == 0 else "unknown"))
	finished_stats = {"turns": tbm.turn_index, "hero_alive": hero_alive, "enemy_alive": enemy_alive}
	finished_ok = (finished_result == "heroes_win")
	var ok: bool = finished_ok
	print("[AutoTest][TeamBattleDemo] result=", finished_result, " stats=", finished_stats, " ok=", ok)
	return ok

func _run_team_battle_ui_demo(main_instance) -> bool:
	# 通过 BattleWindow 展示 TeamBattleManager 的队伍战斗，并验证进度与日志输出
	var bw = main_instance.get_node_or_null("UI/BattleWindow")
	if bw == null:
		print("[AutoTest][TeamBattleUI] 未找到 UI/BattleWindow 节点")
		return false

	# 3v3 队伍示例，含技能、被动与状态效果键
	var heroes := [
		{"name": "战士", "current_hp": 42, "max_hp": 42, "attack": 12, "defense": 4, "skills": ["power_strike"], "passives": ["tough"], "status_effects": ["attack_up"]},
		{"name": "盗贼", "current_hp": 34, "max_hp": 34, "attack": 11, "defense": 3, "skills": ["multi_strike"], "passives": ["lifesteal"], "status_effects": []},
		{"name": "法师", "current_hp": 28, "max_hp": 28, "attack": 13, "defense": 2, "skills": ["power_strike"], "passives": ["berserk"], "status_effects": ["regen"]},
	]
	var enemies := [
		{"name": "枯骨", "current_hp": 30, "max_hp": 30, "attack": 9, "defense": 2, "skills": [], "passives": [], "status_effects": ["poison"]},
		{"name": "蛛母幼体", "current_hp": 33, "max_hp": 33, "attack": 11, "defense": 3, "skills": [], "passives": ["tough"], "status_effects": ["shield"]},
		{"name": "石像鬼", "current_hp": 26, "max_hp": 26, "attack": 10, "defense": 3, "skills": [], "passives": [], "status_effects": []},
	]

	# 调用 UI 接入方法（内部会创建/接入 TeamBattleManager 并运行到结束）
	if bw.has_method("show_team_battle"):
		bw.show_team_battle(heroes, enemies)
	else:
		print("[AutoTest][TeamBattleUI] BattleWindow 缺少 show_team_battle 方法")
		return false

	# 等待一帧以处理信号和文本更新
	await process_frame

	# 读取 UI 文本验证：进度标签显示完成、日志包含 TBM 文本、管理器处于非活跃
	var progress_label = bw.progress_label if bw.has_node("BattlePanel/MainContainer/LogSection/ProgressLabel") else null
	var log_text = bw.log_text if bw.has_node("BattlePanel/MainContainer/LogSection/LogScrollContainer/LogText") else null
	var finished_text_seen := false
	var tbm_log_seen := false
	if progress_label:
		finished_text_seen = (str(progress_label.text).find("完成") != -1)
	if log_text:
		tbm_log_seen = (str(log_text.text).find("[TBM]") != -1)

	var tbm = bw.team_battle_manager
	var inactive_ok: bool = (tbm != null and tbm.has_method("is_battle_active") and (not tbm.is_battle_active()))

	var ok: bool = finished_text_seen and tbm_log_seen and inactive_ok
	print("[AutoTest][TeamBattleUI] finished=", finished_text_seen, " tbm_log=", tbm_log_seen, " inactive=", inactive_ok, " ok=", ok)
	return ok
