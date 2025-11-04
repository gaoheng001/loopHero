extends SceneTree

# 深度调试敌方受击动画问题
# 重点检查敌方动画器初始化问题

func _init():
	print("=== 深度调试敌方动画器初始化问题 ===")
	
	# 加载主游戏场景
	var main_scene = load("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	
	# 等待场景初始化
	await process_frame
	await process_frame
	
	# 获取关键组件
	var battle_window = main_scene.get_node("UI/BattleWindow")
	
	if not battle_window:
		print("错误：无法找到BattleWindow")
		quit()
		return
	
	print("✓ BattleWindow获取成功")
	
	# 等待BattleAnimationController初始化
	await process_frame
	var bac = battle_window.get_node_or_null("BattleAnimationController")
	if not bac:
		print("错误：BattleAnimationController未找到")
		quit()
		return
	
	print("✓ BattleAnimationController获取成功")
	
	# 开始深度调试
	await _debug_enemy_animator_initialization(bac, battle_window, main_scene)
	
	print("=== 调试完成 ===")
	quit()

func _debug_enemy_animator_initialization(bac, battle_window, main_scene):
	print("\n--- 第1步：检查team_battle_manager状态 ---")
	
	# 检查team_battle_manager
	var team_battle_manager = bac.team_battle_manager
	print("team_battle_manager存在: %s" % (team_battle_manager != null))
	
	if team_battle_manager:
		print("team_battle_manager类型: %s" % team_battle_manager.get_class())
		print("team_battle_manager脚本: %s" % team_battle_manager.get_script())
		
		# 检查敌方队伍数据
		if team_battle_manager.has_method("get") or "enemy_team" in team_battle_manager:
			var enemy_team = team_battle_manager.enemy_team if "enemy_team" in team_battle_manager else null
			print("enemy_team存在: %s" % (enemy_team != null))
			if enemy_team:
				print("enemy_team大小: %d" % enemy_team.size())
				print("enemy_team内容: %s" % enemy_team)
			else:
				print("❌ enemy_team为null或不存在")
		else:
			print("❌ team_battle_manager没有enemy_team属性")
	else:
		print("❌ team_battle_manager为null")
	
	print("\n--- 第2步：检查动画器容器状态 ---")
	
	# 检查动画器容器
	var anim_area = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea")
	print("AnimationArea存在: %s" % (anim_area != null))
	
	if anim_area:
		var hero_container = anim_area.get_node_or_null("HeroAnimators")
		var enemy_container = anim_area.get_node_or_null("EnemyAnimators")
		
		print("HeroAnimators容器存在: %s" % (hero_container != null))
		print("EnemyAnimators容器存在: %s" % (enemy_container != null))
		
		if hero_container:
			print("HeroAnimators子节点数量: %d" % hero_container.get_child_count())
		if enemy_container:
			print("EnemyAnimators子节点数量: %d" % enemy_container.get_child_count())
	
	print("\n--- 第3步：手动触发战斗来初始化敌方队伍 ---")
	
	# 获取游戏管理器
	var game_manager = main_scene.get_node_or_null("GameManager")
	var hero_manager = main_scene.get_node_or_null("HeroManager")
	var battle_manager = main_scene.get_node_or_null("BattleManager")
	
	print("GameManager存在: %s" % (game_manager != null))
	print("HeroManager存在: %s" % (hero_manager != null))
	print("BattleManager存在: %s" % (battle_manager != null))
	
	if game_manager and hero_manager and battle_manager:
		# 手动创建测试队伍
		var test_hero_roster = [
			{"name": "测试英雄", "level": 1, "hp": 100, "max_hp": 100, "attack": 20, "defense": 5}
		]
		var test_enemy_roster = [
			{"name": "测试敌人", "level": 1, "hp": 80, "max_hp": 80, "attack": 15, "defense": 3}
		]
		
		print("创建测试队伍...")
		print("英雄队伍: %s" % test_hero_roster)
		print("敌方队伍: %s" % test_enemy_roster)
		
		# 手动调用show_team_battle
		if battle_window.has_method("show_team_battle"):
			print("调用show_team_battle...")
			battle_window.show_team_battle(test_hero_roster, test_enemy_roster)
			
			# 等待战斗初始化
			await process_frame
			await process_frame
			await process_frame
			
			print("\n--- 第4步：重新检查敌方动画器状态 ---")
			
			# 重新检查team_battle_manager
			team_battle_manager = bac.team_battle_manager
			if team_battle_manager and "enemy_team" in team_battle_manager:
				var enemy_team = team_battle_manager.enemy_team
				print("战斗初始化后 enemy_team大小: %d" % (enemy_team.size() if enemy_team else 0))
			
			# 重新检查敌方动画器
			print("战斗初始化后 敌方动画器数量: %d" % bac.enemy_animators.size())
			
			if bac.enemy_animators.size() > 0:
				print("✓ 敌方动画器创建成功!")
				for i in range(bac.enemy_animators.size()):
					var animator = bac.enemy_animators[i]
					print("敌方动画器 %d:" % i)
					print("  - 有效性: %s" % is_instance_valid(animator))
					print("  - 可见性: %s" % animator.visible)
					print("  - 位置: %s" % animator.global_position)
					
					# 检查CharacterSprite
					var sprite = animator.get_node_or_null("CharacterSprite")
					if sprite:
						print("  - CharacterSprite存在: true")
						print("    * 可见性: %s" % sprite.visible)
						print("    * 颜色: %s" % sprite.color)
					else:
						print("  - ❌ CharacterSprite不存在!")
					
					# 测试受击动画
					if animator.has_method("play_hit_animation"):
						print("  - ✓ play_hit_animation方法存在，测试动画...")
						animator.play_hit_animation(false)
						print("  - ✓ 动画调用成功")
						await get_tree().create_timer(1.0).timeout
					else:
						print("  - ❌ play_hit_animation方法不存在!")
			else:
				print("❌ 敌方动画器仍然为空!")
				
				# 手动调用_create_character_animators
				print("手动调用_create_character_animators...")
				if bac.has_method("_create_character_animators"):
					bac._create_character_animators()
					await process_frame
					print("手动创建后 敌方动画器数量: %d" % bac.enemy_animators.size())
		else:
			print("❌ BattleWindow没有show_team_battle方法")
	else:
		print("❌ 无法获取必要的管理器组件")