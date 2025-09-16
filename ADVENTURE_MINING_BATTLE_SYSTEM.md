# 《冒险与挖矿》整体回合战斗系统设计文档

## 1. 系统概述

### 1.1 核心理念
基于《冒险与挖矿》的整体回合战斗机制，实现队伍协作的战斗系统，区别于传统的单体回合制战斗。

### 1.2 核心特点
- **队伍整体作战**：最多支持25人队伍（后期可扩展到30人）
- **统一回合判定**：每回合队伍作为整体进行技能触发判定
- **技能优先机制**：有技能触发则释放技能，无技能触发则整队普攻
- **被动技能支撑**：被动技能提供持续的属性加成和特殊效果

## 2. 战斗流程设计

### 2.1 战斗初始化
```
1. 队伍配置验证（1-25人）
2. 被动技能生效（四维属性加成、特殊抗性等）
3. 先攻值计算（基础先攻 + 被动加成）
4. 战斗顺序确定
```

### 2.2 回合执行流程
```
每回合执行顺序：
1. 先攻判定 → 确定行动方（我方/敌方）
2. 技能触发判定 → 按队伍顺序逐个判定概率主动技能
3. 技能执行 → 一旦有技能触发，立即释放并结束本回合
4. 普攻执行 → 若无技能触发，整队进行普攻
5. 伤害结算 → 计算最终伤害（含被动技能加成）
6. 状态更新 → 更新生命值、特殊状态等
7. 胜负判定 → 检查战斗是否结束
```

### 2.3 技能触发机制
```
技能判定顺序：
- 按队伍中角色的排列顺序（1号位→2号位→...→25号位）
- 每个角色独立进行技能触发概率判定
- 一旦有角色技能触发，立即执行该技能
- 后续角色不再进行判定，本回合结束
- 若所有角色均未触发技能，则执行整队普攻
```

## 3. 技能系统设计

### 3.1 主动技能分类

#### 3.1.1 伤害类技能
- **暴击技能**：造成高额暴击伤害，前期优势明显
- **纯粹技能**：稳定的固定伤害，中后期优势
- **大伤害技能**：高倍率伤害，但触发概率较低
- **百分比技能**：按敌人最大生命值百分比造成伤害

#### 3.1.2 辅助类技能
- **回复技能**：恢复队伍生命值
- **吸血技能**：造成伤害的同时回复生命值

#### 3.1.3 控制类技能
- **封印技能**：阻止敌人使用技能
- **虚弱技能**：降低敌人攻击力
- **减速技能**：降低敌人先攻值

### 3.2 被动技能分类

#### 3.2.1 属性加成类
- **四维属性提升**：
  - 先攻加成：提升行动顺序和暴击伤害
  - 防御加成：减少受到的伤害
  - 闪避加成：提升闪避概率
  - 王者加成：提升整体战斗力

#### 3.2.2 特殊效果类
- **状态抗性**：抵抗封印、虚弱、流血等负面效果
- **伤害修正**：增加暴击率、暴击伤害、最终伤害
- **回复增强**：提升治疗效果、生命回复速度

### 3.3 组合技能系统
- **五虎上将**：+10先攻、+12防御
- **万事屋组合**：特殊技能效果加成
- **大夜场组合**：夜间战斗加成

## 4. 伤害计算公式

### 4.1 基础伤害计算
```
基础伤害 = 角色攻击力 × 技能倍率 × 随机波动(0.9-1.1)
```

### 4.2 暴击伤害计算
```
暴击伤害 = 基础伤害 × 暴击倍率 × (1 + 先攻值/100)
```

### 4.3 最终伤害计算
```
最终伤害 = (基础伤害 + 被动加成) × (1 - 敌人防御减免) × 特殊效果倍率
```

### 4.4 防御减免计算
```
防御减免 = 敌人防御值 / (敌人防御值 + 100)
```

## 5. 战术流派设计

### 5.1 先攻暴击流
- **核心思路**：高先攻值确保先手，暴击技能快速击杀
- **角色配置**：高先攻、高暴击率角色为主
- **被动技能**：先攻加成、暴击率提升

### 5.2 高防回复流
- **核心思路**：高防御值减少伤害，回复技能持续作战
- **角色配置**：高防御、回复技能角色为主
- **被动技能**：防御加成、回复效果提升

### 5.3 纯粹流
- **核心思路**：稳定的固定伤害输出，不依赖暴击
- **角色配置**：纯粹技能角色为主
- **被动技能**：技能伤害加成、技能触发率提升

## 6. 技术架构设计

### 6.1 核心类结构

#### 6.1.1 TeamBattleManager
```gdscript
class_name TeamBattleManager
extends Node

# 队伍管理
var hero_team: Array[Dictionary] = []
var enemy_team: Array[Dictionary] = []

# 战斗状态
var current_turn: int = 0
var battle_phase: BattlePhase
var active_effects: Array[Dictionary] = []

# 核心方法
func initialize_battle(heroes: Array, enemies: Array)
func execute_turn()
func check_skill_triggers() -> Dictionary
func execute_skill(skill_data: Dictionary, caster: Dictionary)
func execute_team_attack()
func calculate_damage(attacker: Dictionary, target: Dictionary, skill: Dictionary = {}) -> int
func apply_passive_effects()
func check_battle_end() -> bool
```

#### 6.1.2 SkillSystem
```gdscript
class_name SkillSystem
extends Node

# 技能数据
var active_skills: Dictionary = {}
var passive_skills: Dictionary = {}
var combo_skills: Dictionary = {}

# 核心方法
func register_skill(skill_id: String, skill_data: Dictionary)
func check_skill_trigger(character: Dictionary, skill_id: String) -> bool
func execute_active_skill(skill_id: String, caster: Dictionary, targets: Array)
func apply_passive_skill(skill_id: String, character: Dictionary)
func check_combo_skills(team: Array[Dictionary]) -> Array[Dictionary]
```

#### 6.1.3 DamageCalculator
```gdscript
class_name DamageCalculator
extends Node

# 伤害计算
func calculate_base_damage(attacker: Dictionary, skill: Dictionary = {}) -> int
func calculate_critical_damage(base_damage: int, attacker: Dictionary) -> int
func apply_defense_reduction(damage: int, defender: Dictionary) -> int
func apply_special_effects(damage: int, effects: Array[Dictionary]) -> int
```

### 6.2 数据结构设计

#### 6.2.1 角色数据结构
```gdscript
var character_data = {
	"id": "hero_001",
	"name": "战士",
	"position": 1,  # 队伍中的位置（1-25）
	"stats": {
		"max_hp": 100,
		"current_hp": 100,
		"attack": 20,
		"defense": 10,
		"agility": 15,  # 先攻
		"dodge": 5,     # 闪避
		"king": 8       # 王者
	},
	"active_skills": ["skill_001", "skill_002"],
	"passive_skills": ["passive_001"],
	"equipment": {},
	"status_effects": []
}
```

#### 6.2.2 技能数据结构
```gdscript
var skill_data = {
	"id": "skill_001",
	"name": "暴击斩",
	"type": "active",
	"category": "critical",
	"trigger_chance": 0.3,
	"damage_multiplier": 2.0,
	"critical_bonus": 0.5,
	"target_type": "single_enemy",
	"effects": [
		{
			"type": "damage",
			"value": 150,
			"calculation": "percentage"
		}
	],
	"cooldown": 0,
	"description": "造成150%攻击力的暴击伤害"
}
```

### 6.3 信号系统设计
```gdscript
# 战斗事件信号
signal battle_started(hero_team: Array, enemy_team: Array)
signal turn_started(turn_number: int, active_side: String)
signal skill_triggered(caster: Dictionary, skill: Dictionary, targets: Array)
signal damage_dealt(attacker: Dictionary, target: Dictionary, damage: int, is_critical: bool)
signal character_defeated(character: Dictionary)
signal battle_ended(victory: bool, rewards: Dictionary)

# 技能事件信号
signal passive_effect_applied(character: Dictionary, effect: Dictionary)
signal status_effect_added(character: Dictionary, effect: Dictionary)
signal combo_skill_activated(characters: Array, combo: Dictionary)
```

## 7. 与Loop Hero的集成

### 7.1 现有系统改造
- **保留**：基础的战斗管理器框架、信号系统、UI接口
- **替换**：单体回合制逻辑 → 队伍整体回合制逻辑
- **扩展**：技能系统、被动效果系统、组合技系统

### 7.2 英雄系统集成
- **HeroManager扩展**：支持多角色队伍管理
- **角色配置界面**：队伍编成、角色排序、技能配置
- **角色成长系统**：技能解锁、被动技能获得

### 7.3 卡牌系统集成
- **角色卡牌**：新增角色卡牌类型，可招募到队伍
- **技能卡牌**：为角色装备新技能
- **组合卡牌**：激活特定角色组合的组合技

## 8. 开发优先级

### 8.1 第一优先级（核心功能）
1. TeamBattleManager基础框架
2. 队伍整体回合制逻辑
3. 基础技能触发机制
4. 简单的主动技能实现

### 8.2 第二优先级（扩展功能）
1. 被动技能系统
2. 伤害计算公式完善
3. 状态效果系统
4. 战斗动画和特效

### 8.3 第三优先级（高级功能）
1. 组合技能系统
2. 复杂的战术流派支持
3. AI智能化
4. 平衡性调优

## 9. 测试计划

### 9.1 单元测试
- 技能触发概率测试
- 伤害计算公式验证
- 被动技能效果测试

### 9.2 集成测试
- 完整战斗流程测试
- 多种队伍配置测试
- 极端情况处理测试

### 9.3 平衡性测试
- 不同流派的胜率统计
- 技能触发频率分析
- 战斗时长评估

---

**文档版本**：v1.0  
**创建日期**：2024年12月  
**负责人**：开发团队