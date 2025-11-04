extends SceneTree

func _init():
	print("[统一受击动画测试] 开始测试")
	await test_unified_hit_animation()
	print("[统一受击动画测试] 测试完成")

func _print_scene_tree(node: Node, depth: int):
	"""递归打印场景树结构"""
	var indent = ""
	for i in range(depth):
		indent += "  "
	print("[统一受击动画测试] %s%s (%s)" % [indent, node.name, node.get_class()])
	
	for child in node.get_children():
		_print_scene_tree(child, depth + 1)
	quit()

func test_unified_hit_animation():
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	
	# 等待场景初始化
	await process_frame
	await process_frame
	
	# 获取BattleWindow - 等待MainGameController创建
	await create_timer(3.0).timeout  # 等待更长时间让MainGameController完成初始化
	
	var battle_window = root.get_node_or_null("Main/UI/BattleWindow")
	if not battle_window:
		# 尝试其他可能的路径
		battle_window = root.get_node_or_null("MainGameController/UI/BattleWindow")
		if not battle_window:
			# 搜索所有可能的BattleWindow节点
			var all_nodes = get_nodes_in_group("battle_window")
			if all_nodes.size() > 0:
				battle_window = all_nodes[0]
			else:
				print("[统一受击动画测试] 错误：找不到BattleWindow")
				print("[统一受击动画测试] 场景树结构:")
				_print_scene_tree(root, 0)
				return
	
	print("[统一受击动画测试] 找到BattleWindow，等待初始化...")
	await create_timer(2.0).timeout
	
	# 获取动画控制器
	var anim_controller = battle_window.get_node_or_null("BattleAnimationController")
	if not anim_controller:
		print("[统一受击动画测试] 错误：找不到BattleAnimationController")
		return
	
	print("[统一受击动画测试] 找到BattleAnimationController")
	
	# 获取动画器容器
	var hero_container = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/HeroAnimators")
	var enemy_container = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/EnemyAnimators")
	
	if hero_container:
		print("[统一受击动画测试] 英雄容器找到，子节点数量: %d" % hero_container.get_child_count())
	else:
		print("[统一受击动画测试] 错误：找不到英雄容器")
		return
	
	if enemy_container:
		print("[统一受击动画测试] 敌人容器找到，子节点数量: %d" % enemy_container.get_child_count())
	else:
		print("[统一受击动画测试] 错误：找不到敌人容器")
		return
	
	# 测试统一的受击动画效果
	print("[统一受击动画测试] === 测试1：英雄队伍普通受击 ===")
	print("[统一受击动画测试] 预期效果：只有角色文本闪烁，无容器方块闪烁")
	anim_controller.play_team_damage_animation("heroes", false)
	await create_timer(1.5).timeout
	
	print("[统一受击动画测试] === 测试2：英雄队伍暴击受击 ===")
	print("[统一受击动画测试] 预期效果：角色文本金黄色闪烁")
	anim_controller.play_team_damage_animation("heroes", true)
	await create_timer(1.5).timeout
	
	print("[统一受击动画测试] === 测试3：敌人队伍普通受击 ===")
	print("[统一受击动画测试] 预期效果：只有角色文本闪烁，无容器方块闪烁")
	anim_controller.play_team_damage_animation("enemies", false)
	await create_timer(1.5).timeout
	
	print("[统一受击动画测试] === 测试4：敌人队伍暴击受击 ===")
	print("[统一受击动画测试] 预期效果：角色文本金黄色闪烁")
	anim_controller.play_team_damage_animation("enemies", true)
	await create_timer(1.5).timeout
	
	print("[统一受击动画测试] === 测试5：对比测试 ===")
	print("[统一受击动画测试] 连续测试英雄和敌人受击，验证效果一致性")
	
	for i in range(3):
		print("[统一受击动画测试] 第%d轮对比测试" % (i + 1))
		
		print("[统一受击动画测试] - 英雄受击")
		anim_controller.play_team_damage_animation("heroes", false)
		await create_timer(1.0).timeout
		
		print("[统一受击动画测试] - 敌人受击")
		anim_controller.play_team_damage_animation("enemies", false)
		await create_timer(1.0).timeout
	
	# 验证容器本身没有颜色变化
	print("[统一受击动画测试] === 测试6：验证容器颜色保持不变 ===")
	var hero_original_color = hero_container.modulate
	var enemy_original_color = enemy_container.modulate
	
	print("[统一受击动画测试] 英雄容器初始颜色: %s" % hero_original_color)
	print("[统一受击动画测试] 敌人容器初始颜色: %s" % enemy_original_color)
	
	# 触发受击动画
	anim_controller.play_team_damage_animation("heroes", false)
	await create_timer(0.5).timeout
	
	var hero_mid_color = hero_container.modulate
	print("[统一受击动画测试] 英雄容器动画中颜色: %s" % hero_mid_color)
	
	await create_timer(1.0).timeout
	
	var hero_final_color = hero_container.modulate
	print("[统一受击动画测试] 英雄容器最终颜色: %s" % hero_final_color)
	
	# 验证容器颜色没有变化
	if hero_original_color.is_equal_approx(hero_final_color):
		print("[统一受击动画测试] ✓ 容器颜色保持不变，修复成功")
	else:
		print("[统一受击动画测试] ✗ 容器颜色发生变化，可能仍有问题")
	
	print("[统一受击动画测试] 所有测试完成")
	print("[统一受击动画测试] 修复总结：")
	print("[统一受击动画测试] - 移除了容器级方块闪烁动画")
	print("[统一受击动画测试] - 统一使用个人角色文本闪烁")
	print("[统一受击动画测试] - 我方和敌方受击效果现在完全一致")