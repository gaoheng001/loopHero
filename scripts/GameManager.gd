# GameManager.gd
# 游戏总管理器 - 负责游戏状态管理、场景切换等核心功能
class_name GameManager
extends Node

# 游戏状态枚举
enum GameState {
	MAIN_MENU,
	IN_LOOP,
	CAMP_MANAGEMENT,
	PAUSED,
	GAME_OVER
}

# 信号定义
signal game_state_changed(new_state: GameState)
signal hero_died
signal loop_completed(loop_number: int)
signal resources_changed(resources: Dictionary)

# 游戏状态
var current_state: GameState = GameState.MAIN_MENU
var loop_number: int = 0
var is_paused: bool = false

# 资源数据
var resources: Dictionary = {
	"wood": 0,
	"stone": 0,
	"metal": 0,
	"magic_crystal": 0,
	"food": 0
}

# 单例实例
static var instance: GameManager

func _ready():
	# 设置为单例
	if instance == null:
		instance = self
		# 在Godot中，通常通过AutoLoad来实现单例
		# 这里我们简单地保持引用
	else:
		queue_free()
		return
	
	# 连接信号
	game_state_changed.connect(_on_game_state_changed)
	
	# 初始化游戏
	_initialize_game()

func _initialize_game():
	"""初始化游戏设置"""
	print("Game Manager initialized")
	# 设置初始资源
	reset_resources()

func change_state(new_state: GameState):
	"""改变游戏状态"""
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		game_state_changed.emit(new_state)
		print("Game state changed from ", old_state, " to ", new_state)

func _on_game_state_changed(new_state: GameState):
	"""响应游戏状态变化"""
	match new_state:
		GameState.MAIN_MENU:
			_handle_main_menu()
		GameState.IN_LOOP:
			_handle_in_loop()
		GameState.CAMP_MANAGEMENT:
			_handle_camp_management()
		GameState.PAUSED:
			_handle_paused()
		GameState.GAME_OVER:
			_handle_game_over()

func _handle_main_menu():
	"""处理主菜单状态"""
	get_tree().paused = false

func _handle_in_loop():
	"""处理循环冒险状态"""
	get_tree().paused = false

func _handle_camp_management():
	"""处理营地管理状态"""
	get_tree().paused = false

func _handle_paused():
	"""处理暂停状态"""
	get_tree().paused = true

func _handle_game_over():
	"""处理游戏结束状态"""
	get_tree().paused = false

func start_new_loop():
	"""开始新的循环"""
	loop_number += 1
	change_state(GameState.IN_LOOP)
	print("Starting loop #", loop_number)

func complete_loop():
	"""完成当前循环"""
	loop_completed.emit(loop_number)
	print("Loop #", loop_number, " completed")

func retreat_from_loop():
	"""从循环中撤退"""
	print("Retreating from loop #", loop_number)
	change_state(GameState.CAMP_MANAGEMENT)

func hero_death():
	"""英雄死亡处理"""
	hero_died.emit()
	change_state(GameState.GAME_OVER)
	print("Hero died in loop #", loop_number)

func add_resources(resource_type: String, amount: int):
	"""添加资源"""
	if resource_type in resources:
		resources[resource_type] += amount
		resources_changed.emit(resources)
		print("Added ", amount, " ", resource_type, ". Total: ", resources[resource_type])

func spend_resources(resource_type: String, amount: int) -> bool:
	"""消耗资源"""
	if resource_type in resources and resources[resource_type] >= amount:
		resources[resource_type] -= amount
		resources_changed.emit(resources)
		print("Spent ", amount, " ", resource_type, ". Remaining: ", resources[resource_type])
		return true
	else:
		print("Not enough ", resource_type, " to spend ", amount)
		return false

func get_resource_amount(resource_type: String) -> int:
	"""获取资源数量"""
	return resources.get(resource_type, 0)

func reset_resources():
	"""重置资源"""
	for key in resources.keys():
		resources[key] = 0
	# 给予初始资源
	resources["wood"] = 10
	resources["food"] = 5
	resources_changed.emit(resources)

func _input(event):
	"""处理全局输入"""
	if event.is_action_pressed("pause"):
		print("[GameManager] Pause key pressed, toggling pause")
		toggle_pause()

func toggle_pause():
	"""切换暂停状态"""
	print("[GameManager] toggle_pause called, current_state: ", current_state, ", is_paused: ", is_paused)
	if current_state == GameState.IN_LOOP:
		if is_paused:
			print("[GameManager] Unpausing game")
			change_state(GameState.IN_LOOP)
			is_paused = false
		else:
			print("[GameManager] Pausing game")
			change_state(GameState.PAUSED)
			is_paused = true

func save_game():
	"""保存游戏"""
	# TODO: 实现存档功能
	pass

func load_game():
	"""加载游戏"""
	# TODO: 实现读档功能
	pass