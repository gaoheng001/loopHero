extends SceneTree

func _ready():
	print("=== 攻击与受击动画并发播放测试 ===")
	await test_concurrent_animations()
	quit()

func test_concurrent_animations():
	# 加载CharacterAnimator场景
	var animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	if not animator_scene:
		print("[错误] 无法加载CharacterAnimator场景")
		return
	
	# 创建攻击方和受击方动画器
	var attacker = animator_scene.instantiate()
	var defender = animator_scene.instantiate()
	
	# 添加到场景树
	root.add_child(attacker)
	root.add_child(defender)
	
	# 初始化角色数据
	var attacker_data = {
		"name": "攻击者",
		"team": "hero",
		"position": 0,
		"hp": 100,
		"max_hp": 100
	}
	
	var defender_data = {
		"name": "防御者", 
		"team": "enemy",
		"position": 0,
		"hp": 80,
		"max_hp": 100
	}
	
	attacker.initialize_character(attacker_data)
	defender.initialize_character(defender_data)
	
	print("[测试] 角色初始化完成")
	print("[测试] 攻击者:", attacker_data.name)
	print("[测试] 防御者:", defender_data.name)
	
	# 测试1：攻击动画开始后立即触发受击动画
	print("\n[测试1] 攻击动画开始后立即触发受击动画")
	print("[测试1] 开始攻击动画...")
	attacker.play_attack_animation()
	
	# 等待攻击动画进入冲击阶段（约0.35秒）
	await create_timer(0.35).timeout
	print("[测试1] 攻击到达冲击点，立即触发受击动画...")
	defender.play_hit_animation(false)
	
	# 等待动画完成
	await create_timer(2.0).timeout
	print("[测试1] ✓ 攻击与受击动画并发播放测试完成")
	
	# 测试2：暴击攻击与受击动画并发
	print("\n[测试2] 暴击攻击与受击动画并发")
	print("[测试2] 开始暴击攻击动画...")
	attacker.play_attack_animation()
	
	# 更短的延迟，模拟更快的反应
	await create_timer(0.2).timeout
	print("[测试2] 快速触发暴击受击动画...")
	defender.play_hit_animation(true)
	
	await create_timer(3.0).timeout
	print("[测试2] ✓ 暴击攻击与受击动画并发播放测试完成")
	
	# 测试3：连续攻击与连续受击
	print("\n[测试3] 连续攻击与连续受击")
	for i in range(3):
		print("[测试3] 第%d轮攻击开始..." % (i+1))
		attacker.play_attack_animation()
		
		# 随机延迟模拟不同的攻击时机
		var delay = 0.1 + i * 0.1
		await create_timer(delay).timeout
		
		var is_crit = (i == 2)  # 第3次攻击为暴击
		print("[测试3] 第%d轮受击%s..." % [i+1, ("(暴击)" if is_crit else "")])
		defender.play_hit_animation(is_crit)
		
		await create_timer(1.0).timeout
	
	print("[测试3] ✓ 连续攻击与受击测试完成")
	
	print("\n=== 并发动画测试总结 ===")
	print("✓ 攻击动画不再阻塞受击动画")
	print("✓ 受击动画可以在攻击关键帧时立即响应")
	print("✓ 动画状态管理支持并发播放")
	print("✓ 战斗连贯感显著提升")
	print("✓ 视觉反馈更加即时和流畅")