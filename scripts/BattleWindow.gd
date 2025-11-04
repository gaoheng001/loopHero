# BattleWindow.gd
# 战斗窗口控制器 - 负责战斗UI的显示和交互
class_name BattleWindow
extends Control

# 信号定义
signal battle_action_selected(action: String)
signal battle_window_closed

# UI引用
# 队伍血条
@onready var hero_team_health_progress = $BattlePanel/MainContainer/TeamHealthBars/HeroTeamHealthBar/HeroTeamHealthContainer/HeroTeamHealthProgress
@onready var hero_team_health_label = $BattlePanel/MainContainer/TeamHealthBars/HeroTeamHealthBar/HeroTeamHealthContainer/HeroTeamHealthLabel
@onready var enemy_team_health_progress = $BattlePanel/MainContainer/TeamHealthBars/EnemyTeamHealthBar/EnemyTeamHealthContainer/EnemyTeamHealthProgress
@onready var enemy_team_health_label = $BattlePanel/MainContainer/TeamHealthBars/EnemyTeamHealthBar/EnemyTeamHealthContainer/EnemyTeamHealthLabel

# 回合数显示
@onready var round_label = $BattlePanel/MainContainer/RoundCounter/RoundLabel

# 个体角色UI
@onready var hero_label = $BattlePanel/MainContainer/ContentContainer/BattleArea/HeroSection/HeroLabel
@onready var hero_sprite = $BattlePanel/MainContainer/ContentContainer/BattleArea/HeroSection/HeroSprite
@onready var hero_hp_label = $BattlePanel/MainContainer/ContentContainer/BattleArea/HeroSection/HeroStats/HeroHP
@onready var hero_attack_label = $BattlePanel/MainContainer/ContentContainer/BattleArea/HeroSection/HeroStats/HeroAttack
@onready var hero_defense_label = $BattlePanel/MainContainer/ContentContainer/BattleArea/HeroSection/HeroStats/HeroDefense

@onready var enemy_label = $BattlePanel/MainContainer/ContentContainer/BattleArea/EnemySection/EnemyLabel
@onready var enemy_sprite = $BattlePanel/MainContainer/ContentContainer/BattleArea/EnemySection/EnemySprite
@onready var enemy_hp_label = $BattlePanel/MainContainer/ContentContainer/BattleArea/EnemySection/EnemyStats/EnemyHP
@onready var enemy_attack_label = $BattlePanel/MainContainer/ContentContainer/BattleArea/EnemySection/EnemyStats/EnemyAttack
@onready var enemy_defense_label = $BattlePanel/MainContainer/ContentContainer/BattleArea/EnemySection/EnemyStats/EnemyDefense

@onready var log_text = $BattlePanel/MainContainer/ContentContainer/LogSection/LogScrollContainer/LogText
@onready var log_scroll = $BattlePanel/MainContainer/ContentContainer/LogSection/LogScrollContainer
@onready var progress_label = $BattlePanel/MainContainer/ContentContainer/LogSection/ProgressLabel

@onready var attack_button = $BattlePanel/MainContainer/ContentContainer/LogSection/ActionContainer/AttackButton
@onready var defend_button = $BattlePanel/MainContainer/ContentContainer/LogSection/ActionContainer/DefendButton
@onready var close_button = $BattlePanel/CloseButton

# 战斗数据
var current_attacking_sprite: ColorRect  # 当前正在攻击的精灵引用
var hero_data: Dictionary = {}
var enemy_data: Dictionary = {}
var original_enemy_hp: int = 0
var battle_log: Array[String] = []
var is_auto_battle: bool = true
var battle_manager: Node = null
var team_battle_manager: Node = null
var team_hero_roster: Array = []
var team_enemy_roster: Array = []

# 回合攻击表现系统组件
var battle_animation_controller: Node = null
var battle_controls: BattleControls = null
var _auto_battle_timer: Timer = null
var _base_turn_interval: float = 2.0  # 自动回合基础间隔（秒），会随速度缩放
var _is_turn_in_progress: bool = false  # 本地回合执行标志，阻止Timer重入
var auto_load_debug_scripts: bool = false  # 开关：是否自动加载调试脚本（默认关闭）

# 血条更新控制
var hp_bar_updated_by_side: Dictionary = {}

func _ready():
	"""初始化战斗窗口"""
	print("[BattleWindow] _ready() 开始初始化")
	# 连接按钮信号
	if attack_button and not attack_button.is_connected("pressed", Callable(self, "_on_attack_button_pressed")):
		attack_button.pressed.connect(_on_attack_button_pressed)
	if defend_button and not defend_button.is_connected("pressed", Callable(self, "_on_defend_button_pressed")):
		defend_button.pressed.connect(_on_defend_button_pressed)
	if close_button and not close_button.is_connected("pressed", Callable(self, "_on_close_button_pressed")):
		close_button.pressed.connect(_on_close_button_pressed)
	
	# 初始化动画控制器
	_initialize_animation_controller()
	
	# 初始化战斗控制面板
	_initialize_battle_controls()
	
	# 初始状态隐藏窗口
	visible = false

	# 移除默认的测试战斗触发，避免与正式战斗冲突
	# 如需测试，可在调试脚本中显式调用 _delayed_test_battle()
	# 可选加载调试脚本：仅在调试构建且开启开关时
	if OS.is_debug_build() and auto_load_debug_scripts:
		_load_debug_script()
	print("[BattleWindow] _ready() 初始化完成")

func _process(delta):
	"""每帧更新"""
	# 更新特效管理器的状态效果（避免在 Node 基类上直接访问未声明属性）
	if battle_animation_controller != null:
		var effects_mgr = null
		if battle_animation_controller.has_method("get"):
			effects_mgr = battle_animation_controller.get("effects_manager")
		if effects_mgr != null:
			effects_mgr.update_status_effects()

func _initialize_animation_controller():
	"""初始化动画控制器"""
	print("[BattleWindow] 开始初始化动画控制器")
	
	# 获取或创建BattleAnimationController节点
	battle_animation_controller = get_node_or_null("BattleAnimationController")
	
	if not battle_animation_controller:
		print("[BattleWindow] 创建BattleAnimationController节点")
		# 使用脚本类直接实例化，避免运行时 set_script 带来的方法表未就绪问题
		var BAC = preload("res://scripts/battle/BattleAnimationController.gd")
		battle_animation_controller = BAC.new()
		battle_animation_controller.name = "BattleAnimationController"
		add_child(battle_animation_controller)
		print("[BattleWindow] BattleAnimationController节点已创建并添加")
	else:
		print("[BattleWindow] BattleAnimationController节点已存在")
		# 若检测到旧节点没有 initialize 方法，认为处于半挂载状态，直接重建
		if not battle_animation_controller.has_method("initialize"):
			print("[BattleWindow] 检测到旧的BattleAnimationController缺少initialize，重建节点以避免半挂载")
			if is_instance_valid(battle_animation_controller):
				remove_child(battle_animation_controller)
				battle_animation_controller.queue_free()
			var BAC2 = preload("res://scripts/battle/BattleAnimationController.gd")
			battle_animation_controller = BAC2.new()
			battle_animation_controller.name = "BattleAnimationController"
			add_child(battle_animation_controller)
	
	# 等待一帧让脚本完全加载
	# 检查get_tree()是否可用，避免空值错误
	if get_tree():
		await get_tree().process_frame
	else:
		print("[BattleWindow] 警告: get_tree()不可用，跳过等待帧")
	
	# 检查节点状态
	print("[BattleWindow] BattleAnimationController类型: ", battle_animation_controller.get_class())
	print("[BattleWindow] BattleAnimationController脚本: ", battle_animation_controller.get_script())
	print("[BattleWindow] 是否有initialize方法: ", battle_animation_controller.has_method("initialize"))
	
	print("[BattleWindow] 动画控制器初始化完成")

func _initialize_battle_controls():
	"""初始化战斗控制面板"""
	battle_controls = BattleControls.new()
	battle_controls.name = "BattleControls"
	add_child(battle_controls)
	
	# 连接战斗控制信号
	battle_controls.speed_changed.connect(_on_speed_changed)
	battle_controls.pause_toggled.connect(_on_pause_toggled)
	battle_controls.auto_battle_toggled.connect(_on_auto_battle_toggled)
	battle_controls.skip_animation_requested.connect(_on_skip_animation_requested)
	battle_controls.battle_exit_requested.connect(_on_battle_exit_requested)
	
	# 初始状态隐藏控制面板
	battle_controls.visible = false
	
	print("[BattleWindow] 战斗控制面板初始化完成")

func show_battle(hero_stats: Dictionary, enemy_stats: Dictionary, battle_mgr: Node = null):
	"""弃用1v1：兼容入口，转发为队伍战斗显示"""
	# 构造3v3队伍并调用队伍战斗
	var h0 := {
		"name": String(hero_stats.get("name", "英雄")),
		"current_hp": int(hero_stats.get("current_hp", hero_stats.get("max_hp", 100))),
		"max_hp": int(hero_stats.get("max_hp", hero_stats.get("current_hp", 100))),
		"attack": int(hero_stats.get("attack", 12)),
		"defense": int(hero_stats.get("defense", 4)),
		"skills": ["power_strike"],
		"passives": ["tough"],
		"status_effects": []
	}
	var h1 := {
		"name": "战友A",
		"current_hp": max(24, int(h0.current_hp * 0.7)),
		"max_hp": max(24, int(h0.max_hp * 0.7)),
		"attack": max(1, int(h0.attack) - 1),
		"defense": int(h0.defense),
		"skills": ["multi_strike"],
		"passives": ["lifesteal"],
		"status_effects": []
	}
	var h2 := {
		"name": "战友B",
		"current_hp": max(20, int(h0.current_hp * 0.6)),
		"max_hp": max(20, int(h0.max_hp * 0.6)),
		"attack": int(h0.attack) + 1,
		"defense": max(0, int(h0.defense) - 1),
		"skills": ["power_strike"],
		"passives": ["berserk"],
		"status_effects": []
	}
	var ebase := {
		"name": String(enemy_stats.get("name", "敌人")),
		"current_hp": int(enemy_stats.get("hp", 30)),
		"max_hp": int(enemy_stats.get("hp", 30)),
		"attack": int(enemy_stats.get("attack", 8)),
		"defense": int(enemy_stats.get("defense", 3)),
		"skills": [],
		"passives": [],
		"status_effects": []
	}
	var e1 := ebase.duplicate(true); e1.name = String(ebase.name) + "·甲"
	var e2 := ebase.duplicate(true); e2.name = String(ebase.name) + "·乙"
	show_team_battle([h0, h1, h2], [ebase, e1, e2], null)

	# 显示1v1战斗的UI元素
	_show_1v1_battle_elements()
	
	hero_data = hero_stats.duplicate()
	enemy_data = enemy_stats.duplicate()
	original_enemy_hp = int(enemy_data.get("hp", 0))
	battle_manager = battle_mgr
	
	# 更新UI显示
	_update_hero_display()
	_update_enemy_display()
	
	# 清空战斗日志
	battle_log.clear()
	log_text.text = ""
	
	# 添加初始日志
	_add_battle_log("[color=yellow]战斗开始！[/color]")
	_add_battle_log("英雄 vs " + String(enemy_data.get("name", "未知")))
	
	# 显示窗口 - 确保正确显示
	visible = true
	modulate = Color.WHITE  # 确保不透明
	z_index = 100  # 设置高Z-index确保在最前面
	# 置顶以确保不会被其他UI遮挡
	move_to_front()
	print("[BattleWindow] show_battle: set visible=true, z_index=100 and raised to top")
	
	# 强制更新显示
	await get_tree().process_frame
	
	# 如果是自动战斗，禁用按钮
	if is_auto_battle:
		attack_button.disabled = true
		defend_button.disabled = true
	else:
		attack_button.disabled = false
		defend_button.disabled = false

func hide_battle():
	"""隐藏战斗窗口"""
	visible = false
	
	# 隐藏战斗控制面板
	if battle_controls:
		battle_controls.visible = false
		battle_controls.set_battle_state("battle_end")
	
	# 释放战斗相关节点与脚本，避免资源泄漏
	_cleanup_battle_nodes()
	
	battle_window_closed.emit()

func update_hero_stats(new_stats: Dictionary):
	"""更新英雄状态"""
	hero_data = new_stats.duplicate()
	_update_hero_display()

func update_enemy_stats(new_stats: Dictionary):
	"""更新敌人状态"""
	enemy_data = new_stats.duplicate()
	_update_enemy_display()

func add_battle_log(message: String):
	"""添加战斗日志"""
	_add_battle_log(message)

func show_team_battle(hero_roster: Array, enemy_roster: Array, tbm: Node = null):
	"""接入TeamBattleManager，显示队伍战斗并输出回合日志与进度"""
	# 每次进入新战斗时重置本地回合标志，避免旧状态阻塞
	_is_turn_in_progress = false

	# 隐藏1v1战斗的UI元素
	_hide_1v1_battle_elements()

	# 初始化动画控制器
	await _initialize_animation_controller()

	# 确保队伍战斗的动画区域可见
	var animation_area = $BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea
	if animation_area:
		animation_area.visible = true
	
	# 保存队伍编制用于奖励计算
	team_hero_roster = hero_roster.duplicate(true)
	team_enemy_roster = enemy_roster.duplicate(true)
	# 更新队伍标签为聚合
	hero_label.text = "英雄队伍"
	enemy_label.text = "敌人队伍"
	# 改为显示队伍HP池而非存活计数
	var hero_cur := 0
	var hero_max := 0
	for h in hero_roster:
		hero_cur += int(h.get("current_hp", 0))
		hero_max += int(h.get("max_hp", h.get("current_hp", 0)))
	var enemy_cur := 0
	var enemy_max := 0
	for e in enemy_roster:
		enemy_cur += int(e.get("current_hp", 0))
		enemy_max += int(e.get("max_hp", e.get("current_hp", 0)))
	hero_hp_label.text = "队伍HP: " + str(hero_cur) + "/" + str(hero_max)
	enemy_hp_label.text = "队伍HP: " + str(enemy_cur) + "/" + str(enemy_max)
	hero_attack_label.text = "攻击: -"
	hero_defense_label.text = "防御: -"
	enemy_attack_label.text = "攻击: -"
	enemy_defense_label.text = "防御: -"
	
	# 更新队伍血条
	_update_team_health_bars(hero_cur, hero_max, enemy_cur, enemy_max)
	
	# 初始化回合数显示
	round_label.text = "第 1 回合"

	# 清空日志并显示窗口
	battle_log.clear()
	log_text.text = ""
	visible = true
	# 置顶以确保不会被其他UI遮挡
	move_to_front()
	print("[BattleWindow] show_team_battle: set visible=true and raised to top")
	attack_button.disabled = true
	defend_button.disabled = true
	close_button.disabled = true
	
	# 显示战斗控制面板
	if battle_controls:
		battle_controls.visible = true
		battle_controls.set_battle_state("battle_start")
		# Godot 4 控件置顶改用 move_to_front
		battle_controls.move_to_front()

	# 在切换到新的 TBM 之前，断开旧 TBM 的信号并清理旧实例，避免重复信号导致卡住
	if team_battle_manager != null:
		if team_battle_manager.is_connected("log_message", Callable(self, "_on_tbm_log")):
			team_battle_manager.disconnect("log_message", Callable(self, "_on_tbm_log"))
		if team_battle_manager.is_connected("turn_started", Callable(self, "_on_tbm_turn_started")):
			team_battle_manager.disconnect("turn_started", Callable(self, "_on_tbm_turn_started"))
		if team_battle_manager.is_connected("turn_finished", Callable(self, "_on_tbm_turn_finished")):
			team_battle_manager.disconnect("turn_finished", Callable(self, "_on_tbm_turn_finished"))
		if team_battle_manager.is_connected("battle_finished", Callable(self, "_on_tbm_finished")):
			team_battle_manager.disconnect("battle_finished", Callable(self, "_on_tbm_finished"))
		if team_battle_manager.is_connected("skill_triggered", Callable(self, "_on_tbm_skill_triggered")):
			team_battle_manager.disconnect("skill_triggered", Callable(self, "_on_tbm_skill_triggered"))
		if team_battle_manager.is_connected("damage_dealt", Callable(self, "_on_tbm_damage_dealt")):
			team_battle_manager.disconnect("damage_dealt", Callable(self, "_on_tbm_damage_dealt"))
		if team_battle_manager.is_connected("team_hp_changed", Callable(self, "_on_tbm_team_hp_changed")):
			team_battle_manager.disconnect("team_hp_changed", Callable(self, "_on_tbm_team_hp_changed"))
		# 若旧 TBM 属于 BattleWindow，释放它以防仍然发射信号
		if team_battle_manager.get_parent() == self:
			team_battle_manager.queue_free()
		team_battle_manager = null

	# 设置TBM
	team_battle_manager = tbm
	if team_battle_manager == null:
		# 使用全局类名创建实例
		print("[BattleWindow] 创建TeamBattleManager实例")
		team_battle_manager = TeamBattleManager.new()
		add_child(team_battle_manager)
		print("[BattleWindow] TeamBattleManager实例创建完成")
		# 调试：检查实例的方法和信号
		print("[BattleWindow] 检查TeamBattleManager方法:")
		print("  - has start_battle:", team_battle_manager.has_method("start_battle"))
		print("  - has execute_turn:", team_battle_manager.has_method("execute_turn"))
		print("  - has signal log_message:", team_battle_manager.has_signal("log_message"))
		print("  - has signal damage_dealt:", team_battle_manager.has_signal("damage_dealt"))

	# 连接信号（在TeamBattleManager完全初始化后）
	if not team_battle_manager.is_connected("log_message", Callable(self, "_on_tbm_log")):
		team_battle_manager.connect("log_message", Callable(self, "_on_tbm_log"))
	if not team_battle_manager.is_connected("turn_started", Callable(self, "_on_tbm_turn_started")):
		team_battle_manager.connect("turn_started", Callable(self, "_on_tbm_turn_started"))
	if not team_battle_manager.is_connected("turn_finished", Callable(self, "_on_tbm_turn_finished")):
		team_battle_manager.connect("turn_finished", Callable(self, "_on_tbm_turn_finished"))
	if not team_battle_manager.is_connected("battle_finished", Callable(self, "_on_tbm_finished")):
		team_battle_manager.connect("battle_finished", Callable(self, "_on_tbm_finished"))
	# 新增：连接技能触发信号
	if not team_battle_manager.is_connected("skill_triggered", Callable(self, "_on_tbm_skill_triggered")):
		team_battle_manager.connect("skill_triggered", Callable(self, "_on_tbm_skill_triggered"))
	# 新增：连接伤害事件以实时刷新队伍HP
	if not team_battle_manager.is_connected("damage_dealt", Callable(self, "_on_tbm_damage_dealt")):
		team_battle_manager.connect("damage_dealt", Callable(self, "_on_tbm_damage_dealt"))
	# 新增：连接队伍HP变更事件，统一驱动血条刷新
	if not team_battle_manager.is_connected("team_hp_changed", Callable(self, "_on_tbm_team_hp_changed")):
		team_battle_manager.connect("team_hp_changed", Callable(self, "_on_tbm_team_hp_changed"))

	# 初始化动画控制器与TeamBattleManager的连接
	if battle_animation_controller:
		# 直接初始化（在 _initialize_animation_controller 已保证方法表就绪）
		if battle_animation_controller.has_method("initialize"):
			battle_animation_controller.initialize(team_battle_manager, self)
			print("[BattleWindow] BattleAnimationController初始化成功")
			# 设置TeamBattleManager的battle_animation_controller引用
			if team_battle_manager:
				team_battle_manager.battle_animation_controller = battle_animation_controller
				print("[BattleWindow] 已设置TeamBattleManager的battle_animation_controller引用")
		else:
			print("[BattleWindow] Error: initialize() missing on BattleAnimationController")

	# 初始队伍展示
	_add_battle_log("[color=yellow]队伍战斗开始！[/color]")
	var hero_names: Array = []
	for h in hero_roster:
		hero_names.append(str(h.get("name", "成员")))
	var enemy_names: Array = []
	for e in enemy_roster:
		enemy_names.append(str(e.get("name", "成员")))
	var hero_names_text = ""
	for i in range(hero_names.size()):
		hero_names_text += hero_names[i]
		if i < hero_names.size() - 1:
			hero_names_text += ", "
	var enemy_names_text = ""
	for i in range(enemy_names.size()):
		enemy_names_text += enemy_names[i]
		if i < enemy_names.size() - 1:
			enemy_names_text += ", "
	_add_battle_log("英雄队: " + hero_names_text)
	_add_battle_log("敌人队: " + enemy_names_text)

	progress_label.text = "回合: - | 英雄队伍HP " + str(hero_cur) + "/" + str(hero_max) + " | 敌人队伍HP " + str(enemy_cur) + "/" + str(enemy_max)

	# 启动战斗，但不立即完成，让动画系统有时间播放
	# 兜底：若动画器尚未创建，先主动创建一次，防止信号先后顺序导致不可见
	var anim_area = get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea")
	var hero_cont = anim_area.get_node_or_null("HeroAnimators") if anim_area else null
	var enemy_cont = anim_area.get_node_or_null("EnemyAnimators") if anim_area else null
	if battle_animation_controller and battle_animation_controller.has_method("_create_character_animators"):
		var hero_children := hero_cont.get_child_count() if hero_cont else 0
		var enemy_children := enemy_cont.get_child_count() if enemy_cont else 0
		if hero_children == 0 and enemy_children == 0:
			print("[BattleWindow] Fallback: 主动创建角色动画器")
			battle_animation_controller._create_character_animators()
			# 调试：输出容器信息
			if hero_cont and hero_cont is Control:
				print("[BattleWindow] HeroAnimators pos=", hero_cont.global_position, ", size=", hero_cont.size)
			if enemy_cont and enemy_cont is Control:
				print("[BattleWindow] EnemyAnimators pos=", enemy_cont.global_position, ", size=", enemy_cont.size)

	if team_battle_manager and team_battle_manager.has_method("start_battle"):
		team_battle_manager.start_battle(hero_roster, enemy_roster, {})
	else:
		print("[BattleWindow] Error: team_battle_manager is null or doesn't have start_battle method")
	# 启动自动战斗循环，让战斗逐步进行以显示动画
	_start_auto_battle_loop()

func _start_auto_battle_loop():
	"""启动自动战斗循环，逐步执行战斗回合以显示动画"""
	print("[BattleWindow] 启动自动战斗循环")
	
	# 使用Timer来控制战斗节奏，给动画时间播放
	if _auto_battle_timer == null:
		_auto_battle_timer = Timer.new()
		_auto_battle_timer.name = "AutoBattleTimer"
		# 首次启动按当前速度折算间隔
		var speed := 1.0
		if battle_controls:
			speed = battle_controls.get_current_speed()
		_auto_battle_timer.wait_time = max(0.25, _base_turn_interval / speed)
		_auto_battle_timer.timeout.connect(_execute_next_turn)
		add_child(_auto_battle_timer)
	_auto_battle_timer.start()

func _execute_next_turn():
	"""执行下一个战斗回合"""
	if team_battle_manager and team_battle_manager.battle_active:
		# 防止在上一个回合尚未结束时再次触发，导致同时掉血/动画并发
		if _is_turn_in_progress:
			print("[BattleWindow] 当前回合尚未结束，跳过此次触发")
			return
		print("[BattleWindow] 执行战斗回合")
		team_battle_manager.execute_turn()
	else:
		print("[BattleWindow] 战斗已结束，停止自动循环")
		# 战斗结束，清理Timer
		if _auto_battle_timer:
			_auto_battle_timer.stop()
			_auto_battle_timer.queue_free()
			_auto_battle_timer = null

func _on_tbm_log(text: String):
	_add_battle_log(text)

# 辅助：统一更新队伍HP池标签
func _update_team_hp_labels():
	if team_battle_manager == null:
		return
	var h_cur = team_battle_manager._get_team_hp_current(team_battle_manager.hero_team)
	var h_max = team_battle_manager._get_team_hp_max(team_battle_manager.hero_team)
	var e_cur = team_battle_manager._get_team_hp_current(team_battle_manager.enemy_team)
	var e_max = team_battle_manager._get_team_hp_max(team_battle_manager.enemy_team)
	hero_hp_label.text = "队伍HP: " + str(h_cur) + "/" + str(h_max)
	enemy_hp_label.text = "队伍HP: " + str(e_cur) + "/" + str(e_max)

func _update_round_display():
	"""更新回合数显示"""
	if team_battle_manager == null:
		round_label.text = "第 1 回合"
		return
	var current_round = team_battle_manager.turn_index
	if current_round <= 0:
		current_round = 1
	round_label.text = "第 " + str(current_round) + " 回合"

func _on_tbm_turn_started(turn_index: int, side: String):
	_is_turn_in_progress = true
	# 重置血条更新标志
	var normalized_side = "heroes" if side == "hero" else "enemies"
	hp_bar_updated_by_side[normalized_side] = false
	
	# 改用队伍HP池显示进度
	_update_team_hp_labels()
	_update_round_display()
	var h_cur = team_battle_manager._get_team_hp_current(team_battle_manager.hero_team)
	var h_max = team_battle_manager._get_team_hp_max(team_battle_manager.hero_team)
	var e_cur = team_battle_manager._get_team_hp_current(team_battle_manager.enemy_team)
	var e_max = team_battle_manager._get_team_hp_max(team_battle_manager.enemy_team)
	progress_label.text = "回合: " + str(turn_index) + "(" + side + ") | 英雄队伍HP " + str(h_cur) + "/" + str(h_max) + " | 敌人队伍HP " + str(e_cur) + "/" + str(e_max)

func _on_tbm_turn_finished(turn_index: int):
	# 标记回合结束，允许下一次Timer触发
	_is_turn_in_progress = false

# 新增：伤害事件时延迟刷新队伍HP，配合动画时序
func _on_tbm_damage_dealt(attacker_data, target_data, damage: int, is_critical: bool):
	# 改为仅处理表现层逻辑（动画/音效），不再直接刷新血条
	# UI 刷新统一由 team_hp_changed 驱动，避免双方同时掉血的竞态
	return

# 新增：队伍HP变更事件统一刷新血条
func _on_tbm_team_hp_changed(side: String, current: int, max: int):
	if team_battle_manager == null:
		return

	var hero_cur: int
	var hero_max: int
	var enemy_cur: int
	var enemy_max: int

	if side == "heroes":
		hero_cur = current
		hero_max = max
		enemy_cur = team_battle_manager._get_team_hp_current(team_battle_manager.enemy_team)
		enemy_max = team_battle_manager._get_team_hp_max(team_battle_manager.enemy_team)
	else:
		enemy_cur = current
		enemy_max = max
		hero_cur = team_battle_manager._get_team_hp_current(team_battle_manager.hero_team)
		hero_max = team_battle_manager._get_team_hp_max(team_battle_manager.hero_team)

	_update_team_health_bars(hero_cur, hero_max, enemy_cur, enemy_max)
	# 同步队伍HP池标签
	hero_hp_label.text = "队伍HP: " + str(hero_cur) + "/" + str(hero_max)
	enemy_hp_label.text = "队伍HP: " + str(enemy_cur) + "/" + str(enemy_max)

func _on_tbm_finished(result: String, stats: Dictionary):
	_add_battle_log("[color=yellow]战斗结束：" + result + "[/color]")
	# 改为输出队伍HP池统计
	var h_hp = stats.get("hero_team_hp", 0)
	var e_hp = stats.get("enemy_team_hp", 0)
	_add_battle_log("统计: 回合=" + str(stats.get("turns", 0)) + ", 英雄队伍HP=" + str(h_hp) + ", 敌人队伍HP=" + str(e_hp))
	progress_label.text = "完成 | 回合: " + str(stats.get("turns", 0))
	# 计算与应用队伍战斗奖励，并传递给循环系统
	var victory: bool = (result == "heroes_win")
	var rewards: Dictionary = {}
	if victory:
		rewards = _calculate_team_victory_rewards()
		_apply_team_victory_rewards(rewards)
	var loop_mgr = get_node_or_null("/root/MainGame/LoopManager")
	if loop_mgr and loop_mgr.has_method("on_battle_ended"):
		loop_mgr.on_battle_ended(victory, rewards)
	# 延迟关闭窗口，让玩家看到结果与奖励
	await get_tree().create_timer(2.0).timeout
	close_button.disabled = false
	hide_battle()

func set_auto_battle(auto: bool):
	"""设置自动战斗模式"""
	is_auto_battle = auto
	if is_auto_battle:
		attack_button.disabled = true
		defend_button.disabled = true
	else:
		attack_button.disabled = false
		defend_button.disabled = false


# 删除兼容旧接口的占位方法，统一使用下方的完整视觉效果实现

func _update_hero_display():
	"""更新英雄显示"""
	hero_label.text = "英雄"
	hero_hp_label.text = "HP: " + str(hero_data.current_hp) + "/" + str(hero_data.max_hp)
	hero_attack_label.text = "攻击: " + str(hero_data.get("attack", 0))
	hero_defense_label.text = "防御: " + str(hero_data.get("defense", 0))
	
	# 根据血量设置颜色
	var hp_ratio = float(hero_data.current_hp) / float(hero_data.max_hp)
	if hp_ratio > 0.6:
		hero_sprite.color = Color(0.2, 0.6, 1, 1)  # 蓝色
	elif hp_ratio > 0.3:
		hero_sprite.color = Color(1, 1, 0.2, 1)  # 黄色
	else:
		hero_sprite.color = Color(1, 0.6, 0.2, 1)  # 橙色

func _update_enemy_display():
	"""更新敌人显示"""
	enemy_label.text = String(enemy_data.get("name", "未知"))
	enemy_hp_label.text = "HP: " + str(int(enemy_data.get("hp", 0))) + "/" + str(original_enemy_hp)
	enemy_attack_label.text = "攻击: " + str(enemy_data.get("attack", 0))
	enemy_defense_label.text = "防御: " + str(enemy_data.get("defense", 0))
	
	# 根据血量设置颜色
	var hp_ratio = float(int(enemy_data.get("hp", 0))) / float(original_enemy_hp)
	if hp_ratio > 0.6:
		enemy_sprite.color = Color(1, 0.2, 0.2, 1)  # 红色
	elif hp_ratio > 0.3:
		enemy_sprite.color = Color(1, 0.6, 0.2, 1)  # 橙色
	else:
		enemy_sprite.color = Color(0.6, 0.2, 0.2, 1)  # 深红色

func _add_battle_log(message: String):
	"""添加战斗日志"""
	battle_log.append(message)
	
	# 更新日志显示
	if log_text.text == "":
		log_text.text = message
	else:
		log_text.text += "\n" + message
	
	# 自动滚动到底部
	await get_tree().process_frame
	log_scroll.scroll_vertical = log_scroll.get_v_scroll_bar().max_value

func _on_attack_button_pressed():
	"""攻击按钮点击"""
	battle_action_selected.emit("attack")

func _on_defend_button_pressed():
	"""防御按钮点击"""
	battle_action_selected.emit("defend")

func _on_close_button_pressed():
	"""关闭按钮点击"""
	# 只有在战斗结束后才能关闭
	if battle_manager and battle_manager.is_battle_active():
		_add_battle_log("[color=red]战斗进行中，无法关闭窗口！[/color]")
		return
	
	hide_battle()

# 动画效果
func show_attack_animation(attacker: String):
	"""显示攻击动画 - 攻击者横移攻击"""
	var attacker_sprite = hero_sprite if attacker == "Hero" else enemy_sprite
	
	# 计算移动距离（向目标方向移动80像素，更明显）
	var move_distance = 80
	if attacker == "Enemy":
		move_distance = -80  # 敌人向左移动
	
	# 保存原始状态
	var original_position = attacker_sprite.position
	var original_color = attacker_sprite.color
	var original_modulate = attacker_sprite.modulate
	var original_scale = attacker_sprite.scale
	
	print("[Attack Animation] Starting attack animation for ", attacker)
	print("[Attack Animation] Original position: ", original_position)
	print("[Attack Animation] Move distance: ", move_distance)
	
	# 创建攻击动画：使用position实现横移
	var attack_tween = create_tween()
	# 攻击时变亮并放大
	attack_tween.parallel().tween_property(attacker_sprite, "modulate", Color(1.8, 1.8, 1.2, 1.0), 0.15)
	attack_tween.parallel().tween_property(attacker_sprite, "scale", Vector2(1.2, 1.2), 0.15)
	# 快速移动到目标位置（使用position实现横移）
	attack_tween.parallel().tween_property(attacker_sprite, "position:x", original_position.x + move_distance, 0.2)
	# 稍作停顿
	attack_tween.tween_interval(0.15)
	# 回到原始位置和状态
	attack_tween.parallel().tween_property(attacker_sprite, "position", original_position, 0.25)
	attack_tween.parallel().tween_property(attacker_sprite, "modulate", original_modulate, 0.25)
	attack_tween.parallel().tween_property(attacker_sprite, "scale", original_scale, 0.25)
	# 动画结束后确保所有属性重置
	attack_tween.tween_callback(_reset_attack_animation.bind(attacker_sprite, original_position, original_color, original_modulate, original_scale))

func _reset_sprite_pivot(sprite: ColorRect, original_pivot: Vector2):
	"""重置精灵pivot_offset"""
	sprite.pivot_offset = original_pivot

func _reset_attack_animation(sprite: ColorRect, original_position: Vector2, original_color: Color, original_modulate: Color, original_scale: Vector2):
	"""重置攻击动画的所有属性"""
	sprite.position = original_position
	sprite.color = original_color
	sprite.modulate = original_modulate
	sprite.scale = original_scale
	print("[Attack Animation] Animation reset completed")

func _restore_sprite_color(sprite: ColorRect, original_color: Color, original_modulate: Color = Color.WHITE):
	"""恢复精灵原始颜色和调制"""
	sprite.color = original_color
	sprite.modulate = original_modulate

func show_damage_effect(target: String, damage: int):
	"""显示伤害效果 - 统一使用方块闪烁动画"""
	var target_sprite = hero_sprite if target == "Hero" else enemy_sprite
	
	# 创建伤害数字标签
	var damage_label = Label.new()
	damage_label.text = "-" + str(damage)
	damage_label.add_theme_color_override("font_color", Color.RED)
	damage_label.position = target_sprite.global_position + Vector2(0, -30)
	add_child(damage_label)
	
	# 创建动画
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position", damage_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(damage_label.queue_free)
	
	# 统一使用方块闪烁动画而不是名字闪烁
	if battle_animation_controller and battle_animation_controller.has_method("play_simplified_team_damage_animation"):
		var side = "heroes" if target == "Hero" else "enemies"
		var is_critical = damage > 50  # 简单的暴击判断
		battle_animation_controller.play_simplified_team_damage_animation(side, is_critical)

func _calculate_team_victory_rewards() -> Dictionary:
	"""计算队伍战斗胜利奖励（聚合所有敌人）"""
	var rewards = {
		"experience": 0,
		"resources": {},
		"items": []
	}

	# 经验：按每个敌人的最大生命与攻击力的组合累加
	for e in team_enemy_roster:
		var max_hp = int(e.get("max_hp", e.get("hp", 0)))
		var atk = int(e.get("attack", 0))
		rewards.experience += max_hp + atk * 2

	# 资源：累加敌人自带资源奖励，外加每名敌人基础灵石
	for e in team_enemy_roster:
		var spirit_reward = 5
		if e.has("is_boss") and e.get("is_boss") == true:
			spirit_reward = 50
		if e.has("rewards"):
			var er = e.get("rewards").duplicate()
			for k in er:
				rewards.resources[k] = rewards.resources.get(k, 0) + er[k]
			# 追加灵石
			rewards.resources["spirit_stones"] = rewards.resources.get("spirit_stones", 0) + spirit_reward
		else:
			# 默认资源
			rewards.resources["wood"] = rewards.resources.get("wood", 0) + randi_range(1, 3)
			rewards.resources["stone"] = rewards.resources.get("stone", 0) + randi_range(0, 2)
			rewards.resources["spirit_stones"] = rewards.resources.get("spirit_stones", 0) + spirit_reward

	# 装备掉落：按每个敌人10%概率生成一件
	for e in team_enemy_roster:
		if randf() < 0.1:
			rewards.items.append({
				"name": "队伍战利品",
				"slot_type": "misc",
				"stats": {},
				"rarity": "common"
			})

	return rewards

func _apply_team_victory_rewards(rewards: Dictionary):
	"""应用队伍战斗胜利奖励到系统，并在战斗窗口日志中展示"""
	# 给予经验
	var hero_mgr = get_node_or_null("/root/MainGame/HeroManager")
	if hero_mgr and rewards.has("experience") and hero_mgr.has_method("gain_experience"):
		hero_mgr.gain_experience(int(rewards.experience))
		_add_battle_log("获得 " + str(rewards.experience) + " 点经验")

	# 给予资源
	var game_mgr = get_node_or_null("/root/MainGame/GameManager")
	if rewards.has("resources") and game_mgr and game_mgr.has_method("add_resources"):
		for resource_type in rewards.resources:
			var amount = int(rewards.resources[resource_type])
			game_mgr.add_resources(resource_type, amount)
			_add_battle_log("获得 " + str(amount) + " " + str(resource_type))
	else:
		_add_battle_log("[警告] 未找到GameManager或resources为空，资源奖励未应用")

	# 物品掉落（仅日志演示）
	if rewards.has("items") and rewards.items.size() > 0:
		for item in rewards.items:
			_add_battle_log("获得物品: " + str(item.get("name", "未知物品")))

func show_heal_effect(target: String, heal: int):
	"""显示治疗效果"""
	var target_sprite = hero_sprite if target == "Hero" else enemy_sprite
	
	# 创建治疗数字标签
	var heal_label = Label.new()
	heal_label.text = "+" + str(heal)
	heal_label.add_theme_color_override("font_color", Color.GREEN)
	heal_label.position = target_sprite.global_position + Vector2(0, -30)
	add_child(heal_label)
	
	# 创建动画
	var tween = create_tween()
	tween.parallel().tween_property(heal_label, "position", heal_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(heal_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(heal_label.queue_free)
	
	# 保存原始颜色和调制
	var original_color = target_sprite.color
	var original_modulate = target_sprite.modulate
	
	# 目标闪烁效果
	var flash_tween = create_tween()
	flash_tween.tween_property(target_sprite, "modulate", Color.GREEN, 0.1)
	flash_tween.tween_property(target_sprite, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(target_sprite, "modulate", Color.GREEN, 0.1)
	flash_tween.tween_property(target_sprite, "modulate", Color.WHITE, 0.1)
	# 确保恢复到原始颜色和调制
	flash_tween.tween_callback(_restore_sprite_color.bind(target_sprite, original_color, original_modulate))

# ============ 动画控制器信号处理 ============

func _on_animation_started(animation_type: String):
	"""动画开始时的处理"""
	print("[BattleWindow] 动画开始: %s" % animation_type)
	
	# 在动画播放期间禁用UI交互
	_set_ui_interactive(false)

func _on_animation_finished(animation_type: String):
	"""动画结束时的处理"""
	print("[BattleWindow] 动画结束: %s" % animation_type)
	
	# 动画结束后恢复UI交互
	_set_ui_interactive(true)

func _set_ui_interactive(interactive: bool):
	"""设置UI交互状态"""
	if not is_auto_battle:
		attack_button.disabled = not interactive
		defend_button.disabled = not interactive
	
	# 在动画播放期间也可以禁用关闭按钮
	# close_button.disabled = not interactive

# ============ 动画控制公共接口 ============

func set_animation_speed(speed: float):
	"""设置动画播放速度"""
	if battle_animation_controller:
		battle_animation_controller.set_animation_speed(speed)

func set_auto_advance_animation(enabled: bool):
	"""设置是否自动推进动画"""
	if battle_animation_controller:
		if battle_animation_controller.has_method("set_auto_advance_animation"):
			battle_animation_controller.set_auto_advance_animation(enabled)
		else:
			print("[BattleWindow] Warning: battle_animation_controller missing set_auto_advance_animation")

func skip_current_animation():
	"""跳过当前播放的动画"""
	if battle_animation_controller:
		battle_animation_controller.skip_current_animation()

func is_animation_playing() -> bool:
	"""检查是否有动画正在播放"""
	if battle_animation_controller:
		return battle_animation_controller.is_animation_playing()
	return false

# ============ 战斗控制信号处理 ============

func _on_speed_changed(speed: float):
	"""速度变化处理"""
	print("[BattleWindow] 动画速度设置为: %.1fx" % speed)
	if battle_animation_controller:
		battle_animation_controller.set_animation_speed(speed)
	# 同步自动回合计时器节奏
	if _auto_battle_timer:
		_auto_battle_timer.wait_time = max(0.25, _base_turn_interval / speed)

func _on_pause_toggled(is_paused: bool):
	"""暂停切换处理"""
	print("[BattleWindow] 战斗暂停状态: %s" % ("暂停" if is_paused else "继续"))
	
	# 暂停/恢复战斗管理器
	if team_battle_manager and team_battle_manager.has_method("set_paused"):
		team_battle_manager.set_paused(is_paused)
	
	# 暂停/恢复动画控制器
	if battle_animation_controller and battle_animation_controller.has_method("set_paused"):
		battle_animation_controller.set_paused(is_paused)
	
	# 管理自动回合计时器
	if _auto_battle_timer:
		if is_paused:
			_auto_battle_timer.stop()
		else:
			# 仅当处于自动战斗模式且战斗仍在进行时重启
			if is_auto_battle and team_battle_manager and team_battle_manager.battle_active:
				_auto_battle_timer.start()

func _on_auto_battle_toggled(is_auto: bool):
	"""自动战斗切换处理"""
	print("[BattleWindow] 自动战斗状态: %s" % ("开启" if is_auto else "关闭"))
	set_auto_battle(is_auto)
	
	# 通知战斗管理器
	if team_battle_manager and team_battle_manager.has_method("set_auto_battle"):
		team_battle_manager.set_auto_battle(is_auto)
	
	# 管理自动回合计时器
	if _auto_battle_timer:
		if is_auto:
			# 恢复到当前速度对应的节奏并启动
			var speed := 1.0
			if battle_controls:
				speed = battle_controls.get_current_speed()
			_auto_battle_timer.wait_time = max(0.25, _base_turn_interval / speed)
			if team_battle_manager and team_battle_manager.battle_active:
				_auto_battle_timer.start()
		else:
			_auto_battle_timer.stop()

func _on_skip_animation_requested():
	"""跳过动画请求处理"""
	print("[BattleWindow] 跳过动画请求")
	skip_current_animation()

func _on_battle_exit_requested():
	"""退出战斗请求处理"""
	print("[BattleWindow] 退出战斗请求")
	
	# 停止当前战斗
	if team_battle_manager and team_battle_manager.has_method("stop_battle"):
		team_battle_manager.stop_battle()
	
	# 隐藏控制面板
	if battle_controls:
		battle_controls.visible = false

	# 同步隐藏窗口并清理战斗节点
	hide_battle()

func _cleanup_battle_nodes():
	"""释放TeamBattleManager与动画控制器，断开信号并解除脚本引用，避免资源泄漏"""
	# 停止自动回合计时器
	if _auto_battle_timer:
		_auto_battle_timer.stop()

	# 断开TeamBattleManager信号并释放
	if team_battle_manager:
		if team_battle_manager.is_connected("log_message", Callable(self, "_on_tbm_log")):
			team_battle_manager.disconnect("log_message", Callable(self, "_on_tbm_log"))
		if team_battle_manager.is_connected("turn_started", Callable(self, "_on_tbm_turn_started")):
			team_battle_manager.disconnect("turn_started", Callable(self, "_on_tbm_turn_started"))
		if team_battle_manager.is_connected("turn_finished", Callable(self, "_on_tbm_turn_finished")):
			team_battle_manager.disconnect("turn_finished", Callable(self, "_on_tbm_turn_finished"))
		if team_battle_manager.is_connected("battle_finished", Callable(self, "_on_tbm_finished")):
			team_battle_manager.disconnect("battle_finished", Callable(self, "_on_tbm_finished"))
		if team_battle_manager.is_connected("skill_triggered", Callable(self, "_on_tbm_skill_triggered")):
			team_battle_manager.disconnect("skill_triggered", Callable(self, "_on_tbm_skill_triggered"))
		if team_battle_manager.is_connected("damage_dealt", Callable(self, "_on_tbm_damage_dealt")):
			team_battle_manager.disconnect("damage_dealt", Callable(self, "_on_tbm_damage_dealt"))
		if team_battle_manager.is_connected("team_hp_changed", Callable(self, "_on_tbm_team_hp_changed")):
			team_battle_manager.disconnect("team_hp_changed", Callable(self, "_on_tbm_team_hp_changed"))

		team_battle_manager.queue_free()
		team_battle_manager = null

	# 释放动画控制器：解除脚本引用以释放GDScript资源
	if battle_animation_controller:
		if battle_animation_controller.get_script() != null:
			battle_animation_controller.set_script(null)
		battle_animation_controller.queue_free()
		battle_animation_controller = null

func _hide_1v1_battle_elements():
	"""隐藏1v1战斗的UI元素，用于小队战斗模式"""
	# 获取1v1战斗区域的节点引用
	var battle_area = $BattlePanel/MainContainer/ContentContainer/BattleArea
	if battle_area:
		var hero_section = battle_area.get_node("HeroSection")
		var enemy_section = battle_area.get_node("EnemySection") 
		var vs_label = battle_area.get_node("VSLabel")
		
		# 隐藏这些元素
		if hero_section:
			hero_section.visible = false
		if enemy_section:
			enemy_section.visible = false
		if vs_label:
			vs_label.visible = false
		
		print("[BattleWindow] 已隐藏1v1战斗UI元素")

func _show_1v1_battle_elements():
	"""显示1v1战斗的UI元素，用于单体战斗模式"""
	# 获取1v1战斗区域的节点引用
	var battle_area = $BattlePanel/MainContainer/ContentContainer/BattleArea
	if battle_area:
		var hero_section = battle_area.get_node("HeroSection")
		var enemy_section = battle_area.get_node("EnemySection")
		var vs_label = battle_area.get_node("VSLabel")
		
		# 显示这些元素
		if hero_section:
			hero_section.visible = true
		if enemy_section:
			enemy_section.visible = true
		if vs_label:
			vs_label.visible = true
		
		print("[BattleWindow] 已显示1v1战斗UI元素")

func _on_tbm_skill_triggered(caster, skill_id: String, targets: Array):
	# 技能触发时显示技能喊招飘字（简化版）
	show_skill_shout(caster, skill_id)

# 简化版技能喊招飘字，直接在 BattleWindow 用 Label 动画显示
func show_skill_shout(caster, skill_id: String):
	var is_hero: bool = false
	if team_battle_manager != null:
		is_hero = _is_member_in_team(team_battle_manager.hero_team, caster)
	var sprite = hero_sprite if is_hero else enemy_sprite
	if sprite == null:
		return
	var shout_text := _get_skill_shout_text(skill_id)
	var label := Label.new()
	label.text = shout_text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", (Color(0.2, 0.8, 1.0, 1.0) if is_hero else Color(1.0, 0.7, 0.2, 1.0)))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.modulate = Color(1, 1, 1, 0)
	label.scale = Vector2(0.85, 0.85)
	label.position = sprite.global_position + Vector2(0, -30)
	add_child(label)
	var tween := create_tween()
	# 进入动画：淡入 + 稍微放大
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(label, "scale", Vector2(1.0, 1.0), 0.18)
	# 悬停片刻
	tween.tween_interval(0.15)
	# 上升+淡出
	var target_pos := label.position + Vector2(0, -60)
	tween.parallel().tween_property(label, "position", target_pos, 0.85)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.85)
	tween.tween_callback(label.queue_free)

func _get_skill_shout_text(skill_id: String) -> String:
	match skill_id:
		"power_strike":
			return "强击!"
		"multi_strike":
			return "连击!"
		_:
			return "技能!"

func _is_member_in_team(team_array: Array, member) -> bool:
	for m in team_array:
		if typeof(m) == TYPE_DICTIONARY and typeof(member) == TYPE_DICTIONARY:
			if String(m.get("name", "")) == String(member.get("name", "")):
				return true
	return false

# 测试函数 - 延迟触发测试战斗
func _delayed_test_battle():
	"""延迟触发测试战斗以测试敌方攻击动画"""
	print("[BattleWindow] _delayed_test_battle 函数被调用")
	await get_tree().create_timer(2.0).timeout  # 等待2秒确保所有组件初始化完成
	print("[BattleWindow] 开始触发测试战斗...")
	
	# 创建测试队伍数据，确保有唯一ID
	var hero_roster = [
		{"id": "hero_warrior", "name": "测试战士", "current_hp": 50, "max_hp": 50, "attack": 5, "defense": 2},
		{"id": "hero_ranger", "name": "测试游侠", "current_hp": 40, "max_hp": 40, "attack": 4, "defense": 1},
		{"id": "hero_mage", "name": "测试法师", "current_hp": 30, "max_hp": 30, "attack": 3, "defense": 1}
	]
	
	var enemy_roster = [
		{"id": "enemy_1", "name": "强力敌人1", "current_hp": 80, "max_hp": 80, "attack": 15, "defense": 5},
		{"id": "enemy_2", "name": "强力敌人2", "current_hp": 90, "max_hp": 90, "attack": 18, "defense": 6},
		{"id": "enemy_3", "name": "强力敌人3", "current_hp": 100, "max_hp": 100, "attack": 20, "defense": 7}
	]
	
	print("[BattleWindow] 触发测试战斗，英雄队伍弱化，敌方队伍强化")
	show_team_battle(hero_roster, enemy_roster)
	
	# 等待战斗初始化完成
	await get_tree().create_timer(3.0).timeout
	
	# 添加动画匹配测试脚本
	print("[BattleWindow] 尝试加载动画匹配测试脚本...")
	var debug_script = load("res://test_animation_matching.gd")
	if debug_script:
		print("[BattleWindow] ✓ 动画匹配测试脚本加载成功")
		var debug_node = Node.new()
		debug_node.set_script(debug_script)
		debug_node.name = "AnimationMatchingTester"
		add_child(debug_node)
		print("[BattleWindow] ✓ 动画匹配测试节点已添加")
	else:
		print("[BattleWindow] ✗ 动画匹配测试脚本加载失败")

func _load_debug_script():
	"""直接加载调试脚本"""
	print("[BattleWindow] 直接加载调试脚本...")
	await get_tree().create_timer(1.0).timeout  # 等待1秒确保组件初始化
	
	var debug_script = load("res://test_animation_matching.gd")
	if debug_script:
		print("[BattleWindow] ✓ 动画匹配测试脚本加载成功")
		var debug_node = Node.new()
		debug_node.set_script(debug_script)
		debug_node.name = "DirectDebugger"
		add_child(debug_node)

# 队伍血条更新方法
func _update_team_health_bars(hero_current: int, hero_max: int, enemy_current: int, enemy_max: int):
	"""更新队伍血条显示"""
	if hero_team_health_progress and hero_team_health_label:
		hero_team_health_progress.max_value = hero_max
		hero_team_health_progress.value = hero_current
		hero_team_health_label.text = str(hero_current) + "/" + str(hero_max)
		
		# 根据血量百分比设置血条颜色
		var hero_percentage = float(hero_current) / float(hero_max) if hero_max > 0 else 0.0
		if hero_percentage > 0.6:
			hero_team_health_progress.modulate = Color.GREEN
		elif hero_percentage > 0.3:
			hero_team_health_progress.modulate = Color.YELLOW
		else:
			hero_team_health_progress.modulate = Color.RED
	
	if enemy_team_health_progress and enemy_team_health_label:
		enemy_team_health_progress.max_value = enemy_max
		enemy_team_health_progress.value = enemy_current
		enemy_team_health_label.text = str(enemy_current) + "/" + str(enemy_max)
		
		# 根据血量百分比设置血条颜色
		var enemy_percentage = float(enemy_current) / float(enemy_max) if enemy_max > 0 else 0.0
		if enemy_percentage > 0.6:
			enemy_team_health_progress.modulate = Color.GREEN
		elif enemy_percentage > 0.3:
			enemy_team_health_progress.modulate = Color.YELLOW
		else:
			enemy_team_health_progress.modulate = Color.RED

func update_team_health_from_rosters():
	"""从当前队伍编制更新血条显示"""
	if team_hero_roster.size() > 0 and team_enemy_roster.size() > 0:
		var hero_cur := 0
		var hero_max := 0
		for h in team_hero_roster:
			hero_cur += int(h.get("current_hp", 0))
			hero_max += int(h.get("max_hp", h.get("current_hp", 0)))
		
		var enemy_cur := 0
		var enemy_max := 0
		for e in team_enemy_roster:
			enemy_cur += int(e.get("current_hp", 0))
			enemy_max += int(e.get("max_hp", e.get("current_hp", 0)))
		
		_update_team_health_bars(hero_cur, hero_max, enemy_cur, enemy_max)
		
		# 同时更新个体血条显示
		hero_hp_label.text = "队伍HP: " + str(hero_cur) + "/" + str(hero_max)
		enemy_hp_label.text = "队伍HP: " + str(enemy_cur) + "/" + str(enemy_max)
		print("[BattleWindow] ✓ 调试节点已添加")
	else:
		print("[BattleWindow] ✗ 动画匹配测试脚本加载失败")