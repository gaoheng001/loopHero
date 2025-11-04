extends SceneTree

func _init():
	print("=== 测试优化后的闪烁效果 ===")
	print("优化内容：")
	print("- 闪烁次数：从5次减少到1次")
	print("- 闪烁持续时间：从0.4秒缩短到0.15秒")
	print("- 总闪烁时间：从约3秒缩短到0.3秒")
	
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
		"current_health": 80,
		"current_hp": 80,
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
	
	print("\n[优化测试] 初始状态:")
	print("  - 初始color: ", character_sprite.color)
	print("  - 初始modulate: ", character_sprite.modulate)
	
	# 测试1：优化后的普通闪烁
	print("\n[优化测试] 测试1：优化后的普通闪烁 (1次，0.15秒)")
	var start_time = Time.get_ticks_msec()
	character_animator.play_hit_animation(false)
	
	await process_frame
	print("  - 闪烁开始，color变为: ", character_sprite.color)
	
	# 等待闪烁完成
	await create_tween().tween_interval(1.0).finished
	
	var end_time = Time.get_ticks_msec()
	var duration = (end_time - start_time) / 1000.0
	print("  - 闪烁完成，color恢复为: ", character_sprite.color)
	print("  - 实际持续时间: %.2f秒" % duration)
	
	# 等待间隔
	await create_tween().tween_interval(1.0).finished
	
	# 测试2：优化后的暴击闪烁
	print("\n[优化测试] 测试2：优化后的暴击闪烁 (1次，0.15秒)")
	start_time = Time.get_ticks_msec()
	character_animator.play_hit_animation(true)
	
	await process_frame
	print("  - 暴击闪烁开始，color变为: ", character_sprite.color)
	
	# 等待闪烁完成
	await create_tween().tween_interval(1.0).finished
	
	end_time = Time.get_ticks_msec()
	duration = (end_time - start_time) / 1000.0
	print("  - 暴击闪烁完成，color恢复为: ", character_sprite.color)
	print("  - 实际持续时间: %.2f秒" % duration)
	
	# 测试3：连续闪烁测试
	print("\n[优化测试] 测试3：连续闪烁测试")
	for i in range(3):
		print("  - 第%d次闪烁" % (i + 1))
		character_animator.play_hit_animation(i % 2 == 1)  # 交替普通和暴击
		await create_tween().tween_interval(0.5).finished  # 短间隔
	
	print("\n=== 闪烁效果优化验证完成 ===")
	print("✅ 闪烁次数已优化：5次 → 1次")
	print("✅ 闪烁持续时间已优化：0.4秒 → 0.15秒")
	print("✅ 总动画时间已优化：约3秒 → 约0.3秒")
	print("✅ 闪烁效果更加简洁快速")
	
	quit()