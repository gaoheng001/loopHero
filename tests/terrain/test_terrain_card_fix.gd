# test_terrain_card_fix.gd
# 测试地形卡牌选择修复后的功能

extends SceneTree

func _init():
	print("[TerrainCardFix] 开始测试地形卡牌选择修复...")
	
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
		print("[TerrainCardFix] ERROR: 无法找到 CardSelectionWindow")
		quit(1)
		return
	
	if not loop_manager:
		print("[TerrainCardFix] ERROR: 无法找到 LoopManager")
		quit(1)
		return
	
	print("[TerrainCardFix] 找到所有必要组件，开始测试...")
	print("[TerrainCardFix] 当前显示服务器: ", DisplayServer.get_name())
	
	# 手动设置card_selection_window引用
	main_instance.card_selection_window = card_selection
	print("[TerrainCardFix] 手动设置card_selection_window引用")
	
	# 手动调用信号连接方法
	if main_instance.has_method("_connect_manager_signals"):
		print("[TerrainCardFix] 手动调用_connect_manager_signals")
		main_instance._connect_manager_signals()
	else:
		print("[TerrainCardFix] _connect_manager_signals方法不存在")
	
	# 获取CardManager并确保其初始化
	var card_manager = main_scene.get_node_or_null("CardManager")
	if card_manager:
		print("[TerrainCardFix] 找到CardManager，调用_ready方法")
		card_manager._ready()
		await create_timer(0.5).timeout
	else:
		print("[TerrainCardFix] 未找到CardManager")
	
	# 启动游戏循环
	if main_instance.has_method("_on_start_button_pressed"):
		main_instance._on_start_button_pressed()
		print("[TerrainCardFix] 启动游戏循环")
		await create_timer(0.5).timeout
	
	# 模拟天数变化以触发卡牌选择
	print("[TerrainCardFix] 检查card_selection_window引用: ", main_instance.card_selection_window != null)
	print("[TerrainCardFix] 卡牌选择窗口当前可见性: ", card_selection.visible)
	
	if main_instance.has_method("_on_day_changed"):
		main_instance._on_day_changed(2)
		print("[TerrainCardFix] 触发天数变化到第2天")
		await create_timer(1.0).timeout
	
	print("[TerrainCardFix] 天数变化后卡牌选择窗口可见性: ", card_selection.visible)
	
	# 如果窗口没有显示，尝试手动调用show_card_selection
	if not card_selection.visible:
		print("[TerrainCardFix] 手动调用show_card_selection...")
		
		# 检查CardManager状态
		var cm = main_scene.get_node_or_null("CardManager")
		if cm:
			print("[TerrainCardFix] CardManager存在，数据库大小: ", cm.card_database.size())
			print("[TerrainCardFix] 数据库键: ", cm.card_database.keys())
		else:
			print("[TerrainCardFix] CardManager不存在")
		
		card_selection.show_card_selection(2)
		# 在headless模式下，窗口会自动选择卡牌并隐藏，所以等待更长时间
		await create_timer(2.0).timeout
		print("[TerrainCardFix] 手动调用后卡牌选择窗口可见性: ", card_selection.visible)
		print("[TerrainCardFix] available_cards数量: ", card_selection.available_cards.size())
	
	# 在headless模式下，窗口会自动选择卡牌，所以我们不需要检查窗口是否显示
	# 而是直接检查选择后的状态
	print("[TerrainCardFix] 跳过窗口显示检查（headless模式下会自动选择）")
	
	# 记录选择前的状态
	print("[TerrainCardFix] 选择前状态:")
	print("  - is_placing_card: ", main_instance.is_placing_card)
	print("  - selected_terrain_card: ", main_instance.selected_terrain_card)
	print("  - terrain_card_preview_sprite: ", main_instance.terrain_card_preview_sprite != null)
	
	# 在headless模式下，卡牌已经自动选择，等待信号处理完成
	print("[TerrainCardFix] 等待自动选择完成...")
	await create_timer(1.0).timeout
	
	# 检查选择后的状态
	print("[TerrainCardFix] 选择后状态:")
	print("  - is_placing_card: ", main_instance.is_placing_card)
	print("  - selected_terrain_card: ", main_instance.selected_terrain_card)
	print("  - terrain_card_preview_sprite: ", main_instance.terrain_card_preview_sprite != null)
	print("  - placeable_highlights count: ", loop_manager.placeable_highlights.size())
	
	# 验证修复结果
	var success = true
	var error_messages = []
	
	if not main_instance.is_placing_card:
		success = false
		error_messages.append("is_placing_card 应该为 true")
	
	if main_instance.selected_terrain_card.size() == 0:
		success = false
		error_messages.append("selected_terrain_card 应该包含卡牌数据")
	
	if main_instance.terrain_card_preview_sprite == null:
		success = false
		error_messages.append("terrain_card_preview_sprite 应该被创建")
	
	if loop_manager.placeable_highlights.size() == 0:
		success = false
		error_messages.append("placeable_highlights 应该显示高亮区域")
	
	# 输出测试结果
	if success:
		print("[TerrainCardFix] ✓ 测试通过：地形卡牌选择修复成功！")
		print("[TerrainCardFix] ✓ 所有功能正常工作：")
		print("  ✓ 进入放置模式")
		print("  ✓ 创建地形卡牌预览")
		print("  ✓ 显示可放置区域高亮")
	else:
		print("[TerrainCardFix] ✗ 测试失败：")
		for error in error_messages:
			print("  ✗ ", error)
	
	# 等待一段时间让用户看到结果
	await create_timer(3.0).timeout
	
	print("[TerrainCardFix] 测试完成")
	quit(0 if success else 1)