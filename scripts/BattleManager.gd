# BattleManager.gd
# 战斗管理器 - 负责战斗逻辑、伤害计算、战斗结果处理等
class_name BattleManager
extends Node

# 信号定义
signal battle_started(hero_stats: Dictionary, enemy_data: Dictionary)
signal battle_ended(victory: bool, rewards: Dictionary)
signal damage_dealt(attacker: String, target: String, damage: int)
signal battle_log_updated(message: String)

# 战斗状态枚举
enum BattleState {
	IDLE,
	IN_PROGRESS,
	HERO_TURN,
	ENEMY_TURN,
	ENDED
}

# 当前战斗状态
var current_state: BattleState = BattleState.IDLE
var battle_log: Array[String] = []

# 战斗参与者
var hero_data: Dictionary = {}
var enemy_data: Dictionary = {}
var original_enemy_hp: int = 0

# 战斗配置
var auto_battle: bool = true
var battle_speed: float = 1.0
var turn_delay: float = 1.0

# 引用
var hero_manager: Node
var loop_manager: Node
var battle_window: Node

func _ready():
	print("Battle Manager initialized")

func start_battle(enemy: Dictionary, hero_mgr: Node = null, loop_mgr: Node = null):
	"""开始战斗"""
	if current_state != BattleState.IDLE:
		print("Battle already in progress")
		return
	
	# 设置引用
	hero_manager = hero_mgr
	loop_manager = loop_mgr
	
	# 初始化战斗数据
	enemy_data = enemy.duplicate()
	original_enemy_hp = enemy_data.hp
	
	if hero_manager:
		hero_data = hero_manager.get_stats()
	else:
		# 使用默认英雄数据（测试用）
		hero_data = {
			"max_hp": 100,
			"current_hp": 100,
			"attack": 15,
			"defense": 5,
			"critical_chance": 0.1,
			"critical_damage": 1.5
		}
	
	# 清空战斗日志
	battle_log.clear()
	
	# 开始战斗
	current_state = BattleState.IN_PROGRESS
	battle_started.emit(hero_data, enemy_data)
	
	_add_battle_log("战斗开始！")
	_add_battle_log("英雄 vs " + enemy_data.name)
	_add_battle_log("英雄生命值: " + str(hero_data.current_hp) + "/" + str(hero_data.max_hp))
	_add_battle_log("敌人生命值: " + str(enemy_data.hp))
	
	print("Battle started: Hero vs ", enemy_data.name)
	
	# 开始战斗循环
	if auto_battle:
		_start_auto_battle()

func _start_auto_battle():
	"""开始自动战斗"""
	while current_state == BattleState.IN_PROGRESS:
		# 英雄回合
		current_state = BattleState.HERO_TURN
		_hero_attack()
		
		# 检查敌人是否死亡
		if enemy_data.hp <= 0:
			_end_battle(true)
			break
		
		# 等待
		await get_tree().create_timer(turn_delay / battle_speed).timeout
		
		# 敌人回合
		current_state = BattleState.ENEMY_TURN
		_enemy_attack()
		
		# 检查英雄是否死亡
		if hero_data.current_hp <= 0:
			_end_battle(false)
			break
		
		# 等待下一轮
		await get_tree().create_timer(turn_delay / battle_speed).timeout
		current_state = BattleState.IN_PROGRESS

func _hero_attack():
	"""英雄攻击"""
	# 播放攻击动画
	if battle_window:
		battle_window.show_attack_animation("Hero")
	
	var damage = _calculate_hero_damage()
	var actual_damage = _apply_damage_to_enemy(damage)
	
	damage_dealt.emit("Hero", enemy_data.name, actual_damage)
	_add_battle_log("英雄攻击造成 " + str(actual_damage) + " 点伤害")
	_add_battle_log(enemy_data.name + " 剩余生命值: " + str(enemy_data.hp))

func _enemy_attack():
	"""敌人攻击"""
	# 播放攻击动画
	if battle_window:
		battle_window.show_attack_animation("Enemy")
	
	var damage = _calculate_enemy_damage()
	var actual_damage = _apply_damage_to_hero(damage)
	
	damage_dealt.emit(enemy_data.name, "Hero", actual_damage)
	_add_battle_log(enemy_data.name + " 攻击造成 " + str(actual_damage) + " 点伤害")
	_add_battle_log("英雄剩余生命值: " + str(hero_data.current_hp) + "/" + str(hero_data.max_hp))

func _calculate_hero_damage() -> int:
	"""计算英雄伤害"""
	var base_damage = hero_data.attack
	
	# 检查暴击
	var is_critical = randf() < hero_data.get("critical_chance", 0.0)
	if is_critical:
		base_damage = int(base_damage * hero_data.get("critical_damage", 1.5))
		_add_battle_log("暴击！")
	
	# 应用随机波动（±10%）
	var damage_variance = randf_range(0.9, 1.1)
	base_damage = int(base_damage * damage_variance)
	
	return max(1, base_damage)

func _calculate_enemy_damage() -> int:
	"""计算敌人伤害"""
	var base_damage = enemy_data.get("attack", 10)
	
	# 应用随机波动（±15%）
	var damage_variance = randf_range(0.85, 1.15)
	base_damage = int(base_damage * damage_variance)
	
	return max(1, base_damage)

func _apply_damage_to_enemy(damage: int) -> int:
	"""对敌人造成伤害"""
	var enemy_defense = enemy_data.get("defense", 0)
	var actual_damage = max(1, damage - enemy_defense)
	
	enemy_data.hp -= actual_damage
	enemy_data.hp = max(0, enemy_data.hp)
	
	return actual_damage

func _apply_damage_to_hero(damage: int) -> int:
	"""对英雄造成伤害"""
	var hero_defense = hero_data.get("defense", 0)
	var actual_damage = max(1, damage - hero_defense)
	
	hero_data.current_hp -= actual_damage
	hero_data.current_hp = max(0, hero_data.current_hp)
	
	# 同步到英雄管理器
	if hero_manager:
		hero_manager.take_damage(actual_damage)
	
	return actual_damage

func _end_battle(victory: bool):
	"""结束战斗"""
	current_state = BattleState.ENDED
	
	var rewards = {}
	
	if victory:
		_add_battle_log("胜利！")
		rewards = _calculate_victory_rewards()
		_apply_victory_rewards(rewards)
	else:
		_add_battle_log("失败！英雄死亡...")
	
	battle_ended.emit(victory, rewards)
	print("Battle ended. Victory: ", victory)
	
	# 注释掉直接调用，避免重复调用on_battle_ended
	# 现在只通过信号连接来调用，确保只调用一次
	# if loop_manager:
	#	print("[BattleManager] Calling loop_manager.on_battle_ended")
	#	loop_manager.on_battle_ended(victory, rewards)
	# else:
	#	print("[BattleManager] Error: loop_manager is null!")
	
	# 重置状态
	current_state = BattleState.IDLE

func _calculate_victory_rewards() -> Dictionary:
	"""计算胜利奖励"""
	var rewards = {
		"experience": 0,
		"resources": {},
		"items": []
	}
	
	# 基础经验奖励
	var base_exp = original_enemy_hp + enemy_data.get("attack", 0) * 2
	rewards.experience = base_exp
	
	# 资源奖励（如果敌人卡牌有定义）
	if enemy_data.has("rewards"):
		rewards.resources = enemy_data.rewards.duplicate()
	else:
		# 默认资源奖励
		rewards.resources = {
			"wood": randi_range(1, 3),
			"stone": randi_range(0, 2)
		}
	
	# 装备掉落（低概率）
	if randf() < 0.1:  # 10%概率
		rewards.items.append(_generate_random_item())
	
	return rewards

func _apply_victory_rewards(rewards: Dictionary):
	"""应用胜利奖励"""
	# 给予经验
	if hero_manager and rewards.has("experience"):
		if hero_manager.has_method("gain_experience"):
			hero_manager.gain_experience(rewards.experience)
			_add_battle_log("获得 " + str(rewards.experience) + " 点经验")
	
	# 给予资源
	if rewards.has("resources"):
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager and game_manager.has_method("add_resources"):
			for resource_type in rewards.resources:
				var amount = rewards.resources[resource_type]
				game_manager.add_resources(resource_type, amount)
				_add_battle_log("获得 " + str(amount) + " " + resource_type)
	
	# 给予物品
	if rewards.has("items"):
		for item in rewards.items:
			_add_battle_log("获得物品: " + item.name)
			# TODO: 添加到背包系统

func _generate_random_item() -> Dictionary:
	"""生成随机物品"""
	var items = [
		{
			"name": "生锈的剑",
			"slot_type": "weapon",
			"stats": {"attack": 3},
			"rarity": "common"
		},
		{
			"name": "皮甲",
			"slot_type": "armor",
			"stats": {"defense": 2, "max_hp": 5},
			"rarity": "common"
		},
		{
			"name": "铁盾",
			"slot_type": "shield",
			"stats": {"defense": 4},
			"rarity": "common"
		}
	]
	
	return items[randi() % items.size()]

func _add_battle_log(message: String):
	"""添加战斗日志"""
	battle_log.append(message)
	battle_log_updated.emit(message)
	
	# 同时更新战斗窗口的日志
	if battle_window:
		battle_window.add_battle_log(message)
	
	print("[Battle] ", message)

# 移除了_on_battle_ended函数，现在直接在_end_battle中调用loop_manager.on_battle_ended

func get_battle_log() -> Array[String]:
	"""获取战斗日志"""
	return battle_log.duplicate()

func get_battle_state() -> BattleState:
	"""获取战斗状态"""
	return current_state

func is_battle_active() -> bool:
	"""检查是否正在战斗"""
	return current_state != BattleState.IDLE and current_state != BattleState.ENDED

func set_battle_speed(speed: float):
	"""设置战斗速度"""
	battle_speed = clamp(speed, 0.5, 3.0)
	print("Battle speed set to ", battle_speed)

func set_auto_battle(enabled: bool):
	"""设置自动战斗"""
	auto_battle = enabled
	print("Auto battle ", "enabled" if enabled else "disabled")

func force_end_battle():
	"""强制结束战斗"""
	if is_battle_active():
		_add_battle_log("战斗被强制结束")
		_end_battle(false)

func get_hero_battle_data() -> Dictionary:
	"""获取英雄战斗数据"""
	return hero_data.duplicate()

func get_enemy_battle_data() -> Dictionary:
	"""获取敌人战斗数据"""
	return enemy_data.duplicate()

# 特殊战斗效果
func apply_special_effect(effect_name: String, data: Dictionary = {}):
	"""应用特殊战斗效果"""
	match effect_name:
		"poison":
			_apply_poison_effect(data)
		"heal":
			_apply_heal_effect(data)
		"buff_attack":
			_apply_attack_buff(data)
		"debuff_defense":
			_apply_defense_debuff(data)
		_:
			print("Unknown special effect: ", effect_name)

func _apply_poison_effect(data: Dictionary):
	"""应用毒素效果"""
	var damage = data.get("damage", 5)
	enemy_data.hp -= damage
	_add_battle_log(enemy_data.name + " 受到毒素伤害: " + str(damage))

func _apply_heal_effect(data: Dictionary):
	"""应用治疗效果"""
	var heal_amount = data.get("amount", 10)
	hero_data.current_hp = min(hero_data.max_hp, hero_data.current_hp + heal_amount)
	_add_battle_log("英雄恢复 " + str(heal_amount) + " 点生命值")

func _apply_attack_buff(data: Dictionary):
	"""应用攻击力增益"""
	var buff_amount = data.get("amount", 5)
	hero_data.attack += buff_amount
	_add_battle_log("英雄攻击力提升 " + str(buff_amount))

func _apply_defense_debuff(data: Dictionary):
	"""应用防御力减益"""
	var debuff_amount = data.get("amount", 3)
	enemy_data.defense = max(0, enemy_data.get("defense", 0) - debuff_amount)
	_add_battle_log(enemy_data.name + " 防御力降低 " + str(debuff_amount))