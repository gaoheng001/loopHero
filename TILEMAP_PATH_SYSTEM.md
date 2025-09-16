# TileMapLayer路径系统技术文档

## 概述

Loop Hero项目采用基于TileMapLayer的瓦片路径系统，支持自定义路径设计。该系统通过检测TileMapLayer中的特定瓦片来生成英雄移动路径。

## 技术实现

### 1. 核心组件

#### TileMapLayer节点配置
- **节点名称**: `Level1TileMapLayer`
- **父节点**: `LoopManager`
- **位置**: `Vector2(-1212, -881)`
- **缩放**: `Vector2(2.5, 2.5)`
- **Z索引**: `-1` (背景层)

#### 路径瓦片标识
- **Source ID**: `0` (使用第一个瓦片集)
- **Atlas坐标**: `Vector2i(25, 5)` (路径瓦片在瓦片集中的位置)
- **瓦片集**: 使用 `All tiles v1.png` 资源

### 2. 路径生成算法

#### 自定义路径检测 (`_generate_custom_path_from_tilemap`)
```gdscript
# 扫描TileMapLayer中的路径瓦片
for x in range(-search_radius, search_radius + 1):
    for y in range(-search_radius, search_radius + 1):
        var tile_pos = Vector2i(x, y)
        var tile_data = tile_map_layer.get_cell_source_id(tile_pos)
        var atlas_coords = tile_map_layer.get_cell_atlas_coords(tile_pos)
        
        # 检查是否是路径瓦片
        if tile_data != -1 and atlas_coords == Vector2i(25, 5):
            # 坐标转换处理
            var tile_local_pos = tile_map_layer.map_to_local(tile_pos)
            var transformed_pos = tile_local_pos * tile_map_layer.scale + tile_map_layer.position
            var final_pos = transformed_pos + position
            path_points.append(final_pos)
```

#### 路径点排序 (`_sort_path_points`)
- 使用最近邻算法对路径点进行排序
- 确保形成连续的循环路径
- 从第一个点开始，依次找最近的下一个点

#### 错误处理机制
- 当TileMapLayer中未找到路径瓦片时输出错误信息
- 提示用户检查瓦片配置
- 确保路径瓦片正确放置

### 3. 坐标系统

#### 坐标转换流程
1. **瓦片坐标** → **TileMapLayer本地坐标** (使用 `map_to_local`)
2. **本地坐标** → **变换后坐标** (应用scale和position)
3. **变换后坐标** → **LoopManager坐标** (相对于LoopManager位置)

#### 关键参数
- **搜索半径**: 50瓦片 (可调整)
- **瓦片大小**: 由TileMapLayer自动计算
- **LoopManager位置**: `Vector2(640, 360)`

### 4. 路径类型

系统现在仅支持自定义瓦片路径，通过TileMapLayer中的路径瓦片生成。

### 5. 使用方式

#### 设计自定义路径
1. 在Godot编辑器中打开 `MainGame.tscn`
2. 选择 `LoopManager/Level1TileMapLayer` 节点
3. 使用瓦片绘制工具，选择路径瓦片 (Atlas坐标 25,5)
4. 在地图上绘制连续的循环路径
5. 运行游戏，系统会自动检测并使用自定义路径

#### 调试信息
- 控制台会输出找到的路径瓦片数量
- 显示使用的路径类型 (自定义或圆形)
- 输出最终路径点数量

### 6. 优势特点

1. **灵活性**: 支持任意形状的循环路径设计
2. **可视化**: 在编辑器中直接绘制路径
3. **简洁性**: 专注于自定义路径，避免复杂的fallback逻辑
4. **扩展性**: 易于添加新的路径特效和功能
5. **性能**: 一次性生成路径，运行时无额外计算

### 7. 注意事项

- 确保路径瓦片形成闭合循环
- 路径点之间距离不宜过大，影响移动平滑度
- TileMapLayer的scale和position会影响最终路径坐标
- 路径瓦片的Atlas坐标必须准确匹配 `Vector2i(25, 5)`

## 未来扩展

1. **多层路径**: 支持不同层级的路径系统
2. **动态路径**: 运行时修改路径结构
3. **路径效果**: 不同路径段的特殊效果
4. **路径验证**: 自动检测路径连通性和合法性