extends Control
class_name BattleControls

"""
战斗控制面板
提供速度控制、暂停/继续、自动战斗等功能
"""

# ============ 信号定义 ============

signal speed_changed(speed: float)
signal pause_toggled(is_paused: bool)
signal auto_battle_toggled(is_auto: bool)
signal skip_animation_requested()
signal battle_exit_requested()

# ============ 控制状态 ============

enum ControlState {
	NORMAL,      # 正常状态
	PAUSED,      # 暂停状态
	AUTO_BATTLE, # 自动战斗状态
	FAST_FORWARD # 快进状态
}

# ============ 组件引用 ============

@onready var speed_slider: HSlider
@onready var speed_label: Label
@onready var pause_button: Button
@onready var auto_button: Button
@onready var skip_button: Button
@onready var exit_button: Button
@onready var control_panel: Panel

# ============ 控制配置 ============

var current_state: ControlState = ControlState.NORMAL
var current_speed: float = 1.0
var is_paused: bool = false
var is_auto_battle: bool = false

# 速度预设
var speed_presets: Array[float] = [0.5, 1.0, 1.5, 2.0, 3.0]
var current_preset_index: int = 1

# ============ 初始化 ============

func _ready():
	print("[BattleControls] 战斗控制面板初始化")
	_create_ui_components()
	_setup_ui_layout()
	_connect_signals()
	_update_ui_state()

func _create_ui_components():
	"""创建UI组件"""
	# 创建主面板
	control_panel = Panel.new()
	control_panel.name = "ControlPanel"
	add_child(control_panel)
	
	# 创建速度滑块
	speed_slider = HSlider.new()
	speed_slider.name = "SpeedSlider"
	speed_slider.min_value = 0.5
	speed_slider.max_value = 3.0
	speed_slider.step = 0.1
	speed_slider.value = current_speed
	control_panel.add_child(speed_slider)
	
	# 创建速度标签
	speed_label = Label.new()
	speed_label.name = "SpeedLabel"
	speed_label.text = "速度: %.1fx" % current_speed
	control_panel.add_child(speed_label)
	
	# 创建暂停按钮
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "暂停"
	control_panel.add_child(pause_button)
	
	# 创建自动战斗按钮
	auto_button = Button.new()
	auto_button.name = "AutoButton"
	auto_button.text = "自动"
	control_panel.add_child(auto_button)
	
	# 创建跳过动画按钮
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "跳过"
	control_panel.add_child(skip_button)
	
	# 创建退出按钮
	exit_button = Button.new()
	exit_button.name = "ExitButton"
	exit_button.text = "退出"
	control_panel.add_child(exit_button)

func _setup_ui_layout():
	"""设置UI布局"""
	# 设置面板大小和位置
	control_panel.size = Vector2(300, 80)
	control_panel.position = Vector2(10, 10)
	
	# 设置组件位置
	speed_label.position = Vector2(10, 10)
	speed_label.size = Vector2(80, 20)
	
	speed_slider.position = Vector2(100, 10)
	speed_slider.size = Vector2(180, 20)
	
	pause_button.position = Vector2(10, 40)
	pause_button.size = Vector2(60, 30)
	
	auto_button.position = Vector2(80, 40)
	auto_button.size = Vector2(60, 30)
	
	skip_button.position = Vector2(150, 40)
	skip_button.size = Vector2(60, 30)
	
	exit_button.position = Vector2(220, 40)
	exit_button.size = Vector2(60, 30)

func _connect_signals():
	"""连接信号"""
	speed_slider.value_changed.connect(_on_speed_changed)
	pause_button.pressed.connect(_on_pause_pressed)
	auto_button.pressed.connect(_on_auto_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

# ============ 公共接口 ============

func set_battle_state(state: String):
	"""设置战斗状态"""
	match state:
		"battle_start":
			_enable_all_controls()
		"battle_end":
			_disable_battle_controls()
		"animation_playing":
			skip_button.disabled = false
		"animation_idle":
			skip_button.disabled = true

func set_speed(speed: float):
	"""设置播放速度"""
	current_speed = clamp(speed, 0.5, 3.0)
	speed_slider.value = current_speed
	speed_label.text = "速度: %.1fx" % current_speed
	emit_signal("speed_changed", current_speed)

func set_pause_state(paused: bool):
	"""设置暂停状态"""
	is_paused = paused
	pause_button.text = "继续" if is_paused else "暂停"
	current_state = ControlState.PAUSED if is_paused else ControlState.NORMAL
	_update_ui_state()

func set_auto_battle_state(auto: bool):
	"""设置自动战斗状态"""
	is_auto_battle = auto
	auto_button.text = "手动" if is_auto_battle else "自动"
	current_state = ControlState.AUTO_BATTLE if is_auto_battle else ControlState.NORMAL
	_update_ui_state()

func get_current_speed() -> float:
	"""获取当前速度"""
	return current_speed

func is_battle_paused() -> bool:
	"""检查是否暂停"""
	return is_paused

func is_auto_battle_enabled() -> bool:
	"""检查是否自动战斗"""
	return is_auto_battle

# ============ 信号处理 ============

func _on_speed_changed(value: float):
	"""速度滑块变化处理"""
	current_speed = value
	speed_label.text = "速度: %.1fx" % current_speed
	emit_signal("speed_changed", current_speed)
	print("[BattleControls] 速度设置为: %.1fx" % current_speed)

func _on_pause_pressed():
	"""暂停按钮处理"""
	is_paused = !is_paused
	set_pause_state(is_paused)
	emit_signal("pause_toggled", is_paused)
	print("[BattleControls] 暂停状态: %s" % ("暂停" if is_paused else "继续"))

func _on_auto_pressed():
	"""自动战斗按钮处理"""
	is_auto_battle = !is_auto_battle
	set_auto_battle_state(is_auto_battle)
	emit_signal("auto_battle_toggled", is_auto_battle)
	print("[BattleControls] 自动战斗: %s" % ("开启" if is_auto_battle else "关闭"))

func _on_skip_pressed():
	"""跳过动画按钮处理"""
	emit_signal("skip_animation_requested")
	print("[BattleControls] 跳过动画请求")

func _on_exit_pressed():
	"""退出按钮处理"""
	emit_signal("battle_exit_requested")
	print("[BattleControls] 退出战斗请求")

# ============ 内部方法 ============

func _update_ui_state():
	"""更新UI状态"""
	match current_state:
		ControlState.NORMAL:
			_enable_all_controls()
		ControlState.PAUSED:
			speed_slider.editable = false
			auto_button.disabled = true
			skip_button.disabled = true
		ControlState.AUTO_BATTLE:
			pause_button.disabled = false
			skip_button.disabled = false
		ControlState.FAST_FORWARD:
			pause_button.disabled = false

func _enable_all_controls():
	"""启用所有控制"""
	speed_slider.editable = true
	pause_button.disabled = false
	auto_button.disabled = false
	skip_button.disabled = false
	exit_button.disabled = false

func _disable_battle_controls():
	"""禁用战斗控制"""
	speed_slider.editable = false
	pause_button.disabled = true
	auto_button.disabled = true
	skip_button.disabled = true

# ============ 快捷键处理 ============

func _input(event):
	"""处理快捷键输入"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_on_pause_pressed()
			KEY_A:
				_on_auto_pressed()
			KEY_S:
				_on_skip_pressed()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var preset_index = event.keycode - KEY_1
				if preset_index < speed_presets.size():
					set_speed(speed_presets[preset_index])

# ============ 预设功能 ============

func cycle_speed_preset():
	"""循环速度预设"""
	current_preset_index = (current_preset_index + 1) % speed_presets.size()
	set_speed(speed_presets[current_preset_index])

func reset_to_default():
	"""重置为默认设置"""
	set_speed(1.0)
	set_pause_state(false)
	set_auto_battle_state(false)
	current_preset_index = 1

# ============ 状态保存 ============

func save_control_settings() -> Dictionary:
	"""保存控制设置"""
	return {
		"speed": current_speed,
		"auto_battle": is_auto_battle,
		"preset_index": current_preset_index
	}

func load_control_settings(settings: Dictionary):
	"""加载控制设置"""
	if settings.has("speed"):
		set_speed(settings.speed)
	if settings.has("auto_battle"):
		set_auto_battle_state(settings.auto_battle)
	if settings.has("preset_index"):
		current_preset_index = settings.preset_index