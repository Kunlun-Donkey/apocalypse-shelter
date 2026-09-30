# Apocalypse Shelter Core World & Configuration Specification v0.2

《末世庇护所》Steam 独立游戏 — 世界体系 + 系统体系 + 配置体系规范

```text
世界体系完整
↓
功能模块独立
↓
大 CONF 控制系统
↓
小 CONF 控制内容
↓
代码负责运行规则
↓
Scene 负责表现
↓
新增内容优先增加 CONF
↓
核心代码尽量不动
```

文档版本: v0.2 | 配置规范: CONF-D v2 | 引擎: Godot 4.x | 目标平台: Steam (Windows 优先)

> 本文档的最终产物不是 GDD, 而是**驱动程序开发的配置体系规范**。
> 另一台 AI / 程序员应能依据本文档 + `configs/` 目录生成第一阶段程序骨架;
> Windows 上的 Cline + Godot MCP 读取同一套 CONF 和代码, 把已开启的系统真正跑起来。

---

# PART A 游戏世界体系

## A1 项目定位

- 平台: Steam 单机 | 视角: 2.5D | 类型: 末世庇护所经营升级
- 体验支柱: 末世氛围 + 爽文式成长 + 模拟经营 + 资源管理 + 基级升级 + 探索 + 随机事件 + 轻 RPG
- 不是硬核生存模拟器, 不是纯放置游戏。失败成本低, 成长反馈快。

## A2 末世背景 (服务于玩法)

| 设计问题 | 结论 | 玩法服务点 |
|---|---|---|
| 为什么发生末世 | 2029 年"灰孢"(Grey Spore) 真菌-病毒共生体全球爆发: 空气传播致死, 孢子可长期休眠并二次感染尸体, 产生感染者 | 感染体 = 敌人来源; 药品 = 战略资源 |
| 什么时候开始 | 2029-10 | 时间线基准 |
| 玩家开始时距末世多久 | 灾变第 1096 天 (约 3 年) | 世界已荒废但未风化: 资源留存、建筑可搜刮 |
| 社会崩溃程度 | 政府与军事体系 3 年前瓦解; 存活人类约 5-8%, 形成互不统属的聚落 | 贸易、NPC、任务存在的理由 |
| 为什么还有大量资源 | 灾变初期大规模撤离 + 快速死亡, 物资封存在建筑/车辆/仓库中; 幸存者人口太少消耗不掉 | 探索搜刮 = 核心获取渠道之一 |
| 为什么野外还有动物 | 灰孢对多数非人哺乳动物致死率低, 部分产生免疫; 生态在 3 年内恢复 | 狩猎、皮毛、生态事件 |
| 为什么存在幸存者 | 天然免疫者 (约 5-8%) 幸存, 在废墟间迁徙求生 | 招募、人口、生产人力 |
| 为什么存在感染体 | 孢子休眠-复苏循环使尸体持续转化为感染者; 高密度区形成尸群 | 战斗、危险区域、灾难事件 |
| 为什么旧城市可探索 | 城市是最大物资库; 感染密度随昼夜/天气波动, 留有可搜刮的窗口期 | 风险-收益探索循环 |

## A3 世界舞台: 晨星谷 (Morningstar Valley)

玩家庇护所位于"临江市"西北的城郊山谷, 命名 **晨星谷**。地理结构由内向外:

```text
晨星哨站 (玩家基地, 安全区)
  → 城郊带 (suburb): 低风险, 住宅/超市/加油站
    → 城市废墟 (city_ruin): 中高风险, 高价值物资
    → 工业区 (industrial): 中风险, 钢材/电子/燃料
    → 农村 (rural): 低中风险, 食物/水/木材
    → 森林 (forest) / 山区 (mountain): 动物/木材/稀有矿
    → 军事区 (military): 高风险, 武器/装备/稀有材料
    → 感染区 (infected_zone): 极高风险, Boss/稀有掉落
    → 禁区 (forbidden): 后期剧情/终局内容
```

## A4 区域模板 (map 系统数据)

每个区域按下列模板配置 (完整文件位于 `configs/map/`, 后续阶段生成):

| 区域类型 | 推荐等级 | 风险 | 主要资源 | 敌人 | 动物 | NPC | 事件倾向 | 天气影响 |
|---|---|---|---|---|---|---|---|---|
| 安全区 safe_zone | 1 | 无 | 基地生产 | 无 | 少 | 常驻 | 正面 | 无 |
| 城郊 suburb | 1-3 | 低 | 食物/水/木材/杂物 | 少量感染者 | 老鼠/乌鸦/野狗 | 流商 | 物资/求助 | 小 |
| 农村 rural | 2-4 | 低中 | 食物/水/木材 | 感染农夫 | 兔/鹿/野猪 | 农夫 | 收获/兽群 | 中 |
| 森林 forest | 3-5 | 中 | 木材/草药/猎物 | 感染犬 | 鹿/狼/蛇 | 猎人 | 迷雾/伏击 | 大 |
| 工业区 industrial | 4-6 | 中高 | 钢材/燃料/电子 | 重型感染者 | 老鼠 | 拾荒者 | 坍塌/泄漏 | 中 |
| 城市废墟 city_ruin | 5-8 | 高 | 全类杂物/药品/电子 | 快速感染者/尸群 | 野狗群 | 幸存者小队 | 尸群/求救 | 大 |
| 山区 mountain | 6-8 | 高 | 稀有矿/燃料 | 狼群/感染狼 | 狼/熊 | 隐士 | 雪崩/矿脉 | 极大 |
| 军事区 military | 7-10 | 极高 | 武器/装备/稀有合金 | 精英感染体 | 无 | 逃兵 | 陷阱/军火库 | 中 |
| 感染区 infected_zone | 9-12 | 极高 | 稀有材料/剧情物 | Boss/变异体 | 感染兽 | 无 | 尸潮/变异 | 大 |
| 禁区 forbidden | 11-12 | 特殊 | 终局物 | 特殊 Boss | 无 | 神秘人 | 剧情 | 特殊 |

## A5 世界逻辑闭环

```text
灰孢爆发 → 社会崩溃 → 资源封存 + 感染体游荡 + 免疫幸存者求生
   ↓
玩家建立庇护所 → 基地生产 + 野外搜刮 → 升级基地/招募人口
   ↓
更强的基地 → 更深的探索 → 更好的资源/装备/情报
   ↓
吸引商人/幸存者/任务 → 应对尸潮/灾害/剧情 → 大型末世基地
```

---

# PART B 完整系统列表

系统全集 (共 35 个可开关系统 + 5 个恒开 CORE 模块)。
大 CONF `[system]` 中每个系统都有开关; CORE 组恒为 true, 不列入开关。

## B1 CORE 恒开模块 (引擎最小内核)

| 模块 | ID | 职责 |
|---|---|---|
| 核心循环 | core | 主循环、tick、系统注册表、模块生命周期 |
| 配置系统 | config | ConfigManager: 加载/校验/缓存全部 CONF |
| 存档系统 | save | 序列化 GameState, 版本迁移 |
| 时间系统 | time | 游戏时钟、昼夜、定时器、生产结算 |
| UI 框架 | ui | HUD/面板框架, 按开关挂载系统 UI |

## B2 可开关功能系统

| 系统 | ID | 开关 | 第一阶段 | 职责摘要 |
|---|---|---|---|---|
| 资源系统 | resource | `resource` | **ON** | 资源池、容量、产消结算 |
| 庇护所系统 | shelter | `shelter` | **ON** | 庇护所等级、槽位、解锁、基础收入 |
| 建筑系统 | building | `building` | **ON** | 建筑实例、建造/升级、产消挂载 |
| 生产系统 | production | `production` | OFF | 幸存者岗位生产、生产线配方 |
| 幸存者系统 | survivor | `survivor` | OFF | 招募、职业、属性、状态 |
| 人口系统 | population | `population` | OFF | 人口上限、食物水消耗、出生死亡 |
| NPC 系统 | npc | `npc` | OFF | NPC 刷新、功能、对话、招募 |
| 探索系统 | exploration | `exploration` | OFF | 派队、负重、风险、搜刮结算 |
| 地图系统 | map | `map` | OFF | 区域图、路径、解锁 |
| 地点系统 | location | `location` | OFF | 可探索地点实例、刷新 |
| 掉落系统 | loot | `loot` | OFF | 掉落表、搜刮节点 |
| 野生动物 | wildlife | `wildlife` | OFF | 动物生态总控 |
| 动物系统 | animal | `animal` | OFF | 普通动物实体、狩猎 |
| 敌人系统 | enemy | `enemy` | OFF | 感染体/敌对实体数据与生成 |
| 战斗系统 | combat | `combat` | OFF | 回合/半即时战斗结算 |
| 物品系统 | item | `item` | OFF | 物品实例、堆叠、背包 |
| 装备系统 | equipment | `equipment` | OFF | 装备槽、属性加成 |
| 制作系统 | crafting | `crafting` | OFF | 配方、制作队列 |
| 科技系统 | technology | `technology` | OFF | 科技树、全局加成 |
| 任务系统 | quest | `quest` | OFF | 任务链、目标、奖励 |
| 事件系统 | event | `event` | OFF | 随机事件、选项、后续事件 |
| 剧情系统 | story | `story` | OFF | 主线、章节、结局 |
| 天气系统 | weather | `weather` | OFF | 天气状态、对系统修正 |
| 世界系统 | world | `world` | OFF | 世界状态、区域全局事件 |
| 贸易系统 | trade | `trade` | OFF | 交易、汇率、物价 |
| 商人系统 | merchant | `merchant` | OFF | 商人库存、来访周期 |
| 医疗系统 | medical | `medical` | OFF | 疾病、治疗、药品消耗 |
| 士气系统 | morale | `morale` | OFF | 士气值、生产/稳定修正 |
| 防御系统 | defense | `defense` | OFF | 城防、袭击防御结算 |
| 灾害系统 | disaster | `disaster` | OFF | 尸潮、风暴、地震等大事件 |
| 成就系统 | achievement | `achievement` | OFF | Steam 成就映射 |
| Steam 集成 | steam | `steam` | OFF | Steamworks API 封装 |
| 音频系统 | audio | `audio` | OFF | BGM/SFX/混音 |
| 设置系统 | settings | `settings` | OFF | 图形/音量/辅助功能 |

---

# PART C 系统依赖图

## C1 完整依赖关系

```text
CORE (恒开)
 ├── config
 ├── save
 ├── time
 ├── ui
 └── core

resource  → (无, CORE 级)
shelter   → (无)
building  → shelter, resource

production  → building, resource
population  → shelter
survivor    → population, building
npc         → shelter
map         → shelter
world       → time
wildlife    → map
animal      → wildlife
enemy       → shelter
loot        → resource
location    → map, loot
exploration → map, location, survivor
item        → resource
equipment   → item
crafting    → item, building
technology  → building
combat      → enemy
event       → shelter
quest       → npc, event
story       → quest
weather     → time
trade       → item, resource, npc
merchant    → trade
medical     → building, item
morale      → population
defense     → building
disaster    → weather, event
achievement → core
steam       → core
audio       → core
settings    → core
```

软依赖 (`system.conf [soft_dependencies]`, 缺失不阻止启动, 启用方功能降级):

```text
combat    ⇢ equipment, survivor, item   (无装备=徒手战斗)
enemy     ⇢ map                          (无地图=基地周边遭遇)
loot      ⇢ map, location                (无地图=固定搜刮点)
world     ⇢ weather                      (无天气=仅昼夜/永夜)
production⇢ survivor                     (无人口=建筑自动生产)
```

## C2 依赖图 (第一阶段高亮)

```text
CORE
 ├── Resource  ──ON──┐
 ├── Shelter   ──ON──┤
 └── Save      ──ON──┘
        │
        └── Building ──ON──  ← PLAYABLE CORE 闭环
```

## C3 依赖规则

1. 依赖写在 `system.conf [dependencies]`, ConfigManager 启动时校验。
2. `A = B, C` 表示启用 A 时 B 与 C 必须同为 true。
3. 违例时输出 `MissingDependency` 错误并**终止启动**, 禁止悄悄运行。
4. 依赖仅声明"直接依赖"; 传递依赖由校验器递归展开验证。

---

# PART D 大 CONF 设计

## D1 职责边界

大 CONF = `configs/system.conf`, **唯一**一个。只允许包含:

- `[meta]` 配置版本
- `[profile]` 开发阶段预设
- `[system]` 系统级开关 (布尔)
- `[dependencies]` 依赖声明
- `[engine]` 启动级硬性参数 (时间倍率、存档槽数量等)

**禁止**出现建筑/资源/事件等具体内容数值 — 那是小 CONF 的职责。

## D2 PROFILE 预设

| profile | 含义 | 默认开关组合 |
|---|---|---|
| prototype | 原型验证 | resource + shelter + building |
| vertical_slice | 垂直切片 | + population, survivor, map, location, loot, exploration, item, event |
| development | 开发联调 | vertical_slice + combat, enemy, equipment, weather, quest |
| full_game | 正式全量 | 全部业务系统 ON (steam/achievement 依发行需要) |
| debug | 调试 | prototype + 任意手开, 开启 `allow_debug_fallback` |
| test | 自动化测试 | 按用例显式指定 |

规则: **预设仅提供默认值, 最终以 `[system]` 中显式写出的开关为准** (显式覆盖预设)。

## D3 开关语义

| 值 | 行为 |
|---|---|
| true | 启动时初始化该系统, 加载其小 CONF 目录, 挂载 UI |
| false | **完全不初始化**: 不建 Manager、不加载数据、不挂 UI。小 CONF 文件允许存在 ("内容存在, 功能关闭") |

## D4 启用系统后的自动加载

开启新系统**不需要改核心代码**:

```text
改 system.conf: survivor = true, population = true
→ 重启游戏
→ ConfigManager 校验依赖
→ 自动加载 configs/survivors/*.conf, configs/population/*
→ SystemRegistry 自动实例化 SurvivorSystem / PopulationSystem
```

前提: 该系统的 System 类已在注册表登记 (一次性)。新增系统 = 新增 1 个 System 类 + 注册 + 目录, 不触碰核心循环。

## D5 实际文件

完整真实数据见 `configs/system.conf` (第一阶段: `resource/shelter/building = true`, 其余 false, `profile = prototype`)。

---

# PART E 小 CONF 设计规范 (CONF-D v2)

## E1 设计目标

- 人类可读可编辑, diff 友好
- Godot 4 `ConfigFile` 可直接解析 (分层 INI 语义)
- 类型明确、引用可校验、可扩展、可版本化
- **新增 100 个建筑/事件/NPC = 新增 CONF 文件, 不改代码**

## E2 通用格式

```ini
; 注释以分号开头
[meta]
config_version = 1          ; int, 配置结构版本
schema = building           ; 声明本文件遵循的字段规范
id = building.generator     ; 全局唯一 ID

[base]
name = 废旧发电机            ; 展示名 (禁止用 name 查数据, 只用 id)
; ...字段...

[level.1]                   ; 分层节, 命名空间用点号
produce_power_per_hour = 5  ; typed value
```

## E3 类型系统

| 类型 | 写法 | 校验 |
|---|---|---|
| bool | `true` / `false` | 枚举 |
| int | `5` | 范围检查 |
| float | `1.5` | 范围检查 |
| string | 不带引号的行文本 | 非空 (name/description) |
| enum | `common` | schema 枚举集 |
| id_ref | `building.generator` | **必须解析到已注册 ID** |
| id_ref_with_level | `building.generator:2` | 同上 + 等级存在 |
| id_list | `[a.b, c.d]` | 逐项解析 |
| range | `10~30` | min <= max |
| minutes | `90` | >= 0 |

## E4 ID 呺名规范

```text
<entity_type>.<snake_case_name>

resource.wood        building.generator      shelter.levels
survivor.engineer    npc.merchant_01         location.supermarket_01
enemy.infected_01    event.generator_failure quest.main_01
item.medkit_01       loot.hospital_cache     weather.storm
```

- 全局唯一, 不允许 DuplicateID
- **禁止**程序通过中文 Name 查找数据 — name 仅用于显示
- 运行时实体持有 `config_id` + `instance_id` (存档用)

## E5 层级块 (Level Block)

建筑/庇护所/敌人成长使用 `[level.N]`:

- `level.N.upgrade_cost_*` = **升到本级**的花费 (level.1 即建造花费)
- 生产/消耗/容量 = 本级生效值 (全量值, 非增量)
- 视觉切换由 `visual_stage` 映射 Godot Scene 内状态, CONF 不写节点树

## E6 通用字段集 (各 schema 的并集)

```text
id / name / description / category / tags
unlock_condition(如 unlock_shelter_level) / requirements / dependencies
level / max_level / cost / production / consumption / capacity
rewards / loot / risk / time / visual / audio
```

每个 schema 明确规定哪些字段必填, 由 ConfigManager 按 schema 校验 (MissingData / InvalidValue)。

## E7 schema 清单 (随系统开放逐步启用)

| schema | 所在目录 | 关键字段 |
|---|---|---|
| resource | resources/ | category, rarity, flow_type, capacity, value_curve, sources |
| shelter | shelter/ | levels_file, max_level, initial_state |
| shelter_levels | shelter/ | population_cap, building_slots, storage_bonus, production_bonus_percent, defense, income_*, unlocks_*, upgrade_cost_*, requirements_* |
| building | buildings/ | category, max_level, unlock_shelter_level, size, worker_requirement, dependencies, level.N |
| survivor | survivors/ | profession, rarity, stats, skills, work_pref |
| npc | npcs/ | identity, spawn_region, spawn_condition, functions, recruit_allowed |
| location | locations/ | region, risk, search_time, loot_table, events, respawn |
| loot_table | loot/ | entries: item/resource + weight + range |
| enemy | enemies/ | hp, atk, def, speed, ai, drop_table |
| animal | wildlife/ | hp, yield, habitat, behavior |
| item | items/ | stack, weight, use_effect, tradable |
| event | events/ | condition, options, results, follow_up |
| quest | quests/ | chain, objectives, rewards |
| weather | weather/ | duration, modifiers |
| disaster | disaster/ | warning_time, impact, rewards |
| exploration | exploration/ | cost_time, risk_rules, carry_weight |

## E8 版本与迁移

- 每个文件 `[meta] config_version = N`
- ConfigManager 检测版本; 低版本经 `migrations/` 迁移链升级
- 主版本不一致 → ConfigError, 不静默猜测

## E9 配置错误处理

| 错误类 | 触发条件 | 级别 |
|---|---|---|
| ConfigError | 核心缺失/版本不符/解析失败 | 终止启动 |
| MissingDependency | 系统依赖未开启 | 终止启动 |
| MissingData | 必填字段缺失 | 终止启动 |
| InvalidValue | 越界/类型错误 | 终止启动 |
| InvalidID | id_ref 解析失败 | 终止启动 (`missing_ref_policy = fail`) |
| DuplicateID | ID 重复 | 终止启动 |
| ConfigWarning | 非必填缺失/用了默认值/多余字段 | 告警继续 |

启动日志格式示例:

```text
CONFIG ERROR: Building "building.generator" requires resource "resource.fuel"
but resource fuel is disabled.
CONFIG ERROR: Exploration requires Map.
Please enable: map = true
CONFIG WARN : building.farm [level.4] missing visual_stage, default used.
```

## E10 默认值原则

- 非必填字段缺失 → 用 schema 默认值, 记 ConfigWarning, **不崩溃**
- 核心字段缺失 (id / name / level 数值 / system.conf 的 time 倍率) → ConfigError

---

# PART F 核心资源体系

## F1 资源总表 (8 种核心资源 + 1 种基础设施资源)

| ID | 名称 | 类型 | 稀有度 | 主要用途 | 获取主渠道 (前/中/后期) | 可交易 | 有限 |
|---|---|---|---|---|---|---|---|
| resource.wood | 木材 | material | common | 建造/升级建筑 | 基地生产→探索→事件 | 是 | 否 |
| resource.steel | 钢材 | material | common | 建筑升级/防御工事 | 基地生产→探索→敌人掉落 | 是 | 否 |
| resource.food | 食物 | consumable | common | 维持消耗/任务 | 搜刮→基地生产→狩猎 | 是 | 否 |
| resource.water | 水 | consumable | common | 维持消耗/农业 | 搜刮→基地生产 | 是 | 否 |
| resource.fuel | 燃料 | material | uncommon | 发电/车辆/远征 | 工业区探索→交易 (第 2 阶段) | 是 | 否 |
| resource.medicine | 药品 | consumable | uncommon | 医疗/状态恢复 | 医院搜刮→事件→商人 (第 2 阶段) | 是 | 否 |
| resource.electronics | 电子元件 | material | rare | 科技/通信/高级建筑 | 城市/工业搜刮 (第 3 阶段) | 是 | 否 |
| resource.rare_alloy | 稀有合金 | material | epic | 终局建筑/装备 | 军事区/Boss/禁区 (第 3 阶段+) | 是 | **是** |
| resource.power | 电力 | infrastructure | common | 驱动耗电建筑 | 发电机产出 (流转型) | 否 | 否 |

## F2 获取渠道归属 (避免"万物皆可掉")

| 渠道 | 主要产出 | 次要产出 |
|---|---|---|
| 基地生产 (建筑) | wood, steel, food, water, power | — |
| 庇护所基础收入 | wood, steel | — |
| 野外采集/搜索废墟 | food, water, medicine | wood, steel |
| 探索地点稀有箱 | electronics, fuel | rare_alloy, medicine |
| 击杀敌人 | — | steel, rare_alloy, medicine |
| 狩猎动物 | food | — |
| 随机事件 | 任一类 (小量) | medicine, fuel |
| 任务奖励 | 按任务表 | rare_alloy |
| 交易 | 货币化互换 | 全类 (溢价) |

## F3 价值曲线 (爽文式)

前期 wood/steel 最贵 (建设饥渴) → 中期 food/water 平稳、medicine/fuel 抬头 → 后期 electronics/rare_alloy 主导。
具体数值见 `configs/resources/*.conf` 的 `[value_curve]`。

## F4 第一阶段 (MVP) 最小集合

**wood, steel, food, water, power** (5 种)。fuel/medicine/electronics/rare_alloy 的 CONF 文件可在第 2 阶段加入 registry, 不改代码。

---

# PART G 庇护所等级体系

## G1 完整设计 Lv1~Lv12

| 等级 | 名称 | 人口 | 建筑槽 | 防御 | 生产加成 | 解锁建筑 | 解锁区域 | 解锁系统 |
|---|---|---|---|---|---|---|---|---|
| 1 | 废弃哨站 | 5 | 4 | 10 | 0% | generator, warehouse, lumber_yard, water_collector | — | — |
| 2 | 修补营地 | 10 | 6 | 25 | 5% | farm, salvage_workshop | 城郊 | — |
| 3 | 前哨聚落 | 20 | 8 | 50 | 10% | workshop, dormitory | 城市废墟入口 | — |
| 4 | 铁壁据点 | 30 | 10 | 90 | 15% | watchtower, wall, clinic | 工业区边缘 | defense |
| 5 | 自给城镇 | 45 | 12 | 140 | 20% | greenhouse, water_purifier, radio_tower | 农村/森林 | trade, merchant |
| 6 | 要塞雏形 | 60 | 14 | 200 | 25% | lab, solar_array | 山区 | technology |
| 7 | 区域强权 | 80 | 16 | 280 | 30% | 军用级建筑 | 军事区 | combat 装备链 |
| 8 | 末世城邦 | 100 | 18 | 380 | 35% | 稀有生产线 | 感染区外围 | story 章节 3 |
| 9 | 钢铁之心 | 125 | 20 | 500 | 40% | 终局建筑 I | 感染区 | — |
| 10 | 黎明之光 | 150 | 22 | 650 | 45% | 终局建筑 II | 禁区入口 | — |
| 11 | 人类灯塔 | 180 | 24 | 850 | 50% | 终局建筑 III | 禁区 | — |
| 12 | 末世丰碑 | 220 | 26 | 1100 | 60% | 全解锁 | 全图 | 结局 |

## G2 每级数据结构 (shelter_levels schema)

```text
level.N:
  name / description / visual_stage
  population_cap / building_slots / storage_bonus / defense
  production_bonus_percent
  income_wood_per_hour / income_steel_per_hour      # 基础拾荒收入
  unlocks_buildings[] / unlocks_systems[] / unlocks_locations[]
  upgrade_cost_wood/steel/food/water                 # 0 = 无 (Lv1)
  requirements_buildings[] (id:level) / requirements_shelter_level
```

## G3 MVP 数据 (真实样例)

完整真实数据见 `configs/shelter/shelter_levels.conf` (Lv1~Lv3):

- Lv1→Lv2: wood 300 / steel 150 / food 50 / water 50, 需 generator:2 + warehouse:1
- Lv2→Lv3: wood 800 / steel 400 / food 200 / water 200, 需 generator:3 + lumber_yard:2 + water_collector:2

Lv4~Lv12 在后续阶段以**追加 `[level.4]`~`[level.12]` 节**的方式加入同一文件, 不改代码。

---

# PART H 建筑体系

## H1 建筑总表 (16 种, 覆盖 10 个分类)

| 分类 | 建筑 ID | 名称 | 最大等级 | 解锁 |
|---|---|---|---|---|
| core | building.warehouse | 仓库 | 5 | Lv1 |
| energy | building.generator | 废旧发电机 | 5 | Lv1 |
| energy | building.solar_array | 太阳能阵列 | 5 | Lv6 |
| resource | building.lumber_yard | 木材回收场 | 5 | Lv1 |
| resource | building.water_collector | 集水器 | 5 | Lv1 |
| resource | building.farm | 温室农场 | 5 | Lv2 |
| resource | building.greenhouse | 水培温室 | 5 | Lv5 |
| processing | building.salvage_workshop | 废钢回收站 | 5 | Lv2 |
| processing | building.workshop | 维修工坊 | 5 | Lv3 |
| processing | building.water_purifier | 净水站 | 5 | Lv5 |
| medical | building.clinic | 医疗站 | 5 | Lv4 |
| population | building.dormitory | 宿舍 | 5 | Lv3 |
| defense | building.watchtower | 瞭望塔 | 5 | Lv4 |
| defense | building.wall | 围墙 | 5 | Lv4 |
| tech | building.lab | 实验室 | 5 | Lv6 |
| communication | building.radio_tower | 无线电塔 | 5 | Lv5 |

## H2 建筑数据结构 (building schema)

```text
[meta]   id / config_version / schema
[base]   name / description / category / max_level
         unlock_shelter_level / size / worker_requirement
         dependencies[] (id_ref_with_level) / visual_scene
[tags]   tags[]
[level.N] visual_stage
          upgrade_cost_wood/steel/food/water(/fuel...)
          produce_<resource>_per_hour / consume_<resource>_per_hour
          capacity_bonus_all / capacity_bonus_<resource>
          worker_requirement / defense_bonus      # 可选, 按需
```

约定:
- `upgrade_cost_*` = 升到本级的花费; `produce/consume_*_per_hour` = 本级全量值
- 产量引用资源 ID 后缀 (`produce_wood_per_hour` ↔ `resource.wood`), ConfigManager 校验资源存在且未被禁用
- 未写出的 produce/consume 字段视为 0
- 新增建筑 = 新增 `buildings/xxx.conf` + 在 `buildings.conf [registry]` 登记一行

## H3 MVP 建筑 (6 种, 每种 5 级, 真实数据)

| 建筑 | 产出/小时 (Lv1→Lv5) | 消耗/小时 (Lv1→Lv5) | 依赖 | 解锁 |
|---|---|---|---|---|
| generator | power 5→40 | — | — | Lv1 |
| warehouse | capacity +200→2000 | — | — | Lv1 |
| lumber_yard | wood 5→34 | power 0→5 | — | Lv1 |
| water_collector | water 4→32 | power 0→5 | — | Lv1 |
| farm | food 4→32 | water 2→12, power 1→6 | water_collector:1 | Lv2 |
| salvage_workshop | steel 3→24 | power 1→8 | generator:1 | Lv2 |

完整数值见 `configs/buildings/*.conf`。

## H4 MVP 经济闭环验证

```text
开局: wood 200 / steel 80 / food 60 / water 60 + generator:1 + warehouse:1
基地收入: wood +2/h, steel +1/h; 维持: food -2/h, water -2/h
建造 lumber_yard:1 (wood 40, steel 30) → wood +5/h
升级 generator:2 (wood 120, steel 60) → power +10/h
升级 warehouse:2 (wood 120, steel 80) → 容量 +400
升级 shelter Lv2 (wood 300, steel 150, food 50, water 50)
  → 解锁 farm / salvage_workshop, 槽位 4→6, 收入加成 +5%
建造 farm:1 (wood 90, steel 30) → food +4/h, water -2/h, power -1/h
建造 water_collector:1 (wood 60, steel 20) → water +4/h
建造 salvage_workshop:1 (wood 100, steel 20) → steel +3/h, power -1/h
升级 shelter Lv3 (wood 800, steel 400, food 200, water 200)
  → 解锁后续内容, 槽位 6→8
保存 → 重新加载 → 状态一致
```

结论: wood/steel/food/water/power 五资源形成完整产销闭环, 可支撑 Lv1→Lv3 全程。

---

# PART I 幸存者 / NPC

## I1 幸存者体系 (survivor, 第 2 阶段)

职业 8 种: `worker 工人 / engineer 工程师 / doctor 医生 / soldier 士兵 / scout 侦察兵 / farmer 农夫 / scientist 科研员 / cook 厨师`

```text
survivor.<profession>_<nn>
  profession / rarity (common~legendary) / stats (str/agi/int/vit)
  skills[] / work_pref (建筑偏好) / explore_ability / combat_ability
  status (idle/working/exploring/sick/injured)
```

- 受人口系统约束 (population_cap), 在建筑岗位产生生产加成
- 稀有度影响属性上限与技能槽; 技能效果全部数值化入 CONF

## I2 NPC 体系 (npc, 第 2 阶段)

| NPC ID | 身份 | 出现区域 | 功能 | 可招募 | 重复出现 |
|---|---|---|---|---|---|
| npc.merchant_01 | 流动商人 | 城郊/安全区 | 交易 | 否 | 是 |
| npc.doctor_01 | 游医 | 城郊/农村 | 医疗 | 是 | 是 |
| npc.engineer_01 | 机械师 | 工业区 | 建筑折扣/修理 | 是 | 是 |
| npc.scout_01 | 侦察员 | 森林/山区 | 地图情报 | 是 | 否 |
| npc.soldier_01 | 逃兵 | 军事区边缘 | 战斗协助 | 是 | 否 |
| npc.scientist_01 | 研究员 | 城市废墟 | 科技解锁 | 是 | 否 |
| npc.stranger_01 | 神秘人 | 禁区 | 剧情/特殊奖励 | 否 | 否 |
| npc.quest_giver_01 | 幸存者首领 | 城市废墟 | 任务 | 否 | 是 |

```text
npcs/merchant_01.conf
  [meta] id = npc.merchant_01
  [base] identity / spawn_region[] / spawn_condition / repeatable / recruit_allowed
  [functions] trade_table / services[] / quests[] / events[]
```

新增 NPC = 新增 `npcs/xxx.conf` + registry 登记。

---

# PART J 野外资源 (搜刮节点)

30 种野外可交互物资节点 (schema: `loot_node`), 分 12 类:

| 类别 | 节点示例 | 主产出 | 危险 | 刷新 |
|---|---|---|---|---|
| 住宅 | house_wardrobe / house_kitchen / house_bedroom / house_garage | food, water, wood, 杂物 | 低 | 7 天 |
| 车辆 | car_trunk / bus_wreck / truck_cargo / van_ambulance | fuel, medicine, item | 低中 | 一次性 |
| 超市 | supermarket_shelf / supermarket_backroom / supermarket_frozen | food, water | 中 | 14 天 |
| 医院 | hospital_pharmacy / hospital_storage / hospital_office | medicine, item | 中高 | 21 天 |
| 工厂 | factory_warehouse / factory_line / factory_chemical | steel, fuel, electronics | 中高 | 21 天 |
| 仓库 | depot_crates / depot_fuel_tank / depot_loading | steel, fuel, wood | 中 | 14 天 |
| 农场 | barn_hay / farm_silo / farm_toolshed / farmhouse_cellar | food, water, wood | 低 | 7 天 |
| 军事区 | military_armory / military_checkpoint / military_depot / military_tent | rare_alloy, equipment | 极高 | 一次性 |
| 森林 | forest_herbs / forest_beehive / forest_camp | medicine, food | 低 | 3 天 |
| 道路 | road_pileup / road_toll / roadside_diner | fuel, food, item | 中 | 14 天 |
| 废墟 | ruin_rubble / ruin_basement / ruin_kiosk | wood, steel, electronics | 中 | 14 天 |
| 特殊 | lab_vault / bunker_sealed / radio_station / bank_vault | rare_alloy, story, electronics | 极高 | 一次性 |

节点数据结构:

```text
loot_node.<id>
  type / spawn_region[] / loot_table_ref (id_ref)
  amount_range (range) / search_time (minutes) / danger (enum)
  respawn_days / rarity / special_event (id_ref 可空)
```

---

# PART K 野外生物

## K1 普通动物 (animal)

| ID | 名称 | 产出 | 栖息 | 行为 |
|---|---|---|---|---|
| animal.rat | 老鼠 | food(少) | 城市/住宅 | 逃窜 |
| animal.rabbit | 兔 | food, 皮毛 | 农村/森林 | 逃窜 |
| animal.deer | 鹿 | food, 皮毛 | 森林/山区 | 逃窜 |
| animal.boar | 野猪 | food, 皮毛 | 森林 | 反击 |
| animal.dog | 野狗 | food | 城郊 | 群体/反击 |
| animal.wolf | 狼 | food, 皮毛 | 森林/山区 | 群体攻击 |
| animal.crow | 乌鸦 | food(极少) | 全图 | 逃窜 |
| animal.snake | 蛇 | food, 毒液 | 森林/废墟 | 反击 |

## K2 感染动物 (enemy schema, wildlife 分组)

| ID | 名称 | 特点 | 掉落 |
|---|---|---|---|
| enemy.infected_dog | 感染犬 | 速度快 | steel, medicine |
| enemy.infected_boar | 感染野猪 | 高血量 | food, rare_alloy |
| enemy.infected_wolf | 感染狼 | 群体 | steel, medicine |
| enemy.mutated_deer | 变异鹿 | 高攻击 | rare_alloy |

## K3 感染体/敌人 (enemy)

| ID | 名称 | 定位 | 掉落 |
|---|---|---|---|
| enemy.infected_01 | 感染者 | 基础杂兵 | steel, item |
| enemy.infected_fast | 快速感染者 | 追击 | medicine |
| enemy.infected_heavy | 重型感染者 | 坦克 | steel, rare_alloy |
| enemy.infected_ranged | 远程感染体 | 远程 | electronics |
| enemy.infected_bomber | 自爆感染体 | 爆发 | fuel |
| enemy.infected_elite | 精英感染体 | 精英 | rare_alloy, equipment |
| enemy.boss_mutant_01 | Boss: 灰孢母体 | 区域 Boss | rare_alloy, story |

敌人数据结构: `hp / atk / def / speed / ai_type / aggro_range / drop_table (id_ref) / exp`。

---

# PART L 探索系统

## L1 探索循环

```text
选择区域(map) → 选择地点(location) → 组队(survivor) + 负重上限
→ 时间推进(time) → 遭遇(enemy/animal/event) → 搜刮(loot) → 撤退/伤亡
→ 结算入仓(resource)
```

## L2 配置驱动

| 文件 | 驱动内容 |
|---|---|
| exploration.conf | 全局规则: 基础负重、时间系数、撤退规则、伤亡惩罚 |
| map/*.conf | 区域: 等级、风险、连接、解锁条件 |
| locations/*.conf | 地点: 搜索时间、危险、loot_table、事件表、刷新 |
| loot/*.conf | 掉落表: 条目、权重、数量范围、保底 |

## L3 地点 schema 样例 (未来生成)

```ini
[meta]
config_version = 1
schema = location
id = location.supermarket_01

[base]
name = 城郊超市
region = suburb
recommended_level = 2
risk = medium
search_time = 90
carry_bonus = 20
respawn_days = 14

[loot]
loot_table = loot.supermarket_01
guaranteed = [resource.food]
amount_range = 20~60

[events]
event_table = [event.found_supplies, event.beggar]

[visual]
scene = locations/supermarket_01.tscn
```

---

# PART M 事件系统

## M1 事件总表 (首批 12 个, 全配置化)

| 事件 ID | 触发 | 选项 | 结果 |
|---|---|---|---|
| event.found_supplies | 探索中 | 拿走/检查 | 物资 / 可能遇袭 |
| event.found_survivor | 探索中 | 招募/驱赶/给补给 | 人口 / 士气 / 感谢奖励 |
| event.sos_signal | 无线电类建筑存在 | 救援/忽略 | 奖励 / 无 |
| event.disease | 人口阶段 | 治疗/隔离 | 消耗药品 / 士气下降 |
| event.generator_failure | 发电机 Lv3+ | 立即修/停机修 | 消耗 steel / 停电损失 |
| event.horde_coming | 灾害阶段 | 加固/撤离 | 防御结算 |
| event.heavy_rain | weather=rain | 接水/防护 | water+ / 产能下降 |
| event.blizzard | weather=snow | 保暖/停工 | morale± / 产能 |
| event.beast_attack | wildlife=on | 驱赶/狩猎 | 食物+ / 伤亡 |
| event.merchant_arrive | merchant=on | 交易/拒绝 | 交易窗口 |
| event.mystery_site | 探索稀有 | 进入/标记 | 稀有奖励 / 风险 |
| event.aftershock | disaster=on | 加固/救人 | 建筑受损 / 人口 |

## M2 事件 schema

```ini
[meta]
schema = event
id = event.generator_failure

[condition]
trigger = random
weight = 10
cooldown_hours = 48
require_tags = [building.generator:3]

[option.1]
label = 立即抢修
cost_steel = 20
result = fixed
follow_up = event.generator_upgrade_hint

[option.2]
label = 停机检修
cost_none = true
result = power_penalty_24h

[result.fixed]
reward_power_bonus_percent = 0
message = 发电机恢复运转。
```

字段: condition / options / results / rewards / penalties / follow_up / weight / cooldown。新增事件 = 新增 `events/xxx.conf`。

---

# PART N 任务 / 剧情

## N1 任务体系 (quest)

- 任务链 (chain) + 目标 (objective) + 奖励 (reward), 全配置化
- 任务可引用: 事件 (id_ref)、地点、敌人、资源、NPC
- 分类: 主线 main / 支线 side / 日常 daily / 聚落请求 settlement

```ini
[meta]
schema = quest
id = quest.main_01

[base]
name = 点亮晨星
type = main
chain = chain_main
prerequisites = []

[objective.1]
type = building_level
target = building.generator
value = 2

[objective.2]
type = shelter_level
target = shelter.main
value = 2

[reward]
reward_wood = 150
reward_steel = 80
unlock = quest.main_02
```

## N2 剧情体系 (story)

- 主线按章节 (chapter) 推进, 引用 quest 完成度
- 第一阶段无剧情系统; 剧情节点全部由 quest + event 引用驱动
- 结局分支数据挂 `story/*.conf`, 由 story 系统读取

---

# PART O 时间 / 天气 / 灾害

## O1 时间 (time, CORE 恒开)

```text
1 游戏日 = 24 游戏小时
1 游戏小时 = real_seconds_per_game_hour (默认 60 现实秒)
阶段: Day (06:00-19:00) / Night (19:00-06:00)
```

受影响系统: production (生产结算)、exploration (搜索时间/风险)、event (权重)、enemy (夜间仇恨)、weather (切换)。

## O2 天气 (weather, 第 3 阶段)

| 天气 | 持续 | 影响 |
|---|---|---|
| clear 晴 | 随机 | 无 |
| rain 暴雨 | 半天 | 产能 -10%, 集水 +50%, 探索风险 + |
| snow 暴雪 | 半天 | 产能 -20%, morale-, 探索风险 ++ |
| fog 浓雾 | 数小时 | 探索风险 ++, 敌人警戒 - |
| heatwave 酷热 | 一天 | water 消耗 +30% |
| radiation 辐射尘 | 稀有 | 全图危险, 需 medicine |

天气通过 `weather/*.conf` 定义 modifiers, 各系统读取自己关心的修正键。

## O3 灾害 (disaster, 第 3 阶段+)

尸潮 horde / 风暴 storm / 地震 earthquake / 变异潮 mutation_wave。
每个灾害: `warning_time → impact → defense 结算 → rewards/损失`, 引用 event 系统的 follow_up 机制。

---

# PART P 完整数据关系

## P1 引用关系矩阵 (谁引用谁)

```text
system.conf ──开关──▶ System 类 ──加载──▶ 各系统小 CONF 目录

building ──id_ref──▶ resource        (produce/consume/cost)
building ──id_ref_with_level──▶ building   (dependencies)
building ──int──▶ shelter level      (unlock_shelter_level)
shelter_levels ──id_ref──▶ building  (unlocks_buildings, requirements_buildings)
shelter_levels ──id_ref──▶ location / system  (unlocks_*)
shelter ──id_ref──▶ shelter_levels   (levels_file)

location ──id_ref──▶ loot_table      (loot_table)
location ──id_ref──▶ event           (event_table)
loot_table ──id_ref──▶ resource / item (entries)
enemy ──id_ref──▶ loot_table         (drop_table)
animal ──id_ref──▶ resource          (yield)
event ──id_ref──▶ event              (follow_up)
event ──id_ref──▶ resource / item    (reward/cost)
event ──id_ref_with_level──▶ building (require_tags)
quest ──id_ref──▶ event / enemy / location / building / resource (objectives, reward)
quest ──id_ref──▶ quest              (unlock / chain)
npc ──id_ref──▶ quest / event / item (functions)
exploration ──id_ref──▶ map / location / survivor
```

## P2 引用完整性规则

1. 所有 id_ref 在 ConfigManager 加载期解析; 引用的实体**所属系统已开启**却解析失败 → InvalidID (终止)
2. 休眠引用 (dormant ref): 被引用实体所属系统为 OFF 时, 引用保留但不阻断启动,
   记 ConfigWarning `dormant ref`; 当目标系统未来开启时, 在其加载期强制校验该引用
   (届时解析失败 = InvalidID)。这允许"内容存在, 功能关闭"以及提前书写解锁表
3. 运行期实体: `config_id` (引用 CONF) + `instance_id` (存档身份)

示例: 第一阶段 `shelter_levels.conf` 中 `unlocks_locations = [location.suburb_edge]`,
location 系统为 OFF → dormant ref 告警; 第二阶段 `location = true` 时,
若 `locations/` 下仍无 `location.suburb_edge` → ConfigError 终止。

## P3 GameState (存档) 与 CONF 的边界

| CONF (设计态, 随版本更新) | GameState (运行态, 存档保存) |
|---|---|
| 建筑定义/等级表 | 建筑实例: config_id + instance_id + current_level + 工作状态 |
| 资源定义 | 资源数量、容量 |
| 庇护所等级表 | 当前 shelter_level |
| 事件定义 | 事件冷却计时、已触发标记 |
| 时间规则 | 当前游戏时刻/天数 |

存档保存的是"配置驱动出来的运行状态"; 读档时用 config_id 回查 CONF, 缺失则 ConfigWarning + 按默认处理。

---

# PART Q 目录结构

## Q1 最终目录 (评估后确认)

```text
game/
├── docs/
│   └── Apocalypse_Shelter_Core_World_Config_Specification_v0.2.md
├── configs/                      # ★ 全部游戏内容数据
│   ├── system.conf               # 大 CONF (唯一)
│   ├── core/                     # 核心规则 (时间、默认值)
│   ├── resources/                # resource.registry + 每资源一文件
│   ├── shelter/                  # shelter.conf + shelter_levels.conf
│   ├── buildings/                # buildings.registry + 每建筑一文件
│   ├── production/               # 配方/生产线 (阶段 2)
│   ├── survivors/  npcs/  population/
│   ├── exploration/  map/  locations/  loot/
│   ├── wildlife/  enemies/  combat/
│   ├── items/  equipment/  crafting/  technology/
│   ├── quests/  events/  story/
│   ├── weather/  world/  trade/  merchants/  disaster/
│   ├── steam/  achievement/
│   └── migrations/               # config_version 迁移脚本/数据
└── src/                          # Godot 工程
    ├── core/                     # boot, ConfigManager, SystemRegistry, SaveManager, TimeManager
    ├── systems/                  # 每系统一目录: resource/, shelter/, building/, ...
    ├── ui/
    └── scenes/                   # 视觉表现 (与 CONF 严格分离)
```

评估结论: 该结构成立。微调:
1. 增加 `core/` (核心规则) 与 `migrations/` (版本迁移)
2. `location`/`loot` 从 `exploration/` 独立成顶层目录 (与依赖图一致)
3. registry 命名: `buildings/buildings.conf` (buildings 目录下), `resources/resource.conf`

## Q2 当前仓库已生成 (第一阶段)

```text
configs/
├── system.conf
├── resources/  resource.conf, wood.conf, steel.conf, food.conf, water.conf, power.conf
├── shelter/    shelter.conf, shelter_levels.conf
└── buildings/  buildings.conf, generator.conf, warehouse.conf, lumber_yard.conf,
                water_collector.conf, farm.conf, salvage_workshop.conf
```

---

# PART R 第一阶段 3 系统 MVP

## R1 开关

```ini
resource = true
shelter = true
building = true
其余全部 = false
profile = prototype
```

## R2 必须实现的程序模块

| 模块 | 职责 | 对应 CONF |
|---|---|---|
| ConfigManager | 读 system.conf→校验依赖→按开关加载小 CONF→缓存→查询接口 | 全部 |
| CoreSystem | 启动流程、tick、SystemRegistry | system.conf [engine] |
| ResourceSystem | 资源池、容量、产消结算、upkeep | resources/* |
| ShelterSystem | 等级、槽位、解锁、基础收入、升级校验 | shelter/* |
| BuildingSystem | 实例化、建造/升级、产消挂载、依赖校验 | buildings/* |
| SaveSystem | GameState 序列化/反序列化、版本 | — |
| TimeManager | 游戏时钟、小时 tick | system.conf [engine] |

## R3 ConfigManager 查询接口 (最小集)

```gdscript
ConfigManager.is_enabled("resource")            -> bool
ConfigManager.get_resource("resource.wood")     -> Dictionary
ConfigManager.get_shelter_level(3)              -> Dictionary
ConfigManager.get_building("building.generator")-> Dictionary
ConfigManager.get_building_level("building.generator", 2) -> Dictionary
ConfigManager.get_initial_state()               -> Dictionary
ConfigManager.validate_building_cost(id, level) -> bool
```

## R4 PLAYABLE CORE 验收流程

```text
游戏启动 → Boot → ConfigManager(读/校验/加载) → Core
→ Resource/Shelter/Building 初始化
→ 创建玩家初始状态 + Lv1 庇护所 + 初始建筑 (generator:1, warehouse:1)
→ 小时 tick: 生产/消耗结算 (含 upkeep food/water -2/h)
→ 建造建筑 → 升级建筑 → 资源校验扣除
→ 升级庇护所 Lv1→Lv2→Lv3 (校验 requirements_buildings)
→ 新建筑解锁 (farm, salvage_workshop...)
→ 保存 → 重新加载 → 状态一致
```

通过 = 允许进入第二阶段。

## R5 本仓库交付物

- 本文档 (规范)
- `configs/` 全部 MVP 真实数据 (system + 5 资源 + 庇护所 Lv1-3 + 6 建筑×5 级)

---

# PART S 第二阶段开放顺序

一次开启一组, 每组稳定后再开下一组:

| 组 | 开关 | 内容 |
|---|---|---|
| 1 | production, population | 岗位生产、人口消耗 |
| 2 | survivor, item | 招募、职业、背包物品 |
| 3 | map, location, loot | 区域图、地点、搜刮 |
| 4 | exploration | 派队远征闭环 |
| 5 | enemy, wildlife, animal | 生物与威胁 |
| 6 | equipment, combat | 装备与战斗 |
| 7 | event, quest, npc | 事件/任务/NPC 交互 |
| 8 | crafting, technology, medical, morale | 深度经营 |
| 9 | trade, merchant | 经济互通 |
| 10 | weather, world, disaster, defense | 世界压力 |
| 11 | story | 剧情与结局 |
| 12 | steam, achievement, audio, settings | 发行包装 |

每组开启时只做: 补齐该组小 CONF + 该系统 System 类; 核心代码不动。

---

# PART T 配置加载生命周期

```text
1. Boot
2. ConfigManager.load("configs/system.conf")
3. 解析 [meta]/[profile]/[system]/[dependencies]/[engine]
4. 应用 profile 默认值 → 显式开关覆盖
5. 依赖校验 (递归) → 违例输出 MissingDependency 并终止
6. 对每个 enabled 系统:
   a. 读取其 registry 文件 (如 buildings/buildings.conf)
   b. 逐个加载登记的 *.conf
   c. 按 schema 校验: 必填/类型/范围 (MissingData/InvalidValue)
   d. ID 唯一性 (DuplicateID)
   e. id_ref 解析 (InvalidID) — 含跨系统引用检查 (P2)
   f. 版本检查/迁移 (config_version)
   g. 写入内存缓存 (只读)
7. CoreSystem 初始化 → 按开关实例化 System (禁用系统零初始化)
8. 加载/创建 GameState
9. 进入 Main Scene (UI 按开关挂载)
10. 运行期: 系统只读缓存查询 CONF, 不再解析文件
```

失败策略: 任一 ConfigError → 打印完整错误清单 → 终止启动 (除非 `allow_debug_fallback = true` 的 debug profile)。

---

# §47 最终完整检查 (20 项)

| # | 检查项 | 结论 |
|---|---|---|
| 1 | 所有系统都有开关? | ✔ 35 个业务系统均在 system.conf [system]; CORE 5 模块恒开并已声明 |
| 2 | 系统依赖完整? | ✔ [dependencies] + PART C 递归可验证 |
| 3 | 大/小 CONF 职责清晰? | ✔ 大 CONF 仅开关/依赖/profile/引擎参数; 数值全在小 CONF |
| 4 | 禁用系统真正不初始化? | ✔ 开关=false → 零初始化、不加载、不挂 UI |
| 5 | 开启后自动加载? | ✔ 重启后 ConfigManager 按 registry 自动加载, 不改核心代码 |
| 6 | 数据唯一 ID? | ✔ `<type>.<name>` 规范 + DuplicateID 校验 |
| 7 | 建筑引用资源? | ✔ produce_*/consume_*/upgrade_cost_* ↔ resource.*; InvalidID 校验 |
| 8 | 建筑引用庇护所等级? | ✔ unlock_shelter_level + shelter_levels.requirements_buildings |
| 9 | 探索引用地点? | ✔ exploration → location (依赖图 + P1) |
| 10 | 地点引用 Loot? | ✔ location.loot_table → loot_table (P1) |
| 11 | Enemy 引用 Drop? | ✔ enemy.drop_table → loot_table (P1) |
| 12 | Event 引用 Reward? | ✔ event result 奖励字段 + follow_up (P1) |
| 13 | Quest 引用 Event? | ✔ quest objective/reward 可含 event id_ref (P1) |
| 14 | Save 保存配置驱动状态? | ✔ config_id + instance_id 模型 (P3) |
| 15 | 第一阶段三系统闭环? | ✔ PART H4 经济验证: 5 资源产销+升级链+存读档 (PART R4) |
| 16 | 增系统需改核心代码? | ✔ 不需要; 仅新增 System 类+注册+CONF 目录 |
| 17 | +100 建筑只加 CONF? | ✔ 新增 buildings/xxx.conf + registry 一行 |
| 18 | +100 事件只加 CONF? | ✔ 新增 events/xxx.conf (含 registry 登记) |
| 19 | +新 NPC 只加 CONF? | ✔ 新增 npcs/xxx.conf + registry 一行 |
| 20 | 是否存在"加数据必须改核心代码"? | ✔ 无。唯一硬点=新 schema 种类(如新增实体类型)需定义 schema+System, 属于"新系统"而非"新数据" |

复核发现并已修正的点:
- 依赖声明: 原设计仅文档化, 已落入 system.conf `[dependencies]` 由程序校验
- 引用完整性: 已补充 dormant ref 规则 (P2): 未开启系统的引用休眠告警, 开启时强制校验; 已开启系统的悬空引用一律终止
- 版本迁移: 已补充 `migrations/` 目录与迁移策略 (E8)
- MVP 经济: 补充 power 流转资源, 使 building 产消闭环无死资源

---

# FREEZE

```text
SYSTEM DESIGN FREEZE
CONFIGURATION SPEC FREEZE
MVP CORE FREEZE
```

