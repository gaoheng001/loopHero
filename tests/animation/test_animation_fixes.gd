extends Node

# 测试动画修复效果的脚本

func _ready():
	print("=== 动画修复效果测试 ===")
	
	# 等待一帧确保所有节点初始化完成
	await get_tree().process_frame
	
	# 创建测试环境
	var test_scene = preload("res://scenes/MainGame.tscn").instantiate()
	get_tree().root.add_child(test_scene)
	
	# 等待场景初始化
	await get_tree().create_timer(2.0).timeout
	
	# 查找BattleAnimationController
	var battle_animation_controller = _find_battle_animation_controller(test_scene)
	if not battle_animation_controller:
		print("❌ 未找到BattleAnimationController")
		return
	
	print("✅ 找到BattleAnimationController")
	
	# 测试受击动画简化
	test_hit_animation_simplification(battle_animation_controller)
	
	# 测试动画锁时序
	test_animation_lock_timing(battle_animation_controller)
	
	print("=== 测试完成 ===")

func _find_battle_animation_controller(node: Node) -> Node:
	if node.name == "BattleAnimationController":
		return node
	
	for child in node.get_children():
		var result = _find_battle_animation_controller(child)
		if result:
			return result
	
	return null

func test_hit_animation_simplification(controller: Node):
	print("\n--- 测试受击动画简化 ---")
	
	# 检查play_team_damage_animation方法是否存在
	if controller.has_method("play_team_damage_animation"):
		print("✅ play_team_damage_animation方法存在")
		
		# 模拟调用受击动画
		print("🎬 模拟播放受击动画...")
		controller.play_team_damage_animation("heroes", false)
		
		await get_tree().create_timer(1.0).timeout
		print("✅ 受击动画播放完成（应该只有闪烁，无位移和形变）")
	else:
		print("❌ play_team_damage_animation方法不存在")

func test_animation_lock_timing(controller: Node):
	print("\n--- 测试动画锁时序 ---")
	
	# 检查动画锁相关方法
	if controller.has_method("is_animation_playing"):
		print("✅ is_animation_playing方法存在")
		
		# 检查初始状态
		var is_playing = controller.is_animation_playing()
		print("🔒 初始动画锁状态: %s" % ("锁定" if is_playing else "空闲"))
		
		# 模拟伤害事件
		if controller.has_method("_on_damage_dealt"):
			print("🎬 模拟伤害事件...")
			
			# 创建模拟数据
			var attacker_data = {"name": "测试攻击者", "attack": 10}
			var target_data = {"name": "测试目标", "current_hp": 50, "max_hp": 100}
			
			controller._on_damage_dealt(attacker_data, target_data, 15, false)
			
			await get_tree().create_timer(0.5).timeout
			
			# 检查动画锁状态
			is_playing = controller.is_animation_playing()
			print("🔒 伤害后动画锁状态: %s" % ("锁定" if is_playing else "空闲"))
			
			# 等待动画完成
			await get_tree().create_timer(2.0).timeout
			
			is_playing = controller.is_animation_playing()
			print("🔒 最终动画锁状态: %s" % ("锁定" if is_playing else "空闲"))
			
			if not is_playing:
				print("✅ 动画锁正确释放")
			else:
				print("❌ 动画锁未正确释放")
		else:
			print("❌ _on_damage_dealt方法不存在")
	else:
		print("❌ is_animation_playing方法不存在")