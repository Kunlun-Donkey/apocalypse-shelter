---
name: test
description: 运行末日庇护所 (Godot) 项目的 headless 回归测试三件套。当用户说"跑测试/回归/验证/test"或改动 src/、configs/ 后需要验证时使用。
---

# Dev-S1 headless 回归测试

Godot 二进制: `/home/xiaomi/p-luojialei/Desktop/godot/Godot_v4.7.2-stable_linux.x86_64`
工程根: `/home/xiaomi/p-luojialei/Desktop/game` (所有命令在该目录执行)

## 前置

若本轮新增/修改过 class_name 或图片/音频资源, 先导入:

```bash
/home/xiaomi/p-luojialei/Desktop/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --import
```

## 测试三件套 (可并行跑)

```bash
# 23 项: 配置/等级链/升级冷却/存读档/零初始化 (含 2×30s 冷却, 整体 ~70s)
/home/xiaomi/p-luojialei/Desktop/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . res://tests/dev_s1_autotest.tscn

# 5 项: 登录→Main 跳转, 新游戏重置 Lv1 第1天 08:00
/home/xiaomi/p-luojialei/Desktop/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . res://tests/dev_s1_navtest.tscn

# 11 项: 设置面板 (弹出/全屏/音量持久化/Esc 关闭)
/home/xiaomi/p-luojialei/Desktop/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . res://tests/dev_s1_settest.tscn
```

## 判定与收尾

- 每套以 `XXXTEST: ALL PASSED` / `DEV-S1 AUTOTEST: ALL PASSED` 结尾且退出码 0 为通过; 任一 `FAIL` 即失败
- 输出过滤: `2>&1 | grep -E "PASS|FAIL|TEST|ERROR"` (注意别用管道吞退出码)
- settest 会临时改 `user://settings.json` 音量并在结束时还原 80%, 失败中断时可手动还原
- 全部通过后向用户汇报各项数量与结论; 不要自动 commit/push (用户习惯: 明确说了才提交)
