# DamageNumberPool.gd
# 伤害数字对象池管理器 - 管理DamageNumber实例的创建、回收和重用
# 提高性能，避免频繁创建和销毁对象

class_name DamageNumberPool
extends Node

# 对象池信号
signal pool_initialized(pool_size: int)
signal number_spawned(damage_number: DamageNumber)
signal number_returned(damage_number: DamageNumber)

# 对象池配置
var pool_size: int = 20
var damage_number_pool: Array[DamageNumber] = []
var active_numbers: Array[DamageNumber] = []

# 父节点引用（用于添加伤害数字到场景）
var parent_container: Node

func _ready():
	_initialize_pool()

func initialize(container: Node, size: int = 20):
	"""初始化对象池"""
	parent_container = container
	pool_size = size
	_initialize_pool()

func _initialize_pool():
	"""初始化伤害数字对象池"""
	# 清理现有池
	_cleanup_pool()
	
	# 创建新的对象池
	for i in range(pool_size):
		var damage_number = DamageNumber.new()
		damage_number.name = "DamageNumber_Pool_%d" % i
		damage_number.visible = false
		
		# 连接信号
		damage_number.animation_completed.connect(_on_damage_number_completed.bind(damage_number))
		damage_number.number_disappeared.connect(_on_damage_number_disappeared.bind(damage_number))
		
		# 添加到父容器
		if parent_container:
			parent_container.add_child(damage_number)
		
		damage_number_pool.append(damage_number)
	
	print("[DamageNumberPool] 初始化完成，池大小: %d" % pool_size)
	emit_signal("pool_initialized", pool_size)

func _cleanup_pool():
	"""清理对象池"""
	# 清理活跃数字
	for number in active_numbers:
		if number and is_instance_valid(number):
			number.stop_animation()
			number.queue_free()
	active_numbers.clear()
	
	# 清理池中数字
	for number in damage_number_pool:
		if number and is_instance_valid(number):
			number.queue_free()
	damage_number_pool.clear()

# ============ 公共接口方法 ============

func show_damage(value: int, position: Vector2, is_critical: bool = false) -> DamageNumber:
	"""显示伤害数字"""
	var type = DamageNumber.NumberType.CRITICAL if is_critical else DamageNumber.NumberType.DAMAGE
	return _spawn_damage_number(value, type, position)

func show_heal(value: int, position: Vector2) -> DamageNumber:
	"""显示治疗数字"""
	return _spawn_damage_number(value, DamageNumber.NumberType.HEAL, position)

func show_miss(position: Vector2) -> DamageNumber:
	"""显示未命中"""
	return _spawn_damage_number(0, DamageNumber.NumberType.MISS, position)

func show_block(position: Vector2) -> DamageNumber:
	"""显示格挡"""
	return _spawn_damage_number(0, DamageNumber.NumberType.BLOCK, position)

func show_absorb(position: Vector2) -> DamageNumber:
	"""显示吸收"""
	return _spawn_damage_number(0, DamageNumber.NumberType.ABSORB, position)

func show_custom_number(value: int, type: DamageNumber.NumberType, position: Vector2) -> DamageNumber:
	"""显示自定义类型的数字"""
	return _spawn_damage_number(value, type, position)

# ============ 内部方法 ============

func _spawn_damage_number(value: int, type: DamageNumber.NumberType, position: Vector2) -> DamageNumber:
	"""从对象池获取并显示伤害数字"""
	var damage_number = _get_from_pool()
	
	if not damage_number:
		print("[DamageNumberPool] 警告：对象池已满，创建临时伤害数字")
		damage_number = _create_temporary_damage_number()
	
	if damage_number:
		# 设置数字属性
		damage_number.show_damage_number(value, type, position)
		
		# 添加到活跃列表
		if damage_number not in active_numbers:
			active_numbers.append(damage_number)
		
		emit_signal("number_spawned", damage_number)
		
		print("[DamageNumberPool] 生成伤害数字: 值=%d, 类型=%s, 位置=%s" % [
			value, _get_type_name(type), str(position)
		])
	
	return damage_number

func _get_from_pool() -> DamageNumber:
	"""从对象池获取可用的伤害数字"""
	for damage_number in damage_number_pool:
		if damage_number and is_instance_valid(damage_number) and not damage_number.is_playing_animation():
			if damage_number not in active_numbers:
				return damage_number
	
	return null

func _create_temporary_damage_number() -> DamageNumber:
	"""创建临时伤害数字（当对象池满时）"""
	var damage_number = DamageNumber.new()
	damage_number.name = "DamageNumber_Temp_%d" % Time.get_unix_time_from_system()
	
	# 连接信号
	damage_number.animation_completed.connect(_on_damage_number_completed.bind(damage_number))
	damage_number.number_disappeared.connect(_on_damage_number_disappeared.bind(damage_number))
	
	# 添加到父容器
	if parent_container:
		parent_container.add_child(damage_number)
	
	return damage_number

func _return_to_pool(damage_number: DamageNumber):
	"""将伤害数字返回对象池"""
	if not damage_number or not is_instance_valid(damage_number):
		return
	
	# 从活跃列表移除
	if damage_number in active_numbers:
		active_numbers.erase(damage_number)
	
	# 重置状态
	damage_number.reset_to_pool()
	
	# 如果是临时创建的，直接销毁
	if damage_number not in damage_number_pool:
		damage_number.queue_free()
	
	emit_signal("number_returned", damage_number)
	
	print("[DamageNumberPool] 伤害数字已返回池中")

# ============ 信号处理 ============

func _on_damage_number_completed(damage_number: DamageNumber):
	"""伤害数字动画完成处理"""
	# 可以在这里添加额外的完成逻辑
	pass

func _on_damage_number_disappeared(damage_number: DamageNumber):
	"""伤害数字消失处理"""
	_return_to_pool(damage_number)

# ============ 工具方法 ============

func _get_type_name(type: DamageNumber.NumberType) -> String:
	"""获取数字类型名称"""
	match type:
		DamageNumber.NumberType.DAMAGE:
			return "DAMAGE"
		DamageNumber.NumberType.CRITICAL:
			return "CRITICAL"
		DamageNumber.NumberType.HEAL:
			return "HEAL"
		DamageNumber.NumberType.MISS:
			return "MISS"
		DamageNumber.NumberType.BLOCK:
			return "BLOCK"
		DamageNumber.NumberType.ABSORB:
			return "ABSORB"
		_:
			return "UNKNOWN"

# ============ 调试和统计方法 ============

func get_pool_status() -> Dictionary:
	"""获取对象池状态"""
	var available_count = 0
	for damage_number in damage_number_pool:
		if damage_number and is_instance_valid(damage_number) and not damage_number.is_playing_animation():
			if damage_number not in active_numbers:
				available_count += 1
	
	return {
		"total_pool_size": damage_number_pool.size(),
		"active_numbers": active_numbers.size(),
		"available_numbers": available_count,
		"pool_utilization": float(active_numbers.size()) / float(pool_size) if pool_size > 0 else 0.0
	}

func print_pool_status():
	"""打印对象池状态"""
	var status = get_pool_status()
	print("[DamageNumberPool] 状态统计:")
	print("  总池大小: %d" % status["total_pool_size"])
	print("  活跃数字: %d" % status["active_numbers"])
	print("  可用数字: %d" % status["available_numbers"])
	print("  池利用率: %.1f%%" % (status["pool_utilization"] * 100))

func set_animation_speed_for_all(speed: float):
	"""设置所有伤害数字的动画速度"""
	speed = clamp(speed, 0.1, 3.0)
	
	# 设置池中所有数字的速度
	for damage_number in damage_number_pool:
		if damage_number and is_instance_valid(damage_number):
			damage_number.set_animation_speed(speed)
	
	# 设置活跃数字的速度
	for damage_number in active_numbers:
		if damage_number and is_instance_valid(damage_number):
			damage_number.set_animation_speed(speed)

func clear_all_active_numbers():
	"""清除所有活跃的伤害数字"""
	for damage_number in active_numbers.duplicate():
		if damage_number and is_instance_valid(damage_number):
			damage_number.stop_animation()
			_return_to_pool(damage_number)

func resize_pool(new_size: int):
	"""调整对象池大小"""
	if new_size <= 0:
		print("[DamageNumberPool] 错误：池大小必须大于0")
		return
	
	var old_size = pool_size
	pool_size = new_size
	
	if new_size > old_size:
		# 扩大池
		for i in range(old_size, new_size):
			var damage_number = DamageNumber.new()
			damage_number.name = "DamageNumber_Pool_%d" % i
			damage_number.visible = false
			
			# 连接信号
			damage_number.animation_completed.connect(_on_damage_number_completed.bind(damage_number))
			damage_number.number_disappeared.connect(_on_damage_number_disappeared.bind(damage_number))
			
			# 添加到父容器
			if parent_container:
				parent_container.add_child(damage_number)
			
			damage_number_pool.append(damage_number)
	elif new_size < old_size:
		# 缩小池
		for i in range(new_size, old_size):
			if i < damage_number_pool.size():
				var damage_number = damage_number_pool[i]
				if damage_number and is_instance_valid(damage_number):
					damage_number.queue_free()
		
		damage_number_pool = damage_number_pool.slice(0, new_size)
	
	print("[DamageNumberPool] 池大小已调整: %d -> %d" % [old_size, new_size])

# ============ 清理方法 ============

func cleanup():
	"""清理对象池资源"""
	clear_all_active_numbers()
	_cleanup_pool()
	print("[DamageNumberPool] 资源清理完成")