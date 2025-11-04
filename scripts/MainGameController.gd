# MainGameController.gd
# 主游戏控制器 - 负责协调各个管理器和UI组件
class_name MainGameController
extends Node2D

# 管理器引用
var game_manager: GameManager
var loop_manager: LoopManager
var card_manager: CardManager
var hero_manager: HeroManager
var battle_manager: BattleManager

# UI引用
var battle_window: Control
var card_selection_window: Control
var game_over_window: Control
var start_button_proxy: Control

# 时间系统UI
var day_label
var step_progress_bar
var step_label_time

# 资源UI
var resources_container
var wood_label
var stone_label
var metal_label
var food_label
var spirit_label

var loop_label
var state_label

var start_button
var retreat_button
var pause_button

var level_label
var hp_label
var step_label

var log_text
var hand_container

# 卡牌UI
var hand_card_scenes: Array[Control] = []
var selected_card_index: int = -1

# 输入状态
var is_placing_card: bool = false
var hovered_tile_index: int = -1

# 战斗配置
var use_team_battle: bool = true  # 是否使用团队战斗

# 信号
signal game_started
signal game_paused
signal game_resumed

# 调试标志
var debug_mode: bool = false

# 防止重复连接的保护标记
var signals_connected: bool = false

func _init():
	print("=== MainGameController _init() called ===")
	print("*** INIT COMPLETE - WAITING FOR _ready() ***")

# 更稳健的无头模式检测（支持 Windows + --headless 参数）
func _is_headless_mode() -> bool:
	var name := String(DisplayServer.get_name()).to_lower()
	if name == "headless":
		return true
	var args: PackedStringArray = OS.get_cmdline_args()
	for a in args:
		if a == "--headless" or a == "headless":
			return true
	return OS.has_feature("headless")

func _ready():
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!! MAIN GAME CONTROLLER _ready() CALLED !!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("Main Game Controller initialized")
	
	print("About to call _setup_manager_references...")
	# 设置管理器和UI引用
	_setup_manager_references()
	print("_setup_manager_references completed")
	
	print("About to call _connect_manager_signals...")
	# 连接管理器信号
	_connect_manager_signals()
	print("_connect_manager_signals completed")

	# 连接UI信号并初始化UI（避免按钮未绑定与日志未更新）
	print("About to call _connect_ui_signals and _initialize_ui...")
	_connect_ui_signals()
	_initialize_ui()
	print("_connect_ui_signals and _initialize_ui completed")
	# 检查是否为无头模式（自动测试）
	if _is_headless_mode():
		print("[MainGameController] Headless mode detected, starting auto test")
		# 延迟启动自动测试，确保所有管理器都已初始化
		await get_tree().create_timer(0.5).timeout
		print("[MainGameController] Starting new loop...")
		game_manager.start_new_loop()
		print("[MainGameController] Starting hero movement...")
		loop_manager.start_hero_movement()
		
		# 再等待一段时间，然后检查战斗管理器状态
		await get_tree().create_timer(0.5).timeout
		print("[MainGameController] Checking battle manager state...")
		if battle_manager.get_battle_state() == BattleManager.BattleState.IDLE:
			print("[MainGameController] Battle manager is idle, injecting debug battle...")
			# 注入一个调试战斗
			var debug_enemy = {
				"name": "Debug Enemy",
				"type": "enemy",
				"hp": 50,
				"attack": 10,
				"defense": 5
			}
			_on_battle_started(debug_enemy)
		else:
			print("[MainGameController] Battle manager is not idle, state: ", battle_manager.get_battle_state())
		print("[MainGameController] Auto test logic completed")
	else:
		print("[MainGameController] Not in headless mode, skipping auto test")
	print("[MainGameController] Ready for user interaction")

func _connect_manager_signals():
	"""连接管理器信号（防重连）"""
	# 若已连接过一次，则直接跳过，避免多次调用导致的重复连接报错
	if signals_connected:
		print("[MainGameController] Signals already connected, skipping re-connect")
		return
	# GameManager信号
	if game_manager:
		if not game_manager.is_connected("game_state_changed", Callable(self, "_on_game_state_changed")):
			game_manager.connect("game_state_changed", Callable(self, "_on_game_state_changed"))
		if not game_manager.is_connected("resources_changed", Callable(self, "_on_resources_changed")):
			game_manager.connect("resources_changed", Callable(self, "_on_resources_changed"))
		if not game_manager.is_connected("loop_completed", Callable(self, "_on_loop_completed")):
			game_manager.connect("loop_completed", Callable(self, "_on_loop_completed"))
	
	# LoopManager信号
	if loop_manager:
		if not loop_manager.is_connected("hero_moved", Callable(self, "_on_hero_moved")):
			loop_manager.connect("hero_moved", Callable(self, "_on_hero_moved"))
		if not loop_manager.is_connected("battle_started", Callable(self, "_on_battle_started")):
			loop_manager.connect("battle_started", Callable(self, "_on_battle_started"))
		if not loop_manager.is_connected("loop_completed", Callable(self, "_on_loop_manager_loop_completed")):
			loop_manager.connect("loop_completed", Callable(self, "_on_loop_manager_loop_completed"))
		if not loop_manager.is_connected("step_count_updated", Callable(self, "_on_step_count_updated")):
			loop_manager.connect("step_count_updated", Callable(self, "_on_step_count_updated"))
		if not loop_manager.is_connected("day_changed", Callable(self, "_on_day_changed")):
			loop_manager.connect("day_changed", Callable(self, "_on_day_changed"))
		if not loop_manager.is_connected("monsters_spawned", Callable(self, "_on_monsters_spawned")):
			loop_manager.connect("monsters_spawned", Callable(self, "_on_monsters_spawned"))
	
	# CardManager信号
	# 使用字符串信号连接以避免属性访问错误
	if card_manager:
		if not card_manager.is_connected("hand_updated", Callable(self, "_on_hand_updated")):
			card_manager.connect("hand_updated", Callable(self, "_on_hand_updated"))
		if not card_manager.is_connected("card_placed", Callable(self, "_on_card_placed")):
			card_manager.connect("card_placed", Callable(self, "_on_card_placed"))
	
	# HeroManager信号
	if hero_manager:
		if not hero_manager.is_connected("hero_stats_changed", Callable(self, "_on_hero_stats_changed")):
			hero_manager.connect("hero_stats_changed", Callable(self, "_on_hero_stats_changed"))
		if not hero_manager.is_connected("hero_leveled_up", Callable(self, "_on_hero_leveled_up")):
			hero_manager.connect("hero_leveled_up", Callable(self, "_on_hero_leveled_up"))
		if not hero_manager.is_connected("experience_gained", Callable(self, "_on_experience_gained")):
			hero_manager.connect("experience_gained", Callable(self, "_on_experience_gained"))
	
	# BattleManager信号
	if battle_manager:
		if not battle_manager.is_connected("battle_started", Callable(self, "_on_battle_manager_battle_started")):
			battle_manager.connect("battle_started", Callable(self, "_on_battle_manager_battle_started"))
		if not battle_manager.is_connected("battle_ended", Callable(self, "_on_battle_ended")):
			battle_manager.connect("battle_ended", Callable(self, "_on_battle_ended"))
		if not battle_manager.is_connected("battle_log_updated", Callable(self, "_on_battle_log_updated")):
			battle_manager.connect("battle_log_updated", Callable(self, "_on_battle_log_updated"))
	
	# CardSelectionWindow信号
	print("[MainGameController] Connecting CardSelectionWindow signals...")
	print("[MainGameController] card_selection_window exists: ", card_selection_window != null)
	if card_selection_window:
		print("[MainGameController] card_selection_window node path: ", card_selection_window.get_path())
		print("[MainGameController] card_selection_window has card_selected signal: ", card_selection_window.has_signal("card_selected"))
		print("[MainGameController] card_selection_window has selection_closed signal: ", card_selection_window.has_signal("selection_closed"))
		
		# 连接card_selected信号
		if card_selection_window.has_signal("card_selected"):
			if not card_selection_window.is_connected("card_selected", Callable(self, "_on_card_selection_card_selected")):
				card_selection_window.connect("card_selected", Callable(self, "_on_card_selection_card_selected"))
				print("[MainGameController] ✓ card_selected signal connected successfully")
			else:
				print("[MainGameController] ⚠ card_selected signal already connected")
		else:
			print("[MainGameController] ✗ card_selected signal not found")
		
		# 连接selection_closed信号
		if card_selection_window.has_signal("selection_closed"):
			if not card_selection_window.is_connected("selection_closed", Callable(self, "_on_card_selection_closed")):
				card_selection_window.connect("selection_closed", Callable(self, "_on_card_selection_closed"))
				print("[MainGameController] ✓ selection_closed signal connected successfully")
			else:
				print("[MainGameController] ⚠ selection_closed signal already connected")
		else:
			print("[MainGameController] ✗ selection_closed signal not found")
		
		# 连接selection_restarted信号
		if card_selection_window.has_signal("selection_restarted"):
			if not card_selection_window.is_connected("selection_restarted", Callable(self, "_on_card_selection_restarted")):
				card_selection_window.connect("selection_restarted", Callable(self, "_on_card_selection_restarted"))
				print("[MainGameController] ✓ selection_restarted signal connected successfully")
			else:
				print("[MainGameController] ⚠ selection_restarted signal already connected")
		else:
			print("[MainGameController] ✗ selection_restarted signal not found")
	else:
		print("[MainGameController] ✗ card_selection_window is null - signals not connected!")
	# BattleManager 的伤害信号（防重连）
	if battle_manager and not battle_manager.is_connected("damage_dealt", Callable(self, "_on_damage_dealt")):
		battle_manager.connect("damage_dealt", Callable(self, "_on_damage_dealt"))
	
	# BattleWindow信号
	if battle_window:
		if battle_window.has_signal("battle_action_selected") and not battle_window.is_connected("battle_action_selected", Callable(self, "_on_battle_action_selected")):
			battle_window.connect("battle_action_selected", Callable(self, "_on_battle_action_selected"))
		if battle_window.has_signal("battle_window_closed") and not battle_window.is_connected("battle_window_closed", Callable(self, "_on_battle_window_closed")):
			battle_window.connect("battle_window_closed", Callable(self, "_on_battle_window_closed"))

	# 标记已连接，后续调用将被短路
	signals_connected = true

func _connect_ui_signals():
	"""连接UI信号"""
	# 场景文件中已有信号连接，这里防重连以避免 "Signal is already connected" 错误
	if start_button and not start_button.is_connected("pressed", Callable(self, "_on_start_button_pressed")):
		start_button.connect("pressed", Callable(self, "_on_start_button_pressed"))
	if retreat_button and not retreat_button.is_connected("pressed", Callable(self, "_on_retreat_button_pressed")):
		retreat_button.connect("pressed", Callable(self, "_on_retreat_button_pressed"))
	if pause_button and not pause_button.is_connected("pressed", Callable(self, "_on_pause_button_pressed")):
		pause_button.connect("pressed", Callable(self, "_on_pause_button_pressed"))
	
	# 连接GameOverWindow信号
	if game_over_window:
		if game_over_window.has_signal("restart_game") and not game_over_window.is_connected("restart_game", Callable(self, "_on_restart_game")):
			game_over_window.connect("restart_game", Callable(self, "_on_restart_game"))
		if game_over_window.has_signal("quit_game") and not game_over_window.is_connected("quit_game", Callable(self, "_on_quit_game")):
			game_over_window.connect("quit_game", Callable(self, "_on_quit_game"))

func _initialize_ui():
	"""初始化UI"""
	# 更新资源显示
	_update_resources_display()

	# 更新英雄信息
	_update_hero_display()

	# 更新时间系统显示
	_update_time_display()

	# 更新游戏状态
	_update_game_state_display()

	# 初始化战斗日志
	if log_text:
		log_text.text = "[color=gray]等待游戏开始...[/color]"

func _setup_manager_references():
	"""设置管理器之间的引用"""
	print("=== SETUP MANAGER REFERENCES START ===")
	print("=== SETUP MANAGER REFERENCES START ===")
	print("=== SETUP MANAGER REFERENCES START ===")
	print("[MainGameController] Setting up manager references...")
	print("[MainGameController] Current node name: ", name)
	print("[MainGameController] Current node children count: ", get_child_count())
	
	# 打印所有子节点
	for i in range(get_child_count()):
		var child = get_child(i)
		print("[MainGameController] Child ", i, ": ", child.name, " (", child.get_class(), ")")
	
	# 首先获取 CardSelectionWindow，确保在连接信号前就可用
	card_selection_window = get_node_or_null("UI/CardSelectionWindow")
	print("[MainGameController] CardSelectionWindow found: ", card_selection_window != null)
	
	# 获取 GameOverWindow
	game_over_window = get_node_or_null("UI/GameOverWindow")
	print("[MainGameController] GameOverWindow found: ", game_over_window != null)
	
	# 手动获取管理器节点引用
	game_manager = get_node_or_null("GameManager")
	print("[MainGameController] GameManager found: ", game_manager != null)
	if not game_manager:
		print("Warning: GameManager not found!")
	
	loop_manager = get_node_or_null("LoopManager")
	print("[MainGameController] LoopManager found: ", loop_manager != null)
	if not loop_manager:
		print("Warning: LoopManager not found!")
	
	card_manager = get_node_or_null("CardManager")
	print("[MainGameController] CardManager found: ", card_manager != null)
	if not card_manager:
		print("Warning: CardManager not found!")
	
	hero_manager = get_node_or_null("HeroManager")
	print("[MainGameController] HeroManager found: ", hero_manager != null)
	if not hero_manager:
		print("Warning: HeroManager not found!")
		# 创建默认的HeroManager如果没有找到
		hero_manager = preload("res://scripts/HeroManager.gd").new()
		add_child(hero_manager)
		print("Created default HeroManager")
	
	battle_manager = get_node_or_null("BattleManager")
	print("[MainGameController] BattleManager found: ", battle_manager != null)
	if not battle_manager:
		print("Warning: BattleManager not found!")
	
	# 手动获取UI节点引用
	day_label = get_node("UI/MainUI/TopPanel/TimeContainer/DayLabel")
	step_progress_bar = get_node("UI/MainUI/TopPanel/TimeContainer/StepProgressBar")
	step_label_time = get_node("UI/MainUI/TopPanel/TimeContainer/StepLabel")
	
	wood_label = get_node("UI/MainUI/TopPanel/ResourcesContainer/WoodLabel")
	stone_label = get_node("UI/MainUI/TopPanel/ResourcesContainer/StoneLabel")
	metal_label = get_node("UI/MainUI/TopPanel/ResourcesContainer/MetalLabel")
	food_label = get_node("UI/MainUI/TopPanel/ResourcesContainer/FoodLabel")
	spirit_label = get_node("UI/MainUI/TopPanel/ResourcesContainer/SpiritLabel")
	
	loop_label = get_node("UI/MainUI/BottomPanel/StatusContainer/LoopLabel")
	state_label = get_node("UI/MainUI/BottomPanel/StatusContainer/StateLabel")
	
	start_button = get_node("UI/MainUI/BottomPanel/ControlsContainer/StartButton")
	retreat_button = get_node("UI/MainUI/BottomPanel/ControlsContainer/RetreatButton")
	pause_button = get_node("UI/MainUI/BottomPanel/ControlsContainer/PauseButton")
	
	level_label = get_node("UI/MainUI/TopPanel/HeroPanel/HeroContainer/LevelLabel")
	hp_label = get_node("UI/MainUI/TopPanel/HeroPanel/HeroContainer/HPLabel")
	step_label = get_node("UI/MainUI/TopPanel/HeroPanel/HeroContainer/StepLabel")
	
	log_text = get_node("UI/MainUI/LogPanel/LogContainer/LogScrollContainer/LogText")
	hand_container = get_node_or_null("UI/MainUI/BottomPanel/HandPanel/HandContainer")

	# 直接从场景文件创建新的 BattleWindow 实例
	print("[MainGameController] Creating new BattleWindow instance from scene...")
	var bw_scene: PackedScene = preload("res://scenes/BattleWindow.tscn")
	battle_window = bw_scene.instantiate()
	battle_window.name = "BattleWindow"
	
	print("[MainGameController] BattleWindow instantiated, class: ", battle_window.get_class())
	print("[MainGameController] BattleWindow script: ", battle_window.get_script())
	print("[MainGameController] BattleWindow has _ready: ", battle_window.has_method("_ready"))
	
	# 将新实例添加到UI层
	var ui_layer = get_node("UI")
	# 移除旧的 BattleWindow（如果存在）
	if ui_layer.has_node("BattleWindow"):
		var old_bw = ui_layer.get_node("BattleWindow")
		ui_layer.remove_child(old_bw)
		old_bw.queue_free()
	
	print("[MainGameController] Adding BattleWindow to UI layer...")
	ui_layer.add_child(battle_window)
	print("[MainGameController] BattleWindow added to scene tree")
	
	# 等待 BattleWindow 的 _ready 函数完成
	await get_tree().process_frame
	print("[MainGameController] After process_frame, BattleWindow script: ", battle_window.get_script())
	
	# 验证方法是否可用
	print("[MainGameController] BattleWindow has show_battle: ", battle_window.has_method("show_battle"))
	print("[MainGameController] BattleWindow script: ", battle_window.get_script())
	
	# 连接 BattleWindow 信号
	if battle_window:
		if battle_window.has_signal("battle_action_selected") and not battle_window.is_connected("battle_action_selected", Callable(self, "_on_battle_action_selected")):
			battle_window.connect("battle_action_selected", Callable(self, "_on_battle_action_selected"))
		if battle_window.has_signal("battle_window_closed") and not battle_window.is_connected("battle_window_closed", Callable(self, "_on_battle_window_closed")):
			battle_window.connect("battle_window_closed", Callable(self, "_on_battle_window_closed"))
		print("[MainGameController] BattleWindow recreated and signals connected")
	
	# 调试输出节点获取情况
	print("[MainGameController] battle_window created: ", battle_window != null)
	print("[MainGameController] card_selection_window found: ", card_selection_window != null)
	
	# 验证 BattleWindow 方法
	if battle_window:
		print("[MainGameController] BattleWindow has show_team_battle: ", battle_window.has_method("show_team_battle"))
		print("[MainGameController] BattleWindow has show_battle: ", battle_window.has_method("show_battle"))
		print("[MainGameController] BattleWindow script: ", battle_window.get_script())
		print("[MainGameController] BattleWindow class: ", battle_window.get_class())
		
		# 验证方法是否可用
		print("[MainGameController] BattleWindow has show_team_battle: ", battle_window.has_method("show_team_battle"))
		print("[MainGameController] BattleWindow has show_battle: ", battle_window.has_method("show_battle"))
	
	print("[MainGameController] All node references set up successfully")

	# 设置BattleManager的引用
	battle_manager.hero_manager = hero_manager
	battle_manager.loop_manager = loop_manager
	battle_manager.battle_window = battle_window
	
	# 连接BattleManager的battle_ended信号到LoopManager
	# 这样确保LoopManager的on_battle_ended函数会被调用
	battle_manager.connect("battle_ended", Callable(loop_manager, "on_battle_ended"))
	print("[MainGameController] Connected BattleManager.battle_ended to LoopManager.on_battle_ended")

func _create_battle_window() -> void:
	"""创建或重新创建 BattleWindow 并连接信号"""
	var bw_scene: PackedScene = preload("res://scenes/BattleWindow.tscn")
	var ui_layer = get_node("UI")
	# 移除旧的 BattleWindow（如果存在）
	if ui_layer.has_node("BattleWindow"):
		var old_bw = ui_layer.get_node("BattleWindow")
		ui_layer.remove_child(old_bw)
		old_bw.queue_free()
	
	# 创建并添加新的 BattleWindow
	battle_window = bw_scene.instantiate()
	battle_window.name = "BattleWindow"
	# 强制绑定脚本，避免场景脚本未加载导致方法不可用
	var bw_script: Script = preload("res://scripts/BattleWindow.gd")
	if bw_script:
		battle_window.set_script(bw_script)
	ui_layer.add_child(battle_window)
	
	# 等待一帧以保证 _ready 执行
	await get_tree().process_frame
	
	# 强制调用 _ready 以确保脚本正确初始化（防御性）
	if battle_window.has_method("_ready"):
		battle_window._ready()

	# 额外诊断：验证关键方法是否可用
	print("[MainGameController] BattleWindow has show_team_battle: ", battle_window.has_method("show_team_battle"))
	print("[MainGameController] BattleWindow has show_battle: ", battle_window.has_method("show_battle"))
	print("[MainGameController] BattleWindow script: ", battle_window.get_script())
	
	# 连接 BattleWindow 信号
	if battle_window:
		if battle_window.has_signal("battle_action_selected") and not battle_window.is_connected("battle_action_selected", Callable(self, "_on_battle_action_selected")):
			battle_window.connect("battle_action_selected", Callable(self, "_on_battle_action_selected"))
		if battle_window.has_signal("battle_window_closed") and not battle_window.is_connected("battle_window_closed", Callable(self, "_on_battle_window_closed")):
			battle_window.connect("battle_window_closed", Callable(self, "_on_battle_window_closed"))
	
	print("[MainGameController] _create_battle_window() completed; battle_window ready")

func _on_game_state_changed(new_state: GameManager.GameState):
	"""游戏状态改变"""
	_update_game_state_display()
	
	# 使用GameManager.GameState枚举值进行匹配
	match new_state:
		GameManager.GameState.IN_LOOP:
			if start_button:
				start_button.text = "循环中..."
				start_button.disabled = true
			if retreat_button:
				retreat_button.disabled = false
			# 恢复移动：从暂停返回到循环时确保英雄继续前进
			if loop_manager and not get_tree().paused:
				if loop_manager.has_method("start_hero_movement") and not loop_manager.is_moving and (not loop_manager.selection_active):
					loop_manager.start_hero_movement()
					_add_log("[color=cyan]游戏继续[/color]")
		GameManager.GameState.SECT_MANAGEMENT:
			if start_button:
				start_button.text = "开始循环"
				start_button.disabled = false
			if retreat_button:
				retreat_button.disabled = true
		GameManager.GameState.PAUSED:
			if pause_button:
				pause_button.text = "继续"
		_:
			if pause_button:
				pause_button.text = "暂停"

func _on_resources_changed(resources: Dictionary):
	"""资源改变"""
	_update_resources_display()

func _on_loop_completed(loop_number: int):
	"""循环完成"""
	if loop_label:
		loop_label.text = "循环: " + str(loop_number)
	_add_log("[color=green]完成第 " + str(loop_number) + " 次循环！[/color]")

func _on_loop_manager_loop_completed():
	"""循环管理器循环完成"""
	# 应用循环完成时的卡牌效果
	var path_length = loop_manager.get_path_length()
	for tile_index in range(path_length):
		var card_data = loop_manager.get_card_at_tile(tile_index)
		if card_data.size() > 0:
			card_manager.apply_card_effects(card_data, "on_loop_complete")

func _on_hero_moved(new_position: Vector2):
	"""英雄移动"""
	# 可以在这里添加视觉效果
	pass

func _on_step_count_updated(step_count: int):
	"""步数更新"""
	if step_label:
		step_label.text = "步数: " + str(step_count)

	# 更新时间系统UI
	_update_time_display()

	# 写入循环移动日志（与卡牌/战斗日志同路径）
	_add_log("[移动] 英雄前进，步数: " + str(step_count))

func _on_day_changed(day: int):
	"""天数改变"""
	_add_log("[color=yellow]第" + str(day) + "天开始！[/color]")
	_update_time_display()
	
	# 应用每日地形效果
	if hero_manager:
		hero_manager.apply_daily_terrain_effects()
	
	# 暂停游戏移动
	if loop_manager:
		loop_manager.stop_hero_movement()
		# 标记选择窗口活动，防止继续移动或触发战斗
		if loop_manager.has_method("set_selection_active"):
			loop_manager.set_selection_active(true)
	
	# 弹出卡牌选择窗口
	if card_selection_window:
		card_selection_window.show_card_selection(day)

func _on_monsters_spawned(monster_positions: Array):
	"""怪物生成"""
	_add_log("[color=orange]新的怪物出现在路径上！[/color]")
	_add_log("怪物数量: " + str(monster_positions.size()))

func _on_battle_started(enemy_data: Dictionary):
	"""战斗开始（来自LoopManager）"""
	print("[MainGameController] *** _on_battle_started CALLED *** enemy=", enemy_data)
	print("[MainGameController] use_team_battle=", use_team_battle)
	print("[MainGameController] battle_window available=", battle_window != null)
	print("[MainGameController] battle_manager available=", battle_manager != null)
	
	# 显示简单的战斗信息
	_show_simple_battle_info(enemy_data)
	
	# 仅启用队伍整体战斗模式
	if not battle_window or not battle_window.has_method("show_team_battle"):
		print("[MainGameController] Recreating BattleWindow for team battle...")
		await _create_battle_window()
	
	if battle_window and battle_window.has_method("show_team_battle"):
		print("[MainGameController] Starting team battle via BattleWindow.show_team_battle")
		var hero_stats = {}
		if hero_manager and hero_manager.has_method("get_hero_stats"):
			hero_stats = hero_manager.get_hero_stats()
		var hero_roster := _build_team_roster_from_hero_stats(hero_stats)
		var enemy_roster := _build_team_roster_from_enemy_data(enemy_data)
		battle_window.show_team_battle(hero_roster, enemy_roster)
		return
	else:
		# 尝试回退：强制绑定脚本后再次调用
		print("[MainGameController] BattleWindow缺少show_team_battle，尝试强制绑定脚本后重试")
		var bw_script: Script = preload("res://scripts/BattleWindow.gd")
		if battle_window and bw_script:
			battle_window.set_script(bw_script)
			await get_tree().process_frame
			if battle_window.has_method("_ready"):
				battle_window._ready()
			print("[MainGameController] Recheck show_team_battle after script bind:", battle_window.has_method("show_team_battle"))
			if battle_window.has_method("show_team_battle"):
				var hero_stats = {}
				if hero_manager and hero_manager.has_method("get_hero_stats"):
					hero_stats = hero_manager.get_hero_stats()
				var hero_roster := _build_team_roster_from_hero_stats(hero_stats)
				var enemy_roster := _build_team_roster_from_enemy_data(enemy_data)
				battle_window.call_deferred("show_team_battle", hero_roster, enemy_roster)
				return
		# 最终失败才报错
		push_error("BattleWindow 不可用或缺少 show_team_battle 方法，无法开始队伍战斗")
		return
	
	# 已移除 1v1 回退逻辑（统一队伍战斗模式）

# 组装队伍：基于英雄属性构造3人小队
func _build_team_roster_from_hero_stats(hs: Dictionary) -> Array:
	var roster: Array = []
	var h0 := {
		"name": String(hs.get("name", "英雄")),
		"current_hp": int(hs.get("current_hp", hs.get("max_hp", 100))),
		"max_hp": int(hs.get("max_hp", hs.get("current_hp", 100))),
		"attack": int(hs.get("attack", 12)),
		"defense": int(hs.get("defense", 4)),
		"skills": ["power_strike"],
		"passives": ["tough"],
		"status_effects": []
	}
	var h1 := {
		"name": "战友A",
		"current_hp": max(24, int(hs.get("current_hp", 100) * 0.7)),
		"max_hp": max(24, int(hs.get("max_hp", 100) * 0.7)),
		"attack": int(hs.get("attack", 12)) - 1,
		"defense": int(hs.get("defense", 4)),
		"skills": ["multi_strike"],
		"passives": ["lifesteal"],
		"status_effects": []
	}
	var h2 := {
		"name": "战友B",
		"current_hp": max(20, int(hs.get("current_hp", 100) * 0.6)),
		"max_hp": max(20, int(hs.get("max_hp", 100) * 0.6)),
		"attack": int(hs.get("attack", 12)) + 1,
		"defense": int(hs.get("defense", 4)) - 1,
		"skills": ["power_strike"],
		"passives": ["berserk"],
		"status_effects": []
	}
	roster.append(h0)
	roster.append(h1)
	roster.append(h2)
	return roster

# 组装敌人队伍：基于敌人数据构造3人小队
func _build_team_roster_from_enemy_data(ed: Dictionary) -> Array:
	var base := {
		"name": String(ed.get("name", "敌人")),
		"current_hp": int(ed.get("hp", 30)),
		"max_hp": int(ed.get("hp", 30)),
		"attack": int(ed.get("attack", 8)),
		"defense": int(ed.get("defense", 3)),
		"skills": [],
		"passives": [],
		"status_effects": []
	}
	var e1 := base.duplicate(true)
	e1.name = String(base.name) + "·甲"
	var e2 := base.duplicate(true)
	e2.name = String(base.name) + "·乙"
	var e0 := base.duplicate(true)
	return [e0, e1, e2]
func _on_battle_ended(victory: bool, rewards: Dictionary):
	"""战斗结束"""
	print("[MainGameController] _on_battle_ended called with victory: ", victory)
	print("[MainGameController] Current loop_manager.is_moving: ", loop_manager.is_moving)
	if victory:
		_add_log("[color=green]战斗胜利！[/color]")
		if rewards.has("experience"):
			_add_log("获得经验: " + str(rewards.experience))
	else:
		_add_log("[color=red]战斗失败！[/color]")
		# 处理英雄死亡
		game_manager.hero_death()
	
	# 延迟隐藏战斗窗口，让玩家看到结果
	await get_tree().create_timer(2.0).timeout
	print("[MainGameController] Attempting to hide battle window...")
	if battle_window and battle_window.has_method("hide_battle"):
		print("[MainGameController] Calling battle_window.hide_battle()")
		battle_window.hide_battle()
	else:
		print("[MainGameController] Battle window not available or hide_battle method missing")
		# 即使战斗窗口不可用，也要通知 LoopManager 恢复移动
		print("[MainGameController] Directly calling loop_manager.on_battle_window_closed()")
		loop_manager.on_battle_window_closed()
	
	print("[MainGameController] _on_battle_ended finished, loop_manager.is_moving: ", loop_manager.is_moving)

func _on_battle_log_updated(message: String):
	"""战斗日志更新"""
	_add_log(message)

func _on_hand_updated(new_hand: Array):
	"""手牌更新"""
	pass

func _on_card_placed(card_data: Dictionary, position: Vector2):
	"""卡牌放置"""
	_add_log("放置卡牌: " + card_data.get("name", "UNKNOWN"))
	# 应用放置时效果
	card_manager.apply_card_effects(card_data, "on_place")

func _on_hero_stats_changed(new_stats: Dictionary):
	"""英雄属性改变"""
	_update_hero_display()

func _on_hero_leveled_up(new_level: int):
	"""英雄升级"""
	_add_log("[color=yellow]英雄升级到 " + str(new_level) + " 级！[/color]")
	_update_hero_display()

func _on_experience_gained(amount: int):
	"""获得经验"""
	_update_hero_display()

func _on_start_button_pressed():
	"""开始按钮点击"""
	print("[MainGameController] _on_start_button_pressed called!")
	print("[MainGameController] game_manager exists: ", game_manager != null)
	print("[MainGameController] loop_manager exists: ", loop_manager != null)
	
	# 防御性处理：确保不在暂停状态，避免按钮点击或移动被阻断
	get_tree().paused = false
	
	if game_manager and game_manager.has_method("start_new_loop"):
		print("[MainGameController] Calling game_manager.start_new_loop()")
		game_manager.start_new_loop()
		print("[MainGameController] Calling loop_manager.start_hero_movement()")
		loop_manager.start_hero_movement()
		_add_log("[color=cyan]开始新的循环冒险！[/color]")
		print("[MainGameController] Start button processing completed successfully!")
	else:
		print("[MainGameController] ERROR: game_manager.start_new_loop method not found or game_manager is null!")
		if game_manager:
			print("[MainGameController] Available game_manager methods: ", game_manager.get_method_list())
		else:
			print("[MainGameController] game_manager is null!")

func _on_retreat_button_pressed():
	"""撤退按钮点击"""
	print("[MainGameController] _on_retreat_button_pressed called!")
	if game_manager.has_method("retreat_from_loop"):
		loop_manager.stop_hero_movement()
		game_manager.retreat_from_loop()
		_add_log("[color=orange]从循环中撤退[/color]")

func _on_pause_button_pressed():
	"""暂停按钮点击"""
	game_manager.toggle_pause()

func _update_resources_display():
	"""更新资源显示"""
	if game_manager:
		if wood_label:
			wood_label.text = "木材: " + str(game_manager.get_resource_amount("wood"))
		if stone_label:
			stone_label.text = "石头: " + str(game_manager.get_resource_amount("stone"))
		if metal_label:
			metal_label.text = "金属: " + str(game_manager.get_resource_amount("metal"))
		if food_label:
			food_label.text = "食物: " + str(game_manager.get_resource_amount("food"))
		if spirit_label:
			spirit_label.text = "灵石: " + str(game_manager.get_resource_amount("spirit_stones"))

func _update_hero_display():
	"""更新英雄信息显示"""
	if hero_manager:
		var stats = hero_manager.get_stats()
		if level_label:
			level_label.text = "等级: " + str(hero_manager.level)
		if hp_label:
			hp_label.text = "生命值: " + str(stats.current_hp) + "/" + str(stats.max_hp)
	
	# 更新步数显示
	if loop_manager and step_label:
		if loop_manager.has_method("get_step_count"):
			step_label.text = "步数: " + str(loop_manager.get_step_count())
		else:
			step_label.text = "步数: N/A"

func _update_game_state_display():
	"""更新游戏状态显示"""
	if game_manager:
		var state_text = ""
		match game_manager.current_state:
			1: # IN_LOOP
				state_text = "循环中"
			2: # SECT_MANAGEMENT
				state_text = "宗门管理"
			3: # PAUSED
				state_text = "已暂停"
			_:
				state_text = "未知状态"
		
		if state_label:
			state_label.text = "状态: " + state_text
		if loop_label:
			loop_label.text = "循环: " + str(game_manager.loop_number)

func _update_time_display():
	"""更新时间系统显示"""
	if loop_manager:
		var current_day := 1
		var steps_in_day := 0
		var steps_per_day := 20
		if loop_manager.has_method("get_time_info"):
			var time_info: Dictionary = loop_manager.get_time_info()
			current_day = int(time_info.get("current_day", current_day))
			steps_in_day = int(time_info.get("steps_in_current_day", steps_in_day))
			steps_per_day = int(time_info.get("steps_per_day", steps_per_day))
		
		# 更新天数标签
		if day_label:
			day_label.text = "第" + str(current_day) + "天"
		
		# 更新步数进度条
		if step_progress_bar:
			step_progress_bar.value = steps_in_day
			step_progress_bar.max_value = steps_per_day
		
		# 更新步数标签
		if step_label_time:
			step_label_time.text = "步数: " + str(steps_in_day) + "/" + str(steps_per_day)

func _update_hand_display():
	"""更新手牌显示"""
	# 清除现有的手牌UI
	for card_ui in hand_card_scenes:
		card_ui.queue_free()
	hand_card_scenes.clear()
	
	# 创建新的手牌UI
	if card_manager:
		var hand = card_manager.get_hand()
		for i in range(hand.size()):
			var card_data = hand[i]
			var card_ui = _create_card_ui(card_data, i)
			if hand_container:
				hand_container.add_child(card_ui)
			hand_card_scenes.append(card_ui)

func _create_card_ui(card_data: Dictionary, index: int) -> Control:
	"""创建卡牌UI"""
	var card_button = Button.new()
	card_button.custom_minimum_size = Vector2(80, 100)
	card_button.text = card_data.get("name", "UNKNOWN")
	card_button.tooltip_text = card_data.get("description", "")
	
	# 根据卡牌类型设置颜色
	# 根据卡牌类型设置颜色（使用字符串匹配）
	match card_data.get("type", ""):
		"enemy":
			card_button.modulate = Color.RED
		"terrain":
			card_button.modulate = Color.GREEN
		"building":
			card_button.modulate = Color.BLUE
		"special":
			card_button.modulate = Color.PURPLE
	
	# 连接点击信号
	card_button.pressed.connect(_on_card_selected.bind(index))
	
	return card_button

func _on_card_selected(card_index: int):
	"""卡牌被选中"""
	selected_card_index = card_index
	is_placing_card = true
	
	# 高亮选中的卡牌
	for i in range(hand_card_scenes.size()):
		if i == card_index:
			hand_card_scenes[i].modulate.a = 0.7
		else:
			hand_card_scenes[i].modulate.a = 1.0
	
	var card_data = card_manager.get_hand()[card_index]
	_add_log("选择卡牌: " + card_data.get("name", "UNKNOWN") + " (点击循环路径放置)")

func _input(event):
	"""处理输入"""
	# 添加测试快捷键
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F9:  # F9键触发Game Over测试
			print("[MainGameController] F9 pressed - Testing Game Over...")
			if game_manager:
				game_manager.test_game_over()
			return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and is_placing_card:
			_try_place_card_at_mouse(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if selected_terrain_card.size() > 0:
				_cancel_terrain_card_placement()
			else:
				_cancel_card_placement()

func _try_place_card_at_mouse(mouse_pos: Vector2):
	"""尝试在鼠标位置放置卡牌"""
	# 检查是否是地形卡牌放置模式
	if selected_terrain_card.size() > 0:
		_try_place_terrain_card_at_mouse(mouse_pos)
		return
	
	if selected_card_index < 0:
		return
	
	# 将屏幕坐标转换为世界坐标
	var world_pos = get_global_mouse_position()
	
	# 找到最近的瓦片
	var closest_tile = _find_closest_tile(world_pos)
	
	if closest_tile >= 0:
		# 尝试放置卡牌
		if card_manager.place_card(selected_card_index, closest_tile, loop_manager):
			_cancel_card_placement()
		else:
			_add_log("[color=red]无法在此位置放置卡牌[/color]")

func _try_place_terrain_card_at_mouse(mouse_pos: Vector2):
	"""尝试在鼠标位置放置地形卡牌"""
	# 将屏幕坐标转换为世界坐标
	var world_pos = get_global_mouse_position()
	
	# 找到最近的网格位置
	var grid_pos = loop_manager.find_closest_grid_position(world_pos)
	
	# 检查网格位置是否有效且可以放置地形
	if loop_manager.can_place_terrain_at_grid_position(grid_pos):
		# 放置地形卡牌
		if loop_manager.place_terrain_card_at_grid_position(grid_pos, selected_terrain_card):
			# 应用地形卡牌效果到英雄
			hero_manager.add_terrain_card(selected_terrain_card)
			
			_add_log("[color=green]成功放置地形卡牌：" + String(selected_terrain_card.get("name", "UNKNOWN")) + "[/color]")
			
			# 清除放置状态
			is_placing_card = false
			selected_terrain_card.clear()
			
			# 移除预览精灵
			_remove_terrain_card_preview()
			
			# 隐藏可放置区域高亮
			loop_manager.hide_placeable_highlights()
			
			# 在连续选择期间保持暂停，不恢复移动，也不手动关闭选择窗口
			if card_selection_window:
				if DisplayServer.get_name() != "headless":
					card_selection_window.continue_selection()
		else:
			_add_log("[color=red]放置失败[/color]")
	else:
		_add_log("[color=red]此位置无法放置地形卡牌（可能是循环路径或已有地形）[/color]")

func _find_closest_tile(world_pos: Vector2) -> int:
	"""找到最接近世界坐标的瓦片索引"""
	var closest_index = -1
	var closest_distance = 999999.0
	var path_length = loop_manager.get_path_length()
	
	for i in range(path_length):
		var tile_pos = loop_manager.get_tile_position(i)
		var distance = world_pos.distance_to(tile_pos)
		
		if distance < closest_distance and distance < 50.0:  # 50像素内才算有效
			closest_distance = distance
			closest_index = i
	
	return closest_index

func _cancel_card_placement():
	"""取消卡牌放置"""
	is_placing_card = false
	selected_card_index = -1
	
	# 恢复所有卡牌的透明度
	for card_ui in hand_card_scenes:
		card_ui.modulate.a = 1.0
	
	_add_log("取消卡牌放置")

func _cancel_terrain_card_placement():
	"""取消地形卡牌放置"""
	is_placing_card = false
	selected_terrain_card.clear()
	
	# 移除预览精灵
	_remove_terrain_card_preview()
	
	# 隐藏可放置区域高亮
	loop_manager.hide_placeable_highlights()
	
	# 仅取消当前放置，保持选择活动以继续选择，不恢复移动
	_add_log("[color=gray]取消地形卡牌放置[/color]")

func _add_log(message: String):
	"""添加日志消息"""
	if log_text:
		log_text.text += "\n" + message
		
		# 限制日志长度
		var lines = log_text.text.split("\n")
		if lines.size() > 50:
			lines = lines.slice(-50)
			log_text.text = "\n".join(lines)
		
		# 自动滚动到底部
		var scroll_container = log_text.get_parent()
		if scroll_container:
			scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _show_simple_battle_info(enemy_data: Dictionary):
	"""显示简单的战斗信息"""
	_add_log("[color=red]战斗开始！[/color]")
	_add_log("敌人: " + enemy_data.get("name", "未知敌人"))
	_add_log("敌人血量: " + str(enemy_data.get("hp", 0)))
	_add_log("敌人攻击: " + str(enemy_data.get("attack", 0)))
	_add_log("敌人防御: " + str(enemy_data.get("defense", 0)))
	
	if hero_manager:
		var hero_stats = hero_manager.get_stats()
		_add_log("英雄血量: " + str(hero_stats.current_hp) + "/" + str(hero_stats.max_hp))
		_add_log("英雄攻击: " + str(hero_stats.attack))
		_add_log("英雄防御: " + str(hero_stats.get("defense", 0)))
	
	_add_log("[color=yellow]战斗进行中...[/color]")

func _draw():
	"""绘制调试信息"""
	if is_placing_card and selected_card_index >= 0:
		# 绘制放置预览
		var mouse_pos = get_global_mouse_position()
		var closest_tile = _find_closest_tile(mouse_pos)
		
		if closest_tile >= 0:
			var tile_pos = loop_manager.get_tile_position(closest_tile)
			draw_circle(tile_pos, 20, Color.YELLOW)

# 新增的战斗窗口相关信号处理函数
func _on_damage_dealt(attacker: String, target: String, damage: int):
	"""伤害造成时的处理"""
	# 在战斗窗口中显示伤害效果
	if battle_window and battle_window.has_method("show_damage_effect"):
		battle_window.show_damage_effect(target, damage)
	
	# 更新战斗窗口中的状态显示
	if target == "Hero":
		if battle_window and battle_window.has_method("update_hero_stats"):
			battle_window.update_hero_stats(hero_manager.get_stats())
	else:
		if battle_window and battle_window.has_method("update_enemy_stats"):
			battle_window.update_enemy_stats(battle_manager.get_enemy_battle_data())

func _on_battle_action_selected(action: String):
	"""战斗动作选择处理"""
	# 这里可以处理手动战斗的逻辑
	# 目前游戏是自动战斗，所以暂时不需要实现
	print("Battle action selected: ", action)

func _on_battle_window_closed():
	"""战斗窗口关闭处理"""
	print("[MainGameController] Battle window closed signal received")
	# 通知LoopManager战斗窗口已关闭，可以恢复移动
	loop_manager.on_battle_window_closed()

# 删除重复的_process函数定义

# 卡牌选择窗口信号处理函数
var selected_terrain_card: Dictionary = {}  # 存储选中的地形卡牌
var terrain_card_preview_sprite: Sprite2D = null  # 地形卡牌预览精灵
var terrain_card_preview_label: Label = null  # 地形卡牌预览文字标签

func _on_card_selection_card_selected(card_data: Dictionary):
	"""卡牌选择窗口中卡牌选择后的处理"""
	print("[MainGameController] ========== _on_card_selection_card_selected START ==========")
	print("[MainGameController] Signal received! Card data: ", card_data)
	print("[MainGameController] Card name: ", card_data.get("name", "UNKNOWN"))
	print("[MainGameController] Card type: ", card_data.get("type", "UNKNOWN"))
	print("[MainGameController] Current is_placing_card state: ", is_placing_card)
	print("[MainGameController] Current selected_terrain_card: ", selected_terrain_card)
	
	_add_log("[color=cyan]选择了卡牌：" + card_data.get("name", "未知卡牌") + "[/color]")

	# 存储选中的卡牌数据
	selected_terrain_card = card_data
	print("[MainGameController] ✓ Stored selected_terrain_card: ", selected_terrain_card.get("name", "UNKNOWN"))

	# 在无头模式下自动放置卡牌
	var is_headless := _is_headless_mode()
	print("[MainGameController] Headless mode: ", is_headless)
	if is_headless:
		var ctype = card_data.get("type", null)
		var is_terrain = false
		if typeof(ctype) == TYPE_STRING:
			is_terrain = (ctype == "terrain")
		elif typeof(ctype) == TYPE_INT:
			is_terrain = (ctype == 1)
		if is_terrain:
			print("[MainGameController] Headless mode detected, auto-placing terrain card...")
			_auto_place_terrain_card()
			print("[MainGameController] Auto-place terrain card completed")
		else:
			print("[MainGameController] Headless mode: non-terrain card selected, skipping auto-placement")
			if loop_manager and loop_manager.has_method("set_selection_active"):
				loop_manager.set_selection_active(true)
			if loop_manager and loop_manager.is_moving:
				loop_manager.pause_hero_movement()
			if card_selection_window:
				card_selection_window.continue_selection()
		print("[MainGameController] ========== _on_card_selection_card_selected END (headless) ==========")
		return
	
	print("[MainGameController] Non-headless mode - entering placement mode...")
	
	# 开始拖拽放置模式
	is_placing_card = true
	selected_card_index = 0  # 临时索引
	print("[MainGameController] ✓ Set is_placing_card = ", is_placing_card)
	print("[MainGameController] ✓ Set selected_card_index = ", selected_card_index)
	
	# 创建地形卡牌预览精灵
	print("[MainGameController] Creating terrain card preview...")
	_create_terrain_card_preview()
	print("[MainGameController] ✓ Terrain card preview created")
	
	# 显示可放置区域高亮
	print("[MainGameController] Showing placeable highlights...")
	if loop_manager and loop_manager.has_method("show_placeable_highlights"):
		loop_manager.show_placeable_highlights()
		print("[MainGameController] ✓ Placeable highlights shown")
	else:
		print("[MainGameController] ✗ loop_manager or show_placeable_highlights method not available")
	
	# 显示提示信息
	_add_log("[color=yellow]请在绿色高亮区域放置地形卡牌[/color]")
	_add_log("[color=gray]左键点击空地放置，右键取消[/color]")
	
	print("[MainGameController] ✓ Placement mode setup completed")
	print("[MainGameController] Final is_placing_card state: ", is_placing_card)
	print("[MainGameController] ========== _on_card_selection_card_selected END (normal) ==========")
	
	# 保持游戏暂停状态，不恢复移动
	# 游戏将在玩家放置卡牌或取消放置后才恢复移动

func _on_card_selection_closed():
	"""卡牌选择窗口关闭处理"""
	_add_log("[color=gray]卡牌选择窗口已关闭[/color]")
	
	# 如果正在放置地形卡牌，不要重复取消（避免递归调用）
	# 地形卡牌的取消逻辑已经在_cancel_terrain_card_placement中处理
	if is_placing_card and selected_terrain_card.size() > 0:
		# 只清理状态，不重复发送信号
		is_placing_card = false
		selected_terrain_card.clear()
		_remove_terrain_card_preview()
	elif is_placing_card:
		# 处理非地形卡牌的取消
		_cancel_card_placement()
	
	# 隐藏可放置区域高亮
	loop_manager.hide_placeable_highlights()
	
	# 解除选择活动暂停
	if loop_manager and loop_manager.has_method("set_selection_active"):
		loop_manager.set_selection_active(false)
	
	# 恢复游戏移动
	if loop_manager and not loop_manager.is_moving:
		loop_manager.resume_hero_movement()
		_add_log("[color=cyan]游戏继续[/color]")

func _on_card_selection_restarted():
	"""卡牌选择重新开始处理"""
	print("[MainGameController] _on_card_selection_restarted called")
	_add_log("[color=cyan]继续选择卡牌...[/color]")
	
	# 设置选择活动状态来暂停英雄移动
	if loop_manager and loop_manager.has_method("set_selection_active"):
		loop_manager.set_selection_active(true)
		print("[MainGameController] ✓ selection_active set to true for continued selection")
	
	# 暂停英雄移动
	if loop_manager and loop_manager.is_moving:
		loop_manager.pause_hero_movement()
		_add_log("[color=yellow]英雄移动已暂停，等待选择卡牌[/color]")

func _create_terrain_card_preview():
	"""创建地形卡牌预览精灵"""
	print("[MainGameController] _create_terrain_card_preview called")
	print("[MainGameController] selected_terrain_card: ", selected_terrain_card)
	print("[MainGameController] loop_manager exists: ", loop_manager != null)
	
	if terrain_card_preview_sprite:
		print("[MainGameController] Removing existing preview sprite")
		_remove_terrain_card_preview()
	
	if not loop_manager:
		print("[MainGameController] ✗ loop_manager is null, cannot create preview")
		return
	
	if not loop_manager.has_method("_get_actual_tile_size"):
		print("[MainGameController] ✗ loop_manager missing _get_actual_tile_size method")
		return
	
	# 创建地形卡牌预览精灵
	terrain_card_preview_sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	# 使用LoopManager的实际瓦片大小
	var size = int(loop_manager._get_actual_tile_size())
	print("[MainGameController] Tile size: ", size)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# 根据地形类型设置颜色
	var id := String(selected_terrain_card.get("id", ""))
	var color: Color
	match id:
		"bamboo_forest":
			color = Color.GREEN
		"mountain_peak":
			color = Color.GRAY
		"river":
			color = Color.BLUE
		"rock":
			color = Color.DARK_GRAY
		"forest":
			color = Color.FOREST_GREEN
		"meadow":
			color = Color.YELLOW_GREEN
		"old_meadow":
			color = Color.OLIVE
		_:
			color = Color.WHITE
	
	# 创建半透明的方形预览（匹配网格系统）
	for x in range(size):
		for y in range(size):
			# 边框
			if x == 0 or x == size-1 or y == 0 or y == size-1:
				image.set_pixel(x, y, Color.BLACK)
			# 内部填充
			else:
				image.set_pixel(x, y, Color(color.r, color.g, color.b, 0.6))
	
	texture.set_image(image)
	terrain_card_preview_sprite.texture = texture
	terrain_card_preview_sprite.z_index = 1000  # 确保在最上层显示
	
	# 添加到场景
	add_child(terrain_card_preview_sprite)
	
	# 创建文字标签显示卡牌名字的首字
	terrain_card_preview_label = Label.new()
	var card_name := String(selected_terrain_card.get("name", ""))
	terrain_card_preview_label.text = card_name.substr(0, 1)
	terrain_card_preview_label.add_theme_font_size_override("font_size", 24)
	terrain_card_preview_label.add_theme_color_override("font_color", Color.WHITE)
	terrain_card_preview_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	terrain_card_preview_label.add_theme_constant_override("shadow_offset_x", 2)
	terrain_card_preview_label.add_theme_constant_override("shadow_offset_y", 2)
	terrain_card_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	terrain_card_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	terrain_card_preview_label.z_index = 1001  # 确保文字在精灵之上
	
	# 设置标签大小与瓦片大小一致
	terrain_card_preview_label.custom_minimum_size = Vector2(size, size)
	terrain_card_preview_label.size = Vector2(size, size)
	
	# 将标签作为精灵的子节点，这样它们会一起移动
	terrain_card_preview_sprite.add_child(terrain_card_preview_label)
	
	# 调整标签位置，使其居中显示在精灵上
	terrain_card_preview_label.position = Vector2(-size/2, -size/2)
	
	print("[MainGameController] ✓ 创建地形卡牌预览：", selected_terrain_card.get("name", "UNKNOWN"), "，首字：", terrain_card_preview_label.text)
	print("[MainGameController] ✓ Preview sprite created and added to scene")
	print("[MainGameController] ✓ Preview sprite z_index: ", terrain_card_preview_sprite.z_index)
	print("[MainGameController] ✓ Preview label z_index: ", terrain_card_preview_label.z_index)

func _remove_terrain_card_preview():
	"""移除地形卡牌预览精灵"""
	if terrain_card_preview_sprite:
		terrain_card_preview_sprite.queue_free()
		terrain_card_preview_sprite = null
	
	if terrain_card_preview_label:
		terrain_card_preview_label = null  # 标签作为精灵的子节点会自动被清理
	
	print("[MainGameController] 移除地形卡牌预览")

func _process(delta):
	"""每帧更新"""
	# 更新地形卡牌预览位置
	if terrain_card_preview_sprite and is_placing_card and selected_terrain_card.size() > 0:
		# 让预览精灵跟随鼠标，但吸附到网格位置
		var mouse_pos = get_global_mouse_position()
		var grid_pos = loop_manager.find_closest_grid_position(mouse_pos)
		var snap_world_pos = loop_manager.grid_position_to_world_position(grid_pos)
		
		# 预览精灵吸附到网格位置
		terrain_card_preview_sprite.global_position = snap_world_pos
		
		# 检查网格位置是否可以放置地形
		if loop_manager.can_place_terrain_at_grid_position(grid_pos):
			# 在有效位置时显示绿色
			terrain_card_preview_sprite.modulate = Color.GREEN
		else:
			# 在无效位置时显示红色
			terrain_card_preview_sprite.modulate = Color.RED


func _auto_place_terrain_card():
	"""在headless模式下自动放置地形卡牌"""
	print("[MainGameController] Auto-placing terrain card: ", selected_terrain_card.get("name", "UNKNOWN"))
	print("[MainGameController] loop_manager exists: ", loop_manager != null)
	print("[MainGameController] hero_manager exists: ", hero_manager != null)
	
	# 找到第一个可以放置地形的位置
	var placed = false
	var grid_size = 50  # 搜索范围
	print("[MainGameController] Searching for placement position in grid size: ", grid_size)
	
	for x in range(-grid_size, grid_size):
		for y in range(-grid_size, grid_size):
			var grid_pos = Vector2i(x, y)
			if loop_manager.can_place_terrain_at_grid_position(grid_pos):
				print("[MainGameController] Found valid placement position: ", grid_pos)
				# 尝试放置地形卡牌
				if loop_manager.place_terrain_card_at_grid_position(grid_pos, selected_terrain_card):
					print("[MainGameController] Successfully placed terrain card at: ", grid_pos)
					# 应用地形卡牌效果到英雄
					hero_manager.add_terrain_card(selected_terrain_card)
					print("[MainGameController] Applied terrain card effect to hero")
					
					_add_log("[color=green]自动放置地形卡牌：" + String(selected_terrain_card.get("name", "")) + " 在位置 (" + str(grid_pos.x) + "," + str(grid_pos.y) + ")[/color]")
					print("[MainGameController] Successfully auto-placed terrain card at grid position: ", grid_pos)
					
					# 清除选择状态
					selected_terrain_card.clear()
					is_placing_card = false
					print("[MainGameController] Cleared card selection state")

					# 隐藏可放置区域高亮（headless下预览可能未显示）
					if loop_manager:
						loop_manager.hide_placeable_highlights()

					# 在 headless 模式下，结束选择并恢复移动；正常模式保持选择暂停以继续选择
					var is_headless := _is_headless_mode()
					if is_headless:
						if card_selection_window:
							card_selection_window.hide_selection()
						if loop_manager and loop_manager.has_method("set_selection_active"):
							loop_manager.set_selection_active(false)
						if loop_manager and not loop_manager.is_moving:
							loop_manager.resume_hero_movement()
					else:
						# 在连续选择流程中，立即重申暂停，避免间隙推进一步
						if loop_manager and loop_manager.has_method("set_selection_active"):
							loop_manager.set_selection_active(true)
						if loop_manager and loop_manager.is_moving:
							loop_manager.pause_hero_movement()
						# 不在每次自动放置后恢复移动；继续选择剩余卡牌
						if card_selection_window:
							card_selection_window.continue_selection()
					
					placed = true
					break
			
		if placed:
			break
	
	if not placed:
		print("[MainGameController] Failed to auto-place terrain card, skipping...")
		_add_log("[color=red]无法自动放置地形卡牌，跳过[/color]")
		
		# 清除选择状态
		selected_terrain_card.clear()
		is_placing_card = false
		print("[MainGameController] Cleared card selection state after failure")
		
		# 在连续选择流程中，立即重申暂停，避免间隙推进一步
		if loop_manager and loop_manager.has_method("set_selection_active"):
			loop_manager.set_selection_active(true)
		if loop_manager and loop_manager.is_moving:
			loop_manager.pause_hero_movement()
		
		# 失败后保持选择暂停，不恢复移动；交由选择窗口管理流程
		if card_selection_window:
			if not _is_headless_mode():
				card_selection_window.continue_selection()

func show_game_over(loop_count: int = 0, step_count: int = 0):
	"""显示Game Over窗口"""
	print("[MainGameController] show_game_over called with loop_count: ", loop_count, ", step_count: ", step_count)
	
	if game_over_window and game_over_window.has_method("show_game_over"):
		game_over_window.show_game_over(loop_count, step_count)
		print("[MainGameController] Game Over window shown")
	else:
		print("[MainGameController] ERROR: GameOverWindow not found or missing show_game_over method")

func _on_restart_game():
	"""处理重新开始游戏"""
	print("[MainGameController] Restart game requested")
	
	# 隐藏Game Over窗口
	if game_over_window and game_over_window.has_method("hide_game_over"):
		game_over_window.hide_game_over()
	
	# 重置游戏状态
	if game_manager:
		game_manager.reset_game()
	
	# 重新开始游戏
	_on_start_button_pressed()

func _on_quit_game():
	"""处理退出游戏"""
	print("[MainGameController] Quit game requested")
	get_tree().quit()
