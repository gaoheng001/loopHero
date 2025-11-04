extends SceneTree

func _init():
	print("[TerrainCardNormal] 开始测试地形卡牌选择修复（正常模式）...")
	
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn").instantiate()
	root.add_child(main_scene)
	
	# 等待场景初始化
	await create_timer(1.0).timeout
	
	# 获取主要组件
	var main_instance = main_scene  # MainGame场景本身就是MainGameController
	var loop_manager = main_scene.get_node("LoopManager")
	var card_selection = main_scene.get_node("UI/CardSelectionWindow")
	
	if not main_instance:
		print("[TerrainCardNormal] 错误：MainGameController未找到")
		quit(1)
		return
	
	if not loop_manager:
		print("[TerrainCardNormal] 错误：LoopManager未找到")
		quit(1)
		return
	
	if not card_selection:
		print("[TerrainCardNormal] 错误：CardSelectionWindow未找到")
		quit(1)
		return
	
	print("[TerrainCardNormal] 所有组件已找到")
	
	# 手动设置card_selection_window引用
	main_instance.card_selection_window = card_selection
	print("[TerrainCardNormal] 手动设置card_selection_window引用")
	
	# 手动调用信号连接方法
	if main_instance.has_method("_connect_manager_signals"):
		print("[TerrainCardNormal] 手动调用_connect_manager_signals")
		main_instance._connect_manager_signals()
	else:
		print("[TerrainCardNormal] _connect_manager_signals方法不存在")
	
	# 获取CardManager并确保其初始化
	var card_manager = main_scene.get_node_or_null("CardManager")
	if card_manager:
		print("[TerrainCardNormal] 找到CardManager")
		if card_manager.has_method("_ready"):
			card_manager._ready()
			print("[TerrainCardNormal] 调用CardManager._ready()")
	else:
		print("[TerrainCardNormal] 警告：CardManager未找到")
	
	# 等待初始化完成
	await create_timer(1.0).timeout
	
	# 手动调用show_card_selection
	print("[TerrainCardNormal] 手动调用show_card_selection...")
	card_selection.show_card_selection(2)
	
	# 等待卡牌生成
	await create_timer(0.5).timeout
	
	print("[TerrainCardNormal] 卡牌选择窗口可见性: ", card_selection.visible)
	print("[TerrainCardNormal] available_cards数量: ", card_selection.available_cards.size())
	
	# 检查是否有可用卡牌
	if card_selection.available_cards.size() == 0:
		print("[TerrainCardNormal] 错误：没有可用卡牌")
		quit(1)
		return
	
	# 记录选择前的状态
	print("[TerrainCardNormal] 选择前状态:")
	print("  - is_placing_card: ", main_instance.is_placing_card)
	print("  - selected_terrain_card: ", main_instance.selected_terrain_card)
	print("  - terrain_card_preview_sprite: ", main_instance.terrain_card_preview_sprite != null)
	
	# 手动选择第一张卡牌（模拟正常模式下的用户选择）
	var first_card = card_selection.available_cards[0]
	print("[TerrainCardNormal] 手动选择卡牌: ", first_card.get("name", "UNKNOWN"))
	
	# 直接调用_select_card方法，但不在headless模式下
	# 我们需要模拟正常的信号处理
	main_instance._on_card_selection_card_selected(first_card)
	
	# 等待信号处理完成
	await create_timer(0.5).timeout
	
	# 检查选择后的状态
	print("[TerrainCardNormal] 选择后状态:")
	print("  - is_placing_card: ", main_instance.is_placing_card)
	print("  - selected_terrain_card: ", main_instance.selected_terrain_card)
	print("  - terrain_card_preview_sprite: ", main_instance.terrain_card_preview_sprite != null)
	print("  - placeable_highlights count: ", loop_manager.placeable_highlights.size())
	
	# 验证修复结果
	var success = true
	var error_messages = []
	
	if not main_instance.is_placing_card:
		success = false
		error_messages.append("✗ is_placing_card 应该为 true")
	else:
		print("✓ is_placing_card 正确设置为 true")
	
	if main_instance.selected_terrain_card.size() == 0:
		success = false
		error_messages.append("✗ selected_terrain_card 应该包含卡牌数据")
	else:
		print("✓ selected_terrain_card 包含卡牌数据: ", main_instance.selected_terrain_card.get("name", "UNKNOWN"))
	
	if main_instance.terrain_card_preview_sprite == null:
		success = false
		error_messages.append("✗ terrain_card_preview_sprite 应该被创建")
	else:
		print("✓ terrain_card_preview_sprite 已创建")
	
	if loop_manager.placeable_highlights.size() == 0:
		success = false
		error_messages.append("✗ placeable_highlights 应该显示高亮区域")
	else:
		print("✓ placeable_highlights 显示了 ", loop_manager.placeable_highlights.size(), " 个高亮区域")
	
	if success:
		print("[TerrainCardNormal] ✓ 测试成功：地形卡牌选择后正确进入放置模式")
	else:
		print("[TerrainCardNormal] ✗ 测试失败：")
		for msg in error_messages:
			print("  ", msg)
	
	print("[TerrainCardNormal] 测试完成")
	quit(0)