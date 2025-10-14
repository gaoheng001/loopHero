# LoopManager.gd
# 循环管理器 - 负责英雄移动、基于TileMapLayer的循环路径管理、战斗触发等
# 从TileMapLayer中检测路径瓦片生成自定义路径
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

# 路径配置
const TILE_SIZE = 64
const LOOP_RADIUS = 200
const MOVE_SPEED = 100.0

# 网格地图配置
const GRID_SIZE = 40  # 40x40的网格，确保覆盖整个游戏区域
const GRID_TILE_SIZE = 16  # 每个网格瓦片的基础大小，与TileSet的texture_region_size一致

# 时间系统配置
const STEPS_PER_DAY = 20

# 路径类型：仅支持自定义瓦片路径
# 从TileMapLayer中检测路径瓦片生成路径

# 循环状态
var current_tile_index: int = 0
var is_moving: bool = false
var movement_tween: Tween  # 移动动画的 tween 实例
var hero_position: Vector2
var loop_path: Array[Vector2] = []
var placed_cards: Dictionary = {}  # tile_index -> card_data
var placed_terrain_cards: Dictionary = {}  # tile_index -> terrain_card_data
var just_finished_battle: bool = false  # 刚刚结束战斗的标记
var selection_active: bool = false  # 卡牌选择或交互暂停标记
var step_count: int = 0  # 步数计数器

# 调试：是否绘制路径线（已有路径瓦片可视，不再需要）
var show_path_debug_lines: bool = false

# 网格地图状态
var grid_terrain_cards: Dictionary = {}  # Vector2i(grid_x, grid_y) -> terrain_card_data
var grid_terrain_sprites: Dictionary = {}  # Vector2i(grid_x, grid_y) -> ColorRect节点
var grid_visual_node: Node2D  # 网格可视化节点
var placeable_highlights = []  # 可放置区域高亮精灵列表

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
	
	# 创建网格可视化
	_create_grid_visualization()
	
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
	_generate_custom_path_from_tilemap()
	print("Generated loop path with ", loop_path.size(), " positions")




func _generate_custom_path_from_tilemap():
	"""从TileMapLayer读取自定义路径点"""
	if not tile_map_layer:
		print("Error: TileMapLayer not found! Cannot generate path.")
		return

	# 通过 get_used_cells 精确遍历所有已使用瓦片，避免错过真实路径范围
	var path_points: Array[Vector2] = []
	var used_cells: PackedVector2Array = tile_map_layer.get_used_cells()

	for i in range(used_cells.size()):
		var tile_pos: Vector2i = used_cells[i]
		var atlas_coords = tile_map_layer.get_cell_atlas_coords(tile_pos)
		# 使用 atlas 坐标识别路径瓦片（约定为 25,5）
		if atlas_coords == Vector2i(25, 5):
			# 将瓦片坐标转换为TileMapLayer的本地坐标并再转换为全局坐标
			var tile_local_pos = tile_map_layer.map_to_local(tile_pos)
			var global_pos = tile_map_layer.to_global(tile_local_pos)
			path_points.append(global_pos)
	
	print("Found ", path_points.size(), " path tiles in TileMapLayer")
	
	# 如果找到路径点，按距离排序形成连续路径
	if path_points.size() > 0:
		_sort_path_points(path_points)
		loop_path = path_points
		print("Using custom path with ", loop_path.size(), " points")
	else:
		print("Error: No custom path found in TileMapLayer! Please add path tiles.")

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
	
	# 保持TileMapLayer中已有的瓦片数据
	print("Using existing TileMapLayer data for custom path")
	return

func start_hero_movement():
	"""开始英雄移动"""
	if selection_active:
		print("[LoopManager] Selection active, not starting movement")
		return
	if not is_moving:
		is_moving = true
		# 只在英雄位置未初始化时才设置到起始位置
		if hero_node and loop_path.size() > 0:
			# 如果hero_position还没有初始化（Vector2.ZERO），则设置到起始位置
			if hero_position == Vector2.ZERO:
				hero_node.position = loop_path[0]
				hero_position = loop_path[0]
			else:
				# 保持当前位置，确保hero_node与hero_position同步
				hero_node.position = hero_position
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
	
	# 创建移动补间动画
	var distance = hero_position.distance_to(target_position)
	var duration = max(distance / MOVE_SPEED, 0.05)
	movement_tween = create_tween()
	movement_tween.set_ease(Tween.EASE_IN_OUT)
	movement_tween.set_trans(Tween.TRANS_SINE)
	
	# 使用属性补间让英雄节点实际移动
	if hero_node:
		# 在开始移动前确保动画播放（带安全回退）
		var animated_sprite = hero_node.get_node("AnimatedSprite2D")
		if animated_sprite:
			var frames = animated_sprite.sprite_frames
			if frames:
				var names = frames.get_animation_names()
				var target_anim = "walk"
				if not names.has("walk") and names.size() > 0:
					target_anim = names[0]
				if animated_sprite.animation != target_anim or not animated_sprite.is_playing():
					animated_sprite.play(target_anim)

		movement_tween.tween_property(hero_node, "position", target_position, duration)
	else:
		movement_tween.tween_method(_on_hero_position_update, hero_position, target_position, duration)
	movement_tween.tween_callback(_on_movement_completed)

func _on_hero_position_update(position: Vector2):
	"""英雄位置更新回调（动画过程中）"""
	hero_position = position
	# 更新Character_sword节点的位置
	if hero_node:
		hero_node.position = position
		# 播放动画（带安全回退）
		var animated_sprite = hero_node.get_node("AnimatedSprite2D")
		if animated_sprite:
			var frames = animated_sprite.sprite_frames
			if frames:
				var names = frames.get_animation_names()
				var target_anim = "walk"
				if not names.has("walk") and names.size() > 0:
					target_anim = names[0]
				if animated_sprite.animation != target_anim or not animated_sprite.is_playing():
					animated_sprite.play(target_anim)
	queue_redraw()


func _on_movement_completed():
	"""移动完成回调"""
	# 同步内部位置到节点
	if hero_node:
		hero_position = hero_node.position
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

	# 若选择窗口处于活动状态，确保暂停移动
	if selection_active:
		is_moving = false
		print("[LoopManager] Selection active after movement complete, pausing movement")
	
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

	# 选择窗口活动时，不进行任何战斗或卡牌检查，并保持暂停
	if selection_active:
		is_moving = false
		print("[LoopManager] Selection active on tile reach, skipping checks and pausing movement")
		return
	
	# 如果刚刚结束战斗，跳过所有检查（包括卡牌效果和随机战斗）
	var skip_battle_checks = false
	if just_finished_battle:
		just_finished_battle = false
		skip_battle_checks = true
		print("[LoopManager] Skipping battle checks - just finished battle")
		# 确保在跳过战斗检查时保持移动状态
		if not selection_active:
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
		{"name": "Yaokou", "hp": 20, "attack": 5, "defense": 2},
		{"name": "Kugu", "hp": 15, "attack": 7, "defense": 1},
		{"name": "Zhumu", "hp": 12, "attack": 6, "defense": 0}
	]
	
	return enemies[randi() % enemies.size()]

func place_card_at_tile(tile_index: int, card_data: Dictionary):
	"""在指定瓦片放置卡牌"""
	if tile_index >= 0 and tile_index < loop_path.size():
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

func get_time_info() -> Dictionary:
	"""获取时间系统信息: 当前天、当天步数、每日步数上限"""
	return {
		"current_day": current_day,
		"steps_in_current_day": steps_in_current_day,
		"steps_per_day": STEPS_PER_DAY
	}

func get_path_length() -> int:
	"""获取路径长度"""
	return loop_path.size()

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
		if not selection_active:
			is_moving = true
			_move_to_next_tile()

# 路径类型相关函数已移除，现在只支持自定义瓦片路径

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
		var monster_types = ["Yaokou", "Kugu", "Zhumu"]
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
		var monster_types = ["Yaokou", "Kugu", "Manku"]
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
		var color = Color.RED if monster_type == "Yaokou" else (Color.BLUE if monster_type == "Kugu" else (Color.GREEN if monster_type == "Manku" else Color.YELLOW))
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
	if not show_path_debug_lines:
		# 默认不再绘制路径线，避免与路径瓦片显示不一致
		return
	if loop_path.size() > 0 and tile_map_layer:
		# 直接使用TileMapLayer的坐标系统绘制路径
		# 这样确保绘制的路径与TileMapLayer中的瓦片完全对齐

		# 绘制路径（最底层）
		for i in range(loop_path.size()):
			# 直接使用loop_path中已经变换过的坐标
			var current_pos = loop_path[i]
			var next_pos = loop_path[(i + 1) % loop_path.size()]

			draw_line(current_pos, next_pos, Color.WHITE, 3.0)

# 地形卡牌管理函数
func can_place_terrain_at_tile(tile_index: int) -> bool:
	"""检查是否可以在指定瓦片放置地形卡牌（旧版本，保持兼容性）"""
	# 检查索引是否有效
	if tile_index < 0 or tile_index >= loop_path.size():
		return false
	
	# 检查是否已有地形卡牌
	if tile_index in placed_terrain_cards:
		return false
	
	# 检查是否已有其他卡牌
	if tile_index in placed_cards:
		return false
	
	return true

func can_place_terrain_at_grid_position(grid_pos: Vector2i) -> bool:
	"""检查是否可以在指定TileMapLayer瓦片位置放置地形卡牌"""
	if not tile_map_layer:
		return false
	
	# 检查是否是路径瓦片（不能在路径上放置地形）
	var atlas_coords = tile_map_layer.get_cell_atlas_coords(grid_pos)
	if atlas_coords == Vector2i(25, 5):  # 路径瓦片
		return false
	
	# 检查是否已有地形卡牌
	if grid_pos in grid_terrain_cards:
		return false
	
	# 检查是否在白色空地瓦片区域内（只有白色空地瓦片的位置才能放置地形）
	if atlas_coords != Vector2i(5, 2):  # 不是白色空地瓦片
		return false
	
	return true

func world_position_to_grid_position(world_pos: Vector2) -> Vector2i:
	"""将世界坐标转换为TileMapLayer瓦片坐标"""
	if not tile_map_layer:
		print("[LoopManager] 错误：tile_map_layer为空")
		return Vector2i(0, 0)
	
	# 将世界坐标转换为相对于TileMapLayer的本地坐标
	var local_pos = world_pos - position - tile_map_layer.position
	
	# 使用TileMapLayer的local_to_map方法进行坐标转换
	var tile_pos = tile_map_layer.local_to_map(local_pos / tile_map_layer.scale)
	
	return tile_pos

func grid_position_to_world_position(grid_pos: Vector2i) -> Vector2:
	"""将TileMapLayer瓦片坐标转换为世界坐标"""
	if not tile_map_layer:
		print("[LoopManager] 错误：tile_map_layer为空")
		return Vector2.ZERO
	
	# 使用TileMapLayer的map_to_local方法进行坐标转换
	var local_pos = tile_map_layer.map_to_local(grid_pos)
	
	# 应用TileMapLayer的变换（缩放和位置）
	var transformed_pos = local_pos * tile_map_layer.scale + tile_map_layer.position
	
	# 转换为世界坐标
	var world_pos = transformed_pos + position
	
	return world_pos

func place_terrain_card(tile_index: int, card_data: Dictionary):
	"""在指定瓦片放置地形卡牌（旧版本，保持兼容性）"""
	if can_place_terrain_at_tile(tile_index):
		placed_terrain_cards[tile_index] = card_data
		print("[LoopManager] 在瓦片", tile_index, "放置地形卡牌：", card_data.name)
		
		# 创建地形卡牌的视觉表示
		_create_terrain_visual(tile_index, card_data)
		return true
	return false

func place_terrain_card_at_grid_position(grid_pos: Vector2i, card_data: Dictionary) -> bool:
	"""在指定网格位置放置地形卡牌"""
	if can_place_terrain_at_grid_position(grid_pos):
		grid_terrain_cards[grid_pos] = card_data
		print("[LoopManager] 在网格位置", grid_pos, "放置地形卡牌：", card_data.name)
		
		# 创建地形卡牌的视觉表示
		_create_terrain_visual_at_grid(grid_pos, card_data)
		return true
	return false

func find_closest_grid_position(world_pos: Vector2) -> Vector2i:
	"""找到最接近世界坐标的网格位置"""
	return world_position_to_grid_position(world_pos)

func _create_terrain_visual(tile_index: int, card_data: Dictionary):
	"""创建地形卡牌的视觉表示（旧版本）"""
	var tile_pos = get_tile_position(tile_index)
	
	# 创建一个简单的彩色圆圈表示地形
	var terrain_sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# 根据地形类型设置颜色
	var color: Color
	match card_data.id:
		"bamboo_forest":
			color = Color.GREEN
		"mountain_peak":
			color = Color.GRAY
		"river":
			color = Color.BLUE
		"rock":
			color = Color.DARK_GRAY
		"forest":
			color = Color.FOREST_GREEN
		"meadow":
			color = Color.YELLOW_GREEN
		"old_meadow":
			color = Color.OLIVE
		_:
			color = Color.WHITE
	
	# 填充圆形
	for x in range(32):
		for y in range(32):
			var distance = Vector2(x - 16, y - 16).length()
			if distance <= 12:
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	texture.set_image(image)
	terrain_sprite.texture = texture
	terrain_sprite.position = tile_pos
	terrain_sprite.z_index = 1
	
	add_child(terrain_sprite)
	
	# 存储精灵引用（如果需要后续移除）
	if not has_meta("terrain_sprites"):
		set_meta("terrain_sprites", {})
	get_meta("terrain_sprites")[tile_index] = terrain_sprite

func _create_terrain_visual_at_grid(grid_pos: Vector2i, card_data: Dictionary):
	"""创建地形卡牌的视觉表示（基于TileMapLayer网格）"""
	print("[LoopManager] 开始创建地形视觉 - 网格位置:", grid_pos, "卡牌:", card_data.name)
	
	# 检查TileMapLayer是否存在
	if not tile_map_layer:
		print("[LoopManager] 错误: TileMapLayer为空!")
		return
	
	# 转换网格位置到世界坐标
	var world_pos = grid_position_to_world_position(grid_pos)
	print("[LoopManager] 世界坐标:", world_pos)
	
	# 获取实际的瓦片大小
	var size = _get_actual_tile_size()
	print("[LoopManager] 瓦片大小:", size)
	
	# 创建一个ColorRect作为地形卡牌的视觉表示（更可靠）
	var terrain_rect = ColorRect.new()
	terrain_rect.name = "TerrainCard_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	
	# 根据卡牌ID设置颜色
	var color: Color
	match card_data.id:
		"bamboo_forest":
			color = Color.GREEN
		"mountain_peak":
			color = Color.GRAY
		"river":
			color = Color.BLUE
		"rock":
			color = Color.DARK_GRAY
		"forest":
			color = Color.FOREST_GREEN
		"meadow":
			color = Color.YELLOW_GREEN
		"old_meadow":
			color = Color.OLIVE
		_:
			color = Color.WHITE
	
	# 设置ColorRect属性 - 使用相对于LoopManager的本地坐标
	terrain_rect.color = color
	terrain_rect.size = Vector2(size, size)
	# 将世界坐标转换为相对于LoopManager的本地坐标
	var local_pos = world_pos - position
	terrain_rect.position = local_pos - Vector2(size/2, size/2)  # 居中显示
	terrain_rect.z_index = 5  # 在瓦片之上，但在高亮之下
	
	# 检查相机位置
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("[LoopManager] 警告: 未找到相机")
	
	# 添加到场景
	add_child(terrain_rect)
	
	# 创建文字标签
	var terrain_label = Label.new()
	terrain_label.name = "TerrainLabel_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	terrain_label.text = card_data.name.substr(0, 1)  # 获取名字的第一个字
	terrain_label.add_theme_font_size_override("font_size", 24)
	terrain_label.add_theme_color_override("font_color", Color.WHITE)
	terrain_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	terrain_label.add_theme_constant_override("shadow_offset_x", 2)
	terrain_label.add_theme_constant_override("shadow_offset_y", 2)
	terrain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	terrain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	terrain_label.z_index = 6  # 确保文字在ColorRect之上
	
	# 设置标签大小与瓦片大小一致
	terrain_label.size = Vector2(size, size)
	terrain_label.position = Vector2(0, 0)  # 相对于父节点的位置
	
	# 将标签作为ColorRect的子节点
	terrain_rect.add_child(terrain_label)
	print("[LoopManager] 标签已添加到ColorRect")
	
	# 存储引用
	grid_terrain_sprites[grid_pos] = terrain_rect
	
	print("[LoopManager] 地形卡牌视觉创建完成 - 网格位置:", grid_pos)
	print("[LoopManager] 最终ColorRect全局位置:", terrain_rect.global_position, "可见性:", terrain_rect.visible)
	
	# 强制更新显示
	terrain_rect.queue_redraw()
	print("[LoopManager] 已请求重绘ColorRect")

func get_terrain_at_tile(tile_index: int) -> Dictionary:
	"""获取指定瓦片的地形卡牌数据"""
	if tile_index in placed_terrain_cards:
		return placed_terrain_cards[tile_index]
	return {}

func remove_terrain_at_tile(tile_index: int):
	"""移除指定瓦片的地形卡牌"""
	if tile_index in placed_terrain_cards:
		placed_terrain_cards.erase(tile_index)
		
		# 移除视觉表示
		if has_meta("terrain_sprites"):
			var terrain_sprites = get_meta("terrain_sprites")
			if tile_index in terrain_sprites:
				terrain_sprites[tile_index].queue_free()
				terrain_sprites.erase(tile_index)
	
	print("[LoopManager] 移除瓦片", tile_index, "的地形卡牌")



func get_terrain_at_grid_position(grid_pos: Vector2i) -> Dictionary:
	"""获取指定网格位置的地形卡牌数据"""
	if grid_pos in grid_terrain_cards:
		return grid_terrain_cards[grid_pos]
	return {}

func remove_terrain_at_grid_position(grid_pos: Vector2i):
	"""移除指定TileMapLayer瓦片位置的地形卡牌"""
	if grid_pos in grid_terrain_cards:
		var removed_card = grid_terrain_cards[grid_pos]
		grid_terrain_cards.erase(grid_pos)
		
		# 在TileMapLayer上恢复为白色空地瓦片
		if tile_map_layer:
			tile_map_layer.set_cell(grid_pos, 0, Vector2i(5, 2))  # 恢复为白色空地
		
		# 移除对应的精灵
		if grid_pos in grid_terrain_sprites:
			grid_terrain_sprites[grid_pos].queue_free()
			grid_terrain_sprites.erase(grid_pos)
		
		print("[LoopManager] 移除TileMapLayer位置", grid_pos, "的地形卡牌：", removed_card.name)
	else:
		print("[LoopManager] TileMapLayer位置", grid_pos, "没有地形卡牌可移除")

func _get_actual_tile_size() -> float:
	"""获取TileMapLayer的实际瓦片大小"""
	if not tile_map_layer:
		return GRID_TILE_SIZE  # 如果没有TileMapLayer，使用默认大小
	
	# 获取TileMapLayer的瓦片大小和缩放
	var tile_set = tile_map_layer.tile_set
	if not tile_set:
		return GRID_TILE_SIZE  # 如果没有TileSet，使用默认大小
	
	# 获取瓦片的基础大小 - 从TileSetAtlasSource获取
	var base_tile_size = 32.0  # 默认大小
	
	# 尝试从TileSet的源获取实际的瓦片大小
	var source = tile_set.get_source(0)
	if source and source is TileSetAtlasSource:
		var atlas_source = source as TileSetAtlasSource
		base_tile_size = atlas_source.texture_region_size.x  # 使用texture_region_size
	
	# 应用TileMapLayer的缩放
	var actual_size = base_tile_size * tile_map_layer.scale.x
	
	return actual_size

func _create_grid_visualization():
	"""基于TileMapLayer创建网格可视化"""
	if not tile_map_layer:
		print("[LoopManager] 警告: TileMapLayer未找到，无法创建网格")
		return
	
	# 清除现有的网格瓦片（保留路径瓦片）
	_clear_grid_tiles()
	
	# 在TileMapLayer上创建白色空瓦片网格
	_create_tilemap_grid()
	
	print("[LoopManager] 基于TileMapLayer的网格可视化创建完成")

func _clear_grid_tiles():
	"""清除网格区域的瓦片（保留路径瓦片）"""
	if not tile_map_layer:
		return
	
	# 首先找到循环路径在TileMapLayer中的瓦片坐标范围
	var path_tile_positions: Array[Vector2i] = []
	var search_radius = 50  # 扩大搜索半径
	
	# 扫描TileMapLayer寻找路径瓦片，确定路径范围
	for x in range(-search_radius, search_radius + 1):
		for y in range(-search_radius, search_radius + 1):
			var tile_pos = Vector2i(x, y)
			var atlas_coords = tile_map_layer.get_cell_atlas_coords(tile_pos)
			
			# 检查是否是路径瓦片
			if atlas_coords == Vector2i(25, 5):
				path_tile_positions.append(tile_pos)
	
	if path_tile_positions.size() == 0:
		print("[LoopManager] 警告: 未找到路径瓦片，使用默认范围清除")
		# 如果没有找到路径瓦片，使用默认范围
		var grid_half_size = GRID_SIZE / 2
		
		for x in range(-grid_half_size, grid_half_size):
			for y in range(-grid_half_size, grid_half_size):
				var tile_pos = Vector2i(x, y)
				var atlas_coords = tile_map_layer.get_cell_atlas_coords(tile_pos)
				
				# 如果不是路径瓦片，则清除
				if atlas_coords != Vector2i(25, 5):
					tile_map_layer.set_cell(tile_pos, -1)  # 清除瓦片
		return
	
	# 计算路径瓦片的边界
	var min_x = path_tile_positions[0].x
	var max_x = path_tile_positions[0].x
	var min_y = path_tile_positions[0].y
	var max_y = path_tile_positions[0].y
	
	for pos in path_tile_positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
	
	# 扩展边界，为地形卡牌放置留出空间
	var padding = 8  # 在路径周围留出8个瓦片的空间
	min_x -= padding
	max_x += padding
	min_y -= padding
	max_y += padding
	
	# 在路径周围的区域清除非路径瓦片
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var tile_pos = Vector2i(x, y)
			var atlas_coords = tile_map_layer.get_cell_atlas_coords(tile_pos)
			
			# 如果不是路径瓦片，则清除
			if atlas_coords != Vector2i(25, 5):
				tile_map_layer.set_cell(tile_pos, -1)  # 清除瓦片

func _create_tilemap_grid():
	"""在TileMapLayer上创建白色空瓦片网格"""
	if not tile_map_layer:
		return
	
	# 首先找到循环路径在TileMapLayer中的瓦片坐标范围
	var path_tile_positions: Array[Vector2i] = []
	var search_radius = 100  # 扩大搜索半径到100，确保覆盖整个地图
	
	# 扫描TileMapLayer寻找路径瓦片，确定路径范围
	print("[LoopManager] 开始扫描路径瓦片，搜索范围: ", -search_radius, " 到 ", search_radius)
	for x in range(-search_radius, search_radius + 1):
		for y in range(-search_radius, search_radius + 1):
			var tile_pos = Vector2i(x, y)
			var atlas_coords = tile_map_layer.get_cell_atlas_coords(tile_pos)
			
			# 检查是否是路径瓦片
			if atlas_coords == Vector2i(25, 5):
				path_tile_positions.append(tile_pos)
				print("[LoopManager] 找到路径瓦片: ", tile_pos)
	
	print("[LoopManager] 总共找到 ", path_tile_positions.size(), " 个路径瓦片")
	
	if path_tile_positions.size() == 0:
		print("[LoopManager] 警告: 未找到路径瓦片，使用默认范围")
		# 如果没有找到路径瓦片，使用默认范围
		var grid_half_size = GRID_SIZE / 2
		var empty_tile_count = 0
		
		for x in range(-grid_half_size, grid_half_size):
			for y in range(-grid_half_size, grid_half_size):
				var tile_pos = Vector2i(x, y)
				var atlas_coords = tile_map_layer.get_cell_atlas_coords(tile_pos)
				
				if atlas_coords == Vector2i(-1, -1) or tile_map_layer.get_cell_source_id(tile_pos) == -1:
					tile_map_layer.set_cell(tile_pos, 0, Vector2i(5, 2))
					empty_tile_count += 1
		
		print("[LoopManager] 创建了", empty_tile_count, "个白色空地瓦片（默认范围）")
		return
	
	# 计算路径瓦片的边界
	var min_x = path_tile_positions[0].x
	var max_x = path_tile_positions[0].x
	var min_y = path_tile_positions[0].y
	var max_y = path_tile_positions[0].y
	
	for pos in path_tile_positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
	
	print("[LoopManager] 路径瓦片边界: (", min_x, ",", min_y, ") 到 (", max_x, ",", max_y, ")")
	
	# 考虑到TileMapLayer的变换，计算在屏幕可见范围内的瓦片坐标
	# TileMapLayer position: (-1212, -881), scale: (2.4, 2.4)
	# 屏幕尺寸: 1280x720, 摄像机zoom: 0.8
	var camera_zoom = 0.8
	var screen_width = 1280.0 / camera_zoom  # 1600
	var screen_height = 720.0 / camera_zoom  # 900
	var tile_size = 64.0 * 2.4  # 瓦片实际显示大小
	
	# 计算屏幕可见范围对应的瓦片坐标范围
	var tilemap_pos = Vector2(-1212, -881)
	var visible_min_x = int((-tilemap_pos.x) / tile_size) - 5
	var visible_max_x = int((-tilemap_pos.x + screen_width) / tile_size) + 5
	var visible_min_y = int((-tilemap_pos.y) / tile_size) - 5
	var visible_max_y = int((-tilemap_pos.y + screen_height) / tile_size) + 5
	
	print("[LoopManager] 屏幕可见瓦片范围: (", visible_min_x, ",", visible_min_y, ") 到 (", visible_max_x, ",", visible_max_y, ")")
	
	# 由于路径可能超出屏幕可见范围，我们在整个可见范围内生成白色瓦片
	# 同时确保路径周围也有白色瓦片
	var padding = 8
	var extended_min_x = min_x - padding
	var extended_max_x = max_x + padding
	var extended_min_y = min_y - padding
	var extended_max_y = max_y + padding
	
	# 合并路径扩展范围和可见范围
	min_x = min(extended_min_x, visible_min_x)
	max_x = max(extended_max_x, visible_max_x)
	min_y = min(extended_min_y, visible_min_y)
	max_y = max(extended_max_y, visible_max_y)
	
	print("[LoopManager] 最终生成范围: (", min_x, ",", min_y, ") 到 (", max_x, ",", max_y, ")")
	
	var empty_tile_count = 0
	
	# 在路径周围的区域创建白色空地瓦片
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var tile_pos = Vector2i(x, y)
			var atlas_coords = tile_map_layer.get_cell_atlas_coords(tile_pos)
			
			# 如果是空瓦片位置，设置为白色空地瓦片
			if atlas_coords == Vector2i(-1, -1) or tile_map_layer.get_cell_source_id(tile_pos) == -1:
				# 使用白色空地瓦片 (使用atlas坐标(5,2)表示白色空地)
				tile_map_layer.set_cell(tile_pos, 0, Vector2i(5, 2))
				empty_tile_count += 1
	
	print("[LoopManager] 围绕路径创建了", empty_tile_count, "个白色空地瓦片")
	print("[LoopManager] 最终范围: (", min_x, ",", min_y, ") 到 (", max_x, ",", max_y, ")")

func show_placeable_highlights():
	"""显示可放置区域的高亮（基于TileMapLayer）"""
	# 清除之前的高亮
	hide_placeable_highlights()
	
	if not tile_map_layer:
		return
	
	# 获取实际的摄像机信息
	var camera = get_viewport().get_camera_2d()
	var camera_zoom = 1.0
	if camera:
		camera_zoom = camera.zoom.x  # 假设x和y缩放相同
	
	# 获取屏幕尺寸
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_width = viewport_size.x / camera_zoom
	var screen_height = viewport_size.y / camera_zoom
	
	# 获取摄像机位置
	var camera_pos = Vector2(640, 360)  # 默认摄像机位置
	if camera:
		camera_pos = camera.global_position
	
	# 计算屏幕可见区域的世界坐标范围
	var screen_left = camera_pos.x - screen_width / 2
	var screen_right = camera_pos.x + screen_width / 2
	var screen_top = camera_pos.y - screen_height / 2
	var screen_bottom = camera_pos.y + screen_height / 2
	
	# 将屏幕边界转换为TileMapLayer的瓦片坐标
	var top_left_grid = world_position_to_grid_position(Vector2(screen_left, screen_top))
	var bottom_right_grid = world_position_to_grid_position(Vector2(screen_right, screen_bottom))
	
	# 添加一些边距以确保覆盖完整
	var margin = 2
	var min_x = top_left_grid.x - margin
	var max_x = bottom_right_grid.x + margin
	var min_y = top_left_grid.y - margin
	var max_y = bottom_right_grid.y + margin
	
	print("[LoopManager] 摄像机位置: ", camera_pos, ", 缩放: ", camera_zoom)
	print("[LoopManager] 屏幕可见范围: (", screen_left, ",", screen_top, ") 到 (", screen_right, ",", screen_bottom, ")")
	print("[LoopManager] 瓦片范围: (", min_x, ",", min_y, ") 到 (", max_x, ",", max_y, ")")
	
	# 遍历计算出的瓦片范围
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var grid_pos = Vector2i(x, y)
			if can_place_terrain_at_grid_position(grid_pos):
				# 创建高亮精灵
				var highlight = Sprite2D.new()
				var texture = ImageTexture.new()
				
				# 获取瓦片大小
				var tile_size = int(_get_actual_tile_size())
				var image = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
				
				# 创建半透明绿色方形
				var highlight_color = Color(0, 1, 0, 0.3)  # 半透明绿色
				for px in range(tile_size):
					for py in range(tile_size):
						image.set_pixel(px, py, highlight_color)
				
				texture.set_image(image)
				highlight.texture = texture
				highlight.position = grid_position_to_world_position(grid_pos) - position
				highlight.z_index = 10  # 显示在最上层
				
				add_child(highlight)
				placeable_highlights.append(highlight)
	
	print("[LoopManager] 显示了", placeable_highlights.size(), "个可放置区域高亮（摄像机可见范围）")

func hide_placeable_highlights():
	"""隐藏可放置区域的高亮"""
	for highlight in placeable_highlights:
		if highlight and is_instance_valid(highlight):
			highlight.queue_free()
	placeable_highlights.clear()
	print("[LoopManager] 隐藏了可放置区域高亮")

		# 英雄现在使用Character_sword节点显示，不需要在这里绘制瓦片位置和英雄

func set_selection_active(active: bool):
	"""设置选择窗口活动状态，活动时强制暂停移动"""
	selection_active = active
	if selection_active:
		is_moving = false
		print("[LoopManager] Selection active set, pausing movement")

