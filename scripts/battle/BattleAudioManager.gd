# BattleAudioManager.gd
# 回合攻击表现系统 - 音效管理器
# 负责战斗音效、技能音效、环境音效的播放和管理

class_name BattleAudioManager
extends Node

# 音效信号
signal audio_started(audio_type: String, sound_id: String)
signal audio_finished(audio_type: String, sound_id: String)

# 音效类型枚举
enum AudioType {
	ATTACK,          # 攻击音效
	SKILL,           # 技能音效
	DAMAGE,          # 受伤音效
	HEAL,            # 治疗音效
	CRITICAL,        # 暴击音效
	BLOCK,           # 格挡音效
	MISS,            # 未命中音效
	STATUS,          # 状态效果音效
	ENVIRONMENT,     # 环境音效
	UI               # UI音效
}

# 音效配置
var audio_configs: Dictionary = {
	# 攻击音效
	"basic_attack": {
		"type": AudioType.ATTACK,
		"volume": 0.8,
		"pitch_range": [0.9, 1.1],
		"duration": 0.5
	},
	"power_strike": {
		"type": AudioType.ATTACK,
		"volume": 1.0,
		"pitch_range": [0.8, 1.0],
		"duration": 0.8
	},
	"multi_strike": {
		"type": AudioType.ATTACK,
		"volume": 0.7,
		"pitch_range": [1.0, 1.3],
		"duration": 0.3
	},
	
	# 技能音效
	"fire_skill": {
		"type": AudioType.SKILL,
		"volume": 0.9,
		"pitch_range": [0.9, 1.1],
		"duration": 1.2
	},
	"ice_skill": {
		"type": AudioType.SKILL,
		"volume": 0.8,
		"pitch_range": [0.8, 1.0],
		"duration": 1.5
	},
	"heal_skill": {
		"type": AudioType.HEAL,
		"volume": 0.7,
		"pitch_range": [1.0, 1.2],
		"duration": 1.0
	},
	"poison_strike": {
		"type": AudioType.SKILL,
		"volume": 0.6,
		"pitch_range": [0.7, 0.9],
		"duration": 0.8
	},
	
	# 状态音效
	"damage_taken": {
		"type": AudioType.DAMAGE,
		"volume": 0.6,
		"pitch_range": [0.8, 1.2],
		"duration": 0.3
	},
	"critical_hit": {
		"type": AudioType.CRITICAL,
		"volume": 1.0,
		"pitch_range": [1.1, 1.3],
		"duration": 0.6
	},
	"block": {
		"type": AudioType.BLOCK,
		"volume": 0.8,
		"pitch_range": [0.9, 1.1],
		"duration": 0.4
	},
	"miss": {
		"type": AudioType.MISS,
		"volume": 0.5,
		"pitch_range": [1.2, 1.5],
		"duration": 0.2
	},
	
	# 状态效果音效
	"poison_apply": {
		"type": AudioType.STATUS,
		"volume": 0.4,
		"pitch_range": [0.6, 0.8],
		"duration": 0.5
	},
	"burn_apply": {
		"type": AudioType.STATUS,
		"volume": 0.5,
		"pitch_range": [0.8, 1.0],
		"duration": 0.4
	},
	"shield_apply": {
		"type": AudioType.STATUS,
		"volume": 0.6,
		"pitch_range": [1.0, 1.2],
		"duration": 0.6
	},
	
	# 环境音效
	"battle_start": {
		"type": AudioType.ENVIRONMENT,
		"volume": 0.7,
		"pitch_range": [1.0, 1.0],
		"duration": 2.0
	},
	"battle_end": {
		"type": AudioType.ENVIRONMENT,
		"volume": 0.8,
		"pitch_range": [1.0, 1.0],
		"duration": 1.5
	},
	"turn_start": {
		"type": AudioType.ENVIRONMENT,
		"volume": 0.3,
		"pitch_range": [1.0, 1.0],
		"duration": 0.5
	}
}

# 音频播放器池
var audio_players: Dictionary = {}
var available_players: Array[AudioStreamPlayer] = []
var active_players: Array[AudioStreamPlayer] = []

# 音效设置
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.7
var audio_enabled: bool = true

# 音频资源缓存
var audio_cache: Dictionary = {}

func _ready():
	"""初始化音效管理器"""
	_initialize_audio_players()
	_load_audio_resources()
	print("[BattleAudioManager] 音效管理器初始化完成")

func _initialize_audio_players():
	"""初始化音频播放器池"""
	# 创建多个音频播放器以支持同时播放多个音效
	for i in range(10):
		var player = AudioStreamPlayer.new()
		player.name = "AudioPlayer_%d" % i
		player.finished.connect(_on_audio_player_finished.bind(player))
		add_child(player)
		available_players.append(player)

func _load_audio_resources():
	"""加载音频资源（使用程序生成的音效）"""
	# 由于没有实际音频文件，我们使用程序生成的简单音效
	for sound_id in audio_configs.keys():
		var config = audio_configs[sound_id]
		var audio_stream = _generate_audio_stream(config)
		if audio_stream:
			audio_cache[sound_id] = audio_stream

func _generate_audio_stream(config: Dictionary) -> AudioStream:
	"""生成程序音效流"""
	# 创建一个简单的音频流生成器
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.1
	return generator

# ============ 公共接口 ============

func play_attack_sound(attack_type: String = "basic_attack", attacker: Node = null, target: Node = null):
	"""播放攻击音效"""
	if not audio_enabled:
		return
	
	emit_signal("audio_started", "attack", attack_type)
	
	var player = _get_available_player()
	if player and audio_cache.has(attack_type):
		var config = audio_configs.get(attack_type, {})
		_configure_player(player, config)
		player.stream = audio_cache[attack_type]
		player.play()
		
		# 添加到活跃播放器列表
		active_players.append(player)
		
		print("[BattleAudioManager] 播放攻击音效: %s" % attack_type)
	else:
		# 使用程序生成的音效
		_play_generated_sound(attack_type, AudioType.ATTACK)

func play_skill_sound(skill_id: String, caster: Node = null, targets: Array = []):
	"""播放技能音效"""
	if not audio_enabled:
		return
	
	emit_signal("audio_started", "skill", skill_id)
	
	var player = _get_available_player()
	if player and audio_cache.has(skill_id):
		var config = audio_configs.get(skill_id, {})
		_configure_player(player, config)
		player.stream = audio_cache[skill_id]
		player.play()
		
		active_players.append(player)
		print("[BattleAudioManager] 播放技能音效: %s" % skill_id)
	else:
		_play_generated_sound(skill_id, AudioType.SKILL)

func play_damage_sound(damage_amount: int, is_critical: bool = false, target: Node = null):
	"""播放受伤音效"""
	if not audio_enabled:
		return
	
	var sound_id = "critical_hit" if is_critical else "damage_taken"
	emit_signal("audio_started", "damage", sound_id)
	
	var player = _get_available_player()
	if player:
		var config = audio_configs.get(sound_id, {})
		_configure_player(player, config)
		
		# 根据伤害量调整音调
		var pitch_modifier = 1.0 + (damage_amount / 100.0) * 0.2
		player.pitch_scale = clamp(pitch_modifier, 0.5, 2.0)
		
		_play_generated_sound(sound_id, AudioType.DAMAGE)
		print("[BattleAudioManager] 播放受伤音效: %s (伤害: %d)" % [sound_id, damage_amount])

func play_heal_sound(heal_amount: int, target: Node = null):
	"""播放治疗音效"""
	if not audio_enabled:
		return
	
	emit_signal("audio_started", "heal", "heal_skill")
	_play_generated_sound("heal_skill", AudioType.HEAL)
	print("[BattleAudioManager] 播放治疗音效 (治疗: %d)" % heal_amount)

func play_status_sound(status_id: String, action: String = "apply", target: Node = null):
	"""播放状态效果音效"""
	if not audio_enabled:
		return
	
	var sound_id = status_id + "_" + action
	emit_signal("audio_started", "status", sound_id)
	
	if audio_configs.has(sound_id):
		_play_generated_sound(sound_id, AudioType.STATUS)
		print("[BattleAudioManager] 播放状态音效: %s" % sound_id)

func play_environment_sound(event_type: String):
	"""播放环境音效"""
	if not audio_enabled:
		return
	
	emit_signal("audio_started", "environment", event_type)
	
	if audio_configs.has(event_type):
		_play_generated_sound(event_type, AudioType.ENVIRONMENT)
		print("[BattleAudioManager] 播放环境音效: %s" % event_type)

func play_ui_sound(ui_action: String):
	"""播放UI音效"""
	if not audio_enabled:
		return
	
	emit_signal("audio_started", "ui", ui_action)
	
	# 简单的UI音效
	match ui_action:
		"button_click":
			_play_generated_sound("button_click", AudioType.UI)
		"button_hover":
			_play_generated_sound("button_hover", AudioType.UI)
		"window_open":
			_play_generated_sound("window_open", AudioType.UI)
		"window_close":
			_play_generated_sound("window_close", AudioType.UI)

func stop_all_sounds():
	"""停止所有音效"""
	for player in active_players:
		if player and is_instance_valid(player) and player.playing:
			player.stop()
	
	active_players.clear()
	available_players.append_array(active_players)

func set_master_volume(volume: float):
	"""设置主音量"""
	master_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

func set_sfx_volume(volume: float):
	"""设置音效音量"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

func set_music_volume(volume: float):
	"""设置音乐音量"""
	music_volume = clamp(volume, 0.0, 1.0)

func set_audio_enabled(enabled: bool):
	"""设置音效开关"""
	audio_enabled = enabled
	if not enabled:
		stop_all_sounds()

func set_audio_speed(speed: float):
	"""设置音频播放速度"""
	speed = clamp(speed, 0.1, 3.0)  # 限制速度范围
	
	# 更新所有正在播放的音频的播放速度
	for player in active_players:
		if player and is_instance_valid(player) and player.playing:
			player.pitch_scale = speed
	
	print("[BattleAudioManager] 音频速度设置为: %f" % speed)

func is_playing_audio() -> bool:
	"""检查是否有音效正在播放"""
	return active_players.size() > 0

# ============ 内部方法 ============

func _get_available_player() -> AudioStreamPlayer:
	"""获取可用的音频播放器"""
	if available_players.size() > 0:
		return available_players.pop_back()
	
	# 如果没有可用播放器，创建新的
	var player = AudioStreamPlayer.new()
	player.name = "AudioPlayer_Extra_%d" % get_children().size()
	player.finished.connect(_on_audio_player_finished.bind(player))
	add_child(player)
	return player

func _configure_player(player: AudioStreamPlayer, config: Dictionary):
	"""配置音频播放器"""
	var volume = config.get("volume", 1.0) * sfx_volume * master_volume
	player.volume_db = linear_to_db(volume)
	
	var pitch_range = config.get("pitch_range", [1.0, 1.0])
	player.pitch_scale = randf_range(pitch_range[0], pitch_range[1])

func _play_generated_sound(sound_id: String, audio_type: AudioType):
	"""播放程序生成的音效"""
	var player = _get_available_player()
	if not player:
		return
	
	var config = audio_configs.get(sound_id, {})
	_configure_player(player, config)
	
	# 创建简单的音效生成器
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.1
	
	player.stream = generator
	player.play()
	
	active_players.append(player)
	
	# 根据音效类型设置不同的播放时长
	var duration = config.get("duration", 0.5)
	await get_tree().create_timer(duration).timeout
	
	if player and is_instance_valid(player) and player.playing:
		player.stop()

func _update_all_volumes():
	"""更新所有播放器的音量"""
	for player in active_players:
		if player and is_instance_valid(player):
			var base_volume = 1.0  # 可以从配置中获取
			var volume = base_volume * sfx_volume * master_volume
			player.volume_db = linear_to_db(volume)

func _on_audio_player_finished(player: AudioStreamPlayer):
	"""音频播放器播放完成处理"""
	if player in active_players:
		active_players.erase(player)
		available_players.append(player)
	
	# 发送音效结束信号
	emit_signal("audio_finished", "unknown", "unknown")

# ============ 预设音效方法 ============

func play_battle_start_audio():
	"""播放战斗开始音效"""
	play_environment_sound("battle_start")

func play_battle_end_audio(winner: String):
	"""播放战斗结束音效"""
	play_environment_sound("battle_end")

func play_turn_start_audio():
	"""播放回合开始音效"""
	play_environment_sound("turn_start")

func play_victory_audio():
	"""播放胜利音效"""
	play_environment_sound("battle_end")
	print("[BattleAudioManager] 播放胜利音效")

func play_defeat_audio():
	"""播放失败音效"""
	play_environment_sound("battle_end")
	print("[BattleAudioManager] 播放失败音效")

func play_critical_hit_audio():
	"""播放暴击音效"""
	play_damage_sound(100, true)

func play_miss_audio():
	"""播放未命中音效"""
	_play_generated_sound("miss", AudioType.MISS)

func play_block_audio():
	"""播放格挡音效"""
	_play_generated_sound("block", AudioType.BLOCK)

# ============ 音效组合播放 ============

func play_attack_sequence(attack_type: String, attacker: Node, target: Node, damage: int, is_critical: bool):
	"""播放完整的攻击音效序列"""
	# 播放攻击音效
	play_attack_sound(attack_type, attacker, target)
	
	# 延迟播放受伤音效
	await get_tree().create_timer(0.2).timeout
	play_damage_sound(damage, is_critical, target)

func play_skill_sequence(skill_id: String, caster: Node, targets: Array, effects: Array = []):
	"""播放完整的技能音效序列"""
	# 播放技能释放音效
	play_skill_sound(skill_id, caster, targets)
	
	# 延迟播放状态效果音效
	await get_tree().create_timer(0.5).timeout
	for effect in effects:
		play_status_sound(effect, "apply")
		await get_tree().create_timer(0.1).timeout

# ============ 音效配置管理 ============

func add_custom_audio_config(sound_id: String, config: Dictionary):
	"""添加自定义音效配置"""
	audio_configs[sound_id] = config

func remove_audio_config(sound_id: String):
	"""移除音效配置"""
	if audio_configs.has(sound_id):
		audio_configs.erase(sound_id)
	if audio_cache.has(sound_id):
		audio_cache.erase(sound_id)

func get_audio_config(sound_id: String) -> Dictionary:
	"""获取音效配置"""
	return audio_configs.get(sound_id, {})

func get_all_audio_configs() -> Dictionary:
	"""获取所有音效配置"""
	return audio_configs.duplicate()

func cleanup():
	"""清理音效管理器"""
	stop_all_sounds()
	audio_cache.clear()
	
	for player in get_children():
		if player is AudioStreamPlayer:
			player.queue_free()
	
	available_players.clear()
	active_players.clear()