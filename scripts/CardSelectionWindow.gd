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

func show_card_selection(day: int):
	"""显示卡牌选择窗口"""
	print("[CardSelection] show_card_selection called for day ", day)
	title_label.text = "第" + str(day) + "天 - 选择一张卡牌"
	
	# 生成3张随机卡牌
	print("[CardSelection] 开始生成随机卡牌...")
	available_cards = _generate_random_cards()
	print("[CardSelection] 生成完成，available_cards数量: ", available_cards.size())
	
	# 更新UI显示
	print("[CardSelection] 开始更新UI显示...")
	_update_card_display()
	print("[CardSelection] UI显示更新完成")
	
	# 显示窗口
	visible = true
	
	print("[CardSelection] Showing card selection for day ", day)

func hide_selection():
	"""隐藏选择窗口"""
	visible = false

func _generate_random_cards() -> Array[Dictionary]:
	"""生成3张随机地形卡牌"""
	var cards: Array[Dictionary] = []
	
	# 从CardManager获取卡牌数据
	var card_manager = get_node("../../CardManager")
	if not card_manager:
		print("[CardSelection] 错误: 无法找到CardManager节点")
		return cards
	
	# 定义所有可用的地形卡牌ID
	var terrain_card_ids = ["bamboo_forest", "mountain_peak", "river"]
	print("[CardSelection] 开始生成卡牌，可用卡牌ID: ", terrain_card_ids)
	
	# 随机打乱卡牌顺序
	terrain_card_ids.shuffle()
	print("[CardSelection] 打乱后的卡牌ID: ", terrain_card_ids)
	
	# 选择前3张卡牌（确保总是有3张卡牌）
	for i in range(3):
		var card_id = terrain_card_ids[i % terrain_card_ids.size()]
		print("[CardSelection] 尝试获取卡牌: ", card_id)
		var card_data = card_manager.get_card_by_id(card_id)
		print("[CardSelection] 获取到的卡牌数据: ", card_data)
		if card_data.size() > 0:
			cards.append(card_data)
			print("[CardSelection] 成功添加卡牌: ", card_data.name)
		else:
			print("[CardSelection] 警告: 无法获取卡牌数据: ", card_id)
	
	# 确保至少有3张卡牌
	while cards.size() < 3:
		# 如果卡牌不足，重复添加已有的卡牌
		for card_id in terrain_card_ids:
			if cards.size() >= 3:
				break
			var card_data = card_manager.get_card_by_id(card_id)
			if card_data.size() > 0:
				cards.append(card_data)
	
	print("[CardSelection] 生成了", cards.size(), "张随机地形卡牌")
	return cards

func _update_card_display():
	"""更新卡牌显示"""
	print("[CardSelection] _update_card_display called, available_cards.size(): ", available_cards.size())
	
	# 如果没有卡牌，强制生成
	if available_cards.size() == 0:
		print("[CardSelection] 警告: available_cards为空，强制重新生成")
		available_cards = _generate_random_cards()
	
	if available_cards.size() >= 1:
		card1_name.text = available_cards[0].name
		card1_description.text = available_cards[0].description
		card1_button.disabled = false
		print("[CardSelection] 卡牌1设置为: ", available_cards[0].name)
	else:
		card1_name.text = "无卡牌"
		card1_description.text = ""
		card1_button.disabled = true
		print("[CardSelection] 卡牌1设置为: 无卡牌")
	
	if available_cards.size() >= 2:
		card2_name.text = available_cards[1].name
		card2_description.text = available_cards[1].description
		card2_button.disabled = false
		print("[CardSelection] 卡牌2设置为: ", available_cards[1].name)
	else:
		card2_name.text = "无卡牌"
		card2_description.text = ""
		card2_button.disabled = true
		print("[CardSelection] 卡牌2设置为: 无卡牌")
	
	if available_cards.size() >= 3:
		card3_name.text = available_cards[2].name
		card3_description.text = available_cards[2].description
		card3_button.disabled = false
		print("[CardSelection] 卡牌3设置为: ", available_cards[2].name)
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

func _select_card(card_data: Dictionary):
	"""选择卡牌"""
	print("[CardSelection] Selected card: ", card_data.name)
	card_selected.emit(card_data)
	hide_selection()

func _on_close_button_pressed():
	"""关闭按钮点击"""
	print("[CardSelection] Selection skipped")
	selection_closed.emit()
	hide_selection()