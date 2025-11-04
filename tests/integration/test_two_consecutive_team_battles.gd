# test_two_consecutive_team_battles.gd
# 连战自测：验证两场连续队伍战斗之间动画锁/队列/受击冷却是否被正确重置
extends SceneTree

func _init():
    print("[TwoBattleTest] 开始两场连战状态残留验证")

    var scene: PackedScene = load("res://scenes/MainGame.tscn")
    var main_instance = scene.instantiate()
    root.add_child(main_instance)
    await create_timer(0.6).timeout

    var bw = main_instance.get_node_or_null("UI/BattleWindow")
    if bw == null:
        print("[TwoBattleTest] 未找到 BattleWindow")
        quit(1)
        return

    # 第一场战斗阵容
    var heroes1 := [
        {"name": "战士", "current_hp": 42, "max_hp": 42, "attack": 12, "defense": 4, "skills": ["power_strike"], "passives": ["tough"], "status_effects": ["attack_up"]},
        {"name": "盗贼", "current_hp": 34, "max_hp": 34, "attack": 11, "defense": 3, "skills": ["multi_strike"], "passives": ["lifesteal"], "status_effects": []},
        {"name": "法师", "current_hp": 28, "max_hp": 28, "attack": 13, "defense": 2, "skills": ["power_strike"], "passives": ["berserk"], "status_effects": ["regen"]},
    ]
    var enemies1 := [
        {"name": "枯骨", "current_hp": 30, "max_hp": 30, "attack": 9, "defense": 2, "skills": [], "passives": [], "status_effects": ["poison"]},
        {"name": "蛛母幼体", "current_hp": 33, "max_hp": 33, "attack": 11, "defense": 3, "skills": [], "passives": ["tough"], "status_effects": ["shield"]},
        {"name": "石像鬼", "current_hp": 26, "max_hp": 26, "attack": 10, "defense": 3, "skills": [], "passives": [], "status_effects": []},
    ]

    # 启动第一场队伍战斗
    if bw.has_method("show_team_battle"):
        bw.show_team_battle(heroes1, enemies1)
    else:
        print("[TwoBattleTest] BattleWindow 缺少 show_team_battle 方法")
        quit(1)
        return

    await process_frame
    var tbm = bw.team_battle_manager
    var bac = bw.get_node_or_null("BattleAnimationController")

    # 等待第一场战斗结束，最多 12 秒
    var finished1 := false
    for i in range(24): # 24 * 0.5s = 12s
        await create_timer(0.5).timeout
        if tbm and tbm.has_method("is_battle_active") and (not tbm.is_battle_active()):
            finished1 = true
            break

    print("[TwoBattleTest] 第一场结束 finished=", finished1)

    if bac:
        var lock1 = bac.get("_animation_lock")
        var queue1 = bac.get("pending_animations")
        var processing1 = bac.get("is_processing_queue")
        var cd1 = bac.get("last_damage_animation_time")
        var cd1_len := 0
        if typeof(cd1) == TYPE_DICTIONARY:
            cd1_len = (cd1.keys() as Array).size()
        print("[TwoBattleTest] 第一场后状态: lock=", lock1, " queue_len=", (queue1 as Array).size(), " processing=", processing1, " cd_keys=", cd1_len)

    # 第二场战斗阵容（不同敌人）
    var heroes2 := [
        {"name": "骑士", "current_hp": 40, "max_hp": 40, "attack": 14, "defense": 5, "skills": ["shield_bash"], "passives": ["guard"], "status_effects": []},
        {"name": "游侠", "current_hp": 32, "max_hp": 32, "attack": 12, "defense": 2, "skills": ["power_strike"], "passives": [], "status_effects": ["haste"]},
        {"name": "德鲁伊", "current_hp": 30, "max_hp": 30, "attack": 10, "defense": 3, "skills": ["heal"], "passives": [], "status_effects": ["regen"]},
    ]
    var enemies2 := [
        {"name": "哥布林", "current_hp": 28, "max_hp": 28, "attack": 10, "defense": 2, "skills": [], "passives": [], "status_effects": []},
        {"name": "巨鼠", "current_hp": 35, "max_hp": 35, "attack": 11, "defense": 3, "skills": [], "passives": [], "status_effects": ["poison"]},
        {"name": "幽魂", "current_hp": 24, "max_hp": 24, "attack": 9, "defense": 1, "skills": [], "passives": [], "status_effects": []},
    ]

    # 启动第二场队伍战斗
    bw.show_team_battle(heroes2, enemies2)
    await process_frame
    await create_timer(0.5).timeout

    var bac2 = bw.get_node_or_null("BattleAnimationController")
    var ok := true
    if bac2:
        var lock2 = bac2.get("_animation_lock")
        var queue2 = bac2.get("pending_animations")
        var processing2 = bac2.get("is_processing_queue")
        var cd2 = bac2.get("last_damage_animation_time")
        var cd2_len := 0
        if typeof(cd2) == TYPE_DICTIONARY:
            cd2_len = (cd2.keys() as Array).size()
        print("[TwoBattleTest] 第二场开局状态: lock=", lock2, " queue_len=", (queue2 as Array).size(), " processing=", processing2, " cd_keys=", cd2_len)
        ok = (lock2 == false and (queue2 as Array).size() == 0 and processing2 == false and cd2_len == 0)
    else:
        print("[TwoBattleTest] ✗ 未找到 BattleAnimationController")
        ok = false

    print("[TwoBattleTest] 连战状态重置验证结果:", ok)
    quit(0 if ok else 1)