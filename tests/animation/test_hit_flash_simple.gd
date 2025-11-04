extends SceneTree

func _init():
	print("[简单受击闪烁测试] 开始测试")
	
	# 创建一个简单的测试场景
	var test_scene = Node2D.new()
	root.add_child(test_scene)
	
	# 创建CharacterSprite节点
	var hero_sprite = Sprite2D.new()
	hero_sprite.name = "HeroSprite"
	hero_sprite.modulate = Color.BLUE  # 英雄蓝色
	test_scene.add_child(hero_sprite)
	
	var enemy_sprite = Sprite2D.new()
	enemy_sprite.name = "EnemySprite"
	enemy_sprite.modulate = Color.RED   # 敌方红色
	test_scene.add_child(enemy_sprite)
	
	# 等待一帧
	await process_frame
	
	print("--- 初始状态 ---")
	print("英雄modulate: ", hero_sprite.modulate)
	print("敌方modulate: ", enemy_sprite.modulate)
	
	# 测试英雄受击闪烁（红色）
	print("\n--- 测试英雄普通受击（红色闪烁） ---")
	test_hit_flash(hero_sprite, false, "hero")
	await get_timer(1.5)
	print("英雄受击后modulate: ", hero_sprite.modulate)
	
	# 测试敌方受击闪烁（白色）
	print("\n--- 测试敌方普通受击（白色闪烁） ---")
	test_hit_flash(enemy_sprite, false, "enemy")
	await get_timer(1.5)
	print("敌方受击后modulate: ", enemy_sprite.modulate)
	
	# 测试英雄暴击受击（金黄色）
	print("\n--- 测试英雄暴击受击（金黄色闪烁） ---")
	test_hit_flash(hero_sprite, true, "hero")
	await get_timer(1.5)
	print("英雄暴击后modulate: ", hero_sprite.modulate)
	
	# 测试敌方暴击受击（金黄色）
	print("\n--- 测试敌方暴击受击（金黄色闪烁） ---")
	test_hit_flash(enemy_sprite, true, "enemy")
	await get_timer(1.5)
	print("敌方暴击后modulate: ", enemy_sprite.modulate)
	
	# 连续对比测试
	print("\n--- 连续对比测试 ---")
	for i in range(3):
		print("第", i+1, "轮对比测试")
		
		print("  英雄普通受击...")
		test_hit_flash(hero_sprite, false, "hero")
		await get_timer(0.8)
		
		print("  敌方普通受击...")
		test_hit_flash(enemy_sprite, false, "enemy")
		await get_timer(0.8)
	
	print("\n[简单受击闪烁测试] 测试完成！")
	print("修复效果说明：")
	print("- 英雄（蓝色）：普通受击用红色闪烁，暴击用金黄色闪烁")
	print("- 敌方（红色）：普通受击用白色闪烁（更明显），暴击用金黄色闪烁")
	
	quit()

# 模拟CharacterAnimator的play_hit_animation方法（修复后的版本）
func test_hit_flash(sprite: Sprite2D, is_critical: bool, team_type: String):
	var original_modulate = sprite.modulate
	var flash_color: Color
	
	if is_critical:
		# 暴击时使用金黄色闪烁
		flash_color = Color(1.0, 0.8, 0.0, 1.0)  # 金黄色
	else:
		# 普通受击时根据队伍类型选择颜色
		if team_type == "hero":
			flash_color = Color.RED  # 英雄用红色闪烁
		else:
			flash_color = Color.WHITE  # 敌方用白色闪烁，在红色背景上更明显
	
	print("    闪烁颜色: ", flash_color)
	
	# 创建闪烁动画
	var tween = create_tween()
	tween.set_loops(3)  # 闪烁3次
	
	# 每次闪烁：变为闪烁颜色 -> 恢复原色
	tween.tween_property(sprite, "modulate", flash_color, 0.1)
	tween.tween_property(sprite, "modulate", original_modulate, 0.1)

func get_timer(duration: float):
	return create_timer(duration).timeout