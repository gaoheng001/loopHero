extends SceneTree

func _init():
    print("=== 开始测试战斗动画播放效果 ===")

    var battle_window_scene = preload("res://scenes/BattleWindow.tscn")
    var battle_window = battle_window_scene.instantiate()
    root.add_child(battle_window)

    print("[测试] BattleWindow实例创建成功:", battle_window)
    print("[测试] BattleWindow已添加到场景树")

    for i in range(5):
        await process_frame

    print("[测试] 等待_ready方法执行完成")

    var team_manager = TeamBattleManager.new()
    team_manager.hero_team = [
        {"id": "hero1", "name": "英雄1", "current_hp": 100, "max_hp": 100, "attack": 20, "defense": 10},
        {"id": "hero2", "name": "英雄2", "current_hp": 80, "max_hp": 80, "attack": 15, "defense": 8}
    ]
    team_manager.enemy_team = [
        {"id": "enemy1", "name": "敌人1", "current_hp": 60, "max_hp": 60, "attack": 12, "defense": 5},
        {"id": "enemy2", "name": "敌人2", "current_hp": 70, "max_hp": 70, "attack": 18, "defense": 7}
    ]

    if battle_window.has_method("show_team_battle"):
        battle_window.show_team_battle(team_manager.hero_team, team_manager.enemy_team, team_manager)
    else:
        print("[测试] ✗ BattleWindow 未提供 show_team_battle 方法")

    var battle_animation_controller = battle_window.get_node("BattleAnimationController")
    if battle_animation_controller:
        print("[测试] ✓ BattleAnimationController获取成功:", battle_animation_controller)
        if battle_animation_controller.has_method("initialize"):
            battle_animation_controller.initialize(team_manager, battle_window)
        if battle_animation_controller.has_method("_create_character_animators"):
            battle_animation_controller._create_character_animators()

        await process_frame

        print("[测试] 开始测试动画播放...")

        var hero_animators = battle_animation_controller.get("hero_animators")
        var enemy_animators = battle_animation_controller.get("enemy_animators")

        if hero_animators and hero_animators.size() > 0:
            var hero_animator = hero_animators[0]
            print("[测试] 测试英雄攻击动画...")
            if hero_animator.has_method("play_attack_animation"):
                hero_animator.play_attack_animation()
                print("[测试] ✓ 英雄攻击动画调用成功")
            else:
                print("[测试] ✗ 英雄动画器没有找到play_attack_animation方法")
        else:
            print("[测试] ✗ 没有找到英雄动画器")

        await create_timer(2.0).timeout

        if enemy_animators and enemy_animators.size() > 0:
            var enemy_animator = enemy_animators[0]
            print("[测试] 测试敌人受伤动画...")
            if enemy_animator.has_method("play_damage_animation"):
                enemy_animator.play_damage_animation(25, false)
                print("[测试] ✓ 敌人受伤动画调用成功")
            else:
                print("[测试] ✗ 敌人动画器没有找到play_damage_animation方法")
        else:
            print("[测试] ✗ 没有找到敌人动画器")

        await create_timer(2.0).timeout

        if enemy_animators and enemy_animators.size() > 0:
            var enemy_animator2 = enemy_animators[0]
            print("[测试] 测试敌人死亡动画...")
            if enemy_animator2.has_method("play_death_animation"):
                enemy_animator2.play_death_animation()
                print("[测试] ✓ 敌人死亡动画调用成功")
            else:
                print("[测试] ✗ 敌人动画器没有找到play_death_animation方法")
        else:
            print("[测试] ✗ 没有找到敌人动画器")

        await create_timer(2.0).timeout

        print("[测试] 测试动画速度控制...")
        if battle_animation_controller.has_method("set_animation_speed"):
            battle_animation_controller.set_animation_speed(2.0)
            print("[测试] ✓ 设置动画速度为2.0倍")
            if hero_animators and hero_animators.size() > 1:
                var hero_animator2b = hero_animators[1]
                if hero_animator2b.has_method("play_attack_animation"):
                    hero_animator2b.play_attack_animation()
                    print("[测试] ✓ 2倍速攻击动画调用成功")
        else:
            print("[测试] ✗ 没有找到set_animation_speed方法")

        await create_timer(1.0).timeout

        print("[测试] 测试动画完成信号...")
        if battle_animation_controller.has_signal("character_animation_completed"):
            print("[测试] ✓ 找到character_animation_completed信号")
            battle_animation_controller.character_animation_completed.connect(_on_animation_completed)
            if hero_animators and hero_animators.size() > 0:
                var hero_animator3 = hero_animators[0]
                if hero_animator3.has_method("play_attack_animation"):
                    hero_animator3.play_attack_animation()
                    print("[测试] 播放动画并等待完成信号...")
                    await create_timer(3.0).timeout
        else:
            print("[测试] ✗ 没有找到character_animation_completed信号")
    else:
        print("[测试] ✗ BattleAnimationController获取失败")

    print("=== 动画播放测试完成 ===")
    quit()

func _on_animation_completed(character_id: String, animation_type: String):
    print("[测试] ✓ 收到动画完成信号 - 角色:", character_id, ", 动画类型:", animation_type)