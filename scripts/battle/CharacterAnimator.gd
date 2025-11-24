# CharacterAnimator.gd
# 角色动画器 - 负责单个角色的所有动画表现
# 包括攻击动画、受击动画、技能动画、血量条更新等

class_name CharacterAnimator
extends Control

# 角色动画信号
signal animation_started(animation_type: String)
signal animation_completed(animation_type: String)
signal health_changed(current_hp: int, max_hp: int)
signal character_defeated

# UI组件
var character_sprite: ColorRect
var health_bar: ProgressBar
var character_label: Label
var status_icons_container: HBoxContainer
var ziling_animated: AnimatedSprite2D

# 伤害数字池引用
var damage_number_pool: DamageNumberPool

# 角色数据
var character_data: Dictionary = {}
var team_type: String = ""  # "hero" 或 "enemy"
var position_index: int = 0
var original_position: Vector2
var original_scale: Vector2
var original_color: Color
var original_modulate: Color
var original_sprite_position: Vector2

# 新增：补充声明，避免未定义变量导致编译报错
var health_label: Label
var current_animation: String = ""
var animation_speed: float = 1.0
var is_highlighted: bool = false
var team_pool_mode: bool = false

func _ready():
	_setup_ui_components()
	_setup_default_appearance()
	_setup_damage_number_pool()

func _setup_ui_components():
	"""设置UI组件"""
	# 设置CharacterAnimator自身的尺寸
	size = Vector2(80, 120)  # 确保有足够空间容纳所有UI元素
	
	# 创建或获取主要的角色精灵
	character_sprite = (get_node_or_null("CharacterSprite") as ColorRect)
	if character_sprite == null:
		character_sprite = ColorRect.new()
		character_sprite.name = "CharacterSprite"
		character_sprite.size = Vector2(80, 80)
		# 不设置颜色，由initialize_character方法控制
		add_child(character_sprite)

	# 获取或创建紫菱 AnimatedSprite2D（在场景中为占位节点 ZilingAnimated）
	ziling_animated = (get_node_or_null("ZilingAnimated") as AnimatedSprite2D)
	if ziling_animated == null:
		ziling_animated = AnimatedSprite2D.new()
		ziling_animated.name = "ZilingAnimated"
		ziling_animated.visible = false
		add_child(ziling_animated)
	
	# 创建或获取血量条
	health_bar = (get_node_or_null("HealthBar") as ProgressBar)
	if health_bar == null:
		health_bar = ProgressBar.new()
		health_bar.name = "HealthBar"
		health_bar.size = Vector2(80, 8)
		health_bar.position = Vector2(0, -15)
		add_child(health_bar)
	# 统一初始化血量条属性（防重复创建时漏配）
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	
	# 创建或获取血量文本标签
	health_label = (get_node_or_null("HealthLabel") as Label)
	if health_label == null:
		health_label = Label.new()
		health_label.name = "HealthLabel"
		health_label.size = Vector2(80, 16)
		health_label.position = Vector2(0, -28)
		health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		health_label.add_theme_font_size_override("font_size", 10)
		add_child(health_label)
	
	# 创建或获取角色名称标签
	character_label = (get_node_or_null("CharacterLabel") as Label)
	if character_label == null:
		character_label = Label.new()
		character_label.name = "CharacterLabel"
		character_label.size = Vector2(80, 20)
		character_label.position = Vector2(0, 85)
		character_label.text = "角色"
		character_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		character_label.add_theme_font_size_override("font_size", 12)
		add_child(character_label)
	
	# 创建或获取状态图标容器
	status_icons_container = (get_node_or_null("StatusIcons") as HBoxContainer)
	if status_icons_container == null:
		status_icons_container = HBoxContainer.new()
		status_icons_container.name = "StatusIcons"
		status_icons_container.size = Vector2(80, 16)
		status_icons_container.position = Vector2(0, -40)
		add_child(status_icons_container)

func _setup_default_appearance():
	"""设置默认外观"""
	# 保存原始状态
	original_position = position
	original_scale = Vector2(1.0, 1.0)
	original_modulate = Color.WHITE
	if character_sprite:
		original_sprite_position = character_sprite.position
		# 设置初始状态
		character_sprite.scale = original_scale
		character_sprite.modulate = original_modulate
		# 不设置颜色，完全由initialize_character方法控制

func _use_ziling_visuals():
	"""启用紫菱的 AnimatedSprite2D，并绑定 attack/idle 动画"""
	if ziling_animated == null:
		return

	# 从 MainGame.tscn 中临时抽取紫菱的 SpriteFrames（包含 attack/idle）
	var main_scene: PackedScene = load("res://scenes/MainGame.tscn")
	if main_scene:
		var temp_root = main_scene.instantiate()
		var temp_sprite: AnimatedSprite2D = temp_root.get_node_or_null("Character_ziling/AnimatedSprite2D")
		if temp_sprite and temp_sprite.sprite_frames:
			ziling_animated.sprite_frames = temp_sprite.sprite_frames.duplicate(true)
			ziling_animated.animation = "idle"
			ziling_animated.autoplay = "idle"
			ziling_animated.frame = 0
			ziling_animated.visible = true
			# 同步正式资源节点自身的展示属性，避免二次缩放
			# 同时考虑父节点 Character_ziling 的缩放，得到有效缩放
			var temp_parent: Node2D = temp_root.get_node_or_null("Character_ziling")
			var effective_scale: Vector2 = temp_sprite.scale
			if temp_parent:
				effective_scale = Vector2(effective_scale.x * temp_parent.scale.x, effective_scale.y * temp_parent.scale.y)
			ziling_animated.scale = effective_scale
			ziling_animated.centered = temp_sprite.centered
			ziling_animated.offset = temp_sprite.offset
			# 根据容器尺寸自动缩放与定位，避免因帧过大被裁剪
			_fit_ziling_to_container()
			# 隐藏原有 ColorRect，只使用紫菱动画显示
			if character_sprite:
				character_sprite.visible = false
			# 清理临时实例
			temp_root.queue_free()

	print("[CharacterAnimator] 紫菱资源绑定完成：attack/idle 已就绪")

func _fit_ziling_to_container():
	"""将紫菱动画缩放到可视区域内，并进行居中与底对齐，避免裁剪"""
	if ziling_animated == null or not ziling_animated.visible:
		return

	var target_size: Vector2 = Vector2(80, 80)
	# 优先使用占位精灵尺寸；若占位不可见或不存在，则使用动画器自身尺寸
	if character_sprite and character_sprite.visible:
		# 使用占位精灵的尺寸作为期望显示区域
		target_size = character_sprite.size
	else:
		target_size = size

	var tex: Texture2D = null
	if ziling_animated.sprite_frames:
		if ziling_animated.sprite_frames.has_animation("idle"):
			tex = ziling_animated.sprite_frames.get_frame_texture("idle", 0)
		else:
			var names := ziling_animated.sprite_frames.get_animation_names()
			if names.size() > 0:
				tex = ziling_animated.sprite_frames.get_frame_texture(names[0], 0)

	if tex:
		var frame_size: Vector2 = tex.get_size()
		# 不再在此处进行缩放，使用资源节点自身的缩放
		var scale_vec: Vector2 = ziling_animated.scale
		# 计算显示后的尺寸，并按 AnimatedSprite2D 的居中锚点对齐
		# 注意：AnimatedSprite2D 默认 centered=true，position 表示精灵中心点
		# 底部居中应当将中心点放在 (target_width*0.5, target_height - drawn_height*0.5)
		ziling_animated.centered = true
		var drawn_size: Vector2 = Vector2(frame_size.x * scale_vec.x, frame_size.y * scale_vec.y)
		var pos_x: float = target_size.x * 0.5
		var pos_y: float = target_size.y - drawn_size.y * 0.5
		ziling_animated.position = Vector2(pos_x, pos_y)

func _setup_damage_number_pool():
	"""设置伤害数字池"""
	damage_number_pool = DamageNumberPool.new()
	damage_number_pool.name = "DamageNumberPool"
	add_child(damage_number_pool)
	damage_number_pool.initialize(self, 5)  # 每个角色5个伤害数字

func initialize_character(char_data: Dictionary, team: String, pos: int):
	"""初始化角色数据"""
	# 确保UI组件已经设置好（防止_ready还未执行完成）
	if character_sprite == null:
		_setup_ui_components()
	
	character_data = char_data.duplicate(true)
	team_type = team
	position_index = pos
	
	# 更新显示
	_update_character_display()
	_update_health_bar()
	
	# 根据队伍类型设置颜色
	if team_type == "hero":
		if character_sprite:
			character_sprite.color = Color.BLUE
			character_sprite.visible = true  # 确保可见
		original_color = Color.BLUE
		print("[CharacterAnimator] 设置英雄颜色为蓝色")
	else:
		if character_sprite:
			character_sprite.color = Color.RED
			character_sprite.visible = true  # 确保可见
		original_color = Color.RED
		print("[CharacterAnimator] 设置敌方颜色为红色")
	
	# 确保动画器本身可见
	visible = true
	
	print("[CharacterAnimator] 初始化角色: %s (%s队伍, 位置%d)" % [
		_get_character_name(), team_type, position_index
	])
	print("[CharacterAnimator] 动画器状态: 位置=%s, 尺寸=%s, 可见=%s" % [
		position, size, visible
	])
	if character_sprite:
		print("[CharacterAnimator] 精灵状态: 位置=%s, 尺寸=%s, 颜色=%s, 可见=%s" % [
			character_sprite.position, character_sprite.size, character_sprite.color, character_sprite.visible
		])

	# 如果角色为紫菱，切换为 AnimatedSprite2D 显示（使用 attack/idle）
	if _get_character_name() == "紫菱":
		_use_ziling_visuals()

func mirror_for_enemy_layout():
	"""为敌方角色应用简化的镜像布局"""
	# 不使用负缩放，避免视觉不一致
	# 镜像效果主要通过动画中的移动方向来体现
	
	# 确保所有UI元素居中对齐
	if character_label:
		character_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if health_bar:
		# 确保血量条居中
		health_bar.size = Vector2(health_bar.size.x, health_bar.size.y)
	if health_label:
		health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 标记为敌方，动画系统会根据team_type自动处理镜像效果
	print("[CharacterAnimator] 敌方角色镜像布局完成: %s" % _get_character_name())

func _update_character_display():
	"""更新角色显示信息"""
	var name = _get_character_name()
	if character_label:
		character_label.text = name
	
	# 根据角色状态调整显示
	var current_hp = character_data.get("current_hp", 0)
	if current_hp <= 0:
		if character_sprite:
			# 只有在没有动画进行时才设置死亡效果，避免干扰闪烁等动画
			if current_animation == "":
				character_sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)  # 死亡时变灰暗
		if character_label:
			character_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		if character_sprite:
			# 只有在没有动画进行时才重置modulate，避免干扰闪烁等动画效果
			if current_animation == "":
				character_sprite.modulate = Color.WHITE
		if character_label:
			character_label.add_theme_color_override("font_color", Color.WHITE)

func _update_health_bar():
	"""更新血量条 - 添加平滑动画效果"""
	var current_hp = character_data.get("current_hp", 0)
	var max_hp = character_data.get("max_hp", 100)
	
	if health_bar:
		health_bar.max_value = max_hp
		
		# 使用Tween创建平滑的血量条动画
		var tween = create_tween()
		tween.tween_property(health_bar, "value", current_hp, 0.5)
		
		# 根据血量比例设置颜色
		var hp_ratio = float(current_hp) / float(max_hp)
		var target_color: Color
		if hp_ratio > 0.6:
			target_color = Color.GREEN
		elif hp_ratio > 0.3:
			target_color = Color.YELLOW
		else:
			target_color = Color.RED
		
		# 平滑过渡血量条颜色
		if health_bar.has_method("add_theme_color_override"):
			health_bar.add_theme_color_override("fill", target_color)
	
	# 更新血量文本显示
	if health_label:
		health_label.text = str(current_hp) + "/" + str(max_hp)
	
	emit_signal("health_changed", current_hp, max_hp)
	
	# 检查是否死亡
	if current_hp <= 0 and current_animation != "death":
		play_death_animation()

# ============ 动画播放方法 ============

func play_attack_animation():
	"""播放攻击动画 - 增强版本，更加明显和有冲击力"""
	# 允许受击动画中断攻击动画，提升战斗连贯感
	if current_animation == "attack":
		print("[CharacterAnimator] 攻击动画正在播放，允许继续或重新开始")
	elif current_animation != "":
		print("[CharacterAnimator] 中断当前动画:", current_animation, "开始攻击动画")
	
	current_animation = "attack"
	print("[CharacterAnimator] 播放增强攻击动画: %s" % _get_character_name())

	# 若为紫菱显示，先播放 attack 帧
	if ziling_animated and ziling_animated.visible and ziling_animated.sprite_frames and ziling_animated.sprite_frames.has_animation("attack"):
		ziling_animated.play("attack")
	
	# 增加移动距离，使动画更明显
	var move_distance = 120  # 从60增加到120
	var is_enemy = (team_type != "hero")
	
	# 第一阶段：蓄力动画（向后拉）
	var charge_tween = create_tween()
	charge_tween.set_parallel(true)
	
	# 蓄力时向后移动并压缩
	var charge_x: float
	if is_enemy:
		charge_x = character_sprite.position.x + 15  # 敌人向右拉（蓄力）
	else:
		charge_x = character_sprite.position.x - 15  # 英雄向左拉（蓄力）
	
	charge_tween.tween_property(character_sprite, "position:x", charge_x, 0.12 / animation_speed)
	charge_tween.tween_property(character_sprite, "scale", Vector2(0.9, 1.1), 0.12 / animation_speed)
	charge_tween.tween_property(character_sprite, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.12 / animation_speed)
	
	await charge_tween.finished
	
	# 第二阶段：爆发攻击动画
	var attack_tween = create_tween()
	attack_tween.set_parallel(true)
	
	# 更强烈的视觉效果：更亮的颜色和更大的缩放
	attack_tween.tween_property(character_sprite, "modulate", Color(2.2, 2.0, 1.5, 1.0), 0.08 / animation_speed)
	attack_tween.tween_property(character_sprite, "scale", Vector2(1.6, 1.4), 0.08 / animation_speed)
	
	# 快速冲刺到目标位置
	var target_x: float
	if is_enemy:
		target_x = character_sprite.position.x - move_distance  # 敌人向左冲刺
	else:
		target_x = character_sprite.position.x + move_distance  # 英雄向右冲刺
	
	attack_tween.tween_property(character_sprite, "position:x", target_x, 0.15 / animation_speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await attack_tween.finished
	
	# 第三阶段：冲击停顿（增加冲击感）
	var impact_tween = create_tween()
	impact_tween.set_parallel(true)
	
	# 冲击时的震动效果和颜色闪烁
	impact_tween.tween_property(character_sprite, "scale", Vector2(1.8, 1.2), 0.06 / animation_speed)
	impact_tween.tween_property(character_sprite, "modulate", Color(2.5, 2.5, 2.0, 1.0), 0.06 / animation_speed)
	
	await impact_tween.finished
	
	# 短暂停顿增加冲击感
	var pause_tween = create_tween()
	pause_tween.tween_interval(0.1 / animation_speed)
	await pause_tween.finished
	
	# 第四阶段：回位动画
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(character_sprite, "position:x", original_sprite_position.x, 0.3 / animation_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return_tween.tween_property(character_sprite, "modulate", original_modulate, 0.3 / animation_speed)
	return_tween.tween_property(character_sprite, "scale", original_scale, 0.3 / animation_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await return_tween.finished

	# 紫菱动画回到 idle
	if ziling_animated and ziling_animated.visible and ziling_animated.sprite_frames and ziling_animated.sprite_frames.has_animation("idle"):
		ziling_animated.play("idle")
	
	current_animation = ""
	emit_signal("animation_completed", "attack")

# ============ 受击动画系统 ============

func _play_hit_flash_animation(is_critical: bool):
	"""核心闪烁动画逻辑 - 被所有受击方法复用"""
	print("[CharacterAnimator] 开始播放闪烁动画 - 暴击:", is_critical, " 角色:", _get_character_name())
	print("[CharacterAnimator] 当前color:", character_sprite.color, " 原始color:", original_color)
	
	# 超强增强的受击颜色：极其明显的闪烁效果
	var flash_color: Color
	if is_critical:
		flash_color = Color(1.0, 0.3, 0.3, 1.0)  # 暴击：亮红色
	else:
		flash_color = Color(1.0, 1.0, 1.0, 1.0)  # 普通：亮白色

	print("[CharacterAnimator] 闪烁颜色:", flash_color)

	# 简洁闪烁效果：1次闪烁，快速明显的视觉反馈
	print("[CharacterAnimator] 执行1次闪烁")
	
	var flash_duration = 0.15 / animation_speed  # 单次闪烁持续时间 (缩短到0.15秒)
	
	# 只闪烁1次
	var flash_tween = create_tween()
	
	# 闪亮 - 直接修改color属性
	flash_tween.tween_property(character_sprite, "color", flash_color, flash_duration)
	await flash_tween.finished
	
	# 恢复原色
	var restore_tween = create_tween()
	restore_tween.tween_property(character_sprite, "color", original_color, flash_duration)
	await restore_tween.finished

	print("[CharacterAnimator] 闪烁动画执行完成")

func play_hit_animation(is_critical: bool):
	"""纯视觉受击动画 - 用于队伍受击和测试"""
	print("[CharacterAnimator] play_hit_animation 被调用 - 暴击:", is_critical, " 角色:", _get_character_name())
	print("[CharacterAnimator] 当前动画状态:", current_animation)
	
	# 受击动画具有最高优先级，可以中断任何动画
	# 这确保了攻击关键帧时的即时视觉反馈
	if current_animation == "hit_animation":
		print("[CharacterAnimator] 受击动画正在播放，允许叠加新的受击效果")
	elif current_animation == "attack":
		print("[CharacterAnimator] 攻击动画播放中，受击动画立即响应（并发播放）")
	elif current_animation != "":
		print("[CharacterAnimator] 中断当前动画:", current_animation, "播放受击动画")
	
	# 不改变current_animation状态，允许攻击动画继续播放
	# 受击闪烁作为叠加效果，不影响主动画流程
	var previous_animation = current_animation
	current_animation = "hit_animation"
	print("[CharacterAnimator] 设置当前动画为 hit_animation (之前:", previous_animation, ")")

	await _play_hit_flash_animation(is_critical)
	
	# 如果之前有其他动画在播放，恢复其状态
	if previous_animation == "attack":
		current_animation = "attack"
		print("[CharacterAnimator] 受击动画完成，恢复攻击动画状态")
	else:
		current_animation = ""
		print("[CharacterAnimator] 受击动画完成，清空动画状态")
	
	emit_signal("animation_completed", "hit_animation")

func play_damage_visual_effects(damage: int, is_critical: bool):
	"""纯视觉伤害效果：伤害数字 + 受击闪烁（不处理数据）"""
	print("[CharacterAnimator] 播放伤害视觉效果: %s, 伤害: %d%s" % [
		_get_character_name(), damage, ("(暴击)" if is_critical else "")
	])
	
	if current_animation != "":
		# 如果已有动画在播放，避免冲突
		return
	current_animation = "damage_visual"
	
	# 显示伤害数字
	if damage_number_pool:
		var damage_pos = character_sprite.global_position + Vector2(character_sprite.size.x * 0.5, character_sprite.size.y * 0.5 - 10)
		damage_number_pool.show_damage(damage, damage_pos, is_critical)
	
	# 播放受击闪烁动画
	await _play_hit_flash_animation(is_critical)
	
	current_animation = ""
	emit_signal("animation_completed", "damage_visual")

# ============ 向后兼容接口 ============

func play_damage_animation(damage: int, is_critical: bool):
	"""向后兼容接口 - 重定向到纯视觉方法"""
	await play_damage_visual_effects(damage, is_critical)

func apply_damage_with_effects(damage: int, is_critical: bool):
	"""已废弃的方法 - 重定向到纯视觉方法以保持兼容性"""
	print("[CharacterAnimator] 警告: apply_damage_with_effects 已废弃，请使用 play_damage_visual_effects")
	await play_damage_visual_effects(damage, is_critical)

func play_heal_animation(heal_amount: int):
	"""播放治疗动画"""
	print("[CharacterAnimator] 播放治疗动画: %s, 治疗: %d" % [
		_get_character_name(), heal_amount
	])
	
	# 在 play_heal_animation 中，替换更新血量的部分：
	# 更新角色数据中的血量（队伍HP模式不改成员血量）
	if not team_pool_mode:
		var current_hp = character_data.get("current_hp", 0)
		var max_hp = character_data.get("max_hp", current_hp)
		current_hp = min(max_hp, current_hp + heal_amount)
		character_data["current_hp"] = current_hp
		_update_health_bar()
	
	# 显示治疗数字
	if damage_number_pool:
		var heal_pos = character_sprite.global_position + Vector2(character_sprite.size.x * 0.5, character_sprite.size.y * 0.5 - 10)
		damage_number_pool.show_heal(heal_amount, heal_pos)
	
	# 播放治疗发光动画
	var heal_tween = create_tween()
	heal_tween.tween_property(character_sprite, "modulate", Color(1.2, 1.5, 1.2, 1.0), 0.3 / animation_speed)
	heal_tween.tween_property(character_sprite, "modulate", original_modulate, 0.3 / animation_speed)
	
	await heal_tween.finished
	
	# 更新显示状态
	_update_character_display()

func play_miss_animation():
	"""播放未命中动画"""
	print("[CharacterAnimator] 播放未命中动画: %s" % _get_character_name())
	
	# 显示未命中文字
	if damage_number_pool:
		var miss_pos = character_sprite.global_position + Vector2(character_sprite.size.x * 0.5, character_sprite.size.y * 0.5 - 10)
		damage_number_pool.show_miss(miss_pos)
	
	# 播放闪避动画
	var dodge_tween = create_tween()
	dodge_tween.set_parallel(true)
	
	# 快速左右移动
	dodge_tween.tween_property(character_sprite, "position:x", character_sprite.position.x + 10, 0.1 / animation_speed)
	dodge_tween.tween_property(character_sprite, "position:x", character_sprite.position.x - 10, 0.1 / animation_speed)
	dodge_tween.tween_property(character_sprite, "position:x", original_position.x, 0.1 / animation_speed)
	
	await dodge_tween.finished

func play_block_animation():
	"""播放格挡动画"""
	print("[CharacterAnimator] 播放格挡动画: %s" % _get_character_name())
	
	# 显示格挡文字
	if damage_number_pool:
		var block_pos = character_sprite.global_position + Vector2(character_sprite.size.x * 0.5, character_sprite.size.y * 0.5 - 10)
		damage_number_pool.show_block(block_pos)
	
	# 播放格挡闪光动画
	var block_tween = create_tween()
	block_tween.tween_property(character_sprite, "modulate", Color(1.5, 1.5, 2.0, 1.0), 0.2 / animation_speed)
	block_tween.tween_property(character_sprite, "modulate", original_modulate, 0.2 / animation_speed)
	
	await block_tween.finished

func play_skill_animation(skill_id: String):
	"""播放技能动画"""
	if current_animation != "":
		return

	current_animation = "skill"
	print("[CharacterAnimator] 播放技能动画: %s 使用 %s" % [_get_character_name(), skill_id])

	# 技能开始：紫菱统一播放 attack 帧
	if ziling_animated and ziling_animated.visible and ziling_animated.sprite_frames and ziling_animated.sprite_frames.has_animation("attack"):
		ziling_animated.play("attack")

	# 根据技能类型播放不同动画
	match skill_id:
		"skill.hero.wanjian_guizong.v1":
			await _play_wanjian_guizong_animation()
		"power_strike":
			await _play_power_strike_animation()
		"multi_strike":
			await _play_multi_strike_animation()
		_:
			await _play_default_skill_animation()

	# 技能结束：紫菱回到 idle 帧
	if ziling_animated and ziling_animated.visible and ziling_animated.sprite_frames and ziling_animated.sprite_frames.has_animation("idle"):
		ziling_animated.play("idle")

	current_animation = ""
	emit_signal("animation_completed", "skill")

func _play_power_strike_animation():
	"""播放强击技能动画"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 蓄力效果
	tween.tween_property(character_sprite, "scale", Vector2(1.5, 1.5), 0.3 / animation_speed)
	tween.tween_property(character_sprite, "modulate", Color(2.0, 1.5, 1.0, 1.0), 0.3 / animation_speed)
	
	await tween.finished
	
	# 释放效果
	var release_tween = create_tween()
	release_tween.set_parallel(true)
	release_tween.tween_property(character_sprite, "scale", original_scale, 0.2 / animation_speed)
	release_tween.tween_property(character_sprite, "modulate", original_modulate, 0.2 / animation_speed)
	
	await release_tween.finished

func _play_multi_strike_animation():
	"""播放连击技能动画"""
	# 快速连续攻击动作
	for i in range(2):
		var strike_tween = create_tween()
		strike_tween.set_parallel(true)
		
		# 快速前冲
		var move_distance = 30 if team_type == "hero" else -30
		strike_tween.tween_property(character_sprite, "position:x", character_sprite.position.x + move_distance, 0.1 / animation_speed)
		strike_tween.tween_property(character_sprite, "modulate", Color(1.5, 1.5, 1.8, 1.0), 0.1 / animation_speed)
		
		await strike_tween.finished
		
		# 快速回退
		var return_tween = create_tween()
		return_tween.set_parallel(true)
		return_tween.tween_property(character_sprite, "position:x", original_position.x, 0.1 / animation_speed)
		return_tween.tween_property(character_sprite, "modulate", original_modulate, 0.1 / animation_speed)
		
		await return_tween.finished
		
		# 短暂间隔
		var interval_timer = create_tween()
		interval_timer.tween_interval(0.1 / animation_speed)
		await interval_timer.finished

func _play_wanjian_guizong_vfx_boost():
	"""万剑归宗的额外视觉增强（短暂高亮与缩放脉冲）"""
	var vfx_tween = create_tween()
	vfx_tween.set_parallel(true)
	vfx_tween.tween_property(character_sprite, "modulate", Color(2.2, 2.2, 2.2, 1.0), 0.08 / animation_speed)
	vfx_tween.tween_property(character_sprite, "scale", Vector2(1.7, 1.3), 0.08 / animation_speed)
	await vfx_tween.finished
	var recover = create_tween()
	recover.set_parallel(true)
	recover.tween_property(character_sprite, "modulate", original_modulate, 0.18 / animation_speed)
	recover.tween_property(character_sprite, "scale", original_scale, 0.18 / animation_speed)
	await recover.finished

func _play_wanjian_guizong_animation():
	"""播放万剑归宗技能动画：更大的前冲位移与冲击感"""
	# 蓄力：轻微后拉与发光
	var is_enemy = (team_type != "hero")
	var charge = create_tween()
	charge.set_parallel(true)
	var charge_x: float = character_sprite.position.x + (15 if is_enemy else -15)
	charge.tween_property(character_sprite, "position:x", charge_x, 0.12 / animation_speed)
	charge.tween_property(character_sprite, "modulate", Color(1.4, 1.3, 1.0, 1.0), 0.12 / animation_speed)
	charge.tween_property(character_sprite, "scale", Vector2(1.05, 1.05), 0.12 / animation_speed)
	await charge.finished

	# 释放：更大的位移幅度（较普攻更突出）
	var move_distance: float = 180.0  # 普攻120，这里提升到180以突出技能力量
	var target_x: float = character_sprite.position.x + (move_distance if not is_enemy else -move_distance)
	var surge = create_tween()
	surge.set_parallel(true)
	surge.tween_property(character_sprite, "position:x", target_x, 0.16 / animation_speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	surge.tween_property(character_sprite, "scale", Vector2(1.6, 1.4), 0.10 / animation_speed)
	surge.tween_property(character_sprite, "modulate", Color(2.4, 2.2, 1.6, 1.0), 0.10 / animation_speed)
	await surge.finished

	# 冲击增强：短促的亮度与缩放脉冲
	await _play_wanjian_guizong_vfx_boost()

	# 短暂停顿增加冲击感
	var pause = create_tween()
	pause.tween_interval(0.10 / animation_speed)
	await pause.finished

	# 回位：平滑恢复到初始位置与外观
	var back = create_tween()
	back.set_parallel(true)
	back.tween_property(character_sprite, "position:x", original_sprite_position.x, 0.28 / animation_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(character_sprite, "modulate", original_modulate, 0.28 / animation_speed)
	back.tween_property(character_sprite, "scale", original_scale, 0.28 / animation_speed)
	await back.finished

func _play_default_skill_animation():
	"""播放默认技能动画"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 发光效果
	tween.tween_property(character_sprite, "modulate", Color(1.5, 1.5, 2.0, 1.0), 0.5 / animation_speed)
	tween.tween_property(character_sprite, "scale", Vector2(1.2, 1.2), 0.5 / animation_speed)
	
	await tween.finished
	
	# 恢复
	var restore_tween = create_tween()
	restore_tween.set_parallel(true)
	restore_tween.tween_property(character_sprite, "modulate", original_modulate, 0.3 / animation_speed)
	restore_tween.tween_property(character_sprite, "scale", original_scale, 0.3 / animation_speed)
	
	await restore_tween.finished

func play_death_animation():
	"""播放死亡动画"""
	if current_animation == "death":
		return
	
	current_animation = "death"
	print("[CharacterAnimator] 播放死亡动画: %s" % _get_character_name())
	
	var death_tween = create_tween()
	death_tween.set_parallel(true)
	
	# 倒下效果
	death_tween.tween_property(character_sprite, "rotation", PI/2, 1.0 / animation_speed)
	death_tween.tween_property(character_sprite, "modulate", Color(0.3, 0.3, 0.3, 0.5), 1.0 / animation_speed)
	death_tween.tween_property(character_sprite, "scale", Vector2(0.8, 0.8), 1.0 / animation_speed)
	
	await death_tween.finished
	
	emit_signal("character_defeated")
	emit_signal("animation_completed", "death")

func play_victory_animation():
	"""播放胜利动画"""
	if character_data.get("current_hp", 0) <= 0:
		return  # 死亡角色不播放胜利动画
	
	var victory_tween = create_tween()
	victory_tween.set_parallel(true)
	
	# 庆祝效果
	victory_tween.tween_property(character_sprite, "modulate", Color(1.5, 1.5, 1.0, 1.0), 0.5)
	victory_tween.tween_property(character_sprite, "scale", Vector2(1.2, 1.2), 0.5)
	
	# 跳跃效果
	for i in range(3):
		victory_tween.tween_property(character_sprite, "position:y", character_sprite.position.y - 20, 0.2)
		victory_tween.tween_property(character_sprite, "position:y", original_position.y, 0.2)
	
	await victory_tween.finished
	
	# 恢复原状
	var restore_tween = create_tween()
	restore_tween.set_parallel(true)
	restore_tween.tween_property(character_sprite, "modulate", original_modulate, 0.3)
	restore_tween.tween_property(character_sprite, "scale", original_scale, 0.3)
	
	await restore_tween.finished

func play_defeat_animation():
	"""播放失败动画"""
	if character_data.get("current_hp", 0) <= 0:
		return  # 已死亡角色不需要额外失败动画
	
	var defeat_tween = create_tween()
	defeat_tween.set_parallel(true)
	
	# 沮丧效果
	defeat_tween.tween_property(character_sprite, "modulate", Color(0.7, 0.7, 0.7, 1.0), 1.0)
	defeat_tween.tween_property(character_sprite, "scale", Vector2(0.9, 0.9), 1.0)
	defeat_tween.tween_property(character_sprite, "position:y", character_sprite.position.y + 10, 1.0)
	
	await defeat_tween.finished

# ============ 状态效果动画 ============

func add_status_effect(effect_type: String, duration: float = 0.0):
	"""添加状态效果图标和动画"""
	print("[CharacterAnimator] 添加状态效果: %s 到 %s" % [effect_type, _get_character_name()])
	
	# 创建状态图标
	var status_icon = ColorRect.new()
	status_icon.size = Vector2(12, 12)
	status_icon.name = "Status_" + effect_type
	
	# 根据状态类型设置颜色
	match effect_type:
		"poison":
			status_icon.color = Color.GREEN
		"regen":
			status_icon.color = Color.LIGHT_GREEN
		"attack_up":
			status_icon.color = Color.ORANGE
		"defense_down":
			status_icon.color = Color.PURPLE
		"shield":
			status_icon.color = Color.CYAN
		_:
			status_icon.color = Color.GRAY
	
	status_icons_container.add_child(status_icon)
	
	# 播放状态效果动画
	_play_status_effect_animation(effect_type)
	
	# 如果有持续时间，自动移除
	if duration > 0:
		var duration_timer = create_tween()
		duration_timer.tween_interval(duration)
		await duration_timer.finished
		remove_status_effect(effect_type)

func remove_status_effect(effect_type: String):
	"""移除状态效果"""
	var status_node = status_icons_container.get_node_or_null("Status_" + effect_type)
	if status_node:
		status_node.queue_free()

func _play_status_effect_animation(effect_type: String):
	"""播放状态效果动画"""
	match effect_type:
		"poison":
			_play_poison_effect()
		"regen":
			_play_regen_effect()
		"attack_up", "defense_down", "shield":
			_play_buff_debuff_effect()

func _play_poison_effect():
	"""播放中毒效果"""
	var poison_tween = create_tween()
	poison_tween.tween_property(character_sprite, "modulate", Color(0.8, 1.2, 0.8, 1.0), 0.3)
	poison_tween.tween_property(character_sprite, "modulate", original_modulate, 0.3)

func _play_regen_effect():
	"""播放再生效果"""
	var regen_tween = create_tween()
	regen_tween.tween_property(character_sprite, "modulate", Color(1.2, 1.5, 1.2, 1.0), 0.3)
	regen_tween.tween_property(character_sprite, "modulate", original_modulate, 0.3)

func _play_buff_debuff_effect():
	"""播放增益/减益效果"""
	var effect_tween = create_tween()
	effect_tween.tween_property(character_sprite, "scale", Vector2(1.1, 1.1), 0.2)
	effect_tween.tween_property(character_sprite, "scale", original_scale, 0.2)

# ============ 公共接口方法 ============

func update_health_bar(current_hp: int, max_hp: int):
	"""外部调用更新血量条"""
	character_data["current_hp"] = current_hp
	character_data["max_hp"] = max_hp
	_update_health_bar()

func set_highlight(highlighted: bool):
	"""设置高亮状态"""
	is_highlighted = highlighted
	
	if highlighted:
		# 高亮效果
		var highlight_tween = create_tween()
		highlight_tween.tween_property(character_sprite, "modulate", Color(1.3, 1.3, 1.0, 1.0), 0.3)
	else:
		# 取消高亮
		var unhighlight_tween = create_tween()
		unhighlight_tween.tween_property(character_sprite, "modulate", original_modulate, 0.3)

func set_animation_speed(speed: float):
	"""设置动画播放速度"""
	animation_speed = clamp(speed, 0.1, 3.0)
	
	# 同时设置伤害数字池的动画速度
	if damage_number_pool:
		damage_number_pool.set_animation_speed_for_all(speed)

func is_animation_playing() -> bool:
	"""检查是否有动画正在播放"""
	return current_animation != ""

func get_character_data() -> Dictionary:
	"""获取角色数据"""
	return character_data

func matches_character(other_data: Dictionary) -> bool:
	"""检查是否匹配指定的角色数据"""
	if not character_data or not other_data:
		return false
	
	# 通过名称和队伍类型匹配
	var my_name = character_data.get("name", "")
	var other_name = other_data.get("name", "")
	
	# 如果有唯一ID，优先使用ID匹配
	if character_data.has("id") and other_data.has("id"):
		return character_data.get("id") == other_data.get("id")
	
	# 否则使用名称匹配
	return my_name == other_name and my_name != ""

func _get_character_name() -> String:
	"""获取角色名称"""
	return str(character_data.get("name", "未知角色"))

func cleanup():
	"""清理资源"""
	# 停止所有动画
	var tweens = get_tree().get_nodes_in_group("tween")
	for tween in tweens:
		if tween.get_parent() == self:
			tween.kill()
	
	# 清理状态图标
	for child in status_icons_container.get_children():
		child.queue_free()
	
	# 清理伤害数字池
	if damage_number_pool:
		damage_number_pool.cleanup()
	
	current_animation = ""
# 新增方法：显式切换队伍HP模式并隐藏成员血条
func set_team_pool_mode(enabled: bool):
	team_pool_mode = enabled
	if health_bar:
		health_bar.visible = not enabled
	if health_label:
		health_label.visible = not enabled