extends Node

# 简化的敌方动画调试脚本

func _ready():
	print("[简化调试] 开始...")
	
	# 等待游戏初始化
	await get_tree().create_timer(5.0).timeout
	
	# 查找BattleAnimationController
	var bac = _find_battle_animation_controller()
	if not bac:
		print("[简化调试] ✗ 未找到BattleAnimationController")
		return
	
	# 检查TeamBattleManager
	var tbm = bac.get("team_battle_manager")
	if not tbm:
		print("[简化调试] ✗ 没有TeamBattleManager")
		return
	
	# 检查队伍数据
	var enemy_team = tbm.get("enemy_team")
	var enemy_animators = bac.get("enemy_animators")
	
	if not enemy_team or enemy_team.size() == 0:
		print("[简化调试] ✗ 没有敌方队伍数据")
		return
		
	if not enemy_animators:
		print("[简化调试] ✗ 没有敌方动画器数组")
		return
	
	print("[简化调试] 敌方队伍数量: %d, 动画器数量: %d" % [enemy_team.size(), enemy_animators.size()])
	
	# 输出所有敌方队伍数据
	print("[简化调试] === 敌方队伍数据 ===")
	for i in range(enemy_team.size()):
		var enemy = enemy_team[i]
		print("  [%d] name='%s', id='%s'" % [i, enemy.get("name", ""), enemy.get("id", "")])
	
	# 输出所有动画器数据
	print("[简化调试] === 敌方动画器数据 ===")
	for i in range(enemy_animators.size()):
		var animator = enemy_animators[i]
		if animator and is_instance_valid(animator):
			var char_data = animator.get("character_data")
			if char_data:
				print("  [%d] name='%s', id='%s'" % [i, char_data.get("name", ""), char_data.get("id", "")])
			else:
				print("  [%d] 无角色数据" % i)
		else:
			print("  [%d] 无效动画器" % i)
	
	# 测试第一个敌人的匹配
	if enemy_team.size() > 0:
		var test_enemy = enemy_team[0]
		print("[简化调试] === 测试匹配第一个敌人 ===")
		print("测试敌人: name='%s', id='%s'" % [test_enemy.get("name", ""), test_enemy.get("id", "")])
		
		var found_animator = bac._find_character_animator(test_enemy)
		if found_animator:
			print("✓ 找到匹配的动画器")
		else:
			print("✗ 未找到匹配的动画器")
			
			# 手动测试每个动画器的匹配
			for i in range(enemy_animators.size()):
				var animator = enemy_animators[i]
				if animator and is_instance_valid(animator) and animator.has_method("matches_character"):
					var matches = animator.matches_character(test_enemy)
					var char_data = animator.get("character_data")
					print("  动画器[%d] 匹配结果: %s (name='%s', id='%s')" % [
						i, "✓" if matches else "✗", 
						char_data.get("name", "") if char_data else "",
						char_data.get("id", "") if char_data else ""
					])

func _find_battle_animation_controller():
	return _recursive_find_node(get_tree().root, "BattleAnimationController")

func _recursive_find_node(node: Node, target_name: String):
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = _recursive_find_node(child, target_name)
		if result:
			return result
	return null