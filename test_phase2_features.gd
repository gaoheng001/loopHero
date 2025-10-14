# test_phase2_features.gd
# 测试 Phase2 完善的功能
extends SceneTree

func _init():
	print("[Phase2Test] 开始测试 Phase2 完善功能...")
	
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	
	# 等待一帧让所有节点初始化
	await process_frame
	await process_frame
	
	# 测试卡牌选择窗口的资源联动功能
	test_card_selection_resource_binding(main_scene)
	
	print("[Phase2Test] 测试完成，退出...")
	quit()

func test_card_selection_resource_binding(main_scene):
	print("[Phase2Test] 测试卡牌选择窗口资源联动功能...")
	
	# 获取组件
	var game_manager = main_scene.get_node("GameManager")
	var card_selection_window = main_scene.get_node("UI/CardSelectionWindow")
	
	if not game_manager:
		print("[Phase2Test] ERROR: 未找到 GameManager")
		return
	
	if not card_selection_window:
		print("[Phase2Test] ERROR: 未找到 CardSelectionWindow")
		return
	
	print("[Phase2Test] 找到所需组件")
	
	# 测试初始资源
	var initial_stones = game_manager.get_resource_amount("spirit_stones")
	print("[Phase2Test] 初始灵石数量: ", initial_stones)
	
	# 显示卡牌选择窗口
	card_selection_window.show_card_selection(1)
	print("[Phase2Test] 显示卡牌选择窗口")
	
	# 等待UI更新
	await process_frame
	await process_frame
	
	# 检查按钮文案
	var refresh_button = card_selection_window.refresh_button
	if refresh_button:
		print("[Phase2Test] 刷新按钮文案: '", refresh_button.text, "'")
		if refresh_button.text.begins_with("刷新(") and refresh_button.text.ends_with(")"):
			print("[Phase2Test] ✓ 刷新按钮文案格式正确")
		else:
			print("[Phase2Test] ✗ 刷新按钮文案格式错误")
	
	# 检查购买按钮文案
	var card1_button = card_selection_window.card1_button
	if card1_button:
		print("[Phase2Test] 购买按钮文案: '", card1_button.text, "'")
		if card1_button.text.begins_with("购买(") and card1_button.text.ends_with(")"):
			print("[Phase2Test] ✓ 购买按钮文案格式正确")
		else:
			print("[Phase2Test] ✗ 购买按钮文案格式错误")
	
	# 测试资源变化时的UI更新
	print("[Phase2Test] 测试资源变化时的UI更新...")
	game_manager.add_resources("spirit_stones", 100)
	
	# 等待资源变化信号处理
	await process_frame
	
	print("[Phase2Test] 资源变化后灵石数量: ", game_manager.get_resource_amount("spirit_stones"))
	
	# 检查按钮状态是否更新
	if refresh_button:
		print("[Phase2Test] 刷新按钮是否禁用: ", refresh_button.disabled)
	
	if card1_button:
		print("[Phase2Test] 购买按钮是否禁用: ", card1_button.disabled)
	
	print("[Phase2Test] 资源联动测试完成")