extends Node

func _ready():
	print("[HitAnimationTest] 开始测试受击动画")
	
	# 等待游戏初始化
	await get_tree().process_frame
	await get_tree().create_timer(3.0).timeout
	
	# 查找MainGame节点
	var main_game = get_node("/root/MainGame")
	if not main_game:
		print("[HitAnimationTest] 错误：找不到MainGame")
		return
	
	print("[HitAnimationTest] 找到MainGame")
	
	# 开始游戏循环
	var game_manager = main_game.game_manager
	if game_manager:
		print("[HitAnimationTest] 开始新循环")
		game_manager.start_new_loop()
		
		# 等待一秒后开始英雄移动
		await get_tree().create_timer(1.0).timeout
		
		var loop_manager = main_game.loop_manager
		if loop_manager and loop_manager.has_method("start_hero_movement"):
			print("[HitAnimationTest] 开始英雄移动")
			loop_manager.start_hero_movement()
			
			# 等待战斗触发
			print("[HitAnimationTest] 等待战斗触发...")
			await get_tree().create_timer(10.0).timeout
			
			# 检查BattleWindow
			var battle_window = main_game.get_node_or_null("UI/BattleWindow")
			if battle_window and battle_window.visible:
				print("[HitAnimationTest] 找到战斗窗口")
				
				# 检查动画控制器
				var anim_controller = battle_window.get_node_or_null("BattleAnimationController")
				if anim_controller:
					print("[HitAnimationTest] 找到动画控制器")
					
					# 检查动画器容器
					var hero_container = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/HeroAnimators")
					var enemy_container = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/EnemyAnimators")
					
					if hero_container:
						print("[HitAnimationTest] 英雄容器找到，子节点数量: ", hero_container.get_child_count())
						print("[HitAnimationTest] 英雄容器位置: ", hero_container.global_position)
						print("[HitAnimationTest] 英雄容器可见: ", hero_container.visible)
					else:
						print("[HitAnimationTest] 错误：找不到英雄容器")
					
					if enemy_container:
						print("[HitAnimationTest] 敌人容器找到，子节点数量: ", enemy_container.get_child_count())
						print("[HitAnimationTest] 敌人容器位置: ", enemy_container.global_position)
						print("[HitAnimationTest] 敌人容器可见: ", enemy_container.visible)
					else:
						print("[HitAnimationTest] 错误：找不到敌人容器")
					
					# 手动测试受击动画
					print("[HitAnimationTest] 手动测试英雄受击动画")
					if anim_controller.has_method("play_team_damage_animation"):
						anim_controller.play_team_damage_animation("heroes", false)
						await get_tree().create_timer(1.0).timeout
						
						print("[HitAnimationTest] 手动测试敌人受击动画")
						anim_controller.play_team_damage_animation("enemies", false)
						await get_tree().create_timer(1.0).timeout
						
						print("[HitAnimationTest] 手动测试敌人暴击受击动画")
						anim_controller.play_team_damage_animation("enemies", true)
				else:
					print("[HitAnimationTest] 错误：找不到动画控制器")
			else:
				print("[HitAnimationTest] 战斗窗口未找到或不可见")