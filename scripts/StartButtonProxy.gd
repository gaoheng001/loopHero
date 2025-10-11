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
        print("[StartButtonProxy] has _ready:", root.has_method("_ready"), " has start:", root.has_method("_on_start_button_pressed"))
    if root and root.has_method("_on_start_button_pressed"):
        root._on_start_button_pressed()
    else:
        print("[StartButtonProxy] ERROR: handler not found on root scene")