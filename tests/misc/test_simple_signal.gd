extends SceneTree

var signal_count = 0
var received_signals = []

func _ready():
	print("[简单信号测试] 开始测试...")
	
	# 加载CharacterAnimator场景
	var animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	if animator_scene == null:
		print("[简单信号测试] ✗ 无法加载CharacterAnimator场景")
		quit()
		return
	
	# 实例化
	var animator = animator_scene.instantiate()
	if animator == null:
		print("[简单信号测试] ✗ 无法实例化CharacterAnimator")
		quit()
		return
	
	# 添加到场景树
	root.add_child(animator)
	
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
	print("[简单信号测试] ✓ 角色初始化完成")
	
	# 连接信号
	animator.animation_completed.connect(_on_animation_completed)
	print("[简单信号测试] ✓ 信号已连接")
	
	# 测试1：普通受击闪烁
	print("[简单信号测试] 测试1：播放普通受击闪烁...")
	animator.play_hit_animation(false)
	
	# 等待一段时间
	for i in range(120):  # 等待2秒 (60fps * 2)
		await process_frame
	
	# 测试2：暴击受击闪烁
	print("[简单信号测试] 测试2：播放暴击受击闪烁...")
	animator.play_hit_animation(true)
	
	# 等待一段时间
	for i in range(120):  # 等待2秒 (60fps * 2)
		await process_frame
	
	# 输出结果
	print("[简单信号测试] 测试完成！")
	print("[简单信号测试] 总共收到 %d 个信号" % signal_count)
	print("[简单信号测试] 收到的信号类型: %s" % str(received_signals))
	
	if signal_count >= 2:
		print("[简单信号测试] ✓ 测试成功！CharacterAnimator的animation_completed信号工作正常")
	else:
		print("[简单信号测试] ✗ 测试失败！期望收到2个信号，实际收到%d个" % signal_count)
	
	quit()

func _on_animation_completed(animation_type: String):
	signal_count += 1
	received_signals.append(animation_type)
	print("[简单信号测试] ✓ 收到信号 #%d: %s" % [signal_count, animation_type])