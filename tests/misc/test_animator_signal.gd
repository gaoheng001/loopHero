# test_animator_signal.gd
# 测试CharacterAnimator的animation_completed信号

extends SceneTree

func _init():
	print("[信号测试] 开始测试CharacterAnimator的animation_completed信号...")
	call_deferred("start_test")

func start_test():
	# 加载CharacterAnimator场景
	var animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	if animator_scene == null:
		print("[信号测试] ✗ 无法加载CharacterAnimator场景")
		quit()
		return
	
	# 实例化CharacterAnimator
	var animator = animator_scene.instantiate()
	if animator == null:
		print("[信号测试] ✗ 无法实例化CharacterAnimator")
		quit()
		return
	
	print("[信号测试] ✓ CharacterAnimator实例化成功")
	
	# 添加到场景树
	root.add_child(animator)
	
	# 创建测试角色数据
	var test_character = {
		"name": "测试敌人",
		"current_hp": 100,
		"max_hp": 100,
		"attack": 20,
		"defense": 10,
		"speed": 15,
		"sprite_path": "res://assets/sprites/enemies/goblin.png"
	}
	
	# 初始化角色
	animator.initialize_character(test_character, "enemy", 0)
	print("[信号测试] ✓ 角色初始化完成")
	
	# 连接animation_completed信号
	var signal_received = false
	var received_animation_type = ""
	
	# 使用callable连接信号
	var signal_callback = func(animation_type: String):
		print("[信号测试] ✓ 收到animation_completed信号！动画类型: %s" % animation_type)
		signal_received = true
		received_animation_type = animation_type
	
	animator.animation_completed.connect(signal_callback)
	
	print("[信号测试] ✓ 已连接animation_completed信号")
	
	# 调用play_hit_animation方法
	print("[信号测试] 开始播放受击闪烁动画...")
	animator.play_hit_animation(false)  # 非暴击
	
	# 等待信号
	var wait_frames = 0
	var max_wait_frames = 300  # 等待5秒 (60fps * 5)
	
	while not signal_received and wait_frames < max_wait_frames:
		await process_frame
		wait_frames += 1
	
	if signal_received:
		print("[信号测试] ✓ 测试成功！animation_completed信号正常发出，动画类型: %s" % received_animation_type)
	else:
		print("[信号测试] ✗ 测试失败！等待%d帧后仍未收到animation_completed信号" % wait_frames)
	
	# 测试暴击闪烁
	print("[信号测试] 开始测试暴击闪烁动画...")
	signal_received = false
	received_animation_type = ""
	animator.play_hit_animation(true)  # 暴击
	
	wait_frames = 0
	while not signal_received and wait_frames < max_wait_frames:
		await process_frame
		wait_frames += 1
	
	if signal_received:
		print("[信号测试] ✓ 暴击闪烁测试成功！animation_completed信号正常发出，动画类型: %s" % received_animation_type)
	else:
		print("[信号测试] ✗ 暴击闪烁测试失败！等待%d帧后仍未收到animation_completed信号" % wait_frames)
	
	print("[信号测试] 测试完成")
	quit()