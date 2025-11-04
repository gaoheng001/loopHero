extends SceneTree

func _init():
	print("[简单闪烁验证] 开始测试...")
	
	# 加载主场景
	var main_scene = preload("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	
	# 等待场景初始化
	await process_frame
	await process_frame
	
	# 查找BattleWindow
	var ui = main_scene.get_node_or_null("UI")
	if not ui:
		print("[简单闪烁验证] ❌ 找不到UI层")
		quit()
		return
		
	var battle_window = ui.get_node_or_null("BattleWindow")
	if not battle_window:
		print("[简单闪烁验证] ❌ 找不到BattleWindow")
		quit()
		return
	
	print("[简单闪烁验证] ✓ 找到BattleWindow")
	
	# 查找或创建BattleAnimationController
	var bac = battle_window.get_node_or_null("BattleAnimationController")
	if not bac:
		var bac_scene = preload("res://scenes/battle/BattleAnimationController.tscn")
		bac = bac_scene.instantiate()
		battle_window.add_child(bac)
		await process_frame
		print("[简单闪烁验证] ✓ 创建了BattleAnimationController")
	else:
		print("[简单闪烁验证] ✓ 找到BattleAnimationController")
	
	# 创建测试动画器
	await _test_flash_animation(bac)
	
	print("[简单闪烁验证] 测试完成")
	quit()

func _test_flash_animation(bac):
	"""测试闪烁动画"""
	print("[简单闪烁验证] 创建测试动画器...")
	
	# 加载CharacterAnimator场景
	var animator_scene = preload("res://scenes/battle/CharacterAnimator.tscn")
	var test_animator = animator_scene.instantiate()
	
	# 添加到场景中
	bac.add_child(test_animator)
	test_animator.position = Vector2(200, 200)
	
	# 创建测试角色数据
	var test_character = {
		"name": "测试角色",
		"current_hp": 100,
		"max_hp": 100,
		"attack": 10
	}
	
	# 初始化角色
	test_animator.initialize_character(test_character, "hero", 0)
	await process_frame
	
	print("[简单闪烁验证] ✓ 动画器初始化完成")
	
	# 测试普通闪烁
	print("[简单闪烁验证] 测试普通闪烁...")
	test_animator.play_hit_animation(false)
	
	# 等待2秒
	await create_timer(2.0).timeout
	
	# 测试暴击闪烁
	print("[简单闪烁验证] 测试暴击闪烁...")
	# 重置动画状态
	test_animator.current_animation = ""
	test_animator.play_hit_animation(true)
	
	# 等待2秒
	await create_timer(2.0).timeout
	
	print("[简单闪烁验证] ✓ 闪烁测试完成")