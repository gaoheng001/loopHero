extends SceneTree

func _init():
	print("=== 测试动画器可见性修复 ===")
	
	# 加载BattleWindow场景
	var battle_scene = load("res://scenes/BattleWindow.tscn")
	if not battle_scene:
		print("错误：无法加载BattleWindow.tscn")
		quit()
		return
	
	var battle_window = battle_scene.instantiate()
	get_root().add_child(battle_window)
	
	# 显示战斗窗口
	battle_window.visible = true
	
	# 查找AnimationArea及其子容器（兼容是否存在 ContentContainer 包裹层）
	var animation_area = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea")
	if not animation_area:
		animation_area = battle_window.get_node_or_null("BattlePanel/MainContainer/BattleArea/AnimationArea")
	var hero_container = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/HeroAnimators")
	if not hero_container:
		hero_container = battle_window.get_node_or_null("BattlePanel/MainContainer/BattleArea/AnimationArea/HeroAnimators")
	var enemy_container = battle_window.get_node_or_null("BattlePanel/MainContainer/ContentContainer/BattleArea/AnimationArea/EnemyAnimators")
	if not enemy_container:
		enemy_container = battle_window.get_node_or_null("BattlePanel/MainContainer/BattleArea/AnimationArea/EnemyAnimators")
	
	if not animation_area or not hero_container or not enemy_container:
		print("错误：找不到动画容器")
		quit()
		return
	
	print("=== 容器信息 ===")
	print("AnimationArea - pos:", animation_area.global_position, ", size:", animation_area.size, ", visible:", animation_area.visible)
	print("HeroAnimators - pos:", hero_container.global_position, ", size:", hero_container.size, ", visible:", hero_container.visible)
	print("EnemyAnimators - pos:", enemy_container.global_position, ", size:", enemy_container.size, ", visible:", enemy_container.visible)
	
	# 手动创建CharacterAnimator实例进行测试
	var CharacterAnimatorClass = load("res://scripts/battle/CharacterAnimator.gd")
	if not CharacterAnimatorClass:
		print("错误：无法加载CharacterAnimator类")
		quit()
		return
	
	print("\n=== 创建测试动画器 ===")
	
	# 创建英雄动画器
	var hero_animator = CharacterAnimatorClass.new()
	hero_animator.name = "TestHeroAnimator"
	hero_animator.position = Vector2(10, 10)
	hero_container.add_child(hero_animator)
	
	# 创建敌人动画器
	var enemy_animator = CharacterAnimatorClass.new()
	enemy_animator.name = "TestEnemyAnimator"
	enemy_animator.position = Vector2(10, 10)
	enemy_container.add_child(enemy_animator)
	
	# 等待一帧让UI更新
	await process_frame
	
	print("=== 动画器信息 ===")
	print("HeroAnimator - pos:", hero_animator.global_position, ", size:", hero_animator.size, ", visible:", hero_animator.visible)
	print("EnemyAnimator - pos:", enemy_animator.global_position, ", size:", enemy_animator.size, ", visible:", enemy_animator.visible)
	
	# 检查动画器的子节点
	print("\n=== 动画器子节点 ===")
	print("HeroAnimator children:", hero_animator.get_child_count())
	for i in range(hero_animator.get_child_count()):
		var child = hero_animator.get_child(i)
		var pos_info = "N/A"
		var size_info = "N/A"
		if child is CanvasItem:
			pos_info = str(child.position)
		if child is Control:
			size_info = str(child.size)
		print("  - ", child.name, " (", child.get_class(), ") pos:", pos_info, ", size:", size_info)
	
	print("EnemyAnimator children:", enemy_animator.get_child_count())
	for i in range(enemy_animator.get_child_count()):
		var child = enemy_animator.get_child(i)
		var pos_info = "N/A"
		var size_info = "N/A"
		if child is CanvasItem:
			pos_info = str(child.position)
		if child is Control:
			size_info = str(child.size)
		print("  - ", child.name, " (", child.get_class(), ") pos:", pos_info, ", size:", size_info)
	
	# 初始化动画器
	var test_hero_data = {
		"name": "测试英雄",
		"hp": 100,
		"max_hp": 100,
		"character_type": "hero"
	}
	
	var test_enemy_data = {
		"name": "测试敌人", 
		"hp": 80,
		"max_hp": 80,
		"character_type": "enemy"
	}
	
	hero_animator.initialize_character(test_hero_data, "hero", 0)
	enemy_animator.initialize_character(test_enemy_data, "enemy", 0)
	
	# 等待一帧让初始化完成
	await process_frame
	
	print("\n=== 初始化后的动画器信息 ===")
	print("HeroAnimator - pos:", hero_animator.global_position, ", size:", hero_animator.size, ", visible:", hero_animator.visible)
	print("EnemyAnimator - pos:", enemy_animator.global_position, ", size:", enemy_animator.size, ", visible:", enemy_animator.visible)
	
	# 检查CharacterSprite
	var hero_sprite = hero_animator.get_node_or_null("CharacterSprite")
	var enemy_sprite = enemy_animator.get_node_or_null("CharacterSprite")
	
	if hero_sprite:
		print("HeroSprite - pos:", hero_sprite.global_position, ", size:", hero_sprite.size, ", color:", hero_sprite.color, ", visible:", hero_sprite.visible)
	if enemy_sprite:
		print("EnemySprite - pos:", enemy_sprite.global_position, ", size:", enemy_sprite.size, ", color:", enemy_sprite.color, ", visible:", enemy_sprite.visible)
	
	print("\n=== 测试完成 ===")
	
	# 等待5秒后退出
	await create_timer(5.0).timeout
	quit()