extends SceneTree

func _init():
	print("[AutoTest] Starting auto test...")
	
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn")
	if main_scene == null:
		print("[AutoTest] Failed to load MainGame.tscn")
		quit(1)
		return
	
	print("[AutoTest] Loaded MainGame.tscn")
	
	# 实例化场景
	var scene_instance = main_scene.instantiate()
	if scene_instance == null:
		print("[AutoTest] Failed to instantiate MainGame scene")
		quit(1)
		return
	
	print("[AutoTest] Instantiated MainGame scene")
	
	# 添加到场景树
	root.add_child(scene_instance)
	print("[AutoTest] Added scene to tree")
	
	# 设置为当前场景
	current_scene = scene_instance
	print("[AutoTest] Set current scene")
	
	# 等待一帧，确保_ready方法被调用
	await process_frame
	print("[AutoTest] Waited for process frame")
	
	# 检查是否有MainGameController脚本
	var main_controller = scene_instance
	if main_controller.has_method("_on_start_button_pressed"):
		print("[AutoTest] Found MainGameController script on root node")
	else:
		print("[AutoTest] ERROR: MainGameController script not found!")
		quit()
		return
	
	# 等待2秒后自动点击开始按钮
	print("[AutoTest] Waiting 2 seconds before clicking start button...")
	await create_timer(2.0).timeout
	
	print("[AutoTest] Triggering start button...")
	main_controller._on_start_button_pressed()
	
	print("[AutoTest] Start button triggered, waiting for game to run...")
	
	# 等待游戏运行更长时间以到达第5天（比如120秒）
	await create_timer(120.0).timeout
	
	print("[AutoTest] Test completed, exiting...")
	quit(0)