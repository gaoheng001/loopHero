extends SceneTree

# 平衡战斗测试 - 让敌方有机会攻击

func _init():
	print("[平衡战斗测试] 开始初始化...")

func _ready():
	print("[平衡战斗测试] 场景树就绪")
	
	# 等待一帧确保所有节点加载完成
	await process_frame
	
	# 查找并修改GameManager中的英雄属性
	var game_manager = _find_node_recursive(root, "GameManager")
	if game_manager:
		print("[平衡战斗测试] ✓ 找到GameManager")
		_weaken_heroes(game_manager)
	else:
		print("[平衡战斗测试] ✗ 未找到GameManager")
	
	# 启动正常游戏流程
	print("[平衡战斗测试] 启动游戏...")

func _weaken_heroes(game_manager):
	"""大幅削弱英雄属性，让敌方有机会攻击"""
	var hero_manager = game_manager.get("hero_manager")
	if not hero_manager:
		print("[平衡战斗测试] ✗ 未找到HeroManager")
		return
	
	var heroes = hero_manager.get("heroes")
	if not heroes or heroes.size() == 0:
		print("[平衡战斗测试] ✗ 没有英雄数据")
		return
	
	print("[平衡战斗测试] 修改 %d 个英雄的属性..." % heroes.size())
	
	for i in range(heroes.size()):
		var hero = heroes[i]
		if hero is Dictionary:
			# 大幅降低英雄属性
			hero["max_hp"] = 30
			hero["hp"] = 30
			hero["current_hp"] = 30
			hero["attack"] = 3
			hero["defense"] = 0
			
			print("[平衡战斗测试] 英雄[%d] %s: HP=%d, ATK=%d, DEF=%d" % [
				i, hero.get("name", "未知"), hero.get("hp", 0), 
				hero.get("attack", 0), hero.get("defense", 0)
			])
	
	print("[平衡战斗测试] ✓ 英雄属性已削弱")

func _find_node_recursive(node: Node, target_name: String) -> Node:
	"""递归查找指定名称的节点"""
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_recursive(child, target_name)
		if result:
			return result
	
	return null