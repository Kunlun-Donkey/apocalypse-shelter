# windows_log — Windows 端运行日志归档

本目录存放 Windows 开发机上的 Godot 运行/验证日志 (2026-10, 会话记录)。

| 文件 | 内容 |
|---|---|
| _imp2_log.txt / _imp2_err.txt | `godot --headless --import` 全局类扫描日志 (stdout/stderr) |
| _imp2head.txt | 上述导入日志的尾部摘要 (各阶段 DONE 状态) |
| _final.txt | 全局类注册表验证: 36 条注册项, 0 坏路径 |
| _clsdiff.txt | 全项目 .gd 的 class_name 声明清单 (36 个, 含所在文件) |
| _clsdiff2.txt | class_name 声明 vs global_script_class_cache.cfg 注册表比对 (36/36 一致) |
| _cls.txt | global_script_class_cache.cfg 注册表快照 |
| _gamelog.txt / _gamelog_err.txt | 游戏运行日志 (若存在; BOOT OK 验证) |

结论: class_name 全局类注册 36/36 全部生效, 游戏 BOOT OK 无错误。
