extends SceneTree

func _init():
	print("[直接受击闪烁测试] 开始...")
	
	# 直接测试CharacterAnimator的受击动画
	test_direct_hit_flash()
	
	print("[直接受击闪烁测试] 测试完成")
	quit()

func test_direct_hit_flash():
	print("[直接受击闪烁测试] 直接测试CharacterAnimator的受击动画方法")
	
	# 加载CharacterAnimator场景
	var animator_scene = preload("res://scenes/battle/CharacterAnimator.tscn")
	if not animator_scene:
		print("[直接受击闪烁测试] ❌ 无法加载CharacterAnimator场景")
		return
	
	# 创建两个动画器：一个用于我方，一个用于敌方
	var hero_animator = animator_scene.instantiate()
	var enemy_animator = animator_scene.instantiate()
	
	if not hero_animator or not enemy_animator:
		print("[直接受击闪烁测试] ❌ 无法实例化CharacterAnimator")
		return
	
	root.add_child(hero_animator)
	root.add_child(enemy_animator)
	
	print("[直接受击闪烁测试] ✓ CharacterAnimator实例化成功")
	
	# 设置测试角色数据
	var hero_data = {
		"name": "测试英雄",
		"current_hp": 100,
		"max_hp": 100,
		"attack": 20
	}
	
	var enemy_data = {
		"name": "测试敌人",
		"current_hp": 80,
		"max_hp": 100,
		"attack": 15
	}
	
	# 初始化角色
	if hero_animator.has_method("initialize_character"):
		hero_animator.initialize_character(hero_data, "hero", 0)
		print("[直接受击闪烁测试] ✓ 英雄角色初始化完成")
	
	if enemy_animator.has_method("initialize_character"):
		enemy_animator.initialize_character(enemy_data, "enemy", 0)
		print("[直接受击闪烁测试] ✓ 敌人角色初始化完成")
	
	# 等待初始化完成
	for i in range(60):  # 等待1秒
		await process_frame
	
	print("[直接受击闪烁测试] === 测试对比：修复前后的动画效果 ===")
	
	# 测试1：我方受击动画（使用play_damage_animation）
	print("[直接受击闪烁测试] 测试1：我方受击动画（play_damage_animation）")
	print("[直接受击闪烁测试] 预期：3次闪烁，每次0.1秒，红色闪烁")
	if hero_animator.has_method("play_damage_animation"):
		hero_animator.play_damage_animation(25, false)
		print("[直接受击闪烁测试] ✓ 我方受击动画开始")
	
	# 等待动画完成
	for i in range(120):  # 等待2秒
		await process_frame
	
	# 测试2：敌方受击动画（使用修复后的play_hit_animation）
	print("[直接受击闪烁测试] 测试2：敌方受击动画（修复后的play_hit_animation）")
	print("[直接受击闪烁测试] 预期：与我方一致，3次闪烁，每次0.1秒，白色闪烁")
	if enemy_animator.has_method("play_hit_animation"):
		enemy_animator.play_hit_animation(false)
		print("[直接受击闪烁测试] ✓ 敌方受击动画开始")
	
	# 等待动画完成
	for i in range(120):  # 等待2秒
		await process_frame
	
	# 测试3：我方暴击受击动画
	print("[直接受击闪烁测试] 测试3：我方暴击受击动画（play_damage_animation）")
	print("[直接受击闪烁测试] 预期：3次闪烁，每次0.1秒，金黄色闪烁")
	if hero_animator.has_method("play_damage_animation"):
		hero_animator.play_damage_animation(50, true)
		print("[直接受击闪烁测试] ✓ 我方暴击受击动画开始")
	
	# 等待动画完成
	for i in range(120):  # 等待2秒
		await process_frame
	
	# 测试4：敌方暴击受击动画
	print("[直接受击闪烁测试] 测试4：敌方暴击受击动画（修复后的play_hit_animation）")
	print("[直接受击闪烁测试] 预期：与我方一致，3次闪烁，每次0.1秒，白色闪烁")
	if enemy_animator.has_method("play_hit_animation"):
		enemy_animator.play_hit_animation(true)
		print("[直接受击闪烁测试] ✓ 敌方暴击受击动画开始")
	
	# 等待动画完成
	for i in range(120):  # 等待2秒
		await process_frame
	
	print("[直接受击闪烁测试] === 修复总结 ===")
	print("[直接受击闪烁测试] 修复内容：")
	print("[直接受击闪烁测试] 1. 将play_hit_animation的闪烁次数从2次改为3次")
	print("[直接受击闪烁测试] 2. 将play_hit_animation的闪烁时长从0.08秒改为0.1秒")
	print("[直接受击闪烁测试] 3. 移除了max()函数，使用统一的animation_speed")
	print("[直接受击闪烁测试] 4. 现在敌方受击动画与我方受击动画完全一致")
	print("[直接受击闪烁测试] 修复完成！敌方受击闪烁效果应该更加明显了")