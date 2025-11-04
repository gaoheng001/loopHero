extends Node

func _ready():
    print("[动画匹配测试] 开始测试...")
    await get_tree().create_timer(2.0).timeout

    var bac = _find_battle_animation_controller()
    if not bac:
        print("[动画匹配测试] ✗ 未找到BattleAnimationController")
        return

    var tbm = _find_team_battle_manager()
    if not tbm:
        # 尝试通过 BattleWindow 触发一次队伍战斗来创建 TBM
        var bw = _find_battle_window()
        if bw and bw.has_method("show_team_battle"):
            # 构造最小可用队伍（包含必要字段与唯一id）
            var hero_roster = [
                {"id": "hero_test_1", "name": "测试英雄", "current_hp": 30, "max_hp": 30, "attack": 5, "defense": 1}
            ]
            var enemy_roster = [
                {"id": "enemy_test_1", "name": "测试敌人", "current_hp": 20, "max_hp": 20, "attack": 3, "defense": 0}
            ]
            bw.show_team_battle(hero_roster, enemy_roster)
            # 等待一会儿让TBM创建与信号连接完成
            await get_tree().create_timer(1.0).timeout
            tbm = _find_team_battle_manager()

    if not tbm:
        print("[动画匹配测试] ✗ 未找到TeamBattleManager")
        return

    print("[动画匹配测试] ✓ 找到关键组件")

    # 获取动画器数组
    var hero_animators = bac.get("hero_animators")
    var enemy_animators = bac.get("enemy_animators")

    if not hero_animators or not enemy_animators:
        print("[动画匹配测试] ✗ 动画器数组为空")
        return

    print("[动画匹配测试] 英雄动画器数量: %d" % hero_animators.size())
    print("[动画匹配测试] 敌人动画器数量: %d" % enemy_animators.size())

    # 获取队伍数据
    var hero_team = tbm.get("hero_team")
    var enemy_team = tbm.get("enemy_team")

    if not hero_team or not enemy_team:
        print("[动画匹配测试] ✗ 队伍数据为空")
        return

    print("[动画匹配测试] 英雄队伍数量: %d" % hero_team.size())
    print("[动画匹配测试] 敌人队伍数量: %d" % enemy_team.size())

    # 测试英雄匹配
    print("\n=== 测试英雄匹配 ===")
    for i in range(hero_team.size()):
        var hero_data = hero_team[i]
        print("[动画匹配测试] 测试英雄[%d]: name='%s', id='%s'" % [
            i, hero_data.get("name", ""), hero_data.get("id", "")
        ])

        var found_animator = bac._find_character_animator(hero_data)
        if found_animator:
            print("[动画匹配测试] ✓ 找到匹配的英雄动画器")
        else:
            print("[动画匹配测试] ✗ 未找到匹配的英雄动画器")
            _debug_matching_failure(hero_animators, hero_data, "英雄")

    # 测试敌人匹配
    print("\n=== 测试敌人匹配 ===")
    for i in range(enemy_team.size()):
        var enemy_data = enemy_team[i]
        print("[动画匹配测试] 测试敌人[%d]: name='%s', id='%s'" % [
            i, enemy_data.get("name", ""), enemy_data.get("id", "")
        ])

        var found_animator = bac._find_character_animator(enemy_data)
        if found_animator:
            print("[动画匹配测试] ✓ 找到匹配的敌人动画器")
        else:
            print("[动画匹配测试] ✗ 未找到匹配的敌人动画器")
            _debug_matching_failure(enemy_animators, enemy_data, "敌人")

    print("\n[动画匹配测试] 测试完成")

func _debug_matching_failure(animators: Array, test_data: Dictionary, type: String):
    """调试匹配失败的原因"""
    print("  [%s匹配调试] 分析匹配失败原因:" % type)
    for i in range(animators.size()):
        var animator = animators[i]
        if not animator or not is_instance_valid(animator):
            print("    动画器[%d]: 无效" % i)
            continue

        var char_data = animator.get("character_data")
        if not char_data:
            print("    动画器[%d]: 无角色数据" % i)
            continue

        print("    动画器[%d]: name='%s', id='%s'" % [
            i, char_data.get("name", ""), char_data.get("id", "")
        ])

        if animator.has_method("matches_character"):
            var matches = animator.matches_character(test_data)
            print("      匹配结果: %s" % ("✓" if matches else "✗"))

            if not matches:
                # 详细分析
                var animator_id = char_data.get("id", "")
                var test_id = test_data.get("id", "")
                var animator_name = char_data.get("name", "")
                var test_name = test_data.get("name", "")

                print("      ID比较: '%s' vs '%s' = %s" % [
                    animator_id, test_id, "✓" if animator_id == test_id else "✗"
                ])
                print("      名称比较: '%s' vs '%s' = %s" % [
                    animator_name, test_name, "✓" if animator_name == test_name else "✗"
                ])
        else:
            print("      ✗ 没有matches_character方法")

func _find_battle_animation_controller():
    # 首先尝试按名称查找
    var by_name = _recursive_find_node(get_tree().root, "BattleAnimationController")
    if by_name:
        return by_name

    # 然后尝试按脚本查找
    return _recursive_find_by_script(get_tree().root, "BattleAnimationController")

func _find_team_battle_manager():
    # 首先尝试按名称查找
    var by_name = _recursive_find_node(get_tree().root, "TeamBattleManager")
    if by_name:
        return by_name

    # 然后尝试按脚本查找
    return _recursive_find_by_script(get_tree().root, "TeamBattleManager")

func _find_battle_window():
    # 先按名称查找
    var by_name = _recursive_find_node(get_tree().root, "BattleWindow")
    if by_name:
        return by_name
    # 再尝试按脚本查找
    return _recursive_find_by_script(get_tree().root, "BattleWindow")

func _recursive_find_node(node: Node, target_name: String):
    if node.name == target_name:
        return node
    for child in node.get_children():
        var result = _recursive_find_node(child, target_name)
        if result:
            return result
    return null

func _recursive_find_by_script(node: Node, script_class_name: String):
    # 检查节点的脚本
    var script = node.get_script()
    if script:
        var script_path = script.resource_path
        if script_path.ends_with(script_class_name + ".gd"):
            return node

    # 递归检查子节点
    for child in node.get_children():
        var result = _recursive_find_by_script(child, script_class_name)
        if result:
            return result
    return null