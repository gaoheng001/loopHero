extends SceneTree

func _init():
	print("[战斗时序测试] 开始测试优化后的动画时序")
	
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn").instantiate()
	current_scene = main_scene
	
	# 等待场景初始化
	await process_frame
	await process_frame
	
	print("[战斗时序测试] 主场景加载完成，开始测试")
	
	# 开始测试
	_run_timing_test()

func _run_timing_test():
	"""运行时序测试"""
	print("[战斗时序测试] 运行时序测试")
	
	# 等待初始化完成
	await create_timer(2.0).timeout
	
	# 获取主要组件
	var main_game = current_scene
	if not main_game:
		print("[战斗时序测试] 错误：找不到MainGame场景")
		quit()
		return
	
	var battle_window = main_game.get_node("UI/BattleWindow")
	if not battle_window:
		print("[战斗时序测试] 错误：找不到BattleWindow")
		quit()
		return
	
	print("[战斗时序测试] 找到BattleWindow，开始测试")
	
	# 测试动画时序
	await _test_animation_timing(battle_window)
	
	print("[战斗时序测试] 测试完成")
	quit()

func _test_animation_timing(battle_window):
	"""测试动画时序"""
	print("[战斗时序测试] 测试动画时序")
	
	# 获取动画控制器
	var animation_controller = battle_window.get_node("BattleAnimationController")
	if not animation_controller:
		print("[战斗时序测试] 错误：找不到BattleAnimationController")
		return
	
	# 检查新方法是否存在
	if animation_controller.has_method("play_team_attack_animation_with_timing"):
		print("[战斗时序测试] ✓ 找到优化后的时序方法")
		
		# 模拟初始化动画器
		if animation_controller.has_method("initialize"):
			animation_controller.initialize(battle_window)
			print("[战斗时序测试] ✓ 动画控制器初始化完成")
		
		# 测试时序逻辑
		print("[战斗时序测试] 开始测试攻击时序：攻击位移→受击闪烁→血条扣血")
		
		# 记录开始时间
		var start_time = Time.get_time_dict_from_system()
		print("[战斗时序测试] 开始时间: %02d:%02d:%02d" % [start_time.hour, start_time.minute, start_time.second])
		
		# 触发优化后的攻击动画
		await animation_controller.play_team_attack_animation_with_timing("heroes", "enemies", 25, false)
		
		# 记录结束时间
		var end_time = Time.get_time_dict_from_system()
		print("[战斗时序测试] 结束时间: %02d:%02d:%02d" % [end_time.hour, end_time.minute, end_time.second])
		
		print("[战斗时序测试] ✓ 优化后的攻击时序测试完成")
		print("[战斗时序测试] 预期效果：")
		print("  - 攻击动画开始后0.35秒触发受击效果")
		print("  - 受击闪烁和血条更新同时进行")
		print("  - 整体动画流畅无停顿")
		
	else:
		print("[战斗时序测试] ✗ 未找到优化后的时序方法")
	
	# 检查其他相关方法
	var methods_to_check = [
		"_start_attack_with_impact_timing",
		"_on_attack_impact", 
		"_trigger_hit_effects_at_impact"
	]
	
	for method_name in methods_to_check:
		if animation_controller.has_method(method_name):
			print("[战斗时序测试] ✓ 找到方法: %s" % method_name)
		else:
			print("[战斗时序测试] ✗ 未找到方法: %s" % method_name)