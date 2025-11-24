## 现状
- 资源位置：`res://scenes/MainGame.tscn` 中存在节点 `monster_zhuyao`，含 `AnimatedSprite2D` 与 `SpriteFrames`，已配置 `idle` 与 `attack` 动画，默认不可见。
- 战斗动画管线：`BattleAnimationController.gd` 在 `BattleWindow.gd` 中创建每个参战单位的 `CharacterAnimator.tscn`；动画播放由 `CharacterAnimator.gd` 负责。
- 特例处理：`CharacterAnimator.gd` 对“紫菱”通过 `_use_ziling_visuals()` 动态加载 `MainGame.tscn` 的 `SpriteFrames`，并在攻击时切换 `attack`/`idle`，其余视觉效果依赖 `Tween`。
- 当前未对 `monster_zhuyao` 做类似绑定，因此敌方单位不会自动使用该动画资源。

## 目标
- 让符合命名的敌方单位（如 `Zhuyao`/`主妖`）在战斗中使用 `monster_zhuyao` 的 `AnimatedSprite2D` 帧进行展示与攻击动画。
- 保持既有战斗管线不变，尽量不新增场景/文件，遵循 Godot 4.4 与现有工程风格。

## 实施步骤
1. 在 `res://scripts/battle/CharacterAnimator.gd` 增加 `_use_zhuyao_visuals()`：
   - 从 `res://scenes/MainGame.tscn` 加载节点 `monster_zhuyao/AnimatedSprite2D` 的 `SpriteFrames`。
   - 将帧资源赋值到动画器内部现有的 `ZilingAnimated`（作为通用承载节点），并设 `visible=true`、`animation="idle"`、`play()`。
   - 自适配容器尺寸与镜像（复用已有“紫菱”逻辑）。
2. 在 `initialize_character(char_data, team, pos)` 或 `_update_character_display()` 中：
   - 增加名称匹配判断（`Zhuyao`、`主妖`、大小写/空格变体），命中时调用 `_use_zhuyao_visuals()`；未命中保持现状。
3. 在现有攻击/受击/死亡流程中复用动画切换：
   - `play_attack_animation()`：若特殊动画可见，则在攻击窗口播放 `attack`，结束后切回 `idle`。
   - `play_damage_animation()`：保留原有 `Tween` 抖动/闪烁作为受击效果；`monster_zhuyao` 无独立受击帧时仍可产生反馈。
   - `play_death_animation()`：执行透明度淡出与下落等现有效果；若未来提供 `death` 帧，可平滑接入。
4. 验证：
   - 在 `BattleWindow.tscn` 下通过 `TeamBattleManager.gd` 构造包含 `Zhuyao` 的 `enemy_team`；运行后确认 `idle` 自动播放、攻击时切换到 `attack`，受击/死亡效果正常。
   - 保证镜像与布局在 `EnemyAnimators` 容器中正确显示。

## 影响范围
- 仅修改 `CharacterAnimator.gd`（增加方法与分支），不新增文件、不改动管线结构。
- 若后续需在地图上使用同一贴图，可另行在 `LoopManager.gd` 的 `_create_monster_sprite` 添加资源路径映射，但本次不包含此项。

## 交付与回滚
- 提交前进行本地运行验证；如出现问题，删除 `_use_zhuyao_visuals()` 及名称匹配分支即可回滚到当前稳定行为。

是否按上述方案进行集成？确认后我将直接实现并验证。