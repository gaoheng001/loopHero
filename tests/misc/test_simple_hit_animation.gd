# test_simple_hit_animation.gd
# 简单的受击动画测试

extends SceneTree

func _init():
	print("[简单受击动画测试] 开始测试")
	await test_hit_animation()
	print("[简单受击动画测试] 测试完成")
	quit()

func test_hit_animation():
	# 加载主场景
	var main_scene = preload("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	
	# 等待场景初始化
	await process_frame
	await process_frame
	await create_timer(3.0).timeout
	
	# 查找BattleWindow
	var battle_window = find_battle_window(root)
	if not battle_window:
		print("[简单受击动画测试] 错误：找不到BattleWindow")
		return
	
	print("[简单受击动画测试] 找到BattleWindow: %s" % battle_window.name)
	
	# 获取动画控制器
	var anim_controller = battle_window.get_node_or_null("BattleAnimationController")
	if not anim_controller:
		print("[简单受击动画测试] 错误：找不到BattleAnimationController")
		return
	
	print("[简单受击动画测试] 找到BattleAnimationController")
	
	# 测试受击动画
	print("[简单受击动画测试] === 测试英雄队伍受击动画 ===")
	anim_controller.play_team_damage_animation("heroes", false)
	await create_timer(2.0).timeout
	
	print("[简单受击动画测试] === 测试敌人队伍受击动画 ===")
	anim_controller.play_team_damage_animation("enemies", false)
	await create_timer(2.0).timeout
	
	print("[简单受击动画测试] 受击动画测试完成")

func find_battle_window(node: Node) -> Node:
	"""递归查找BattleWindow节点"""
	if node.name == "BattleWindow":
		return node
	
	for child in node.get_children():
		var result = find_battle_window(child)
		if result:
			return result
	
	return null