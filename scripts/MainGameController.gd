# MainGameController.gd
# 主游戏控制器 - 连接各个管理器，处理UI更新和用户交互
class_name MainGameController
extends Node2D

# 管理器引用
@onready var game_manager: Node = $GameManager
@onready var loop_manager: Node = $LoopManager
@onready var card_manager: Node = $CardManager
@onready var hero_manager: Node = $HeroManager
@onready var battle_manager: Node = $BattleManager

# UI引用
# 时间系统UI
@onready var day_label = $UI/MainUI/TopPanel/TimeContainer/DayLabel
@onready var step_progress_bar = $UI/MainUI/TopPanel/TimeContainer/StepProgressBar
@onready var step_label_time = $UI/MainUI/TopPanel/TimeContainer/StepLabel

# 资源UI
@onready var resources_container = $UI/MainUI/TopPanel/ResourcesContainer
@onready var wood_label = $UI/MainUI/TopPanel/ResourcesContainer/WoodLabel
@onready var stone_label = $UI/MainUI/TopPanel/ResourcesContainer/StoneLabel
@onready var metal_label = $UI/MainUI/TopPanel/ResourcesContainer/MetalLabel
@onready var food_label = $UI/MainUI/TopPanel/ResourcesContainer/FoodLabel

@onready var loop_label = $UI/MainUI/BottomPanel/StatusContainer/LoopLabel
@onready var state_label = $UI/MainUI/BottomPanel/StatusContainer/StateLabel

@onready var start_button = $UI/MainUI/BottomPanel/ControlsContainer/StartButton
@onready var retreat_button = $UI/MainUI/BottomPanel/ControlsContainer/RetreatButton
@onready var pause_button = $UI/MainUI/BottomPanel/ControlsContainer/PauseButton

@onready var level_label = $UI/MainUI/TopPanel/HeroPanel/HeroContainer/LevelLabel
@onready var hp_label = $UI/MainUI/TopPanel/HeroPanel/HeroContainer/HPLabel
@onready var step_label = $UI/MainUI/TopPanel/HeroPanel/HeroContainer/StepLabel

@onready var log_text = $UI/MainUI/LogPanel/LogContainer/LogScrollContainer/LogText
@onready var hand_container = $UI/MainUI/BottomPanel/HandPanel/HandContainer

# 战斗窗口引用
@onready var battle_window = $UI/BattleWindow

# 卡牌UI
var hand_card_scenes: Array[Control] = []
var selected_card_index: int = -1

# 输入状态
var is_placing_card: bool = false
var hovered_tile_index: int = -1

func _ready():
	# 连接管理器信号
	_connect_manager_signals()
	
	# 连接UI信号
	_connect_ui_signals()
	
	# 初始化UI
	_initialize_ui()
	
	# 设置管理器引用
	_setup_manager_references()
	
	print("Main Game Controller initialized")
	
	# 自动开始游戏用于测试
	await get_tree().process_frame
	_on_start_button_pressed()

func _connect_manager_signals():
	"""连接管理器信号"""
	# GameManager信号
	game_manager.game_state_changed.connect(_on_game_state_changed)
	game_manager.resources_changed.connect(_on_resources_changed)
	game_manager.loop_completed.connect(_on_loop_completed)
	
	# LoopManager信号
	loop_manager.hero_moved.connect(_on_hero_moved)
	loop_manager.battle_started.connect(_on_battle_started)
	loop_manager.loop_completed.connect(_on_loop_manager_loop_completed)
	loop_manager.step_count_updated.connect(_on_step_count_updated)
	loop_manager.day_changed.connect(_on_day_changed)
	loop_manager.monsters_spawned.connect(_on_monsters_spawned)
	
	# CardManager信号
	card_manager.hand_updated.connect(_on_hand_updated)
	card_manager.card_placed.connect(_on_card_placed)
	
	# HeroManager信号
	hero_manager.hero_stats_changed.connect(_on_hero_stats_changed)
	hero_manager.hero_leveled_up.connect(_on_hero_leveled_up)
	hero_manager.experience_gained.connect(_on_experience_gained)
	
	# BattleManager信号
	battle_manager.battle_started.connect(_on_battle_manager_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.battle_log_updated.connect(_on_battle_log_updated)
	battle_manager.damage_dealt.connect(_on_damage_dealt)
	
	# BattleWindow信号
	battle_window.battle_action_selected.connect(_on_battle_action_selected)
	battle_window.battle_window_closed.connect(_on_battle_window_closed)

func _connect_ui_signals():
	"""连接UI信号"""
	start_button.pressed.connect(_on_start_button_pressed)
	retreat_button.pressed.connect(_on_retreat_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)

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
	# 设置BattleManager的引用
	battle_manager.hero_manager = hero_manager
	battle_manager.loop_manager = loop_manager
	battle_manager.battle_window = battle_window
	
	# 连接BattleManager的battle_ended信号到LoopManager
	# 这样确保LoopManager的on_battle_ended函数会被调用
	battle_manager.battle_ended.connect(loop_manager.on_battle_ended)
	print("[MainGameController] Connected BattleManager.battle_ended to LoopManager.on_battle_ended")

func _on_game_state_changed(new_state: int):
	"""游戏状态改变"""
	_update_game_state_display()
	
	# 简化状态处理，使用数字常量
	match new_state:
		1: # IN_LOOP
			if start_button:
				start_button.text = "循环中..."
				start_button.disabled = true
			if retreat_button:
				retreat_button.disabled = false
		2: # CAMP_MANAGEMENT
			if start_button:
				start_button.text = "开始循环"
				start_button.disabled = false
			if retreat_button:
				retreat_button.disabled = true
		3: # PAUSED
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
	for tile_index in range(loop_manager.TILES_PER_LOOP):
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

func _on_day_changed(day: int):
	"""天数改变"""
	_add_log("[color=yellow]第" + str(day) + "天开始！[/color]")
	_update_time_display()

func _on_monsters_spawned(monster_positions: Array):
	"""怪物生成"""
	_add_log("[color=orange]新的怪物出现在路径上！[/color]")
	_add_log("怪物数量: " + str(monster_positions.size()))

func _on_battle_started(enemy_data: Dictionary):
	"""战斗开始（来自LoopManager）"""
	battle_manager.start_battle(enemy_data, hero_manager, loop_manager)

func _on_battle_manager_battle_started(hero_stats: Dictionary, enemy_data: Dictionary):
	"""战斗开始（来自BattleManager）"""
	_add_log("[color=red]战斗开始！[/color]")
	_add_log("敌人: " + enemy_data.name)
	
	# 显示战斗窗口
	battle_window.show_battle(hero_stats, enemy_data, battle_manager)

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
	battle_window.hide_battle()
	
	print("[MainGameController] _on_battle_ended finished, loop_manager.is_moving: ", loop_manager.is_moving)

func _on_battle_log_updated(message: String):
	"""战斗日志更新"""
	_add_log(message)

func _on_hand_updated(new_hand: Array):
	"""手牌更新"""
	_update_hand_display()

func _on_card_placed(card_data: Dictionary, position: Vector2):
	"""卡牌放置"""
	_add_log("放置卡牌: " + card_data.name)
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
	if game_manager.has_method("start_new_loop"):
		game_manager.start_new_loop()
		loop_manager.start_hero_movement()
		_add_log("[color=cyan]开始新的循环冒险！[/color]")

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
		step_label.text = "步数: " + str(loop_manager.get_step_count())

func _update_game_state_display():
	"""更新游戏状态显示"""
	if game_manager:
		var state_text = ""
		match game_manager.current_state:
			1: # IN_LOOP
				state_text = "循环中"
			2: # CAMP_MANAGEMENT
				state_text = "营地管理"
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
		var current_day = loop_manager.current_day
		var steps_in_day = loop_manager.steps_in_current_day
		var steps_per_day = loop_manager.STEPS_PER_DAY
		
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
	card_button.text = card_data.name
	card_button.tooltip_text = card_data.description
	
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
	_add_log("选择卡牌: " + card_data.name + " (点击循环路径放置)")

func _input(event):
	"""处理输入"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and is_placing_card:
			_try_place_card_at_mouse(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_card_placement()

func _try_place_card_at_mouse(mouse_pos: Vector2):
	"""尝试在鼠标位置放置卡牌"""
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

func _find_closest_tile(world_pos: Vector2) -> int:
	"""找到最接近世界坐标的瓦片索引"""
	var closest_index = -1
	var closest_distance = 999999.0
	
	for i in range(loop_manager.TILES_PER_LOOP):
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
	battle_window.show_damage_effect(target, damage)
	
	# 更新战斗窗口中的状态显示
	if target == "Hero":
		battle_window.update_hero_stats(hero_manager.get_stats())
	else:
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

func _process(_delta):
	"""每帧更新"""
	if is_placing_card:
		queue_redraw()  # 重绘以显示放置预览