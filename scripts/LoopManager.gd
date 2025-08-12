# LoopManager.gd
# 循环管理器 - 负责英雄移动、循环路径管理、战斗触发等
class_name LoopManager
extends Node2D

# 信号定义
signal hero_moved(new_position: Vector2)
signal battle_started(enemy_data: Dictionary)
signal tile_reached(tile_position: Vector2)
signal loop_completed
signal step_count_updated(step_count: int)
signal day_changed(day: int)
signal monsters_spawned(monster_positions: Array)

# 循环路径配置
const TILE_SIZE = 64
const LOOP_RADIUS = 200
const TILES_PER_LOOP = 12
const MOVE_SPEED = 100.0

# 时间系统配置
const STEPS_PER_DAY = 20

# 路径类型枚举
enum PathType {
	CIRCULAR,	# 固定圆形路径
	CUSTOM		# 从TileMapLayer读取的自定义路径
}

# 当前路径类型
var current_path_type: PathType = PathType.CUSTOM

# 循环状态
var current_tile_index: int = 0
var is_moving: bool = false
var movement_tween: Tween  # 移动动画的 tween 实例
var hero_position: Vector2
var loop_path: Array[Vector2] = []
var placed_cards: Dictionary = {}  # tile_index -> card_data
var just_finished_battle: bool = false  # 刚刚结束战斗的标记
var step_count: int = 0  # 步数计数器

# 时间系统
var current_day: int = 1  # 当前天数
var steps_in_current_day: int = 0  # 当前天内的步数

# 怪物系统
var spawned_monsters: Dictionary = {}  # tile_index -> monster_data
var monster_sprites: Dictionary = {}  # tile_index -> Sprite2D

# 引用
var hero_node: CharacterBody2D
var card_manager: Node
var battle_manager: Node
var tile_map_layer: TileMapLayer

func _ready():
	# 获取TileMapLayer引用
	tile_map_layer = get_node("Level1TileMapLayer")
	
	# 初始化节点引用
	hero_node = get_node_or_null("../Character_sword")
	card_manager = get_node_or_null("/root/CardManager")
	battle_manager = get_node_or_null("/root/BattleManager")
	
	# 检查关键引用是否成功获取
	if not hero_node:
		print("Warning: Character_sword node not found!")
	else:
		print("Character_sword node found successfully!")
		# 确保Character_sword节点可见
		hero_node.visible = true
		hero_node.show()
		# 确保AnimatedSprite2D也可见
		var animated_sprite = hero_node.get_node("AnimatedSprite2D")
		if animated_sprite:
			animated_sprite.visible = true
			animated_sprite.show()
	if not card_manager:
		print("Warning: CardManager not found!")
	if not battle_manager:
		print("Warning: BattleManager not found!")
	
	# 生成循环路径
	_generate_loop_path()
	
	# 初始化第一关地图
	_initialize_level1_map()
	
	# 连接信号
	tile_reached.connect(_on_tile_reached)
	
	# 初始化英雄位置
	if loop_path.size() > 0:
		hero_position = loop_path[0]
	else:
		hero_position = Vector2.ZERO
		print("Warning: No valid loop path found!")
	
	# 生成初始怪物
	_spawn_initial_monsters()
	
	# 初始绘制
	queue_redraw()
	
	print("Loop Manager initialized with ", loop_path.size(), " path points")

func _generate_loop_path():
	"""生成循环路径的瓦片位置"""
	loop_path.clear()
	
	match current_path_type:
		PathType.CIRCULAR:
			_generate_circular_path()
		PathType.CUSTOM:
			_generate_custom_path_from_tilemap()
	
	print("Generated loop path with ", loop_path.size(), " positions")

func _generate_circular_path():
	"""生成固定圆形路径"""
	for i in range(TILES_PER_LOOP):
		var angle = (float(i) / TILES_PER_LOOP) * 2 * PI
		var x = cos(angle) * LOOP_RADIUS
		var y = sin(angle) * LOOP_RADIUS
		loop_path.append(Vector2(x, y))

func _generate_custom_path_from_tilemap():
	"""从TileMapLayer读取自定义路径点"""
	if not tile_map_layer:
		print("Warning: TileMapLayer not found, falling back to circular path")
		_generate_circular_path()
		return
	
	# 扫描TileMapLayer寻找路径瓦片
	var path_points: Array[Vector2] = []
	var search_radius = 50  # 扩大搜索半径
	
	# 在指定范围内搜索路径瓦片
	for x in range(-search_radius, search_radius + 1):
		for y in range(-search_radius, search_radius + 1):
			var tile_pos = Vector2i(x, y)
			var tile_data = tile_map_layer.get_cell_source_id(tile_pos)
			var atlas_coords = tile_map_layer.get_cell_atlas_coords(tile_pos)
			

			# 检查是否是路径瓦片（source ID不为-1且atlas坐标为(25,5)表示路径）
			if tile_data != -1 and atlas_coords == Vector2i(25, 5):
				# 将瓦片坐标转换为TileMapLayer的本地坐标
				var tile_local_pos = tile_map_layer.map_to_local(tile_pos)
				# 应用TileMapLayer的变换（position和scale）
				var transformed_pos = tile_local_pos * tile_map_layer.scale + tile_map_layer.position
				# 转换为相对于LoopManager的本地坐标（LoopManager position是(640, 360)）
				var final_pos = transformed_pos + position
				path_points.append(final_pos)
	
	print("Found ", path_points.size(), " path tiles in TileMapLayer")
	
	# 如果找到路径点，按距离排序形成连续路径
	if path_points.size() > 0:
		_sort_path_points(path_points)
		loop_path = path_points
		print("Using custom path with ", loop_path.size(), " points")
	else:
		print("No custom path found in TileMapLayer, using circular path")
		_generate_circular_path()

func _sort_path_points(points: Array[Vector2]):
	"""对路径点进行排序，形成连续的循环路径"""
	if points.size() <= 1:
		return
	
	# 简单的最近邻排序算法
	var sorted_points: Array[Vector2] = []
	var remaining_points = points.duplicate()
	
	# 从第一个点开始
	sorted_points.append(remaining_points[0])
	remaining_points.remove_at(0)
	
	# 依次找最近的点
	while remaining_points.size() > 0:
		var current_pos = sorted_points[-1]
		var nearest_index = 0
		var nearest_distance = current_pos.distance_to(remaining_points[0])
		
		for i in range(1, remaining_points.size()):
			var distance = current_pos.distance_to(remaining_points[i])
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_index = i
		
		sorted_points.append(remaining_points[nearest_index])
		remaining_points.remove_at(nearest_index)
	
	points.clear()
	points.append_array(sorted_points)

func _initialize_level1_map():
	"""初始化第一关地图"""
	if not tile_map_layer:
		print("Warning: TileMapLayer not found!")
		return
	
	# 当使用自定义路径时，保持TileMapLayer中已有的瓦片数据
	if current_path_type == PathType.CUSTOM:
		print("Using existing TileMapLayer data for custom path")
		return
	
	# 只有在使用圆形路径时才创建新的瓦片数据
	# 创建基础草地背景 (使用瓦片ID 0)
	for x in range(-10, 11):
		for y in range(-8, 9):
			tile_map_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	
	# 在循环路径上放置路径瓦片 (使用瓦片ID 0，不同的atlas坐标)
	for i in range(loop_path.size()):
		var world_pos = loop_path[i]
		var tile_pos = Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))
		tile_map_layer.set_cell(tile_pos, 0, Vector2i(25, 2))  # 路径瓦片
	
	print("Level 1 map initialized with basic terrain")

func start_hero_movement():
	"""开始英雄移动"""
	if not is_moving:
		is_moving = true
		# 确保Character_sword节点位于起始位置
		if hero_node and loop_path.size() > 0:
			hero_node.position = loop_path[0]
			hero_position = loop_path[0]
		queue_redraw()  # 初始绘制
		_move_to_next_tile()

func stop_hero_movement():
	"""停止英雄移动"""
	is_moving = false
	# 停止walk动画
	if hero_node:
		var animated_sprite = hero_node.get_node("AnimatedSprite2D")
		if animated_sprite:
			animated_sprite.stop()

func _move_to_next_tile():
	"""移动到下一个瓦片"""
	if not is_moving or loop_path.size() == 0:
		return
	
	# 移动到下一个位置
	current_tile_index = (current_tile_index + 1) % loop_path.size()
	var target_position = loop_path[current_tile_index]
	
	# 计算移动方向并设置动画镜像
	if hero_node:
		var animated_sprite = hero_node.get_node("AnimatedSprite2D")
		if animated_sprite:
			# 计算移动方向
			var delta_x = target_position.x - hero_position.x
			var delta_y = target_position.y - hero_position.y
			
			# 判断是否需要镜像：向左移动或从上往下移动时使用镜像
			var should_flip = false
			if abs(delta_x) > abs(delta_y):
				# 主要是水平移动
				should_flip = delta_x < 0  # 向左移动
			else:
				# 主要是垂直移动
				should_flip = delta_y > 0  # 从上往下移动
			
			animated_sprite.flip_h = should_flip
	
	# 确保之前的 tween 被停止
	if movement_tween:
		movement_tween.kill()
		print("[LoopManager] Killed previous tween")
	
	# 创建移动补间动画
	movement_tween = create_tween()
	# 设置补间动画属性，使移动更平滑
	movement_tween.set_ease(Tween.EASE_IN_OUT)
	movement_tween.set_trans(Tween.TRANS_SINE)
	
	# 在动画过程中持续重绘，缩短动画时间减少停顿感
	movement_tween.tween_method(_on_hero_position_update, hero_position, target_position, 0.3)
	movement_tween.tween_callback(_on_movement_completed)

func _on_hero_position_update(position: Vector2):
	"""英雄位置更新回调（动画过程中）"""
	hero_position = position
	# 更新Character_sword节点的位置
	if hero_node:
		hero_node.position = position
		# 播放walk动画
		var animated_sprite = hero_node.get_node("AnimatedSprite2D")
		if animated_sprite:
			if not animated_sprite.is_playing() or animated_sprite.animation != "walk":
				animated_sprite.play("walk")
	queue_redraw()

func _on_movement_completed():
	"""移动完成回调"""
	# 更新步数计数器
	step_count += 1
	steps_in_current_day += 1
	step_count_updated.emit(step_count)
	
	# 检查是否需要进入新的一天
	if steps_in_current_day >= STEPS_PER_DAY:
		current_day += 1
		steps_in_current_day = 0
		day_changed.emit(current_day)
		# 新的一天开始时生成怪物
		_spawn_monsters_for_new_day()
	
	# 检查是否完成一圈
	if current_tile_index == 0:
		print("[LoopManager] Loop completed, emitting loop_completed signal")
		loop_completed.emit()
	
	# 发射hero_moved信号，确保只有在移动完成后才处理瓦片事件
	hero_moved.emit(loop_path[current_tile_index])
	
	# 保存当前移动状态，因为tile_reached信号可能会改变is_moving
	var was_moving = is_moving
	print("[LoopManager] Before tile_reached signal, is_moving: ", is_moving)
	tile_reached.emit(loop_path[current_tile_index])
	print("[LoopManager] After tile_reached signal, is_moving: ", is_moving)
	
	# 只有在信号处理后仍然在移动状态才继续移动
	# 这确保了如果在tile_reached信号处理中触发了战斗，移动会正确停止
	if is_moving:
		print("[LoopManager] Continuing movement to next tile")
		# 立即移动到下一个瓦片，不添加延迟
		_move_to_next_tile()
	else:
		print("[LoopManager] Movement stopped, is_moving is false")

func _on_tile_reached(tile_position: Vector2):
	"""到达瓦片时的处理"""
	print("Hero reached tile ", current_tile_index, " at position ", tile_position)
	
	# 如果刚刚结束战斗，跳过所有检查（包括卡牌效果和随机战斗）
	var skip_battle_checks = false
	if just_finished_battle:
		just_finished_battle = false
		skip_battle_checks = true
		print("[LoopManager] Skipping battle checks - just finished battle")
		# 确保在跳过战斗检查时保持移动状态
		is_moving = true
		return
	
	var has_battle = false
	
	# 只有在不跳过战斗检查时才处理怪物、卡牌和随机战斗
	if not skip_battle_checks:
		# 优先检查该位置是否有怪物
		if current_tile_index in spawned_monsters:
			var monster_data = spawned_monsters[current_tile_index]
			print("Found monster at tile ", current_tile_index, ": ", monster_data.type)
			_trigger_monster_battle(monster_data)
			has_battle = true
		# 如果没有怪物，检查该位置是否有卡牌
		elif current_tile_index in placed_cards:
			var card_data = placed_cards[current_tile_index]
			print("Found card at tile ", current_tile_index, ": ", card_data.name)
			# 检查是否是敌人卡牌，如果是则标记为已触发战斗
			if card_data.get("type") == "enemy":
				has_battle = true
			_handle_card_effect(card_data)
		
		# 只有在没有任何战斗的情况下才检查随机战斗
		if not has_battle:
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

func _trigger_monster_battle(monster_data: Dictionary):
	"""触发怪物战斗"""
	print("Monster battle triggered with ", monster_data.type)
	# 创建战斗数据，格式与卡牌战斗兼容
	var battle_data = {
		"name": monster_data.type,
		"type": "enemy",
		"hp": monster_data.health,  # 使用hp字段以兼容BattleManager
		"attack": monster_data.attack,
		"defense": monster_data.get("defense", 0),
		"is_monster": true,
		"tile_index": current_tile_index
	}
	battle_started.emit(battle_data)
	
	# 暂停移动直到战斗结束
	is_moving = false

func _trigger_battle(enemy_card: Dictionary):
	"""触发战斗"""
	print("Battle triggered with ", enemy_card.name)
	battle_started.emit(enemy_card)
	
	# 暂停移动直到战斗结束
	# 注意：不直接调用stop_hero_movement()，而是只设置is_moving为false
	# 这样可以避免在_on_movement_completed中的状态检查问题
	is_moving = false
	# 停止walk动画
	if hero_node:
		var animated_sprite = hero_node.get_node("AnimatedSprite2D")
		if animated_sprite:
			animated_sprite.stop()

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
	# 注意：just_finished_battle 的处理已经在 _on_tile_reached 中完成
	# 这里不需要再次检查 just_finished_battle
	
	# 修复：只有在没有怪物和卡牌的空地才可能触发随机战斗
	# 但是为了游戏平衡，暂时禁用随机战斗功能
	# 只有放置的敌人卡牌和生成的怪物才会触发战斗
	pass  # 不再触发随机战斗

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

func get_step_count() -> int:
	"""获取当前步数"""
	return step_count

func on_battle_ended(victory: bool, rewards: Dictionary = {}):
	"""战斗结束处理"""
	if victory:
		print("Battle won! Waiting for battle window to close before continuing movement...")
		if current_tile_index in spawned_monsters:
			print("Removing defeated monster at tile ", current_tile_index)
			_remove_monster_at_tile(current_tile_index)
		
		just_finished_battle = true
		# 不立即恢复移动，等待战斗窗口关闭信号
		# is_moving = true
		# _move_to_next_tile()
	else:
		print("Battle lost! Hero died...")
		# 战斗失败，英雄死亡
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager and game_manager.has_method("hero_death"):
			game_manager.hero_death()

func on_battle_window_closed():
	"""战斗窗口关闭后的处理"""
	print("Battle window closed, resuming movement...")
	if just_finished_battle:
		is_moving = true
		_move_to_next_tile()

func set_path_type(path_type: PathType):
	"""设置路径类型并重新生成路径"""
	current_path_type = path_type
	_generate_loop_path()
	# 重置英雄位置
	if loop_path.size() > 0:
		hero_position = loop_path[0]
		current_tile_index = 0
		queue_redraw()
	
func get_path_type() -> PathType:
	"""获取当前路径类型"""
	return current_path_type

func reset_loop():
	"""重置循环状态"""
	current_tile_index = 0
	if loop_path.size() > 0:
		hero_position = loop_path[0]
	is_moving = false
	placed_cards.clear()
	step_count = 0  # 重置步数计数器
	current_day = 1  # 重置天数
	steps_in_current_day = 0  # 重置当天步数
	_clear_all_monsters()  # 清除所有怪物
	print("Loop reset to starting position")

# 怪物系统相关函数
func _spawn_initial_monsters():
	"""游戏开始时生成初始怪物"""
	# 清除之前的怪物
	_clear_all_monsters()
	
	# 随机在路径上生成怪物（避开起始位置）
	var monster_count = randi() % 3 + 2  # 2-4个怪物
	var available_tiles = []
	
	# 收集可用的瓦片位置（排除起始位置）
	for i in range(1, loop_path.size()):
		available_tiles.append(i)
	
	# 随机选择位置生成怪物
	for i in range(min(monster_count, available_tiles.size())):
		var random_index = randi() % available_tiles.size()
		var tile_index = available_tiles[random_index]
		available_tiles.remove_at(random_index)
		
		# 创建怪物数据（初始怪物较弱）
		var monster_types = ["Goblin", "Skeleton", "Spider"]
		var monster_type = monster_types[randi() % monster_types.size()]
		var monster_data = {
			"type": monster_type,
			"health": 20,  # 初始怪物血量较低
			"attack": 5,   # 初始怪物攻击力较低
			"defense": 1,  # 初始怪物防御力较低
			"day_spawned": current_day
		}
		
		spawned_monsters[tile_index] = monster_data
		_create_monster_sprite(tile_index, monster_type)
	
	var monster_positions = []
	for tile_index in spawned_monsters.keys():
		monster_positions.append(loop_path[tile_index])
	
	monsters_spawned.emit(monster_positions)
	print("[LoopManager] Spawned ", spawned_monsters.size(), " initial monsters")

func _spawn_monsters_for_new_day():
	"""为新的一天生成怪物"""
	# 修复：不清除之前的怪物，只在空的瓦片上添加新怪物
	# 这样之前天数的怪物会保留下来
	
	# 随机在路径上生成怪物（避开起始位置和已有怪物的位置）
	var monster_count = randi() % 2 + 1  # 1-2个新怪物
	var available_tiles = []
	
	# 收集可用的瓦片位置（排除起始位置和已有怪物的位置）
	for i in range(1, loop_path.size()):
		if not (i in spawned_monsters):  # 只选择没有怪物的瓦片
			available_tiles.append(i)
	
	# 如果没有可用位置，就不生成新怪物
	if available_tiles.size() == 0:
		print("[LoopManager] No available tiles for new monsters on day ", current_day)
		return
	
	# 随机选择位置生成怪物
	var new_monsters_count = 0
	for i in range(min(monster_count, available_tiles.size())):
		var random_index = randi() % available_tiles.size()
		var tile_index = available_tiles[random_index]
		available_tiles.remove_at(random_index)
		
		# 创建怪物数据
		var monster_types = ["Goblin", "Skeleton", "Orc"]
		var monster_type = monster_types[randi() % monster_types.size()]
		var monster_data = {
			"type": monster_type,
			"health": 30 + current_day * 5,  # 随天数增加血量
			"attack": 8 + current_day * 2,   # 随天数增加攻击力
			"day_spawned": current_day
		}
		
		spawned_monsters[tile_index] = monster_data
		_create_monster_sprite(tile_index, monster_type)
		new_monsters_count += 1
	
	var monster_positions = []
	for tile_index in spawned_monsters.keys():
		monster_positions.append(loop_path[tile_index])
	
	monsters_spawned.emit(monster_positions)
	print("[LoopManager] Spawned ", new_monsters_count, " new monsters for day ", current_day, ". Total monsters: ", spawned_monsters.size())

func _create_monster_sprite(tile_index: int, monster_type: String):
	"""创建怪物精灵"""
	var sprite = Sprite2D.new()
	var texture_path = "res://assets/enemies/" + monster_type.to_lower() + ".png"
	
	# 尝试加载怪物贴图，如果不存在则使用默认贴图
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		print("[Monster] Loaded texture for ", monster_type, " from ", texture_path)
	else:
		# 创建一个简单的彩色方块作为占位符
		var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
		var color = Color.RED if monster_type == "Goblin" else (Color.BLUE if monster_type == "Skeleton" else (Color.GREEN if monster_type == "Orc" else Color.YELLOW))
		image.fill(color)
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture
		print("[Monster] Created placeholder texture for ", monster_type, " with color ", color)
	
	# 修正位置计算：由于LoopManager的position是(640, 360)，而loop_path中的坐标已经包含了这个偏移
	# 所以怪物精灵的本地坐标应该是loop_path坐标减去LoopManager的position
	var world_position = loop_path[tile_index]
	var local_position = world_position - position
	sprite.position = local_position
	sprite.scale = Vector2(0.8, 0.8)  # 稍微大一点以便看清
	sprite.z_index = 10  # 确保怪物显示在地图上方
	
	# 添加一个标签显示怪物类型
	var label = Label.new()
	label.text = monster_type
	label.position = Vector2(-16, -40)  # 在怪物上方显示
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	sprite.add_child(label)
	
	add_child(sprite)
	monster_sprites[tile_index] = sprite
	print("[Monster] Created sprite for ", monster_type, " at tile ", tile_index, " world position ", world_position, " local position ", local_position)

func _clear_all_monsters():
	"""清除所有怪物"""
	# 移除怪物精灵
	for sprite in monster_sprites.values():
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
	
	spawned_monsters.clear()
	monster_sprites.clear()

func _remove_monster_at_tile(tile_index: int):
	"""移除指定位置的怪物"""
	if tile_index in spawned_monsters:
		spawned_monsters.erase(tile_index)
		
	if tile_index in monster_sprites:
		var sprite = monster_sprites[tile_index]
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
		monster_sprites.erase(tile_index)

func get_monster_at_tile(tile_index: int) -> Dictionary:
	"""获取指定位置的怪物数据"""
	if tile_index in spawned_monsters:
		return spawned_monsters[tile_index]
	return {}

func _draw():
	"""绘制循环路径（调试用）"""
	if loop_path.size() > 0 and tile_map_layer:
		# 直接使用TileMapLayer的坐标系统绘制路径
		# 这样确保绘制的路径与TileMapLayer中的瓦片完全对齐
		
		# 绘制路径（最底层）
		for i in range(loop_path.size()):
			# 直接使用loop_path中已经变换过的坐标
			var current_pos = loop_path[i]
			var next_pos = loop_path[(i + 1) % loop_path.size()]
			
			draw_line(current_pos, next_pos, Color.WHITE, 3.0)
		
		# 英雄现在使用Character_sword节点显示，不需要在这里绘制瓦片位置和英雄
