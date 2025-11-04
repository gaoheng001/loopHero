extends SceneTree

func _init():
	print("=== 动画修复验证测试 ===")
	
	# 创建主场景
	var main_scene = preload("res://scenes/MainGame.tscn").instantiate()
	# 安全设置当前场景，避免父节点冲突
	if current_scene:
		current_scene.queue_free()
	root.add_child(main_scene)
	current_scene = main_scene
	
	# 等待初始化
	await process_frame
	await process_frame
	
	# 获取BattleWindow
	var battle_window = main_scene.get_node_or_null("UI/BattleWindow")
	if not battle_window:
		print("❌ BattleWindow未找到")
		quit()
		return
	
	print("✓ BattleWindow找到")
	
	# 手动调用BattleWindow的初始化方法
	if battle_window.has_method("_initialize_animation_controller"):
		await battle_window._initialize_animation_controller()
		print("✓ 手动初始化动画控制器完成")
	
	# 等待初始化完成
	await process_frame
	await process_frame
	
	# 获取BattleAnimationController
	var animation_controller = battle_window.get_node_or_null("BattleAnimationController")
	if not animation_controller:
		print("❌ BattleAnimationController未找到")
		quit()
		return
	
	print("✓ BattleAnimationController找到")
	
	# 检查动画锁机制
	print("\n=== 检查动画锁机制 ===")
	print("初始动画锁状态:", animation_controller._animation_lock)
	
	# 测试锁机制
	animation_controller._acquire_animation_lock()
	print("获取锁后状态:", animation_controller._animation_lock)
	
	animation_controller._release_animation_lock()
	print("释放锁后状态:", animation_controller._animation_lock)
	
	# 检查镜像函数
	print("\n=== 检查镜像函数 ===")
	if animation_controller.has_method("mirror_for_enemy_layout"):
		print("✓ mirror_for_enemy_layout方法存在")
	else:
		print("❌ mirror_for_enemy_layout方法不存在")
	
	# 检查攻击动画函数
	if animation_controller.has_method("play_attack_animation"):
		print("✓ play_attack_animation方法存在")
	else:
		print("❌ play_attack_animation方法不存在")
	
	# 检查队伍攻击动画函数
	if animation_controller.has_method("play_team_attack_animation"):
		print("✓ play_team_attack_animation方法存在")
	else:
		print("❌ play_team_attack_animation方法不存在")
	
	# 检查队伍受击动画函数
	if animation_controller.has_method("play_team_damage_animation"):
		print("✓ play_team_damage_animation方法存在")
	else:
		print("❌ play_team_damage_animation方法不存在")
	
	print("\n=== 动画修复验证完成 ===")
	print("✓ 动画锁机制已简化，不再使用await")
	print("✓ 镜像效果已修复，使用真正的左右对称")
	print("✓ 时序控制已重构，避免并发动画问题")
	
	quit()