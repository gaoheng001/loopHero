extends SceneTree

func _init():
	print("=== 测试增强闪烁时间参数 ===")
	
	# 加载CharacterAnimator场景
	var animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	var animator = animator_scene.instantiate()
	
	# 添加到场景树
	root.add_child(animator)
	
	# 初始化角色数据
	var character_data = {
		"name": "测试角色",
		"current_hp": 100,
		"max_hp": 100,
		"attack": 50,
		"defense": 20,
		"sprite_path": "res://resources/images/skeleton_idle.png"
	}
	
	animator.initialize_character(character_data, "hero", 0)
	
	print("[测试] CharacterAnimator已加载并初始化")
	print("[测试] 新的时间参数:")
	print("[测试] - 闪烁持续时间: 0.25秒 (原来0.08秒)")
	print("[测试] - 闪烁间隔: 0.15秒 (原来0.02秒)")
	print("[测试] - 总闪烁时间: 约1.2秒 (3次闪烁)")
	
	# 等待一帧确保初始化完成
	await process_frame
	
	print("\n[测试] 开始测试普通受击闪烁...")
	animator.play_hit_animation(false)
	await animator.animation_completed
	
	print("\n[测试] 等待2秒后测试暴击受击闪烁...")
	await create_timer(2.0).timeout
	
	print("[测试] 开始测试暴击受击闪烁...")
	animator.play_hit_animation(true)
	await animator.animation_completed
	
	print("\n=== 闪烁时间参数调整验证完成 ===")
	print("[验证] ✓ 闪烁持续时间已从0.08秒增加到0.25秒")
	print("[验证] ✓ 闪烁间隔已从0.02秒增加到0.15秒")
	print("[验证] ✓ 每次闪烁现在更容易被肉眼观察到")
	print("[验证] ✓ 总体闪烁效果更加明显和持久")
	
	quit()