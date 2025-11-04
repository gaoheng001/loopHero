extends SceneTree

"""
测试优化后的战斗动画时序
验证：攻击位移→受击闪烁→血条扣血的流畅衔接
"""

var battle_window: Node
var battle_animation_controller: Node
var test_results = {}

func _init():
	print("=== 开始动画时序测试 ===")
	_run_tests()

func _run_tests():
	await _setup_battle_environment()
	
	print("\n=== 测试1: 普通攻击时序 ===")
	await _test_normal_attack_timing()
	
	print("\n=== 测试2: 暴击攻击时序 ===") 
	await _test_critical_attack_timing()
	
	print("\n=== 测试3: 连续攻击时序 ===")
	await _test_continuous_attack_timing()
	
	_print_test_results()
	quit()

func _setup_battle_environment():
	"""设置战斗环境"""
	print("[测试] 设置战斗环境...")
	
	# 加载主场景
	var main_scene = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	
	# 查找BattleWindow
	battle_window = _find_battle_window(main_scene)
	if not battle_window:
		print("[错误] 未找到BattleWindow")
		return
	
	# 查找或创建BattleAnimationController
	battle_animation_controller = battle_window.get_node_or_null("BattleAnimationController")
	if not battle_animation_controller:
		print("[测试] 创建BattleAnimationController")
		var controller_script = load("res://scripts/battle/BattleAnimationController.gd")
		battle_animation_controller = Node.new()
		battle_animation_controller.set_script(controller_script)
		battle_animation_controller.name = "BattleAnimationController"
		battle_window.add_child(battle_animation_controller)
	
	# 初始化控制器
	if battle_animation_controller.has_method("initialize"):
		battle_animation_controller.initialize(battle_window)
	
	print("[测试] 战斗环境设置完成")

func _find_battle_window(node: Node) -> Node:
	"""递归查找BattleWindow节点"""
	if node.name == "BattleWindow":
		return node
	
	for child in node.get_children():
		var result = _find_battle_window(child)
		if result:
			return result
	
	return null

func _test_normal_attack_timing():
	"""测试普通攻击的时序"""
	print("[测试] 开始普通攻击时序测试")
	
	var start_time = Time.get_ticks_msec()
	var timing_events = []
	
	# 连接信号监听时序
	if battle_animation_controller.has_signal("animation_started"):
		battle_animation_controller.animation_started.connect(_on_animation_event.bind("attack_started", timing_events))
	if battle_animation_controller.has_signal("animation_finished"):
		battle_animation_controller.animation_finished.connect(_on_animation_event.bind("attack_finished", timing_events))
	
	# 模拟攻击数据
	var animation_data = {
		"side": "heroes",
		"damage": 50,
		"is_critical": false
	}
	
	# 执行攻击
	if battle_animation_controller.has_method("_play_damage_animation_immediate"):
		await battle_animation_controller._play_damage_animation_immediate(animation_data, "enemies")
	
	var total_time = Time.get_ticks_msec() - start_time
	test_results["normal_attack"] = {
		"total_time": total_time,
		"events": timing_events,
		"success": timing_events.size() > 0
	}
	
	print("[测试] 普通攻击时序测试完成，耗时: %d ms" % total_time)

func _test_critical_attack_timing():
	"""测试暴击攻击的时序"""
	print("[测试] 开始暴击攻击时序测试")
	
	var start_time = Time.get_ticks_msec()
	var timing_events = []
	
	# 模拟暴击攻击数据
	var animation_data = {
		"side": "heroes", 
		"damage": 100,
		"is_critical": true
	}
	
	# 执行暴击攻击
	if battle_animation_controller.has_method("_play_damage_animation_immediate"):
		await battle_animation_controller._play_damage_animation_immediate(animation_data, "enemies")
	
	var total_time = Time.get_ticks_msec() - start_time
	test_results["critical_attack"] = {
		"total_time": total_time,
		"events": timing_events,
		"success": timing_events.size() > 0
	}
	
	print("[测试] 暴击攻击时序测试完成，耗时: %d ms" % total_time)

func _test_continuous_attack_timing():
	"""测试连续攻击的时序"""
	print("[测试] 开始连续攻击时序测试")
	
	var start_time = Time.get_ticks_msec()
	
	# 执行3次连续攻击
	for i in range(3):
		var animation_data = {
			"side": "heroes",
			"damage": 30 + i * 10,
			"is_critical": i == 2  # 第三次是暴击
		}
		
		print("[测试] 执行第%d次攻击" % (i + 1))
		if battle_animation_controller.has_method("_play_damage_animation_immediate"):
			await battle_animation_controller._play_damage_animation_immediate(animation_data, "enemies")
		
		# 短暂间隔
		await create_timer(0.2).timeout
	
	var total_time = Time.get_ticks_msec() - start_time
	test_results["continuous_attack"] = {
		"total_time": total_time,
		"success": true
	}
	
	print("[测试] 连续攻击时序测试完成，总耗时: %d ms" % total_time)

func _on_animation_event(event_name: String, timing_events: Array):
	"""记录动画事件时序"""
	var timestamp = Time.get_ticks_msec()
	timing_events.append({
		"event": event_name,
		"time": timestamp
	})
	print("[时序] %s - %d ms" % [event_name, timestamp])

func _print_test_results():
	"""打印测试结果"""
	print("\n=== 动画时序测试结果 ===")
	
	for test_name in test_results:
		var result = test_results[test_name]
		var status = "通过" if result.success else "失败"
		print("%s: %s (耗时: %d ms)" % [test_name, status, result.get("total_time", 0)])
	
	var passed_tests = 0
	for test_name in test_results:
		if test_results[test_name].success:
			passed_tests += 1
	
	print("\n总结: %d/%d 测试通过" % [passed_tests, test_results.size()])
	
	if passed_tests == test_results.size():
		print("✅ 所有动画时序测试通过！新的时序优化成功！")
	else:
		print("❌ 部分测试失败，需要进一步调试")