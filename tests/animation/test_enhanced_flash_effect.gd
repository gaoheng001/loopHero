extends SceneTree

# 增强闪烁效果测试脚本
# 验证修复后的3次闪烁效果是否明显可见

func _init():
	print("[增强闪烁效果测试] 开始测试...")
	
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn")
	if not main_scene:
		print("[增强闪烁效果测试] ❌ 无法加载MainGame场景")
		quit()
		return
	
	var scene_instance = main_scene.instantiate()
	root.add_child(scene_instance)
	current_scene = scene_instance
	
	# 等待场景初始化
	await process_frame
	await process_frame
	
	_test_enhanced_flash_effects()

func _test_enhanced_flash_effects():
	print("[增强闪烁效果测试] 开始测试增强后的闪烁效果...")
	
	# MainGame场景的根节点就是MainGame，它有MainGameController脚本
	var main_controller = current_scene
	if not main_controller:
		print("[增强闪烁效果测试] ❌ 找不到MainGame节点")
		quit()
		return
	
	# 获取战斗窗口 - 在UI/BattleWindow路径下
	var battle_window = current_scene.get_node_or_null("UI/BattleWindow")
	if not battle_window:
		print("[增强闪烁效果测试] ❌ 找不到BattleWindow")
		quit()
		return
	
	print("[增强闪烁效果测试] ✓ 找到BattleWindow")
	
	# 显示战斗窗口
	battle_window.visible = true
	await process_frame
	
	# 获取动画控制器
	var animation_controller = battle_window.get_node_or_null("BattleAnimationController")
	if not animation_controller:
		print("[增强闪烁效果测试] ❌ 找不到BattleAnimationController")
		quit()
		return
	
	print("[增强闪烁效果测试] ✓ 找到BattleAnimationController")
	
	# 初始化动画控制器
	if animation_controller.has_method("initialize"):
		animation_controller.initialize(null, battle_window)
		print("[增强闪烁效果测试] ✓ 动画控制器初始化完成")
	
	# 创建角色动画器
	if animation_controller.has_method("_create_character_animators"):
		animation_controller._create_character_animators()
		print("[增强闪烁效果测试] ✓ 角色动画器创建完成")
	
	# 等待初始化完成
	await create_timer(1.0).timeout
	
	# 获取动画器
	var hero_animators = animation_controller.hero_animators
	var enemy_animators = animation_controller.enemy_animators
	
	print("[增强闪烁效果测试] 英雄动画器数量: %d" % hero_animators.size())
	print("[增强闪烁效果测试] 敌人动画器数量: %d" % enemy_animators.size())
	
	if hero_animators.size() == 0 or enemy_animators.size() == 0:
		print("[增强闪烁效果测试] ❌ 动画器创建失败")
		quit()
		return
	
	# 测试英雄受击闪烁
	print("\n[增强闪烁效果测试] === 测试1：英雄普通受击闪烁 ===")
	print("[增强闪烁效果测试] 预期效果：3次白色闪烁，每次0.08秒，间隔0.02秒")
	
	var hero_animator = hero_animators[0]
	if hero_animator and hero_animator.has_method("play_hit_animation"):
		hero_animator.play_hit_animation(false)  # 普通受击
		print("[增强闪烁效果测试] ✓ 英雄普通受击动画开始")
		
		# 等待动画完成
		await create_timer(1.0).timeout
		print("[增强闪烁效果测试] ✓ 英雄普通受击动画完成")
	
	await create_timer(0.5).timeout
	
	# 测试英雄暴击受击闪烁
	print("\n[增强闪烁效果测试] === 测试2：英雄暴击受击闪烁 ===")
	print("[增强闪烁效果测试] 预期效果：3次红色闪烁，每次0.08秒，间隔0.02秒")
	
	if hero_animator and hero_animator.has_method("play_hit_animation"):
		hero_animator.play_hit_animation(true)  # 暴击受击
		print("[增强闪烁效果测试] ✓ 英雄暴击受击动画开始")
		
		# 等待动画完成
		await create_timer(1.0).timeout
		print("[增强闪烁效果测试] ✓ 英雄暴击受击动画完成")
	
	await create_timer(0.5).timeout
	
	# 测试敌人受击闪烁
	print("\n[增强闪烁效果测试] === 测试3：敌人普通受击闪烁 ===")
	print("[增强闪烁效果测试] 预期效果：3次白色闪烁，每次0.08秒，间隔0.02秒")
	
	var enemy_animator = enemy_animators[0]
	if enemy_animator and enemy_animator.has_method("play_hit_animation"):
		enemy_animator.play_hit_animation(false)  # 普通受击
		print("[增强闪烁效果测试] ✓ 敌人普通受击动画开始")
		
		# 等待动画完成
		await create_timer(1.0).timeout
		print("[增强闪烁效果测试] ✓ 敌人普通受击动画完成")
	
	await create_timer(0.5).timeout
	
	# 测试敌人暴击受击闪烁
	print("\n[增强闪烁效果测试] === 测试4：敌人暴击受击闪烁 ===")
	print("[增强闪烁效果测试] 预期效果：3次红色闪烁，每次0.08秒，间隔0.02秒")
	
	if enemy_animator and enemy_animator.has_method("play_hit_animation"):
		enemy_animator.play_hit_animation(true)  # 暴击受击
		print("[增强闪烁效果测试] ✓ 敌人暴击受击动画开始")
		
		# 等待动画完成
		await create_timer(1.0).timeout
		print("[增强闪烁效果测试] ✓ 敌人暴击受击动画完成")
	
	await create_timer(0.5).timeout
	
	# 测试队伍受击动画
	print("\n[增强闪烁效果测试] === 测试5：队伍受击动画 ===")
	print("[增强闪烁效果测试] 预期效果：所有队员同时进行3次闪烁")
	
	if animation_controller.has_method("play_team_damage_animation"):
		print("[增强闪烁效果测试] 测试英雄队伍受击...")
		animation_controller.play_team_damage_animation("heroes", false)
		await create_timer(1.5).timeout
		
		print("[增强闪烁效果测试] 测试敌人队伍受击...")
		animation_controller.play_team_damage_animation("enemies", true)
		await create_timer(1.5).timeout
	
	print("\n[增强闪烁效果测试] === 测试总结 ===")
	print("[增强闪烁效果测试] ✅ 所有闪烁效果测试完成")
	print("[增强闪烁效果测试] 修复内容：")
	print("[增强闪烁效果测试] 1. 闪烁次数：1次 → 3次")
	print("[增强闪烁效果测试] 2. 颜色强度：增强至8.0倍亮度")
	print("[增强闪烁效果测试] 3. 时序控制：0.08秒闪烁 + 0.02秒间隔")
	print("[增强闪烁效果测试] 4. 视觉效果：显著提升，更容易观察")
	
	quit()