extends SceneTree

func _init():
	print("[TMP] Begin TBM instantiation test")
	print("[TMP] typeof TeamBattleManager:", typeof(TeamBattleManager))
	var ok = false
	var tbm = null
	# Try global class new()
	if typeof(TeamBattleManager) == TYPE_OBJECT and not (TeamBattleManager is Script):
		print("[TMP] Using TeamBattleManager.new()")
		tbm = TeamBattleManager.new()
		ok = tbm != null
	else:
		print("[TMP] Symbol is Script; attempting load().new()")
		var s = load("res://scripts/TeamBattleManager.gd")
		print("[TMP] loaded script:", s, " can_instantiate:", (s != null and s.can_instantiate()))
		if s != null and s.can_instantiate():
			# In Godot 4, script.new() should instantiate the class if can_instantiate()==true
			tbm = s.new()
			ok = tbm != null
		else:
			var n = Node.new()
			if s != null:
				n.set_script(s)
				ok = true
				tbm = n
	print("[TMP] tbm:", tbm, " ok:", ok)
	if tbm:
		print("[TMP] tbm has start_battle:", tbm.has_method("start_battle"))
		print("[TMP] tbm script:", tbm.get_script())
		var sc = tbm.get_script()
		if sc:
			print("[TMP] script global_name:", sc.get_global_name())
			print("[TMP] script base:", sc.get_instance_base_type())
			print("[TMP] script signals exist battle_started:", sc.has_script_signal("battle_started"))
			print("[TMP] script signals exist damage_dealt:", sc.has_script_signal("damage_dealt"))
	print("[TMP] End TBM instantiation test")
	quit()