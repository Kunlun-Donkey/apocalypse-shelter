# AGENTS.md — AI 开发代理指导 (Apocalypse Shelter)

> 本文件是 AI 开发代理 (Cline / Claude Code / MiMo + Godot MCP) 的**唯一开发阶段入口**。
> 开始任何开发任务前: 先读本文件 → 再读规范 → 再看 `configs/` 真实数据。
> 完整设计规范: `docs/Apocalypse_Shelter_Core_World_Config_Specification_v0.2.md`
> (以下引用格式: "SPEC PART R" = 该文档的 PART R 章节)

## 0. 你在做什么项目

Steam 单机 2.5D 末世庇护所经营游戏, 引擎 Godot 4.x。
架构铁律 (违反即错误答案):

```text
大 CONF (configs/system.conf)  → 只放系统开关/依赖/profile
小 CONF (configs/**.conf)      → 只放游戏内容数值
代码 (src/)                    → 只放"怎么运行", 不放游戏数值
Scene (scenes/)                → 只放表现
新增内容 = 新增 CONF + registry 登记一行, 绝不改核心代码
```

**开发按"玩法内容阶段"递进** (见 §1), 不是按系统模块分组。
一次只做当前阶段, 不得提前实现后续阶段的玩法。
CONF 数据文件可以提前存在 (休眠), 但对应 System/UI/玩法代码不得提前写。

## 1. 玩法内容阶段总览 (开发路线)

| 阶段 | 玩法内容 | 开启开关 | 状态 |
|---|---|---|---|
| Dev-S1 | 庇护所 + 升级 (无资源) | shelter | ⬜ 当前 |
| Dev-S2 | 野外物资 + 资源 + 基础建筑 | resource, building, loot | ⬜ |
| Dev-S3 | 敌人与战斗 | enemy, combat | ⬜ |
| Dev-S4 | NPC 与幸存者 | npc, population, survivor, event | ⬜ |
| Dev-S5 | 天灾 / 永夜 / 天气 | weather, disaster, world | ⬜ |
| Dev-S6+ | 深度系统与发行 (探索/交易/科技/剧情/Steam…) | 按 SPEC PART S | ⬜ |

每阶段切换 = 改 `system.conf` 开关 + 补该阶段 CONF + 写该阶段 System/UI, 重启生效。
阶段内验收通过才进入下一阶段 (各阶段出口标准见对应章节)。

> 与 SPEC 的关系: SPEC PART R 的 "3 系统 MVP" 是**架构验收口径** (ConfigManager/依赖校验/
> 存读档闭环), 在 Dev-S2 完成时达成; SPEC 的 20 项检查与 FREEZE 不变。
> 本文件的阶段划分以"最快跑起来、内容逐层递进"为准, 优先于 SPEC PART R 的实现顺序。

## 2. Dev-S1 庇护所 + 升级 (当前阶段, 最高优先级: 先跑起来)

### 2.1 目标

Godot 里 F5 能运行: 看到庇护所 Lv1, 点升级 → Lv2 → Lv3, 退出重进进度还在。
**没有任何资源** — 升级只花现实时间冷却 (临时常量 30 秒/级, S2 引入资源后废弃)。

### 2.2 开关 (configs/system.conf, 应保持一致)

```text
ON : shelter   (+ CORE 恒开: core/config/save/time/ui)
OFF: 其余全部 — 禁止实现、禁止初始化、禁止写 UI
```

### 2.3 范围裁剪 (关键)

- `shelter_levels.conf` 中的 `upgrade_cost_*` / `requirements_buildings` / `income_*`
  本期**不校验不生效** (resource/building 关闭 → 休眠字段), S2 起生效
- 不做 ResourceSystem / BuildingSystem / 任何搜刮 / 任何战斗
- CONF 文件不动 (数据休眠, 符合"内容存在, 功能关闭")

### 2.4 任务清单 (按顺序, 最小可运行优先)

1. **Godot 工程骨架**: `project.godot` + 目录对齐 SPEC PART Q1 (src/core, src/systems, src/ui, src/scenes)
2. **ConfigManager 精简版** (src/core/config_manager.gd)
   - 读 `system.conf` → 校验 `[dependencies]` → 仅加载开启系统对应的 CONF
   - 本期只需: `is_enabled()`, `get_shelter_level(n)`, `get_initial_state()`
   - 错误处理按 SPEC E9 (配置坏了要报错终止, 不许崩 Godot)
3. **ShelterSystem** (src/systems/shelter/shelter_system.gd)
   - 当前等级状态, 升级 = 冷却结束即可升, 校验 `requirements_shelter_level`
   - 每级生效: population_cap / building_slots / storage_bonus / defense / production_bonus_percent (只存数值, 无消费方也无妨)
4. **SaveSystem**: GameState { shelter_level, 升级冷却计时, 游戏时刻 } 序列化, 3 槽
5. **TimeManager**: 游戏时钟 (1 游戏时 = 60 现实秒), 升级冷却计时用现实秒
6. **最小 UI**: 庇护所面板 (名称/等级/满级进度/升级按钮+冷却显示), 保存/读档按钮
7. **验收**: §2.5 全部勾掉

### 2.5 Dev-S1 出口标准 (全部满足才进 S2)

- [ ] F5 运行, 无报错, 显示 Lv1 废弃哨站
- [ ] 点升级 → 冷却 30 秒 → Lv2 修补营地 (名称/数值随 CONF 变化)
- [ ] 连升到 Lv3, 满级后升级按钮正确禁用
- [ ] 保存 → 关游戏 → 读档, 等级/冷却一致
- [ ] 改坏 `shelter_levels.conf` (如删掉 [level.2]) → 启动输出 CONFIG ERROR 并终止, 不静默
- [ ] `system.conf` 中任一 OFF 系统未被初始化 (零初始化验证)

## 3. Dev-S2 野外物资 + 资源 + 基础建筑

### 3.1 玩法目标

外出搜刮获得物资 → 资源入仓 → 建造/升级建筑产出 → 庇护所升级开始消耗资源。
此时达到 SPEC PART R "3 系统 MVP" 架构验收口径。

### 3.2 开关

```text
+ resource, building, loot = true
```

### 3.3 任务清单

1. **ResourceSystem**: 资源池/容量/upkeep; 5 资源 (wood/steel/food/water/power)
2. **搜刮 (简版, 不做完整探索)**: 搜刮按钮面板, 读 loot 节点 CONF (可在 `configs/loot/` 新建 S2 专用节点, 数值参照 SPEC PART J 住宅/超市类), 冷却 + 随机获取资源
3. **BuildingSystem**: 6 基础建筑 (generator/warehouse/lumber_yard/water_collector/farm/salvage_workshop), 建造/升级/小时 tick 产消
4. **shelter_levels 休眠字段激活**: upgrade_cost_* / requirements_buildings / income_* 开始生效; S1 的 30 秒临时冷却废弃
5. **UI**: 资源面板、建筑面板、搜刮按钮
6. **回归**: Dev-S1 升级流程在有资源成本后仍通畅

### 3.4 出口标准

- [ ] SPEC R4 验收流程通过 (经济闭环可走通 Lv1→Lv3, 参照 SPEC H4)
- [ ] 新增假建筑 `buildings/test_hut.conf` + registry 一行 → 游戏内可见可建, 零代码改动 → 删除
- [ ] 新增搜刮节点 CONF 一行 → 搜刮面板出现, 零代码改动

## 4. Dev-S3 敌人与战斗

### 4.1 玩法目标

野外/基地遭遇敌人, 简单战斗结算 (威胁 + 战利品), 让搜刮有风险。

### 4.2 开关

```text
+ enemy, combat = true     (item/equipment 简版武器可同期或紧随其后)
```

### 4.3 任务要点

- enemy/*.conf 按 SPEC PART K3 (先做 enemy.infected_01 一种跑通)
- 搜刮时按概率遭遇战斗 → 结算伤害/战利品 → 掉落走 loot 表
- 战斗数值全在 CONF, 代码只做结算规则
- 出口: 打得赢/打不赢都有明确反馈, 掉落入库, 新增敌人 = 加 CONF

## 5. Dev-S4 NPC 与幸存者

开关: `+ npc, population, survivor, event = true`。
按 SPEC PART I/M: 人口消耗、幸存者招募上岗、NPC 到访、随机事件。
出口: 新增 NPC = 加 `npcs/xxx.conf`; 新增事件 = 加 `events/xxx.conf`, 均零代码改动。

## 6. Dev-S5 天灾 / 永夜 / 天气

开关: `+ weather, disaster, world = true`。
按 SPEC PART O: 昼夜/天气对产出的修正、尸潮等灾害 (预警→冲击→结算)、"永夜"等
特殊世界状态作为 disaster/weather 的极端事件配置。出口: 新增灾害 = 加 CONF。

## 7. Dev-S6+ 与后续

探索 (map/location/exploration)、交易 (trade/merchant)、制作/科技、剧情 (quest/story)、
医疗/士气/防御、Steam/成就/音频/设置 — 顺序参考 SPEC PART S, 每组仍按
"开开关 → 补 CONF → 写 System → 回归" 的节奏。

## 8. 阶段工作流 (每阶段通用)

```text
1. 确认当前阶段 (本文件 §1 状态列)
2. 改 system.conf 开关 (含依赖, 见 SPEC PART C)
3. 补/改该阶段小 CONF (schema 见 SPEC E7)
4. 实现该阶段 System/UI (只写本阶段玩法)
5. 跑本阶段出口标准 + 回归前面阶段
6. 通过 → 更新本文件 §1 状态列, 进入下一阶段
```

禁止: 一次做多阶段; 绕过 CONF 写数值; 给 OFF 系统写运行时代码。

## 9. 给 AI 代理的阅读顺序

1. 本文件 (AGENTS.md) — **阶段与任务以此为准**
2. `configs/system.conf` — 当前真实开关状态 (应与本文件 §1 一致)
3. SPEC PART E (CONF 格式) + PART T (加载生命周期) + 当前阶段涉及的 PART
4. `configs/` 下相关 .conf — 数值以文件为准, 文档表格仅为设计意图

## 10. 常见坑

- **禁止用中文 name 查数据**, 只用 `type.name` ID
- `level.N.upgrade_cost_*` = 升到本级的花费 (level.1 = 建造花费)
- 文档与 CONF 数值冲突时, **以 CONF 为准**
- 休眠字段/休眠 CONF: 所属系统 OFF 时忽略, 不许提前实现其玩法
- power 是流转型资源 (S2 起, 实时产需结算), 不参与交易
- 修改 CONF 后必须重启才生效 (启动期加载, 运行期只读缓存)
- S1 临时升级冷却 30 秒是**临时常量**, S2 起必须废弃并改由 CONF 驱动

## 11. 交付物定义

每阶段交付: 可运行的 Godot 工程增量 + 通过该阶段出口标准。
完成时更新本文件 §1 状态列, 并列出本阶段新增的 System 类与 CONF 文件。

## 12. Godot 工程结合方式 (硬约定)

### 12.1 工程布局

```text
game/                      ← project.godot 就放这里 (工程根)
├── project.godot
├── configs/               ← res://configs/   (随包导出)
├── src/                   ← res://src/       (GDScript)
│   ├── core/              ← autoload: config_manager.gd, time_manager.gd, save_manager.gd
│   ├── systems/<name>/    ← 每系统一目录
│   ├── ui/                ← UI 脚本 + .tscn 面板布局
│   └── scenes/            ← 2.5D 世界场景
└── assets/                ← res://assets/    (美术/音频, 见 §13)
```

### 12.2 启动流 (对齐 SPEC PART T)

```text
project.godot 启动
→ autoload 就绪 (ConfigManager 最先)
→ Boot.tscn: ConfigManager.load("res://configs/system.conf") → 校验
→ 按开关初始化 System (禁用系统零初始化)
→ SaveManager 读档或新建
→ 切 Main.tscn (UI 按开关挂载)
```

### 12.3 CONF 读取约定

- Godot `ConfigFile` **只负责** `[节]` + `key = value` 的原始读取
- 数组 `[a, b]`、范围 `10~30`、`id:level`、类型转换 → **ConfigManager 自己解析** (CONF-D v2, SPEC E3)
- 导出设置必做: **Export → Filters to export non-resource files 加 `*.conf`**, 否则打包后读不到配置
- 改 CONF 一律重启生效 (启动期加载, 运行期只读缓存)

## 13. UI / 美术资源处理方式 (硬约定)

### 13.1 目录

```text
assets/
├── ui/
│   ├── icons/        ← 图标 (svg 优先)
│   ├── fonts/        ← 字体
│   ├── themes/       ← theme.tres (全局唯一主题)
│   └── panels/       ← 面板装饰图
├── buildings/        ← 建筑视觉素材
└── audio/            ← SFX / BGM
```

### 13.2 命名与 ID 挂钩 (让 UI 代码可自动找图)

```text
ui_icon_<entity_type>_<name>.svg

例: ui_icon_resource_wood.svg      ↔ resource.wood
    ui_icon_building_generator.svg ↔ building.generator
    ui_panel_shelter.svg           ← 通用件自由命名
```

UI 代码按 `config_id` 拼路径: `res://assets/ui/icons/ui_icon_%s.svg` % id.replace(".", "_")...
**找不到时用占位图, 不崩溃**。这样新增资源/建筑的图标 = 丢一个文件, 零代码改动。

### 13.3 CONF 与美术的边界

- CONF 的 `visual_scene` / `visual_stage` 只写**场景引用** (`res://src/scenes/...tscn`) 或 **stage 枚举**
- 美术资源路径不进数值字段; 个别特例要写路径时用 `[visual]` 节 (如 shelter.conf)
- 新增 UI 流程: 丢素材进 assets/ui/ → (可选) 在 CONF visual 节引用 → 需要新布局才动 .tscn
- UI 布局 (.tscn) 与主题 (.tres) 属于表现层, 不受"零代码新增内容"约束, 允许改

### 13.4 素材格式/尺寸总规范

| 类型 | 格式 | 尺寸 | 说明 |
|---|---|---|---|
| UI 图标 | **SVG 优先**, PNG 备选 | 画布 64×64, 显示 32~48 | Godot 4 原生导入 SVG; 必须小写 snake_case |
| 面板/按钮底图 | PNG (透明) | 512×512, **必须 9-slice** (NinePatchRect) | 四角 32px 不拉伸, 中段拉伸 |
| 大型场景视觉 | PNG/WebP (不用 JPG) | 16:9, 基准 1920×1080, 按 2x 出 2048×1152 亦可 | 2.5D 主视觉/背景 |
| 字体 | TTF/OTF | — | 先用 Godot 默认字体顶着, 有正式字再放 fonts/ |
| 进度条/冷却条 | 不出图 | — | 用 StyleBoxFlat 代码/主题画, 省素材 |

通用: 全小写 snake_case; UI 图标留 4px 安全边; 导出 PNG 用无损; 大图导入后开 mipmaps、图标关 mipmaps。

### 13.5 Dev-S1 素材清单 (照此出图即可)

```text
assets/
├── ui/
│   ├── icons/
│   │   ├── ui_icon_placeholder.svg      64×64   ★必做, 缺图兜底
│   │   ├── ui_icon_shelter_main.svg     64×64   庇护所面板头像
│   │   ├── ui_icon_upgrade.svg          64×64   升级按钮
│   │   ├── ui_icon_clock.svg            64×64   升级冷却显示
│   │   ├── ui_icon_save.svg             64×64   保存
│   │   └── ui_icon_load.svg             64×64   读档
│   ├── panels/
│   │   └── ui_panel_shelter.png         512×512 9-slice, 庇护所主面板底
│   └── themes/
│       └── theme.tres                   —       先建空主题即可 (颜色/字号)
└── scenes/
    └── shelter/                         ← 视觉对应 shelter.conf [visual] visual_stages
        ├── shelter_outpost.png          1920×1080 (或 2048×1152)  Lv1 废弃哨站
        ├── shelter_camp.png             同上                      Lv2 修补营地
        └── shelter_settlement.png       同上                      Lv3 前哨聚落
```

要点:
- 3 张庇护所视觉对应 `shelter_levels.conf` 的 `visual_stage = outpost / camp / settlement`,
  是**同一构图的三级演变**(建筑变多变好), 不是 3 张无关的图
- S1 **不需要**: 建筑图标、资源图标、敌人/地图素材 (S2 起才要)
- 没拿到正式图前, 全部可用 ui_icon_placeholder.svg + 纯色块顶着跑, 不阻塞开发

### 13.6 音频素材格式/尺寸总规范

| 类型 | 格式 | 规格 | 说明 |
|---|---|---|---|
| BGM | OGG Vorbis | 44.1kHz 立体声, 128~160kbps, 1~2 分钟可循环段 | 导入时**开 Loop** |
| 环境氛围音 | OGG Vorbis | 44.1kHz 立体声, 96~128kbps, 30~60 秒**无缝**循环 | 导入时开 Loop, 首尾无缝 |
| UI/交互 SFX | **WAV** 16/24bit (OGG 备选) | 44.1kHz, **时长 < 1 秒** | 导入时**关 Loop**; WAV 延迟低适合点击 |
| 语音 VO | OGG Vorbis / WAV | 44.1kHz, **单声道**, 每条 5~10 秒 | TTS 生成; 同一角色音色一致; 见 §13.7 台词表 |

通用: 全小写 snake_case; 音效响度归一 (峰值留 -6dB 余量); BGM 响度低于 SFX, VO 介于两者之间;
命名 `bgm_<scene>_<name>.ogg` / `amb_<scene>_<name>.ogg` / `sfx_<category>_<action>.wav` / `vo_<role>_<topic>.ogg`。

边界 (同 §13.3 精神):
- S1 允许 UI 用 `AudioStreamPlayer` 播**一次性音效** (表现层); **不建 AudioSystem**
- 音量设置/音频总线/混音管理 = audio 开关的内容, S6+ 才实现
- 音频文件可提前放入 `assets/audio/` 休眠, 不违反"内容存在, 功能关闭"

### 13.7 Dev-S1 音频清单 (照此出音频即可)

```text
assets/audio/
├── bgm/
│   └── bgm_shelter_main.ogg        1~2 分钟循环     庇护所主界面 BGM
├── amb/                            (可选, 不阻塞)
│   └── amb_shelter_wind.ogg        30~60 秒无缝循环  营地风声/末世氛围
├── sfx/
│   ├── sfx_ui_click.wav            < 0.2 秒   通用按钮点击
│   ├── sfx_ui_error.wav            < 0.5 秒   操作无效 (冷却中/满级点升级)
│   ├── sfx_upgrade_start.wav       < 1 秒     点升级成功, 冷却启动
│   ├── sfx_upgrade_complete.wav    1~2 秒     升级完成, 等级提升
│   ├── sfx_save.wav                < 0.5 秒   保存成功
│   └── sfx_load.wav                < 0.5 秒   读档成功
└── voice/
    ├── vo_radio_intro.ogg          5~8 秒   开场: 首次进游戏/读档后引导
    ├── vo_radio_upgrade.ogg        5~8 秒   提示: 升级冷却完成可再升级
    ├── vo_radio_maxlevel.ogg       5~8 秒   提示: 达到 MVP 满级
    └── vo_radio_save.ogg           4~6 秒   提示: 首次保存成功 (只播一次)
```

### 13.8 引导语音 (VO) 台词与 TTS 生成规范

- **角色载体**: **庇护所核心的语音接口** — 就是新世界观中发送
  【世界生存率预测：3.7%】的同一存在。核心绑定幸存者后成为庇护所中枢, 语音 = 它的引导提示。
  (世界观: 神秘预警 → 天穹裂痕 → 庇护所核心 → 文明重建 → 世界重启)
- **触发哲学**: 只在里程碑开口 (绑定完成/每级升级完成/满级/首次日志), 每条 ≤10 秒,
  不排队不打断操作, 永不说"玩家/按钮/界面/存档" (保存说"日志")。末世但不丧, 打气不说教。
- **风格选型进行中**: 4 个候选风格样本已生成在 `assets/audio/voice/samples/`
  (同一段台词、含性别/文本/风格描述, 见该目录 `manifest.md`):
  A 冷感系统播报 (女) / B 温度渐变 (女) / C 古文明残响 (男) / D 人类同伴 (男)。
  **待选定风格后重写本节台词表**。
- **TTS 生成**: 云端 MiMo TTS (`xiaomi/mimo-v2.5-tts`, 走 `/v1/chat/completions`),
  user 消息放音色指令, assistant 消息放台词, `message.audio.data` 返回 WAV;
  同一角色全部台词用**同一音色指令**生成保证一致; 导出转 OGG 单声道 44.1kHz (§13.6)。
  另有 `mimo-v2.5-tts-voiceclone` (音色克隆) / `mimo-v2.5-tts-voicedesign` (音色设计) 可选。

音频要点:
- SFX 最小集 = `sfx_ui_click` + `sfx_upgrade_complete` 两个即可跑通听感, 其余按表备齐
- **不做**冷却倒计时 tick 音 (秒针声易烦), 冷却只做视觉进度条
- VO 每条 ≤ 10 秒; 生成后统一响度 (VO 峰值 -6dB, 响度介于 BGM 与 SFX 之间)
- 播放逻辑极简: `AudioStreamPlayer` 一次性播放, **不排队不打断** (正在播就不播新的)
- 找不到音频文件时静默跳过, 不崩溃 (同图标占位策略); 全静音跑不阻塞开发
- 后续阶段沿用同一核心语音补各自清单: S2 搜刮/建造音效与台词, S3 战斗音效与首次遇敌台词, S4 幸存者到来台词, S5 灾害预警台词

## 14. 与 MiMo / Godot MCP 协作要点

- 每轮开工先说: "按 AGENTS.md 执行当前阶段下一个任务" (阶段状态见 §1)
- 做完一个任务 → 跑该阶段出口标准 (§2.5 等) → 勾掉后再进下一个
- 发现 MiMo 违反 §0 铁律 (数值进代码/提前实现后续阶段) → 指出具体条款让它回退
- Godot MCP 常用链: 建工程文件 → 挂 autoload → 跑场景 → 读报错 → 修
