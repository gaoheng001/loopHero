extends SceneTree

func _init():
	print("[完整集成测试] 开始测试BattleAnimationController完整集成")
	
	# 获取根节点
	var root = get_root()
	
	# 创建模拟的battle_window结构
	var battle_window = Control.new()
	battle_window.name = "BattleWindow"
	root.add_child(battle_window)
	
	# 创建完整的节点结构
	var battle_panel = Control.new()
	battle_panel.name = "BattlePanel"
	battle_window.add_child(battle_panel)
	
	var main_container = Control.new()
	main_container.name = "MainContainer"
	battle_panel.add_child(main_container)
	
	var content_container = Control.new()
	content_container.name = "ContentContainer"
	main_container.add_child(content_container)
	
	var battle_area = Control.new()
	battle_area.name = "BattleArea"
	content_container.add_child(battle_area)
	
	var animation_area = Control.new()
	animation_area.name = "AnimationArea"
	battle_area.add_child(animation_area)
	
	var hero_animators = Control.new()
	hero_animators.name = "HeroAnimators"
	animation_area.add_child(hero_animators)
	
	var enemy_animators = Control.new()
	enemy_animators.name = "EnemyAnimators"
	animation_area.add_child(enemy_animators)
	
	print("[完整集成测试] ✓ 创建了完整的battle_window结构")
	
	# 加载BattleAnimationController场景
	var bac_scene = load("res://scenes/battle/BattleAnimationController.tscn")
	if not bac_scene:
		print("[完整集成测试] ❌ 无法加载BattleAnimationController场景")
		return
	
	var bac = bac_scene.instantiate()
	if not bac:
		print("[完整集成测试] ❌ 无法实例化BattleAnimationController")
		return
	
	root.add_child(bac)
	print("[完整集成测试] ✓ BattleAnimationController实例化成功")
	
	# 创建真正的TeamBattleManager实例
	var team_battle_manager = preload("res://scripts/TeamBattleManager.gd").new()
	team_battle_manager.name = "TeamBattleManager"
	root.add_child(team_battle_manager)
	
	# 设置队伍数据
	team_battle_manager.hero_team = [
		{"name": "英雄1", "current_hp": 100, "max_hp": 100, "attack": 20},
		{"name": "英雄2", "current_hp": 80, "max_hp": 100, "attack": 15}
	]
	team_battle_manager.enemy_team = [
		{"name": "敌人1", "current_hp": 60, "max_hp": 80, "attack": 12},
		{"name": "敌人2", "current_hp": 50, "max_hp": 70, "attack": 10},
		{"name": "敌人3", "current_hp": 40, "max_hp": 60, "attack": 8}
	]
	
	print("[完整集成测试] ✓ 创建了模拟的TeamBattleManager")
	
	# 初始化BattleAnimationController
	if bac.has_method("initialize"):
		bac.initialize(team_battle_manager, battle_window)
		print("[完整集成测试] ✓ BattleAnimationController初始化成功")
		
		# 手动创建角色动画器
		bac._create_character_animators()
		print("[完整集成测试] ✓ 角色动画器创建完成")
	else:
		print("[完整集成测试] ❌ BattleAnimationController没有initialize方法")
		return
	
	# 等待一帧让初始化完成
	await process_frame
	
	# 检查动画器是否创建成功
	print("[完整集成测试] 检查动画器创建状态...")
	print("[完整集成测试] battle_window: %s" % battle_window)
	print("[完整集成测试] hero_animators数量: %d" % bac.hero_animators.size())
	print("[完整集成测试] enemy_animators数量: %d" % bac.enemy_animators.size())
	
	# 检查容器中的子节点
	print("[完整集成测试] HeroAnimators容器子节点数量: %d" % hero_animators.get_child_count())
	print("[完整集成测试] EnemyAnimators容器子节点数量: %d" % enemy_animators.get_child_count())
	
	# 测试队伍受击动画
	print("\n[完整集成测试] 开始测试敌方队伍受击动画...")
	
	# 连接信号监控
	var signals_received = []
	
	# 为每个敌方动画器连接信号
	for i in range(bac.enemy_animators.size()):
		var animator = bac.enemy_animators[i]
		if animator and animator.has_signal("animation_completed"):
			animator.animation_completed.connect(func(animation_type): 
				signals_received.append({"animator": i, "type": animation_type})
				print("[完整集成测试] 收到敌方动画器[%d]信号: %s" % [i, animation_type])
			)
	
	# 测试普通受击动画
	if bac.has_method("play_team_damage_animation"):
		print("[完整集成测试] 调用play_team_damage_animation(enemies, false)...")
		bac.play_team_damage_animation("enemies", false)
		print("[完整集成测试] ✓ 普通受击动画调用成功")
		
		# 等待动画完成
		for i in range(180): # 等待3秒 (60fps * 3)
			await process_frame
		
		print("[完整集成测试] 普通受击动画完成，收到信号数量: %d" % signals_received.size())
		for signal_data in signals_received:
			print("[完整集成测试] - 动画器[%d]: %s" % [signal_data.animator, signal_data.type])
		
		# 清空信号记录
		signals_received.clear()
		
		# 测试暴击受击动画
		print("\n[完整集成测试] 测试暴击受击动画...")
		bac.play_team_damage_animation("enemies", true)
		print("[完整集成测试] ✓ 暴击受击动画调用成功")
		
		# 等待动画完成
		for i in range(180): # 等待3秒 (60fps * 3)
			await process_frame
		
		print("[完整集成测试] 暴击受击动画完成，收到信号数量: %d" % signals_received.size())
		for signal_data in signals_received:
			print("[完整集成测试] - 动画器[%d]: %s" % [signal_data.animator, signal_data.type])
		
	else:
		print("[完整集成测试] ❌ BattleAnimationController没有play_team_damage_animation方法")
	
	print("\n[完整集成测试] 测试完成")
	quit()