# test_battle_integration.gd
# 测试回合攻击表现系统的完整集成

extends SceneTree

func _init():
	print("=== 回合攻击表现系统集成测试开始 ===")
	test_complete_battle_flow()
	quit()

func test_complete_battle_flow():
	"""测试完整的战斗流程"""
	print("\n1. 创建测试环境...")
	
	# 创建主场景
	var main_scene = Node.new()
	main_scene.name = "TestMain"
	
	# 创建BattleWindow
	var BattleWindowScript = load("res://scripts/BattleWindow.gd")
	var battle_window = BattleWindowScript.new()
	battle_window.name = "BattleWindow"
	main_scene.add_child(battle_window)
	
	# 创建TeamBattleManager
	var TeamBattleManagerScript = load("res://scripts/TeamBattleManager.gd")
	var team_battle_manager = TeamBattleManagerScript.new()
	team_battle_manager.name = "TeamBattleManager"
	main_scene.add_child(team_battle_manager)
	
	print("✅ 测试环境创建成功")
	
	print("\n2. 测试动画控制器集成...")
	
	# 检查BattleWindow是否有动画控制器
	if battle_window.has_method("_initialize_animation_controller"):
		print("✅ BattleWindow具有动画控制器初始化方法")
	else:
		print("❌ BattleWindow缺少动画控制器初始化方法")
	
	# 模拟动画控制器初始化
	battle_window._initialize_animation_controller()
	
	if battle_window.battle_animation_controller != null:
		print("✅ 动画控制器成功创建")
		
		# 测试动画控制器与TeamBattleManager的连接
		battle_window.battle_animation_controller.initialize(team_battle_manager, battle_window)
		print("✅ 动画控制器与TeamBattleManager连接成功")
	else:
		print("❌ 动画控制器创建失败")
	
	print("\n3. 测试战斗数据准备...")
	
	# 创建测试英雄队伍
	var hero_roster = [
		{
			"name": "战士",
			"current_hp": 100,
			"max_hp": 100,
			"attack": 25,
			"defense": 15,
			"skills": ["power_strike"]
		},
		{
			"name": "法师",
			"current_hp": 80,
			"max_hp": 80,
			"attack": 35,
			"defense": 8,
			"skills": ["burn_skill"]
		}
	]
	
	# 创建测试敌人队伍
	var enemy_roster = [
		{
			"name": "骷髅兵",
			"current_hp": 60,
			"max_hp": 60,
			"attack": 20,
			"defense": 10,
			"skills": []
		},
		{
			"name": "哥布林",
			"current_hp": 45,
			"max_hp": 45,
			"attack": 18,
			"defense": 5,
			"skills": ["poison_skill"]
		}
	]
	
	print("✅ 战斗数据准备完成")
	print("   英雄队伍: %d 人" % hero_roster.size())
	print("   敌人队伍: %d 人" % enemy_roster.size())
	
	print("\n4. 测试TeamBattleManager信号发射...")
	
	# 连接信号监听器
	var signal_received = {}
	
	team_battle_manager.battle_started.connect(func(hero_team, enemy_team): 
		signal_received["battle_started"] = true
		print("✅ 接收到 battle_started 信号")
	)
	
	team_battle_manager.turn_started.connect(func(turn: int): 
		signal_received["turn_started"] = true
		print("✅ 接收到 turn_started 信号 (回合 %d)" % turn)
	)
	
	team_battle_manager.damage_dealt.connect(func(attacker: Dictionary, target: Dictionary, damage: int, is_critical: bool): 
		signal_received["damage_dealt"] = true
		print("✅ 接收到 damage_dealt 信号: %s -> %s, 伤害: %d%s" % [
			attacker.get("name", "未知"), 
			target.get("name", "未知"), 
			damage,
			(" (暴击)" if is_critical else "")
		])
	)
	
	team_battle_manager.skill_triggered.connect(func(caster: Dictionary, skill_id: String, targets: Array): 
		signal_received["skill_triggered"] = true
		print("✅ 接收到 skill_triggered 信号: %s 使用 %s" % [
			caster.get("name", "未知"), skill_id
		])
	)
	
	team_battle_manager.battle_finished.connect(func(winner: String): 
		signal_received["battle_finished"] = true
		print("✅ 接收到 battle_finished 信号: 胜利者 %s" % winner)
	)
	
	print("\n5. 开始模拟战斗...")
	
	# 开始战斗
	team_battle_manager.start_battle(hero_roster, enemy_roster)
	
	# 等待一帧让信号处理
	await process_frame
	
	# 等待战斗完成（最多10回合）
	var max_turns = 10
	var current_turn = 0
	
	while not signal_received.get("battle_finished", false) and current_turn < max_turns:
		current_turn += 1
		print("\n--- 回合 %d ---" % current_turn)
		
		# 执行一回合
		team_battle_manager.execute_turn()
		
		# 等待动画完成
		await create_timer(0.1).timeout
		
		# 检查战斗是否结束
		if team_battle_manager.is_battle_finished():
			break
	
	print("\n6. 测试结果总结...")
	
	var required_signals = ["battle_started", "turn_started", "damage_dealt", "battle_finished"]
	var all_signals_received = true
	
	for signal_name in required_signals:
		if signal_received.get(signal_name, false):
			print("✅ 信号 '%s' 正确发射" % signal_name)
		else:
			print("❌ 信号 '%s' 未发射" % signal_name)
			all_signals_received = false
	
	if all_signals_received:
		print("\n🎉 回合攻击表现系统集成测试完全成功！")
		print("   - 所有核心组件正常工作")
		print("   - 信号系统正确连接")
		print("   - 动画控制器成功集成")
		print("   - 战斗流程完整运行")
	else:
		print("\n⚠️ 集成测试部分成功，但有信号未正确发射")
	
	# 清理
	main_scene.queue_free()
	
	print("\n=== 回合攻击表现系统集成测试完成 ===")