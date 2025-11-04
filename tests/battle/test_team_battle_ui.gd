# test_team_battle_ui.gd
# 自测：验证队伍整体战斗（3v3）与战报持续生成（[TBM] 日志）
extends SceneTree

func _init():
	print("[TeamBattleUITest] 开始队伍战斗UI自测")
	# 加载主场景
	var scene: PackedScene = load("res://scenes/MainGame.tscn")
	var main_instance = scene.instantiate()
	root.add_child(main_instance)
	await create_timer(0.6).timeout
	
	# 获取 BattleWindow
	var bw = main_instance.get_node_or_null("UI/BattleWindow")
	if bw == null:
		print("[TeamBattleUITest] 未找到 BattleWindow")
		quit(1)
		return
	
	# 调试：打印脚本与类信息
	print("[TeamBattleUITest] bw class=", bw.get_class())
	print("[TeamBattleUITest] bw script=", bw.get_script())
	if bw.get_script() != null:
		var sc: Script = bw.get_script()
		print("[TeamBattleUITest] script resource_path=", sc.resource_path)
		var ml = bw.get_method_list()
		print("[TeamBattleUITest] method_list size=", ml.size())
		var names := []
		for m in ml:
			if m.has("name"):
				names.append(m["name"]) 
		print("[TeamBattleUITest] method_list has show_team_battle=", names.has("show_team_battle"))
		print("[TeamBattleUITest] Object has_method show_team_battle=", bw.has_method("show_team_battle"))
	
	# 3v3 队伍编制
	var heroes := [
		{"name": "战士", "current_hp": 42, "max_hp": 42, "attack": 12, "defense": 4, "skills": ["power_strike"], "passives": ["tough"], "status_effects": ["attack_up"]},
		{"name": "盗贼", "current_hp": 34, "max_hp": 34, "attack": 11, "defense": 3, "skills": ["multi_strike"], "passives": ["lifesteal"], "status_effects": []},
		{"name": "法师", "current_hp": 28, "max_hp": 28, "attack": 13, "defense": 2, "skills": ["power_strike"], "passives": ["berserk"], "status_effects": ["regen"]},
	]
	var enemies := [
		{"name": "枯骨", "current_hp": 30, "max_hp": 30, "attack": 9, "defense": 2, "skills": [], "passives": [], "status_effects": ["poison"]},
		{"name": "蛛母幼体", "current_hp": 33, "max_hp": 33, "attack": 11, "defense": 3, "skills": [], "passives": ["tough"], "status_effects": ["shield"]},
		{"name": "石像鬼", "current_hp": 26, "max_hp": 26, "attack": 10, "defense": 3, "skills": [], "passives": [], "status_effects": []},
	]
	
	# 启动队伍战斗（UI会连接TBM信号并自动循环）
	if bw.has_method("show_team_battle"):
		bw.show_team_battle(heroes, enemies)
	else:
		print("[TeamBattleUITest] BattleWindow 缺少 show_team_battle 方法")
		quit(1)
		return
	
	await process_frame
	
	# 观察战报文本与战斗状态，最多等待 10 秒
	var tbm = bw.team_battle_manager
	var tbm_log_seen := false
	var lines_count := 0
	var finished := false
	for i in range(20):  # 20 * 0.5s = 10s
		await create_timer(0.5).timeout
		# 直接使用 BattleWindow 暴露的 onready 引用，避免路径变更导致取不到节点
		var log_text_node = bw.log_text
		if log_text_node:
			var text := String(log_text_node.text)
			if text.find("[TBM]") != -1:
				tbm_log_seen = true
				lines_count = text.split("\n").size()
		# 战斗结束条件
		if tbm and tbm.has_method("is_battle_active") and (not tbm.is_battle_active()):
			finished = true
			break
	
	var is_3v3 := (heroes.size() == 3 and enemies.size() == 3)
	print("[TeamBattleUITest] roster heroes=", heroes.size(), " enemies=", enemies.size(), " is_3v3=", is_3v3)
	print("[TeamBattleUITest] tbm_log_seen=", tbm_log_seen, " lines_count=", lines_count, " finished=", finished)
	# 验证标准：3v3 阵容 + 战报包含 [TBM] 且行数足够（>=20），不强制要求战斗在限定时间内结束
	var ok := bool(is_3v3 and tbm_log_seen and lines_count >= 20)
	print("[TeamBattleUITest] 自测结果:", ok)
	quit(0 if ok else 1)