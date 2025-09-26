# HeroManager.gd
# 英雄管理器 - 负责英雄属性、装备、技能、升级等管理
class_name HeroManager
extends Node

# 信号定义
signal hero_stats_changed(new_stats: Dictionary)
signal hero_leveled_up(new_level: int)
signal hero_died
signal equipment_changed(slot: String, item: Dictionary)
signal experience_gained(amount: int)

# 英雄职业枚举
enum HeroClass {
	WARRIOR,
	ROGUE,
	NECROMANCER
}

# 装备槽位枚举
enum EquipmentSlot {
	WEAPON,
	ARMOR,
	SHIELD,
	HELMET,
	BOOTS,
	RING,
	AMULET
}

# 英雄基础属性
var hero_class: HeroClass = HeroClass.WARRIOR
var level: int = 1
var experience: int = 0
var experience_to_next_level: int = 100

# 基础属性
var base_stats: Dictionary = {
	"max_hp": 100,
	"current_hp": 100,
	"attack": 10,
	"defense": 5,
	"magic_power": 0,
	"magic_resistance": 2,
	"speed": 100,
	"critical_chance": 0.05,
	"critical_damage": 1.5
}

# 当前属性（包含装备加成）
var current_stats: Dictionary = {}

# 装备系统
var equipment: Dictionary = {
	EquipmentSlot.WEAPON: {},
	EquipmentSlot.ARMOR: {},
	EquipmentSlot.SHIELD: {},
	EquipmentSlot.HELMET: {},
	EquipmentSlot.BOOTS: {},
	EquipmentSlot.RING: {},
	EquipmentSlot.AMULET: {}
}

# 技能系统
var skills: Dictionary = {}
var skill_points: int = 0

# 状态效果
var status_effects: Array[Dictionary] = []

# 地形buff系统
var terrain_buffs: Dictionary = {
	"attack_bonus": 0,  # 攻击力加成
	"max_hp_bonus": 0,  # 生命上限加成
	"experience_bonus_percent": 0  # 经验加成百分比
}
var placed_terrain_cards: Array[Dictionary] = []  # 已放置的地形卡牌

func _ready():
	# 初始化英雄
	_initialize_hero()
	
	# 计算初始属性
	_calculate_stats()
	
	print("Hero Manager initialized - Level ", level, " ", HeroClass.keys()[hero_class])

func _initialize_hero():
	"""初始化英雄数据"""
	# 根据职业设置基础属性
	match hero_class:
		HeroClass.WARRIOR:
			base_stats.max_hp = 120
			base_stats.attack = 12
			base_stats.defense = 8
			base_stats.magic_power = 0
			base_stats.magic_resistance = 3
		HeroClass.ROGUE:
			base_stats.max_hp = 80
			base_stats.attack = 15
			base_stats.defense = 3
			base_stats.speed = 120
			base_stats.critical_chance = 0.15
		HeroClass.NECROMANCER:
			base_stats.max_hp = 70
			base_stats.attack = 8
			base_stats.defense = 2
			base_stats.magic_power = 20
			base_stats.magic_resistance = 8
	
	# 设置当前生命值
	base_stats.current_hp = base_stats.max_hp
	
	# 初始化技能
	_initialize_skills()

func _initialize_skills():
	"""初始化技能树"""
	match hero_class:
		HeroClass.WARRIOR:
			skills = {
				"heavy_strike": {"level": 0, "max_level": 5, "description": "增加攻击力"},
				"armor_mastery": {"level": 0, "max_level": 5, "description": "增加防御力"},
				"berserker_rage": {"level": 0, "max_level": 3, "description": "低血量时攻击力提升"}
			}
		HeroClass.ROGUE:
			skills = {
				"precision": {"level": 0, "max_level": 5, "description": "增加暴击率"},
				"evasion": {"level": 0, "max_level": 5, "description": "增加闪避率"},
				"poison_blade": {"level": 0, "max_level": 3, "description": "攻击附带毒素伤害"}
			}
		HeroClass.NECROMANCER:
			skills = {
				"dark_magic": {"level": 0, "max_level": 5, "description": "增加魔法攻击力"},
				"life_drain": {"level": 0, "max_level": 5, "description": "攻击时吸取生命值"},
				"summon_kugu": {"level": 0, "max_level": 3, "description": "召唤枯骨助战"}
			}

func _calculate_stats():
	"""计算当前属性（基础+装备+技能+地形加成）"""
	current_stats = base_stats.duplicate()
	
	# 应用装备加成
	for slot in equipment:
		var item = equipment[slot]
		if item.size() > 0 and item.has("stats"):
			for stat in item.stats:
				if stat in current_stats:
					current_stats[stat] += item.stats[stat]
	
	# 应用技能加成
	_apply_skill_bonuses()
	
	# 应用地形buff加成
	_apply_terrain_buffs()
	
	# 应用状态效果
	_apply_status_effects()
	
	# 确保当前生命值不超过最大值
	if current_stats.current_hp > current_stats.max_hp:
		current_stats.current_hp = current_stats.max_hp
	
	hero_stats_changed.emit(current_stats)

func _apply_skill_bonuses():
	"""应用技能加成"""
	match hero_class:
		HeroClass.WARRIOR:
			if skills.heavy_strike.level > 0:
				current_stats.attack += skills.heavy_strike.level * 3
			if skills.armor_mastery.level > 0:
				current_stats.defense += skills.armor_mastery.level * 2
		HeroClass.ROGUE:
			if skills.precision.level > 0:
				current_stats.critical_chance += skills.precision.level * 0.02
			if skills.evasion.level > 0:
				current_stats.speed += skills.evasion.level * 5
		HeroClass.NECROMANCER:
			if skills.dark_magic.level > 0:
				current_stats.magic_power += skills.dark_magic.level * 4
			if skills.life_drain.level > 0:
				# 生命吸取在战斗中处理
				pass

func _apply_status_effects():
	"""应用状态效果"""
	for effect in status_effects:
		if effect.has("stat_modifiers"):
			for stat in effect.stat_modifiers:
				if stat in current_stats:
					current_stats[stat] += effect.stat_modifiers[stat]

func gain_experience(amount: int):
	"""获得经验值"""
	experience += amount
	experience_gained.emit(amount)
	
	# 检查升级
	while experience >= experience_to_next_level:
		level_up()
	
	print("Gained ", amount, " experience. Total: ", experience, "/", experience_to_next_level)

func level_up():
	"""升级"""
	experience -= experience_to_next_level
	level += 1
	skill_points += 1
	
	# 计算下一级所需经验
	experience_to_next_level = int(100 * pow(1.2, level - 1))
	
	# 提升基础属性
	base_stats.max_hp += 10
	base_stats.attack += 2
	base_stats.defense += 1
	
	# 恢复生命值
	base_stats.current_hp = base_stats.max_hp
	
	# 重新计算属性
	_calculate_stats()
	
	hero_leveled_up.emit(level)
	print("Level up! Now level ", level, ". Skill points: ", skill_points)

func equip_item(slot: EquipmentSlot, item: Dictionary) -> bool:
	"""装备物品"""
	if not _can_equip_item(slot, item):
		return false
	
	# 卸下当前装备
	var old_item = equipment[slot]
	equipment[slot] = item
	
	# 重新计算属性
	_calculate_stats()
	
	equipment_changed.emit(EquipmentSlot.keys()[slot], item)
	print("Equipped ", item.name, " in ", EquipmentSlot.keys()[slot], " slot")
	
	return true

func unequip_item(slot: EquipmentSlot) -> Dictionary:
	"""卸下装备"""
	var item = equipment[slot]
	equipment[slot] = {}
	
	# 重新计算属性
	_calculate_stats()
	
	equipment_changed.emit(EquipmentSlot.keys()[slot], {})
	print("Unequipped item from ", EquipmentSlot.keys()[slot], " slot")
	
	return item

func _can_equip_item(slot: EquipmentSlot, item: Dictionary) -> bool:
	"""检查是否可以装备物品"""
	# 检查物品类型是否匹配槽位
	if not item.has("slot_type"):
		return false
	
	if item.slot_type != slot:
		return false
	
	# 检查职业限制
	if item.has("class_requirement"):
		if item.class_requirement != hero_class:
			return false
	
	# 检查等级要求
	if item.has("level_requirement"):
		if level < item.level_requirement:
			return false
	
	return true

func upgrade_skill(skill_name: String) -> bool:
	"""升级技能"""
	if not skill_name in skills:
		return false
	
	var skill = skills[skill_name]
	
	if skill_points <= 0:
		print("No skill points available")
		return false
	
	if skill.level >= skill.max_level:
		print("Skill already at max level")
		return false
	
	# 升级技能
	skill.level += 1
	skill_points -= 1
	
	# 重新计算属性
	_calculate_stats()
	
	print("Upgraded skill ", skill_name, " to level ", skill.level)
	return true

func take_damage(damage: int) -> bool:
	"""受到伤害"""
	# 计算实际伤害（考虑防御）
	var actual_damage = max(1, damage - current_stats.defense)
	
	current_stats.current_hp -= actual_damage
	base_stats.current_hp = current_stats.current_hp
	
	print("Hero took ", actual_damage, " damage. HP: ", current_stats.current_hp, "/", current_stats.max_hp)
	
	# 检查死亡
	if current_stats.current_hp <= 0:
		current_stats.current_hp = 0
		base_stats.current_hp = 0
		hero_died.emit()
		print("Hero died!")
		return true
	
	hero_stats_changed.emit(current_stats)
	return false

func heal(amount: int):
	"""治疗"""
	current_stats.current_hp = min(current_stats.max_hp, current_stats.current_hp + amount)
	base_stats.current_hp = current_stats.current_hp
	
	hero_stats_changed.emit(current_stats)
	print("Hero healed for ", amount, " HP. Current HP: ", current_stats.current_hp, "/", current_stats.max_hp)

func add_status_effect(effect: Dictionary):
	"""添加状态效果"""
	status_effects.append(effect)
	_calculate_stats()
	print("Added status effect: ", effect.name)

func remove_status_effect(effect_name: String):
	"""移除状态效果"""
	for i in range(status_effects.size() - 1, -1, -1):
		if status_effects[i].name == effect_name:
			status_effects.remove_at(i)
			break
	
	_calculate_stats()
	print("Removed status effect: ", effect_name)

func get_attack_damage() -> int:
	"""计算攻击伤害"""
	var base_damage = current_stats.attack
	
	# 检查暴击
	if randf() < current_stats.critical_chance:
		base_damage = int(base_damage * current_stats.critical_damage)
		print("Critical hit!")
	
	return base_damage

func get_stats() -> Dictionary:
	"""获取当前属性"""
	return current_stats.duplicate()

func get_equipment() -> Dictionary:
	"""获取当前装备"""
	return equipment.duplicate()

func get_skills() -> Dictionary:
	"""获取技能信息"""
	return skills.duplicate()

func is_alive() -> bool:
	"""检查是否存活"""
	return current_stats.current_hp > 0

func reset_hero():
	"""重置英雄状态（用于新游戏）"""
	level = 1
	experience = 0
	experience_to_next_level = 100
	skill_points = 0
	
	# 重置装备
	for slot in equipment:
		equipment[slot] = {}
	
	# 重置技能
	_initialize_skills()
	
	# 重置地形buff
	terrain_buffs = {
		"attack_bonus": 0,
		"max_hp_bonus": 0,
		"experience_bonus_percent": 0
	}
	placed_terrain_cards.clear()
	
	# 重新计算属性
	_calculate_stats()
	
	# 发出信号
	hero_stats_changed.emit(current_stats)

# 地形buff系统函数
func _apply_terrain_buffs():
	"""应用地形buff加成"""
	# 攻击力加成
	current_stats.attack += terrain_buffs.attack_bonus
	
	# 生命上限加成
	current_stats.max_hp += terrain_buffs.max_hp_bonus

func add_terrain_card(card_data: Dictionary):
	"""添加地形卡牌效果"""
	placed_terrain_cards.append(card_data)
	
	# 应用初始效果
	if card_data.has("effects"):
		var effects = card_data.effects
		
		if effects.has("initial_attack_bonus"):
			terrain_buffs.attack_bonus += effects.initial_attack_bonus
			print("[HeroManager] 竹林效果：攻击力+", effects.initial_attack_bonus)
		
		if effects.has("initial_max_hp_bonus"):
			terrain_buffs.max_hp_bonus += effects.initial_max_hp_bonus
			print("[HeroManager] 山峰效果：生命上限+", effects.initial_max_hp_bonus)
		
		if effects.has("experience_bonus_percent"):
			terrain_buffs.experience_bonus_percent += effects.experience_bonus_percent
			print("[HeroManager] 河流效果：经验加成+", effects.experience_bonus_percent, "%")
	
	# 重新计算属性
	_calculate_stats()
	hero_stats_changed.emit(current_stats)

func apply_daily_terrain_effects():
	"""应用每日地形效果"""
	for card in placed_terrain_cards:
		if card.has("effects"):
			var effects = card.effects
			
			# 竹林每日攻击力加成
			if effects.has("daily_attack_bonus"):
				terrain_buffs.attack_bonus += effects.daily_attack_bonus
				print("[HeroManager] 竹林每日效果：攻击力+", effects.daily_attack_bonus)
			
			# 山峰每日治疗
			if effects.has("daily_heal"):
				heal(effects.daily_heal)
				print("[HeroManager] 山峰每日效果：恢复", effects.daily_heal, "点生命值")
	
	# 重新计算属性
	_calculate_stats()
	hero_stats_changed.emit(current_stats)

func get_experience_multiplier() -> float:
	"""获取经验倍率"""
	return 1.0 + (terrain_buffs.experience_bonus_percent / 100.0)