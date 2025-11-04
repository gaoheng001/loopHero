extends Node

# 自动触发战斗的测试脚本

func _ready():
	print("[自动战斗测试] 开始自动战斗测试...")
	
	# 等待游戏初始化
	await get_tree().create_timer(3.0).timeout
	
	# 查找MainGameController
	var main_game_controller = _find_main_game_controller()
	if not main_game_controller:
		print("[自动战斗测试] ✗ 未找到MainGameController")
		return
	
	print("[自动战斗测试] ✓ 找到MainGameController")
	
	# 查找BattleWindow
	var battle_window = main_game_controller.get("battle_window")
	if not battle_window:
		print("[自动战斗测试] ✗ 未找到BattleWindow")
		return
	
	print("[自动战斗测试] ✓ 找到BattleWindow")
	
	# 触发一场测试战斗
	if battle_window.has_method("show_team_battle"):
		print("[自动战斗测试] 触发测试战斗...")
		
		# 创建测试队伍数据
		var hero_team = [
			{"name": "测试英雄1", "id": "hero_1", "hp": 100, "max_hp": 100},
			{"name": "测试英雄2", "id": "hero_2", "hp": 100, "max_hp": 100}
		]
		
		var enemy_team = [
			{"name": "测试敌人1", "id": "enemy_1", "hp": 80, "max_hp": 80},
			{"name": "测试敌人2", "id": "enemy_2", "hp": 80, "max_hp": 80}
		]
		
		battle_window.show_team_battle(hero_team, enemy_team)
		
		# 等待战斗初始化
		await get_tree().create_timer(2.0).timeout
		
		# 模拟敌方攻击
		await _simulate_enemy_attack(battle_window)
		
	else:
		print("[自动战斗测试] ✗ BattleWindow没有show_team_battle方法")

func _simulate_enemy_attack(battle_window):
	"""模拟敌方攻击"""
	print("[自动战斗测试] 模拟敌方攻击...")
	
	# 查找BattleAnimationController
	var bac = battle_window.get_node_or_null("BattleAnimationController")
	if not bac:
		print("[自动战斗测试] ✗ 未找到BattleAnimationController")
		return
	
	print("[自动战斗测试] ✓ 找到BattleAnimationController")
	
	# 获取TeamBattleManager
	var tbm = bac.get("team_battle_manager")
	if not tbm:
		print("[自动战斗测试] ✗ 没有TeamBattleManager")
		return
	
	print("[自动战斗测试] ✓ 找到TeamBattleManager")
	
	# 获取队伍数据
	var enemy_team = tbm.get("enemy_team")
	var hero_team = tbm.get("hero_team")
	
	if not enemy_team or enemy_team.size() == 0:
		print("[自动战斗测试] ✗ 没有敌方队伍数据")
		return
	
	if not hero_team or hero_team.size() == 0:
		print("[自动战斗测试] ✗ 没有英雄队伍数据")
		return
	
	print("[自动战斗测试] ✓ 敌方队伍: %d, 英雄队伍: %d" % [enemy_team.size(), hero_team.size()])
	
	# 模拟敌方攻击英雄
	var attacker = enemy_team[0]
	var target = hero_team[0]
	
	print("[自动战斗测试] 模拟攻击: %s -> %s" % [
		attacker.get("name", "未知敌人"),
		target.get("name", "未知英雄")
	])
	
	# 触发伤害事件
	if bac.has_method("_on_damage_dealt"):
		bac._on_damage_dealt(attacker, target, 25, false)
		print("[自动战斗测试] ✓ 伤害事件已触发")
	else:
		print("[自动战斗测试] ✗ BattleAnimationController没有_on_damage_dealt方法")

func _find_main_game_controller():
	"""查找MainGameController"""
	return _recursive_find_node(get_tree().root, "MainGameController")

func _recursive_find_node(node: Node, target_name: String):
	"""递归查找节点"""
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = _recursive_find_node(child, target_name)
		if result:
			return result
	
	return null