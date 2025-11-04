extends SceneTree

func _init():
	print("[队伍受击动画测试] 开始...")
	
	# 直接测试BattleAnimationController的play_team_damage_animation方法
	test_team_damage_animation()
	
	print("[队伍受击动画测试] 测试完成")
	quit()

func test_team_damage_animation():
	print("[队伍受击动画测试] 测试BattleAnimationController队伍受击动画")
	
	# 加载BattleAnimationController场景
	var bac_scene = preload("res://scenes/battle/BattleAnimationController.tscn")
	if not bac_scene:
		print("[队伍受击动画测试] ❌ 无法加载BattleAnimationController场景")
		return
	
	# 实例化BattleAnimationController
	var bac = bac_scene.instantiate()
	if not bac:
		print("[队伍受击动画测试] ❌ 无法实例化BattleAnimationController")
		return
	
	print("[队伍受击动画测试] ✓ BattleAnimationController实例化成功")
	
	# 添加到场景树
	root.add_child(bac)
	
	# 创建测试动画器
	var test_animators = []
	for i in range(2):
		var animator = create_test_animator("敌人" + str(i+1), "enemy", i)
		if animator:
			test_animators.append(animator)
			root.add_child(animator)
	
	print("[队伍受击动画测试] ✓ 创建了 %d 个测试动画器" % test_animators.size())
	
	# 手动设置enemy_animators数组
	bac.set("enemy_animators", test_animators)
	
	# 检查BattleAnimationController的状态
	print("[队伍受击动画测试] 检查BattleAnimationController状态...")
	print("[队伍受击动画测试] battle_window: ", bac.get("battle_window"))
	print("[队伍受击动画测试] enemy_animators数量: ", bac.get("enemy_animators").size())
	
	# 测试play_team_damage_animation方法
	if bac.has_method("play_team_damage_animation"):
		print("[队伍受击动画测试] 开始测试普通受击动画...")
		bac.play_team_damage_animation("enemies", false)
		print("[队伍受击动画测试] ✓ 普通受击动画调用成功")
		
		# 等待一下
		for i in range(60):  # 等待约1秒（60帧）
			await process_frame
		
		print("[队伍受击动画测试] 开始测试暴击受击动画...")
		bac.play_team_damage_animation("enemies", true)
		print("[队伍受击动画测试] ✓ 暴击受击动画调用成功")
	else:
		print("[队伍受击动画测试] ❌ BattleAnimationController没有play_team_damage_animation方法")

func create_test_animator(name: String, team: String, pos: int):
	"""创建测试用的CharacterAnimator"""
	var animator_scene = preload("res://scenes/battle/CharacterAnimator.tscn")
	if not animator_scene:
		print("[队伍受击动画测试] ❌ 无法加载CharacterAnimator场景")
		return null
	
	var animator = animator_scene.instantiate()
	if not animator:
		print("[队伍受击动画测试] ❌ 无法实例化CharacterAnimator")
		return null
	
	# 设置测试角色数据
	var test_character = {
		"name": name,
		"current_hp": 50,
		"max_hp": 100,
		"attack": 15
	}
	
	# 初始化角色数据
	if animator.has_method("initialize_character"):
		animator.initialize_character(test_character, team, pos)
		print("[队伍受击动画测试] ✓ 角色 %s 初始化完成" % name)
	else:
		print("[队伍受击动画测试] ❌ CharacterAnimator没有initialize_character方法")
		return null
	
	return animator