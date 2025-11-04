# BattleAnimationController.gd
# 回合攻击表现系统 - 核心动画控制器
# 负责协调战斗表现效果，连接TeamBattleManager信号与UI表现

class_name BattleAnimationController
extends Node

# 动画控制信号
signal animation_started(animation_type: String)
signal animation_finished(animation_type: String)
signal character_animation_completed(character_index: int, team_type: String, animation_type: String)

# 动画状态枚举
enum AnimationState {
	IDLE,
	TURN_START,
	ATTACKING,
	SKILL_CASTING,
	BATTLE_END
}

# 组件引用
var team_battle_manager: Node
var battle_window: Control
var hero_animators: Array[CharacterAnimator] = []
var enemy_animators: Array[CharacterAnimator] = []
var effects_manager: BattleEffectsManager
var audio_manager: BattleAudioManager

# 动画配置
var animation_speed: float = 1.0
var auto_advance_animation: bool = true
var current_state: AnimationState = AnimationState.IDLE
var animation_queue: Array = []

# 队伍攻击动画播放标志
var team_attack_played_by_side: Dictionary = {}

# 防重复动画机制
var last_damage_animation_time: Dictionary = {}
var damage_animation_cooldown: float = 0.3  # 同一方受击动画冷却时间

func _ready():
	print("[BattleAnimationController] 动画控制器初始化")
	_initialize_effects_manager()
	_initialize_audio_manager()

func initialize(tbm: Node, window: Control):
	"""初始化动画控制器"""
	team_battle_manager = tbm
	battle_window = window
	
	# 连接TeamBattleManager信号
	_connect_team_battle_signals()
	
	print("[BattleAnimationController] 已连接到TeamBattleManager和BattleWindow")

func _connect_team_battle_signals():
	"""连接TeamBattleManager的信号"""
	if not team_battle_manager:
		print("[BattleAnimationController] 错误：TeamBattleManager未设置")
		return
	
	# 连接战斗事件信号
	if not team_battle_manager.is_connected("battle_started", Callable(self, "_on_battle_started")):
		team_battle_manager.connect("battle_started", Callable(self, "_on_battle_started"))
	
	if not team_battle_manager.is_connected("turn_started", Callable(self, "_on_turn_started")):
		team_battle_manager.connect("turn_started", Callable(self, "_on_turn_started"))
	
	if not team_battle_manager.is_connected("turn_finished", Callable(self, "_on_turn_finished")):
		team_battle_manager.connect("turn_finished", Callable(self, "_on_turn_finished"))
	
	if not team_battle_manager.is_connected("damage_dealt", Callable(self, "_on_damage_dealt")):
		team_battle_manager.connect("damage_dealt", Callable(self, "_on_damage_dealt"))
	
	if not team_battle_manager.is_connected("skill_triggered", Callable(self, "_on_skill_triggered")):
		team_battle_manager.connect("skill_triggered", Callable(self, "_on_skill_triggered"))
	
	if not team_battle_manager.is_connected("battle_finished", Callable(self, "_on_battle_ended")):
		team_battle_manager.connect("battle_finished", Callable(self, "_on_battle_ended"))
	
	if not team_battle_manager.is_connected("log_message", Callable(self, "_on_log_message")):
		team_battle_manager.connect("log_message", Callable(self, "_on_log_message"))
	
	print("[BattleAnimationController] TeamBattleManager信号连接完成")

# ============ TeamBattleManager信号处理 ============

func _on_battle_started(hero_team = null, enemy_team = null):
	"""战斗开始处理"""
	print("[BattleAnimationController] 战斗开始，初始化角色动画器")
	current_state = AnimationState.IDLE
	# 确保新战斗不受上场残留影响：重置锁、队列与冷却
	_animation_lock = false
	pending_animations.clear()
	is_processing_queue = false
	last_damage_animation_time.clear()
	team_attack_played_by_side = {"heroes": false, "enemies": false}
	skill_triggered_by_side = {"heroes": false, "enemies": false}
	
	# 播放战斗开始音效
	if audio_manager:
		audio_manager.play_battle_start_audio()
	
	# 创建角色动画器
	_create_character_animators()
	
	# 播放战斗开始动画
	play_battle_start_animation()
	
	# 播放战斗开始音效
	if audio_manager:
		audio_manager.play_battle_start_audio()
	
	# 创建角色动画器
	_create_character_animators()
	
	# 播放战斗开始动画
	play_battle_start_animation()

func _on_turn_started(turn_index: int, team_type: String):
	"""回合开始处理"""
	print("[BattleAnimationController] 回合 %d 开始 - 队伍: %s" % [turn_index, team_type])
	# 获取动画锁，防止回合开始动画与伤害/技能动画并发
	await _acquire_animation_lock()
	current_state = AnimationState.TURN_START
	# 存储行动方并重置该方标记
	var normalized = _normalize_side(team_type)
	print("[BattleAnimationController] 标准化队伍名称: '%s' -> '%s'" % [team_type, normalized])
	current_acting_side = normalized
	print("[BattleAnimationController] 当前行动方设置为: '%s'" % current_acting_side)
	skill_triggered_by_side[current_acting_side] = false
	# 重置队伍攻击动画标志 - 每回合开始时重置双方标记
	team_attack_played_by_side = {"heroes": false, "enemies": false}

	# 播放回合开始音效
	if audio_manager:
		audio_manager.play_turn_start_audio()

	# 播放回合开始动画
	emit_signal("animation_started", "turn_start")
	await play_turn_start_animation(turn_index)
	current_state = AnimationState.IDLE
	emit_signal("animation_finished", "turn_start")
	# 释放动画锁
	_release_animation_lock()

# 新增：整体动画状态标记（按阵营分开）
var skill_triggered_by_side := {"heroes": false, "enemies": false}
var current_acting_side: String = ""
var _animation_lock: bool = false

# 新增：动画队列系统
var pending_animations: Array = []
var is_processing_queue: bool = false

# 动画数据结构
class AnimationData:
	var type: String  # "damage", "skill", "heal"
	var attacker_data
	var target_data
	var damage: int
	var is_critical: bool
	var side: String  # "heroes" or "enemies"
	
	func _init(t: String, a, tgt, dmg: int = 0, crit: bool = false, s: String = ""):
		type = t
		attacker_data = a
		target_data = tgt
		damage = dmg
		is_critical = crit
		side = s

func _acquire_animation_lock() -> void:
	# 简化的锁机制，不再使用await
	_animation_lock = true

func _release_animation_lock() -> void:
	_animation_lock = false

func _on_damage_dealt(attacker_data, target_data, damage: int, is_critical: bool):
	"""伤害处理 - 改进的时序控制"""
	# 检查是否是攻击动画（需要动画锁），还是受击动画（可以并行）
	var hero_team = _get_hero_team()
	var attacker_is_hero = false
	
	# 处理攻击者是数组（队伍攻击）的情况
	if typeof(attacker_data) == TYPE_ARRAY:
		var attacking_team = attacker_data as Array
		if attacking_team.size() > 0:
			var first_attacker = attacking_team[0]
			attacker_is_hero = _is_member_in_team(hero_team, first_attacker)
	else:
		# 单个攻击者
		attacker_is_hero = _is_member_in_team(hero_team, attacker_data)
	
	# 只有在没有攻击动画播放时才设置动画锁
	if current_state == AnimationState.IDLE and not _animation_lock:
		_animation_lock = true
		print("[BattleAnimationController] 设置动画锁，开始播放动画")
	else:
		print("[BattleAnimationController] 受击动画并行播放，不设置动画锁")
	
	var attacker_name = ""
	var attacker_side = ""
	
	# 处理攻击者是数组（队伍攻击）的情况
	if typeof(attacker_data) == TYPE_ARRAY:
		var attacking_team = attacker_data as Array
		if attacking_team.size() > 0:
			var first_attacker = attacking_team[0]
			attacker_name = "队伍攻击"
			attacker_is_hero = _is_member_in_team(hero_team, first_attacker)
			attacker_side = "heroes" if attacker_is_hero else "enemies"
		else:
			attacker_name = "未知队伍"
			attacker_side = "enemies"
	else:
		# 单个攻击者
		attacker_name = _safe_get_name(attacker_data)
		attacker_is_hero = _is_member_in_team(hero_team, attacker_data)
		attacker_side = "heroes" if attacker_is_hero else "enemies"
	
	print("[BattleAnimationController] 伤害事件: %s -> %s, 伤害: %d%s" % [
		attacker_name,
		_safe_get_name(target_data),
		damage,
		("(暴击)" if is_critical else "")
	])
	
	# 计算目标阵营
	var target_is_hero = _is_member_in_team(hero_team, target_data)
	var target_side = "heroes" if target_is_hero else "enemies"
	
	# 创建动画数据
	var animation_data = AnimationData.new("damage", attacker_data, target_data, damage, is_critical, attacker_side)
	
	# 立即播放动画
	print("[BattleAnimationController] 立即播放动画: %s -> %s" % [attacker_side, target_side])
	await _play_damage_animation_immediate(animation_data, target_side)
	
	# 注意：动画锁已在_play_damage_animation_immediate内部释放
	print("[BattleAnimationController] 动画序列完成")

func _play_damage_animation_immediate(animation_data: AnimationData, target_side: String):
	"""立即播放伤害动画"""
	var attacker_side = animation_data.side

	# 如果该阵营刚刚触发了技能，则跳过队伍普攻动画，直接处理受伤
	if skill_triggered_by_side.has(attacker_side) and skill_triggered_by_side[attacker_side]:
		print("[BattleAnimationController] 技能伤害阶段，跳过队伍普攻动画: %s" % attacker_side)
		
		# 技能伤害：立即播放受击闪烁和血量扣除
		await _trigger_hit_effects_at_impact(target_side, animation_data.damage, animation_data.is_critical)
		
		# 释放动画锁
		_animation_lock = false
		print("[BattleAnimationController] 技能伤害处理完成，释放动画锁")
		
		# 音效：只播放受击音效（施法音效已在技能触发时播放）
		if audio_manager:
			audio_manager.play_damage_sound(animation_data.damage, animation_data.is_critical, null)
		# 复位技能标记，防止后续普通攻击仍被跳过
		skill_triggered_by_side[attacker_side] = false
		return

	# 普通攻击：播放队伍普攻动画，并在冲击时触发受击效果
	print("[BattleAnimationController] 播放队伍普攻动画: %s" % attacker_side)
	current_state = AnimationState.ATTACKING
	emit_signal("animation_started", "attack")
	
	# 并行启动攻击动画和受击处理
	await play_team_attack_animation_with_timing(attacker_side, target_side, animation_data.damage, animation_data.is_critical)
	
	current_state = AnimationState.IDLE
	emit_signal("animation_finished", "attack")
	
	# 释放动画锁
	_animation_lock = false
	print("[BattleAnimationController] 完整受伤处理完成，释放动画锁")

	# 音效
	if audio_manager:
		audio_manager.play_attack_sound("team_attack", null, null)
		audio_manager.play_damage_sound(animation_data.damage, animation_data.is_critical, null)

func process_pending_animations():
	"""处理队列中的动画 - 已简化，不再使用队列机制"""
	print("[BattleAnimationController] 动画队列机制已简化，所有动画立即播放")
	# 清空队列，防止遗留数据
	pending_animations.clear()
	is_processing_queue = false

# 修改：回合结束时的简化处理
func _on_turn_finished(turn_index: int):
	"""回合结束处理 - 简化版本"""
	print("[BattleAnimationController] 回合 %d 结束" % turn_index)
	# 不再处理队列，所有动画都是立即播放的

func _on_skill_triggered(caster_data, skill_id: String, targets: Array):
	"""技能触发处理"""
	print("[BattleAnimationController] 技能触发: %s 使用 %s" % [
		_safe_get_name(caster_data), skill_id
	])
	# 标记本回合发生了技能（按阵营）
	var caster_side = _get_side_for_member(caster_data)
	skill_triggered_by_side[caster_side] = true
	
	var caster_animator = _find_character_animator(caster_data)
	if caster_animator:
		current_state = AnimationState.SKILL_CASTING
		emit_signal("animation_started", "skill")
		
		# 播放技能音效
		if audio_manager:
			audio_manager.play_skill_sound(skill_id, caster_animator)
		
		# 播放施法者技能动画
		caster_animator.play_skill_animation(skill_id)
		await caster_animator.animation_completed
		
		# 播放技能特效
		var target_animators = []
		for target_data in targets:
			var target_animator = _find_character_animator(target_data)
			if target_animator:
				target_animators.append(target_animator)
		
		if effects_manager:
			effects_manager.play_skill_effect(skill_id, caster_animator, target_animators)
		
		# 播放目标效果动画
		for target_data in targets:
			var target_animator = _find_character_animator(target_data)
			if target_animator:
				# 根据技能类型播放不同效果
				_play_skill_target_effect(target_animator, skill_id, target_data)
		
		current_state = AnimationState.IDLE
		emit_signal("animation_finished", "skill")

func _on_battle_ended(result, stats):
	"""战斗结束处理"""
	print("[BattleAnimationController] 战斗结束，结果: %s" % str(result))
	current_state = AnimationState.BATTLE_END
	
	# 播放战斗结束音效
	var winner = "heroes" if result == "heroes_win" else "enemy"
	if audio_manager:
		if winner == "heroes":
			audio_manager.play_victory_audio()
		else:
			audio_manager.play_defeat_audio()
	
	# 播放战斗结束动画
	emit_signal("animation_started", "battle_end")
	play_battle_end_animation(winner)
	
	# 根据获胜方播放不同动画
	if winner == "heroes":
		# 英雄胜利动画
		for animator in hero_animators:
			if animator and is_instance_valid(animator):
				animator.play_victory_animation()
		
		for animator in enemy_animators:
			if animator and is_instance_valid(animator):
				animator.play_defeat_animation()
	else:
		# 敌人胜利动画
		for animator in enemy_animators:
			if animator and is_instance_valid(animator):
				animator.play_victory_animation()
		
		for animator in hero_animators:
			if animator and is_instance_valid(animator):
				animator.play_defeat_animation()
	
	await get_tree().create_timer(2.0).timeout
	emit_signal("animation_finished", "battle_end")

	# 立即清理：移除并释放上一场战斗的角色动画器，重置容器状态
	_cleanup_character_animators()
	# 重置本轮标记，避免跨战斗残留
	skill_triggered_by_side = {"heroes": false, "enemies": false}
	team_attack_played_by_side = {"heroes": false, "enemies": false}
	current_acting_side = ""
	current_state = AnimationState.IDLE
	# 额外清理：重置动画锁与队列/冷却，防止跨战斗卡住
	_animation_lock = false
	pending_animations.clear()
	is_processing_queue = false
	last_damage_animation_time.clear()

func _play_skill_target_effect(target_animator: CharacterAnimator, skill_id: String, target_data: Dictionary):
	"""播放技能目标效果"""
	if not effects_manager:
		return
	
	match skill_id:
		"heal":
			# 治疗效果
			effects_manager.play_heal_effect(target_animator, 50)
			if audio_manager:
				audio_manager.play_heal_sound(50, target_animator)
			if target_animator:
				target_animator.add_status_effect("regen", 2.0)
		"poison_skill":
			# 中毒效果
			effects_manager.apply_poison(target_animator, 5.0)
			if audio_manager:
				audio_manager.play_status_sound("poison", "apply", target_animator)
		"burn_skill":
			# 燃烧效果
			effects_manager.apply_burn(target_animator, 3.0)
			if audio_manager:
				audio_manager.play_status_sound("burn", "apply", target_animator)
		"shield_skill":
			# 护盾效果
			effects_manager.apply_shield(target_animator, 10.0)
			if audio_manager:
				audio_manager.play_status_sound("shield", "apply", target_animator)
		"power_strike", "multi_strike":
			# 攻击技能无额外目标效果
			pass
		_:
			# 默认效果
			pass

# ============ 事件处理 ============

func _on_character_defeated(character_index: int, team_type: String):
	"""角色死亡处理"""
	print("[BattleAnimationController] 角色死亡: %s队伍 位置%d" % [team_type, character_index])

# ============ 公共接口 ============

func set_animation_speed(speed: float):
	"""设置动画播放速度"""
	animation_speed = clamp(speed, 0.1, 3.0)
	
	# 更新所有角色动画器的速度
	var all_animators = hero_animators + enemy_animators
	for animator in all_animators:
		if animator and is_instance_valid(animator):
			animator.set_animation_speed(animation_speed)
	
	# 更新特效管理器的速度
	if effects_manager:
		effects_manager.set_animation_speed(animation_speed)
	
	# 更新音频管理器的播放速度
	if audio_manager:
		audio_manager.set_audio_speed(animation_speed)

func set_auto_advance_animation(auto: bool):
	"""设置自动推进动画"""
	auto_advance_animation = auto

func skip_current_animation():
	"""跳过当前动画"""
	# 停止所有正在播放的动画
	var all_animators = hero_animators + enemy_animators
	for animator in all_animators:
		if animator and is_instance_valid(animator) and animator.is_animation_playing():
			# 这里可以实现跳过逻辑
			pass

func is_animation_playing() -> bool:
	"""检查是否有动画正在播放"""
	# 首先检查动画锁状态
	if _animation_lock:
		return true
	
	if current_state != AnimationState.IDLE:
		return true
	
	var all_animators = hero_animators + enemy_animators
	for animator in all_animators:
		if animator and is_instance_valid(animator) and animator.is_animation_playing():
			return true
	
	return false

func get_animation_state() -> AnimationState:
	"""获取当前动画状态"""
	return current_state

func cleanup():
	"""清理资源"""
	print("[BattleAnimationController] 清理动画控制器")
	
	_cleanup_character_animators()
	animation_queue.clear()
	current_state = AnimationState.IDLE
	
	# 清理特效管理器
	if effects_manager and is_instance_valid(effects_manager):
		effects_manager.clear_all_effects()
		effects_manager.queue_free()
		effects_manager = null
	
	# 清理音频管理器
	if audio_manager and is_instance_valid(audio_manager):
		audio_manager.stop_all_audio()
		audio_manager.queue_free()
		audio_manager = null
	
	# 重置状态
	team_battle_manager = null
	battle_window = null

# ============ 特效管理器集成 ============

func _initialize_effects_manager():
	"""初始化特效管理器"""
	effects_manager = BattleEffectsManager.new()
	effects_manager.name = "BattleEffectsManager"
	add_child(effects_manager)
	
	# 连接特效管理器信号
	effects_manager.effect_started.connect(_on_effect_started)
	effects_manager.effect_finished.connect(_on_effect_finished)
	
	print("[BattleAnimationController] 特效管理器初始化完成")

func _on_effect_started(effect_type: String, target: Node):
	"""特效开始处理"""
	print("[BattleAnimationController] 特效开始: %s" % effect_type)

func _on_effect_finished(effect_type: String, target: Node):
	"""特效结束处理"""
	print("[BattleAnimationController] 特效结束: %s" % effect_type)

# ============ 音频管理器集成 ============

func _initialize_audio_manager():
	"""初始化音频管理器"""
	audio_manager = BattleAudioManager.new()
	audio_manager.name = "BattleAudioManager"
	add_child(audio_manager)
	
	# 连接音频管理器信号
	audio_manager.audio_started.connect(_on_audio_started)
	audio_manager.audio_finished.connect(_on_audio_finished)
	
	print("[BattleAnimationController] 音频管理器初始化完成")

func _on_audio_started(audio_type: String, sound_id: String):
	"""音效开始处理"""
	print("[BattleAnimationController] 音效开始: %s - %s" % [audio_type, sound_id])

func _on_audio_finished(audio_type: String, sound_id: String):
	"""音效结束处理"""
	print("[BattleAnimationController] 音效结束: %s - %s" % [audio_type, sound_id])

# ============ 辅助函数 ============

func _safe_get_name(obj) -> String:
	"""安全获取对象名称"""
	if typeof(obj) == TYPE_DICTIONARY:
		return obj.get("name", "未知")
	elif obj != null and typeof(obj) == TYPE_OBJECT and obj.has_method("get"):
		var name = obj.get("name")
		return name if name != null else "未知"
	else:
		return "未知"

# ============ 缺失方法的最小桩实现，避免解析错误 ============
func _on_log_message(message: String) -> void:
	print("[BattleAnimationController] Log: %s" % message)

func _create_character_animators() -> void:
	"""根据TeamBattleManager的队伍数据创建CharacterAnimator实例"""
	# 清理现有的动画器
	_cleanup_character_animators()
	
	if not team_battle_manager:
		print("[BattleAnimationController] 错误：TeamBattleManager未设置")
		return
	
	if not battle_window:
		print("[BattleAnimationController] 错误：BattleWindow未设置")
		return
	
	# 获取动画器容器
	var hero_container = battle_window.get_node("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/HeroAnimators")
	var enemy_container = battle_window.get_node("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/EnemyAnimators")
	var animation_area = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea")
	
	if not hero_container or not enemy_container:
		print("[BattleAnimationController] 错误：找不到动画器容器")
		return
	
	# 确保动画区域与容器可见并在前层
	if animation_area:
		animation_area.visible = true
		if animation_area is CanvasItem:
			animation_area.z_index = max(animation_area.z_index, 5)
	hero_container.visible = true
	enemy_container.visible = true
	if hero_container is CanvasItem:
		hero_container.z_index = max(hero_container.z_index, 10)
	if enemy_container is CanvasItem:
		enemy_container.z_index = max(enemy_container.z_index, 10)

	# 调试：输出容器几何信息
	if hero_container is Control:
		print("[BAC] HeroAnimators pos=", hero_container.global_position, ", size=", hero_container.size)
	if enemy_container is Control:
		print("[BAC] EnemyAnimators pos=", enemy_container.global_position, ", size=", enemy_container.size)

	# 创建英雄动画器
	var hero_team = _get_hero_team()
	if hero_team:
		for i in range(hero_team.size()):
			var hero_data = hero_team[i]
			var animator = _create_single_character_animator(hero_data, "hero", i)
			if animator:
				hero_container.add_child(animator)
				hero_animators.append(animator)
				# 设置位置，增加间距避免重叠
				animator.position = Vector2(0, i * 120)  # 垂直排列，增加间距
				if animator is CanvasItem:
					animator.z_index = 20
	
	# 创建敌人动画器
	for i in range(team_battle_manager.enemy_team.size()):
		var enemy_data = team_battle_manager.enemy_team[i]
		var animator = _create_single_character_animator(enemy_data, "enemy", i)
		if animator:
			enemy_container.add_child(animator)
			enemy_animators.append(animator)
			# 设置位置并镜像，增加间距避免重叠
			animator.position = Vector2(0, i * 120)  # 垂直排列，增加间距
			animator.mirror_for_enemy_layout()
			if animator is CanvasItem:
				animator.z_index = 20
	
	print("[BattleAnimationController] 创建了 %d 个英雄动画器和 %d 个敌人动画器" % [
		hero_animators.size(), enemy_animators.size()
	])
	print("[BattleAnimationController] HeroAnimators children: %d, EnemyAnimators children: %d" % [
		hero_container.get_child_count(), enemy_container.get_child_count()
	])
	
	# 调试：输出所有动画器的详细信息
	for i in range(hero_animators.size()):
		var animator = hero_animators[i]
		var sprite = animator.get_node_or_null("CharacterSprite")
		print("[BattleAnimationController] 英雄动画器%d: 全局位置=%s, 尺寸=%s, 可见=%s" % [
			i, animator.global_position, animator.size, animator.visible
		])
		if sprite:
			print("  - CharacterSprite: 位置=%s, 尺寸=%s, 颜色=%s, 可见=%s" % [
				sprite.global_position, sprite.size, sprite.color, sprite.visible
			])
		else:
			print("  - CharacterSprite: 未找到!")
		
		# 检查父容器
		var parent = animator.get_parent()
		if parent:
			print("  - 父容器: %s, 位置=%s, 可见=%s" % [
				parent.name, parent.global_position, parent.visible
			])
		else:
			print("  - 父容器: 无")
	
	for i in range(enemy_animators.size()):
		var animator = enemy_animators[i]
		var sprite = animator.get_node_or_null("CharacterSprite")
		print("[BattleAnimationController] 敌人动画器%d: 全局位置=%s, 尺寸=%s, 可见=%s" % [
			i, animator.global_position, animator.size, animator.visible
		])
		if sprite:
			print("  - CharacterSprite: 位置=%s, 尺寸=%s, 颜色=%s, 可见=%s" % [
				sprite.global_position, sprite.size, sprite.color, sprite.visible
			])
		else:
			print("  - CharacterSprite: 未找到!")
		
		# 检查父容器
		var parent = animator.get_parent()
		if parent:
			print("  - 父容器: %s, 位置=%s, 可见=%s" % [
				parent.name, parent.global_position, parent.visible
			])
		else:
			print("  - 父容器: 无")

func _create_single_character_animator(character_data: Dictionary, team_type: String, position: int) -> CharacterAnimator:
	"""创建单个角色动画器"""
	# 加载CharacterAnimator场景
	var animator_scene = preload("res://scenes/battle/CharacterAnimator.tscn")
	var animator = animator_scene.instantiate()
	
	# 初始化角色数据
	animator.initialize_character(character_data, team_type, position)
	# 启用队伍HP模式，隐藏成员血条
	if animator.has_method("set_team_pool_mode"):
		animator.set_team_pool_mode(true)
	
	# 连接动画完成信号
	if animator.has_signal("animation_completed"):
		animator.animation_completed.connect(_on_character_animation_completed_wrapper.bind(position, team_type))
	
	return animator

func _on_character_animation_completed_wrapper(animation_type: String, character_index: int, team_type: String):
	"""包装函数：处理CharacterAnimator的animation_completed信号"""
	_on_character_animation_completed(character_index, team_type, animation_type)

func _on_character_animation_completed(character_index: int, team_type: String, animation_type: String = ""):
	"""处理角色动画完成事件"""
	print("[BattleAnimationController] 角色动画完成: %s队伍第%d个角色" % [team_type, character_index])
	character_animation_completed.emit(character_index, team_type, animation_type)

func play_battle_start_animation() -> void:
	# TODO: 播放战斗开始动画
	pass

func play_turn_start_animation(turn_index: int) -> void:
	# 简单的回合开始提示动画：让当前阵营的容器闪烁并轻微抖动
	var side := current_acting_side if current_acting_side != "" else "heroes"
	var container = _get_animator_container_for_side(side)
	if container == null:
		return
	var start_pos: Vector2 = container.position
	var original_modulate: Color = container.modulate
	# 根据动画速度缩放时长
	var dur: float = 0.12 / max(animation_speed, 0.1)
	var tween = create_tween()
	# 颜色高亮
	tween.tween_property(container, "modulate", Color(1.2, 1.2, 1.0, 1.0), dur)
	# 轻微抖动
	tween.tween_property(container, "position", start_pos + Vector2(12 * (1 if side == "heroes" else -1), 0), dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(container, "position", start_pos, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# 恢复颜色
	var tween2 = create_tween()
	tween2.tween_property(container, "modulate", original_modulate, dur)
	await tween.finished
	await tween2.finished

# 测试函数 - 直接触发敌方攻击动画
func test_enemy_attack_animation():
	"""测试函数：直接触发敌方攻击动画"""
	print("[BattleAnimationController] 开始测试敌方攻击动画...")
	
	# 检查敌方动画器
	print("[BattleAnimationController] 敌方动画器数量: %d" % enemy_animators.size())
	for i in range(enemy_animators.size()):
		var animator = enemy_animators[i]
		if animator and is_instance_valid(animator):
			print("[BattleAnimationController] 敌方动画器[%d]: %s" % [i, animator.name])
			
			# 直接调用攻击动画
			if animator.has_method("play_attack_animation"):
				print("[BattleAnimationController] 播放敌方动画器[%d]的攻击动画..." % i)
				animator.play_attack_animation()
				await get_tree().create_timer(1.0).timeout  # 等待动画播放
				print("[BattleAnimationController] 敌方动画器[%d]攻击动画完成" % i)
			else:
				print("[BattleAnimationController] 敌方动画器[%d]没有play_attack_animation方法" % i)
		else:
			print("[BattleAnimationController] 敌方动画器[%d]无效" % i)
	
	print("[BattleAnimationController] 敌方攻击动画测试完成")

# 在_ready函数中添加延迟测试调用
func _delayed_test_enemy_animation():
	"""延迟测试敌方动画"""
	await get_tree().create_timer(3.0).timeout  # 等待3秒确保所有组件初始化完成
	if enemy_animators.size() > 0:
		print("[BattleAnimationController] 自动触发敌方攻击动画测试...")
		test_enemy_attack_animation()

func play_battle_end_animation(winner: String) -> void:
	# TODO: 播放战斗结束动画
	pass

func _cleanup_character_animators() -> void:
	# 清理角色动画器列表并移除容器内的所有子节点，防止跨战斗叠加
	var hero_container: Node = null
	var enemy_container: Node = null
	if battle_window:
		hero_container = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/HeroAnimators")
		enemy_container = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/EnemyAnimators")

	# 释放数组中旧的动画器
	for animator in hero_animators:
		if animator and is_instance_valid(animator):
			animator.queue_free()
	for animator in enemy_animators:
		if animator and is_instance_valid(animator):
			animator.queue_free()

	# 移除容器内所有子节点
	if hero_container:
		for child in hero_container.get_children():
			hero_container.remove_child(child)
			child.queue_free()
		# 重置容器的临时属性（位置/调制），避免上一场动画残留
		hero_container.modulate = Color(1, 1, 1, 1)
	if enemy_container:
		for child in enemy_container.get_children():
			enemy_container.remove_child(child)
			child.queue_free()
		enemy_container.modulate = Color(1, 1, 1, 1)

	# 清空数组
	hero_animators.clear()
	enemy_animators.clear()



func _find_character_animator(character_data) -> CharacterAnimator:
	"""根据角色数据在动画器中查找匹配的动画器"""
	if not character_data:
		print("[BattleAnimationController] _find_character_animator: 角色数据为空")
		return null
	
	var character_name = _safe_get_name(character_data)
	print("[BattleAnimationController] 查找角色动画器: %s" % character_name)
	
	# 首先检查英雄动画器
	for i in range(hero_animators.size()):
		var animator = hero_animators[i]
		if animator and is_instance_valid(animator):
			var animator_data = animator.get_character_data()
			var animator_name = _safe_get_name(animator_data)
			print("[BattleAnimationController] 检查英雄动画器[%d]: %s" % [i, animator_name])
			
			# 优先使用ID匹配
			if character_data.has("id") and animator_data.has("id"):
				if character_data.get("id") == animator_data.get("id"):
					print("[BattleAnimationController] 通过ID匹配找到英雄动画器: %s" % animator_name)
					return animator
			
			# 其次使用名称匹配
			if character_name != "未知" and animator_name != "未知" and character_name == animator_name:
				print("[BattleAnimationController] 通过名称匹配找到英雄动画器: %s" % animator_name)
				return animator
	
	# 然后检查敌人动画器
	for i in range(enemy_animators.size()):
		var animator = enemy_animators[i]
		if animator and is_instance_valid(animator):
			var animator_data = animator.get_character_data()
			var animator_name = _safe_get_name(animator_data)
			print("[BattleAnimationController] 检查敌人动画器[%d]: %s" % [i, animator_name])
			
			# 优先使用ID匹配
			if character_data.has("id") and animator_data.has("id"):
				if character_data.get("id") == animator_data.get("id"):
					print("[BattleAnimationController] 通过ID匹配找到敌人动画器: %s" % animator_name)
					return animator
			
			# 其次使用名称匹配
			if character_name != "未知" and animator_name != "未知" and character_name == animator_name:
				print("[BattleAnimationController] 通过名称匹配找到敌人动画器: %s" % animator_name)
				return animator
	
	print("[BattleAnimationController] 未找到匹配的动画器: %s" % character_name)
	return null
# 辅助：判断数据所属阵营
func _is_member_in_team(team: Array, data) -> bool:
	if data == null:
		return false
	var name := _safe_get_name(data)
	for m in team:
		if m.has("id") and data.has("id") and m["id"] == data["id"]:
			return true
		if name != "未知" and m.get("name", "") == name:
			return true
	return false

func _get_side_for_member(data) -> String:
	if team_battle_manager != null:
		var heroes: Array = _get_hero_team() if _get_hero_team() else []
		var enemies: Array = _get_enemy_team() if _get_enemy_team() else []
		if _is_member_in_team(heroes, data):
			return "heroes"
		if _is_member_in_team(enemies, data):
			return "enemies"
	# 兜底：使用当前行动方或默认英雄侧
	return current_acting_side if current_acting_side != "" else "heroes"

# ======= 整体动画实现 =======
func _normalize_side(side: String) -> String:
	var s = side.to_lower()
	if s.find("hero") != -1:
		return "heroes"
	if s.find("enemy") != -1:
		return "enemies"
	return s

func _get_animator_container_for_side(side: String) -> Node:
	if battle_window == null:
		return null
	var area = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea")
	if area == null:
		return null
	return area.get_node_or_null("HeroAnimators" if side == "heroes" else "EnemyAnimators")

func play_team_attack_animation_with_timing(attacker_side: String, target_side: String, damage: int, is_critical: bool):
	"""带时序控制的队伍攻击动画：攻击位移→受击闪烁→血条扣血"""
	print("[BattleAnimationController] 播放带时序的队伍攻击动画: %s -> %s" % [attacker_side, target_side])
	
	# 获取攻击方动画器
	var animators = hero_animators if attacker_side == "heroes" else enemy_animators
	
	if animators.size() == 0:
		print("[BattleAnimationController] 警告：没有找到 %s 阵营的动画器" % attacker_side)
		return
	
	# 启动所有攻击动画
	for i in range(animators.size()):
		var animator = animators[i]
		if animator and is_instance_valid(animator):
			print("[BattleAnimationController] 队员%d开始攻击动画" % (i+1))
			# 直接启动攻击动画，不等待
			_start_attack_with_impact_timing(animator, target_side, damage, is_critical)
		else:
			print("[BattleAnimationController] 警告：队员%d动画器无效" % (i+1))
	
	# 等待一个合理的时间让所有动画完成
	var total_animation_time = 1.0  # 攻击动画总时长约1秒
	await get_tree().create_timer(total_animation_time).timeout
	
	print("[BattleAnimationController] 所有队员攻击动画和受击效果完成")

func _start_attack_with_impact_timing(attacker_animator: Node, target_side: String, damage: int, is_critical: bool):
	"""启动单个角色的攻击动画，在冲击时触发受击效果（非协程版本）"""
	if not attacker_animator:
		return
		
	# 启动攻击动画
	if attacker_animator.has_method("play_attack_animation"):
		attacker_animator.play_attack_animation()
		
		# 设置定时器在冲击时触发受击效果
		var impact_delay = 0.35  # 攻击动画到达冲击点的时间
		get_tree().create_timer(impact_delay).timeout.connect(_on_attack_impact.bind(target_side, damage, is_critical), CONNECT_ONE_SHOT)

func _on_attack_impact(target_side: String, damage: int, is_critical: bool):
	"""攻击冲击时的回调函数"""
	_trigger_hit_effects_at_impact(target_side, damage, is_critical)

func _trigger_hit_effects_at_impact(target_side: String, damage: int, is_critical: bool):
	"""在攻击冲击时触发受击效果：闪烁→血条扣血"""
	print("[BattleAnimationController] 攻击冲击时触发受击效果: %s" % target_side)
	
	# 1. 同时更新血量数据和UI
	_update_team_health_data(target_side, damage)
	_update_team_health_ui(target_side)
	_show_team_damage_number(target_side, damage, is_critical)
	
	# 2. 播放受击闪烁动画（不等待完成）
	play_team_damage_animation(target_side, is_critical)
	
	print("[BattleAnimationController] 受击效果触发完成: %s" % target_side)

func play_team_attack_animation(side: String):
	"""队伍普攻动画：所有队员同时播放攻击动画"""
	print("[BattleAnimationController] 播放队伍普攻动画: %s" % side)
	print("[BattleAnimationController] 当前英雄动画器数量: %d, 敌人动画器数量: %d" % [hero_animators.size(), enemy_animators.size()])
	
	# 获取对应阵营的所有动画器
	var animators = hero_animators if side == "heroes" else enemy_animators
	
	if animators.size() == 0:
		print("[BattleAnimationController] 警告：没有找到 %s 阵营的动画器" % side)
		print("[BattleAnimationController] 尝试重新创建动画器...")
		_create_character_animators()
		animators = hero_animators if side == "heroes" else enemy_animators
		if animators.size() == 0:
			print("[BattleAnimationController] 错误：重新创建后仍然没有动画器")
			return
		else:
			print("[BattleAnimationController] 重新创建成功，%s 阵营动画器数量: %d" % [side, animators.size()])
	
	# 让所有队员同时播放攻击动画
	var animation_tasks = []
	for i in range(animators.size()):
		var animator = animators[i]
		if animator and is_instance_valid(animator):
			print("[BattleAnimationController] 队员%d开始攻击动画" % (i+1))
			animator.play_attack_animation()
			animation_tasks.append(animator.animation_completed)
		else:
			print("[BattleAnimationController] 警告：队员%d动画器无效" % (i+1))
	
	# 等待所有攻击动画完成
	if animation_tasks.size() > 0:
		print("[BattleAnimationController] 等待%d个队员攻击动画完成..." % animation_tasks.size())
		for task in animation_tasks:
			await task
		print("[BattleAnimationController] 所有队员攻击动画完成")
	
	# 移除多余的容器位移动画，避免与个人攻击动画重复
	# 个人攻击动画已经提供了足够的视觉效果，无需额外的容器位移

func play_team_damage_animation(side: String, is_critical: bool = false):
	"""队伍受击动画 - 统一的纯视觉闪烁效果
	
	此方法负责：
	1. 遍历指定队伍的所有成员
	2. 并行触发每个成员的 play_hit_animation（纯视觉闪烁）
	3. 等待所有闪烁动画完成
	
	注意：此方法不处理血量更新和伤害数字，仅负责视觉反馈
	"""
	var container = _get_animator_container_for_side(side)
	if container == null:
		return

	print("[BattleAnimationController] 播放队伍受击动画: %s%s" % [side, ("(暴击)" if is_critical else "")])

	# 获取对应队伍的动画器列表
	var animators = hero_animators if side == "heroes" else enemy_animators
	var flash_tasks: Array = []
	
	# 并行触发全员受击闪烁（纯视觉效果，不改血量、不显示数字）
	for animator in animators:
		if animator and is_instance_valid(animator) and animator.has_method("play_hit_animation"):
			animator.play_hit_animation(is_critical)
			flash_tasks.append(animator.animation_completed)

	# 记录动画时间用于调试
	var current_timestamp = Time.get_ticks_msec() / 1000.0
	last_damage_animation_time[side] = current_timestamp
	
	# 等待所有成员闪烁完成
	for task in flash_tasks:
		await task

# ============ 小队受伤处理逻辑 ============

func apply_team_damage_with_effects(target_side: String, damage: int, is_critical: bool = false):
	"""完整的小队受伤处理 - 包括血量更新、UI更新和视觉效果
	
	此方法负责：
	1. 更新小队血量数据
	2. 更新UI显示（血条、HP标签）
	3. 显示伤害数字
	4. 播放受击闪烁动画
	
	这是小队战斗模式下的核心受伤处理方法
	"""
	print("[BattleAnimationController] 开始处理小队受伤: %s, 伤害: %d%s" % [
		target_side, damage, ("(暴击)" if is_critical else "")
	])
	
	# 1. 更新小队血量数据
	_update_team_health_data(target_side, damage)
	
	# 2. 更新UI显示
	_update_team_health_ui(target_side)
	
	# 3. 显示伤害数字（选择一个代表性角色显示）
	_show_team_damage_number(target_side, damage, is_critical)
	
	# 4. 播放受击闪烁动画
	await play_team_damage_animation(target_side, is_critical)
	
	print("[BattleAnimationController] 小队受伤处理完成: %s" % target_side)

func _update_team_health_data(target_side: String, damage: int):
	"""更新小队血量数据"""
	if not team_battle_manager:
		print("[BattleAnimationController] 错误：TeamBattleManager未设置")
		return
	
	# 获取当前血量
	var current_hp: int
	var max_hp: int
	
	if target_side == "heroes":
		current_hp = team_battle_manager.hero_team_hp_current
		max_hp = team_battle_manager.hero_team_hp_max
	else:
		current_hp = team_battle_manager.enemy_team_hp_current
		max_hp = team_battle_manager.enemy_team_hp_max
	
	# 计算新血量
	var new_hp = max(0, current_hp - damage)
	
	# 更新血量数据
	if target_side == "heroes":
		team_battle_manager.hero_team_hp_current = new_hp
	else:
		team_battle_manager.enemy_team_hp_current = new_hp
	
	print("[BattleAnimationController] %s 血量更新: %d/%d -> %d/%d" % [
		target_side, current_hp, max_hp, new_hp, max_hp
	])

func _update_team_health_ui(target_side: String):
	"""更新小队血量UI显示"""
	if not battle_window:
		print("[BattleAnimationController] 错误：BattleWindow未设置")
		return
	
	# 获取血量数据
	var current_hp: int
	var max_hp: int
	
	if target_side == "heroes":
		current_hp = team_battle_manager.hero_team_hp_current
		max_hp = team_battle_manager.hero_team_hp_max
	else:
		current_hp = team_battle_manager.enemy_team_hp_current
		max_hp = team_battle_manager.enemy_team_hp_max
	
	# 更新血条和标签
	if battle_window.has_method("_update_team_health_bars"):
		var hero_current = team_battle_manager.hero_team_hp_current
		var hero_max = team_battle_manager.hero_team_hp_max
		var enemy_current = team_battle_manager.enemy_team_hp_current
		var enemy_max = team_battle_manager.enemy_team_hp_max
		
		battle_window._update_team_health_bars(hero_current, hero_max, enemy_current, enemy_max)
	
	# 更新HP标签
	var hp_label_path = "hero_hp_label" if target_side == "heroes" else "enemy_hp_label"
	var hp_label = battle_window.get(hp_label_path)
	if hp_label:
		hp_label.text = "队伍HP: %d/%d" % [current_hp, max_hp]
	
	print("[BattleAnimationController] %s UI更新完成: %d/%d" % [target_side, current_hp, max_hp])

func _show_team_damage_number(target_side: String, damage: int, is_critical: bool):
	"""显示小队伤害数字（选择一个代表性角色显示）"""
	var animators = hero_animators if target_side == "heroes" else enemy_animators
	
	if animators.size() > 0:
		# 选择第一个有效的动画器显示伤害数字
		for animator in animators:
			if animator and is_instance_valid(animator) and animator.has_method("show_damage_number"):
				animator.show_damage_number(damage, is_critical)
				print("[BattleAnimationController] 在 %s 第一个角色上显示伤害数字: %d%s" % [
					target_side, damage, ("(暴击)" if is_critical else "")
				])
				break

func _get_hero_team():
	"""安全地获取英雄队伍数据"""
	if not team_battle_manager:
		return null
	if team_battle_manager.has_method("get") and team_battle_manager.has_method("has"):
		# 如果是字典类型的访问
		if team_battle_manager.has("hero_team"):
			return team_battle_manager.get("hero_team")
	elif "hero_team" in team_battle_manager:
		# 如果是对象属性访问
		return team_battle_manager.hero_team
	return null

func _get_enemy_team():
	"""安全地获取敌人队伍数据"""
	if not team_battle_manager:
		return null
	if team_battle_manager.has_method("get") and team_battle_manager.has_method("has"):
		# 如果是字典类型的访问
		if team_battle_manager.has("enemy_team"):
			return team_battle_manager.get("enemy_team")
	elif "enemy_team" in team_battle_manager:
		# 如果是对象属性访问
		return team_battle_manager.enemy_team
	return null

func _get_team_animators(side: String) -> Array:
	"""获取指定阵营的动画器数组"""
	return hero_animators if side == "heroes" else enemy_animators