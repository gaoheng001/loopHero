# CardManager.gd
# 卡牌管理器 - 负责卡牌数据管理、放置逻辑、效果处理等
class_name CardManager
extends Node

# 信号定义
signal card_placed(card_data: Dictionary, position: Vector2)
signal card_removed(card_data: Dictionary, position: Vector2)
signal hand_updated(new_hand: Array)
signal deck_updated(new_deck: Array)

# 卡牌类型枚举
enum CardType {
	ENEMY,
	TERRAIN,
	BUILDING,
	SPECIAL
}

# 卡牌稀有度枚举
enum CardRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# 卡牌数据
var card_database: Dictionary = {}
var player_deck: Array[Dictionary] = []
var player_hand: Array[Dictionary] = []
var max_hand_size: int = 7
var cards_per_draw: int = 1

# 放置限制
var placement_rules: Dictionary = {}

# 类型定价表（仅作为对外查询，不用于战斗掉落）
var type_price_table: Dictionary = {
    CardType.ENEMY: 0,
    CardType.TERRAIN: 10,
    CardType.BUILDING: 15,
    CardType.SPECIAL: 20
}

func _ready():
	# 初始化卡牌数据库
	_initialize_card_database()
	
	# 初始化玩家牌组
	_initialize_starter_deck()
	
	# 抽取初始手牌
	draw_cards(3)
	
	print("Card Manager initialized with ", card_database.size(), " cards in database")
	
	# 验证特定卡牌是否存在
	var test_cards = ["bamboo_forest", "mountain_peak", "river"]
	for card_id in test_cards:
		if not card_id in card_database:
			print("[CardManager] ERROR: 卡牌 '", card_id, "' 不存在于数据库中")

func _initialize_card_database():
	"""初始化卡牌数据库"""
	# 敌人卡牌
	card_database["yaokou_camp"] = {
		"id": "yaokou_camp",
		"name": "妖寇营地",
		"type": "enemy",
		"description": "生成妖寇敌人，提供少量资源",
		"enemy_data": {"name": "Yaokou", "hp": 25, "attack": 8, "defense": 2},
		"rarity": "common",
		"unlock_condition": "初始可用"
	}
	
	card_database["kugu_yinzong"] = {
		"id": "kugu_yinzong",
		"name": "枯骨阴冢",
		"type": "enemy",
		"description": "生成枯骨敌人，掉落骨材",
		"enemy_data": {"name": "Kugu", "hp": 20, "attack": 12, "defense": 1},
		"rarity": "uncommon",
		"unlock_condition": "完成一次循环",
		"terrain_effect": {"terrain": "yinzong", "effect": "+5% 暴击率"}
	}
	
	# 地形卡牌
	card_database["rock"] = {
		"id": "rock",
		"name": "岩石",
		"type": CardType.TERRAIN,
		"rarity": CardRarity.COMMON,
		"description": "提供防御加成，相邻敌人+2防御",
		"effects": {"adjacent_defense_bonus": 2},
		"placement_type": "roadside"
	}
	
	card_database["forest"] = {
		"id": "forest",
		"name": "森林",
		"type": CardType.TERRAIN,
		"rarity": CardRarity.COMMON,
		"description": "每次经过恢复2点生命值",
		"effects": {"heal_on_pass": 2},
		"placement_type": "roadside"
	}
	
	card_database["meadow"] = {
		"id": "meadow",
		"name": "草地",
		"type": CardType.TERRAIN,
		"rarity": CardRarity.COMMON,
		"description": "提供少量食物资源",
		"effects": {"food_bonus": 1},
		"placement_type": "roadside"
	}
	
	# 新增的buff地形卡牌
	card_database["bamboo_forest"] = {
		"id": "bamboo_forest",
		"name": "竹林",
		"type": CardType.TERRAIN,
		"rarity": CardRarity.RARE,
		"description": "放置时角色攻击+5，每天攻击+1",
		"effects": {
			"initial_attack_bonus": 5,
			"daily_attack_bonus": 1
		},
		"placement_type": "roadside"
	}
	
	card_database["mountain_peak"] = {
		"id": "mountain_peak",
		"name": "山峰",
		"type": CardType.TERRAIN,
		"rarity": CardRarity.RARE,
		"description": "放置时角色生命上限+10，每天恢复10点血量",
		"effects": {
			"initial_max_hp_bonus": 10,
			"daily_heal": 10
		},
		"placement_type": "roadside"
	}
	
	card_database["river"] = {
		"id": "river",
		"name": "河流",
		"type": CardType.TERRAIN,
		"rarity": CardRarity.UNCOMMON,
		"description": "每块河流提供1%经验加成",
		"effects": {
			"experience_bonus_percent": 1
		},
		"placement_type": "roadside"
	}
	
	card_database["old_meadow"] = {
		"id": "old_meadow",
		"name": "旧草地",
		"type": CardType.TERRAIN,
		"rarity": CardRarity.COMMON,
		"description": "每完成一圈获得1食物",
		"effects": {"food_per_loop": 1},
		"placement_type": "roadside"
	}
	
	# 建筑卡牌
	card_database["village"] = {
		"id": "village",
		"name": "村庄",
		"type": CardType.BUILDING,
		"rarity": CardRarity.UNCOMMON,
		"description": "每圈提供资源，相邻草地+1食物产出",
		"effects": {"resources_per_loop": {"wood": 1, "food": 2}, "meadow_bonus": 1},
		"placement_type": "roadside"
	}
	
	card_database["watchtower"] = {
		"id": "watchtower",
		"name": "瞭望塔",
		"type": CardType.BUILDING,
		"rarity": CardRarity.UNCOMMON,
		"description": "提供攻击加成，相邻敌人+3攻击力",
		"effects": {"adjacent_attack_bonus": 3},
		"placement_type": "roadside"
	}
	
	# 特殊卡牌
	card_database["treasury"] = {
		"id": "treasury",
		"name": "宝库",
		"type": CardType.SPECIAL,
		"rarity": CardRarity.RARE,
		"description": "战斗胜利后额外获得资源",
		"effects": {"bonus_resources_multiplier": 1.5},
		"placement_type": "roadside"
	}

func _initialize_starter_deck():
	"""初始化新手牌组"""
	player_deck.clear()
	
	# 添加基础卡牌
	for i in range(3):
		player_deck.append(card_database["yaokou_camp"].duplicate())
	
	for i in range(2):
		player_deck.append(card_database["rock"].duplicate())
		player_deck.append(card_database["forest"].duplicate())
	
	player_deck.append(card_database["meadow"].duplicate())
	
	# 洗牌
	shuffle_deck()
	
	print("Initialized starter deck with ", player_deck.size(), " cards")

func shuffle_deck():
	"""洗牌"""
	player_deck.shuffle()
	deck_updated.emit(player_deck)

func draw_cards(count: int = 1):
	"""抽卡"""
	var drawn = 0
	
	while drawn < count and player_hand.size() < max_hand_size and player_deck.size() > 0:
		var card = player_deck.pop_back()
		player_hand.append(card)
		drawn += 1
	
	hand_updated.emit(player_hand)
	deck_updated.emit(player_deck)
	
	print("Drew ", drawn, " cards. Hand size: ", player_hand.size())

func can_place_card(card_data: Dictionary, tile_index: int, loop_manager: Node) -> bool:
	"""检查是否可以放置卡牌"""
	# 检查位置是否已有卡牌
	if loop_manager.get_card_at_tile(tile_index).size() > 0:
		return false
	
	# 检查卡牌类型的放置规则
	match card_data.placement_type:
		"path":
			# 路径卡牌只能放在路径上
			return true
		"roadside":
			# 路边卡牌可以放在路径旁边（这里简化为都可以放置）
			return true
		_:
			return false

func place_card(card_index: int, tile_index: int, loop_manager: Node) -> bool:
	"""放置卡牌"""
	if card_index < 0 or card_index >= player_hand.size():
		print("Invalid card index: ", card_index)
		return false
	
	var card_data = player_hand[card_index]
	
	if not can_place_card(card_data, tile_index, loop_manager):
		print("Cannot place card at tile ", tile_index)
		return false
	
	# 放置卡牌
	if loop_manager.place_card_at_tile(tile_index, card_data):
		# 从手牌中移除
		player_hand.remove_at(card_index)
		
		# 发送信号
		var position = loop_manager.get_tile_position(tile_index)
		card_placed.emit(card_data, position)
		hand_updated.emit(player_hand)
		
		# 抽取新卡牌
		draw_cards(cards_per_draw)
		
		print("Placed card '", card_data.name, "' at tile ", tile_index)
		return true
	else:
		return false

func remove_card_from_tile(tile_index: int, loop_manager: Node) -> Dictionary:
	"""从瓦片移除卡牌"""
	var removed_card = loop_manager.remove_card_at_tile(tile_index)
	
	if removed_card != null and removed_card.size() > 0:
		var position = loop_manager.get_tile_position(tile_index)
		card_removed.emit(removed_card, position)
		print("Removed card '", removed_card.name, "' from tile ", tile_index)
	
	return removed_card

func add_card_to_deck(card_id: String):
	"""添加卡牌到牌组"""
	if card_id in card_database:
		var new_card = card_database[card_id].duplicate()
		player_deck.append(new_card)
		deck_updated.emit(player_deck)
		print("Added card '", new_card.name, "' to deck")
		return true
	else:
		print("Card not found in database: ", card_id)
		return false

func get_card_by_id(card_id: String) -> Dictionary:
	"""根据ID获取卡牌数据"""
	if card_database.is_empty():
		print("[CardManager] ERROR: 卡牌数据库为空！")
		return {}
	
	if card_id.is_empty():
		print("[CardManager] ERROR: 卡牌ID为空")
		return {}
	
	if card_id in card_database:
		return card_database[card_id]
	else:
		print("[CardManager] WARNING: 卡牌ID '", card_id, "' 不存在于数据库中")
		return {}

func get_hand() -> Array[Dictionary]:
	"""获取当前手牌"""
	return player_hand

func get_deck() -> Array[Dictionary]:
	"""获取当前牌组"""
	return player_deck

func get_hand_size() -> int:
	"""获取手牌数量"""
	return player_hand.size()

func get_deck_size() -> int:
	"""获取牌组数量"""
	return player_deck.size()

func apply_card_effects(card_data: Dictionary, context: String = ""):
	"""应用卡牌效果"""
	if not card_data.has("effects"):
		return
	
	var effects = card_data.effects
	
	match context:
		"on_place":
			_apply_placement_effects(effects)
		"on_pass":
			_apply_pass_effects(effects)
		"on_loop_complete":
			_apply_loop_effects(effects)
		"on_battle":
			_apply_battle_effects(effects)
		_:
			_apply_general_effects(effects)

func _apply_placement_effects(effects: Dictionary):
	"""应用放置时效果"""
	print("Applying placement effects: ", effects)

func _apply_pass_effects(effects: Dictionary):
	"""应用经过时效果"""
	if effects.has("heal_on_pass"):
		# TODO: 治疗英雄
		print("Healing hero for ", effects.heal_on_pass, " HP")

func _apply_loop_effects(effects: Dictionary):
	"""应用循环完成时效果"""
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("add_resources"):
		if effects.has("food_per_loop"):
			game_manager.add_resources("food", effects.food_per_loop)
		
		if effects.has("resources_per_loop"):
			for resource_type in effects.resources_per_loop:
				var amount = effects.resources_per_loop[resource_type]
				game_manager.add_resources(resource_type, amount)

func _apply_battle_effects(effects: Dictionary):
	"""应用战斗时效果"""
	print("Applying battle effects: ", effects)

func _apply_general_effects(effects: Dictionary):
	"""应用通用效果"""
	print("Applying general effects: ", effects)

func get_cards_by_type(card_type: CardType) -> Array[Dictionary]:
	"""根据类型获取卡牌"""
	var result: Array[Dictionary] = []
	
	for card in card_database.values():
		if card.type == card_type:
			result.append(card)
	
	return result

func get_cards_by_rarity(rarity: CardRarity) -> Array[Dictionary]:
	"""根据稀有度获取卡牌"""
	var result: Array[Dictionary] = []
	
	for card in card_database.values():
		if card.rarity == rarity:
			result.append(card)
	
	return result

func get_card_price(card_data: Dictionary) -> int:
	"""按类型返回卡牌价格（默认地形10、建筑15、特殊20、敌人0）"""
	var t = card_data.get("type", null)
	# 兼容字符串与枚举
	if typeof(t) == TYPE_STRING:
		match t:
			"enemy":
				return type_price_table[CardType.ENEMY]
			"terrain":
				return type_price_table[CardType.TERRAIN]
			"building":
				return type_price_table[CardType.BUILDING]
			"special":
				return type_price_table[CardType.SPECIAL]
			_:
				return 10
	elif typeof(t) == TYPE_INT:
		return type_price_table.get(t, 10)
	else:
		return 10

func generate_random_cards(count: int = 3, allowed_types: Array = [CardType.TERRAIN]) -> Array[Dictionary]:
	"""生成指定数量的随机卡牌（按允许类型过滤）"""
	var pool: Array[Dictionary] = []
	for card in card_database.values():
		if allowed_types.has(card.type):
			pool.append(card)
	if pool.size() == 0:
		return []
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i in range(count):
		result.append(pool[i % pool.size()].duplicate())
	return result