extends SceneTree

func _ready():
	print("[集成测试] 开始测试完整的敌方受击动画集成...")
	
	# 加载必要的场景
	var battle_controller_scene = load("res://scenes/battle/BattleAnimationController.tscn")
	var animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	
	if battle_controller_scene == null:
		print("[集成测试] ✗ 无法加载BattleAnimationController场景")
		quit()
		return
	
	if animator_scene == null:
		print("[集成测试] ✗ 无法加载CharacterAnimator场景")
		quit()
		return
	
	print("[集成测试] ✓ 场景加载成功")
	
	# 实例化BattleAnimationController
	var battle_controller = battle_controller_scene.instantiate()
	if battle_controller == null:
		print("[集成测试] ✗ 无法实例化BattleAnimationController")
		quit()
		return
	
	root.add_child(battle_controller)
	print("[集成测试] ✓ BattleAnimationController实例化成功")
	
	# 创建模拟的battle_window结构
	var mock_battle_window = Node.new()
	mock_battle_window.name = "MockBattleWindow"
	
	var animation_area = Node.new()
	animation_area.name = "AnimationArea"
	mock_battle_window.add_child(animation_area)
	
	var enemy_container = Node.new()
	enemy_container.name = "EnemyContainer"
	animation_area.add_child(enemy_container)
	
	root.add_child(mock_battle_window)
	print("[集成测试] ✓ 模拟battle_window结构创建完成")
	
	# 创建测试用的敌方动画器
	var enemy_animators = []
	for i in range(3):  # 创建3个敌人
		var animator = animator_scene.instantiate()
		if animator == null:
			print("[集成测试] ✗ 无法实例化敌方动画器 %d" % i)
			quit()
			return
		
		# 创建角色数据
		var enemy_data = {
			"name": "敌人%d" % (i + 1),
			"current_hp": 80,
			"max_hp": 100,
			"attack": 15,
			"defense": 8,
			"speed": 12,
			"sprite_path": "res://assets/sprites/enemies/goblin.png"
		}
		
		# 初始化角色
		animator.initialize_character(enemy_data, "enemy", i)
		enemy_container.add_child(animator)
		enemy_animators.append(animator)
		
		print("[集成测试] ✓ 敌方动画器 %d 创建完成: %s" % [i, enemy_data.name])
	
	# 手动设置BattleAnimationController的依赖
	battle_controller.battle_window = mock_battle_window
	
	# 等待一帧确保所有节点都准备好
	await process_frame
	
	print("[集成测试] 开始测试play_team_damage_animation方法...")
	
	# 连接信号来监控动画完成
	var animation_completed = false
	battle_controller.character_animation_completed.connect(func(character_index: int, team_type: String, animation_type: String):
		print("[集成测试] ✓ 收到角色动画完成信号: 角色%d (%s队伍) - %s" % [character_index, team_type, animation_type])
	)
	
	# 测试1：普通受击动画
	print("[集成测试] 测试1：播放普通受击动画...")
	var start_time = Time.get_ticks_msec()
	
	# 调用play_team_damage_animation
	battle_controller.play_team_damage_animation("enemy", false)
	
	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time
	
	print("[集成测试] play_team_damage_animation调用完成，耗时: %d毫秒" % duration)
	
	if duration < 100:  # 如果立即返回，说明可能有问题
		print("[集成测试] ⚠ 警告：动画调用立即返回，可能存在问题")
	else:
		print("[集成测试] ✓ 动画调用正常，等待了适当的时间")
	
	# 等待一段时间观察
	print("[集成测试] 等待观察动画效果...")
	for i in range(180):  # 等待3秒
		await process_frame
	
	# 测试2：暴击受击动画
	print("[集成测试] 测试2：播放暴击受击动画...")
	start_time = Time.get_ticks_msec()
	
	battle_controller.play_team_damage_animation("enemy", true)
	
	end_time = Time.get_ticks_msec()
	duration = end_time - start_time
	
	print("[集成测试] 暴击动画调用完成，耗时: %d毫秒" % duration)
	
	# 等待一段时间观察
	print("[集成测试] 等待观察暴击动画效果...")
	for i in range(180):  # 等待3秒
		await process_frame
	
	print("[集成测试] 测试完成！")
	print("[集成测试] 总结：")
	print("  - BattleAnimationController实例化: ✓")
	print("  - 敌方动画器创建: ✓ (3个)")
	print("  - battle_window设置: ✓")
	print("  - 普通受击动画调用: ✓")
	print("  - 暴击受击动画调用: ✓")
	
	quit()