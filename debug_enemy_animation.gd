extends Node

# 敌方攻击动画调试脚本

func _ready():
	print("[敌方动画调试] 开始调试...")
	
	# 等待游戏初始化
	await get_tree().create_timer(5.0).timeout
	
	# 查找BattleAnimationController
	var bac = _find_battle_animation_controller()
	if not bac:
		print("[敌方动画调试] ✗ 未找到BattleAnimationController")
		return
	
	print("[敌方动画调试] ✓ 找到BattleAnimationController")
	
	# 检查TeamBattleManager
	var tbm = bac.get("team_battle_manager")
	if not tbm:
		print("[敌方动画调试] ✗ 没有TeamBattleManager")
		return
	
	print("[敌方动画调试] ✓ 找到TeamBattleManager")
	
	# 检查队伍数据
	var enemy_team = tbm.get("enemy_team")
	if not enemy_team or enemy_team.size() == 0:
		print("[敌方动画调试] ✗ 没有敌方队伍数据")
		return
	
	print("[敌方动画调试] ✓ 敌方队伍数量: %d" % enemy_team.size())
	
	# 详细输出敌方队伍数据
	for i in range(enemy_team.size()):
		var enemy = enemy_team[i]
		print("[敌方动画调试] 敌方成员[%d]: name=%s, id=%s" % [
			i, 
			enemy.get("name", "无名称"), 
			enemy.get("id", "无ID")
		])
	
	# 检查敌方动画器
	var enemy_animators = bac.get("enemy_animators")
	if not enemy_animators:
		print("[敌方动画调试] ✗ 没有敌方动画器数组")
		return
	
	print("[敌方动画调试] ✓ 敌方动画器数量: %d" % enemy_animators.size())
	
	# 详细检查每个敌方动画器
	for i in range(enemy_animators.size()):
		var animator = enemy_animators[i]
		if not animator or not is_instance_valid(animator):
			print("[敌方动画调试] ✗ 动画器[%d] 无效" % i)
			continue
		
		var char_data = animator.get("character_data")
		if not char_data:
			print("[敌方动画调试] ✗ 动画器[%d] 没有角色数据" % i)
			continue
		
		print("[敌方动画调试] ✓ 动画器[%d]: name=%s, id=%s" % [
			i,
			char_data.get("name", "无名称"),
			char_data.get("id", "无ID")
		])
	
	# 测试匹配逻辑
	if enemy_team.size() > 0 and enemy_animators.size() > 0:
		for i in range(enemy_team.size()):
			var test_enemy = enemy_team[i]
			print("[敌方动画调试] 测试匹配敌人[%d]: name=%s, id=%s" % [
				i,
				test_enemy.get("name", "无名称"),
				test_enemy.get("id", "无ID")
			])
			
			var found_animator = bac._find_character_animator(test_enemy)
			if found_animator:
				print("[敌方动画调试] ✓ 成功找到匹配的动画器")
				
				# 测试播放攻击动画
				if found_animator.has_method("play_attack_animation"):
					print("[敌方动画调试] 测试播放攻击动画...")
					found_animator.play_attack_animation()
					await get_tree().create_timer(2.0).timeout
					print("[敌方动画调试] ✓ 攻击动画已触发")
				else:
					print("[敌方动画调试] ✗ 动画器没有play_attack_animation方法")
			else:
				print("[敌方动画调试] ✗ 未找到匹配的动画器")
				
				# 详细检查为什么匹配失败
				for j in range(enemy_animators.size()):
					var animator = enemy_animators[j]
					if animator and is_instance_valid(animator):
						var char_data = animator.get("character_data")
						if char_data:
							print("[敌方动画调试] 检查动画器[%d]:" % j)
							print("  动画器数据: name=%s, id=%s" % [
								char_data.get("name", "无名称"),
								char_data.get("id", "无ID")
							])
							print("  测试数据: name=%s, id=%s" % [
								test_enemy.get("name", "无名称"),
								test_enemy.get("id", "无ID")
							])
							
							if animator.has_method("matches_character"):
								var matches = animator.matches_character(test_enemy)
								print("  匹配结果: %s" % ("✓" if matches else "✗"))
								
								# 详细分析匹配失败原因
								if not matches:
									var animator_name = char_data.get("name", "")
									var animator_id = char_data.get("id", "")
									var test_name = test_enemy.get("name", "")
									var test_id = test_enemy.get("id", "")
									
									print("  匹配失败分析:")
									print("    ID匹配: %s (动画器:%s vs 测试:%s)" % [
										"✓" if (animator_id != "" and test_id != "" and animator_id == test_id) else "✗",
										animator_id, test_id
									])
									print("    名称匹配: %s (动画器:%s vs 测试:%s)" % [
										"✓" if (animator_name != "" and test_name != "" and animator_name == test_name) else "✗",
										animator_name, test_name
									])
							else:
								print("  ✗ 没有matches_character方法")
	
	print("[敌方动画调试] 调试完成")

func _find_battle_animation_controller():
	"""查找BattleAnimationController"""
	return _recursive_find_node(get_tree().root, "BattleAnimationController")

func _recursive_find_node(node: Node, target_name: String):
	"""递归查找节点"""
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = _recursive_find_node(child, target_name)
		if result:
			return result
	
	return null