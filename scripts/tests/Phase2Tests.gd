class_name Phase2Tests
# 第二阶段测试模块：价格、刷新递增、资金不足禁用、购买重置
extends Node

static func _assert_log(cond: bool, msg: String) -> bool:
	if not cond:
		print("[Phase2Tests][FAIL] " + msg)
		return false
	else:
		print("[Phase2Tests][OK] " + msg)
		return true

func run(tree: SceneTree, main_instance) -> bool:
	print("[Phase2Tests] 启动阶段2模块测试")
	var ok_all := true

	# 获取关键节点
	var game_manager = main_instance.get_node_or_null("GameManager")
	var card_manager = main_instance.get_node_or_null("CardManager")
	var card_selection_window = main_instance.get_node_or_null("UI/CardSelectionWindow")
	if not game_manager or not card_manager or not card_selection_window:
		print("[Phase2Tests][FAIL] 关键节点未找到: GM=%s, CM=%s, CSW=%s" % [str(game_manager!=null), str(card_manager!=null), str(card_selection_window!=null)])
		return false

	# 初始化
	card_selection_window.refresh_count = 0
	card_selection_window.visible = false

	# 等待两帧，确保节点初始化
	await tree.process_frame
	await tree.process_frame

	# 准备卡池为地形卡（价格应为10）
	var terrain_cards: Array[Dictionary] = card_manager.generate_random_cards(3, [CardManager.CardType.TERRAIN])
	card_selection_window.available_cards = terrain_cards
	card_selection_window._update_card_display()

	# 价格：地形卡10
	var price0 = card_selection_window._get_card_price(terrain_cards[0])
	ok_all = ok_all and _assert_log(price0 == 10, "地形卡价格应为 10，实际=" + str(price0))

	# 刷新价格：5 -> 10 -> 15
	game_manager.resources["spirit_stones"] = 100
	card_selection_window._update_refresh_label()
	ok_all = ok_all and _assert_log(card_selection_window.refresh_price_label.text.begins_with("刷新价格: 5"), "初始刷新价格应为 5 灵石")

	card_selection_window._on_refresh_pressed()
	ok_all = ok_all and _assert_log(card_selection_window.refresh_count == 1, "刷新计数应为 1")
	ok_all = ok_all and _assert_log(card_selection_window.refresh_price_label.text.begins_with("刷新价格: 10"), "第1次刷新后价格应为 10 灵石")

	card_selection_window._on_refresh_pressed()
	ok_all = ok_all and _assert_log(card_selection_window.refresh_count == 2, "刷新计数应为 2")
	ok_all = ok_all and _assert_log(card_selection_window.refresh_price_label.text.begins_with("刷新价格: 15"), "第2次刷新后价格应为 15 灵石")

	# 资金不足：按钮禁用与提示
	game_manager.resources["spirit_stones"] = 0
	card_selection_window.available_cards = terrain_cards
	card_selection_window._update_card_display()
	var b1: Button = card_selection_window.card1_button
	ok_all = ok_all and _assert_log(b1.disabled == true, "资金不足时卡牌按钮应禁用")
	ok_all = ok_all and _assert_log(b1.tooltip_text == "灵石不足", "资金不足时按钮提示应为‘灵石不足’")

	# 购买成功：重置刷新计数
	game_manager.resources["spirit_stones"] = 100
	card_selection_window.available_cards = terrain_cards
	card_selection_window._update_card_display()
	card_selection_window.refresh_count = 2
	card_selection_window._select_card(terrain_cards[0])
	ok_all = ok_all and _assert_log(card_selection_window.refresh_count == 0, "购买成功后刷新计数应重置为 0")

	return ok_all