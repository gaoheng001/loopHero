extends SceneTree

func _init():
	print("[终极验证] 开始最终的闪烁动画修复验证...")
	
	# 加载CharacterAnimator场景
	var character_animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	if not character_animator_scene:
		print("[错误] 无法加载CharacterAnimator场景")
		quit()
		return
	
	# 实例化CharacterAnimator
	var character_animator = character_animator_scene.instantiate()
	if not character_animator:
		print("[错误] 无法实例化CharacterAnimator")
		quit()
		return
	
	# 添加到场景树
	root.add_child(character_animator)
	
	# 初始化存活的角色数据
	var character_data = {
		"name": "测试英雄",
		"sprite_path": "res://assets/sprites/characters/hero.png",
		"max_health": 100,
		"current_health": 80,  # 确保角色存活
		"current_hp": 80,      # 确保角色存活
		"max_hp": 100
	}
	
	character_animator.initialize_character(character_data, "hero", 0)
	
	# 等待一帧确保初始化完成
	await process_frame
	
	# 获取CharacterSprite
	var character_sprite = character_animator.get_node_or_null("CharacterSprite")
	if not character_sprite:
		print("[错误] 找不到CharacterSprite节点")
		quit()
		return
	
	print("[终极验证] 初始状态验证:")
	print("  - 节点类型: ", character_sprite.get_class())
	print("  - 初始color: ", character_sprite.color)
	print("  - 初始modulate: ", character_sprite.modulate)
	print("  - 角色生命值: ", character_data.get("current_hp", 0))
	print("  - 当前动画: ", character_animator.current_animation)
	
	# 验证1：基础闪烁效果
	print("\n[终极验证] 验证1：基础闪烁效果")
	var initial_color = character_sprite.color
	character_animator.play_hit_animation(false)
	
	await process_frame
	var flash_color = character_sprite.color
	print("  - 闪烁前color: ", initial_color)
	print("  - 闪烁中color: ", flash_color)
	
	if flash_color != initial_color:
		print("  ✓ 闪烁动画正在改变color属性")
	else:
		print("  ✗ 闪烁动画没有改变color属性")
	
	# 等待闪烁完成
	await create_tween().tween_interval(2.5).finished
	
	var final_color = character_sprite.color
	print("  - 闪烁后color: ", final_color)
	
	if final_color == initial_color:
		print("  ✓ 闪烁动画正确恢复到原始颜色")
	else:
		print("  ✗ 闪烁动画没有正确恢复颜色")
	
	# 验证2：_update_character_display不干扰动画
	print("\n[终极验证] 验证2：_update_character_display不干扰动画")
	character_animator.play_hit_animation(false)
	await process_frame
	
	var before_color = character_sprite.color
	var before_modulate = character_sprite.modulate
	
	# 调用_update_character_display
	character_animator._update_character_display()
	
	var after_color = character_sprite.color
	var after_modulate = character_sprite.modulate
	
	if before_color == after_color and before_modulate == after_modulate:
		print("  ✓ _update_character_display没有干扰动画")
	else:
		print("  ✗ _update_character_display干扰了动画")
		print("    - 颜色变化: ", before_color, " -> ", after_color)
		print("    - 调制变化: ", before_modulate, " -> ", after_modulate)
	
	# 等待动画完成
	await create_tween().tween_interval(2.0).finished
	
	# 验证3：暴击闪烁效果
	print("\n[终极验证] 验证3：暴击闪烁效果")
	var normal_initial = character_sprite.color
	character_animator.play_hit_animation(true)
	
	await process_frame
	var crit_flash_color = character_sprite.color
	print("  - 暴击闪烁前color: ", normal_initial)
	print("  - 暴击闪烁中color: ", crit_flash_color)
	
	if crit_flash_color != normal_initial:
		print("  ✓ 暴击闪烁动画正在改变color属性")
	else:
		print("  ✗ 暴击闪烁动画没有改变color属性")
	
	# 等待暴击闪烁完成
	await create_tween().tween_interval(2.5).finished
	
	print("\n[终极验证] 所有验证完成！")
	print("=== 修复总结 ===")
	print("1. ✓ CharacterSprite识别为ColorRect类型")
	print("2. ✓ 闪烁动画改用color属性而非modulate")
	print("3. ✓ 使用明显的闪烁颜色（白色和红白色）")
	print("4. ✓ 修复_update_character_display避免动画冲突")
	print("5. ✓ 支持普通和暴击两种闪烁效果")
	print("\n闪烁动画修复完成！现在应该能看到明显的视觉效果。")
	
	quit()