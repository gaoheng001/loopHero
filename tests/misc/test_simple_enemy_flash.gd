extends SceneTree

func _init():
	print("[简单敌方闪烁测试] 开始...")
	
	# 直接测试CharacterAnimator的闪烁功能
	test_character_animator_flash()
	
	print("[简单敌方闪烁测试] 测试完成")
	quit()

func test_character_animator_flash():
	print("[简单敌方闪烁测试] 测试CharacterAnimator闪烁功能")
	
	# 加载CharacterAnimator场景
	var character_animator_scene = preload("res://scenes/battle/CharacterAnimator.tscn")
	if not character_animator_scene:
		print("[简单敌方闪烁测试] ❌ 无法加载CharacterAnimator场景")
		return
	
	# 实例化CharacterAnimator
	var animator = character_animator_scene.instantiate()
	if not animator:
		print("[简单敌方闪烁测试] ❌ 无法实例化CharacterAnimator")
		return
	
	print("[简单敌方闪烁测试] ✓ CharacterAnimator实例化成功")
	
	# 添加到场景树
	root.add_child(animator)
	
	# 设置测试角色数据
	var test_character = {
		"name": "测试敌人",
		"hp": 50,
		"max_hp": 100,
		"attack": 15
	}
	
	# 初始化角色数据
	if animator.has_method("initialize_character"):
		animator.initialize_character(test_character, "enemy", 0)
		print("[简单敌方闪烁测试] ✓ 角色数据初始化完成")
	else:
		print("[简单敌方闪烁测试] ❌ CharacterAnimator没有initialize_character方法")
		return
	
	# 检查CharacterSprite
	var character_sprite = animator.get_node_or_null("CharacterSprite")
	if not character_sprite:
		print("[简单敌方闪烁测试] ❌ 未找到CharacterSprite节点")
		return
	
	print("[简单敌方闪烁测试] ✓ 找到CharacterSprite节点")
	print("[简单敌方闪烁测试] CharacterSprite初始颜色: ", character_sprite.modulate)
	
	# 测试play_hit_animation方法
	if animator.has_method("play_hit_animation"):
		print("[简单敌方闪烁测试] 开始测试play_hit_animation...")
		animator.play_hit_animation(false)  # 非暴击
		print("[简单敌方闪烁测试] ✓ 敌人非暴击受击闪烁开始")
		
		await get_tree().create_timer(2.0).timeout
		
		animator.play_hit_animation(true)   # 暴击
		print("[简单敌方闪烁测试] ✓ 暴击闪烁方法调用成功")
	else:
		print("[简单敌方闪烁测试] ❌ CharacterAnimator没有play_hit_animation方法")
		
	# 检查是否有闪烁相关的Tween
	var children = animator.get_children()
	var has_tween = false
	for child in children:
		if child is Tween:
			has_tween = true
			print("[简单敌方闪烁测试] ✓ 找到Tween节点: ", child.name)
	
	if not has_tween:
		print("[简单敌方闪烁测试] ⚠️ 未找到Tween节点")