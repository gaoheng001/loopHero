# DamageNumber.gd
# 伤害数字组件 - 显示飞出的伤害数字和暴击效果
# 支持不同类型的数字显示：伤害、治疗、暴击等

class_name DamageNumber
extends Control

# 伤害数字信号
signal animation_started
signal animation_completed
signal number_disappeared

# 数字类型枚举
enum NumberType {
	DAMAGE,      # 普通伤害
	CRITICAL,    # 暴击伤害
	HEAL,        # 治疗
	MISS,        # 未命中
	BLOCK,       # 格挡
	ABSORB       # 吸收
}

# UI组件
var number_label: Label
var background_panel: Panel

# 动画配置
var number_type: NumberType = NumberType.DAMAGE
var damage_value: int = 0
var animation_speed: float = 1.0
var is_animating: bool = false

# 样式配置
var type_configs: Dictionary = {
	NumberType.DAMAGE: {
		"color": Color.RED,
		"font_size": 24,
		"outline_color": Color.BLACK,
		"outline_size": 2,
		"scale": Vector2(1.0, 1.0),
		"prefix": "",
		"suffix": ""
	},
	NumberType.CRITICAL: {
		"color": Color.YELLOW,
		"font_size": 32,
		"outline_color": Color.RED,
		"outline_size": 3,
		"scale": Vector2(1.3, 1.3),
		"prefix": "",
		"suffix": "!"
	},
	NumberType.HEAL: {
		"color": Color.GREEN,
		"font_size": 26,
		"outline_color": Color.DARK_GREEN,
		"outline_size": 2,
		"scale": Vector2(1.1, 1.1),
		"prefix": "+",
		"suffix": ""
	},
	NumberType.MISS: {
		"color": Color.GRAY,
		"font_size": 20,
		"outline_color": Color.BLACK,
		"outline_size": 1,
		"scale": Vector2(0.9, 0.9),
		"prefix": "",
		"suffix": ""
	},
	NumberType.BLOCK: {
		"color": Color.CYAN,
		"font_size": 22,
		"outline_color": Color.BLUE,
		"outline_size": 2,
		"scale": Vector2(1.0, 1.0),
		"prefix": "",
		"suffix": ""
	},
	NumberType.ABSORB: {
		"color": Color.PURPLE,
		"font_size": 24,
		"outline_color": Color.DARK_MAGENTA,
		"outline_size": 2,
		"scale": Vector2(1.0, 1.0),
		"prefix": "",
		"suffix": ""
	}
}

func _ready():
	_setup_ui_components()
	_setup_default_appearance()

func _setup_ui_components():
	"""设置UI组件"""
	# 设置控件大小
	size = Vector2(120, 60)
	
	# 创建背景面板（可选）
	background_panel = Panel.new()
	background_panel.name = "BackgroundPanel"
	background_panel.size = size
	background_panel.modulate = Color(1, 1, 1, 0)  # 透明背景
	add_child(background_panel)
	
	# 创建数字标签
	number_label = Label.new()
	number_label.name = "NumberLabel"
	number_label.size = size
	number_label.text = "0"
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(number_label)

func _setup_default_appearance():
	"""设置默认外观"""
	# 初始状态为不可见
	modulate = Color.TRANSPARENT
	visible = false

func show_damage_number(value: int, type: NumberType = NumberType.DAMAGE, start_position: Vector2 = Vector2.ZERO):
	"""显示伤害数字"""
	if is_animating:
		return  # 如果正在播放动画，跳过
	
	damage_value = value
	number_type = type
	
	# 设置位置
	position = start_position
	
	# 应用样式配置
	_apply_number_style()
	
	# 设置数字文本
	_set_number_text()
	
	# 显示并播放动画
	visible = true
	_play_damage_animation()

func _apply_number_style():
	"""应用数字样式"""
	var config = type_configs.get(number_type, type_configs[NumberType.DAMAGE])
	
	# 设置字体颜色
	number_label.add_theme_color_override("font_color", config["color"])
	
	# 设置字体大小
	number_label.add_theme_font_size_override("font_size", config["font_size"])
	
	# 设置描边
	number_label.add_theme_color_override("font_outline_color", config["outline_color"])
	number_label.add_theme_constant_override("outline_size", config["outline_size"])
	
	# 设置缩放
	scale = config["scale"]

func _set_number_text():
	"""设置数字文本"""
	var config = type_configs.get(number_type, type_configs[NumberType.DAMAGE])
	var prefix = config.get("prefix", "")
	var suffix = config.get("suffix", "")
	
	match number_type:
		NumberType.MISS:
			number_label.text = "MISS"
		NumberType.BLOCK:
			number_label.text = "BLOCK"
		NumberType.ABSORB:
			number_label.text = "ABSORB"
		_:
			number_label.text = prefix + str(damage_value) + suffix

func _play_damage_animation():
	"""播放伤害数字动画"""
	if is_animating:
		return
	
	is_animating = true
	emit_signal("animation_started")
	
	# 根据数字类型播放不同动画
	match number_type:
		NumberType.CRITICAL:
			await _play_critical_animation()
		NumberType.HEAL:
			await _play_heal_animation()
		NumberType.MISS:
			await _play_miss_animation()
		NumberType.BLOCK:
			await _play_block_animation()
		NumberType.ABSORB:
			await _play_absorb_animation()
		_:
			await _play_normal_damage_animation()
	
	is_animating = false
	emit_signal("animation_completed")
	emit_signal("number_disappeared")

func _play_normal_damage_animation():
	"""播放普通伤害动画"""
	# 初始状态
	modulate = Color.TRANSPARENT
	var original_position = position
	
	# 创建动画序列
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 阶段1：出现 + 向上移动
	tween.tween_property(self, "modulate", Color.WHITE, 0.2 / animation_speed)
	tween.tween_property(self, "position:y", original_position.y - 30, 0.3 / animation_speed)
	
	# 等待显示
	await get_tree().create_timer(0.5 / animation_speed).timeout
	
	# 阶段2：继续上升 + 淡出
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "position:y", original_position.y - 80, 0.8 / animation_speed)
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.8 / animation_speed)
	
	await fade_tween.finished
	
	# 重置状态
	visible = false
	position = original_position

func _play_critical_animation():
	"""播放暴击动画"""
	# 初始状态
	modulate = Color.TRANSPARENT
	var original_position = position
	var original_scale = scale
	
	# 创建暴击动画序列
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 阶段1：爆炸式出现
	tween.tween_property(self, "modulate", Color.WHITE, 0.1 / animation_speed)
	tween.tween_property(self, "scale", original_scale * 1.5, 0.15 / animation_speed)
	
	await get_tree().create_timer(0.15 / animation_speed).timeout
	
	# 阶段2：震动效果
	for i in range(3):
		var shake_tween = create_tween()
		shake_tween.set_parallel(true)
		shake_tween.tween_property(self, "position:x", original_position.x + 5, 0.05 / animation_speed)
		shake_tween.tween_property(self, "position:x", original_position.x - 5, 0.05 / animation_speed)
		shake_tween.tween_property(self, "position:x", original_position.x, 0.05 / animation_speed)
		await shake_tween.finished
	
	# 阶段3：缩放回正常 + 上升
	var move_tween = create_tween()
	move_tween.set_parallel(true)
	move_tween.tween_property(self, "scale", original_scale, 0.2 / animation_speed)
	move_tween.tween_property(self, "position:y", original_position.y - 50, 0.5 / animation_speed)
	
	await get_tree().create_timer(0.3 / animation_speed).timeout
	
	# 阶段4：淡出
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "position:y", original_position.y - 100, 0.7 / animation_speed)
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.7 / animation_speed)
	
	await fade_tween.finished
	
	# 重置状态
	visible = false
	position = original_position
	scale = original_scale

func _play_heal_animation():
	"""播放治疗动画"""
	# 初始状态
	modulate = Color.TRANSPARENT
	var original_position = position
	
	# 创建治疗动画序列
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 阶段1：从下方飞入
	position.y += 20
	tween.tween_property(self, "modulate", Color.WHITE, 0.2 / animation_speed)
	tween.tween_property(self, "position:y", original_position.y, 0.3 / animation_speed)
	
	# 阶段2：发光效果
	await get_tree().create_timer(0.3 / animation_speed).timeout
	
	var glow_tween = create_tween()
	glow_tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.2 / animation_speed)
	glow_tween.tween_property(self, "modulate", Color.WHITE, 0.2 / animation_speed)
	
	await glow_tween.finished
	
	# 阶段3：向上淡出
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "position:y", original_position.y - 60, 0.8 / animation_speed)
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.8 / animation_speed)
	
	await fade_tween.finished
	
	# 重置状态
	visible = false
	position = original_position

func _play_miss_animation():
	"""播放未命中动画"""
	# 初始状态
	modulate = Color.TRANSPARENT
	var original_position = position
	
	# 创建未命中动画序列
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 阶段1：快速出现
	tween.tween_property(self, "modulate", Color.WHITE, 0.1 / animation_speed)
	
	# 阶段2：左右摇摆
	await get_tree().create_timer(0.1 / animation_speed).timeout
	
	for i in range(2):
		var sway_tween = create_tween()
		sway_tween.set_parallel(true)
		sway_tween.tween_property(self, "position:x", original_position.x + 15, 0.15 / animation_speed)
		sway_tween.tween_property(self, "position:x", original_position.x - 15, 0.15 / animation_speed)
		sway_tween.tween_property(self, "position:x", original_position.x, 0.15 / animation_speed)
		await sway_tween.finished
	
	# 阶段3：快速淡出
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3 / animation_speed)
	
	await fade_tween.finished
	
	# 重置状态
	visible = false
	position = original_position

func _play_block_animation():
	"""播放格挡动画"""
	# 初始状态
	modulate = Color.TRANSPARENT
	var original_position = position
	var original_scale = scale
	
	# 创建格挡动画序列
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 阶段1：盾牌效果（快速放大）
	tween.tween_property(self, "modulate", Color.WHITE, 0.1 / animation_speed)
	tween.tween_property(self, "scale", original_scale * 1.2, 0.1 / animation_speed)
	
	await get_tree().create_timer(0.1 / animation_speed).timeout
	
	# 阶段2：闪烁效果
	for i in range(2):
		var flash_tween = create_tween()
		flash_tween.tween_property(self, "modulate", Color(1.5, 1.5, 2.0, 1.0), 0.1 / animation_speed)
		flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1 / animation_speed)
		await flash_tween.finished
	
	# 阶段3：缩放回正常 + 淡出
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "scale", original_scale, 0.2 / animation_speed)
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5 / animation_speed)
	
	await fade_tween.finished
	
	# 重置状态
	visible = false
	position = original_position
	scale = original_scale

func _play_absorb_animation():
	"""播放吸收动画"""
	# 初始状态
	modulate = Color.TRANSPARENT
	var original_position = position
	
	# 创建吸收动画序列
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 阶段1：螺旋出现
	tween.tween_property(self, "modulate", Color.WHITE, 0.2 / animation_speed)
	
	# 阶段2：螺旋移动
	var spiral_duration = 0.8 / animation_speed
	var spiral_radius = 30
	var spiral_steps = 16
	
	for i in range(spiral_steps):
		var angle = (i / float(spiral_steps)) * PI * 2 * 2  # 两圈
		var radius = spiral_radius * (1.0 - i / float(spiral_steps))  # 逐渐缩小
		var spiral_pos = original_position + Vector2(cos(angle) * radius, sin(angle) * radius)
		
		var step_tween = create_tween()
		step_tween.tween_property(self, "position", spiral_pos, spiral_duration / spiral_steps)
		await step_tween.finished
	
	# 阶段3：回到中心并淡出
	var final_tween = create_tween()
	final_tween.set_parallel(true)
	final_tween.tween_property(self, "position", original_position, 0.2 / animation_speed)
	final_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3 / animation_speed)
	
	await final_tween.finished
	
	# 重置状态
	visible = false
	position = original_position

# ============ 公共接口 ============

func set_animation_speed(speed: float):
	"""设置动画播放速度"""
	animation_speed = clamp(speed, 0.1, 3.0)

func is_playing_animation() -> bool:
	"""检查是否正在播放动画"""
	return is_animating

func stop_animation():
	"""停止当前动画"""
	if is_animating:
		# 停止所有补间动画
		var tweens = get_tree().get_nodes_in_group("tween")
		for tween in tweens:
			if tween.get_parent() == self:
				tween.kill()
		
		# 重置状态
		is_animating = false
		visible = false
		modulate = Color.TRANSPARENT

func reset_to_pool():
	"""重置到对象池状态"""
	stop_animation()
	damage_value = 0
	number_type = NumberType.DAMAGE
	position = Vector2.ZERO
	scale = Vector2.ONE
	modulate = Color.TRANSPARENT
	visible = false

# ============ 静态工厂方法 ============

static func create_damage_number(value: int, is_critical: bool = false) -> DamageNumber:
	"""创建伤害数字实例"""
	var damage_number = DamageNumber.new()
	var type = NumberType.CRITICAL if is_critical else NumberType.DAMAGE
	return damage_number

static func create_heal_number(value: int) -> DamageNumber:
	"""创建治疗数字实例"""
	var damage_number = DamageNumber.new()
	return damage_number

static func create_miss_number() -> DamageNumber:
	"""创建未命中数字实例"""
	var damage_number = DamageNumber.new()
	return damage_number

static func create_block_number() -> DamageNumber:
	"""创建格挡数字实例"""
	var damage_number = DamageNumber.new()
	return damage_number