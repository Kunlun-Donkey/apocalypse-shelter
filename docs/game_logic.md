# 游戏逻辑书 — 规则 / UI / 世界与配置设计 (Apocalypse Shelter)

> 本文件 = **游戏怎么玩 + 界面怎么加载/交互 + 世界/系统/配置设计** 的唯一逻辑依据, 由 `AGENTS.md` 引用。
> 开发流程/阶段任务/工程约定以 `AGENTS.md` 为入口 (先读 AGENTS.md, 再读本文件)。
> 规则数值一律以 `configs/` 下 CONF 为准, 与本文冲突时以 CONF 为准。
> 原 `docs/Apocalypse_Shelter_Core_World_Config_Specification_v0.2.md` (SPEC v0.2) 已**全文整合入本文**,
> 该文件只留重定向存根; 旧引用按下表换算 (代码注释中的 "SPEC Ex" 同)。

文档版本: v0.3 (整合 SPEC v0.2) | 配置规范: CONF-D v2 | 引擎: Godot 4.7.x | 目标平台: Steam (Windows 优先)

**设计总纲** (原文链):

```text
世界体系完整 → 功能模块独立 → 大 CONF 控制系统 → 小 CONF 控制内容
→ 代码负责运行规则 → Scene 负责表现 → 新增内容优先增加 CONF → 核心代码尽量不动
```

## 旧 SPEC 引用映射

| 旧引用 | 新位置 | 旧引用 | 新位置 |
|---|---|---|---|
| SPEC PART A (世界体系) | A1~A2 | SPEC PART J (搜刮) | A10 |
| SPEC PART B (系统列表) | C1~C2 | SPEC PART K (生物) | A11 |
| SPEC PART C (依赖图) | C3~C4 | SPEC PART L (探索) | A12 |
| SPEC PART D (大 CONF) | D1 | SPEC PART M (事件) | A13 |
| SPEC PART E / E3 / E7 / E9 | D2 / D2.3 / D2.7 / D2.9 | SPEC PART N (任务剧情) | A14 |
| SPEC PART F (资源) | A6 | SPEC PART O / O1 / O2~O3 | A5 / A15 |
| SPEC PART G (庇护所等级) | A3 | SPEC PART P (数据关系) | E1~E3 |
| SPEC PART H / H4 (建筑/经济闭环) | A7 / A6 | SPEC PART Q (目录) | E4 |
| SPEC PART I (幸存者/NPC) | A9 | SPEC PART R (MVP 验收) | F1 |
| SPEC PART S (二阶段顺序) | F2 | SPEC PART T (加载生命周期) | D3 |
| SPEC §47 (20 项检查) | F3 | SPEC FREEZE | 文末 FREEZE |

---

## PART A. 游戏逻辑

### A1. 核心循环与项目定位

末世背景下**把庇护所从小木屋一路升级到超级堡垒**是游戏主轴。一切玩法
(搜刮/建造/战斗/人口/天气) 都围绕"攒资源 → 升级庇护所 → 解锁更多"展开。
V1 主线 Lv12+结局 ≈ 35~45h, 全成就 60h+; Lv3 须 ~100 分钟现实可达 (Steam 2h 退款窗)。

- 平台: Steam 单机 | 视角: 2.5D | 类型: 末世庇护所经营升级
- 体验支柱: 末世氛围 + 爽文式成长 + 模拟经营 + 资源管理 + 基级升级 + 探索 + 随机事件 + 轻 RPG
- 不是硬核生存模拟器, 不是纯放置游戏。失败成本低, 成长反馈快。

世界逻辑闭环 (原 SPEC A5):

```text
灰孢爆发 → 社会崩溃 → 资源封存 + 感染体游荡 + 免疫幸存者求生
   ↓
玩家建立庇护所 → 基地生产 + 野外搜刮 → 升级基地/招募人口
   ↓
更强的基地 → 更深的探索 → 更好的资源/装备/情报
   ↓
吸引商人/幸存者/任务 → 应对尸潮/灾害/剧情 → 大型末世基地
```

### A2. 末世背景与世界舞台

#### A2.1 末世背景 (服务于玩法) (原 SPEC A2)

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

#### A2.2 世界舞台: 晨星谷 (Morningstar Valley) (原 SPEC A3)

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

#### A2.3 区域模板 (map 系统数据) (原 SPEC A4)

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

### A3. 庇护所等级链 (12 级, 游戏灵魂)

| Lv | 名称 | visual_stage | 人口 | 建筑槽 | 防御 | 产量加成 | 解锁建筑 | 解锁区域 | 解锁系统 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 小木屋 | cabin | 5 | 4 | 10 | 0% | generator, warehouse, lumber_yard, water_collector | — | npc |
| 2 | 加固木屋 | cabin | 10 | 6 | 25 | 5% | farm, salvage_workshop | 城郊 | — |
| 3 | 修补营地 | camp | 20 | 8 | 50 | 10% | workshop, dormitory | 城市废墟入口 | survivor |
| 4 | 围墙营地 | camp | 30 | 10 | 90 | 15% | watchtower, wall, clinic | 工业区边缘 | defense |
| 5 | 铁皮聚落 | outpost | 45 | 12 | 140 | 20% | greenhouse, water_purifier, radio_tower | 农村/森林 | trade, merchant |
| 6 | 铁壁据点 | outpost | 60 | 14 | 200 | 25% | lab, solar_array | 山区 | technology |
| 7 | 要塞雏形 | fortress | 80 | 16 | 280 | 30% | 军用级建筑 | 军事区 | combat 装备链 |
| 8 | 坚固要塞 | fortress | 100 | 18 | 380 | 35% | 稀有生产线 | 感染区外围 | story 章节 3 |
| 9 | 钢铁之心 | stronghold | 125 | 20 | 500 | 40% | 终局建筑 I | 感染区 | — |
| 10 | 黎明之光 | stronghold | 150 | 22 | 650 | 45% | 终局建筑 II | 禁区入口 | — |
| 11 | 人类灯塔 | stronghold | 180 | 24 | 850 | 50% | 终局建筑 III | 禁区 | — |
| 12 | 超级堡垒 | stronghold | 220 | 26 | 1100 | 60% | 全解锁 | 全图 | 结局 |

- 数据源: `configs/shelter/shelter_levels.conf` 的 `[level.N]` (逐级追加, 无需改代码)
- 每级生效字段: `population_cap / building_slots / storage_bonus / production_bonus_percent / defense` +
  `income_* / unlocks_buildings / unlocks_systems / unlocks_locations` +
  `upgrade_cost_* / requirements_buildings / requirements_shelter_level`
- 当前 MVP 上限 `mvp_max_level = 3` (shelter.conf), 满级后升级按钮禁用, 等待后续版本开放
- 视觉五段演变 (同一构图越修越强): cabin(1-2) → camp(3-4) → outpost(5-6) → fortress(7-8) → stronghold(9-12)

#### A3.1 每级数据结构 (shelter_levels schema) (原 SPEC G2)

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

#### A3.2 MVP 数据 (真实样例) (原 SPEC G3)

完整真实数据见 `configs/shelter/shelter_levels.conf` (Lv1~Lv3):

- Lv1→Lv2: wood 300 / steel 150 / food 50 / water 50, 需 generator:2 + warehouse:1
- Lv2→Lv3: wood 800 / steel 400 / food 200 / water 200, 需 generator:3 + lumber_yard:2 + water_collector:2

Lv4~Lv12 在后续阶段以**追加 `[level.4]`~`[level.12]` 节**的方式加入同一文件, 不改代码。

### A4. 升级规则

- **S1 (现行)**: 升级 = 点击后 30 秒现实冷却结束即升级, 只校验 `requirements_shelter_level`,
  不消耗任何资源。冷却是**临时常量** `TEMP_UPGRADE_COOLDOWN_REAL_SECONDS` (shelter_system.gd),
  S2 引入资源成本后必须废弃
- **S2 起**: 消耗 `upgrade_cost_*` (语义: **升到本级**的花费, level.1 = 建造花费) +
  校验 `requirements_buildings` (id:level 列表), 冷却改由 CONF 驱动
- 状态机: `can_upgrade()` 判定 → `start_upgrade()` 进入升级中 → 冷却结束 `upgrade_completed`
  信号 → 等级+1, 数值按新级生效 (名称/数值全部随 CONF 变化)

### A5. 时间系统 (原 SPEC O1)

- **1 游戏时 = 60 现实秒** — 唯一旋钮 `system.conf [engine] real_seconds_per_game_hour`
- 1 游戏日 = 24 游戏小时; 阶段: Day (06:00-19:00) / Night (19:00-06:00)
- 开局 = **第 1 天 08:00**; 游戏时钟由 TimeManager 驱动; 升级冷却计时用**现实秒** (不走游戏时钟)
- 新游戏/读档都会重置或恢复游戏时刻 (存档含 time 状态)

#### A5.1 时间流速与开局留存节奏 (对齐 Steam 2h 退款窗口)

游戏时间本质是**加速**的: 1 现实分钟 = 1 游戏时 → 1 现实小时 ≈ 2.5 游戏天 →
**2~3 现实小时 = 5~7 游戏天**。开局节奏表 (防止 2 小时退款):

| 现实时间 | 游戏内 | 玩家经历 |
|---|---|---|
| 0~10 分钟 | Day 1 清晨 | 核心绑定 VO, 四选一同伴, 建造启动 |
| ~30 分钟 | Day 1 深夜~Day 2 | Lv2 加固木屋 (第 1 次视觉变化), 农场/回收站, 城郊解锁 |
| ~60~75 分钟 | Day 2~3 | 昼夜已轮转 2 轮, 搜刮循环成型, 钢墙推进 |
| ~100~120 分钟 | Day 4~5 | Lv3 修补营地 (第 2 次视觉变化), survivor 解锁, 城市废墟入口 —— "故事刚开始"钩子 |

设计要求:

- **Lv3 必须在 ~100 分钟内可达** —— 退款线前完成第 2 次大升级, 留下"想看 Lv4"的悬念
- 加速感要**被看见**: UI 显示游戏时钟/日期; 昼夜光照/色调轮转 (廉价高效); 每游戏日一次小结算 (upkeep/日报)
- `real_seconds_per_game_hour` 是唯一时间倍率旋钮, 调留存节奏只动它, 不动各系统数值

受影响系统: production (生产结算)、exploration (搜索时间/风险)、event (权重)、enemy (夜间仇恨)、weather (切换)。

### A6. 资源与经济

#### A6.1 资源总表 (8 种核心资源 + 1 种基础设施资源) (原 SPEC F1)

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

MVP 最小集合 (原 SPEC F4): **wood, steel, food, water, power** (5 种)。
fuel/medicine/electronics/rare_alloy 的 CONF 文件可在第 2 阶段加入 registry, 不改代码。

#### A6.2 获取渠道归属 (避免"万物皆可掉") (原 SPEC F2)

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

#### A6.3 价值曲线 (爽文式) (原 SPEC F3)

前期 wood/steel 最贵 (建设饥渴) → 中期 food/water 平稳、medicine/fuel 抬头 → 后期 electronics/rare_alloy 主导。
具体数值见 `configs/resources/*.conf` 的 `[value_curve]`。

#### A6.4 S1 经济口径 (现行生效)

- **初始资源包** (shelter.conf [initial_state]): wood 200 / steel 100 / food 140 / water 60
  (建材 + 约 3 游戏天口粮, 半挂机约 25~33 游戏时攒出 Lv2)
- **库存上限 = base_capacity + storage_bonus**: 基础容量在 `configs/resources/<id>.conf`
  的 `[flow] base_capacity` (当前均为 200), 加成取当前庇护所等级 `storage_bonus` (0/100/250)
- 庇护所基础拾荒收入: `income_wood_per_hour` / `income_steel_per_hour` (每游戏小时, 等级表)
- 基础消耗 upkeep: food/water 各 2 每游戏小时 (resource.conf [economy]); 溢出策略 stop_production
- 5 种资源: `wood / steel / food / water` (库存类) + `power` (流转型: 实时产需结算, 不参与交易)
- S1 顶部资源条只做**静态展示** (当前数 = 初始值), 不做产消/容量结算;
  S2 ResourceSystem 开启后接管数值 (展示层零改动)

#### A6.5 MVP 经济闭环验证 (原 SPEC H4, 演算样例)

> 注: 下表是设计演算样例, 其中开局资源/费用与现行 CONF 可能有出入, **实际数值以 configs/ 为准**。

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

### A7. 建筑体系 (原 SPEC H)

#### A7.1 建筑总表 (16 种, 覆盖 10 个分类) (原 H1)

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

#### A7.2 建筑数据结构 (building schema) (原 H2)

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

#### A7.3 MVP 建筑 (6 种, 每种 5 级) (原 H3)

| 建筑 | 产出/小时 (Lv1→Lv5) | 消耗/小时 (Lv1→Lv5) | 依赖 | 解锁 |
|---|---|---|---|---|
| generator | power 5→40 | — | — | Lv1 |
| warehouse | capacity +200→2000 | — | — | Lv1 |
| lumber_yard | wood 5→34 | power 0→5 | — | Lv1 |
| water_collector | water 4→32 | power 0→5 | — | Lv1 |
| farm | food 4→32 | water 2→12, power 1→6 | water_collector:1 | Lv2 |
| salvage_workshop | steel 3→24 | power 1→8 | generator:1 | Lv2 |

完整数值见 `configs/buildings/*.conf`。经济闭环演算见 A6.5。

### A8. 存读档

- 3 个槽位: `user://save_slot_N.json` (JSON, `save_version=1`, `saved_at` 时间戳)
- GameState = { shelter 等级 + 升级冷却计时, 游戏时刻 } (S2 起追加资源/建筑等)
- **继续游戏** = 读最近存档 (按 `saved_at` 最大, SaveManager.find_latest_slot(), 无存档禁用)
- 存档路径: Windows `%APPDATA%/Godot/app_userdata/<项目>/`, Linux `~/.local/share/godot/app_userdata/<项目>/`
- **设置与存档分离**: 设置存 `user://settings.json`, 不进游戏存档
- 读档 = `set_state()` 恢复各 System 后进主界面; 存档版本不符 = 视为损坏, 拒绝加载

#### A8.1 GameState 与 CONF 的边界 (原 SPEC P3)

| CONF (设计态, 随版本更新) | GameState (运行态, 存档保存) |
|---|---|
| 建筑定义/等级表 | 建筑实例: config_id + instance_id + current_level + 工作状态 |
| 资源定义 | 资源数量、容量 |
| 庇护所等级表 | 当前 shelter_level |
| 事件定义 | 事件冷却计时、已触发标记 |
| 时间规则 | 当前游戏时刻/天数 |

存档保存的是"配置驱动出来的运行状态"; 读档时用 config_id 回查 CONF, 缺失则 ConfigWarning + 按默认处理。

### A9. 人口与同伴

- `population_cap` = 人口上限 (等级表 A3), 人口消耗 S4 起 (本文 A9.1/M 相关设计)
- Lv1 解锁 npc: **开局四选一同伴** (战斗/资源/陪伴/管家 各一, starter_npcs), 可派出干活
- Lv3 解锁 survivor (幸存者招募上岗)

#### A9.1 幸存者体系 (survivor, 第 2 阶段) (原 SPEC I1)

职业 8 种: `worker 工人 / engineer 工程师 / doctor 医生 / soldier 士兵 / scout 侦察兵 / farmer 农夫 / scientist 科研员 / cook 厨师`

```text
survivor.<profession>_<nn>
  profession / rarity (common~legendary) / stats (str/agi/int/vit)
  skills[] / work_pref (建筑偏好) / explore_ability / combat_ability
  status (idle/working/exploring/sick/injured)
```

- 受人口系统约束 (population_cap), 在建筑岗位产生生产加成
- 稀有度影响属性上限与技能槽; 技能效果全部数值化入 CONF

#### A9.2 NPC 体系 (npc, 第 2 阶段) (原 SPEC I2)

| NPC ID | 身份 | 出现区域 | 功能 | 可招募 | 重复出现 |
|---|---|---|---|---|---|
| npc.merchant_01 | 流动商人 | 城郊/安全区 | 交易 | 否 | 是 |
| npc.doctor_01 | 游医 | 城郊/农村 | 医疗 | 是 | 是 |
| npc.mechanic_01 | 机械师 | 工业区 | 建筑折扣/修理 | 是 | 是 |
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
(注意 id 错开: `npc.engineer_01` 已被开局同伴吴齐越占用, 到访机械师用 `npc.mechanic_01`)

#### A9.3 同伴类型体系 (开局三选一, [passive] 扩展) (原 SPEC I3)

用户定稿 2026-10: 开局第一位同伴从 3 名候选中**三选一** (`shelter.conf starter_npcs`,
玩家在招募面板**点整卡选定**, 见 B4.2), 类型决定被动/主动技能; 其余可在游戏过程中招募
(重复可玩性)。`[passive]`/`[active]` 为 npc schema 扩展块:

| NPC ID | 姓名 | npc_type | 属性 (体力/生存/智慧) | 被动 | 主动 |
|---|---|---|---|---|---|
| `npc.veteran_01` | 唐文轩 (老兵) | `veteran` | 8 / 7 / 4 | 【觅食专长】提升全队获取食物的速度 | 【紧急搜刮】一次性获得一定数量食物 |
| `npc.medic_01` | 张睿 (医师) | `medic` | 4 / 6 / 9 | 【应急救护】减少外出任务里幸存者的伤亡概率 | 【集中救治】一次性治疗一定数量受伤幸存者 |
| `npc.engineer_01` | 吴齐越 (工程师) | `engineer` | 5 / 5 / 10 | 【城防强化】提升据点城防的攻击威力 | 【机械守卫】召唤一台具备攻击力的机器人协助战斗 |

- 三人熟悉度均 35; 属性值上限 10 (展示为属性条 `TextureProgressBar` max=10, 见 B4.2)
- 数值/文案唯一数据源: CONF `npcs/*.conf` + `src/ui/btn_recruit.gd` 的 `NPC_DATA` 字典 (S1 UI 层, S2 起迁 CONF)
- (旧"铁牛/老葛/苏晚/陈姨"四选一设定已作废, 被本表覆盖)

### A10. 野外资源 (搜刮节点) (原 SPEC J)

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
| 特殊 | lab_vault / bunker_sealed / radio_station / bank_vault | rare_alloy, story, electronics | 极大 | 一次性 |

节点数据结构:

```text
loot_node.<id>
  type / spawn_region[] / loot_table_ref (id_ref)
  amount_range (range) / search_time (minutes) / danger (enum)
  respawn_days / rarity / special_event (id_ref 可空)
```

### A11. 野外生物 (原 SPEC K)

#### A11.1 普通动物 (animal) (原 K1)

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

#### A11.2 感染动物 (enemy schema, wildlife 分组) (原 K2)

| ID | 名称 | 特点 | 掉落 |
|---|---|---|---|
| enemy.infected_dog | 感染犬 | 速度快 | steel, medicine |
| enemy.infected_boar | 感染野猪 | 高血量 | food, rare_alloy |
| enemy.infected_wolf | 感染狼 | 群体 | steel, medicine |
| enemy.mutated_deer | 变异鹿 | 高攻击 | rare_alloy |

#### A11.3 感染体/敌人 (enemy) (原 K3)

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

### A12. 探索系统 (原 SPEC L)

#### A12.1 探索循环 (原 L1)

```text
选择区域(map) → 选择地点(location) → 组队(survivor) + 负重上限
→ 时间推进(time) → 遭遇(enemy/animal/event) → 搜刮(loot) → 撤退/伤亡
→ 结算入仓(resource)
```

- **探索挂机等待** (用户定稿 2026-10, S2 实装): 世界界面"探索"按钮走**游戏等待逻辑** —
  派出后按游戏时钟计 `search_time` (locations/*.conf), 时间到自动结算资源入仓,
  无需玩家守着; 等待期间可自由切场景/挂机。S1 该按钮为占位 (B4)。

#### A12.2 配置驱动 (原 L2)

| 文件 | 驱动内容 |
|---|---|
| exploration.conf | 全局规则: 基础负重、时间系数、撤退规则、伤亡惩罚 |
| map/*.conf | 区域: 等级、风险、连接、解锁条件 |
| locations/*.conf | 地点: 搜索时间、危险、loot_table、事件表、刷新 |
| loot/*.conf | 掉落表: 条目、权重、数量范围、保底 |

#### A12.3 地点 schema 样例 (未来生成) (原 L3)

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

### A13. 事件系统 (原 SPEC M)

#### A13.1 事件总表 (首批 12 个, 全配置化) (原 M1)

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

#### A13.2 事件 schema (原 M2)

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

### A14. 任务 / 剧情 (原 SPEC N)

#### A14.1 任务体系 (quest) (原 N1)

- **UI 现状 (S1)**: 任务卷轴面板 TaskPanel 已落地 (B4.1), 列表/详情/接受/放弃为 UI 壳 +
  `task_panel.gd` 占位数组 (任务1~10), 接受状态随存档 `quest.accepted` 持久化;
  真任务链/目标/奖励逻辑待 quest 系统开启 (S3+)
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

#### A14.2 剧情体系 (story) (原 N2)

- 主线按章节 (chapter) 推进, 引用 quest 完成度
- 第一阶段无剧情系统; 剧情节点全部由 quest + event 引用驱动
- 结局分支数据挂 `story/*.conf`, 由 story 系统读取

### A15. 天气与灾害 (原 SPEC O2/O3)

#### A15.1 天气 (weather, 第 3 阶段) (原 O2)

| 天气 | 持续 | 影响 |
|---|---|---|
| clear 晴 | 随机 | 无 |
| rain 暴雨 | 半天 | 产能 -10%, 集水 +50%, 探索风险 + |
| snow 暴雪 | 半天 | 产能 -20%, morale-, 探索风险 ++ |
| fog 浓雾 | 数小时 | 探索风险 ++, 敌人警戒 - |
| heatwave 酷热 | 一天 | water 消耗 +30% |
| radiation 辐射尘 | 稀有 | 全图危险, 需 medicine |

天气通过 `weather/*.conf` 定义 modifiers, 各系统读取自己关心的修正键。

#### A15.2 灾害 (disaster, 第 3 阶段+) (原 O3)

尸潮 horde / 风暴 storm / 地震 earthquake / 变异潮 mutation_wave。
每个灾害: `warning_time → impact → defense 结算 → rewards/损失`, 引用 event 系统的 follow_up 机制。

---

## PART B. UI 加载与交互逻辑

### B1. 场景流与状态归属

```text
boot.tscn → login.tscn → main.tscn ⇄ shelter_interior.tscn
```

- **System 挂 /root 常驻** (如 /root/ShelterSystem), 状态跨场景存活; **场景 = 纯 UI 壳**
  (只读 System 状态渲染 + 转发玩家输入, 不持有玩法状态)
- 场景切换唯一入口 `get_tree().change_scene_to_file()`; 场景间零耦合 (互不引用)
- 读档/新游戏在登录场景完成状态重置后再切场景, 不在主场景做初始化

### B2. boot.tscn (启动)

1. autoload 就绪 (ConfigManager 最先 → TimeManager / SaveManager)
2. `ConfigManager.load_all()` 解析全部 CONF + 校验依赖;
   失败 `printerr("CONFIG ERROR: ...")` + `quit(1)` 终止, **不静默**
3. 按 `system.conf` 开关创建 System 挂 /root (禁用系统**零初始化**: 不建、不初始化、不写 UI)
4. `change_scene` → login.tscn

(配置加载完整生命周期 10 步见 D3)

### B3. login.tscn (登录/开始界面)

- 背景 `blank_login_1920x1080.png` + 半透明压暗层, 菜单垂直居中, 标题 "末日庇护所 / Apocalypse Shelter"
- 菜单 5 按钮 (360×64, ButtonSkin 真实图):

| 按钮 | 交互逻辑 |
|---|---|
| 继续游戏 | 直接读最近存档 (`find_latest_slot()`) 进主界面; 无存档则按钮禁用 |
| 新的游戏 | `ShelterSystem.new_game()` + `TimeManager.new_game()` → 主界面 (Lv1, 第 1 天 08:00) |
| 读取存档 | 弹 SlotPanel 弹层 (SlotButton_1~3 + SlotBackButton), 空槽禁用, 选槽读档进主界面 |
| 设置 | settings 开关门控 → SettingsOverlay (见 B6) |
| 退出游戏 | `get_tree().quit()` |

- 读档流程: `SaveManager.load_game(slot)` → 空/损坏提示不切换; 成功则
  `shelter.set_state()` + `TimeManager.set_state()` → 主界面

### B4. main.tscn (游戏主界面 = 世界界面)

布局 (**顶部资源条 + 底部功能按钮**, 用户定稿 2026-10; 升级不在本界面, 见 B5):

1. **顶部 HUD 通栏** (TopHud, 横贯全宽): 左侧资源条 ResourceBar — wood / steel / food / water
   四格 (节点 `ResourceItem_<id>` + `ResourceName_<id>` + `ResourceValue_<id>`),
   每格显示 **当前数/库存上限** (`200/200` 格式) — 纯 CONF 展示, 数据口径见 A6.4;
   其右 **人口面板 PopulationPanel** (`PopulationLabel`="人口: 当前/上限", 当前=shelter.conf
   `initial_population`, 上限=等级 `population_cap`, survivor 系统开启后接管) +
   **天气面板 WeatherPanel** (`WeatherLabel`="天气: X", 按游戏日轮换 晴/多云/小雨/雾 占位,
   天气系统未开纯 UI 壳); 右侧 **等级标签 LevelLabel (`LvN 名称`)** +
   **日夜图标 DayNightIcon** (6:00~18:00 `day_icon.png` / 其余 `night_icon.png`,
   48×48 随游戏时刻切换) + 游戏时间标签 (TimeManager.get_time_text()) + 设置按钮
2. **中央**: 底图 `assets/map/first_scene.png` (恒定世界图) + 庇护所图按等级换景
   (不放 UI, 等级变化一眼可见; 口径见下方"底图+庇护所图")
3. **底部一排 6 功能按钮** (BottomBar, 等分, 节点名 = 测试契约) + 其上提示行 StatusLabel:

| 按钮 | 节点名 | 功能 | 对应系统 (当前 system.conf 全 OFF) |
|---|---|---|---|
| 任务 | TaskButton | 游戏任务 (卷轴面板, 见 B4.1) | quest (UI 壳) |
| 仓库 | WarehouseButton | 游戏仓库 | resource (+building 容量) |
| 出城 | OutCityButton | 出城新地图 | map + location |
| 探索 | ExploreButton | 探索挂机 (见 A12.1) | exploration + loot |
| 招募 | Btn_Recruit | 招募 NPC (木板卡片面板, 见 B4.2) | npc + survivor (UI 壳) |
| 进入 | EnterShelterButton | 进入庇护所 → shelter_interior.tscn | shelter (已开) |

交互规则:

- **底图+庇护所图** (用户定稿: 进游戏第一屏不放庇护所图): 底图恒定 `assets/map/first_scene.png`
  (进游戏第一屏世界图, 缺图回退 blank_lv1), main.tscn 节点 MapBackground;
  庇护所图 `assets/shelter/shelter_level%d.png` 按当前等级取 — 位置/大小不在图里,
  在 main.tscn 节点 ShelterLayer 上 (**Godot 编辑器拖拽摆位**, 存 tscn 即定稿),
  缺文件回退 shelter_level1, 仍缺则隐藏 (`_shelter_overlay_texture()`)
  — 用户后续重新生成庇护所图覆盖同名文件即换图
- **任务**: 点击弹出**任务卷轴面板 TaskPanel** (见 B4.1; quest 系统 OFF, UI 壳+占位内容)
- **招募**: 点击开/关**招募面板** (木板卡片三选一, 见 B4.2; npc 系统 OFF, UI 壳+静态状态)
- **3 占位按钮** (仓库/出城/探索): S1 纯占位零逻辑, 点击 →
  StatusLabel 显示 `后续版本开放: X`; 各系统开启后逐个接管 (禁用系统零初始化, 不建系统对象)
- **进入**: change_scene → shelter_interior.tscn
- **升级只在庇护所室内** (B5), 世界界面不提供升级入口
- **存读档/返回标题**: 移入设置弹层游戏菜单段 (B6); main 只保留
  `level_changed` 监听刷新楼体图 + LevelLabel (读档/升级后刷新通道)

### B4.1 任务面板 (TaskPanel, 卷轴弹层)

用户定稿 2026-10: 任务不是占位提示, 点击**居中弹出发黄卷轴**面板 (典型任务面板):

- **卷轴底图**: `assets/blank_scroll_1400x900.png` (纯色发黄占位, 用户覆盖同名文件换真卷轴图,
  代码零改动; 节点 `ScrollBg`); Esc 或 `QuestCloseButton` 关闭
- **左列 `TaskList`** (ItemList): 任务列表, 暂列 **任务1~任务10 占位**;
  内容 = `src/ui/task_panel.gd` 的 `TASKS` 常量数组 (id=`quest.placeholder_01~10`),
  用户后续直接改该数组; S2 起迁移 CONF-D `quest/*.conf`
- **右列**: `TaskTitle` 标题 + `TaskDesc` 详情 (选中列表项即显示) +
  **`AcceptButton` 接受任务 / `AbandonButton` 放弃任务** + `TaskStatusLabel` 状态行
- **接受/放弃** (用户定稿: 状态+写入存档): 接受 → 列表项标记"(已接受)",
  状态存 TaskPanel 静态内存态 (跨场景保留, **不建 QuestSystem** — quest 开关 OFF 零初始化);
  放弃 → 清除标记; 新游戏 `TaskPanel.reset()`
- **持久化**: 存档快照加 `quest: {accepted: [id, ...]}` (SaveManager 无 schema 直存),
  保存/读档 (设置弹层 game_menu + 登录读档弹层) 时写入/恢复

### B4.2 招募面板 (BtnRecruit, 木板卡片三选一)

用户定稿 2026-10 (完整规格): 招募按钮 `Btn_Recruit` (挂 `src/ui/btn_recruit.gd`, class_name `BtnRecruit`)
点击开/关面板, **面板默认隐藏**; 面板常驻场景根 (`RecruitPanel` visible 开关, 不销毁):

- **遮罩**: 全屏半透明深色 `ColorRect` (`Mask`, 黑 α0.55), 点击遮罩关闭面板
- **弹窗容器**: 居中 `RecruitBox` (PanelContainer, **1400×700**, 深色圆角), 内含
  `CardRow` HBox 横排等距 3 张卡片
- **NPC 木板卡片** (`NpcCard_1~3`, PanelContainer **380×620**, 节点名 = 测试契约):
  1. 卡底 `BoardBg` = `assets/npc_recruit/board.png` 木板铺满 (STRETCH_SCALE)
  2. 顶部居中 `Diamond_N` 80×80 紫钻 `diamond_purple.png` (路径存字典, 可换钻色)
  3. `NpcName_N` 姓名 (大) + `NpcTitle_N` 职业 (中)
  4. `Familiarity_N` 熟悉度 (中)
  5. 属性条区 `AttrRow_N_i` 最多 3 条: 属性名 + `AttrBar_N_i` (`TextureProgressBar`
     **max=10 固定**, texture_under/texture_progress = bar_under/bar_fill.png 九宫格) + 数值
  6. `Desc_N` 背景描述 (小号多行 AUTOWRAP_WORD_SMART)
  7. `PassiveTitle_N`/`PassiveDesc_N` 被动技能 + `ActiveTitle_N`/`ActiveDesc_N` 主动技能
- **样式**: 全锚点容器布局 (CenterContainer/Margin/VBox, 不写死坐标); 文本深棕
  (BROWN_DARK #4A2F14 / BROWN_TEXT) 适配木板废土风
- **NPC 数据**: `btn_recruit.gd` 的 `NPC_DATA` 字典 = 唯一数据源 (姓名/职业/熟悉度/属性/
  背景/被动/主动/钻石路径), 改数值/换钻石/改文案只动字典; 三人数据见 A9.3
- **整卡点选 (开局 3 选 1)**: 规格卡片版式 ①~⑥ 封闭无选择按钮 → **点整卡选定**;
  已选卡加深棕描边 (StyleBoxFlat 3px 边框), 状态存 `BtnRecruit` 静态内存态
  (`_picked` 存姓名, 跨场景保留; **不建 NpcSystem** — npc 开关 OFF 零初始化);
  新游戏 `BtnRecruit.reset()`
- **持久化**: 存档快照加 `recruit: {picked: "<NPC姓名>"}`, 保存/读档 (设置弹层 game_menu
  + 登录读档弹层) 时写入/恢复

### B5. shelter_interior.tscn (庇护所内部)

- 背景 `blank_interior_1920x1080.png`; 全代码 UI 壳 (tscn 只放根节点)
- **一房一床极简** (用户定稿 2026-10, 其余房间/家具后续版本):
  - `RoomPanel_1` 卧室: 300×220 占位图 `blank_room_panel_512x512.png` + 房名 + `BedLabel`="床 ×1" + "已启用"
  - 原 2×3 五房 (卧室/储藏室/厨房/工作台/大门) 与 RoomSummary/`building_slots` 解锁展示**已移除**,
    待后续房间玩法版本恢复扩展
- **升级区** (自 main 迁入; 升级唯一入口): `UpgradeButton` (升级庇护所) +
  `CooldownLabel` (冷却倒计时) + `UpgradeStatusLabel` (状态文本) + LevelLabel
  - 点击 → `start_upgrade()` 成功则按钮禁用显示"升级中..." + 剩余秒数 (每帧刷新)
    → 冷却完成信号 → "升级完成: LvN 名称"; 满级或冷却中按钮禁用
  - S1 升级 = 30s 现实冷却 (ShelterSystem.TEMP_UPGRADE_COOLDOWN_REAL_SECONDS), S2 引入资源后废弃
- BackButton → 返回主界面

### B6. 设置面板 (SettingsOverlay, 弹层)

- 全屏开关 + 主音量滑条; **修改即生效即写 `user://settings.json`** (与游戏存档分离)
- 登录/主界面两个入口; Esc 或关闭按钮退出; 重开游戏保留上次设置
- **游戏菜单段** (`open(parent, game_menu=true)`, 仅主界面入口带):
  `SlotOption` 3 存档槽 + `SaveButton` 保存进度 + `LoadButton` 读取进度
  (快照 `{shelter, time, quest, recruit}` → SaveManager, 读档 set_state + TaskPanel.set_accepted
  + BtnRecruit.set_picked 后刷新) +
  `MenuStatusLabel` 结果文本 + `BackToTitleButton` 返回标题 (→ login.tscn);
  登录入口 `open(parent)` 不带该段

### B7. UI 资源加载约定 (缺图不崩溃)

- **占位图 (用户定稿)**: 缺图处放 `blank_XX_宽x高.png` 纯色占位 (背景类 1920×1080,
  面板类 512×512), 用户后续**直接覆盖同名文件**填实际 UI, 代码零改动。
  现有: blank_login / blank_lv1~lv3 / blank_interior _1920x1080.png + blank_room_panel_512x512.png
  + blank_scroll_1400x900.png (任务卷轴, 发黄纯色)
- **招募面板素材** (非 blank 命名, 同样覆盖即换图): `assets/npc_recruit/`
  board.png (380×620 木板棕) / diamond_purple.png (80×80 紫钻) /
  bar_under.png + bar_fill.png (16×16 属性条底/填充, 九宫格)
- **HUD 图标** (同覆盖即换图): `assets/hud/` day_icon.png (64×64 太阳) /
  night_icon.png (64×64 弯月) — 顶部日夜图标用
- **地图图 (用户定稿)**: `assets/map/first_scene.png` = 进游戏第一屏恒定世界底图 (2848×1600);
  `assets/shelter/shelter_level%d.png` = 庇护所图 (2304×1728, 按等级 1~12 命名),
  位置/大小不在图里, 在 main.tscn 的 MapBackground / ShelterLayer 两个实体 TextureRect 节点上
  (Godot 编辑器拖拽摆位, 节点名字固定, 代码只换 texture);
  缺文件回退 shelter_level1, 仍缺则隐藏 — 用户重新生成覆盖同名文件即换图
- **按钮例外**: 用真实图 `assets/ui/btn_primary.png` (+_hover/_pressed), 9-slice
  由 ButtonSkin 统一应用, 不放 blank
- 图标按 `config_id` 拼路径找 `assets/ui/icons/ui_icon_<entity_type>_<name>.svg`,
  找不到用 placeholder, **不崩溃** (命名规范见 AGENTS.md §13.2)
- 音频: 找不到文件静默跳过; 播放极简 (`AudioStreamPlayer` 一次性, 不排队不打断)
- 新增图片/音频资源后必须先 `godot --headless --import`, 否则加载失败

---

## PART C. 系统体系与依赖

### C1. CORE 恒开模块 (引擎最小内核)

| 模块 | ID | 职责 |
|---|---|---|
| 核心循环 | core | 主循环、tick、系统注册表、模块生命周期 |
| 配置系统 | config | ConfigManager: 加载/校验/缓存全部 CONF |
| 存档系统 | save | 序列化 GameState, 版本迁移 |
| 时间系统 | time | 游戏时钟、昼夜、定时器、生产结算 |
| UI 框架 | ui | HUD/面板框架, 按开关挂载系统 UI |

### C2. 可开关功能系统

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

> 注: 此为系统设计全集; 各阶段实际开关以 configs/system.conf 为准 (Dev-S1 仅 shelter + settings 开启, 阶段划分见 AGENTS.md)。

### C3. 系统依赖图

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

### C4. 依赖规则

1. 依赖写在 `system.conf [dependencies]`, ConfigManager 启动时校验。
2. `A = B, C` 表示启用 A 时 B 与 C 必须同为 true。
3. 违例时输出 `MissingDependency` 错误并**终止启动**, 禁止悄悄运行。
4. 依赖仅声明"直接依赖"; 传递依赖由校验器递归展开验证。

---

## PART D. 配置体系 (CONF)

### D1. 大 CONF 设计

#### D1.1. 职责边界 (原 D1)

大 CONF = `configs/system.conf`, **唯一**一个。只允许包含:

- `[meta]` 配置版本
- `[profile]` 开发阶段预设
- `[system]` 系统级开关 (布尔)
- `[dependencies]` 依赖声明
- `[engine]` 启动级硬性参数 (时间倍率、存档槽数量等)

**禁止**出现建筑/资源/事件等具体内容数值 — 那是小 CONF 的职责。

#### D1.2. PROFILE 预设 (原 D2)

| profile | 含义 | 默认开关组合 |
|---|---|---|
| prototype | 原型验证 | resource + shelter + building |
| vertical_slice | 垂直切片 | + population, survivor, map, location, loot, exploration, item, event |
| development | 开发联调 | vertical_slice + combat, enemy, equipment, weather, quest |
| full_game | 正式全量 | 全部业务系统 ON (steam/achievement 依发行需要) |
| debug | 调试 | prototype + 任意手开, 开启 `allow_debug_fallback` |
| test | 自动化测试 | 按用例显式指定 |

规则: **预设仅提供默认值, 最终以 `[system]` 中显式写出的开关为准** (显式覆盖预设)。

#### D1.3. 开关语义 (原 D3)

| 值 | 行为 |
|---|---|
| true | 启动时初始化该系统, 加载其小 CONF 目录, 挂载 UI |
| false | **完全不初始化**: 不建 Manager、不加载数据、不挂 UI。小 CONF 文件允许存在 ("内容存在, 功能关闭") |

#### D1.4. 启用系统后的自动加载 (原 D4)

开启新系统**不需要改核心代码**:

```text
改 system.conf: survivor = true, population = true
→ 重启游戏
→ ConfigManager 校验依赖
→ 自动加载 configs/survivors/*.conf, configs/population/*
→ SystemRegistry 自动实例化 SurvivorSystem / PopulationSystem
```

前提: 该系统的 System 类已在注册表登记 (一次性)。新增系统 = 新增 1 个 System 类 + 注册 + 目录, 不触碰核心循环。

#### D1.5. 实际文件 (原 D5)

完整真实数据见 `configs/system.conf` (第一阶段: `resource/shelter/building = true`, 其余 false, `profile = prototype`)。

### D2. 小 CONF 设计规范 (CONF-D v2)

#### D2.1. 设计目标 (原 E1)

- 人类可读可编辑, diff 友好
- Godot 4 `ConfigFile` 可直接解析 (分层 INI 语义)
- 类型明确、引用可校验、可扩展、可版本化
- **新增 100 个建筑/事件/NPC = 新增 CONF 文件, 不改代码**

#### D2.2. 通用格式 (原 E2)

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

#### D2.3. 类型系统 (原 E3)

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

#### D2.4. ID 命名规范 (原 E4)

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

#### D2.5. 层级块 Level Block (原 E5)

建筑/庇护所/敌人成长使用 `[level.N]`:

- `level.N.upgrade_cost_*` = **升到本级**的花费 (level.1 即建造花费)
- 生产/消耗/容量 = 本级生效值 (全量值, 非增量)
- 视觉切换由 `visual_stage` 映射 Godot Scene 内状态, CONF 不写节点树

#### D2.6. 通用字段集 (原 E6)

```text
id / name / description / category / tags
unlock_condition(如 unlock_shelter_level) / requirements / dependencies
level / max_level / cost / production / consumption / capacity
rewards / loot / risk / time / visual / audio
```

每个 schema 明确规定哪些字段必填, 由 ConfigManager 按 schema 校验 (MissingData / InvalidValue)。

#### D2.7. schema 清单 (原 E7)

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

#### D2.8. 版本与迁移 (原 E8)

- 每个文件 `[meta] config_version = N`
- ConfigManager 检测版本; 低版本经 `migrations/` 迁移链升级
- 主版本不一致 → ConfigError, 不静默猜测

#### D2.9. 配置错误处理 (原 E9)

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

#### D2.10. 默认值原则 (原 E10)

- 非必填字段缺失 → 用 schema 默认值, 记 ConfigWarning, **不崩溃**
- 核心字段缺失 (id / name / level 数值 / system.conf 的 time 倍率) → ConfigError

### D3. 配置加载生命周期 (原 PART T)

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
   e. id_ref 解析 (InvalidID) — 含跨系统引用检查 (本文 E2 (原 P2))
   f. 版本检查/迁移 (config_version)
   g. 写入内存缓存 (只读)
7. CoreSystem 初始化 → 按开关实例化 System (禁用系统零初始化)
8. 加载/创建 GameState
9. 进入 Main Scene (UI 按开关挂载)
10. 运行期: 系统只读缓存查询 CONF, 不再解析文件
```

失败策略: 任一 ConfigError → 打印完整错误清单 → 终止启动 (除非 `allow_debug_fallback = true` 的 debug profile)。

---

## PART E. 数据关系与目录

### E1. 引用关系矩阵 (原 P1)

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

### E2. 引用完整性规则 (原 P2)

1. 所有 id_ref 在 ConfigManager 加载期解析; 引用的实体**所属系统已开启**却解析失败 → InvalidID (终止)
2. 休眠引用 (dormant ref): 被引用实体所属系统为 OFF 时, 引用保留但不阻断启动,
   记 ConfigWarning `dormant ref`; 当目标系统未来开启时, 在其加载期强制校验该引用
   (届时解析失败 = InvalidID)。这允许"内容存在, 功能关闭"以及提前书写解锁表
3. 运行期实体: `config_id` (引用 CONF) + `instance_id` (存档身份)

示例: 第一阶段 `shelter_levels.conf` 中 `unlocks_locations = [location.suburb_edge]`,
location 系统为 OFF → dormant ref 告警; 第二阶段 `location = true` 时,
若 `locations/` 下仍无 `location.suburb_edge` → ConfigError 终止。

### E3. GameState (存档) 与 CONF 的边界 (原 P3)

| CONF (设计态, 随版本更新) | GameState (运行态, 存档保存) |
|---|---|
| 建筑定义/等级表 | 建筑实例: config_id + instance_id + current_level + 工作状态 |
| 资源定义 | 资源数量、容量 |
| 庇护所等级表 | 当前 shelter_level |
| 事件定义 | 事件冷却计时、已触发标记 |
| 时间规则 | 当前游戏时刻/天数 |

存档保存的是"配置驱动出来的运行状态"; 读档时用 config_id 回查 CONF, 缺失则 ConfigWarning + 按默认处理。

### E4. 目录结构

#### E4.1. 最终目录 (原 Q1)

```text
game/
├── docs/
│   └── game_logic.md            # 游戏逻辑书 (整合版, 唯一逻辑依据)
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

#### E4.2. 当前仓库已生成 (原 Q2)

```text
configs/
├── system.conf
├── resources/  resource.conf, wood.conf, steel.conf, food.conf, water.conf, power.conf
├── shelter/    shelter.conf, shelter_levels.conf
└── buildings/  buildings.conf, generator.conf, warehouse.conf, lumber_yard.conf,
                water_collector.conf, farm.conf, salvage_workshop.conf
```

---

## PART F. 验收与路线

### F1. 第一阶段 3 系统 MVP (原 PART R)

> 注: 本节是架构验收口径 (3 系统 MVP); Dev 阶段的实际系统划分与出口标准以 AGENTS.md 为准。

#### F1.1. 开关 (原 R1)

```ini
resource = true
shelter = true
building = true
其余全部 = false
profile = prototype
```

#### F1.2. 必须实现的程序模块 (原 R2)

| 模块 | 职责 | 对应 CONF |
|---|---|---|
| ConfigManager | 读 system.conf→校验依赖→按开关加载小 CONF→缓存→查询接口 | 全部 |
| CoreSystem | 启动流程、tick、SystemRegistry | system.conf [engine] |
| ResourceSystem | 资源池、容量、产消结算、upkeep | resources/* |
| ShelterSystem | 等级、槽位、解锁、基础收入、升级校验 | shelter/* |
| BuildingSystem | 实例化、建造/升级、产消挂载、依赖校验 | buildings/* |
| SaveSystem | GameState 序列化/反序列化、版本 | — |
| TimeManager | 游戏时钟、小时 tick | system.conf [engine] |

#### F1.3. ConfigManager 查询接口 (最小集) (原 R3)

```gdscript
ConfigManager.is_enabled("resource")            -> bool
ConfigManager.get_resource("resource.wood")     -> Dictionary
ConfigManager.get_shelter_level(3)              -> Dictionary
ConfigManager.get_building("building.generator")-> Dictionary
ConfigManager.get_building_level("building.generator", 2) -> Dictionary
ConfigManager.get_initial_state()               -> Dictionary
ConfigManager.validate_building_cost(id, level) -> bool
```

#### F1.4. PLAYABLE CORE 验收流程 (原 R4)

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

#### F1.5. 交付物 (原 R5)

- 游戏逻辑书 `docs/game_logic.md` (本文)
- `configs/` 全部 MVP 真实数据 (system + 5 资源 + 庇护所 Lv1-3 + 6 建筑×5 级)

### F2. 第二阶段开放顺序 (原 PART S)

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

### F3. 最终完整检查 (20 项) (原 §47)

| # | 检查项 | 结论 |
|---|---|---|
| 1 | 所有系统都有开关? | ✔ 35 个业务系统均在 system.conf [system]; CORE 5 模块恒开并已声明 |
| 2 | 系统依赖完整? | ✔ [dependencies] + 本文 C3/C4 递归可验证 |
| 3 | 大/小 CONF 职责清晰? | ✔ 大 CONF 仅开关/依赖/profile/引擎参数; 数值全在小 CONF |
| 4 | 禁用系统真正不初始化? | ✔ 开关=false → 零初始化、不加载、不挂 UI |
| 5 | 开启后自动加载? | ✔ 重启后 ConfigManager 按 registry 自动加载, 不改核心代码 |
| 6 | 数据唯一 ID? | ✔ `<type>.<name>` 规范 + DuplicateID 校验 |
| 7 | 建筑引用资源? | ✔ produce_*/consume_*/upgrade_cost_* ↔ resource.*; InvalidID 校验 |
| 8 | 建筑引用庇护所等级? | ✔ unlock_shelter_level + shelter_levels.requirements_buildings |
| 9 | 探索引用地点? | ✔ exploration → location (依赖图 + 本文 E1) |
| 10 | 地点引用 Loot? | ✔ location.loot_table → loot_table (本文 E1) |
| 11 | Enemy 引用 Drop? | ✔ enemy.drop_table → loot_table (本文 E1) |
| 12 | Event 引用 Reward? | ✔ event result 奖励字段 + follow_up (本文 E1) |
| 13 | Quest 引用 Event? | ✔ quest objective/reward 可含 event id_ref (本文 E1) |
| 14 | Save 保存配置驱动状态? | ✔ config_id + instance_id 模型 (本文 E3) |
| 15 | 第一阶段三系统闭环? | ✔ 本文 A6 经济闭环验证: 5 资源产销+升级链+存读档 (本文 F1.4) |
| 16 | 增系统需改核心代码? | ✔ 不需要; 仅新增 System 类+注册+CONF 目录 |
| 17 | +100 建筑只加 CONF? | ✔ 新增 buildings/xxx.conf + registry 一行 |
| 18 | +100 事件只加 CONF? | ✔ 新增 events/xxx.conf (含 registry 登记) |
| 19 | +新 NPC 只加 CONF? | ✔ 新增 npcs/xxx.conf + registry 一行 |
| 20 | 是否存在"加数据必须改核心代码"? | ✔ 无。唯一硬点=新 schema 种类(如新增实体类型)需定义 schema+System, 属于"新系统"而非"新数据" |

复核发现并已修正的点:
- 依赖声明: 原设计仅文档化, 已落入 system.conf `[dependencies]` 由程序校验
- 引用完整性: 已补充 dormant ref 规则 (本文 E2): 未开启系统的引用休眠告警, 开启时强制校验; 已开启系统的悬空引用一律终止
- 版本迁移: 已补充 `migrations/` 目录与迁移策略 (本文 D2.8)
- MVP 经济: 补充 power 流转资源, 使 building 产消闭环无死资源

### FREEZE

```text
SYSTEM DESIGN FREEZE
CONFIGURATION SPEC FREEZE
MVP CORE FREEZE
```
