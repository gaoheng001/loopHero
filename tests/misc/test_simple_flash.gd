extends SceneTree

func _init():
	print("[简单测试] 开始测试闪烁动画...")
	
	# 创建一个简单的ColorRect来模拟CharacterSprite
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(80, 80)
	color_rect.color = Color.BLUE  # 蓝色英雄
	
	root.add_child(color_rect)
	
	print("[简单测试] 初始颜色: ", color_rect.color)
	
	# 创建Tween来模拟闪烁动画
	var flash_tween = create_tween()
	flash_tween.set_loops(5)  # 5次循环
	
	# 闪烁到白色
	flash_tween.tween_property(color_rect, "color", Color.WHITE, 0.1)
	# 恢复到蓝色
	flash_tween.tween_property(color_rect, "color", Color.BLUE, 0.1)
	
	# 等待动画完成
	await flash_tween.finished
	
	print("[简单测试] 闪烁完成，最终颜色: ", color_rect.color)
	
	# 测试暴击闪烁（红白色）
	print("[简单测试] 测试暴击闪烁...")
	
	var crit_tween = create_tween()
	crit_tween.set_loops(5)
	
	# 闪烁到红白色
	crit_tween.tween_property(color_rect, "color", Color(1.0, 0.8, 0.8, 1.0), 0.1)
	# 恢复到蓝色
	crit_tween.tween_property(color_rect, "color", Color.BLUE, 0.1)
	
	await crit_tween.finished
	
	print("[简单测试] 暴击闪烁完成，最终颜色: ", color_rect.color)
	print("[简单测试] 测试完成！颜色变化应该是可见的")
	
	quit()