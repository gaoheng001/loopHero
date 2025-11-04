# BattleEffectsManager.gd
# 回合攻击表现系统 - 特效管理器
# 负责技能特效、状态效果、环境效果的显示和管理

class_name BattleEffectsManager
extends Node2D

# 特效信号
signal effect_started(effect_type: String, target: Node)
signal effect_finished(effect_type: String, target: Node)

# 特效类型枚举
enum EffectType {
	SKILL_CAST,      # 技能释放特效
	SKILL_HIT,       # 技能命中特效
	STATUS_APPLY,    # 状态效果应用
	STATUS_TICK,     # 状态效果持续
	STATUS_REMOVE,   # 状态效果移除
	ENVIRONMENT,     # 环境特效
	BUFF,           # 增益效果
	DEBUFF          # 减益效果
}

# 特效配置
var effect_configs: Dictionary = {
	"fire_skill": {
		"type": EffectType.SKILL_CAST,
		"color": Color.RED,
		"particles": true,
		"duration": 1.0,
		"scale_effect": true
	},
	"ice_skill": {
		"type": EffectType.SKILL_CAST,
		"color": Color.CYAN,
		"particles": true,
		"duration": 1.2,
		"scale_effect": true
	},
	"heal_skill": {
		"type": EffectType.SKILL_CAST,
		"color": Color.GREEN,
		"particles": true,
		"duration": 0.8,
		"scale_effect": false
	},
	"poison": {
		"type": EffectType.STATUS_APPLY,
		"color": Color.PURPLE,
		"particles": false,
		"duration": 0.5,
		"overlay": true
	},
	"burn": {
		"type": EffectType.STATUS_APPLY,
		"color": Color.ORANGE_RED,
		"particles": true,
		"duration": 0.6,
		"overlay": true
	},
	"shield": {
		"type": EffectType.BUFF,
		"color": Color.BLUE,
		"particles": false,
		"duration": 0.4,
		"overlay": true
	}
}

# 活跃特效列表
var active_effects: Array[Dictionary] = []

# 特效对象池
var effect_pools: Dictionary = {}

# 动画速度
var animation_speed: float = 1.0

func _ready():
	"""初始化特效管理器"""
	_initialize_effect_pools()
	print("[BattleEffectsManager] 特效管理器初始化完成")

func _initialize_effect_pools():
	"""初始化特效对象池"""
	for effect_name in effect_configs.keys():
		effect_pools[effect_name] = []

# ============ 公共接口 ============

func play_skill_effect(skill_id: String, caster: Node, targets: Array, effect_data: Dictionary = {}):
	"""播放技能特效"""
	emit_signal("effect_started", "skill", caster)
	
	# 播放施法者特效
	_play_caster_effect(skill_id, caster, effect_data)
	
	# 延迟播放目标特效
	await get_tree().create_timer(0.3 / animation_speed).timeout
	
	for target in targets:
		if target and is_instance_valid(target):
			_play_target_effect(skill_id, target, effect_data)
	
	# 等待特效完成
	var effect_duration = effect_configs.get(skill_id, {}).get("duration", 1.0)
	await get_tree().create_timer(effect_duration / animation_speed).timeout
	
	emit_signal("effect_finished", "skill", caster)

func apply_status_effect(status_id: String, target: Node, duration: float = -1):
	"""应用状态效果"""
	if not target or not is_instance_valid(target):
		return
	
	emit_signal("effect_started", "status", target)
	
	var effect_data = {
		"status_id": status_id,
		"target": target,
		"start_time": Time.get_time_dict_from_system(),
		"duration": duration,
		"visual_node": null
	}
	
	# 创建状态效果视觉
	var visual_node = _create_status_visual(status_id, target)
	if visual_node:
		effect_data.visual_node = visual_node
		active_effects.append(effect_data)
	
	print("[BattleEffectsManager] 应用状态效果: %s 到 %s" % [status_id, target.name])

func remove_status_effect(status_id: String, target: Node):
	"""移除状态效果"""
	if not target or not is_instance_valid(target):
		return
	
	for i in range(active_effects.size() - 1, -1, -1):
		var effect = active_effects[i]
		if effect.status_id == status_id and effect.target == target:
			_remove_status_visual(effect)
			active_effects.remove_at(i)
			emit_signal("effect_finished", "status", target)
			print("[BattleEffectsManager] 移除状态效果: %s 从 %s" % [status_id, target.name])
			break

func play_environment_effect(effect_type: String, position: Vector2, scale: float = 1.0):
	"""播放环境特效"""
	emit_signal("effect_started", "environment", null)
	
	var effect_node = _create_environment_effect(effect_type, position, scale)
	if effect_node:
		add_child(effect_node)
		
		# 播放特效动画
		var tween = create_tween()
		tween.set_parallel(true)
		
		# 缩放动画
		tween.tween_property(effect_node, "scale", Vector2.ONE * scale, 0.3 / animation_speed)
		tween.tween_property(effect_node, "modulate:a", 0.0, 1.0 / animation_speed)
		
		await tween.finished
		effect_node.queue_free()
	
	emit_signal("effect_finished", "environment", null)

func update_status_effects():
	"""更新状态效果（每帧调用）"""
	for i in range(active_effects.size() - 1, -1, -1):
		var effect = active_effects[i]
		
		# 检查目标是否仍然有效
		if not effect.target or not is_instance_valid(effect.target):
			_remove_status_visual(effect)
			active_effects.remove_at(i)
			continue
		
		# 更新状态效果视觉
		_update_status_visual(effect)
		
		# 检查持续时间
		if effect.duration > 0:
			var elapsed = Time.get_time_dict_from_system()["second"] - effect.start_time["second"]
			if elapsed >= effect.duration:
				remove_status_effect(effect.status_id, effect.target)

func clear_all_effects():
	"""清除所有特效"""
	for effect in active_effects:
		_remove_status_visual(effect)
	active_effects.clear()
	
	# 清理子节点中的特效
	for child in get_children():
		if child.has_meta("is_effect"):
			child.queue_free()

func set_animation_speed(speed: float):
	"""设置动画速度"""
	animation_speed = clamp(speed, 0.1, 5.0)

# ============ 内部方法 ============

func _play_caster_effect(skill_id: String, caster: Node, effect_data: Dictionary):
	"""播放施法者特效"""
	var config = effect_configs.get(skill_id, {})
	
	if config.get("scale_effect", false):
		# 缩放特效
		var original_scale = caster.scale
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(caster, "scale", original_scale * 1.2, 0.2 / animation_speed)
		tween.tween_property(caster, "scale", original_scale, 0.3 / animation_speed)
	
	if config.get("particles", false):
		# 粒子特效
		_create_particle_effect(skill_id, caster.global_position, config.get("color", Color.WHITE))

func _play_target_effect(skill_id: String, target: Node, effect_data: Dictionary):
	"""播放目标特效"""
	var config = effect_configs.get(skill_id, {})
	
	# 闪烁特效
	var original_modulate = target.modulate
	var effect_color = config.get("color", Color.WHITE)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "modulate", effect_color, 0.1 / animation_speed)
	tween.tween_property(target, "modulate", original_modulate, 0.2 / animation_speed)
	
	if config.get("particles", false):
		_create_particle_effect(skill_id + "_hit", target.global_position, effect_color)

func _create_status_visual(status_id: String, target: Node) -> Node:
	"""创建状态效果视觉"""
	var config = effect_configs.get(status_id, {})
	
	if config.get("overlay", false):
		# 创建覆盖层
		var overlay = ColorRect.new()
		overlay.size = Vector2(50, 50)
		overlay.color = config.get("color", Color.WHITE)
		overlay.color.a = 0.3
		overlay.position = target.global_position + Vector2(-25, -60)
		overlay.set_meta("is_effect", true)
		overlay.set_meta("status_id", status_id)
		
		add_child(overlay)
		
		# 添加脉冲动画
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(overlay, "modulate:a", 0.1, 0.5 / animation_speed)
		tween.tween_property(overlay, "modulate:a", 0.3, 0.5 / animation_speed)
		
		return overlay
	
	return null

func _update_status_visual(effect: Dictionary):
	"""更新状态效果视觉"""
	var visual_node = effect.visual_node
	if visual_node and is_instance_valid(visual_node) and effect.target:
		# 更新位置跟随目标
		visual_node.position = effect.target.global_position + Vector2(-25, -60)

func _remove_status_visual(effect: Dictionary):
	"""移除状态效果视觉"""
	var visual_node = effect.visual_node
	if visual_node and is_instance_valid(visual_node):
		visual_node.queue_free()

func _create_particle_effect(effect_name: String, position: Vector2, color: Color):
	"""创建粒子特效"""
	# 简单的粒子效果实现
	for i in range(5):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = color
		particle.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		particle.set_meta("is_effect", true)
		
		add_child(particle)
		
		# 粒子动画
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", particle.position + Vector2(randf_range(-30, 30), randf_range(-50, -10)), 1.0 / animation_speed)
		tween.tween_property(particle, "modulate:a", 0.0, 1.0 / animation_speed)
		tween.tween_property(particle, "scale", Vector2.ZERO, 1.0 / animation_speed)
		
		await tween.finished
		particle.queue_free()

func _create_environment_effect(effect_type: String, position: Vector2, scale: float) -> Node:
	"""创建环境特效"""
	var effect_node = ColorRect.new()
	effect_node.size = Vector2(100, 100) * scale
	effect_node.position = position - effect_node.size / 2
	effect_node.color = Color.YELLOW
	effect_node.color.a = 0.5
	effect_node.set_meta("is_effect", true)
	
	return effect_node

# ============ 预设特效方法 ============

func play_attack_effect(attacker: Node, target: Node):
	"""播放攻击特效"""
	play_skill_effect("basic_attack", attacker, [target])

func play_critical_hit_effect(target: Node):
	"""播放暴击特效"""
	play_environment_effect("critical", target.global_position, 1.5)

func play_heal_effect(target: Node, amount: int):
	"""播放治疗特效"""
	play_skill_effect("heal_skill", target, [target], {"amount": amount})

func play_miss_effect(target: Node):
	"""播放未命中特效"""
	play_environment_effect("miss", target.global_position, 0.8)

func play_block_effect(target: Node):
	"""播放格挡特效"""
	apply_status_effect("shield", target, 1.0)

# ============ 状态效果管理 ============

func apply_poison(target: Node, duration: float = 5.0):
	"""应用中毒效果"""
	apply_status_effect("poison", target, duration)

func apply_burn(target: Node, duration: float = 3.0):
	"""应用燃烧效果"""
	apply_status_effect("burn", target, duration)

func apply_shield(target: Node, duration: float = 10.0):
	"""应用护盾效果"""
	apply_status_effect("shield", target, duration)

func remove_poison(target: Node):
	"""移除中毒效果"""
	remove_status_effect("poison", target)

func remove_burn(target: Node):
	"""移除燃烧效果"""
	remove_status_effect("burn", target)

func remove_shield(target: Node):
	"""移除护盾效果"""
	remove_status_effect("shield", target)

func get_active_status_effects(target: Node) -> Array:
	"""获取目标的活跃状态效果"""
	var target_effects = []
	for effect in active_effects:
		if effect.target == target:
			target_effects.append(effect.status_id)
	return target_effects

func has_status_effect(target: Node, status_id: String) -> bool:
	"""检查目标是否有指定状态效果"""
	for effect in active_effects:
		if effect.target == target and effect.status_id == status_id:
			return true
	return false