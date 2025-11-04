extends Node

func _ready():
	print("[增强受击动画测试] 开始测试")
	
	# 等待游戏初始化
	await get_tree().process_frame
	await get_tree().create_timer(3.0).timeout
	
	# 查找MainGame节点
	var main_game = get_node("/root/MainGame")
	if not main_game:
		print("[增强受击动画测试] 错误：找不到MainGame")
		return
	
	print("[增强受击动画测试] 找到MainGame")
	
	# 开始游戏循环
	var game_manager = main_game.game_manager
	if game_manager:
		print("[增强受击动画测试] 开始新循环")
		game_manager.start_new_loop()
		
		# 等待一秒后开始英雄移动
		await get_tree().create_timer(1.0).timeout
		
		var loop_manager = main_game.loop_manager
		if loop_manager and loop_manager.has_method("start_hero_movement"):
			print("[增强受击动画测试] 开始英雄移动")
			loop_manager.start_hero_movement()
			
			# 等待战斗触发
			print("[增强受击动画测试] 等待战斗触发...")
			await get_tree().create_timer(10.0).timeout
			
			# 检查BattleWindow
			var battle_window = main_game.get_node_or_null("UI/BattleWindow")
			if battle_window and battle_window.visible:
				print("[增强受击动画测试] 找到战斗窗口")
				
				# 检查动画控制器
				var anim_controller = battle_window.get_node_or_null("BattleAnimationController")
				if anim_controller:
					print("[增强受击动画测试] 找到动画控制器")
					
					# 增强受击动画测试
					await _test_enhanced_hit_animations(anim_controller, battle_window)
				else:
					print("[增强受击动画测试] 错误：找不到动画控制器")
			else:
				print("[增强受击动画测试] 战斗窗口未找到或不可见")

func _test_enhanced_hit_animations(anim_controller, battle_window):
	print("[增强受击动画测试] 开始增强动画测试")
	
	# 获取动画器容器
	var hero_container = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/HeroAnimators")
	var enemy_container = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/EnemyAnimators")
	
	if hero_container:
		print("[增强受击动画测试] 英雄容器 - 位置: %s, 可见: %s, 子节点: %d" % [
			hero_container.global_position, hero_container.visible, hero_container.get_child_count()
		])
	
	if enemy_container:
		print("[增强受击动画测试] 敌人容器 - 位置: %s, 可见: %s, 子节点: %d" % [
			enemy_container.global_position, enemy_container.visible, enemy_container.get_child_count()
		])
	
	# 测试1：普通受击动画
	print("[增强受击动画测试] === 测试1：英雄普通受击 ===")
	if anim_controller.has_method("play_team_damage_animation"):
		anim_controller.play_team_damage_animation("heroes", false)
		await get_tree().create_timer(1.5).timeout
		
		print("[增强受击动画测试] === 测试2：敌人普通受击 ===")
		anim_controller.play_team_damage_animation("enemies", false)
		await get_tree().create_timer(1.5).timeout
		
		print("[增强受击动画测试] === 测试3：敌人暴击受击 ===")
		anim_controller.play_team_damage_animation("enemies", true)
		await get_tree().create_timer(1.5).timeout
		
		print("[增强受击动画测试] === 测试4：连续受击测试 ===")
		for i in range(3):
			print("[增强受击动画测试] 连续受击 %d/3" % (i + 1))
			anim_controller.play_team_damage_animation("enemies", i == 2)  # 最后一次是暴击
			await get_tree().create_timer(0.8).timeout
	
	# 测试容器直接操作
	print("[增强受击动画测试] === 测试5：直接容器动画测试 ===")
	await _test_direct_container_animation(enemy_container)
	
	print("[增强受击动画测试] 所有测试完成")

func _test_direct_container_animation(container):
	if not container:
		print("[增强受击动画测试] 容器为空，跳过直接动画测试")
		return
	
	print("[增强受击动画测试] 开始直接容器动画测试")
	print("[增强受击动画测试] 容器初始位置: %s" % container.position)
	print("[增强受击动画测试] 容器初始颜色: %s" % container.modulate)
	
	# 创建更明显的抖动动画
	var tween = create_tween()
	var start_pos = container.position
	var shake_distance = 30  # 增大抖动距离
	
	print("[增强受击动画测试] 开始大幅抖动动画")
	tween.tween_property(container, "position", start_pos + Vector2(shake_distance, 0), 0.1)
	tween.tween_property(container, "position", start_pos + Vector2(-shake_distance, 0), 0.1)
	tween.tween_property(container, "position", start_pos + Vector2(shake_distance/2, 0), 0.1)
	tween.tween_property(container, "position", start_pos, 0.1)
	
	# 创建更明显的颜色变化
	var tween2 = create_tween()
	var original_color = container.modulate
	var hit_color = Color(1.0, 0.0, 0.0, 1.0)  # 纯红色
	
	print("[增强受击动画测试] 开始明显颜色变化")
	tween2.tween_property(container, "modulate", hit_color, 0.2)
	tween2.tween_property(container, "modulate", original_color, 0.3)
	
	await tween.finished
	await tween2.finished
	
	print("[增强受击动画测试] 直接容器动画测试完成")
	print("[增强受击动画测试] 容器最终位置: %s" % container.position)
	print("[增强受击动画测试] 容器最终颜色: %s" % container.modulate)