extends SceneTree

func _ready():
	print("开始基本测试...")
	
	# 加载CharacterAnimator场景
	var animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	if animator_scene == null:
		print("✗ 无法加载CharacterAnimator场景")
		quit()
		return
	
	print("✓ CharacterAnimator场景加载成功")
	
	# 实例化
	var animator = animator_scene.instantiate()
	if animator == null:
		print("✗ 无法实例化CharacterAnimator")
		quit()
		return
	
	print("✓ CharacterAnimator实例化成功")
	
	# 添加到场景树
	root.add_child(animator)
	print("✓ 已添加到场景树")
	
	# 创建角色数据
	var test_character = {
		"name": "测试角色",
		"current_hp": 100,
		"max_hp": 100,
		"attack": 20,
		"defense": 10,
		"speed": 15,
		"sprite_path": "res://assets/sprites/enemies/goblin.png"
	}
	
	# 初始化角色
	animator.initialize_character(test_character, "enemy", 0)
	print("✓ 角色初始化完成")
	
	# 检查信号是否存在
	if animator.has_signal("animation_completed"):
		print("✓ animation_completed信号存在")
	else:
		print("✗ animation_completed信号不存在")
	
	print("基本测试完成")
	quit()