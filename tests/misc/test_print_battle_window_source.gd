# 打印 BattleWindow.gd 脚本源代码，以确认引擎加载的是哪个版本
extends SceneTree

func _init():
    var sc: Script = load("res://scripts/BattleWindow.gd")
    if sc == null:
        print("[PrintBW] 脚本加载失败")
        quit(1)
        return
    print("[PrintBW] resource_path=", sc.resource_path)
    var code := ""
    if sc.has_method("get_source_code"):
        # Godot 3 API，保留兼容
        code = sc.get_source_code()
    else:
        # Godot 4 API：直接读取属性
        code = String(sc.source_code)
    print("[PrintBW] 源代码长度=", code.length())
    var idx := code.find("func show_team_battle")
    print("[PrintBW] 是否包含 show_team_battle 定义:", idx != -1)
    idx = code.find("func show_battle")
    print("[PrintBW] 是否包含 show_battle 定义:", idx != -1)
    quit(0)