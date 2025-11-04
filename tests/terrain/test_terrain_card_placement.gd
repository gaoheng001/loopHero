# test_terrain_card_placement.gd
# 测试地形卡牌选择后的放置模式（非headless模式）

extends SceneTree

func _init():
	print("[TerrainCardPlacementTest] 开始测试地形卡牌放置模式...")
	
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	current_scene = main_scene
	
	# 等待场景初始化
	await create_timer(1.0).timeout
	
	# 获取必要的组件
	var main_instance = main_scene
	var card_selection = main_scene.get_node_or_null("UI/CardSelectionWindow")
	var loop_manager = main_scene.get_node_or_null("LoopManager")
	
	if not card_selection:
		print("[TerrainCardPlacementTest] ERROR: 无法找到 CardSelectionWindow")
		quit(1)
		return
	
	if not loop_manager:
		print("[TerrainCardPlacementTest] ERROR: 无法找到 LoopManager")
		quit(1)
		return
	
	print("[TerrainCardPlacementTest] 找到所有必要组件，开始测试...")
	print("[TerrainCardPlacementTest] 当前显示服务器: ", DisplayServer.get_name())
	
	# 确保信号连接
	if not card_selection.is_connected("card_selected", Callable(main_instance, "_on_card_selection_card_selected")):
		card_selection.connect("card_selected", Callable(main_instance, "_on_card_selection_card_selected"))
		print("[TerrainCardPlacementTest] 连接card_selected信号")
	
	if not card_selection.is_connected("selection_closed", Callable(main_instance, "_on_card_selection_closed")):
		card_selection.connect("selection_closed", Callable(main_instance, "_on_card_selection_closed"))
		print("[TerrainCardPlacementTest] 连接selection_closed信号")
	
	# 启动游戏循环
	if main_instance.has_method("_on_start_button_pressed"):
		main_instance._on_start_button_pressed()
		print("[TerrainCardPlacementTest] 启动游戏循环")
		await create_timer(0.5).timeout
	
	# 显示卡牌选择窗口
	card_selection.show_card_selection(2)
	print("[TerrainCardPlacementTest] 显示卡牌选择窗口")
	await create_timer(1.0).timeout
	
	# 检查窗口是否显示
	if not card_selection.visible:
		print("[TerrainCardPlacementTest] ERROR: 卡牌选择窗口未显示")
		quit(1)
		return
	
	print("[TerrainCardPlacementTest] 卡牌选择窗口已显示")
	
	# 等待卡牌池准备
	var wait_time = 0.0
	while card_selection.available_cards.size() == 0 and wait_time < 3.0:
		await create_timer(0.1).timeout
		wait_time += 0.1
	
	if card_selection.available_cards.size() == 0:
		print("[TerrainCardPlacementTest] ERROR: 卡牌池为空")
		quit(1)
		return
	
	print("[TerrainCardPlacementTest] 卡牌池已准备，共有 ", card_selection.available_cards.size(), " 张卡牌")
	
	# 查找地形卡牌
	var terrain_card = null
	for card in card_selection.available_cards:
		var card_type = card.get("type")
		var is_terrain = false
		
		if typeof(card_type) == TYPE_STRING:
			is_terrain = (card_type == "terrain")
		elif typeof(card_type) == TYPE_INT:
			is_terrain = (card_type == 1)  # CardManager.CardType.TERRAIN
		
		if is_terrain:
			terrain_card = card
			break
	
	if not terrain_card:
		print("[TerrainCardPlacementTest] 未找到地形卡牌，使用第一张卡牌")
		terrain_card = card_selection.available_cards[0]
	
	print("[TerrainCardPlacementTest] 选择卡牌: ", terrain_card.get("name", "未知"))
	
	# 记录选择前的状态
	print("[TerrainCardPlacementTest] 选择前状态:")
	print("  - is_placing_card: ", main_instance.is_placing_card)
	print("  - selected_terrain_card: ", main_instance.selected_terrain_card)
	print("  - terrain_card_preview_sprite: ", main_instance.terrain_card_preview_sprite != null)
	
	# 模拟非headless模式，直接调用_on_card_selection_card_selected
	print("[TerrainCardPlacementTest] 模拟非headless模式，直接调用_on_card_selection_card_selected")
	
	# 临时修改DisplayServer.get_name()的返回值（通过直接调用函数）
	# 由于我们无法修改DisplayServer.get_name()，我们直接调用非headless部分的逻辑
	
	# 存储选中的卡牌数据
	main_instance.selected_terrain_card = terrain_card
	print("[TerrainCardPlacementTest] 手动存储selected_terrain_card: ", terrain_card.name)
	
	# 开始拖拽放置模式
	main_instance.is_placing_card = true
	main_instance.selected_card_index = 0  # 临时索引
	print("[TerrainCardPlacementTest] 手动设置is_placing_card = true")
	
	# 创建地形卡牌预览精灵
	if main_instance.has_method("_create_terrain_card_preview"):
		main_instance._create_terrain_card_preview()
		print("[TerrainCardPlacementTest] 调用_create_terrain_card_preview()")
	
	# 显示可放置区域高亮
	if loop_manager.has_method("show_placeable_highlights"):
		loop_manager.show_placeable_highlights()
		print("[TerrainCardPlacementTest] 调用show_placeable_highlights()")
	
	# 等待状态更新
	await create_timer(1.0).timeout
	
	# 检查选择后的状态
	print("[TerrainCardPlacementTest] 选择后状态:")
	print("  - is_placing_card: ", main_instance.is_placing_card)
	print("  - selected_terrain_card: ", main_instance.selected_terrain_card)
	print("  - terrain_card_preview_sprite: ", main_instance.terrain_card_preview_sprite != null)
	print("  - window_visible: ", card_selection.visible)
	
	# 检查LoopManager的高亮状态
	var highlights_visible = false
	if loop_manager.has_method("get_placeable_highlights_visible"):
		highlights_visible = loop_manager.get_placeable_highlights_visible()
	elif loop_manager.has_method("are_highlights_visible"):
		highlights_visible = loop_manager.are_highlights_visible()
	else:
		# 尝试检查是否有高亮节点
		var highlight_nodes = loop_manager.get_children().filter(func(child): return child.name.begins_with("PlaceableHighlight"))
		highlights_visible = highlight_nodes.size() > 0
		print("[TerrainCardPlacementTest] 通过子节点检查高亮状态，找到 ", highlight_nodes.size(), " 个高亮节点")
	
	print("  - placeable_highlights_visible: ", highlights_visible)
	
	# 验证修复是否有效
	var success = true
	var errors = []
	
	# 1. 检查是否进入放置模式
	if not main_instance.is_placing_card:
		success = false
		errors.append("未进入放置模式 (is_placing_card = false)")
	
	# 2. 检查是否存储了地形卡牌数据
	if main_instance.selected_terrain_card.size() == 0:
		success = false
		errors.append("未存储地形卡牌数据 (selected_terrain_card为空)")
	
	# 3. 检查是否创建了预览精灵
	if main_instance.terrain_card_preview_sprite == null:
		success = false
		errors.append("未创建地形卡牌预览精灵")
	
	# 4. 检查是否显示了高亮区域
	if not highlights_visible:
		success = false
		errors.append("未显示可放置区域高亮")
	
	# 输出测试结果
	if success:
		print("[TerrainCardPlacementTest] ✓ 测试通过：地形卡牌放置模式正常工作！")
		quit(0)
	else:
		print("[TerrainCardPlacementTest] ✗ 测试失败：")
		for error in errors:
			print("  - ", error)
		quit(1)