# Phase2EnhancedTests.gd
# Phase2 增强功能测试 - 验证资源联动、按钮文案、实时更新等新完善的功能
extends Node

var test_results = []
var game_manager
var card_selection_window

func run(tree: SceneTree, main_instance) -> bool:
    print("[Phase2Enhanced] 开始 Phase2 增强功能测试...")
    
    # 等待场景初始化
    await tree.process_frame
    await tree.process_frame
    
    # 获取关键组件
    setup_components(main_instance)
    
    # 运行所有测试
    await run_all_tests(tree)
    
    # 输出测试结果
    print_test_results()
    
    var total_tests = test_results.size()
    var passed_tests = 0
    for result in test_results:
        if result.success:
            passed_tests += 1
    var all_ok = (passed_tests == total_tests)
    print("[Phase2Enhanced] 测试完成，结果:", all_ok)
    return all_ok

func setup_components(main_instance):
    """设置测试所需的组件引用"""
    print("[Phase2Enhanced] 设置组件引用...")
    
    game_manager = main_instance.get_node("GameManager")
    card_selection_window = main_instance.get_node("UI/CardSelectionWindow")
	
	if not game_manager:
		add_test_result("组件设置", false, "未找到 GameManager")
		return
	
	if not card_selection_window:
		add_test_result("组件设置", false, "未找到 CardSelectionWindow")
		return
	
	add_test_result("组件设置", true, "所有组件成功获取")

func run_all_tests(tree: SceneTree) -> void:
    """运行所有测试"""
    print("[Phase2Enhanced] 开始运行测试套件...")
    
    # 测试1: 信号连接验证
    test_signal_connection()
    await tree.process_frame
    
    # 测试2: 按钮文案格式验证
    test_button_text_format(tree)
    await tree.process_frame
    
    # 测试3: 资源变化时UI实时更新
    test_resource_change_ui_update(tree)
    await tree.process_frame
    
    # 测试4: 刷新价格递增机制
    test_refresh_price_increment(tree)
    await tree.process_frame
    
    # 测试5: 购买后刷新计数重置
    test_purchase_refresh_reset(tree)
    await tree.process_frame
    
    # 测试6: 边界情况测试
    test_edge_cases(tree)
    await tree.process_frame
    
    # 测试7: Tooltip 提示验证
    test_tooltip_functionality(tree)

func test_signal_connection():
	"""测试1: 验证 resources_changed 信号连接"""
	print("[Phase2Enhanced] 测试1: 信号连接验证")
	
	if not game_manager or not card_selection_window:
		add_test_result("信号连接", false, "组件未正确初始化")
		return
	
	# 检查信号是否存在
	if not game_manager.has_signal("resources_changed"):
		add_test_result("信号连接", false, "GameManager 缺少 resources_changed 信号")
		return
	
	# 检查是否有连接到 CardSelectionWindow
	var connections = game_manager.get_signal_connection_list("resources_changed")
	var found_connection = false
	
	for connection in connections:
		if connection.callable.get_object() == card_selection_window:
			found_connection = true
			break
	
	if found_connection:
		add_test_result("信号连接", true, "resources_changed 信号已正确连接")
	else:
		add_test_result("信号连接", false, "resources_changed 信号未连接到 CardSelectionWindow")

func test_button_text_format(tree: SceneTree):
	"""测试2: 验证按钮文案格式"""
	print("[Phase2Enhanced] 测试2: 按钮文案格式验证")
	
	# 显示卡牌选择窗口
    card_selection_window.show_card_selection(1)
    await tree.process_frame
    await tree.process_frame
	
	# 检查购买按钮文案格式
	var card1_button = card_selection_window.card1_button
	if card1_button and card1_button.text:
		var button_text = card1_button.text
		if button_text.begins_with("购买(") and button_text.ends_with(")"):
			add_test_result("购买按钮文案", true, "格式正确: " + button_text)
		else:
			add_test_result("购买按钮文案", false, "格式错误: " + button_text)
	else:
		add_test_result("购买按钮文案", false, "按钮不存在或文案为空")
	
	# 检查刷新按钮文案格式
	var refresh_button = card_selection_window.refresh_button
	if refresh_button and refresh_button.text:
		var button_text = refresh_button.text
		if button_text.begins_with("刷新(") and button_text.ends_with(")"):
			add_test_result("刷新按钮文案", true, "格式正确: " + button_text)
		else:
			add_test_result("刷新按钮文案", false, "格式错误: " + button_text)
	else:
		add_test_result("刷新按钮文案", false, "按钮不存在或文案为空")

func test_resource_change_ui_update(tree: SceneTree):
	"""测试3: 验证资源变化时UI实时更新"""
	print("[Phase2Enhanced] 测试3: 资源变化UI更新验证")
	
	# 确保窗口可见
    if not card_selection_window.visible:
        card_selection_window.show_card_selection(1)
        await tree.process_frame
	
	# 记录初始状态
	var initial_stones = game_manager.get_resource_amount("spirit_stones")
	var refresh_button = card_selection_window.refresh_button
	var initial_disabled = refresh_button.disabled if refresh_button else true
	
	# 增加资源
    game_manager.add_resources("spirit_stones", 100)
    await tree.process_frame
    await tree.process_frame
	
	# 检查UI是否更新
	var new_stones = game_manager.get_resource_amount("spirit_stones")
	var new_disabled = refresh_button.disabled if refresh_button else true
	
	if new_stones > initial_stones:
		add_test_result("资源增加", true, "从 " + str(initial_stones) + " 增加到 " + str(new_stones))
	else:
		add_test_result("资源增加", false, "资源未正确增加")
	
	# 检查按钮状态是否相应更新
	if initial_disabled and not new_disabled:
		add_test_result("UI实时更新", true, "按钮状态正确更新")
	elif not initial_disabled and not new_disabled:
		add_test_result("UI实时更新", true, "按钮状态保持正确")
	else:
		add_test_result("UI实时更新", false, "按钮状态未正确更新")

func test_refresh_price_increment(tree: SceneTree):
	"""测试4: 验证刷新价格递增机制"""
	print("[Phase2Enhanced] 测试4: 刷新价格递增验证")
	
	# 确保窗口可见且有足够资源
    if not card_selection_window.visible:
        card_selection_window.show_card_selection(1)
        await tree.process_frame
	
	game_manager.add_resources("spirit_stones", 200)  # 确保有足够资源
    await tree.process_frame
	
	# 记录初始刷新价格
	var refresh_button = card_selection_window.refresh_button
	var initial_text = refresh_button.text if refresh_button else ""
	var initial_price = extract_price_from_text(initial_text)
	
	# 执行第一次刷新
	if refresh_button and not refresh_button.disabled:
		refresh_button.pressed.emit()
        await tree.process_frame
        await tree.process_frame
		
		# 检查价格是否递增
		var new_text = refresh_button.text
		var new_price = extract_price_from_text(new_text)
		
		if new_price > initial_price:
			add_test_result("刷新价格递增", true, "价格从 " + str(initial_price) + " 增加到 " + str(new_price))
		else:
			add_test_result("刷新价格递增", false, "价格未正确递增")
	else:
		add_test_result("刷新价格递增", false, "刷新按钮不可用")

func test_purchase_refresh_reset(tree: SceneTree):
	"""测试5: 验证购买后刷新计数重置"""
	print("[Phase2Enhanced] 测试5: 购买后刷新计数重置验证")
	
	# 确保窗口可见且有足够资源
    if not card_selection_window.visible:
        card_selection_window.show_card_selection(1)
        await tree.process_frame
	
	game_manager.add_resources("spirit_stones", 300)
    await tree.process_frame
	
	# 先进行几次刷新以增加价格
	var refresh_button = card_selection_window.refresh_button
	if refresh_button:
		for i in range(2):
			if not refresh_button.disabled:
				refresh_button.pressed.emit()
                await tree.process_frame
	
	# 记录刷新后的价格
	var high_price = extract_price_from_text(refresh_button.text) if refresh_button else 0
	
	# 购买一张卡牌
	var card1_button = card_selection_window.card1_button
	if card1_button and not card1_button.disabled:
		card1_button.pressed.emit()
        await tree.process_frame
        await tree.process_frame
		
		# 重新打开窗口检查刷新价格是否重置
		card_selection_window.show_card_selection(2)
        await tree.process_frame
        await tree.process_frame
		
		var reset_price = extract_price_from_text(refresh_button.text) if refresh_button else 0
		
		if reset_price < high_price:
			add_test_result("购买后重置", true, "刷新价格从 " + str(high_price) + " 重置到 " + str(reset_price))
		else:
			add_test_result("购买后重置", false, "刷新价格未正确重置")
	else:
		add_test_result("购买后重置", false, "无法执行购买操作")

func test_edge_cases(tree: SceneTree):
	"""测试6: 边界情况测试"""
	print("[Phase2Enhanced] 测试6: 边界情况验证")
	
    # 测试资源不足情况：通过接口将灵石设为0
    game_manager.reset_resources()
    var current = game_manager.get_resource_amount("spirit_stones")
    if current > 0:
        game_manager.spend_resources("spirit_stones", current)
    await tree.process_frame
	
	if not card_selection_window.visible:
		card_selection_window.show_card_selection(1)
        await tree.process_frame
	
	# 检查按钮是否正确禁用
	var card1_button = card_selection_window.card1_button
	var refresh_button = card_selection_window.refresh_button
	
	var card_disabled = card1_button.disabled if card1_button else true
	var refresh_disabled = refresh_button.disabled if refresh_button else true
	
	if card_disabled and refresh_disabled:
		add_test_result("资源不足禁用", true, "按钮正确禁用")
	else:
		add_test_result("资源不足禁用", false, "按钮未正确禁用")

func test_tooltip_functionality(tree: SceneTree):
	"""测试7: Tooltip 提示功能验证"""
	print("[Phase2Enhanced] 测试7: Tooltip 功能验证")
	
    # 设置资源不足状态：将灵石设为5（通过接口）
    game_manager.reset_resources()
    var current2 = game_manager.get_resource_amount("spirit_stones")
    if current2 > 5:
        game_manager.spend_resources("spirit_stones", current2 - 5)
    elif current2 < 5:
        game_manager.add_resources("spirit_stones", 5 - current2)
    await tree.process_frame
	
	if not card_selection_window.visible:
		card_selection_window.show_card_selection(1)
        await tree.process_frame
        await tree.process_frame
	
	# 检查按钮的 tooltip
	var card1_button = card_selection_window.card1_button
	var refresh_button = card_selection_window.refresh_button
	
	var card_tooltip = card1_button.tooltip_text if card1_button else ""
	var refresh_tooltip = refresh_button.tooltip_text if refresh_button else ""
	
	var tooltip_correct = false
	if card1_button and card1_button.disabled and card_tooltip.contains("灵石不足"):
		tooltip_correct = true
	elif refresh_button and refresh_button.disabled and refresh_tooltip.contains("灵石不足"):
		tooltip_correct = true
	
	if tooltip_correct:
		add_test_result("Tooltip提示", true, "正确显示灵石不足提示")
	else:
		add_test_result("Tooltip提示", false, "Tooltip提示不正确")

func extract_price_from_text(text: String) -> int:
	"""从按钮文案中提取价格"""
	var regex = RegEx.new()
	regex.compile("\\((\\d+)\\)")
	var result = regex.search(text)
	if result:
		return result.get_string(1).to_int()
	return 0

func add_test_result(test_name: String, success: bool, message: String):
	"""添加测试结果"""
	test_results.append({
		"name": test_name,
		"success": success,
		"message": message
	})
	
	var status = "✓" if success else "✗"
	print("[Phase2Enhanced] " + status + " " + test_name + ": " + message)

func print_test_results():
	"""输出测试结果摘要"""
	print("\n[Phase2Enhanced] ==================== 测试结果摘要 ====================")
	
	var total_tests = test_results.size()
	var passed_tests = 0
	
	for result in test_results:
		if result.success:
			passed_tests += 1
	
	print("[Phase2Enhanced] 总测试数: " + str(total_tests))
	print("[Phase2Enhanced] 通过测试: " + str(passed_tests))
	print("[Phase2Enhanced] 失败测试: " + str(total_tests - passed_tests))
	print("[Phase2Enhanced] 通过率: " + str(float(passed_tests) / float(total_tests) * 100.0) + "%")
	
	if passed_tests == total_tests:
		print("[Phase2Enhanced] 🎉 所有测试通过！Phase2 增强功能验证成功！")
	else:
		print("[Phase2Enhanced] ⚠️  部分测试失败，需要进一步检查")
	
	print("[Phase2Enhanced] =====================================================\n")