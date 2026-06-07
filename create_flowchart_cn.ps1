# ============================================================
# 系统工作流程图 - Visio COM 自动制图 (中文版)
# ============================================================
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  系统工作流程图 - Visio 自动制图 (中文版)" -ForegroundColor Cyan
Write-Host "========================================"

# 清理残留 Visio 进程
Write-Host "[清理] 终止残留 Visio 进程..." -ForegroundColor Yellow
Get-Process VISIO -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 4
Write-Host "[清理] 完成" -ForegroundColor Green

# 启动 Visio（隐藏模式）
Write-Host "[1] 启动 Visio（隐藏模式）..." -ForegroundColor Yellow
$visio = New-Object -ComObject Visio.Application
$visio.Visible = $false
$visio.ShowChanges = $false
$visio.AlertResponse = 1
Start-Sleep -Seconds 3
Write-Host "[1] Visio 已启动" -ForegroundColor Green

# 创建文档
Write-Host "[2] 创建文档并加载模具..." -ForegroundColor Yellow
$doc = $visio.Documents.Add("")
$page = $visio.ActivePage
$page.Name = "系统工作流程图"
$page.PageSheet.CellsU("PageWidth").ResultIU  = 12.0
$page.PageSheet.CellsU("PageHeight").ResultIU = 16.0

$stencilPath = "C:\Program Files\Microsoft Office\root\Office16\Visio Content\2052\BASFLO_M.VSSX"
$stencil = $visio.Documents.OpenEx($stencilPath, 64)
Start-Sleep -Seconds 3
Write-Host "[2] 模具已加载，母版数: $($stencil.Masters.Count)" -ForegroundColor Green

# 获取母版
Write-Host "[3] 获取母版形状..." -ForegroundColor Yellow
$mProcess   = $stencil.Masters.ItemU("Process")
$mDecision  = $stencil.Masters.ItemU("Decision")
$mStartEnd  = $stencil.Masters.ItemU("Start/End")
$mConnector = $stencil.Masters.ItemU("Dynamic connector")
Write-Host "[3] 4 个母版已就绪" -ForegroundColor Green

# 辅助函数
function StyleShape($sh, $fr, $fg, $fb, $lr, $lg, $lb, $lw) {
    $sh.CellsU("FillForegnd").FormulaU = "RGB($fr,$fg,$fb)"
    $sh.CellsU("FillBkgnd").FormulaU   = "RGB($fr,$fg,$fb)"
    $sh.CellsU("FillPattern").FormulaU = "1"
    $sh.CellsU("LineColor").FormulaU   = "RGB($lr,$lg,$lb)"
    $sh.CellsU("LineWeight").FormulaU  = "${lw} pt"
}

function ShapeFont($sh, $fs, $cr, $cg, $cb) {
    try { $sh.CellsU("Char.Size").FormulaU = "${fs} pt"; $sh.CellsU("Char.Color").FormulaU = "RGB($cr,$cg,$cb)" } catch {}
}

# ============================================================
# 创建所有形状（中文标签）
# ============================================================
Write-Host "[4] 创建形状（中文标签）..." -ForegroundColor Yellow
$CX = 6.0

# ---- 第1行：开始 ----
Write-Host "  形状 [1/16] 开始..."
$sh1 = $page.Drop($mStartEnd, $CX, 0.65)
$sh1.CellsU("Width").ResultIU = 1.60; $sh1.CellsU("Height").ResultIU = 0.45
$sh1.CellsU("PinX").ResultIU = $CX; $sh1.CellsU("PinY").ResultIU = 0.65
$sh1.Text = "系统上电 / 复位"
StyleShape $sh1 67 160 71 46 125 50 2.0
ShapeFont $sh1 11 255 255 255
Write-Host "  形状 [1/16] 完成" -ForegroundColor Gray

# ---- 第2行：model1 时钟分频 ----
Write-Host "  形状 [2/16] model1..."
$sh2 = $page.Drop($mProcess, $CX, 1.80)
$sh2.CellsU("Width").ResultIU = 2.80; $sh2.CellsU("Height").ResultIU = 0.60
$sh2.CellsU("PinX").ResultIU = $CX; $sh2.CellsU("PinY").ResultIU = 1.80
$sh2.Text = "model1 时钟分频~产生各模块所需时钟"
StyleShape $sh2 187 222 251 21 101 192 1.8
ShapeFont $sh2 10 13 71 161
Write-Host "  形状 [2/16] 完成" -ForegroundColor Gray

# ---- 第3行：model6 IDLE ----
Write-Host "  形状 [3/16] model6 IDLE..."
$sh3 = $page.Drop($mProcess, $CX, 3.00)
$sh3.CellsU("Width").ResultIU = 2.80; $sh3.CellsU("Height").ResultIU = 0.60
$sh3.CellsU("PinX").ResultIU = $CX; $sh3.CellsU("PinY").ResultIU = 3.00
$sh3.Text = "model6 状态机 → IDLE~等待玩家按下开始键"
StyleShape $sh3 225 190 231 106 27 154 1.8
ShapeFont $sh3 10 74 20 140
Write-Host "  形状 [3/16] 完成" -ForegroundColor Gray

# ---- 第4行：判定 start? ----
Write-Host "  形状 [4/16] 判定 start?..."
$sh4 = $page.Drop($mDecision, $CX, 4.20)
$sh4.CellsU("Width").ResultIU = 1.60; $sh4.CellsU("Height").ResultIU = 0.70
$sh4.CellsU("PinX").ResultIU = $CX; $sh4.CellsU("PinY").ResultIU = 4.20
$sh4.Text = "start?~玩家按下开始?"
StyleShape $sh4 255 249 196 249 168 37 1.8
ShapeFont $sh4 10 230 81 0
Write-Host "  形状 [4/16] 完成" -ForegroundColor Gray

# ---- 第5行：GAMING ----
Write-Host "  形状 [5/16] GAMING..."
$sh5 = $page.Drop($mProcess, $CX, 5.55)
$sh5.CellsU("Width").ResultIU = 2.80; $sh5.CellsU("Height").ResultIU = 0.60
$sh5.CellsU("PinX").ResultIU = $CX; $sh5.CellsU("PinY").ResultIU = 5.55
$sh5.Text = "状态机 → GAMING~开始游戏循环"
StyleShape $sh5 200 230 201 56 142 60 2.0
ShapeFont $sh5 10 27 94 32
Write-Host "  形状 [5/16] 完成" -ForegroundColor Gray

# ---- 第6行：计分器清零 ----
Write-Host "  形状 [6/16] 计分器清零..."
$sh6 = $page.Drop($mProcess, $CX, 6.70)
$sh6.CellsU("Width").ResultIU = 2.80; $sh6.CellsU("Height").ResultIU = 0.60
$sh6.CellsU("PinX").ResultIU = $CX; $sh6.CellsU("PinY").ResultIU = 6.70
$sh6.Text = "model7 计分器清零"
StyleShape $sh6 178 223 219 0 105 92 1.8
ShapeFont $sh6 10 0 77 64
Write-Host "  形状 [6/16] 完成" -ForegroundColor Gray

# ---- 游戏循环体内部 ----
$ly1 = 8.30; $ly2 = 9.60; $ly3 = 10.80

Write-Host "  形状 [7/16] model2..."
$g1 = $page.Drop($mProcess, 2.00, $ly1)
$g1.CellsU("Width").ResultIU = 1.80; $g1.CellsU("Height").ResultIU = 0.55
$g1.CellsU("PinX").ResultIU = 2.00; $g1.CellsU("PinY").ResultIU = $ly1
$g1.Text = "model2~生成随机障碍列"
StyleShape $g1 200 230 201 46 125 50 1.6
ShapeFont $g1 9 27 94 32

Write-Host "  形状 [8/16] model4..."
$g2 = $page.Drop($mProcess, 4.20, $ly1)
$g2.CellsU("Width").ResultIU = 1.80; $g2.CellsU("Height").ResultIU = 0.55
$g2.CellsU("PinX").ResultIU = 4.20; $g2.CellsU("PinY").ResultIU = $ly1
$g2.Text = "model4~障碍物左移一列"
StyleShape $g2 165 214 167 46 125 50 1.6
ShapeFont $g2 9 27 94 32

Write-Host "  形状 [9/16] model3..."
$g3 = $page.Drop($mProcess, 6.40, $ly1)
$g3.CellsU("Width").ResultIU = 1.80; $g3.CellsU("Height").ResultIU = 0.55
$g3.CellsU("PinX").ResultIU = 6.40; $g3.CellsU("PinY").ResultIU = $ly1
$g3.Text = "model3~读取玩家输入(上/下)"
StyleShape $g3 255 249 196 249 168 37 1.6
ShapeFont $g3 9 230 81 0

Write-Host "  形状 [10/16] model5..."
$g4 = $page.Drop($mProcess, 8.60, $ly1)
$g4.CellsU("Width").ResultIU = 1.80; $g4.CellsU("Height").ResultIU = 0.55
$g4.CellsU("PinX").ResultIU = 8.60; $g4.CellsU("PinY").ResultIU = $ly1
$g4.Text = "model5~碰撞检测"
StyleShape $g4 255 204 188 191 54 12 1.6
ShapeFont $g4 9 191 54 12

Write-Host "  形状 [11/16] 判定 碰撞?..."
$g5 = $page.Drop($mDecision, 8.60, $ly2)
$g5.CellsU("Width").ResultIU = 1.20; $g5.CellsU("Height").ResultIU = 0.60
$g5.CellsU("PinX").ResultIU = 8.60; $g5.CellsU("PinY").ResultIU = $ly2
$g5.Text = "碰撞?"
StyleShape $g5 255 249 196 249 168 37 1.6
ShapeFont $g5 9 230 81 0

Write-Host "  形状 [12/16] model7 计分..."
$g6 = $page.Drop($mProcess, 10.20, $ly2)
$g6.CellsU("Width").ResultIU = 1.50; $g6.CellsU("Height").ResultIU = 0.50
$g6.CellsU("PinX").ResultIU = 10.20; $g6.CellsU("PinY").ResultIU = $ly2
$g6.Text = "model7 计分+1"
StyleShape $g6 178 223 219 0 105 92 1.5
ShapeFont $g6 9 0 77 64

Write-Host "  形状 [13/16] model8 LED..."
$g7 = $page.Drop($mProcess, 10.20, $ly3)
$g7.CellsU("Width").ResultIU = 1.50; $g7.CellsU("Height").ResultIU = 0.50
$g7.CellsU("PinX").ResultIU = 10.20; $g7.CellsU("PinY").ResultIU = $ly3
$g7.Text = "model8~刷新LED矩阵"
StyleShape $g7 255 224 178 230 81 0 1.5
ShapeFont $g7 9 191 54 12

# ---- GAMEOVER 分支（左侧） ----
Write-Host "  形状 [14/16] GAMEOVER..."
$e1 = $page.Drop($mProcess, 2.80, 12.20)
$e1.CellsU("Width").ResultIU = 1.80; $e1.CellsU("Height").ResultIU = 0.55
$e1.CellsU("PinX").ResultIU = 2.80; $e1.CellsU("PinY").ResultIU = 12.20
$e1.Text = "GAMEOVER~游戏结束"
StyleShape $e1 229 57 53 198 40 40 2.0
ShapeFont $e1 10 255 255 255

Write-Host "  形状 [15/16] GameState..."
$e2 = $page.Drop($mProcess, 2.80, 13.40)
$e2.CellsU("Width").ResultIU = 1.80; $e2.CellsU("Height").ResultIU = 0.55
$e2.CellsU("PinX").ResultIU = 2.80; $e2.CellsU("PinY").ResultIU = 13.40
$e2.Text = "GameState~显示 GAMEOVER"
StyleShape $e2 237 231 246 123 31 162 1.8
ShapeFont $e2 10 74 20 140

Write-Host "  形状 [16/16] 重新开始?..."
$e3 = $page.Drop($mDecision, 2.80, 14.60)
$e3.CellsU("Width").ResultIU = 1.60; $e3.CellsU("Height").ResultIU = 0.70
$e3.CellsU("PinX").ResultIU = 2.80; $e3.CellsU("PinY").ResultIU = 14.60
$e3.Text = "重新开始?"
StyleShape $e3 255 249 196 249 168 37 1.8
ShapeFont $e3 10 230 81 0

Write-Host "[4] 全部 16 个形状创建完成!" -ForegroundColor Green

# ---- 游戏循环体背景框 ----
Write-Host "[5] 创建游戏循环体背景框..." -ForegroundColor Yellow
$boxLeft = 0.50; $boxTop = 7.50; $boxRight = 11.50; $boxBottom = 11.50
$loopBox = $page.DrawRectangle($boxLeft, $boxTop, $boxRight, $boxBottom)
$loopBox.CellsU("FillPattern").FormulaU = "0"
$loopBox.CellsU("LinePattern").FormulaU = "2"
$loopBox.CellsU("LineColor").FormulaU   = "RGB(230,81,0)"
$loopBox.CellsU("LineWeight").FormulaU  = "2 pt"
$loopBox.SendToBack()

$loopLabel = $page.DrawRectangle($boxLeft, $boxTop, $boxLeft + 1.60, $boxTop + 0.30)
$loopLabel.CellsU("FillPattern").FormulaU = "0"
$loopLabel.CellsU("LinePattern").FormulaU = "0"
$loopLabel.Text = "游戏循环体"
try { $loopLabel.CellsU("Char.Size").FormulaU = "10 pt"; $loopLabel.CellsU("Char.Color").FormulaU = "RGB(230,81,0)" } catch {}
Write-Host "[5] 完成" -ForegroundColor Green

# ---- 连接线 ----
Write-Host "[6] 创建连接线（精确粘合）..." -ForegroundColor Yellow

function MakeConn($src, $tgt, $lr, $lg, $lb, $lw, $dash, $label) {
    $c = $page.Drop($mConnector, 0, 0)
    $c.CellsU("BeginX").GlueTo($src.CellsU("PinX"))
    $c.CellsU("BeginY").GlueTo($src.CellsU("PinY"))
    $c.CellsU("EndX").GlueTo($tgt.CellsU("PinX"))
    $c.CellsU("EndY").GlueTo($tgt.CellsU("PinY"))
    $c.CellsU("LineColor").FormulaU  = "RGB($lr,$lg,$lb)"
    $c.CellsU("LineWeight").FormulaU = "${lw} pt"
    if ($dash) { $c.CellsU("LinePattern").FormulaU = "3" }
    if ($label) { try { $c.Text = $label } catch {} }
    return $c
}

Write-Host "  连接线 [1-6] 主流程..."
$c01 = MakeConn $sh1 $sh2 80 80 80 1.5 $false ""
$c02 = MakeConn $sh2 $sh3 80 80 80 1.5 $false ""
$c03 = MakeConn $sh3 $sh4 80 80 80 1.5 $false ""
$c04 = MakeConn $sh4 $sh5 67 160 71 1.5 $false "是"
$c04b = MakeConn $sh4 $sh3 229 57 53 1.5 $true "否"
$c05 = MakeConn $sh5 $sh6 80 80 80 1.5 $false ""

Write-Host "  连接线 [7-12] 游戏循环..."
$c06 = MakeConn $sh6 $g1 80 80 80 1.5 $false ""
$c07 = MakeConn $g1 $g2 80 80 80 1.3 $false "new_col[7:0]"
$c08 = MakeConn $g2 $g3 80 80 80 1.3 $false "obs_pos[7:0]"
$c09 = MakeConn $g3 $g4 80 80 80 1.3 $false "car_row[2:0]"
$c10 = MakeConn $g4 $g5 80 80 80 1.3 $false ""
$c11 = MakeConn $g5 $g6 67 160 71 1.3 $false "否"

Write-Host "  连接线 [13-18] 分支..."
$c12 = MakeConn $g6 $g7 80 80 80 1.3 $false ""

# 循环回线: model8 → model2（虚线）
$cLoop = $page.Drop($mConnector, 0, 0)
$cLoop.CellsU("BeginX").GlueTo($g7.CellsU("PinX"))
$cLoop.CellsU("BeginY").GlueTo($g7.CellsU("PinY"))
$cLoop.CellsU("EndX").GlueTo($g1.CellsU("PinX"))
$cLoop.CellsU("EndY").GlueTo($g1.CellsU("PinY"))
$cLoop.CellsU("LineColor").FormulaU  = "RGB(100,100,100)"
$cLoop.CellsU("LineWeight").FormulaU = "1.5 pt"
$cLoop.CellsU("LinePattern").FormulaU = "2"
$cLoop.Text = "下一游戏节拍"

# 碰撞 YES → GAMEOVER
$cHit = $page.Drop($mConnector, 0, 0)
$cHit.CellsU("BeginX").GlueTo($g5.CellsU("PinX"))
$cHit.CellsU("BeginY").GlueTo($g5.CellsU("PinY"))
$cHit.CellsU("EndX").GlueTo($e1.CellsU("PinX"))
$cHit.CellsU("EndY").GlueTo($e1.CellsU("PinY"))
$cHit.CellsU("LineColor").FormulaU  = "RGB(198,40,40)"
$cHit.CellsU("LineWeight").FormulaU = "2.5 pt"
$cHit.Text = "是 — 碰撞！"

$c13 = MakeConn $e1 $e2 80 80 80 1.5 $false ""
$c14 = MakeConn $e2 $e3 80 80 80 1.5 $false ""

# 重新开始? 是 → 回到 GAMING
$cRestartY = $page.Drop($mConnector, 0, 0)
$cRestartY.CellsU("BeginX").GlueTo($e3.CellsU("PinX"))
$cRestartY.CellsU("BeginY").GlueTo($e3.CellsU("PinY"))
$cRestartY.CellsU("EndX").GlueTo($sh5.CellsU("PinX"))
$cRestartY.CellsU("EndY").GlueTo($sh5.CellsU("PinY"))
$cRestartY.CellsU("LineColor").FormulaU  = "RGB(67,160,71)"
$cRestartY.CellsU("LineWeight").FormulaU = "2.0 pt"
$cRestartY.Text = "是"

# 重新开始? 否 → 停留在 GameState
$cRestartN = $page.Drop($mConnector, 0, 0)
$cRestartN.CellsU("BeginX").GlueTo($e3.CellsU("PinX"))
$cRestartN.CellsU("BeginY").GlueTo($e3.CellsU("PinY"))
$cRestartN.CellsU("EndX").GlueTo($e2.CellsU("PinX"))
$cRestartN.CellsU("EndY").GlueTo($e2.CellsU("PinY"))
$cRestartN.CellsU("LineColor").FormulaU  = "RGB(229,57,53)"
$cRestartN.CellsU("LineWeight").FormulaU = "1.5 pt"
$cRestartN.CellsU("LinePattern").FormulaU = "3"
$cRestartN.Text = "否"

Write-Host "[6] 全部连接线完成!" -ForegroundColor Green

# ---- 保存 ----
Write-Host "[7] 保存文件..." -ForegroundColor Yellow
$savePath = "c:\Users\17740\Desktop\digital\SystemWorkflowChart.vsdx"
if (Test-Path $savePath) { Remove-Item $savePath -Force }
$doc.SaveAs($savePath)
Write-Host "[7] 已保存: $savePath" -ForegroundColor Green

# 显示 Visio 窗口
$visio.ShowChanges = $true
$visio.Visible = $true

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  制图完成！" -ForegroundColor Cyan
Write-Host "  文件: $savePath" -ForegroundColor Cyan
Write-Host "========================================"
Write-Host ""
Write-Host "Visio 窗口已打开，请检查并手动微调布局。" -ForegroundColor White
