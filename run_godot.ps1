# ============================================================
# run_godot.ps1 — 一键: 重新导入资源 + 启动游戏 (Godot 4.7.2)
# 用法 (PowerShell):
#   .\run_godot.ps1           只启动游戏
#   .\run_godot.ps1 -Import   先重新导入资源, 再启动游戏 (换图/加资源后用)
# 等价手工命令 (记录备查, 不用再找了):
#   导入: H:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --path H:\godot_game\apocalypse-shelter --headless --import --quit
#   运行: H:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe --path H:\godot_game\apocalypse-shelter
# ============================================================
param([switch]$Import)

$Project   = 'H:\godot_game\apocalypse-shelter'
$EngineDir = 'H:\Godot_v4.7.2-stable_win64.exe'
$Console   = "$EngineDir\Godot_v4.7.2-stable_win64_console.exe"
$Game      = "$EngineDir\Godot_v4.7.2-stable_win64.exe"

# 先关掉已有 Godot 进程, 避免多开/占用
Stop-Process -Name 'Godot*' -Force -ErrorAction SilentlyContinue

if ($Import) {
    Write-Host '== 重新导入资源 (headless --import) =='
    & $Console --path $Project --headless --import --quit
    Write-Host '== 导入完成 =='
}

Start-Process -FilePath $Game -ArgumentList '--path', $Project
Write-Host "游戏已启动: $Game --path $Project"