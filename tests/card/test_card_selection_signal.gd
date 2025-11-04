# test_card_selection_signal.gd
# 测试卡牌选择窗口的信号修复

extends SceneTree

func _init():
	print("[TestCardSignal] 开始测试卡牌选择信号修复...")
	
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	current_scene = main_scene
	
	# 等待场景初始化
	await create_timer(1.0).timeout
	
	# 获取必要的组件
	var card_selection_window = main_scene.get_node_or_null("UI/CardSelectionWindow")
	
	if not card_selection_window:
		print("[TestCardSignal] ERROR: 无法找到 CardSelectionWindow")
		quit(1)
		return
	
	print("[TestCardSignal] 找到 CardSelectionWindow，开始测试...")
	
	# 连接信号来监听
	var signal_received = false
	card_selection_window.connect("selection_closed", func(): 
		signal_received = true
		print("[TestCardSignal] ✓ selection_closed 信号已接收")
		# 立即退出测试
		await create_timer(0.1).timeout
		print("[TestCardSignal] ✓ 测试通过：selection_closed 信号正确发送")
		quit(0)
	)
	
	# 显示卡牌选择窗口
	card_selection_window.show_card_selection(1)
	await create_timer(0.5).timeout
	
	# 模拟选择卡牌（直接调用内部方法）
	var test_card = {
		"id": "test_card",
		"name": "测试卡牌",
		"type": "terrain",
		"price": 0
	}
	
	print("[TestCardSignal] 模拟选择卡牌...")
	card_selection_window._select_card(test_card)
	
	# 等待信号处理
	await create_timer(2.0).timeout
	
	# 如果到这里还没有退出，说明信号没有发送
	print("[TestCardSignal] ✗ 测试失败：selection_closed 信号未发送")
	quit(1)