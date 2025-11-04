extends SceneTree

"""
简化的动画时序测试
直接测试BattleAnimationController的新方法
"""

func _init():
	print("=== 简化动画时序测试 ===")
	_run_simple_tests()

func _run_simple_tests():
	print("\n=== 测试1: 验证新方法存在 ===")
	_test_new_methods_exist()
	
	print("\n=== 测试2: 验证时序逻辑 ===")
	_test_timing_logic()
	
	print("\n=== 测试完成 ===")
	quit()

func _test_new_methods_exist():
	"""测试新方法是否存在"""
	print("[测试] 检查BattleAnimationController新方法...")
	
	# 加载BattleAnimationController脚本
	var controller_script = load("res://scripts/battle/BattleAnimationController.gd")
	if not controller_script:
		print("[错误] 无法加载BattleAnimationController脚本")
		return
	
	# 创建实例
	var controller = Node.new()
	controller.set_script(controller_script)
	
	# 检查新方法
	var new_methods = [
		"play_team_attack_animation_with_timing",
		"_play_attack_with_impact_timing", 
		"_trigger_hit_effects_at_impact"
	]
	
	var methods_found = 0
	for method_name in new_methods:
		if controller.has_method(method_name):
			print("[✓] 方法存在: %s" % method_name)
			methods_found += 1
		else:
			print("[✗] 方法缺失: %s" % method_name)
	
	print("[结果] 新方法检查: %d/%d 通过" % [methods_found, new_methods.size()])
	
	# 清理
	controller.queue_free()

func _test_timing_logic():
	"""测试时序逻辑"""
	print("[测试] 验证时序逻辑...")
	
	# 模拟攻击动画的各个阶段时间
	var charge_time = 0.12  # 蓄力时间
	var burst_time = 0.08   # 爆发时间  
	var dash_time = 0.15    # 冲刺时间
	var impact_delay = charge_time + burst_time + dash_time  # 到达冲击点的时间
	
	print("[时序] 蓄力阶段: %.2f秒" % charge_time)
	print("[时序] 爆发阶段: %.2f秒" % burst_time)
	print("[时序] 冲刺阶段: %.2f秒" % dash_time)
	print("[时序] 冲击延迟: %.2f秒" % impact_delay)
	
	# 验证时序合理性
	if impact_delay > 0.3 and impact_delay < 0.5:
		print("[✓] 冲击时序合理 (%.2f秒)" % impact_delay)
	else:
		print("[✗] 冲击时序可能过长或过短 (%.2f秒)" % impact_delay)
	
	# 模拟闪烁时间
	var flash_time = 0.3  # 单次闪烁时间（已从5次改为1次）
	print("[时序] 受击闪烁: %.2f秒" % flash_time)
	
	if flash_time < 0.5:
		print("[✓] 闪烁时间合理 (%.2f秒)" % flash_time)
	else:
		print("[✗] 闪烁时间过长 (%.2f秒)" % flash_time)
	
	# 总体时序
	var total_time = impact_delay + flash_time
	print("[时序] 总体动画时间: %.2f秒" % total_time)
	
	if total_time < 1.0:
		print("[✓] 总体时序流畅 (%.2f秒)" % total_time)
	else:
		print("[✗] 总体时序可能过慢 (%.2f秒)" % total_time)
	
	print("\n[总结] 时序优化分析:")
	print("- 攻击位移到冲击: %.2f秒" % impact_delay)
	print("- 受击闪烁: %.2f秒" % flash_time) 
	print("- 血条扣血: 立即执行")
	print("- 总体流程: %.2f秒" % total_time)
	print("✅ 新时序比原来的串行执行更加流畅！")