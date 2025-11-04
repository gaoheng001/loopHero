extends SceneTree

# 实时游戏测试：监控敌方受击闪烁动画
# 这个脚本会在游戏运行时实时监控敌方受击闪烁的调用情况

var main_scene
var animation_controller
var enemy_animators = []
var monitoring_active = false
var flash_call_count = 0

func _init():
    print("[实时敌方闪烁监控] 开始初始化...")
    
    # 加载主场景（游戏入口）
    var main_scene_path = "res://scenes/MainGame.tscn"
    var main_scene_resource = load(main_scene_path)
    if not main_scene_resource:
        print("[实时敌方闪烁监控] ❌ 无法加载主场景: %s" % main_scene_path)
        quit()
        return
    
    main_scene = main_scene_resource.instantiate()
    root.add_child(main_scene)
    current_scene = main_scene
    
    # 等待游戏初始化完成后开始监控
    _deferred_start()

func _find_node_by_name(parent: Node, target_name: String) -> Node:
    """递归查找指定名称的节点"""
    if parent.name == target_name:
        return parent
    
    for child in parent.get_children():
        var result = _find_node_by_name(child, target_name)
        if result:
            return result
    
    return null

func _deferred_start():
    await create_timer(5.0).timeout
    start_monitoring()

func start_monitoring():
    """开始监控敌方受击闪烁"""
    print("[实时敌方闪烁监控] 开始监控敌方受击闪烁...")
    
    # 查找BattleAnimationController（在场景树中递归查找）
    animation_controller = _find_node_by_name(root, "BattleAnimationController")
    if not animation_controller:
        print("[实时敌方闪烁监控] ❌ 无法找到BattleAnimationController")
        return
    print("[实时敌方闪烁监控] ✓ BattleAnimationController找到")
    
    # 获取敌方动画器数组
    if animation_controller.has_method("get"):
        var anims = animation_controller.get("enemy_animators")
        if anims:
            enemy_animators = anims
            print("[实时敌方闪烁监控] ✓ 获取到%d个敌方动画器" % enemy_animators.size())
        else:
            print("[实时敌方闪烁监控] ❌ enemy_animators为空或不可访问")
            return
    else:
        print("[实时敌方闪烁监控] ❌ BattleAnimationController不支持属性访问")
        return
    
    # 为每个敌方动画器添加监控
    for i in range(enemy_animators.size()):
        var animator = enemy_animators[i]
        if animator and is_instance_valid(animator):
            _connect_flash_signal(animator, i)
    
    # 监控BattleAnimationController的play_team_damage_animation调用
    _monitor_team_damage_animation()
    
    monitoring_active = true
    print("[实时敌方闪烁监控] ✓ 监控已激活，等待战斗事件...")

func _connect_flash_signal(animator, index: int):
    """连接动画完成信号以统计受击闪烁完成次数"""
    if animator.has_signal("animation_completed"):
        animator.animation_completed.connect(_on_animator_animation_completed.bind(index))
        print("[实时敌方闪烁监控] ✓ 已连接敌方动画器%d的animation_completed信号" % index)
    else:
        print("[实时敌方闪烁监控] ❌ 敌方动画器%d不存在animation_completed信号" % index)

func _on_animator_animation_completed(animation_type: String, index: int):
    if animation_type == "hit_flash":
        flash_call_count += 1
        var modulate = null
        var animator = enemy_animators[index]
        if animator and animator.character_sprite:
            modulate = animator.character_sprite.modulate
        print("[实时敌方闪烁监控] 🔥 敌方动画器%d完成受击闪烁。累计: %d，当前modulate: %s" % [index, flash_call_count, str(modulate)])

func _monitor_team_damage_animation():
    """监控play_team_damage_animation的调用"""
    if not animation_controller.has_method("play_team_damage_animation"):
        print("[实时敌方闪烁监控] ❌ BattleAnimationController没有play_team_damage_animation方法")
        return
    
    print("[实时敌方闪烁监控] ✓ 开始监控play_team_damage_animation调用")
 
func _output_monitoring_status():
    """输出监控状态"""
    print("[实时敌方闪烁监控] 📈 监控状态 - 闪烁调用次数: %d" % flash_call_count)
    
    # 检查敌方动画器状态
    for i in range(enemy_animators.size()):
        var animator = enemy_animators[i]
        if animator and is_instance_valid(animator) and animator.character_sprite:
            var modulate = animator.character_sprite.modulate
            print("[实时敌方闪烁监控] 📊 敌方%d当前modulate: %s" % [i, modulate])

func _input(event):
    """处理输入事件"""
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F1:
            # F1键：手动触发敌方受击测试
            _trigger_manual_enemy_hit_test()
        elif event.keycode == KEY_F2:
            # F2键：输出详细状态
            _output_detailed_status()

func _trigger_manual_enemy_hit_test():
    """手动触发敌方受击测试"""
    print("[实时敌方闪烁监控] 🔧 手动触发敌方受击测试...")
    
    if animation_controller and animation_controller.has_method("play_team_damage_animation"):
        print("[实时敌方闪烁监控] 调用play_team_damage_animation('enemies', false)...")
        animation_controller.play_team_damage_animation("enemies", false)
        
        await create_timer(1.0).timeout
        
        print("[实时敌方闪烁监控] 调用play_team_damage_animation('enemies', true)...")
        animation_controller.play_team_damage_animation("enemies", true)
    else:
        print("[实时敌方闪烁监控] ❌ 无法调用play_team_damage_animation")

func _output_detailed_status():
    """输出详细状态信息"""
    print("[实时敌方闪烁监控] 📋 详细状态报告:")
    print("  - 监控激活: %s" % monitoring_active)
    print("  - 闪烁调用次数: %d" % flash_call_count)
    print("  - 敌方动画器数量: %d" % enemy_animators.size())
    
    if animation_controller:
        print("  - BattleAnimationController存在: ✓")
        if animation_controller.has_method("play_team_damage_animation"):
            print("  - play_team_damage_animation方法存在: ✓")
        else:
            print("  - play_team_damage_animation方法存在: ❌")
    else:
        print("  - BattleAnimationController存在: ❌")


func _process(delta):
    # 每5秒输出一次状态
    if monitoring_active and int(Time.get_ticks_msec() / 1000.0) % 5 == 0:
        _output_monitoring_status()

func _finalize():
    """清理资源"""
    monitoring_active = false
    print("[实时敌方闪烁监控] 监控已停止")