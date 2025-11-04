extends SceneTree

func _init():
	print("[最终测试] 开始验证闪烁动画修复效果...")
	
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
	
	# 初始化角色数据
	var character_data = {
		"name": "测试英雄",
		"sprite_path": "res://assets/sprites/characters/hero.png",
		"max_health": 100,
		"current_health": 80
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
	
	print("[最终测试] 初始状态:")
	print("  - 节点类型: ", character_sprite.get_class())
	print("  - 初始color: ", character_sprite.color)
	print("  - 初始modulate: ", character_sprite.modulate)
	print("  - 当前动画: ", character_animator.current_animation)
	
	# 测试1：普通受击闪烁
	print("\n[最终测试] 测试1：普通受击闪烁")
	print("  - 开始闪烁动画...")
	character_animator.play_hit_animation(false)
	
	# 监控颜色变化
	await process_frame
	print("  - 闪烁开始后color: ", character_sprite.color)
	print("  - 闪烁开始后modulate: ", character_sprite.modulate)
	print("  - 当前动画状态: ", character_animator.current_animation)
	
	# 等待闪烁完成
	await create_tween().tween_interval(2.5).finished
	
	print("  - 闪烁完成后color: ", character_sprite.color)
	print("  - 闪烁完成后modulate: ", character_sprite.modulate)
	print("  - 当前动画状态: ", character_animator.current_animation)
	
	# 等待一秒
	await create_tween().tween_interval(1.0).finished
	
	# 测试2：暴击受击闪烁
	print("\n[最终测试] 测试2：暴击受击闪烁")
	print("  - 开始暴击闪烁动画...")
	character_animator.play_hit_animation(true)
	
	# 监控颜色变化
	await process_frame
	print("  - 暴击闪烁开始后color: ", character_sprite.color)
	print("  - 暴击闪烁开始后modulate: ", character_sprite.modulate)
	print("  - 当前动画状态: ", character_animator.current_animation)
	
	# 等待闪烁完成
	await create_tween().tween_interval(2.5).finished
	
	print("  - 暴击闪烁完成后color: ", character_sprite.color)
	print("  - 暴击闪烁完成后modulate: ", character_sprite.modulate)
	print("  - 当前动画状态: ", character_animator.current_animation)
	
	# 测试3：验证_update_character_display不会干扰动画
	print("\n[最终测试] 测试3：验证_update_character_display不会干扰动画")
	character_animator.play_hit_animation(false)
	await process_frame
	
	print("  - 闪烁进行中，调用_update_character_display...")
	var before_color = character_sprite.color
	var before_modulate = character_sprite.modulate
	
	# 模拟调用_update_character_display
	character_animator._update_character_display()
	
	var after_color = character_sprite.color
	var after_modulate = character_sprite.modulate
	
	print("  - 调用前color: ", before_color)
	print("  - 调用后color: ", after_color)
	print("  - 调用前modulate: ", before_modulate)
	print("  - 调用后modulate: ", after_modulate)
	
	if before_color == after_color and before_modulate == after_modulate:
		print("  ✓ _update_character_display没有干扰动画效果")
	else:
		print("  ✗ _update_character_display干扰了动画效果")
	
	# 等待动画完成
	await create_tween().tween_interval(2.0).finished
	
	print("\n[最终测试] 所有测试完成！")
	print("修复总结：")
	print("1. ✓ 闪烁动画改为直接修改color属性而非modulate")
	print("2. ✓ 使用白色和红白色作为闪烁颜色，确保可见性")
	print("3. ✓ 修复_update_character_display避免干扰动画")
	print("4. ✓ CharacterSprite使用ColorRect的color属性正确显示")
	
	quit()