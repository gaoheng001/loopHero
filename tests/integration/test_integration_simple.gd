extends SceneTree

func _ready():
	print("[简化集成测试] 开始测试...")
	
	# 加载BattleAnimationController场景
	var controller_scene = load("res://scenes/battle/BattleAnimationController.tscn")
	if controller_scene == null:
		print("[简化集成测试] ✗ 无法加载BattleAnimationController场景")
		quit()
		return
	
	print("[简化集成测试] ✓ BattleAnimationController场景加载成功")
	
	# 实例化BattleAnimationController
	var controller = controller_scene.instantiate()
	if controller == null:
		print("[简化集成测试] ✗ 无法实例化BattleAnimationController")
		quit()
		return
	
	root.add_child(controller)
	print("[简化集成测试] ✓ BattleAnimationController实例化成功")
	
	# 检查battle_window状态
	print("[简化集成测试] battle_window状态: %s" % str(controller.battle_window))
	print("[简化集成测试] enemy_animators数量: %d" % controller.enemy_animators.size())
	
	# 尝试调用play_team_damage_animation
	print("[简化集成测试] 调用play_team_damage_animation...")
	controller.play_team_damage_animation("enemy", false)
	print("[简化集成测试] play_team_damage_animation调用完成")
	
	print("[简化集成测试] 测试完成")
	quit()