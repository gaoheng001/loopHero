# test_battle_animation_direct.gd
# 直接测试战斗动画系统的创建和配置

extends SceneTree

func _init():
	print("=== 开始测试战斗动画系统 ===")
	
	# 创建主游戏控制器
	var main_controller = MainGameController.new()
	main_controller.name = "MainGameController"
	
	# 创建BattleWindow实例
	var battle_window_scene = preload("res://scenes/BattleWindow.tscn")
	var battle_window = battle_window_scene.instantiate()
	print("[测试] BattleWindow实例创建成功:", battle_window)
	print("[测试] BattleWindow脚本:", battle_window.get_script())
	
	# 添加到场景树
	root.add_child(main_controller)
	main_controller.add_child(battle_window)
	print("[测试] BattleWindow已添加到场景树")
	
	# 等待几帧让_ready方法执行
	for i in range(5):
		await process_frame
	print("[测试] 等待_ready方法执行完成")
	
	# 检查BattleAnimationController是否正确创建
	var animation_controller = battle_window.get_node_or_null("BattleAnimationController")
	print("[测试] BattleAnimationController节点:", animation_controller)
	
	if animation_controller != null:
		print("[测试] ✓ BattleAnimationController创建成功")
		print("[测试] 节点类型:", animation_controller.get_class())
		print("[测试] 脚本:", animation_controller.get_script())
		
		# 检查是否有必要的方法
		var has_create_method = animation_controller.has_method("_create_character_animators")
		var has_battle_started_method = animation_controller.has_method("_on_battle_started")
		print("[测试] 有_create_character_animators方法:", has_create_method)
		print("[测试] 有_on_battle_started方法:", has_battle_started_method)
		
		# 测试创建角色动画器
		if has_create_method:
			print("[测试] 开始测试角色动画器创建...")
			
			# 创建模拟的TeamBattleManager
			var team_manager = TeamBattleManager.new()
			team_manager.name = "TeamBattleManager"
			main_controller.add_child(team_manager)
			
			# 设置模拟数据
			team_manager.hero_team = [
				{"id": "hero1", "name": "英雄1", "hp": 100, "max_hp": 100, "attack": 20, "defense": 10},
				{"id": "hero2", "name": "英雄2", "hp": 80, "max_hp": 80, "attack": 15, "defense": 8}
			]
			team_manager.enemy_team = [
				{"id": "enemy1", "name": "敌人1", "hp": 60, "max_hp": 60, "attack": 12, "defense": 5},
				{"id": "enemy2", "name": "敌人2", "hp": 70, "max_hp": 70, "attack": 18, "defense": 7}
			]
			
			# 设置animation_controller的team_battle_manager引用
			animation_controller.team_battle_manager = team_manager
			
			# 调用创建角色动画器方法
			animation_controller._create_character_animators()
			
			# 检查动画器是否创建成功
			var hero_animators = animation_controller.get("hero_animators")
			var enemy_animators = animation_controller.get("enemy_animators")
			print("[测试] 英雄动画器数量:", hero_animators.size() if hero_animators else 0)
			print("[测试] 敌人动画器数量:", enemy_animators.size() if enemy_animators else 0)
			
			if hero_animators and hero_animators.size() > 0:
				print("[测试] ✓ 英雄动画器创建成功")
				for i in range(hero_animators.size()):
					var animator = hero_animators[i]
					print("[测试] 英雄动画器", i, ":", animator.get_character_data())
			
			if enemy_animators and enemy_animators.size() > 0:
				print("[测试] ✓ 敌人动画器创建成功")
				for i in range(enemy_animators.size()):
					var animator = enemy_animators[i]
					print("[测试] 敌人动画器", i, ":", animator.get_character_data())
		
	else:
		print("[测试] ✗ BattleAnimationController创建失败")
	
	print("=== 测试完成 ===")
	quit()