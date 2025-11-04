extends SceneTree

func _init():
	# 加载主场景
	var main_scene = preload("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	
	# 等待场景初始化后开始测试
	call_deferred("start_test")

func start_test():
	print("[敌方闪烁调试] 开始测试...")
	
	# 等待场景初始化
	await process_frame
	await process_frame
	
	# 查找BattleWindow
	var battle_window = _find_battle_window(root)
	if not battle_window:
		print("[敌方闪烁调试] ❌ 未找到BattleWindow")
		quit()
		return
	
	print("[敌方闪烁调试] ✓ 找到BattleWindow: %s" % battle_window.name)
	
	# 获取BattleAnimationController
	var animation_controller = battle_window.get_node_or_null("BattleAnimationController")
	if not animation_controller:
		print("[敌方闪烁调试] ❌ 未找到BattleAnimationController")
		quit()
		return
	
	print("[敌方闪烁调试] ✓ 找到BattleAnimationController")
	
	# 获取TeamBattleManager（它是BattleWindow的属性，不是子节点）
	var team_battle_manager = battle_window.get("team_battle_manager")
	if not team_battle_manager:
		print("[敌方闪烁调试] ❌ TeamBattleManager未初始化，尝试创建...")
		# 手动创建TeamBattleManager
		var TeamBattleManagerScript = load("res://scripts/TeamBattleManager.gd")
		team_battle_manager = TeamBattleManagerScript.new()
		battle_window.set("team_battle_manager", team_battle_manager)
		print("[敌方闪烁调试] ✓ 创建了TeamBattleManager")
	else:
		print("[敌方闪烁调试] ✓ 找到TeamBattleManager")
	
	# 为TeamBattleManager设置测试队伍数据
	var test_hero_team = [
		{"name": "测试英雄1", "hp": 100, "max_hp": 100, "attack": 20},
		{"name": "测试英雄2", "hp": 80, "max_hp": 100, "attack": 15}
	]
	var test_enemy_team = [
		{"name": "测试敌人1", "hp": 60, "max_hp": 60, "attack": 18},
		{"name": "测试敌人2", "hp": 70, "max_hp": 70, "attack": 12}
	]
	
	# 设置队伍数据
	team_battle_manager.set("hero_team", test_hero_team)
	team_battle_manager.set("enemy_team", test_enemy_team)
	print("[敌方闪烁调试] 设置了测试队伍数据")
	
	# 初始化动画控制器
	if animation_controller.has_method("initialize"):
		print("[敌方闪烁调试] 初始化动画控制器...")
		animation_controller.initialize(team_battle_manager, battle_window)
		await process_frame
		await process_frame
	
	# 手动创建动画器（因为测试环境下没有触发战斗）
	if animation_controller.has_method("_create_character_animators"):
		print("[敌方闪烁调试] 手动创建角色动画器...")
		animation_controller._create_character_animators()
		await process_frame
		await process_frame
	
	# 获取敌方动画器
	var enemy_animators = animation_controller.get("enemy_animators")
	if not enemy_animators:
		print("[敌方闪烁调试] ❌ 敌方动画器数组为空")
		quit()
		return
	
	print("[敌方闪烁调试] ✓ 敌方动画器数量: %d" % enemy_animators.size())
	
	# 检查每个敌方动画器
	for i in range(enemy_animators.size()):
		var animator = enemy_animators[i]
		if not animator or not is_instance_valid(animator):
			print("[敌方闪烁调试] ❌ 敌方动画器%d无效" % i)
			continue
		
		print("[敌方闪烁调试] 检查敌方动画器%d:" % i)
		print("  - 类型: %s" % animator.get_class())
		print("  - 可见: %s" % animator.visible)
		print("  - 位置: %s" % animator.global_position)
		print("  - 尺寸: %s" % animator.size)
		
		# 检查CharacterSprite
		var sprite = animator.get_node_or_null("CharacterSprite")
		if sprite:
			print("  - CharacterSprite存在:")
			print("    - 可见: %s" % sprite.visible)
			print("    - 位置: %s" % sprite.global_position)
			print("    - 颜色: %s" % sprite.color)
			print("    - 调制: %s" % sprite.modulate)
		else:
			print("  - ❌ CharacterSprite不存在")
		
		# 检查是否有play_hit_animation方法
	if animator.has_method("play_hit_animation"):
		print("  - ✓ 有play_hit_animation方法")
	else:
		print("  - ❌ 没有play_hit_animation方法")
	
	# 测试敌方受击闪烁动画
	print("\n[敌方闪烁调试] 开始测试敌方受击闪烁...")
	
	if enemy_animators.size() > 0:
		var first_animator = enemy_animators[0]
		if first_animator and is_instance_valid(first_animator) and first_animator.has_method("play_hit_animation"):
			print("[敌方闪烁调试] 测试第一个敌方动画器的闪烁效果...")
			
			# 获取sprite用于观察颜色变化
			var sprite = first_animator.get_node_or_null("CharacterSprite")
			if sprite:
				print("  - 闪烁前颜色: %s" % sprite.color)
				print("  - 闪烁前调制: %s" % sprite.modulate)
				
				# 播放闪烁动画
				first_animator.play_hit_animation(false)  # 普通受击
				
				# 等待一小段时间观察颜色变化
				await process_frame
				await process_frame
				print("  - 闪烁中颜色: %s" % sprite.color)
				print("  - 闪烁中调制: %s" % sprite.modulate)
				
				# 等待动画完成
				if first_animator.has_signal("animation_completed"):
					await first_animator.animation_completed
				else:
					await create_timer(1.0).timeout
				
				print("  - 闪烁后颜色: %s" % sprite.color)
				print("  - 闪烁后调制: %s" % sprite.modulate)
			else:
				print("  - ❌ 无法获取CharacterSprite进行观察")
		else:
		print("[敌方闪烁调试] ❌ 第一个敌方动画器无效或没有play_hit_animation方法")
	
	# 测试通过BattleAnimationController播放队伍受击动画
	print("\n[敌方闪烁调试] 测试通过BattleAnimationController播放敌方队伍受击动画...")
	
	if animation_controller.has_method("play_team_damage_animation"):
		print("[敌方闪烁调试] 调用play_team_damage_animation('enemies', false)...")
		animation_controller.play_team_damage_animation("enemies", false)
		
		# 等待动画完成
		await create_timer(2.0).timeout
		print("[敌方闪烁调试] 队伍受击动画测试完成")
	else:
		print("[敌方闪烁调试] ❌ BattleAnimationController没有play_team_damage_animation方法")
	
	print("\n[敌方闪烁调试] 测试完成")
	quit()

func _find_battle_window(node: Node) -> Node:
	"""递归查找BattleWindow节点"""
	if node.name == "BattleWindow":
		return node
	
	for child in node.get_children():
		var result = _find_battle_window(child)
		if result:
			return result
	
	return null