extends Node
class_name TeamBattleManager

# 冒险与挖矿风格：队伍整体回合战斗管理器（Alpha骨架）

signal battle_started(hero_team, enemy_team)
signal battle_finished(result, stats)
signal turn_started(turn_index, acting_side)
signal turn_finished(turn_index)
signal skill_triggered(user, skill_id, context)
signal damage_dealt(source, target, amount, is_crit)
signal team_hp_changed(side, current, max)
signal log_message(text)

var hero_team: Array = []
var enemy_team: Array = []
var battle_active: bool = false
var turn_index: int = 0
var options: Dictionary = {}
var rng = RandomNumberGenerator.new()
var _default_skill_limit: int = 1

# 动画控制器引用
var battle_animation_controller: Node = null
# 回合执行状态标志，防止重入导致同时结算
var is_turn_executing: bool = false

# 队伍HP池（战斗内仅使用队伍血量）
var hero_team_hp_current: int = 0
var hero_team_hp_max: int = 0
var enemy_team_hp_current: int = 0
var enemy_team_hp_max: int = 0
 
# 队伍普攻暴击率加成（被动：凝心决）
var heroes_normal_attack_crit_rate_bonus: float = 0.0
var enemies_normal_attack_crit_rate_bonus: float = 0.0
 
# 简易效果/技能/被动支持（基础版本）
# - 成员支持可选字段：skills: Array[String|Dictionary], passives: Array[String|Dictionary], status_effects: Array[String|Dictionary]
# - 目前内置：
#   passives: "tough"(防御+1/默认)、"berserk"(血量<50%时攻击+2/默认)、"lifesteal"(造成伤害后回复20%)
#   skills:   "power_strike"(该次攻击伤害+3)、"multi_strike"(额外攻击一次)
#   status:   "poison"(回合开始失去2点生命)、"regen"(回合开始恢复2点生命)、
#             "attack_up"(攻击+2)、"defense_down"(防御-2)、"shield"(受到伤害-2)

func _ready():
	rng.randomize()

func start_battle(p_hero_team: Array, p_enemy_team: Array, p_options: Dictionary = {}):
	"""
	初始化队伍战斗。
	p_hero_team / p_enemy_team 元素建议为字典或对象，至少包含：
	  - current_hp / max_hp
	  - attack / defense
	  - name（可选，用于日志）
	"""
	hero_team = p_hero_team.duplicate(true)
	enemy_team = p_enemy_team.duplicate(true)
	options = p_options.duplicate(true)
	turn_index = 0
	battle_active = true
	_reset_skill_usage_for_team(hero_team)
	_reset_skill_usage_for_team(enemy_team)

	# 初始化队伍HP池（战斗内仅使用队伍血量）
	hero_team_hp_current = _team_total_hp(hero_team)
	enemy_team_hp_current = _team_total_hp(enemy_team)
	hero_team_hp_max = 0
	for m in hero_team:
		hero_team_hp_max += int(_safe_get(m, "max_hp", _safe_get(m, "current_hp", 0)))
	enemy_team_hp_max = 0
	for m in enemy_team:
		enemy_team_hp_max += int(_safe_get(m, "max_hp", _safe_get(m, "current_hp", 0)))

	# 开战时应用被动：凝心决（技能暴击率+20%，全队普攻暴击率+10%）
	_apply_battle_start_passives(hero_team, "heroes")
	_apply_battle_start_passives(enemy_team, "enemies")

	_log("[TBM] 队伍HP池初始化：英雄 %d/%d，敌方 %d/%d" % [
		hero_team_hp_current, hero_team_hp_max, enemy_team_hp_current, enemy_team_hp_max
	])

	_log("[TBM] Battle started: heroes=%d, enemies=%d" % [hero_team.size(), enemy_team.size()])
	emit_signal("battle_started", hero_team, enemy_team)

	# 若一方为空，直接结束
	var ended = _check_battle_end()
	if ended != null:
		_finish_battle(ended.result, ended.stats)

func execute_turn():
	"""
	执行一个整体回合（按先攻值决定先后手，双方交替行动）。
	若在任一阶段结束后出现团灭，则立即结束战斗。
	"""
	if not battle_active:
		return

	# 防重入：若上一回合尚未完全结束，跳过此次触发
	if is_turn_executing:
		_log("[TBM] Skip: turn already executing")
		return
	is_turn_executing = true

	turn_index += 1
	# 计算双方先攻总值（兼容 initiative / speed 字段）
	var heroes_alive := _collect_alive(hero_team)
	var enemies_alive := _collect_alive(enemy_team)
	var hero_init := _team_total_initiative(heroes_alive)
	var enemy_init := _team_total_initiative(enemies_alive)
	var first_side := "heroes"
	var second_side := "enemies"
	if enemy_init > hero_init:
		first_side = "enemies"
		second_side = "heroes"
	elif enemy_init == hero_init:
		var tie_pref: String = String(options.get("initiative_tie_first", "heroes"))
		first_side = tie_pref
		second_side = ("heroes" if tie_pref == "enemies" else "enemies")
	_log("[TBM] Turn %d initiative — heroes: %d, enemies: %d; first: %s" % [turn_index, hero_init, enemy_init, first_side])
	
	# 先手行动方
	emit_signal("turn_started", turn_index, first_side)
	_log("[TBM] Turn %d started (%s)" % [turn_index, first_side])
	_apply_start_of_turn_effects(
		(hero_team if first_side == "heroes" else enemy_team),
		(enemy_team if first_side == "heroes" else hero_team)
	)
	await _execute_team_phase(
		(hero_team if first_side == "heroes" else enemy_team),
		(enemy_team if first_side == "heroes" else hero_team)
	)
	
	var ended = _check_battle_end()
	if ended != null:
		_finish_battle(ended.result, ended.stats)
		is_turn_executing = false
		return
	
	# 等待先手动画完成后再执行后手，并添加回合间隔
	if battle_animation_controller:
		await get_tree().create_timer(1.0).timeout  # 增加到1秒间隔
	
	# 后手行动方
	emit_signal("turn_started", turn_index, second_side)
	_log("[TBM] Turn %d continued (%s)" % [turn_index, second_side])
	_apply_start_of_turn_effects(
		(hero_team if second_side == "heroes" else enemy_team),
		(enemy_team if second_side == "heroes" else hero_team)
	)
	await _execute_team_phase(
		(hero_team if second_side == "heroes" else enemy_team),
		(enemy_team if second_side == "heroes" else hero_team)
	)
	
	ended = _check_battle_end()
	if ended != null:
		_finish_battle(ended.result, ended.stats)
		is_turn_executing = false
		return
	
	emit_signal("turn_finished", turn_index)
	_log("[TBM] Turn %d finished" % turn_index)
	# 回合完全结束，释放执行标志
	is_turn_executing = false

func run_to_completion(max_turns: int = 100):
	"""
	便捷方法：在不接UI的情况下，直接跑到战斗结束或达到最大回合。
	"""
	var turns = 0
	while battle_active and turns < max_turns:
		execute_turn()
		turns += 1

func _execute_team_phase(attacking_team: Array, defending_team: Array):
	"""
	整体行动阶段：队伍作为整体进行1次行动。
	按照《冒险与挖矿》设计文档：
	1. 按队伍顺序逐个判定技能触发概率
	2. 一旦有技能触发，立即执行并结束本回合
	3. 若无技能触发，则执行整队普攻
	"""
	var defenders_alive = _collect_alive(defending_team)
	if defenders_alive.size() == 0:
		return

	var attackers_alive = _collect_alive(attacking_team)
	if attackers_alive.size() == 0:
		return

	# 队伍整体行动开始提示
	var team_name = "英雄队伍" if attacking_team == hero_team else "敌方队伍"
	_log("=== [TBM] %s 整体行动开始！ ===" % team_name)
	var team_hp_cur = _get_team_hp_current(attacking_team)
	var team_hp_max = _get_team_hp_max(attacking_team)
	var team_atk: int = _team_total_attack(attackers_alive)
	_log("[TBM] 队伍HP：%d/%d，队伍ATK：%d，成员数：%d" % [team_hp_cur, team_hp_max, team_atk, attackers_alive.size()])

	# 第一阶段：按队伍顺序判定技能触发
	var skill_triggered = false
	var skill_caster = null
	var triggered_skill = ""
	
	# 按位置顺序排序（如果有position字段）
	attackers_alive.sort_custom(func(a, b): return _get_position(a) < _get_position(b))
	
	_log("[TBM] 开始按顺序判定技能触发...")
	for i in range(attackers_alive.size()):
		var attacker = attackers_alive[i]
		_log("[TBM] 检查成员%d：%s 的技能触发..." % [i+1, _member_name(attacker)])
		# 检查是否有技能触发（简化实现：30%概率触发技能）
		if _check_skill_trigger(attacker):
			skill_triggered = true
			skill_caster = attacker
			triggered_skill = _get_triggered_skill(attacker)
			_log("[TBM] ✓ 技能触发！%s 将使用 %s" % [_member_name(skill_caster), triggered_skill])
			break
		else:
			_log("[TBM] ✗ %s 技能未触发" % _member_name(attacker))
	
	# 第二阶段：执行技能或整队普攻
	if skill_triggered:
		# 执行技能
		_log("[TBM] >>> 队伍技能阶段：%s 使用 %s <<<" % [_member_name(skill_caster), triggered_skill])
		await _execute_skill(skill_caster, triggered_skill, defenders_alive)
		_log("[TBM] 队伍本回合行动结束（技能触发）")
	else:
		# 整队普攻
		_log("[TBM] >>> 队伍整体普攻阶段：所有成员同时攻击！ <<<")
		_log("[TBM] 参与普攻的成员数量：%d名" % attackers_alive.size())
		await _execute_team_attack(attackers_alive, defenders_alive)
		_log("[TBM] 队伍本回合行动结束（整体普攻）")
	
	_log("=== [TBM] %s 整体行动结束！ ===" % team_name)

func _get_position(member) -> int:
	"""获取队伍成员的位置，用于排序"""
	return _safe_get(member, "position", 999)

func _check_skill_trigger(attacker) -> bool:
	"""检查角色是否触发技能（受次数限制）"""
	# 优先支持：万剑归宗（首回合几率加倍）
	var skills: Array = _safe_get(attacker, "skills", []) as Array
	for s in skills:
		var sid: String = (s if typeof(s) == TYPE_STRING else String(_safe_get(s, "id", "")))
		if sid == "skill.hero.wanjian_guizong.v1" and _can_use_skill(attacker, sid):
			var base: float = 0.30
			var mult: float = 1.0
			if typeof(s) == TYPE_DICTIONARY:
				base = float(_safe_get(s, "chance", base))
				mult = float(_safe_get(s, "first_round_chance_multiplier", 1.0))
			if turn_index == 1:
				base *= mult
			var chance: float = clamp(base, 0.0, 1.0)
			return rng.randf() < chance
	return false

func _get_triggered_skill(attacker) -> String:
	"""获取触发的技能名称（优先 multi_strike / power_strike）"""
	var triggerable: Array = _get_triggerable_skill_ids(attacker)
	# 优先返回自定义技能：万剑归宗
	for id in triggerable:
		if id == "skill.hero.wanjian_guizong.v1":
			return id
	if triggerable.size() > 0:
		if "multi_strike" in triggerable:
			return "multi_strike"
		elif "power_strike" in triggerable:
			return "power_strike"
		return triggerable[0]
	return "basic_attack"

func _execute_skill(caster, skill_name: String, defenders_alive: Array):
	"""执行单个技能（受次数限制）"""
	if defenders_alive.size() == 0:
		return
	# 改为直接以对方整体为目标结算，无需选择单体目标
	if not _can_use_skill(caster, skill_name):
		_log("[TBM] 技能[%s]已达触发上限，改为普通攻击。" % skill_name)
		var dmg_info_fallback: Dictionary = _calc_team_damage(caster, defenders_alive)
		await _apply_team_pool_damage([caster], defenders_alive, dmg_info_fallback.damage, dmg_info_fallback.is_crit)
		_log("[TBM] %s -> 敌方队伍 : %d%s (技能上限后普通攻击)" % [
			_member_name(caster), dmg_info_fallback.damage, ("*" if dmg_info_fallback.is_crit else "")
		])
		return
	match skill_name:
		"skill.hero.wanjian_guizong.v1":
			_register_skill_use(caster, skill_name)
			emit_signal("skill_triggered", caster, "skill.hero.wanjian_guizong.v1", defenders_alive)
			# 根据目标数放大攻击：攻击×目标数×rate（默认0.5）
			var rate: float = 0.5
			var skills: Array = _safe_get(caster, "skills", []) as Array
			for s in skills:
				if typeof(s) == TYPE_DICTIONARY and String(_safe_get(s, "id", "")) == "skill.hero.wanjian_guizong.v1":
					rate = float(_safe_get(s, "rate", rate))
					break
			var target_count: int = max(1, defenders_alive.size())
			var effective_atk: int = int(round(_safe_get(caster, "attack", 10) * target_count * rate))
			# 技能暴击加成来自被动“凝心决”
			var tmp: Dictionary = caster.duplicate(true)
			tmp["attack"] = effective_atk
			if caster.has("__skill_crit_bonus"):
				tmp["__skill_crit_bonus"] = caster["__skill_crit_bonus"]
			var dmg_info: Dictionary = _calc_team_damage(tmp, defenders_alive)
			await _apply_team_pool_damage([caster], defenders_alive, dmg_info.damage, dmg_info.is_crit)
			_log("[TBM] %s 施放 万剑归宗：对敌方队伍造成 %d%s 伤害" % [
				_member_name(caster), dmg_info.damage, ("*" if dmg_info.is_crit else "")
			])
			if _has_passive(caster, "lifesteal"):
				var heal_amount = int(round(dmg_info.damage * 0.2))
				_heal_member(caster, heal_amount)
				_log("[TBM] 被动[吸血] %s 回复 %d 生命" % [_member_name(caster), heal_amount])
		"multi_strike":
			_register_skill_use(caster, skill_name)
			# 以整体为目标，动画对整队播放
			emit_signal("skill_triggered", caster, "multi_strike", defenders_alive)
			for i in range(2):
				var dmg_info = _calc_team_damage(caster, defenders_alive)
				await _apply_team_pool_damage([caster], defenders_alive, dmg_info.damage, dmg_info.is_crit)
				_log("[TBM] %s -> 敌方队伍 : %d%s (连击 %d/2)" % [
					_member_name(caster), dmg_info.damage,
					("*" if dmg_info.is_crit else ""), i+1
				])
				if _has_passive(caster, "lifesteal"):
					var heal_amount = int(round(dmg_info.damage * 0.2))
					_heal_member(caster, heal_amount)
					_log("[TBM] 被动[吸血] %s 回复 %d 生命" % [_member_name(caster), heal_amount])
		"power_strike":
			_register_skill_use(caster, skill_name)
			emit_signal("skill_triggered", caster, "power_strike", defenders_alive)
			var dmg_info = _calc_team_damage(caster, defenders_alive)
			await _apply_team_pool_damage([caster], defenders_alive, dmg_info.damage, dmg_info.is_crit)
			_log("[TBM] %s -> 敌方队伍 : %d%s (强击)" % [
				_member_name(caster), dmg_info.damage, ("*" if dmg_info.is_crit else "")
			])
			if _has_passive(caster, "lifesteal"):
				var heal_amount = int(round(dmg_info.damage * 0.2))
				_heal_member(caster, heal_amount)
				_log("[TBM] 被动[吸血] %s 回复 %d 生命" % [_member_name(caster), heal_amount])
		_:
			var dmg_info = _calc_team_damage(caster, defenders_alive)
			await _apply_team_pool_damage([caster], defenders_alive, dmg_info.damage, dmg_info.is_crit)
			
			_log("[TBM] %s -> 敌方队伍 : %d%s (技能攻击)" % [
				_member_name(caster), dmg_info.damage, ("*" if dmg_info.is_crit else "")
			])

func _execute_team_attack(attackers_alive: Array, defenders_alive: Array):
	"""执行整队普攻：队伍作为整体攻击"""
	_log("[TBM] 🗡️ 整队普攻开始！")
	if defenders_alive.size() == 0 or attackers_alive.size() == 0:
		return
	
	# 计算队伍总攻击力
	var team_atk := _team_total_attack(attackers_alive)
	if team_atk <= 0:
		_log("[TBM] 队伍总攻击为0，无法造成伤害")
		return
	
	# 创建队伍攻击者代表
	var attacker_repr = attackers_alive[0]
	var team_attacker = {
		"name": _member_name(attacker_repr) + "所在队伍",
		"attack": team_atk,
		"skills": [],
		"position": _get_position(attacker_repr),
		"__side__": ("heroes" if attackers_alive == hero_team else "enemies")
	}
	
	# 计算队伍伤害
	var dmg_info = _calc_team_damage(team_attacker, defenders_alive)
	
	# 随机选择一个目标用于动画展示
	var target = defenders_alive[rng.randi_range(0, defenders_alive.size()-1)]
	
	_log("[TBM] 🗡️ 队伍普攻 -> 伤害: %d%s" % [dmg_info.damage, ("*" if dmg_info.is_crit else "")])
	
	# 应用伤害到防守方队伍HP池（包含信号发射）
	await _apply_team_pool_damage(attackers_alive, defenders_alive, dmg_info.damage, dmg_info.is_crit)
	
	# 处理吸血被动（队伍中任何有吸血的成员都能触发）
	for attacker in attackers_alive:
		if _has_passive(attacker, "lifesteal"):
			var heal_amount = int(round(dmg_info.damage * 0.2))
			_heal_member(attacker, heal_amount)
			_log("[TBM] 被动[吸血] %s 回复 %d 生命" % [_member_name(attacker), heal_amount])
	
	_log("[TBM] 🗡️ 整队普攻完成！")

func _calc_damage(attacker, target) -> Dictionary:
	"""
	基础伤害占位：
	  damage = max(1, (attacker.attack - target.defense))，含简易暴击（10%）。
	字段缺失时采用默认值。
	返回 { damage:int, is_crit:bool }。
	"""
	var atk = _safe_get(attacker, "attack", 10)
	var def = _safe_get(target, "defense", 5)

	# 被动修正
	var pmods_att = _get_passive_mods(attacker)
	var pmods_tgt = _get_passive_mods(target)
	atk += pmods_att.atk
	def += pmods_tgt.def

	# 状态修正
	var smods_att = _get_status_mods(attacker)
	var smods_tgt = _get_status_mods(target)
	atk += smods_att.atk
	def += smods_tgt.def

	# 计算基础伤害
	var base = max(1, atk - def)

	# 技能：强击（该次伤害+3）
	if _has_skill(attacker, "power_strike"):
		base += 3
		emit_signal("skill_triggered", attacker, "power_strike", [target])

	# 暴击
	var is_crit = rng.randf() < 0.1
	if is_crit:
		base = int(round(base * 1.5))

	# 目标护盾
	base = max(0, base - _get_incoming_damage_reduction(target))

	return {"damage": base, "is_crit": is_crit}

# ---- 团队整体目标伤害计算 ----
func _calc_team_damage(attacker, defenders_alive: Array) -> Dictionary:
	# 进攻方攻击与修正
	var atk = _safe_get(attacker, "attack", 10)
	var pmods_att = _get_passive_mods(attacker)
	var smods_att = _get_status_mods(attacker)
	atk += pmods_att.atk
	atk += smods_att.atk

	if defenders_alive.size() == 0:
		return {"damage": max(1, atk), "is_crit": false}

	# 统计防守方平均防御与减伤
	var def_sum: int = 0
	var def_mod_sum: int = 0
	var reduce_sum: int = 0
	for d in defenders_alive:
		def_sum += int(_safe_get(d, "defense", 5))
		var pmods = _get_passive_mods(d)
		def_mod_sum += int(pmods.def)
		var smods = _get_status_mods(d)
		def_mod_sum += int(smods.def)
		reduce_sum += int(_get_incoming_damage_reduction(d))
	var count: float = float(defenders_alive.size())
	var def_avg: float = float(def_sum) / count
	var def_mod_avg: float = float(def_mod_sum) / count
	var reduce_avg: float = float(reduce_sum) / count

	var base: int = max(1, int(round(atk - (def_avg + def_mod_avg))))

	# 技能：强击（该次伤害+3）
	if _has_skill(attacker, "power_strike"):
		base += 3

	# 暴击：基础10% + 队伍普攻暴击加成 + 技能暴击加成
	var base_crit := 0.1
	var side := ""
	if typeof(attacker) == TYPE_DICTIONARY and attacker.has("__side__"):
		side = String(attacker["__side__"])
	if side == "heroes":
		base_crit += heroes_normal_attack_crit_rate_bonus
	elif side == "enemies":
		base_crit += enemies_normal_attack_crit_rate_bonus
	if typeof(attacker) == TYPE_DICTIONARY and attacker.has("__skill_crit_bonus"):
		base_crit += float(attacker["__skill_crit_bonus"])
	base_crit = clamp(base_crit, 0.0, 1.0)
	var is_crit: bool = rng.randf() < base_crit
	if is_crit:
		base = int(round(base * 1.5))

	# 团队平均护盾减伤
	base = max(0, base - int(round(reduce_avg)))
	return {"damage": base, "is_crit": is_crit}

func _apply_battle_start_passives(team: Array, side: String) -> void:
	# 处理被动：凝心决
	for m in team:
		var passives: Array = _safe_get(m, "passives", []) as Array
		for p in passives:
			var pid: String = (p if typeof(p) == TYPE_STRING else String(_safe_get(p, "id", "")))
			if String(pid) == "skill.hero.ningxin_jue.v1":
				# 技能暴击率+20%
				var prev: float = float(_safe_get(m, "__skill_crit_bonus", 0.0))
				_safe_set(m, "__skill_crit_bonus", prev + 0.20)
				# 全队普攻暴击率+10%
				if side == "heroes":
					heroes_normal_attack_crit_rate_bonus += 0.10
				elif side == "enemies":
					enemies_normal_attack_crit_rate_bonus += 0.10
				_log("[TBM] 被动触发：%s 的‘凝心决’提供暴击加成" % [_member_name(m)])

func _apply_damage(target, amount: int):
	var old_hp = _safe_get(target, "current_hp", 10)
	var new_hp = max(0, old_hp - max(0, amount))
	_safe_set(target, "current_hp", new_hp)
	
	# 添加血量变化日志
	var max_hp = _safe_get(target, "max_hp", old_hp)
	_log("[TBM] 💔 %s 受到 %d 伤害，血量：%d/%d -> %d/%d" % [
		_member_name(target), amount, old_hp, max_hp, new_hp, max_hp
	])

# ---- 队伍级聚合辅助函数 ----
func _team_total_hp(team: Array) -> int:
	var total: int = 0
	for m in team:
		total += int(_safe_get(m, "current_hp", 0))
	return total

func _team_total_attack(team: Array) -> int:
	var total: int = 0
	for m in team:
		total += int(_safe_get(m, "attack", 0))
	return total

func _apply_team_damage_group(attacker, defenders_alive: Array, amount: int, is_crit: bool):
	# 将整体伤害按前排优先顺序在防守方队伍中顺次分配
	var damage_left = max(0, amount)
	if damage_left == 0 or defenders_alive.size() == 0:
		return
	defenders_alive.sort_custom(func(a, b): return _get_position(a) < _get_position(b))
	for tgt in defenders_alive:
		if damage_left <= 0:
			break
		var before_hp = int(_safe_get(tgt, "current_hp", 0))
		var dealt = min(before_hp, damage_left)
		if dealt > 0:
			_safe_set(tgt, "current_hp", before_hp - dealt)
			emit_signal("damage_dealt", attacker, tgt, dealt, is_crit)
			var max_hp = int(_safe_get(tgt, "max_hp", before_hp))
			_log("[TBM] 💔 团队受伤：%s 受到 %d 伤害，血量：%d/%d -> %d/%d" % [
				_member_name(tgt), dealt, before_hp, max_hp, before_hp - dealt, max_hp
			])
			damage_left -= dealt
	# 如果伤害溢出，表示全队阵亡，剩余伤害无需处理

# ---- 队伍HP池：当前读写与最大值 ----
func _team_total_max_hp(team: Array) -> int:
	var total: int = 0
	for m in team:
		total += int(_safe_get(m, "max_hp", _safe_get(m, "current_hp", 0)))
	return total

func _get_team_hp_current(team: Array) -> int:
	return hero_team_hp_current if team == hero_team else enemy_team_hp_current

func _get_team_hp_max(team: Array) -> int:
	return hero_team_hp_max if team == hero_team else enemy_team_hp_max

func _set_team_hp_current(team: Array, value: int):
	if team == hero_team:
		hero_team_hp_current = max(0, min(hero_team_hp_max, value))
	else:
		enemy_team_hp_current = max(0, min(enemy_team_hp_max, value))

# ---- 队伍HP池：应用整体伤害（不在成员间分配） ----
func _apply_team_pool_damage(attacking_team: Array, defending_team: Array, amount: int, is_crit: bool):
	var before = _get_team_hp_current(defending_team)
	var dmg = max(0, amount)
	var after = max(0, before - dmg)
	
	# 选择一个目标用于动画展示
	var target = null
	var candidates = defending_team
	if candidates.size() > 0:
		target = candidates[rng.randi_range(0, candidates.size()-1)]
	
	# 发射伤害信号（用于动画）- 传递整个攻击队伍信息
	if target != null:
		emit_signal("damage_dealt", attacking_team, target, dmg, is_crit)
		
		# 等待动画完成后再应用血量变化：优先等待动画控制器“空闲”而非固定时延
		if battle_animation_controller:
			if battle_animation_controller.has_method("is_animation_playing"):
				# 给一帧时间启动动画
				await get_tree().process_frame
				var waited: float = 0.0
				var step: float = 0.05
				var max_wait: float = 3.0
				while battle_animation_controller.is_animation_playing() and waited < max_wait:
					await get_tree().create_timer(step).timeout
					waited += step
				if waited >= max_wait:
					print("[TBM] Warn: 等待动画超时，继续结算")
			else:
				# 无法探测动画状态时，保底短暂等待
				await get_tree().create_timer(0.5).timeout
	
	# 注意：血量更新现在由 BattleAnimationController 处理
	# 这里只记录日志和发射信号
	var after_hp = _get_team_hp_current(defending_team)  # 获取更新后的血量
	var team_label := ("英雄队伍" if defending_team == hero_team else "敌方队伍")
	_log("[TBM] 💔 %s 受到 %d 伤害，队伍HP：%d/%d -> %d/%d" % [
		team_label, dmg, before, _get_team_hp_max(defending_team), after_hp, _get_team_hp_max(defending_team)
	])

	# 发射队伍HP变更信号（用于其他系统监听）
	var side := ("heroes" if defending_team == hero_team else "enemies")
	emit_signal("team_hp_changed", side, after_hp, _get_team_hp_max(defending_team))

func _heal_member(member, amount: int):
	var hp = _safe_get(member, "current_hp", 0)
	var max_hp = _safe_get(member, "max_hp", hp)
	hp = min(max_hp, hp + max(0, amount))
	_safe_set(member, "current_hp", hp)

func _member_name(member) -> String:
	return str(_safe_get(member, "name", "成员"))

func _collect_alive(team: Array) -> Array:
	# 战斗内不按成员血量判定；队伍HP池>0视为存活，返回团队数组用于后续流程
	if _get_team_hp_current(team) > 0:
		return team
	return []

func _is_alive(member) -> bool:
	return _safe_get(member, "current_hp", 1) > 0

func _check_battle_end() -> Variant:
	"""
	若任一方队伍HP池归零，返回 { result:String, stats:Dictionary }；否则返回 null。
	result: "heroes_win" | "enemies_win"
	stats: { turns:int, hero_team_hp:int, enemy_team_hp:int }
	"""
	var heroes_hp = hero_team_hp_current
	var enemies_hp = enemy_team_hp_current
	if enemies_hp <= 0:
		return {
			"result": "heroes_win",
			"stats": {"turns": turn_index, "hero_team_hp": heroes_hp, "enemy_team_hp": enemies_hp}
		}
	if heroes_hp <= 0:
		return {
			"result": "enemies_win",
			"stats": {"turns": turn_index, "hero_team_hp": heroes_hp, "enemy_team_hp": enemies_hp}
		}
	return null

func _finish_battle(result: String, stats: Dictionary):
	battle_active = false
	emit_signal("battle_finished", result, stats)
	print("[TBM] Battle finished signal emitted: ", result, " ", stats)
	_log("[TBM] Battle finished: %s, stats=%s" % [result, str(stats)])

func _log(text: String):
	emit_signal("log_message", text)
	# 为战斗记录添加1秒间隔，让玩家能够阅读
	if text.contains("伤害") or text.contains("攻击") or text.contains("技能") or text.contains("Turn"):
		await get_tree().create_timer(1.0).timeout

func _safe_get(obj, key: String, default):
	if typeof(obj) == TYPE_DICTIONARY:
		return obj.get(key, default)
	if obj != null and obj.has_method("get"):
		return obj.get(key) if obj.get(key) != null else default
	return default

func _safe_set(obj, key: String, value):
	if typeof(obj) == TYPE_DICTIONARY:
		obj[key] = value
	elif obj != null and obj.has_method("set"):
		obj.set(key, value)

# ---- 附加：被动/技能/状态工具 ----

func _has_skill(member, skill_id: String) -> bool:
	var skills = _safe_get(member, "skills", [])
	for s in skills:
		var id = (s if typeof(s) == TYPE_STRING else _safe_get(s, "id", ""))
		if id == skill_id:
			return true
	return false

# ---- 技能次数限制：辅助函数 ----
func _reset_skill_usage_for_team(team: Array):
	for m in team:
		_safe_set(m, "__skill_usage__", {})

func _get_skill_limit(member, skill_id: String) -> int:
	var limit = _default_skill_limit
	var skills = _safe_get(member, "skills", [])
	for s in skills:
		var id = (s if typeof(s) == TYPE_STRING else _safe_get(s, "id", ""))
		if id == skill_id:
			var explicit = (0 if typeof(s) == TYPE_STRING else int(_safe_get(s, "limit", 0)))
			if explicit > 0:
				limit = explicit
			break
	var global_limits = _safe_get(options, "skill_limits", {})
	if typeof(global_limits) == TYPE_DICTIONARY and global_limits.has(skill_id):
		var g = int(global_limits[skill_id])
		if g > 0:
			limit = g
	return limit

func _get_skill_usage(member, skill_id: String) -> int:
	var usage = _safe_get(member, "__skill_usage__", {})
	return int(usage.get(skill_id, 0))

func _can_use_skill(member, skill_id: String) -> bool:
	return _get_skill_usage(member, skill_id) < _get_skill_limit(member, skill_id)

func _register_skill_use(member, skill_id: String):
	var usage = _safe_get(member, "__skill_usage__", {})
	var count = int(usage.get(skill_id, 0)) + 1
	usage[skill_id] = count
	_safe_set(member, "__skill_usage__", usage)

func _get_triggerable_skill_ids(member) -> Array:
	var ids: Array = []
	var skills = _safe_get(member, "skills", [])
	for s in skills:
		var id = (s if typeof(s) == TYPE_STRING else _safe_get(s, "id", ""))
		if id == "":
			continue
		if _can_use_skill(member, id):
			ids.append(id)
	return ids

func _has_passive(member, passive_id: String) -> bool:
	var arr = _safe_get(member, "passives", [])
	for p in arr:
		var id = (p if typeof(p) == TYPE_STRING else _safe_get(p, "id", ""))
		if id == passive_id:
			return true
	return false

func _get_passive_mods(member) -> Dictionary:
	var atk_bonus = 0
	var def_bonus = 0
	var arr = _safe_get(member, "passives", [])
	var hp = float(_safe_get(member, "current_hp", 1))
	var max_hp = float(max(1, _safe_get(member, "max_hp", 1)))
	var hp_ratio = hp / max_hp
	for p in arr:
		var id = (p if typeof(p) == TYPE_STRING else _safe_get(p, "id", ""))
		var power = (0 if typeof(p) == TYPE_STRING else int(_safe_get(p, "power", 0)))
		match id:
			"tough":
				def_bonus += (power if power != 0 else 1)
			"berserk":
				if hp_ratio < 0.5:
					atk_bonus += (power if power != 0 else 2)
			_:
				pass
	return {"atk": atk_bonus, "def": def_bonus}

func _get_status_mods(member) -> Dictionary:
	var atk_bonus = 0
	var def_bonus = 0
	var arr = _safe_get(member, "status_effects", [])
	for e in arr:
		var id = (e if typeof(e) == TYPE_STRING else _safe_get(e, "id", ""))
		var power = (0 if typeof(e) == TYPE_STRING else int(_safe_get(e, "power", 0)))
		match id:
			"attack_up":
				atk_bonus += (power if power != 0 else 2)
			"defense_down":
				def_bonus -= (power if power != 0 else 2)
			_:
				pass
	return {"atk": atk_bonus, "def": def_bonus}

func _get_incoming_damage_reduction(member) -> int:
	var reduce = 0
	var arr = _safe_get(member, "status_effects", [])
	for e in arr:
		var id = (e if typeof(e) == TYPE_STRING else _safe_get(e, "id", ""))
		var power = (0 if typeof(e) == TYPE_STRING else int(_safe_get(e, "power", 0)))
		match id:
			"shield":
				reduce += (power if power != 0 else 2)
			_:
				pass
	return reduce

func _apply_start_of_turn_effects(active_team: Array, opposing_team: Array):
	# 回合开始：应用持续状态（例：中毒/再生），按队伍HP池汇总
	var poison_total = 0
	var regen_total = 0
	if _get_team_hp_current(active_team) <= 0:
		return
	for m in active_team:
		var arr = _safe_get(m, "status_effects", [])
		for e in arr:
			var id = (e if typeof(e) == TYPE_STRING else _safe_get(e, "id", ""))
			var power = (0 if typeof(e) == TYPE_STRING else int(_safe_get(e, "power", 0)))
			match id:
				"poison":
					poison_total += (power if power != 0 else 2)
				"regen":
					regen_total += (power if power != 0 else 2)
				_:
					pass
	var before = _get_team_hp_current(active_team)
	var maxhp = _get_team_hp_max(active_team)
	var after = clamp(before - poison_total + regen_total, 0, maxhp)
	_set_team_hp_current(active_team, after)
	if poison_total > 0:
		_log("[TBM] 状态[毒] 队伍受到总计 %d 伤害（队伍HP池）" % poison_total)
	if regen_total > 0:
		_log("[TBM] 状态[再生] 队伍恢复总计 %d 生命（队伍HP池）" % regen_total)

# UI/外部查询便利方法
func get_alive_counts() -> Dictionary:
	return {
		"heroes": _collect_alive(hero_team).size(),
		"enemies": _collect_alive(enemy_team).size()
	}

func is_battle_active() -> bool:
	return battle_active

func is_battle_finished() -> bool:
	return not battle_active
func _team_total_initiative(team: Array) -> int:
	var total := 0
	for m in team:
		var v := 0
		if typeof(m) == TYPE_DICTIONARY:
			if m.has("initiative"):
				v = int(m["initiative"]) 
			elif m.has("speed"):
				v = int(m["speed"]) # 兼容旧字段
		elif typeof(m) == TYPE_OBJECT:
			if m.has_variable("initiative"):
				v = int(m.initiative)
			elif m.has_variable("speed"):
				v = int(m.speed)
		total += v
	return total
