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

func _ready():
	# 连接按钮信号
	card1_button.pressed.connect(_on_card1_selected)
	card2_button.pressed.connect(_on_card2_selected)
	card3_button.pressed.connect(_on_card3_selected)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 初始状态隐藏窗口
	visible = false
	
	# 测试CardManager功能
	call_deferred("_test_card_manager")

func show_card_selection(day: int):
	"""显示卡牌选择窗口"""
	
	# 检查UI组件是否可用（headless模式下可能为空）
	if title_label:
		title_label.text = "第" + str(day) + "天 - 选择一张卡牌"
	
	# 生成3张随机卡牌
	available_cards = _generate_random_cards()
	
	if available_cards.size() == 0:
		print("[CardSelection] ERROR: No cards generated! This will cause problems.")
		return
	
	# 更新UI显示
	_update_card_display()
	
	# 显示窗口
	visible = true
	
	# 在headless模式下自动选择第一张卡牌
	if DisplayServer.get_name() == "headless":
		await get_tree().create_timer(1.0).timeout
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
	
	# 从CardManager获取卡牌数据 - 修复节点路径
	var card_manager = get_node_or_null("../../CardManager")
	if not card_manager:
		card_manager = get_node_or_null("/root/MainGame/CardManager")
		if not card_manager:
			print("[CardSelection] ERROR: 无法找到CardManager节点")
			return cards
	
	# 验证CardManager的状态
	if not "card_database" in card_manager:
		print("[CardSelection] ERROR: CardManager没有card_database属性!")
		return cards
	
	# 动态获取所有地形卡牌ID
	var terrain_card_ids = []
	var terrain_type_value = str(CardManager.CardType.TERRAIN)
	
	for card_id in card_manager.card_database.keys():
		var card_data = card_manager.card_database[card_id]
		if card_data.has("type"):
			var type_str = str(card_data["type"])
			if type_str == terrain_type_value:
				terrain_card_ids.append(card_id)
	
	if terrain_card_ids.size() == 0:
		print("[CardSelection] ERROR: 没有找到地形卡牌")
		return cards
	
	# 随机打乱卡牌顺序
	terrain_card_ids.shuffle()
	
	# 选择前3张卡牌（确保总是有3张卡牌）
	for i in range(3):
		var card_id = terrain_card_ids[i % terrain_card_ids.size()]
		var card_data = card_manager.get_card_by_id(card_id)
		
		if card_data.is_empty():
			print("[CardSelection] WARNING: 无法获取卡牌数据: ", card_id)
			# 创建默认卡牌数据作为回退
			var default_card = {
				"id": card_id,
				"name": "未知卡牌",
				"description": "卡牌数据加载失败",
				"type": CardManager.CardType.TERRAIN,
				"rarity": CardManager.CardRarity.COMMON,
				"effects": {}
			}
			cards.append(default_card)
		else:
			cards.append(card_data)
	
	return cards

func _update_card_display():
	"""更新卡牌显示"""
	
	# 如果没有卡牌，强制生成
	if available_cards.size() == 0:
		print("[CardSelection] WARNING: available_cards为空，强制重新生成")
		available_cards = _generate_random_cards()
	
	if available_cards.size() >= 1:
		card1_name.text = available_cards[0].name
		card1_description.text = available_cards[0].description
		card1_button.disabled = false
	else:
		card1_name.text = "无卡牌"
		card1_description.text = ""
		card1_button.disabled = true
	
	if available_cards.size() >= 2:
		card2_name.text = available_cards[1].name
		card2_description.text = available_cards[1].description
		card2_button.disabled = false
	else:
		card2_name.text = "无卡牌"
		card2_description.text = ""
		card2_button.disabled = true
	
	if available_cards.size() >= 3:
		card3_name.text = available_cards[2].name
		card3_description.text = available_cards[2].description
		card3_button.disabled = false
	else:
		card3_name.text = "无卡牌"
		card3_description.text = ""
		card3_button.disabled = true

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
	card_selected.emit(card_data)
	hide_selection()

func _on_close_button_pressed():
	"""关闭按钮点击"""
	selection_closed.emit()
	hide_selection()