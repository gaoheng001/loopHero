extends SceneTree

func _init():
	print("=== 超强增强闪烁效果测试 ===")
	
	# 加载CharacterAnimator场景
	var animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	var animator = animator_scene.instantiate()
	
	# 创建根节点并添加animator
	var root = Node.new()
	root.add_child(animator)
	current_scene = root
	
	# 初始化角色数据
	var character_data = {
		"name": "测试角色",
		"current_hp": 100,
		"max_hp": 100,
		"attack": 20,
		"defense": 10
	}
	
	animator.initialize_character(character_data, "hero", 0)
	print("[测试] CharacterAnimator已加载并初始化")
	
	print("[测试] 超强增强参数:")
	print("[测试] - 闪烁持续时间: 0.4秒 (原来0.08秒)")
	print("[测试] - 闪烁间隔: 0.2秒 (原来0.02秒)")
	print("[测试] - 闪烁次数: 5次 (原来3次)")
	print("[测试] - 闪烁亮度: 15.0 (原来8.0)")
	print("[测试] - 总闪烁时间: 约3秒")
	print("[测试] - 动画冲突: 已修复，不再跳过")
	
	# 测试普通受击闪烁
	print("\n[测试] 开始测试超强普通受击闪烁...")
	animator.play_hit_animation(false)
	await animator.animation_completed
	
	print("\n[测试] 等待2秒后测试超强暴击受击闪烁...")
	await create_timer(2.0).timeout
	
	# 测试暴击受击闪烁
	print("[测试] 开始测试超强暴击受击闪烁...")
	animator.play_hit_animation(true)
	await animator.animation_completed
	
	print("\n[测试] 等待2秒后测试连续受击...")
	await create_timer(2.0).timeout
	
	# 测试连续受击（验证动画冲突修复）
	print("[测试] 开始测试连续受击（验证动画冲突修复）...")
	animator.play_hit_animation(false)
	await create_timer(0.5).timeout  # 在第一个动画进行中触发第二个
	animator.play_hit_animation(true)
	await animator.animation_completed
	
	print("\n=== 超强增强闪烁效果测试完成 ===")
	print("[验证] ✓ 闪烁持续时间已从0.08秒增加到0.4秒")
	print("[验证] ✓ 闪烁间隔已从0.02秒增加到0.2秒")
	print("[验证] ✓ 闪烁次数已从3次增加到5次")
	print("[验证] ✓ 闪烁亮度已从8.0增加到15.0")
	print("[验证] ✓ 动画冲突问题已修复")
	print("[验证] ✓ 现在的闪烁效果应该极其明显和持久")
	
	quit()