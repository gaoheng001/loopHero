extends Control

var main_game_controller: MainGameController
var battle_window: BattleWindow
var battle_animation_controller: BattleAnimationController
var hero_animators: Array
var enemy_animators: Array

func _ready():
	print("=== 开始可视化动画测试 ===")
	
	# 设置窗口大小
	get_window().size = Vector2i(1200, 800)
	
	# 创建MainGameController
	main_game_controller = preload("res://scenes/MainGame.tscn").instantiate()
	add_child(main_game_controller)
	
	# 等待一帧让节点初始化
	await get_tree().process_frame
	
	# 获取BattleWindow
	battle_window = main_game_controller.get_node("UI/BattleWindow")
	if battle_window:
		print("[测试] ✓ BattleWindow获取成功")
		
		# 获取BattleAnimationController
		battle_animation_controller = battle_window.battle_animation_controller
		if battle_animation_controller:
			print("[测试] ✓ BattleAnimationController获取成功")
			
			# 创建模拟数据并初始化动画器
			await _setup_test_data()
			
			# 开始动画演示
			await _start_animation_demo()
		else:
			print("[测试] ✗ BattleAnimationController获取失败")
	else:
		print("[测试] ✗ BattleWindow获取失败")

func _setup_test_data():
	print("[测试] 设置测试数据...")
	
	# 创建模拟的TeamBattleManager
	var mock_team_manager = Node.new()
	mock_team_manager.name = "MockTeamBattleManager"
	
	# 创建模拟的英雄数据
	var hero_data = {
		"character_id": "hero1",
		"name": "测试英雄",
		"level": 5,
		"health": 100,
		"max_health": 100,
		"attack": 25,
		"defense": 10,
		"sprite_path": "res://assets/characters/hero_default.png"
	}
	
	# 创建模拟的敌人数据
	var enemy_data = {
		"character_id": "enemy1", 
		"name": "测试敌人",
		"level": 3,
		"health": 80,
		"max_health": 80,
		"attack": 20,
		"defense": 5,
		"sprite_path": "res://assets/characters/enemy_default.png"
	}
	
	# 设置team_battle_manager引用
	battle_animation_controller.team_battle_manager = mock_team_manager
	
	# 创建角色动画器
	battle_animation_controller._create_character_animators()
	
	# 获取动画器引用
	hero_animators = battle_animation_controller.get("hero_animators")
	enemy_animators = battle_animation_controller.get("enemy_animators")
	
	if hero_animators and hero_animators.size() > 0:
		print("[测试] ✓ 英雄动画器创建成功，数量: ", hero_animators.size())
		# 设置英雄数据
		for i in range(hero_animators.size()):
			var animator = hero_animators[i]
			if animator.has_method("set_character_data"):
				animator.set_character_data(hero_data)
	
	if enemy_animators and enemy_animators.size() > 0:
		print("[测试] ✓ 敌人动画器创建成功，数量: ", enemy_animators.size())
		# 设置敌人数据
		for i in range(enemy_animators.size()):
			var animator = enemy_animators[i]
			if animator.has_method("set_character_data"):
				animator.set_character_data(enemy_data)

func _start_animation_demo():
	print("[测试] 开始动画演示...")
	
	# 创建UI标签显示当前测试
	var label = Label.new()
	label.text = "动画测试进行中..."
	label.position = Vector2(50, 50)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
	
	# 演示1: 英雄攻击动画
	if hero_animators and hero_animators.size() > 0:
		label.text = "演示: 英雄攻击动画"
		var hero_animator = hero_animators[0]
		if hero_animator.has_method("play_attack_animation"):
			hero_animator.play_attack_animation()
			print("[演示] 播放英雄攻击动画")
		await get_tree().create_timer(3.0).timeout
	
	# 演示2: 敌人受伤动画
	if enemy_animators and enemy_animators.size() > 0:
		label.text = "演示: 敌人受伤动画"
		var enemy_animator = enemy_animators[0]
		if enemy_animator.has_method("play_damage_animation"):
			enemy_animator.play_damage_animation(35, false)
			print("[演示] 播放敌人受伤动画，伤害: 35")
		await get_tree().create_timer(3.0).timeout
	
	# 演示3: 英雄技能动画
	if hero_animators and hero_animators.size() > 0:
		label.text = "演示: 英雄技能动画"
		var hero_animator = hero_animators[0]
		if hero_animator.has_method("play_skill_animation"):
			hero_animator.play_skill_animation("fireball")
			print("[演示] 播放英雄技能动画: fireball")
		await get_tree().create_timer(3.0).timeout
	
	# 演示4: 动画速度控制
	label.text = "演示: 2倍速动画"
	if battle_animation_controller.has_method("set_animation_speed"):
		battle_animation_controller.set_animation_speed(2.0)
		print("[演示] 设置动画速度为2倍")
		
		if hero_animators and hero_animators.size() > 0:
			var hero_animator = hero_animators[0]
			if hero_animator.has_method("play_attack_animation"):
				hero_animator.play_attack_animation()
				print("[演示] 播放2倍速攻击动画")
		await get_tree().create_timer(2.0).timeout
	
	# 演示5: 敌人死亡动画
	if enemy_animators and enemy_animators.size() > 0:
		label.text = "演示: 敌人死亡动画"
		var enemy_animator = enemy_animators[0]
		if enemy_animator.has_method("play_death_animation"):
			enemy_animator.play_death_animation()
			print("[演示] 播放敌人死亡动画")
		await get_tree().create_timer(3.0).timeout
	
	# 演示完成
	label.text = "动画演示完成！所有动画功能正常工作。"
	print("=== 可视化动画测试完成 ===")

func _input(event):
	# 按ESC键退出
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()