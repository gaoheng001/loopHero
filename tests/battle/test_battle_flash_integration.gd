extends SceneTree

var battle_count = 0
var max_battles = 3

func _init():
	print("[战斗闪烁集成测试] 开始测试...")
	
	# 加载主场景
	var main_scene = preload("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	
	# 等待场景初始化
	await process_frame
	await process_frame
	
	print("[战斗闪烁集成测试] 主场景加载完成")
	
	# 获取关键组件
	var main_controller = main_scene  # MainGame场景本身就是MainGameController
	var battle_window = null
	
	if main_controller:
		# 等待BattleWindow创建
		await process_frame
		await process_frame
		battle_window = main_controller.get_node_or_null("UI/BattleWindow")
		if not battle_window:
			print("[战斗闪烁集成测试] 尝试从MainController获取battle_window")
			battle_window = main_controller.get("battle_window")
	
	if not main_controller or not battle_window:
		print("[战斗闪烁集成测试] ❌ 无法找到关键组件")
		print("  - MainController: ", main_controller != null)
		print("  - BattleWindow: ", battle_window != null)
		quit()
		return
	
	print("[战斗闪烁集成测试] ✓ 找到所有关键组件")
	print("  - MainController: ", main_controller.get_class())
	print("  - BattleWindow: ", battle_window.get_class())
	
	# 开始测试循环
	await _run_battle_tests(battle_window)
	
	print("[战斗闪烁集成测试] 测试完成")
	quit()

func _run_battle_tests(battle_window):
	"""运行战斗测试"""
	print("[战斗闪烁集成测试] 开始战斗测试循环...")
	
	while battle_count < max_battles:
		battle_count += 1
		print("[战斗闪烁集成测试] 第" + str(battle_count) + "场战斗开始")
		
		# 创建测试队伍
		var hero_team = _create_test_hero_team()
		var enemy_team = _create_test_enemy_team()
		
		print("[战斗闪烁集成测试] 创建测试队伍完成")
		print("  - 英雄队伍: " + str(hero_team.size()) + " 人")
		print("  - 敌人队伍: " + str(enemy_team.size()) + " 人")
		
		# 开始战斗
		if battle_window.has_method("show_team_battle"):
			print("[战斗闪烁集成测试] ✓ 使用show_team_battle启动战斗...")
			battle_window.show_team_battle(hero_team, enemy_team)
			
			# 等待战斗结束
			await _wait_for_battle_end()
			
			print("[战斗闪烁集成测试] 第" + str(battle_count) + "场战斗结束")
		else:
			print("[战斗闪烁集成测试] ❌ BattleWindow没有show_team_battle方法")
			break
		
		# 战斗间隔
		await create_timer(2.0).timeout

func _create_test_hero_team():
	"""创建测试英雄队伍"""
	return [
		{
			"name": "测试英雄A",
			"current_hp": 100,
			"max_hp": 100,
			"attack": 25,
			"defense": 5
		},
		{
			"name": "测试英雄B", 
			"current_hp": 80,
			"max_hp": 80,
			"attack": 30,
			"defense": 3
		}
	]

func _create_test_enemy_team():
	"""创建测试敌人队伍"""
	return [
		{
			"name": "测试敌人A",
			"current_hp": 60,
			"max_hp": 60,
			"attack": 20,
			"defense": 2
		},
		{
			"name": "测试敌人B",
			"current_hp": 70,
			"max_hp": 70,
			"attack": 18,
			"defense": 4
		}
	]

func _wait_for_battle_end():
	"""等待战斗结束"""
	var timeout = 30.0  # 30秒超时
	var elapsed = 0.0
	var check_interval = 0.5
	
	while elapsed < timeout:
		await create_timer(check_interval).timeout
		elapsed += check_interval
		
		# 这里可以添加检查战斗是否结束的逻辑
		# 暂时使用固定时间等待
		if elapsed >= 10.0:  # 假设每场战斗最多10秒
			break
	
	print("[战斗闪烁集成测试] 战斗等待结束，耗时: " + str(elapsed) + "秒")

func _on_battle_ended(result):
	"""战斗结束回调"""
	print("[战斗闪烁集成测试] 收到战斗结束信号: " + str(result))