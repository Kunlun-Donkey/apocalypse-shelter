---
name: test
description: 运行末日庇护所 (Godot) 项目的 headless 回归测试四件套。当用户说"跑测试/回归/验证/test"或改动 src/、configs/ 后需要验证时使用。
---

# Dev-S1 headless 回归测试

Godot 4.7.2 二进制 (按平台选, 下文用 `$GODOT` 代称):
- Linux: `/home/xiaomi/p-luojialei/Desktop/godot/Godot_v4.7.2-stable_linux.x86_64`
- Windows: Godot_v4.7.2-stable_win64.exe 的实际路径 (标准版, 版本号必须 4.7.2)

工程根 = 仓库根 (project.godot 所在目录), 所有命令在该目录执行。
bash 用法示例: `GODOT=/home/xiaomi/p-luojialei/Desktop/godot/Godot_v4.7.2-stable_linux.x86_64` 赋值后, 以下命令原样可用; Windows 端把 $GODOT 换成 exe 全路径。

## 前置

若本轮新增/修改过 class_name 或图片/音频资源, 先导入:

```bash
$GODOT --headless --import
```

## 测试四件套 (可并行跑)

```bash
# 49 项: 配置/等级链/升级冷却/存读档/npc 招募入队+被动查询/零初始化 (含 2×30s 冷却, 整体 ~80s)
$GODOT --headless --path . res://tests/dev_s1_autotest.tscn

# 15 项: 登录→Main 跳转 + 顶部资源条/人口/天气/日夜图标, 新游戏重置 Lv1 第1天 08:00
$GODOT --headless --path . res://tests/dev_s1_navtest.tscn

# 11 项: 设置面板 (弹出/全屏/音量持久化/Esc 关闭)
$GODOT --headless --path . res://tests/dev_s1_settest.tscn

# 94 项: 世界界面 6 按钮/招募面板(木板卡片三选一+每卡招募按钮/成功弹窗+NpcSystem 招募契约)/任务卷轴面板(列表/接受/放弃)/进入室内 (一房一床+升级冷却+室内同伴名牌(CompanionSlot+详情面板))/返回/设置游戏菜单 (存读档 round-trip)
$GODOT --headless --path . res://tests/dev_s1_inttest.tscn
```

## 判定与收尾

- 每套以 `XXXTEST: ALL PASSED` / `DEV-S1 AUTOTEST: ALL PASSED` 结尾且退出码 0 为通过; 任一 `FAIL` 即失败
- 输出过滤: `2>&1 | grep -E "PASS|FAIL|TEST|ERROR"` (注意别用管道吞退出码)
- settest 会临时改 `user://settings.json` 音量并在结束时还原 80%, 失败中断时可手动还原
- 全部通过后向用户汇报各项数量与结论; 不要自动 commit/push (用户习惯: 明确说了才提交)
