extends SceneTree

func _init():
	print("[受击闪烁测试] 开始测试修复后的敌方受击闪烁效果")
	
	# 加载主游戏场景
	var main_scene = load("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	
	# 等待一帧让场景完全加载
	await process_frame
	
	# 获取BattleWindow节点
	var battle_window = main_scene.get_node("UI/BattleWindow")
	if not battle_window:
		print("[错误] 无法找到BattleWindow节点")
		quit()
		return
	
	# 获取BattleAnimationController
	var battle_animation_controller = battle_window.get_node("BattleAnimationController")
	if not battle_animation_controller:
		print("[错误] 无法找到BattleAnimationController节点")
		quit()
		return
	
	print("[受击闪烁测试] 成功获取关键节点")
	
	# 创建测试队伍
	var hero_team = []
	var enemy_team = []
	
	# 创建测试英雄
	var test_hero = {
		"name": "测试英雄",
		"max_hp": 100,
		"current_hp": 100,
		"attack": 20,
		"defense": 10,
		"speed": 15,
		"level": 1,
		"experience": 0,
		"team_type": "hero"
	}
	hero_team.append(test_hero)
	
	# 创建测试敌人
	var test_enemy = {
		"name": "测试敌人",
		"max_hp": 80,
		"current_hp": 80,
		"attack": 15,
		"defense": 5,
		"speed": 12,
		"level": 1,
		"team_type": "enemy"
	}
	enemy_team.append(test_enemy)
	
	# 手动调用show_team_battle来初始化战斗
	battle_window.show_team_battle(hero_team, enemy_team)
	
	# 等待战斗初始化完成
	await get_timer(1.0)
	
	print("[受击闪烁测试] 战斗初始化完成")
	
	# 检查动画器状态
	var hero_animators = battle_animation_controller.hero_animators
	var enemy_animators = battle_animation_controller.enemy_animators
	
	print("英雄动画器数量: ", hero_animators.size())
	print("敌方动画器数量: ", enemy_animators.size())
	
	if hero_animators.size() == 0 or enemy_animators.size() == 0:
		print("[错误] 动画器未正确创建")
		quit()
		return
	
	var hero_animator = hero_animators[0]
	var enemy_animator = enemy_animators[0]
	
	# 获取CharacterSprite节点
	var hero_sprite = hero_animator.character_sprite
	var enemy_sprite = enemy_animator.character_sprite
	
	if not hero_sprite or not enemy_sprite:
		print("[错误] 无法获取CharacterSprite节点")
		quit()
		return
	
	print("[受击闪烁测试] 成功获取角色精灵节点")
	
	# 检查初始状态
	print("--- 初始状态 ---")
	print("英雄颜色: ", hero_sprite.color)
	print("英雄modulate: ", hero_sprite.modulate)
	print("敌方颜色: ", enemy_sprite.color)
	print("敌方modulate: ", enemy_sprite.modulate)
	
	# 测试英雄普通受击
	print("\n--- 测试英雄普通受击（白色闪烁） ---")
	hero_animator.play_hit_animation(false)
	await get_timer(1.0)
	print("英雄受击后modulate: ", hero_sprite.modulate)
	
	# 测试敌方普通受击
	print("\n--- 测试敌方普通受击（白色闪烁） ---")
	enemy_animator.play_hit_animation(false)
	await get_timer(1.0)
	print("敌方受击后modulate: ", enemy_sprite.modulate)
	
	# 测试英雄暴击受击
	print("\n--- 测试英雄暴击受击（白色闪烁） ---")
	hero_animator.play_hit_animation(true)
	await get_timer(1.0)
	print("英雄暴击后modulate: ", hero_sprite.modulate)
	
	# 测试敌方暴击受击
	print("\n--- 测试敌方暴击受击（白色闪烁） ---")
	enemy_animator.play_hit_animation(true)
	await get_timer(1.0)
	print("敌方暴击后modulate: ", enemy_sprite.modulate)
	
	# 连续测试对比效果
	print("\n--- 连续对比测试 ---")
	for i in range(3):
		print("第", i+1, "轮对比测试")
		print("  英雄普通受击...")
		hero_animator.play_hit_animation(false)
		await get_timer(0.5)
		
		print("  敌方普通受击...")
		enemy_animator.play_hit_animation(false)
		await get_timer(0.5)
		
	print("  英雄暴击受击（白色闪烁）...")
	hero_animator.play_hit_animation(true)
	await get_timer(0.5)
	
	print("  敌方暴击受击（白色闪烁）...")
	enemy_animator.play_hit_animation(true)
	await get_timer(1.0)
	
	print("\n[受击闪烁测试] 测试完成！")
	print("统一效果说明：")
	print("- 英雄与敌方：所有受击统一为白色闪烁（3次，0.1秒/次）")
	
	quit()

func get_timer(duration: float):
	return create_timer(duration).timeout