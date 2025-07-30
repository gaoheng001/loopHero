# LoopManager.gd
# 循环管理器 - 负责英雄移动、循环路径管理、战斗触发等
class_name LoopManager
extends Node2D

# 信号定义
signal hero_moved(new_position: Vector2)
signal battle_started(enemy_data: Dictionary)
signal tile_reached(tile_position: Vector2)
signal loop_completed

# 循环路径配置
const TILE_SIZE = 64
const LOOP_RADIUS = 200
const TILES_PER_LOOP = 12
const MOVE_SPEED = 100.0

# 循环状态
var current_tile_index: int = 0
var is_moving: bool = false
var hero_position: Vector2
var loop_path: Array[Vector2] = []
var placed_cards: Dictionary = {}  # tile_index -> card_data

# 引用
var hero_node: Node2D
var card_manager: CardManager
var battle_manager: BattleManager

func _ready():
	# 生成循环路径
	_generate_loop_path()
	
	# 连接信号
	tile_reached.connect(_on_tile_reached)
	
	# 初始化英雄位置
	hero_position = loop_path[0]
	
	print("Loop Manager initialized with ", TILES_PER_LOOP, " tiles")

func _generate_loop_path():
	"""生成循环路径的瓦片位置"""
	loop_path.clear()
	
	for i in range(TILES_PER_LOOP):
		var angle = (float(i) / TILES_PER_LOOP) * 2 * PI
		var x = cos(angle) * LOOP_RADIUS
		var y = sin(angle) * LOOP_RADIUS
		loop_path.append(Vector2(x, y))
	
	print("Generated loop path with ", loop_path.size(), " positions")

func start_hero_movement():
	"""开始英雄移动"""
	if not is_moving:
		is_moving = true
		_move_to_next_tile()

func stop_hero_movement():
	"""停止英雄移动"""
	is_moving = false

func _move_to_next_tile():
	"""移动到下一个瓦片"""
	if not is_moving:
		return
	
	# 移动到下一个位置
	current_tile_index = (current_tile_index + 1) % TILES_PER_LOOP
	var target_position = loop_path[current_tile_index]
	
	# 创建移动补间动画
	var tween = create_tween()
	tween.tween_property(self, "hero_position", target_position, MOVE_SPEED / 100.0)
	tween.tween_callback(_on_movement_completed)
	
	hero_moved.emit(target_position)

func _on_movement_completed():
	"""移动完成回调"""
	tile_reached.emit(loop_path[current_tile_index])
	
	# 检查是否完成一圈
	if current_tile_index == 0:
		loop_completed.emit()
	
	# 继续移动（如果还在移动状态）
	if is_moving:
		# 添加延迟，让玩家有时间观察
		await get_tree().create_timer(0.5).timeout
		_move_to_next_tile()

func _on_tile_reached(tile_position: Vector2):
	"""到达瓦片时的处理"""
	print("Hero reached tile ", current_tile_index, " at position ", tile_position)
	
	# 检查该位置是否有卡牌
	if current_tile_index in placed_cards:
		var card_data = placed_cards[current_tile_index]
		_handle_card_effect(card_data)
	
	# 检查是否触发战斗
	_check_for_battle()

func _handle_card_effect(card_data: Dictionary):
	"""处理卡牌效果"""
	match card_data.type:
		"enemy":
			_trigger_battle(card_data)
		"terrain":
			_apply_terrain_effect(card_data)
		"building":
			_apply_building_effect(card_data)
		"special":
			_apply_special_effect(card_data)

func _trigger_battle(enemy_card: Dictionary):
	"""触发战斗"""
	print("Battle triggered with ", enemy_card.name)
	battle_started.emit(enemy_card)
	
	# 暂停移动直到战斗结束
	stop_hero_movement()

func _apply_terrain_effect(terrain_card: Dictionary):
	"""应用地形效果"""
	print("Applying terrain effect: ", terrain_card.name)
	# TODO: 实现具体的地形效果

func _apply_building_effect(building_card: Dictionary):
	"""应用建筑效果"""
	print("Applying building effect: ", building_card.name)
	# TODO: 实现具体的建筑效果

func _apply_special_effect(special_card: Dictionary):
	"""应用特殊效果"""
	print("Applying special effect: ", special_card.name)
	# TODO: 实现具体的特殊效果

func _check_for_battle():
	"""检查是否需要触发随机战斗"""
	# 基础战斗概率（可以根据循环次数调整）
	var battle_chance = 0.3
	if GameManager.instance:
		battle_chance += GameManager.instance.loop_number * 0.1
	
	if randf() < battle_chance:
		# 生成随机敌人
		var random_enemy = _generate_random_enemy()
		_trigger_battle(random_enemy)

func _generate_random_enemy() -> Dictionary:
	"""生成随机敌人"""
	var enemies = [
		{"name": "Goblin", "hp": 20, "attack": 5, "defense": 2},
		{"name": "Skeleton", "hp": 15, "attack": 7, "defense": 1},
		{"name": "Spider", "hp": 12, "attack": 6, "defense": 0}
	]
	
	return enemies[randi() % enemies.size()]

func place_card_at_tile(tile_index: int, card_data: Dictionary):
	"""在指定瓦片放置卡牌"""
	if tile_index >= 0 and tile_index < TILES_PER_LOOP:
		placed_cards[tile_index] = card_data
		print("Placed card '", card_data.name, "' at tile ", tile_index)
		return true
	else:
		print("Invalid tile index: ", tile_index)
		return false

func remove_card_at_tile(tile_index: int):
	"""移除指定瓦片的卡牌"""
	if tile_index in placed_cards:
		var removed_card = placed_cards[tile_index]
		placed_cards.erase(tile_index)
		print("Removed card '", removed_card.name, "' from tile ", tile_index)
		return removed_card
	else:
		print("No card at tile ", tile_index)
		return null

func get_card_at_tile(tile_index: int) -> Dictionary:
	"""获取指定瓦片的卡牌"""
	return placed_cards.get(tile_index, {})

func get_tile_position(tile_index: int) -> Vector2:
	"""获取瓦片的世界坐标"""
	if tile_index >= 0 and tile_index < loop_path.size():
		return loop_path[tile_index]
	else:
		return Vector2.ZERO

func get_current_tile_index() -> int:
	"""获取当前瓦片索引"""
	return current_tile_index

func get_hero_position() -> Vector2:
	"""获取英雄当前位置"""
	return hero_position

func on_battle_ended(victory: bool):
	"""战斗结束回调"""
	if victory:
		print("Battle won! Continuing movement...")
	else:
		print("Battle lost! Hero died...")
		GameManager.instance.hero_death()
		return
	
	# 恢复移动
	start_hero_movement()

func reset_loop():
	"""重置循环状态"""
	current_tile_index = 0
	hero_position = loop_path[0]
	is_moving = false
	placed_cards.clear()
	print("Loop reset to starting position")

func _draw():
	"""绘制循环路径（调试用）"""
	if loop_path.size() > 0:
		# 绘制路径
		for i in range(loop_path.size()):
			var current_pos = loop_path[i]
			var next_pos = loop_path[(i + 1) % loop_path.size()]
			draw_line(current_pos, next_pos, Color.WHITE, 2.0)
		
		# 绘制瓦片位置
		for i in range(loop_path.size()):
			var pos = loop_path[i]
			var color = Color.YELLOW if i == current_tile_index else Color.GRAY
			draw_circle(pos, 8, color)
		
		# 绘制英雄位置
		draw_circle(hero_position, 12, Color.BLUE)