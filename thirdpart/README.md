# thirdpart — 第三方免费音频资源包

> 用途: 《末日庇护所》开发期音效选材库。**只作选材参考, 不直接打包进最终游戏**;
> 选用后按 AGENTS.md §13.6 规范 (格式/响度/命名) 导出到 `assets/audio/` 对应目录。
> 拉取日期: 2026-09-29 (经 GitHub codeload 获取, 原站点 kenney.nl / freesound 在本网络不可达)。

## 资源包清单

| 目录 | 来源仓库 | 许可 | 规模 | 说明 |
|---|---|---|---|---|
| `open-game-sfx-index/` | [Mcamento8/open-game-sfx-index](https://github.com/Mcamento8/open-game-sfx-index) | **音频 CC0 1.0** (公共领域, 商用免署名); 索引/脚本代码 MIT | 76 MB, 18 分类, 1451 文件 (752 ogg / 662 wav / 37 flac) | 索引式音效库, 含 ATTRIBUTION.md / SOURCES.md |
| `kenney-ui-audio/` | [Calinou/kenney-ui-audio](https://github.com/Calinou/kenney-ui-audio) | **CC0 1.0** (Kenney 素材) | 2.5 MB | Godot addon 形式 (`addons/kenney_ui_audio/`), UI 音效 |
| `kenney-digital-audio/` | [Boyquotes/kenney-digital-audio-for-godot](https://github.com/Boyquotes/kenney-digital-audio-for-godot) | **CC0 1.0** | 640 KB | Godot addon, 数字/电子音效 |
| `kenney-rpg-audio/` | [Boyquotes/kenney-rpg-audio-for-godot](https://github.com/Boyquotes/kenney-rpg-audio-for-godot) | **CC0 1.0** | 872 KB | Godot addon, RPG 音效 |

许可合规性: 全部 **CC0 1.0** = 公共领域, **可商用、免署名、可二次修改**。
CC0 不强制鸣谢, 但建议保留各包内 LICENSE / ATTRIBUTION.md 原文件以备溯源。

## 分类用途映射 (open-game-sfx-index/audio/)

| 分类目录 | 文件数 | 本项目用途 |
|---|---|---|
| `interface-sounds/` | 100 | **按键音候选** — 替代/补充 `sfx_ui_click` |
| `ui-audio/` | 51 | UI 交互音 (悬停/选中/翻页) |
| `sci-fi-sounds/` | 73 | **科幻 UI / 系统反馈** — 契合"庇护所核心"AI 系统音场景 |
| `impact-sounds/` | 130 | 建造/撞击/坠落 |
| `music-jingles/` | 85 | 过场短音乐 (升级完成/里程碑) |
| `oga-zombies/` | 24 | 末世氛围 (灾变潮/危险) |
| `oga-levelup-powerup/` | 13 | 升级/强化反馈 |
| `voiceover-pack/` | 92 | 备用英文人声 (正式 VO 用 MiMo TTS, 此处仅应急) |
| `oga-battle/` `oga-hits-punches/` `oga-footsteps/` | — | 战斗/脚步 (后续扩展) |
| `casino-audio/` `oga-512-retro/` `oga-gui-lokif/` `oga-rpg-pack/` `voiceover-pack-fighter/` `rpg-audio/` `digital-audio/` | — | 备选风格库 |

## 与 AGENTS.md §13.7 音频清单的对应

| §13.7 目标文件 | 取材建议 |
|---|---|
| `sfx_ui_click.wav` | `open-game-sfx-index/interface-sounds/` 或 `kenney-ui-audio/` (现有 ffmpeg 合成版可替换/对照) |
| `sfx_ui_error.wav` | `interface-sounds/` 中低频嗡鸣类 / `sci-fi-sounds/` 警示类 |
| `sfx_upgrade_start.wav` | `sci-fi-sounds/` 扫频/充能类 |
| `sfx_upgrade_complete.wav` | `music-jingles/` 或 `oga-levelup-powerup/` |
| `sfx_save.wav` / `sfx_load.wav` | `ui-audio/` 确认音 / `sci-fi-sounds/` 数据写入类 |
| `bgm_shelter_main.ogg` | `music-jingles/` 仅短曲; 正式 BGM 需另找 CC0 长曲或定制 |
| `amb_shelter_wind.ogg` | 本包无专门环境音, 需另找 CC0 ambience 或合成 |

## 使用注意

1. 选材导出时必须按 §13.6 转规格 (SFX=WAV <1s 关 Loop, BGM/amb=OGG 开 Loop), 统一峰值 -6dB。
2. 命名统一 `sfx_<category>_<action>.wav`, 不沿用素材原始文件名。
3. Kenney 三包是 Godot addon 结构, 引用时拷贝其中音频文件即可, 不必装 addon。
