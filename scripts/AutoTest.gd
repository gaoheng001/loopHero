# AutoTest.gd
# 统一无头测试入口：支持命令行标签与阶段过滤（e2e/full/phaseX）
extends SceneTree
## 动态加载测试模块，避免编译期预载失败

func _init():
    print("[AutoTest] 启动统一无头测试入口...")

    # 解析命令行参数
    var args = OS.get_cmdline_args()
    var tags: PackedStringArray = PackedStringArray()
    var scenario := "e2e"  # 可选: e2e / full
    for i in range(args.size()):
        var a = args[i]
        if a.begins_with("--tags="):
            tags = a.substr(7).split(",")
        elif a == "--tags" and i + 1 < args.size():
            tags = args[i + 1].split(",")
        elif a.begins_with("--scenario="):
            scenario = a.substr(11)
        elif a == "--scenario" and i + 1 < args.size():
            scenario = args[i + 1]
    # 环境变量兜底（在某些环境下命令行参数无法透传）
    if tags.size() == 0:
        var env_tags = OS.get_environment("AUTOTEST_TAGS")
        if env_tags != "":
            tags = env_tags.split(",")
    if scenario == "e2e":
        var env_scenario = OS.get_environment("AUTOTEST_SCENARIO")
        if env_scenario != "":
            scenario = env_scenario
    print("[AutoTest] 参数解析: scenario=%s, tags=%s" % [scenario, str(tags)])

    # 加载主场景
    var main_scene: PackedScene = load("res://scenes/MainGame.tscn")
    var main_instance = main_scene.instantiate()

    # 添加到场景树并设置为当前场景
    root.add_child(main_instance)
    current_scene = main_instance
    print("[AutoTest] 主场景已加载并设置为当前场景")

    # 等待两帧保证所有节点初始化完成
    await process_frame
    await process_frame

    var all_passed := true

    # 如果是完整场景验证，先跑 e2e 启动流程
    if scenario == "full" and tags.size() == 0:
        all_passed = await _run_e2e_start(main_instance) and all_passed

    # 根据标签选择阶段测试
    if (tags.find("phase2") != -1) or (scenario == "full"):
        print("[AutoTest] 执行 Phase2 测试模块")
        var phase2_script = load("res://scripts/tests/Phase2Tests.gd")
        var ok = await phase2_script.new().run(self, main_instance)
        all_passed = all_passed and ok

    # 增强版 Phase2 测试，保持向后兼容
    if (tags.find("phase2_enhanced") != -1):
        print("[AutoTest] 执行 Phase2 增强测试模块")
        var phase2_enhanced_script = load("res://scripts/tests/Phase2EnhancedTests.gd")
        if phase2_enhanced_script:
            # 期望该脚本提供 Node 并实现 run(tree, main_instance)
            var runner = phase2_enhanced_script.new()
            if runner and runner.has_method("run"):
                var ok2 = await runner.run(self, main_instance)
                all_passed = all_passed and ok2
            else:
                print("[AutoTest][WARN] Phase2EnhancedTests 未提供可调用的 run 方法，跳过")

    # 若无标签（默认），执行简单 e2e 启动验证
    if tags.size() == 0 and scenario == "e2e":
        all_passed = await _run_e2e_start(main_instance) and all_passed

    print("[AutoTest] 测试完成，结果:", all_passed)
    quit(0 if all_passed else 1)

func _run_e2e_start(main_instance) -> bool:
    # 触发开始循环（优先调用根控制器的入口方法）
    paused = false
    if main_instance.has_method("_on_start_button_pressed"):
        print("[AutoTest] 触发 MainGameController._on_start_button_pressed()")
        main_instance._on_start_button_pressed()
    else:
        var start_button = main_instance.get_node_or_null("UI/MainUI/BottomPanel/ControlsContainer/StartButton")
        if start_button:
            print("[AutoTest] 触发 StartButton pressed 信号")
            start_button.emit_signal("pressed")
        else:
            print("[AutoTest] 警告: 未找到开始按钮或入口方法，e2e 启动可能无法继续")

    # 观察关键流程：等待卡牌选择窗口出现（最多等待10秒）
    var card_selection = main_instance.get_node_or_null("UI/CardSelectionWindow")
    var visible_seen := false
    var elapsed := 0.0
    while elapsed < 10.0:
        await create_timer(0.5).timeout
        elapsed += 0.5
        if card_selection and card_selection.visible:
            visible_seen = true
            break

    print("[AutoTest] 卡牌选择窗口可见:", visible_seen)
    # 额外等待1秒以确保日志/状态输出完整
    await create_timer(1.0).timeout
    return visible_seen