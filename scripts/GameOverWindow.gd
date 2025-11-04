extends Control

signal restart_game
signal quit_game

@onready var loop_label = $GameOverPanel/MainContainer/StatsContainer/LoopLabel
@onready var step_label = $GameOverPanel/MainContainer/StatsContainer/StepLabel
@onready var restart_button = $GameOverPanel/MainContainer/ButtonContainer/RestartButton
@onready var quit_button = $GameOverPanel/MainContainer/ButtonContainer/QuitButton

func _ready():
	# 初始时隐藏窗口
	visible = false
	
	# 连接按钮信号
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func show_game_over(loop_count: int = 0, step_count: int = 0):
	"""显示Game Over窗口"""
	# 更新统计信息
	loop_label.text = "完成循环: " + str(loop_count)
	step_label.text = "总步数: " + str(step_count)
	
	# 显示窗口
	visible = true
	
	print("[GameOverWindow] Game Over window shown")

func hide_game_over():
	"""隐藏Game Over窗口"""
	visible = false
	print("[GameOverWindow] Game Over window hidden")

func _on_restart_pressed():
	"""重新开始按钮点击"""
	print("[GameOverWindow] Restart button pressed")
	restart_game.emit()
	hide_game_over()

func _on_quit_pressed():
	"""退出游戏按钮点击"""
	print("[GameOverWindow] Quit button pressed")
	quit_game.emit()
	hide_game_over()