extends SceneTree

func _init():
	print("=== 简化闪烁动画测试 ===")
	call_deferred("start_test")

func start_test():
	# 创建简单的测试场景
	var main_node = Node.new()
	main_node.name = "TestMain"
	root.add_child(main_node)
	
	# 加载CharacterAnimator场景
	var animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	if not animator_scene:
		print("❌ 无法加载CharacterAnimator场景")
		quit()
		return
	
	var animator = animator_scene.instantiate()
	if not animator:
		print("❌ 无法实例化CharacterAnimator")
		quit()
		return
	
	main_node.add_child(animator)
	print("✓ CharacterAnimator创建成功")
	
	# 等待初始化
	await process_frame
	await process_frame
	
	# 初始化角色
	var test_char = {
		"name": "测试角色",
		"current_hp": 100,
		"max_hp": 100,
		"attack": 20,
		"defense": 10
	}
	
	animator.initialize_character(test_char, "hero", 0)
	print("✓ 角色初始化完成")
	
	# 等待初始化完成
	await process_frame
	await process_frame
	
	# 检查CharacterSprite是否存在
	var sprite = animator.get_node_or_null("CharacterSprite")
	if not sprite:
		print("❌ CharacterSprite节点未找到")
		quit()
		return
	
	print("✓ CharacterSprite节点找到")
	print("  - 位置: %s" % sprite.position)
	print("  - 尺寸: %s" % sprite.size)
	print("  - 颜色: %s" % sprite.color)
	print("  - 调制: %s" % sprite.modulate)
	print("  - 可见: %s" % sprite.visible)
	
	# 测试闪烁动画
	print("\n=== 开始闪烁动画测试 ===")
	print("原始调制颜色: %s" % sprite.modulate)
	
	# 调用受击动画
	if animator.has_method("play_hit_animation"):
		print("调用 play_hit_animation(false)...")
		animator.play_hit_animation(false)
		
		# 等待动画完成
		var wait_timer = create_tween()
		wait_timer.tween_interval(3.0)
		await wait_timer.finished
		
		print("动画完成后调制颜色: %s" % sprite.modulate)
		print("✓ 闪烁动画测试完成")
	else:
		print("❌ play_hit_animation方法未找到")
	
	print("\n=== 测试完成 ===")
	quit()