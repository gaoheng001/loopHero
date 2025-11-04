extends SceneTree

var test_animator
var demo_running = true

func _init():
	print("[可视化闪烁演示] 启动演示...")
	
	# 加载主场景
	var main_scene = preload("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	
	# 等待场景初始化
	await process_frame
	await process_frame
	
	# 查找BattleWindow
	var ui = main_scene.get_node_or_null("UI")
	if not ui:
		print("[可视化闪烁演示] ❌ 找不到UI层")
		quit()
		return
		
	var battle_window = ui.get_node_or_null("BattleWindow")
	if not battle_window:
		print("[可视化闪烁演示] ❌ 找不到BattleWindow")
		quit()
		return
	
	print("[可视化闪烁演示] ✓ 找到BattleWindow")
	
	# 查找或创建BattleAnimationController
	var bac = battle_window.get_node_or_null("BattleAnimationController")
	if not bac:
		var bac_scene = preload("res://scenes/battle/BattleAnimationController.tscn")
		bac = bac_scene.instantiate()
		battle_window.add_child(bac)
		await process_frame
		print("[可视化闪烁演示] ✓ 创建了BattleAnimationController")
	else:
		print("[可视化闪烁演示] ✓ 找到BattleAnimationController")
	
	# 创建演示动画器
	await _setup_demo_animator(bac)
	
	# 开始演示循环
	await _run_demo_loop()
	
	print("[可视化闪烁演示] 演示结束")
	quit()

func _setup_demo_animator(bac):
	"""设置演示动画器"""
	print("[可视化闪烁演示] 创建演示动画器...")
	
	# 加载CharacterAnimator场景
	var animator_scene = preload("res://scenes/battle/CharacterAnimator.tscn")
	test_animator = animator_scene.instantiate()
	
	# 添加到场景中心位置
	bac.add_child(test_animator)
	test_animator.position = Vector2(400, 300)  # 屏幕中心
	
	# 创建测试角色数据
	var test_character = {
		"name": "演示角色",
		"current_hp": 100,
		"max_hp": 100,
		"attack": 10
	}
	
	# 初始化角色
	test_animator.initialize_character(test_character, "hero", 0)
	await process_frame
	
	print("[可视化闪烁演示] ✓ 演示动画器创建完成")

func _run_demo_loop():
	"""运行演示循环"""
	print("[可视化闪烁演示] 开始演示循环...")
	print("[可视化闪烁演示] 提示：观察屏幕中心的蓝色角色")
	
	var demo_count = 0
	while demo_running and demo_count < 6:  # 演示6次
		demo_count += 1
		
		# 普通闪烁演示
		print("[可视化闪烁演示] 第" + str(demo_count) + "次演示 - 普通受击闪烁")
		test_animator.current_animation = ""  # 重置状态
		test_animator.play_hit_animation(false)
		
		# 等待闪烁完成
		await create_timer(3.0).timeout
		
		# 暴击闪烁演示
		print("[可视化闪烁演示] 第" + str(demo_count) + "次演示 - 暴击受击闪烁")
		test_animator.current_animation = ""  # 重置状态
		test_animator.play_hit_animation(true)
		
		# 等待闪烁完成
		await create_timer(3.0).timeout
		
		# 间隔
		print("[可视化闪烁演示] 等待下一轮演示...")
		await create_timer(2.0).timeout
	
	print("[可视化闪烁演示] 演示循环完成")