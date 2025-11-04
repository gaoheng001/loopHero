# 检查 BattleAnimationController.gd 的 initialize 方法是否可用
extends SceneTree

func _init():
    var sc: Script = load("res://scripts/battle/BattleAnimationController.gd")
    if sc == null:
        print("[CheckBAC] 脚本加载失败")
        quit(1)
        return
    print("[CheckBAC] resource_path=", sc.resource_path)
    var code := String(sc.source_code)
    print("[CheckBAC] 源代码长度=", code.length())
    var has_def := (code.find("func initialize(") != -1)
    print("[CheckBAC] 源码是否包含 initialize 定义:", has_def)
    var node := Node.new()
    node.set_script(sc)
    print("[CheckBAC] 附脚本后 has_method('initialize')=", node.has_method("initialize"))
    quit(0)