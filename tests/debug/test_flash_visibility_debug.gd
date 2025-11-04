extends SceneTree

func _ready():
	print("=== 受击闪烁动画可见性调试测试 ===")
	await test_flash_visibility()
	quit()

func test_flash_visibility():
	# 加载CharacterAnimator场景
	var animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	if not animator_scene:
		print("[错误] 无法加载CharacterAnimator场景")
		return
	
	# 创建动画器实例
	var animator = animator_scene.instantiate()
	root.add_child(animator)
	
	# 初始化角色数据
	var character_data = {
		"name": "测试角色",
		"team": "hero",
		"position": 0,
		"hp": 100,
		"max_hp": 100
	}
	
	animator.initialize_character(character_data)
	print("[调试] 角色初始化完成:", character_data.name)
	
	# 等待初始化完成
	await create_timer(0.5).timeout
	
	# 获取角色精灵节点
	var character_sprite = animator.get_node("CharacterSprite")
	if character_sprite:
		print("[调试] 找到角色精灵节点")
		print("[调试] 精灵初始modulate:", character_sprite.modulate)
		print("[调试] 精灵初始visible:", character_sprite.visible)
		print("[调试] 精灵初始position:", character_sprite.position)
	else:
		print("[错误] 未找到角色精灵节点")
		return
	
	# 测试1：直接修改modulate测试可见性
	print("\n[测试1] 直接修改modulate测试可见性")
	print("[测试1] 设置为极亮白色 (10, 10, 10, 1)")
	character_sprite.modulate = Color(10.0, 10.0, 10.0, 1.0)
	await create_timer(1.0).timeout
	
	print("[测试1] 设置为红色闪烁 (5, 0, 0, 1)")
	character_sprite.modulate = Color(5.0, 0.0, 0.0, 1.0)
	await create_timer(1.0).timeout
	
	print("[测试1] 恢复正常 (1, 1, 1, 1)")
	character_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	await create_timer(0.5).timeout
	
	# 测试2：使用Tween测试闪烁效果
	print("\n[测试2] 使用Tween测试闪烁效果")
	var tween = create_tween()
	tween.set_loops(3)
	
	print("[测试2] 开始Tween闪烁动画...")
	tween.tween_property(character_sprite, "modulate", Color(15.0, 15.0, 15.0, 1.0), 0.1)
	tween.tween_property(character_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
	
	await tween.finished
	print("[测试2] Tween闪烁动画完成")
	
	# 测试3：调用CharacterAnimator的闪烁方法
	print("\n[测试3] 调用CharacterAnimator的闪烁方法")
	print("[测试3] 调用普通受击闪烁...")
	animator.play_hit_animation(false)
	await create_timer(3.0).timeout
	
	print("[测试3] 调用暴击受击闪烁...")
	animator.play_hit_animation(true)
	await create_timer(4.0).timeout
	
	# 测试4：检查动画参数
	print("\n[测试4] 检查动画参数")
	if animator.has_method("_play_hit_flash_animation"):
		print("[测试4] CharacterAnimator有_play_hit_flash_animation方法")
	else:
		print("[测试4] CharacterAnimator没有_play_hit_flash_animation方法")
	
	# 测试5：手动创建超强闪烁效果
	print("\n[测试5] 手动创建超强闪烁效果")
	var manual_tween = create_tween()
	manual_tween.set_loops(5)
	
	print("[测试5] 手动超强闪烁 - 亮度20.0，持续0.3秒")
	for i in range(5):
		print("[测试5] 第%d次闪烁" % (i+1))
		character_sprite.modulate = Color(20.0, 20.0, 20.0, 1.0)
		await create_timer(0.3).timeout
		character_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		await create_timer(0.2).timeout
	
	print("\n=== 闪烁动画可见性测试总结 ===")
	print("✓ 直接modulate修改测试完成")
	print("✓ Tween动画测试完成")
	print("✓ CharacterAnimator方法测试完成")
	print("✓ 手动超强闪烁测试完成")
	print("请观察游戏窗口中的闪烁效果")