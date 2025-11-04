extends SceneTree

func _init():
	print("[修复测试] 开始测试修复后的闪烁动画...")
	
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
	
	print("[修复测试] 初始状态:")
	print("  - CharacterSprite类型: ", character_sprite.get_class())
	print("  - 初始color: ", character_sprite.color)
	print("  - 初始modulate: ", character_sprite.modulate)
	
	# 测试普通受击闪烁
	print("\n[修复测试] 测试普通受击闪烁...")
	character_animator.play_hit_animation(false)
	
	# 等待闪烁动画完成
	await create_tween().tween_interval(8.0).finished
	
	print("[修复测试] 普通受击闪烁完成")
	print("  - 最终color: ", character_sprite.color)
	print("  - 最终modulate: ", character_sprite.modulate)
	
	# 等待一秒
	await create_tween().tween_interval(1.0).finished
	
	# 测试暴击受击闪烁
	print("\n[修复测试] 测试暴击受击闪烁...")
	character_animator.play_hit_animation(true)
	
	# 等待闪烁动画完成
	await create_tween().tween_interval(8.0).finished
	
	print("[修复测试] 暴击受击闪烁完成")
	print("  - 最终color: ", character_sprite.color)
	print("  - 最终modulate: ", character_sprite.modulate)
	
	print("\n[修复测试] 所有测试完成！")
	print("现在闪烁动画应该直接修改color属性，产生明显的视觉效果")
	
	quit()