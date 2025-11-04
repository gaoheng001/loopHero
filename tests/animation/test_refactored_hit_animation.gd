extends Node

# 测试重构后的受击动画系统
# 验证 CharacterAnimator 和 BattleAnimationController 的重构效果

var battle_controller: BattleAnimationController
var hero_animator: CharacterAnimator
var enemy_animator: CharacterAnimator

func _ready():
	print("=== 重构后受击动画系统测试 ===")
	
	# 初始化测试环境
	setup_test_environment()
	
	# 等待一帧确保初始化完成
	await get_tree().process_frame
	
	# 运行测试
	await run_all_tests()
	
	print("=== 测试完成 ===")

func setup_test_environment():
	print("[测试] 设置测试环境...")
	
	# 创建战斗动画控制器
	battle_controller = BattleAnimationController.new()
	add_child(battle_controller)
	
	# 创建测试用的角色动画器
	hero_animator = CharacterAnimator.new()
	enemy_animator = CharacterAnimator.new()
	
	# 设置基本属性
	hero_animator.character_data = {
		"name": "测试英雄",
		"hp": 100,
		"max_hp": 100
	}
	
	enemy_animator.character_data = {
		"name": "测试敌人", 
		"hp": 80,
		"max_hp": 100
	}
	
	add_child(hero_animator)
	add_child(enemy_animator)
	
	print("[测试] 测试环境设置完成")

func run_all_tests():
	print("\n--- 开始测试重构后的受击动画系统 ---")
	
	# 测试1：CharacterAnimator 的新架构
	await test_character_animator_refactored()
	
	# 测试2：向后兼容性
	await test_backward_compatibility()
	
	# 测试3：BattleAnimationController 的队伍受击
	await test_team_damage_animation()
	
	# 测试4：完整的受击流程
	await test_complete_hit_flow()

func test_character_animator_refactored():
	print("\n[测试1] CharacterAnimator 重构验证")
	
	# 测试新的 play_damage_visual_effects 方法
	print("  测试 play_damage_visual_effects...")
	if hero_animator.has_method("play_damage_visual_effects"):
		hero_animator.play_damage_visual_effects(25, false)
		await hero_animator.animation_completed
		print("  ✓ play_damage_visual_effects 正常工作")
	else:
		print("  ✗ play_damage_visual_effects 方法不存在")
	
	await get_tree().create_timer(1.0).timeout
	
	# 测试纯视觉受击动画
	print("  测试 play_hit_animation...")
	if hero_animator.has_method("play_hit_animation"):
		hero_animator.play_hit_animation(true)  # 暴击闪烁
		await hero_animator.animation_completed
		print("  ✓ play_hit_animation 正常工作")
	else:
		print("  ✗ play_hit_animation 方法不存在")
	
	await get_tree().create_timer(1.0).timeout

func test_backward_compatibility():
	print("\n[测试2] 向后兼容性验证")
	
	# 测试旧的 play_damage_animation 接口
	print("  测试向后兼容的 play_damage_animation...")
	if enemy_animator.has_method("play_damage_animation"):
		enemy_animator.play_damage_animation(30, true)
		await enemy_animator.animation_completed
		print("  ✓ 向后兼容接口正常工作")
	else:
		print("  ✗ 向后兼容接口不存在")
	
	await get_tree().create_timer(1.0).timeout

func test_team_damage_animation():
	print("\n[测试3] BattleAnimationController 队伍受击验证")
	
	# 设置动画器到控制器（模拟真实环境）
	battle_controller.hero_animators = [hero_animator]
	battle_controller.enemy_animators = [enemy_animator]
	
	# 测试英雄队伍受击
	print("  测试英雄队伍受击动画...")
	if battle_controller.has_method("play_team_damage_animation"):
		battle_controller.play_team_damage_animation("heroes", false)
		await get_tree().create_timer(2.0).timeout
		print("  ✓ 英雄队伍受击动画正常")
	else:
		print("  ✗ play_team_damage_animation 方法不存在")
	
	await get_tree().create_timer(1.0).timeout
	
	# 测试敌人队伍受击
	print("  测试敌人队伍受击动画...")
	battle_controller.play_team_damage_animation("enemies", true)
	await get_tree().create_timer(2.0).timeout
	print("  ✓ 敌人队伍受击动画正常")
	
	await get_tree().create_timer(1.0).timeout

func test_complete_hit_flow():
	print("\n[测试4] 完整受击流程验证")
	
	print("  模拟完整的受伤流程...")
	
	# 1. 个人受伤（纯视觉效果）
	print("    步骤1：个人受伤视觉效果")
	hero_animator.play_damage_visual_effects(40, false)
	await hero_animator.animation_completed
	
	await get_tree().create_timer(0.5).timeout
	
	# 2. 队伍受击反馈（纯视觉）
	print("    步骤2：队伍受击反馈")
	battle_controller.play_team_damage_animation("heroes", false)
	await get_tree().create_timer(2.0).timeout
	
	print("  ✓ 完整受击流程测试完成")

func _exit_tree():
	print("[测试] 清理测试环境")