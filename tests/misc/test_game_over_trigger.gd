extends Node

# 测试Game Over触发脚本

func _ready():
	print("[GameOverTest] 测试脚本启动...")
	# 立即触发测试
	call_deferred("_trigger_game_over_test")

func _trigger_game_over_test():
	print("[GameOverTest] 开始触发Game Over测试...")
	
	# 直接查找GameManager
	var game_manager = get_node_or_null("/root/MainGame/GameManager")
	
	if game_manager:
		print("[GameOverTest] 找到GameManager节点")
		if game_manager.has_method("test_game_over"):
			print("[GameOverTest] 调用GameManager.test_game_over()...")
			game_manager.test_game_over()
		else:
			print("[GameOverTest] ERROR: GameManager missing test_game_over method")
	else:
		print("[GameOverTest] ERROR: GameManager not found at /root/MainGame/GameManager")