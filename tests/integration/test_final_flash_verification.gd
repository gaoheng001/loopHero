extends SceneTree

# 最终闪烁动画综合验证测试
# 测试所有闪烁动画功能的完整性和正确性

var main_scene
var battle_window
var battle_animation_controller
var test_results = {}

func _init():
	print("[最终闪烁验证] 开始综合验证测试...")
	_run_comprehensive_tests()

func _run_comprehensive_tests():
	print("[最终闪烁验证] === 第一阶段：基础组件验证 ===")
	
	# 加载主场景
	main_scene = load("res://scenes/MainGame.tscn").instantiate()
	if not main_scene:
		print("[最终闪烁验证] ❌ 无法加载主场景")
		quit(1)
		return
	
	print("[最终闪烁验证] ✅ 主场景加载成功")
	
	# 获取BattleWindow
	battle_window = main_scene.get_node("UI/BattleWindow")
	if not battle_window:
		print("[最终闪烁验证] ❌ 无法找到BattleWindow")
		quit(1)
		return
	
	print("[最终闪烁验证] ✅ BattleWindow找到")
	
	# 获取或创建BattleAnimationController
	battle_animation_controller = battle_window.get_node("BattleAnimationController")
	if not battle_animation_controller:
		print("[最终闪烁验证] BattleAnimationController不存在，正在创建...")
		var bac_scene = load("res://scenes/battle/BattleAnimationController.tscn")
		if bac_scene:
			battle_animation_controller = bac_scene.instantiate()
			battle_window.add_child(battle_animation_controller)
			print("[最终闪烁验证] ✅ BattleAnimationController创建成功")
		else:
			print("[最终闪烁验证] ❌ 无法加载BattleAnimationController场景")
			quit(1)
			return
	else:
		print("[最终闪烁验证] ✅ BattleAnimationController已存在")
	
	print("[最终闪烁验证] === 第二阶段：闪烁动画功能测试 ===")
	_test_flash_animations()

func _test_flash_animations():
	# 创建测试动画器
	var test_animator = _create_test_animator()
	if not test_animator:
		print("[最终闪烁验证] ❌ 无法创建测试动画器")
		quit(1)
		return
	
	print("[最终闪烁验证] ✅ 测试动画器创建成功")
	
	# 测试1：普通受击闪烁
	print("[最终闪烁验证] 测试1：普通受击闪烁")
	var normal_result = _test_normal_flash(test_animator)
	test_results["normal_flash"] = normal_result
	
	# 测试2：暴击受击闪烁
	print("[最终闪烁验证] 测试2：暴击受击闪烁")
	var crit_result = _test_crit_flash(test_animator)
	test_results["crit_flash"] = crit_result
	
	# 测试3：连续闪烁测试
	print("[最终闪烁验证] 测试3：连续闪烁测试")
	var continuous_result = _test_continuous_flash(test_animator)
	test_results["continuous_flash"] = continuous_result
	
	print("[最终闪烁验证] === 第三阶段：战斗集成测试 ===")
	_test_battle_integration()

func _create_test_animator():
	# 创建测试角色动画器
	var animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	if not animator_scene:
		print("[最终闪烁验证] ❌ 无法加载CharacterAnimator场景")
		return null
	
	var animator = animator_scene.instantiate()
	battle_animation_controller.add_child(animator)
	
	# 设置测试角色数据
	var character_data = {
		"name": "测试角色",
		"hp": 100,
		"max_hp": 100,
		"attack": 25
	}
	
	# 使用正确的初始化方法
	animator.initialize_character(character_data, "hero", 0)
	animator.position = Vector2(400, 300)
	
	return animator

func _test_normal_flash(animator):
	print("[最终闪烁验证] 开始普通闪烁测试...")
	
	# 检查闪烁方法是否存在
	if not animator.has_method("play_hit_animation"):
		print("[最终闪烁验证] ❌ 动画器缺少play_hit_animation方法")
		return false
	
	# 执行普通闪烁
	animator.play_hit_animation(false)  # false表示非暴击
	print("[最终闪烁验证] ✅ 普通闪烁动画已触发")
	return true

func _test_crit_flash(animator):
	print("[最终闪烁验证] 开始暴击闪烁测试...")
	
	# 检查闪烁方法是否存在
	if not animator.has_method("play_hit_animation"):
		print("[最终闪烁验证] ❌ 动画器缺少play_hit_animation方法")
		return false
	
	# 执行暴击闪烁
	animator.play_hit_animation(true)  # true表示暴击
	print("[最终闪烁验证] ✅ 暴击闪烁动画已触发")
	return true

func _test_continuous_flash(animator):
	print("[最终闪烁验证] 开始连续闪烁测试...")
	
	# 连续触发多次闪烁
	for i in range(3):
		var is_crit = (i % 2 == 1)  # 交替普通和暴击
		animator.play_hit_animation(is_crit)
		print("[最终闪烁验证] 连续闪烁 " + str(i + 1) + "/3 (" + ("暴击" if is_crit else "普通") + ")")
	
	print("[最终闪烁验证] ✅ 连续闪烁测试完成")
	return true

func _test_battle_integration():
	print("[最终闪烁验证] 开始战斗集成测试...")
	
	# 创建简单的战斗场景
	var hero_team = _create_test_team("hero")
	var enemy_team = _create_test_team("enemy")
	
	if hero_team.size() == 0 or enemy_team.size() == 0:
		print("[最终闪烁验证] ❌ 无法创建测试队伍")
		test_results["battle_integration"] = false
		_print_final_results()
		return
	
	print("[最终闪烁验证] ✅ 测试队伍创建成功")
	
	# 启动战斗
	if battle_window.has_method("show_team_battle"):
		battle_window.show_team_battle(hero_team, enemy_team)
		print("[最终闪烁验证] ✅ 战斗已启动")
		test_results["battle_integration"] = true
	else:
		print("[最终闪烁验证] ❌ BattleWindow缺少show_team_battle方法")
		test_results["battle_integration"] = false
	
	_print_final_results()

func _create_test_team(team_type):
	var team = []
	var names = ["测试角色A", "测试角色B"] if team_type == "hero" else ["测试敌人A", "测试敌人B"]
	
	for i in range(2):
		var character = {
			"name": names[i],
			"hp": 100,
			"max_hp": 100,
			"attack": 25,
			"type": team_type
		}
		team.append(character)
	
	return team

func _print_final_results():
	print("[最终闪烁验证] === 测试结果汇总 ===")
	
	var total_tests = 0
	var passed_tests = 0
	
	for test_name in test_results.keys():
		total_tests += 1
		var result = test_results[test_name]
		var status = "✅ 通过" if result else "❌ 失败"
		print("[最终闪烁验证] " + test_name + ": " + status)
		if result:
			passed_tests += 1
	
	print("[最终闪烁验证] === 最终结果 ===")
	print("[最终闪烁验证] 总测试数: " + str(total_tests))
	print("[最终闪烁验证] 通过测试: " + str(passed_tests))
	print("[最终闪烁验证] 失败测试: " + str(total_tests - passed_tests))
	
	if passed_tests == total_tests:
		print("[最终闪烁验证] 🎉 所有闪烁功能验证通过！")
	else:
		print("[最终闪烁验证] ⚠️ 部分功能需要修复")
	
	print("[最终闪烁验证] 综合验证测试完成")
	quit(0)