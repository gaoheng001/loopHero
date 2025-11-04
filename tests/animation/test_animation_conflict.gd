extends SceneTree

func _init():
	print("[冲突测试] 开始测试动画冲突问题...")
	
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
	
	print("[冲突测试] 初始状态:")
	print("  - color: ", character_sprite.color)
	print("  - modulate: ", character_sprite.modulate)
	
	# 模拟_update_character_display的调用（存活状态）
	print("\n[冲突测试] 调用_update_character_display（存活状态）...")
	character_sprite.modulate = Color.WHITE
	print("  - 设置后modulate: ", character_sprite.modulate)
	
	# 开始闪烁动画
	print("\n[冲突测试] 开始闪烁动画...")
	character_animator.play_hit_animation(false)
	
	# 等待0.5秒，然后模拟其他代码调用_update_character_display
	await create_tween().tween_interval(0.5).finished
	
	print("\n[冲突测试] 闪烁进行中，再次调用_update_character_display...")
	character_sprite.modulate = Color.WHITE  # 这会覆盖闪烁效果
	print("  - 覆盖后color: ", character_sprite.color)
	print("  - 覆盖后modulate: ", character_sprite.modulate)
	
	# 等待闪烁动画完成
	await create_tween().tween_interval(8.0).finished
	
	print("\n[冲突测试] 闪烁动画完成")
	print("  - 最终color: ", character_sprite.color)
	print("  - 最终modulate: ", character_sprite.modulate)
	
	print("\n[冲突测试] 测试完成！")
	print("发现问题：_update_character_display会重置modulate，可能影响视觉效果")
	
	quit()