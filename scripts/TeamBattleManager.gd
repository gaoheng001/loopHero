extends Node
class_name TeamBattleManager

# 冒险与挖矿风格：队伍整体回合战斗管理器（Alpha骨架）

signal battle_started(hero_team, enemy_team)
signal battle_finished(result, stats)
signal turn_started(turn_index, acting_side)
signal turn_finished(turn_index)
signal skill_triggered(user, skill_id, context)
signal damage_dealt(source, target, amount, is_crit)
signal log_message(text)

var hero_team: Array = []
var enemy_team: Array = []
var battle_active: bool = false
var turn_index: int = 0
var options: Dictionary = {}
var rng := RandomNumberGenerator.new()

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
    _log("[TBM] Battle started: heroes=%d, enemies=%d" % [hero_team.size(), enemy_team.size()])
    emit_signal("battle_started", hero_team, enemy_team)

    # 若一方为空，直接结束
    var ended := _check_battle_end()
    if ended != null:
        _finish_battle(ended.result, ended.stats)

func execute_turn():
    """
    执行一个整体回合（英雄方整体行动 -> 敌方整体行动）。
    若在任一阶段结束后出现团灭，则立即结束战斗。
    """
    if not battle_active:
        return

    turn_index += 1
    emit_signal("turn_started", turn_index, "heroes")
    _log("[TBM] Turn %d started (heroes)" % turn_index)
    _execute_team_phase(hero_team, enemy_team)

    var ended := _check_battle_end()
    if ended != null:
        _finish_battle(ended.result, ended.stats)
        return

    emit_signal("turn_started", turn_index, "enemies")
    _log("[TBM] Turn %d continued (enemies)" % turn_index)
    _execute_team_phase(enemy_team, hero_team)

    ended = _check_battle_end()
    if ended != null:
        _finish_battle(ended.result, ended.stats)
        return

    emit_signal("turn_finished", turn_index)
    _log("[TBM] Turn %d finished" % turn_index)

func run_to_completion(max_turns: int = 100):
    """
    便捷方法：在不接UI的情况下，直接跑到战斗结束或达到最大回合。
    """
    var turns := 0
    while battle_active and turns < max_turns:
        execute_turn()
        turns += 1

func _execute_team_phase(attacking_team: Array, defending_team: Array):
    """
    整体行动阶段：队伍成员依次行动（占位实现）。
    目前实现为：每个存活成员对随机的存活敌人进行一次基础攻击。
    未来将接入技能触发、被动效果与状态系统。
    """
    var defenders_alive := _collect_alive(defending_team)
    if defenders_alive.size() == 0:
        return

    for attacker in _collect_alive(attacking_team):
        # TODO: 技能前置触发（如出手前的被动）
        if defenders_alive.size() == 0:
            break
        var target := defenders_alive[rng.randi_range(0, defenders_alive.size()-1)]
        var dmg_info := _calc_damage(attacker, target)
        _apply_damage(target, dmg_info.damage)
        emit_signal("damage_dealt", attacker, target, dmg_info.damage, dmg_info.is_crit)
        _log("[TBM] %s -> %s : %d%s" % [
            _member_name(attacker), _member_name(target), dmg_info.damage, ("*" if dmg_info.is_crit else "")
        ])

        # 目标阵亡后从集合中移除
        if not _is_alive(target):
            defenders_alive.erase(target)

        # TODO: 技能后置触发（如击杀触发、连击等）

func _calc_damage(attacker, target) -> Dictionary:
    """
    基础伤害占位：
      damage = max(1, (attacker.attack - target.defense))，含简易暴击（10%）。
    字段缺失时采用默认值。
    返回 { damage:int, is_crit:bool }。
    """
    var atk := _safe_get(attacker, "attack", 10)
    var def := _safe_get(target, "defense", 5)
    var base := max(1, atk - def)
    var is_crit := rng.randf() < 0.1
    if is_crit:
        base = int(round(base * 1.5))
    return {"damage": base, "is_crit": is_crit}

func _apply_damage(target, amount: int):
    var hp := _safe_get(target, "current_hp", 10)
    hp = max(0, hp - max(0, amount))
    _safe_set(target, "current_hp", hp)

func _member_name(member) -> String:
    return str(_safe_get(member, "name", "成员"))

func _collect_alive(team: Array) -> Array:
    var arr: Array = []
    for m in team:
        if _is_alive(m):
            arr.append(m)
    return arr

func _is_alive(member) -> bool:
    return _safe_get(member, "current_hp", 1) > 0

func _check_battle_end() -> Variant:
    """
    若一方全灭，返回 { result:String, stats:Dictionary }；否则返回 null。
    result: "heroes_win" | "enemies_win"
    stats: { turns:int, hero_alive:int, enemy_alive:int }
    """
    var heroes_alive := _collect_alive(hero_team).size()
    var enemies_alive := _collect_alive(enemy_team).size()
    if enemies_alive == 0:
        return {
            "result": "heroes_win",
            "stats": {"turns": turn_index, "hero_alive": heroes_alive, "enemy_alive": enemies_alive}
        }
    if heroes_alive == 0:
        return {
            "result": "enemies_win",
            "stats": {"turns": turn_index, "hero_alive": heroes_alive, "enemy_alive": enemies_alive}
        }
    return null

func _finish_battle(result: String, stats: Dictionary):
    battle_active = false
    emit_signal("battle_finished", result, stats)
    _log("[TBM] Battle finished: %s, stats=%s" % [result, str(stats)])

func _log(text: String):
    emit_signal("log_message", text)

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