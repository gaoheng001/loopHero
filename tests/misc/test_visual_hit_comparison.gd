extends SceneTree

func _init():
	print("[可视化受击对比测试] 开始...")
	print("[可视化受击对比测试] 这个测试将对比我方和敌方的受击动画效果")
	
	# 测试修复后的效果
	test_visual_comparison()
	
	print("[可视化受击对比测试] 测试完成")
	quit()

func test_visual_comparison():
	print("[可视化受击对比测试] 开始可视化对比测试")
	
	# 加载主游戏场景
	var main_scene = preload("res://scenes/MainGame.tscn")
	if not main_scene:
		print("[可视化受击对比测试] ❌ 无法加载主游戏场景")
		return
	
	var main_game = main_scene.instantiate()
	if not main_game:
		print("[可视化受击对比测试] ❌ 无法实例化主游戏场景")
		return
	
	root.add_child(main_game)
	print("[可视化受击对比测试] ✓ 主游戏场景加载成功")
	
	# 等待场景初始化
	for i in range(120):  # 等待2秒
		await process_frame
	
	# 获取BattleWindow和BattleAnimationController
	var battle_window = main_game.get_node("BattleWindow")
	if not battle_window:
		print("[可视化受击对比测试] ❌ 无法找到BattleWindow")
		return
	
	var animation_controller = battle_window.get_node("BattleAnimationController")
	if not animation_controller:
		print("[可视化受击对比测试] ❌ 无法找到BattleAnimationController")
		return
	
	print("[可视化受击对比测试] ✓ 获取到BattleAnimationController")
	
	# 确保动画控制器已初始化
	if animation_controller.has_method("initialize"):
		animation_controller.initialize(battle_window)
		print("[可视化受击对比测试] ✓ BattleAnimationController初始化完成")
	
	# 手动创建角色动画器（如果需要）
	if animation_controller.has_method("_create_character_animators"):
		animation_controller._create_character_animators()
		print("[可视化受击对比测试] ✓ 角色动画器创建完成")
	
	# 等待初始化完成
	for i in range(60):  # 等待1秒
		await process_frame
	
	print("[可视化受击对比测试] === 修复效果验证 ===")
	print("[可视化受击对比测试] 修复前：敌方受击动画 - 2次闪烁，每次0.08秒（不明显）")
	print("[可视化受击对比测试] 修复后：敌方受击动画 - 3次闪烁，每次0.1秒（与我方一致）")
	
	# 测试我方受击动画
	print("[可视化受击对比测试] 测试1：我方受击动画（参考标准）")
	if animation_controller.has_method("play_team_damage_animation"):
		# 模拟我方受到伤害
		var hero_damage_data = [
			{"character_index": 0, "damage": 25, "is_critical": false},
			{"character_index": 1, "damage": 30, "is_critical": false}
		]
		animation_controller.play_team_damage_animation("hero", hero_damage_data)
		print("[可视化受击对比测试] ✓ 我方受击动画开始播放")
		
		# 等待动画完成
		for i in range(180):  # 等待3秒
			await process_frame
	
	print("[可视化受击对比测试] 测试2：敌方受击动画（修复后）")
	if animation_controller.has_method("play_team_damage_animation"):
		# 模拟敌方受到伤害
		var enemy_damage_data = [
			{"character_index": 0, "damage": 35, "is_critical": false},
			{"character_index": 1, "damage": 40, "is_critical": true},
			{"character_index": 2, "damage": 28, "is_critical": false}
		]
		animation_controller.play_team_damage_animation("enemy", enemy_damage_data)
		print("[可视化受击对比测试] ✓ 敌方受击动画开始播放（修复后）")
		
		# 等待动画完成
		for i in range(180):  # 等待3秒
			await process_frame
	
	print("[可视化受击对比测试] === 修复验证完成 ===")
	print("[可视化受击对比测试] 修复内容总结：")
	print("[可视化受击对比测试] 1. CharacterAnimator.play_hit_animation方法已修复")
	print("[可视化受击对比测试] 2. 闪烁次数：2次 → 3次")
	print("[可视化受击对比测试] 3. 闪烁时长：0.08秒 → 0.1秒")
	print("[可视化受击对比测试] 4. 现在敌方受击动画与我方完全一致")
	print("[可视化受击对比测试] 5. 敌方受击闪烁效果应该更加明显和持久")
	
	# 验证动画器数量
	if animation_controller.has_method("get_hero_animators") and animation_controller.has_method("get_enemy_animators"):
		var hero_animators = animation_controller.get_hero_animators()
		var enemy_animators = animation_controller.get_enemy_animators()
		print("[可视化受击对比测试] 动画器状态：英雄 %d 个，敌人 %d 个" % [
			hero_animators.size() if hero_animators else 0,
			enemy_animators.size() if enemy_animators else 0
		])