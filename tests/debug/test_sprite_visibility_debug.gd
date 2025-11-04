extends SceneTree

func _init():
	print("[深度诊断] 开始检查CharacterSprite节点状态...")
	
	# 加载CharacterAnimator场景
	var character_animator_scene = load("res://scenes/battle/CharacterAnimator.tscn")
	if not character_animator_scene:
		print("[错误] 无法加载CharacterAnimator场景")
		quit()
		return
	
	# 实例化CharacterAnimator
	var character_animator = character_animator_scene.instantiate()
	if not character_animator:
		print("[错误] 无法实例化CharacterAnimator")
		quit()
		return
	
	# 添加到场景树
	root.add_child(character_animator)
	
	# 初始化角色数据
	var character_data = {
		"name": "测试角色",
		"sprite_path": "res://assets/sprites/characters/hero.png",
		"max_health": 100,
		"current_health": 80
	}
	
	character_animator.initialize_character(character_data, "hero", 0)
	
	# 等待一帧确保初始化完成
	await process_frame
	
	# 检查CharacterSprite节点
	var character_sprite = character_animator.get_node_or_null("CharacterSprite")
	if not character_sprite:
		print("[错误] 找不到CharacterSprite节点")
		# 尝试查找所有子节点
		print("[调试] CharacterAnimator的所有子节点:")
		_print_all_children(character_animator, 0)
		quit()
		return
	
	print("[成功] 找到CharacterSprite节点: ", character_sprite)
	print("[调试] CharacterSprite类型: ", character_sprite.get_class())
	print("[调试] CharacterSprite可见性: ", character_sprite.visible)
	print("[调试] CharacterSprite透明度: ", character_sprite.modulate.a)
	print("[调试] CharacterSprite位置: ", character_sprite.position)
	print("[调试] CharacterSprite缩放: ", character_sprite.scale)
	print("[调试] CharacterSprite z_index: ", character_sprite.z_index)
	
	# 检查父节点层级
	print("\n[层级检查] CharacterSprite的父节点链:")
	var current_node = character_sprite
	var level = 0
	while current_node:
		var indent = "  ".repeat(level)
		print(indent + "- " + current_node.name + " (" + current_node.get_class() + ")")
		print(indent + "  可见: " + str(current_node.visible))
		print(indent + "  调制: " + str(current_node.modulate))
		if current_node.has_method("get_z_index"):
			print(indent + "  z_index: " + str(current_node.z_index))
		current_node = current_node.get_parent()
		level += 1
	
	# 检查纹理
	if character_sprite.has_method("get_texture"):
		var texture = character_sprite.texture
		print("\n[纹理检查] CharacterSprite纹理: ", texture)
		if texture:
			print("[纹理检查] 纹理大小: ", texture.get_size())
		else:
			print("[警告] CharacterSprite没有纹理!")
	
	# 检查是否在视口内
	print("\n[视口检查] 检查节点是否在视口内...")
	var viewport = root.get_viewport()
	if viewport:
		print("[视口检查] 视口大小: ", viewport.get_visible_rect().size)
		var global_pos = character_sprite.global_position
		print("[视口检查] CharacterSprite全局位置: ", global_pos)
		var viewport_rect = viewport.get_visible_rect()
		var in_viewport = viewport_rect.has_point(global_pos)
		print("[视口检查] 是否在视口内: ", in_viewport)
	
	# 测试直接颜色变化
	print("\n[颜色测试] 测试直接颜色变化...")
	print("[颜色测试] 原始modulate: ", character_sprite.modulate)
	
	# 设置极亮白色
	character_sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	print("[颜色测试] 设置极亮白色后: ", character_sprite.modulate)
	
	# 等待一秒
	await create_tween().tween_interval(1.0).finished
	
	# 恢复原色
	character_sprite.modulate = Color.WHITE
	print("[颜色测试] 恢复原色后: ", character_sprite.modulate)
	
	# 测试红色闪烁
	print("\n[红色测试] 测试红色闪烁...")
	character_sprite.modulate = Color(3.0, 0.5, 0.5, 1.0)
	print("[红色测试] 设置红色后: ", character_sprite.modulate)
	
	await create_tween().tween_interval(1.0).finished
	
	character_sprite.modulate = Color.WHITE
	print("[红色测试] 恢复原色后: ", character_sprite.modulate)
	
	# 检查是否有其他影响可见性的组件
	print("\n[组件检查] 检查可能影响可见性的组件...")
	_check_visibility_affecting_components(character_animator)
	
	print("\n[深度诊断] 检查完成")
	quit()

func _print_all_children(node: Node, level: int):
	var indent = "  ".repeat(level)
	print(indent + "- " + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_all_children(child, level + 1)

func _check_visibility_affecting_components(node: Node):
	# 检查CanvasLayer
	var canvas_layers = []
	_find_nodes_of_type(node, "CanvasLayer", canvas_layers)
	if canvas_layers.size() > 0:
		print("[组件检查] 找到CanvasLayer节点: ", canvas_layers.size(), "个")
		for layer in canvas_layers:
			print("  - " + layer.name + ", layer: " + str(layer.layer))
	
	# 检查Camera2D
	var cameras = []
	_find_nodes_of_type(node, "Camera2D", cameras)
	if cameras.size() > 0:
		print("[组件检查] 找到Camera2D节点: ", cameras.size(), "个")
		for camera in cameras:
			print("  - " + camera.name + ", enabled: " + str(camera.enabled))
	
	# 检查AnimationPlayer
	var animation_players = []
	_find_nodes_of_type(node, "AnimationPlayer", animation_players)
	if animation_players.size() > 0:
		print("[组件检查] 找到AnimationPlayer节点: ", animation_players.size(), "个")
		for player in animation_players:
			print("  - " + player.name + ", current: " + str(player.current_animation))

func _find_nodes_of_type(node: Node, type_name: String, result_array: Array):
	if node.get_class() == type_name:
		result_array.append(node)
	for child in node.get_children():
		_find_nodes_of_type(child, type_name, result_array)