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
	print("[CardSelection] show_card_selection called for day ", day)
	print("[CardSelection] DisplayServer name: ", DisplayServer.get_name())
	
	# 检查UI组件是否可用（headless模式下可能为空）
	if title_label:
		title_label.text = "第" + str(day) + "天 - 选择一张卡牌"
	else:
		print("[CardSelection] title_label is null (headless mode)")
	
	# 生成3张随机卡牌
	print("[CardSelection] 开始生成随机卡牌...")
	available_cards = _generate_random_cards()
	print("[CardSelection] 生成完成，available_cards数量: ", available_cards.size())
	
	if available_cards.size() == 0:
		print("[CardSelection] ERROR: No cards generated! This will cause problems.")
		return
	
	# 更新UI显示
	print("[CardSelection] 开始更新UI显示...")
	_update_card_display()
	print("[CardSelection] UI显示更新完成")
	
	# 显示窗口
	visible = true
	print("[CardSelection] Window visibility set to true")
	
	print("[CardSelection] Showing card selection for day ", day)
	
	# 在headless模式下自动选择第一张卡牌
	if DisplayServer.get_name() == "headless":
		print("[CardSelection] Headless mode detected, auto-selecting first card in 1 second...")
		await get_tree().create_timer(1.0).timeout
		print("[CardSelection] Timer completed, checking available cards...")
		if available_cards.size() > 0:
			print("[CardSelection] Auto-selecting card: ", available_cards[0].name)
			_select_card(available_cards[0])
			print("[CardSelection] Card selection completed")
		else:
			print("[CardSelection] No cards available for auto-selection, closing window")
			_on_close_button_pressed()
	else:
		print("[CardSelection] Not in headless mode, waiting for user selection")

func hide_selection():
	"""隐藏选择窗口"""
	visible = false

func _generate_random_cards() -> Array[Dictionary]:
	"""生成3张随机地形卡牌"""
	var cards: Array[Dictionary] = []
	
	# 从CardManager获取卡牌数据 - 修复节点路径
	print("[CardSelection] 尝试获取CardManager节点...")
	var card_manager = get_node_or_null("../../CardManager")
	if not card_manager:
		print("[CardSelection] 主路径失败，尝试备用路径...")
		card_manager = get_node_or_null("/root/MainGame/CardManager")
		if not card_manager:
			print("[CardSelection] 错误: 所有路径都无法找到CardManager节点")
			print("[CardSelection] 当前节点路径: ", get_path())
			print("[CardSelection] 父节点: ", get_parent().get_path() if get_parent() else "无父节点")
			return cards
		else:
			print("[CardSelection] 通过备用路径成功找到CardManager")
	else:
		print("[CardSelection] 通过主路径成功找到CardManager")
	
	# 验证CardManager的状态
	print("[CardSelection] CardManager节点类型: ", card_manager.get_class())
	print("[CardSelection] CardManager是否有card_database属性: ", "card_database" in card_manager)
	if "card_database" in card_manager:
		print("[CardSelection] CardManager.card_database大小: ", card_manager.card_database.size())
		print("[CardSelection] CardManager.card_database键列表: ", card_manager.card_database.keys())
	else:
		print("[CardSelection] 错误: CardManager没有card_database属性!")
	
	# 动态获取所有地形卡牌ID
	var terrain_card_ids = []
	var terrain_type_value = str(CardManager.CardType.TERRAIN)
	print("[CardSelection] 寻找type值为 '", terrain_type_value, "' 的地形卡牌")
	
	for card_id in card_manager.card_database.keys():
		var card_data = card_manager.card_database[card_id]
		if card_data.has("type"):
			var type_str = str(card_data["type"])
			if type_str == terrain_type_value:
				terrain_card_ids.append(card_id)
				print("[CardSelection] 添加地形卡牌: ", card_id)
	
	print("[CardSelection] 开始生成卡牌，可用地形卡牌ID: ", terrain_card_ids)
	print("[CardSelection] 总共找到 ", terrain_card_ids.size(), " 张地形卡牌")
	
	# 随机打乱卡牌顺序
	terrain_card_ids.shuffle()
	print("[CardSelection] 打乱后的卡牌ID: ", terrain_card_ids)
	
	# 选择前3张卡牌（确保总是有3张卡牌）
	for i in range(3):
		var card_id = terrain_card_ids[i % terrain_card_ids.size()]
		print("[CardSelection] 尝试获取卡牌: ", card_id)
		var card_data = card_manager.get_card_by_id(card_id)
		print("[CardSelection] 获取到的卡牌数据: ", card_data)
		
		if card_data.is_empty():
			print("[CardSelection] 警告: 无法获取卡牌数据: ", card_id)
			# 创建默认卡牌数据作为回退
			var default_card = {
				"id": card_id,
				"name": "未知卡牌",
				"description": "卡牌数据加载失败",
				"type": CardManager.CardType.TERRAIN,
				"rarity": CardManager.CardRarity.COMMON,
				"effects": {}
			}
			print("[CardSelection] 使用默认卡牌数据: ", default_card)
			cards.append(default_card)
		else:
			cards.append(card_data)
			print("[CardSelection] 成功添加卡牌: ", card_data.name)
	
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

func _test_card_manager():
	"""测试CardManager功能"""
	print("[CardSelectionWindow] 开始测试CardManager功能...")
	
	# 尝试获取CardManager
	var card_manager = get_node_or_null("../../CardManager")
	if not card_manager:
		card_manager = get_node_or_null("/root/MainGame/CardManager")
	
	if not card_manager:
		print("[CardSelectionWindow] 错误: 无法找到CardManager节点")
		return
	
	print("[CardSelectionWindow] 找到CardManager节点")
	print("[CardSelectionWindow] CardManager类型: ", card_manager.get_class())
	
	# 测试获取卡牌
	var test_card_ids = ["bamboo_forest", "mountain_peak", "river"]
	for card_id in test_card_ids:
		print("[CardSelectionWindow] 测试获取卡牌: ", card_id)
		var card_data = card_manager.get_card_by_id(card_id)
		print("[CardSelectionWindow] 获取结果: ", card_data)
		if not card_data.is_empty():
			print("[CardSelectionWindow] 成功获取卡牌: ", card_data.get("name", "未知"))
		else:
			print("[CardSelectionWindow] 获取卡牌失败: ", card_id)

func _select_card(card_data: Dictionary):
	"""选择卡牌"""
	print("[CardSelectionWindow] _select_card called with card: ", card_data.name)
	print("[CardSelectionWindow] Available cards count: ", available_cards.size())
	print("[CardSelectionWindow] Selected card: ", card_data.name)
	print("[CardSelectionWindow] Emitting card_selected signal...")
	card_selected.emit(card_data)
	print("[CardSelectionWindow] card_selected signal emitted, hiding window...")
	hide_selection()
	print("[CardSelectionWindow] Window hidden")

func _on_close_button_pressed():
	"""关闭按钮点击"""
	print("[CardSelection] Selection skipped")
	selection_closed.emit()
	hide_selection()