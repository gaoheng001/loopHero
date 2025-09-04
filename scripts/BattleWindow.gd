# BattleWindow.gd
# 战斗窗口控制器 - 负责战斗UI的显示和交互
class_name BattleWindow
extends Control

# 信号定义
signal battle_action_selected(action: String)
signal battle_window_closed

# UI引用
@onready var hero_label = $BattlePanel/MainContainer/BattleArea/HeroSection/HeroLabel
@onready var hero_sprite = $BattlePanel/MainContainer/BattleArea/HeroSection/HeroSprite
@onready var hero_hp_label = $BattlePanel/MainContainer/BattleArea/HeroSection/HeroStats/HeroHP
@onready var hero_attack_label = $BattlePanel/MainContainer/BattleArea/HeroSection/HeroStats/HeroAttack
@onready var hero_defense_label = $BattlePanel/MainContainer/BattleArea/HeroSection/HeroStats/HeroDefense

@onready var enemy_label = $BattlePanel/MainContainer/BattleArea/EnemySection/EnemyLabel
@onready var enemy_sprite = $BattlePanel/MainContainer/BattleArea/EnemySection/EnemySprite
@onready var enemy_hp_label = $BattlePanel/MainContainer/BattleArea/EnemySection/EnemyStats/EnemyHP
@onready var enemy_attack_label = $BattlePanel/MainContainer/BattleArea/EnemySection/EnemyStats/EnemyAttack
@onready var enemy_defense_label = $BattlePanel/MainContainer/BattleArea/EnemySection/EnemyStats/EnemyDefense

@onready var log_text = $BattlePanel/MainContainer/LogSection/LogScrollContainer/LogText
@onready var log_scroll = $BattlePanel/MainContainer/LogSection/LogScrollContainer

@onready var attack_button = $BattlePanel/MainContainer/LogSection/ActionContainer/AttackButton
@onready var defend_button = $BattlePanel/MainContainer/LogSection/ActionContainer/DefendButton
@onready var close_button = $BattlePanel/CloseButton

# 战斗数据
var current_attacking_sprite: ColorRect  # 当前正在攻击的精灵引用
var hero_data: Dictionary = {}
var enemy_data: Dictionary = {}
var original_enemy_hp: int = 0
var battle_log: Array[String] = []
var is_auto_battle: bool = true
var battle_manager: Node = null

func _ready():
	# 连接按钮信号
	attack_button.pressed.connect(_on_attack_button_pressed)
	defend_button.pressed.connect(_on_defend_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 初始状态隐藏窗口
	visible = false

func show_battle(hero_stats: Dictionary, enemy_stats: Dictionary, battle_mgr: Node = null):
	"""显示战斗窗口"""
	hero_data = hero_stats.duplicate()
	enemy_data = enemy_stats.duplicate()
	original_enemy_hp = enemy_data.hp
	battle_manager = battle_mgr
	
	# 更新UI显示
	_update_hero_display()
	_update_enemy_display()
	
	# 清空战斗日志
	battle_log.clear()
	log_text.text = ""
	
	# 添加初始日志
	_add_battle_log("[color=yellow]战斗开始！[/color]")
	_add_battle_log("英雄 vs " + enemy_data.name)
	
	# 显示窗口
	visible = true
	
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

func set_auto_battle(auto: bool):
	"""设置自动战斗模式"""
	is_auto_battle = auto
	if is_auto_battle:
		attack_button.disabled = true
		defend_button.disabled = true
	else:
		attack_button.disabled = false
		defend_button.disabled = false

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
	enemy_label.text = enemy_data.name
	enemy_hp_label.text = "HP: " + str(enemy_data.hp) + "/" + str(original_enemy_hp)
	enemy_attack_label.text = "攻击: " + str(enemy_data.get("attack", 0))
	enemy_defense_label.text = "防御: " + str(enemy_data.get("defense", 0))
	
	# 根据血量设置颜色
	var hp_ratio = float(enemy_data.hp) / float(original_enemy_hp)
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
	"""显示伤害效果"""
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
	
	# 保存原始颜色和调制
	var original_color = target_sprite.color
	var original_modulate = target_sprite.modulate
	
	# 目标闪烁效果
	var flash_tween = create_tween()
	flash_tween.tween_property(target_sprite, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(target_sprite, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(target_sprite, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(target_sprite, "modulate", Color.WHITE, 0.1)
	# 确保恢复到原始颜色和调制
	flash_tween.tween_callback(_restore_sprite_color.bind(target_sprite, original_color, original_modulate))

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