extends Button

func _ready():
    pressed.connect(_on_pressed)

func _on_pressed():
    print("[StartButtonProxy] pressed")
    # 解除暂停，确保点击生效
    get_tree().paused = false
    var root = get_tree().current_scene
    if root:
        var sc = root.get_script()
        var rp = ""
        if sc and sc.has_method("get_path"):
            rp = sc.get_path()
        elif sc and sc.has_property("resource_path"):
            rp = sc.resource_path
        print("[StartButtonProxy] root class:", root.get_class(), " script:", sc, " path:", rp)
        # 优先尝试控制器标准入口
        if root.has_method("_on_start_button_pressed"):
            root.call_deferred("_on_start_button_pressed")
        else:
            print("[StartButtonProxy] Controller handler missing, will try fallback if needed")

        # 异步兜底：下一帧检查是否已经启动，否则直接调用管理器
        call_deferred("_ensure_started")
    else:
        print("[StartButtonProxy] ERROR: no current_scene")

func _ensure_started():
    var root = get_tree().current_scene
    if not root:
        print("[StartButtonProxy] ERROR: no current_scene in _ensure_started")
        return
    var lm = root.get_node_or_null("LoopManager")
    var gm = root.get_node_or_null("GameManager")
    var moving := false
    if lm:
        # 直接读取属性值（Godot4中无 has_property），不存在时 get 返回 null
        moving = bool(lm.get("is_moving"))
    if moving:
        print("[StartButtonProxy] Start confirmed: movement already active")
        return
    # 未启动则走兜底
    var started := false
    if gm and gm.has_method("start_new_loop"):
        gm.start_new_loop()
        started = true
    if lm and lm.has_method("start_hero_movement"):
        lm.start_hero_movement()
        started = true
    if started:
        print("[StartButtonProxy] Fallback ensured start via managers")
    else:
        print("[StartButtonProxy] ERROR: fallback failed to start loop/movement")