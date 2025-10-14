# CardSelectionWindow.gd
# 卡牌选择窗口 - 每天弹出让玩家选择一张卡牌
class_name CardSelectionWindow
extends Control

# 信号定义
signal card_selected(card_data: Dictionary)
signal selection_closed

# UI节点引用
@onready var title_label: Label = $SelectionPanel/MainContainer/TitleLabel
@onready var cards_container: HBoxContainer = $SelectionPanel/MainContainer/CardsContainer
@onready var close_button: Button = $SelectionPanel/MainContainer/ButtonContainer/CloseButton
@onready var refresh_button: Button = $SelectionPanel/MainContainer/ButtonContainer/RefreshButton
@onready var refresh_price_label: Label = $SelectionPanel/MainContainer/ButtonContainer/RefreshPriceLabel

# 卡牌按钮和标签引用
@onready var card1_button: Button = $SelectionPanel/MainContainer/CardsContainer/Card1/Card1Button
@onready var card1_name: Label = $SelectionPanel/MainContainer/CardsContainer/Card1/Card1Name
@onready var card1_description: Label = $SelectionPanel/MainContainer/CardsContainer/Card1/Card1Description

@onready var card2_button: Button = $SelectionPanel/MainContainer/CardsContainer/Card2/Card2Button
@onready var card2_name: Label = $SelectionPanel/MainContainer/CardsContainer/Card2/Card2Name
@onready var card2_description: Label = $SelectionPanel/MainContainer/CardsContainer/Card2/Card2Description

@onready var card3_button: Button = $SelectionPanel/MainContainer/CardsContainer/Card3/Card3Button
@onready var card3_name: Label = $SelectionPanel/MainContainer/CardsContainer/Card3/Card3Name
@onready var card3_description: Label = $SelectionPanel/MainContainer/CardsContainer/Card3/Card3Description

# 当前可选择的卡牌数据
var available_cards: Array[Dictionary] = []
var refresh_count: int = 0
var base_refresh_price: int = 5
var refresh_increment: int = 5
var current_day: int = 0

func _ready():
	# 连接按钮信号
	card1_button.pressed.connect(_on_card1_selected)
	card2_button.pressed.connect(_on_card2_selected)
	card3_button.pressed.connect(_on_card3_selected)
	close_button.pressed.connect(_on_close_button_pressed)
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)

	# 连接 GameManager 的资源变化信号
	call_deferred("_connect_resource_signals")

	# 初始状态隐藏窗口
	visible = false
	
	# 测试CardManager功能
	call_deferred("_test_card_manager")

func show_card_selection(day: int):
	"""显示卡牌选择窗口"""
	current_day = day
	# 每日打开时重置刷新计数
	refresh_count = 0
	
	# 检查UI组件是否可用（headless模式下可能为空）
	if title_label:
		title_label.text = "第" + str(day) + "天 - 选择一张卡牌"
	
	# 生成3张随机卡牌（仅允许地形类型）
	available_cards = _generate_random_cards()

	if available_cards.size() == 0:
		print("[CardSelection] ERROR: No cards generated! This will cause problems.")
		return
	
	# 更新UI显示
	_update_card_display()
	
	# 显示窗口
	visible = true

	# 更新刷新价格与按钮状态
	_update_prices_and_buttons()

	# 在headless模式下自动选择第一张卡牌（保护get_tree为空的情况）
	if DisplayServer.get_name() == "headless":
		var tree = get_tree()
		if tree:
			await tree.create_timer(1.0).timeout
		if available_cards.size() > 0:
			_select_card(available_cards[0])
		else:
			print("[CardSelection] ERROR: No cards available for auto-selection")
			_on_close_button_pressed()

func hide_selection():
	"""隐藏选择窗口"""
	visible = false

func _generate_random_cards() -> Array[Dictionary]:
	"""生成3张随机地形卡牌"""
	var cards: Array[Dictionary] = []
	var card_manager = _get_card_manager()
	if not card_manager:
		return cards
	# 使用CardManager的生成接口，允许类型为地形
	cards = card_manager.generate_random_cards(3, [CardManager.CardType.TERRAIN])
	return cards

func _update_card_display():
	"""更新卡牌显示"""

	# 如果没有卡牌，强制生成
	if available_cards.size() == 0:
		print("[CardSelection] WARNING: available_cards为空，强制重新生成")
		available_cards = _generate_random_cards()

	var game_manager = _get_game_manager()
	var stones = 0
	if game_manager:
		stones = game_manager.get_resource_amount("spirit_stones")

	if available_cards.size() >= 1:
		if card1_name:
			card1_name.text = available_cards[0].name
		var price1 = _get_card_price(available_cards[0])
		if card1_description:
			card1_description.text = available_cards[0].description + "\n价格: " + str(price1) + " 灵石"
		if card1_button:
			card1_button.text = "购买(" + str(price1) + ")"
			card1_button.disabled = stones < price1
			card1_button.tooltip_text = "" if stones >= price1 else "灵石不足"
	else:
		if card1_name:
			card1_name.text = "无卡牌"
		if card1_description:
			card1_description.text = ""
		if card1_button:
			card1_button.disabled = true
			card1_button.text = "不可购买"
			card1_button.tooltip_text = ""

	if available_cards.size() >= 2:
		if card2_name:
			card2_name.text = available_cards[1].name
		var price2 = _get_card_price(available_cards[1])
		if card2_description:
			card2_description.text = available_cards[1].description + "\n价格: " + str(price2) + " 灵石"
		if card2_button:
			card2_button.text = "购买(" + str(price2) + ")"
			card2_button.disabled = stones < price2
			card2_button.tooltip_text = "" if stones >= price2 else "灵石不足"
	else:
		if card2_name:
			card2_name.text = "无卡牌"
		if card2_description:
			card2_description.text = ""
		if card2_button:
			card2_button.disabled = true
			card2_button.text = "不可购买"
			card2_button.tooltip_text = ""

	if available_cards.size() >= 3:
		if card3_name:
			card3_name.text = available_cards[2].name
		var price3 = _get_card_price(available_cards[2])
		if card3_description:
			card3_description.text = available_cards[2].description + "\n价格: " + str(price3) + " 灵石"
		if card3_button:
			card3_button.text = "购买(" + str(price3) + ")"
			card3_button.disabled = stones < price3
			card3_button.tooltip_text = "" if stones >= price3 else "灵石不足"
	else:
		if card3_name:
			card3_name.text = "无卡牌"
		if card3_description:
			card3_description.text = ""
		if card3_button:
			card3_button.disabled = true
			card3_button.text = "不可购买"
			card3_button.tooltip_text = ""

	_update_title()
	_update_refresh_label()

func _on_card1_selected():
	"""选择第1张卡牌"""
	if available_cards.size() >= 1:
		_select_card(available_cards[0])

func _on_card2_selected():
	"""选择第2张卡牌"""
	if available_cards.size() >= 2:
		_select_card(available_cards[1])

func _on_card3_selected():
	"""选择第3张卡牌"""
	if available_cards.size() >= 3:
		_select_card(available_cards[2])

func _test_card_manager():
	"""测试CardManager功能"""
	# 尝试获取CardManager
	var card_manager = get_node_or_null("../../CardManager")
	if not card_manager:
		card_manager = get_node_or_null("/root/MainGame/CardManager")
	
	if not card_manager:
		print("[CardSelectionWindow] ERROR: 无法找到CardManager节点")
		return
	
	# 测试获取卡牌
	var test_card_ids = ["bamboo_forest", "mountain_peak", "river"]
	for card_id in test_card_ids:
		var card_data = card_manager.get_card_by_id(card_id)
		if card_data.is_empty():
			print("[CardSelectionWindow] ERROR: 获取卡牌失败: ", card_id)

func _select_card(card_data: Dictionary):
	"""选择卡牌"""
	# 购买扣费
	var gm = _get_game_manager()
	var price = _get_card_price(card_data)
	if gm:
		if gm.spend_resources("spirit_stones", price):
			# 从待选列表移除已购买卡牌
			_remove_selected_card(card_data)
			# 购买后重置刷新计数（价格清零）
			refresh_count = 0
			# 发出选择信号并隐藏窗口以进行放置
			card_selected.emit(card_data)
			hide_selection()
			return
		else:
			print("[CardSelection] 灵石不足，无法购买: ", card_data.name)
			if DisplayServer.get_name() == "headless":
				print("[CardSelection] Headless模式下忽略购买消耗，直接选择用于自动化测试")
				_remove_selected_card(card_data)
				card_selected.emit(card_data)
				hide_selection()
				return
	else:
		print("[CardSelection] 未找到GameManager，直接选择（测试模式）")
		_remove_selected_card(card_data)
		card_selected.emit(card_data)
		hide_selection()

func _remove_selected_card(selected: Dictionary):
	"""从当前备选列表中移除已选择的卡牌（基于id匹配）"""
	var sid = selected.get("id", null)
	if sid != null:
		for i in range(available_cards.size()):
			if available_cards[i].get("id", null) == sid:
				available_cards.remove_at(i)
				break
	else:
		available_cards.erase(selected)

func continue_selection():
	"""继续购买剩余卡牌：若仍有卡牌则重新显示窗口，否则视为关闭"""
	if available_cards.size() > 0:
		_update_card_display()
		visible = true
		_update_prices_and_buttons()
	else:
		selection_closed.emit()
		hide_selection()

func _on_close_button_pressed():
	"""关闭按钮点击"""
	selection_closed.emit()
	hide_selection()

func _on_refresh_pressed():
	"""刷新按钮点击，消耗灵石后重新生成卡牌"""
	var gm = _get_game_manager()
	if not gm:
		print("[CardSelection] 未找到GameManager，无法刷新")
		return
	var price = base_refresh_price + refresh_count * refresh_increment
	if gm.spend_resources("spirit_stones", price):
		refresh_count += 1
		available_cards = _generate_random_cards()
		_update_card_display()
		_update_prices_and_buttons()
	else:
		print("[CardSelection] 灵石不足，无法刷新。需要: ", price)

func _update_prices_and_buttons():
	"""更新刷新按钮与卡牌按钮的可用状态"""
	_update_card_display()
	_update_refresh_label()

func _update_title():
	var gm = _get_game_manager()
	if title_label and gm:
		title_label.text = "第" + str(current_day) + "天 - 选择一张卡牌    (灵石: " + str(gm.get_resource_amount("spirit_stones")) + ")"

func _update_refresh_label():
	var price = base_refresh_price + refresh_count * refresh_increment
	
	# 更新刷新价格标签
	if refresh_price_label:
		refresh_price_label.text = "刷新价格: " + str(price) + " 灵石"
	
	# 更新刷新按钮文案和状态
	if refresh_button:
		var gm = _get_game_manager()
		var stones = gm.get_resource_amount("spirit_stones") if gm else 0
		refresh_button.text = "刷新(" + str(price) + ")"
		refresh_button.disabled = stones < price
		refresh_button.tooltip_text = "" if stones >= price else "灵石不足"

func _get_game_manager() -> Node:
	var gm = get_node_or_null("../../GameManager")
	if not gm:
		gm = get_node_or_null("/root/MainGame/GameManager")
	if not gm:
		gm = get_node_or_null("/root/GameManager")
	return gm

func _get_card_manager() -> Node:
	var cm = get_node_or_null("../../CardManager")
	if not cm:
		cm = get_node_or_null("/root/MainGame/CardManager")
	return cm

func _connect_resource_signals():
	"""连接 GameManager 的资源变化信号"""
	var gm = _get_game_manager()
	if gm and gm.has_signal("resources_changed"):
		if not gm.is_connected("resources_changed", _on_resources_changed):
			gm.connect("resources_changed", _on_resources_changed)
			print("[CardSelection] Connected to GameManager resources_changed signal")
	else:
		print("[CardSelection] WARNING: GameManager not found or missing resources_changed signal")

func _on_resources_changed(resources: Dictionary):
	"""响应资源变化，更新UI状态"""
	if visible:  # 只在窗口可见时更新UI
		_update_prices_and_buttons()

func _get_card_price(card_data: Dictionary) -> int:
	var cm = _get_card_manager()
	if cm and cm.has_method("get_card_price"):
		return cm.get_card_price(card_data)
	return 10