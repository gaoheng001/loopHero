# test_day5_card_selection.gd
# 测试第5天卡牌选择功能
extends SceneTree

func _init():
	print("[TestDay5] 开始测试第5天卡牌选择功能...")
	_run_test()

func _run_test():
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn")
	if not main_scene:
		print("[TestDay5] 错误: 无法加载MainGame.tscn")
		quit(1)
		return
	
	# 实例化主场景
	var main_instance = main_scene.instantiate()
	if not main_instance:
		print("[TestDay5] 错误: 无法实例化主场景")
		quit(1)
		return
	
	# 设置为当前场景
	current_scene = main_instance
	print("[TestDay5] 主场景已加载，开始查找组件...")
	
	# MainGameController脚本附加到根节点上
	var main_controller = main_instance
	if not main_controller.has_method("_on_day_changed"):
		print("[TestDay5] 错误: 根节点没有_on_day_changed方法")
		quit(1)
		return
	
	print("[TestDay5] 找到MainGameController（根节点）")
	
	# 等待一帧，确保所有节点都已初始化
	await process_frame
	
	# 检查CardManager是否已初始化
	var card_manager = main_controller.get_node_or_null("CardManager")
	if not card_manager:
		print("[TestDay5] 错误: CardManager未找到")
		quit(1)
		return
	
	print("[TestDay5] CardManager已找到，手动调用_ready方法...")
	card_manager._ready()
	await process_frame
	
	# 手动设置card_manager引用到MainGameController
	main_controller.card_manager = card_manager
	print("[TestDay5] CardManager引用已设置到MainGameController")
	
	# 手动设置card_selection_window引用
	main_controller.card_selection_window = main_controller.get_node("UI/CardSelectionWindow")
	if main_controller.card_selection_window:
		print("[TestDay5] CardSelectionWindow已找到并设置")
	else:
		print("[TestDay5] 错误：CardSelectionWindow未找到，退出测试")
		quit(1)
		return
	
	# 直接调用_on_day_changed方法来模拟第5天
	print("[TestDay5] 模拟第5天，调用_on_day_changed(5)...")
	main_controller._on_day_changed(5)
	
	# 等待一段时间让卡牌选择完成
	await create_timer(3.0).timeout
	
	print("[TestDay5] 测试完成，退出...")
	quit(0)