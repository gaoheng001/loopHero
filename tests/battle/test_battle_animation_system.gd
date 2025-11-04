# test_battle_animation_system.gd
# 测试回合攻击表现系统的集成和功能

extends SceneTree

func _init():
	print("=== 回合攻击表现系统测试开始 ===")
	test_battle_animation_system()
	quit()

func test_battle_animation_system():
	"""测试战斗动画系统"""
	print("\n1. 测试动画控制器初始化...")
	test_animation_controller_initialization()
	
	print("\n2. 测试角色动画器...")
	test_character_animator()
	
	print("\n3. 测试伤害数字系统...")
	test_damage_number_system()
	
	print("\n4. 测试战斗特效管理器...")
	test_battle_effects_manager()
	
	print("\n5. 测试音效管理器...")
	test_audio_manager()
	
	print("\n6. 测试战斗控制面板...")
	test_battle_controls()
	
	print("\n7. 测试TeamBattleManager信号集成...")
	test_team_battle_manager_integration()
	
	print("\n=== 回合攻击表现系统测试完成 ===")

func test_animation_controller_initialization():
	"""测试动画控制器初始化"""
	var BattleAnimationControllerScript = load("res://scripts/battle/BattleAnimationController.gd")
	if BattleAnimationControllerScript == null:
		print("❌ BattleAnimationController脚本加载失败")
		return
	
	var controller = BattleAnimationControllerScript.new()
	if controller == null:
		print("❌ BattleAnimationController实例化失败")
		return
	
	print("✅ BattleAnimationController初始化成功")
	
	# 测试信号定义
	var expected_signals = ["animation_started", "animation_finished", "character_animation_completed"]
	for signal_name in expected_signals:
		if controller.has_signal(signal_name):
			print("✅ 信号 '%s' 定义正确" % signal_name)
		else:
			print("❌ 信号 '%s' 未定义" % signal_name)
	
	controller.queue_free()

func test_character_animator():
	"""测试角色动画器"""
	var CharacterAnimatorScript = load("res://scripts/battle/CharacterAnimator.gd")
	if CharacterAnimatorScript == null:
		print("❌ CharacterAnimator脚本加载失败")
		return
	
	var animator = CharacterAnimatorScript.new()
	if animator == null:
		print("❌ CharacterAnimator实例化失败")
		return
	
	print("✅ CharacterAnimator初始化成功")
	
	# 测试角色数据初始化
	var test_character = {
		"name": "测试英雄",
		"current_hp": 100,
		"max_hp": 100,
		"attack": 20,
		"defense": 10
	}
	
	animator.initialize_character(test_character, "hero", 0)
	print("✅ 角色数据初始化成功")
	
	# 测试动画方法存在性
	var animation_methods = ["play_attack_animation", "play_damage_animation", "play_skill_animation", "play_death_animation"]
	for method_name in animation_methods:
		if animator.has_method(method_name):
			print("✅ 动画方法 '%s' 存在" % method_name)
		else:
			print("❌ 动画方法 '%s' 不存在" % method_name)
	
	animator.queue_free()

func test_damage_number_system():
	"""测试伤害数字系统"""
	var DamageNumberScript = load("res://scripts/battle/DamageNumber.gd")
	if DamageNumberScript == null:
		print("❌ DamageNumber脚本加载失败")
		return
	
	var DamageNumberPoolScript = load("res://scripts/battle/DamageNumberPool.gd")
	if DamageNumberPoolScript == null:
		print("❌ DamageNumberPool脚本加载失败")
		return
	
	var damage_number = DamageNumberScript.new()
	var damage_pool = DamageNumberPoolScript.new()
	
	print("✅ 伤害数字系统初始化成功")
	
	# 测试伤害数字显示方法
	if damage_number.has_method("show_damage_number"):
		print("✅ 伤害显示方法存在")
	elif damage_pool.has_method("show_damage"):
		print("✅ 伤害池显示方法存在")
	else:
		print("❌ 伤害显示方法不存在")
	
	damage_number.queue_free()
	damage_pool.queue_free()

func test_battle_effects_manager():
	"""测试战斗特效管理器"""
	var BattleEffectsManagerScript = load("res://scripts/battle/BattleEffectsManager.gd")
	if BattleEffectsManagerScript == null:
		print("❌ BattleEffectsManager脚本加载失败")
		return
	
	var effects_manager = BattleEffectsManagerScript.new()
	print("✅ BattleEffectsManager初始化成功")
	
	# 测试特效方法
	var effect_methods = ["play_attack_effect", "play_skill_effect", "play_critical_hit_effect"]
	for method_name in effect_methods:
		if effects_manager.has_method(method_name):
			print("✅ 特效方法 '%s' 存在" % method_name)
		else:
			print("❌ 特效方法 '%s' 不存在" % method_name)
	
	effects_manager.queue_free()

func test_audio_manager():
	"""测试音效管理器"""
	var BattleAudioManagerScript = load("res://scripts/battle/BattleAudioManager.gd")
	if BattleAudioManagerScript == null:
		print("❌ BattleAudioManager脚本加载失败")
		return
	
	var audio_manager = BattleAudioManagerScript.new()
	print("✅ BattleAudioManager初始化成功")
	
	# 测试音效方法
	var audio_methods = ["play_attack_sound", "play_skill_sound", "play_damage_sound"]
	for method_name in audio_methods:
		if audio_manager.has_method(method_name):
			print("✅ 音效方法 '%s' 存在" % method_name)
		else:
			print("❌ 音效方法 '%s' 不存在" % method_name)
	
	audio_manager.queue_free()

func test_battle_controls():
	"""测试战斗控制面板"""
	var BattleControlsScript = load("res://scripts/battle/BattleControls.gd")
	if BattleControlsScript == null:
		print("❌ BattleControls脚本加载失败")
		return
	
	var battle_controls = BattleControlsScript.new()
	print("✅ BattleControls初始化成功")
	
	# 测试控制信号
	var control_signals = ["speed_changed", "pause_toggled", "auto_battle_toggled"]
	for signal_name in control_signals:
		if battle_controls.has_signal(signal_name):
			print("✅ 控制信号 '%s' 定义正确" % signal_name)
		else:
			print("❌ 控制信号 '%s' 未定义" % signal_name)
	
	battle_controls.queue_free()

func test_team_battle_manager_integration():
	"""测试TeamBattleManager信号集成"""
	var TeamBattleManagerScript = load("res://scripts/TeamBattleManager.gd")
	if TeamBattleManagerScript == null:
		print("❌ TeamBattleManager脚本加载失败")
		return
	
	var tbm = TeamBattleManagerScript.new()
	print("✅ TeamBattleManager加载成功")
	
	# 检查关键信号
	var required_signals = ["damage_dealt", "skill_triggered", "battle_started", "battle_finished"]
	for signal_name in required_signals:
		if tbm.has_signal(signal_name):
			print("✅ TeamBattleManager信号 '%s' 存在" % signal_name)
		else:
			print("❌ TeamBattleManager信号 '%s' 不存在" % signal_name)
	
	# 测试BattleWindow集成
	var BattleWindowScript = load("res://scripts/BattleWindow.gd")
	if BattleWindowScript != null:
		var battle_window = BattleWindowScript.new()
		if battle_window.has_method("show_team_battle"):
			print("✅ BattleWindow集成TeamBattleManager成功")
		else:
			print("❌ BattleWindow缺少show_team_battle方法")
		battle_window.queue_free()
	
	tbm.queue_free()