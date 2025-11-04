extends SceneTree

func _init():
	print("[颜色测试] 开始测试ColorRect的color vs modulate...")
	
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
		"name": "测试角色",
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
	
	print("[初始状态] CharacterSprite:")
	print("  - color: ", character_sprite.color)
	print("  - modulate: ", character_sprite.modulate)
	print("  - 最终显示颜色: ", character_sprite.color * character_sprite.modulate)
	
	# 测试1: 只改变modulate（当前闪烁动画的做法）
	print("\n[测试1] 只改变modulate为极亮白色...")
	character_sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	print("  - color: ", character_sprite.color)
	print("  - modulate: ", character_sprite.modulate)
	print("  - 最终显示颜色: ", character_sprite.color * character_sprite.modulate)
	
	await create_tween().tween_interval(1.0).finished
	
	# 恢复
	character_sprite.modulate = Color.WHITE
	print("  - 恢复后最终显示颜色: ", character_sprite.color * character_sprite.modulate)
	
	# 测试2: 直接改变color属性
	print("\n[测试2] 直接改变color为极亮白色...")
	var original_color = character_sprite.color
	character_sprite.color = Color(3.0, 3.0, 3.0, 1.0)
	print("  - color: ", character_sprite.color)
	print("  - modulate: ", character_sprite.modulate)
	print("  - 最终显示颜色: ", character_sprite.color * character_sprite.modulate)
	
	await create_tween().tween_interval(1.0).finished
	
	# 恢复
	character_sprite.color = original_color
	print("  - 恢复后最终显示颜色: ", character_sprite.color * character_sprite.modulate)
	
	# 测试3: 同时改变color和modulate
	print("\n[测试3] 同时改变color和modulate...")
	character_sprite.color = Color.WHITE  # 设置为白色基础
	character_sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)  # 极亮调制
	print("  - color: ", character_sprite.color)
	print("  - modulate: ", character_sprite.modulate)
	print("  - 最终显示颜色: ", character_sprite.color * character_sprite.modulate)
	
	await create_tween().tween_interval(1.0).finished
	
	# 恢复
	character_sprite.color = original_color
	character_sprite.modulate = Color.WHITE
	print("  - 恢复后最终显示颜色: ", character_sprite.color * character_sprite.modulate)
	
	print("\n[结论] 测试完成")
	print("ColorRect的最终显示颜色 = color * modulate")
	print("如果color是深色（如蓝色0,0,1），即使modulate很亮，最终效果也可能不明显")
	
	quit()