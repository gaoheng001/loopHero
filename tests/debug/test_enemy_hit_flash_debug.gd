extends SceneTree

func _init():
	print("=== 敌方受击闪烁动画直接测试 ===")
	
	# 创建一个简单的测试场景
	var test_scene = Node2D.new()
	root.add_child(test_scene)
	
	# 加载CharacterAnimator脚本
	var character_animator_script = load("res://scripts/battle/CharacterAnimator.gd")
	
	# 创建敌方动画器
	var enemy_animator = Control.new()
	enemy_animator.set_script(character_animator_script)
	test_scene.add_child(enemy_animator)
	
	# 创建精灵节点（使用ColorRect）
	var sprite = ColorRect.new()
	sprite.name = "CharacterSprite"
	sprite.size = Vector2(64, 64)
	sprite.color = Color.RED  # 红色背景模拟敌方
	enemy_animator.add_child(sprite)
	
	print("✓ 创建了敌方精灵，初始颜色: 红色")
	print("✓ 初始modulate: ", sprite.modulate)
	
	# 初始化动画器
	enemy_animator.team_type = "enemy"
	enemy_animator.character_sprite = sprite
	enemy_animator.animation_speed = 1.0
	enemy_animator.current_animation = ""
	
	print("✓ 敌方动画器初始化完成")
	print("✓ team_type: ", enemy_animator.team_type)
	
	# 等待一帧
	await process_frame
	
	print("\n=== 测试1: 敌方普通受击闪烁 ===")
	print("🔥 [调试] 调用前modulate=", sprite.modulate)
	print("🔥 [调试] team_type=", enemy_animator.team_type)
	enemy_animator.play_hit_animation(false)
	print("🔥 [调试] 调用后modulate=", sprite.modulate)
	
	# 监控modulate变化
	for i in range(30):
		await process_frame
		print("第", i+1, "帧 modulate: ", sprite.modulate)
		if i == 10:
			print("--- 10帧后检查 ---")
	
	print("\n=== 测试2: 敌方暴击受击闪烁 ===")
	enemy_animator.play_hit_animation(true)
	
	# 监控modulate变化
	for i in range(30):
		await process_frame
		print("暴击第", i+1, "帧 modulate: ", sprite.modulate)
		if i == 10:
			print("--- 暴击10帧后检查 ---")
	
	print("\n=== 测试完成 ===")
	print("最终modulate: ", sprite.modulate)
	quit()