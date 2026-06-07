# ============================================================
# 数字逻辑课程设计 — 系统工作流程图 (Visio 自动制图脚本)
# 使用 Visio COM 自动化精确绘制，连接点对齐无误
# ============================================================

$ErrorActionPreference = "Stop"
$visio = $null

try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  系统工作流程图 — Visio 自动制图" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # ============================================================
    # 1. 启动 Visio
    # ============================================================
    Write-Host "[1/8] 正在启动 Visio..." -ForegroundColor Yellow
    $visio = New-Object -ComObject Visio.Application
    $visio.Visible = $true
    $visio.AlertResponse = 1  # OK to all alerts
    Start-Sleep -Seconds 2
    Write-Host "  ✓ Visio 已启动" -ForegroundColor Green

    # ============================================================
    # 2. 新建文档
    # ============================================================
    Write-Host "[2/8] 正在创建文档..." -ForegroundColor Yellow

    # 尝试用基本流程图模板创建文档
    $templateNames = @("Basic Flowchart", "BASFLO_M", "Basic Flowchart.vstx")
    $doc = $null

    foreach ($tpl in $templateNames) {
        try {
            $doc = $visio.Documents.Add($tpl)
            Write-Host "  ✓ 使用模板 '$tpl' 创建成功" -ForegroundColor Green
            break
        } catch {
            Write-Host "  ⚠ 模板 '$tpl' 不可用，尝试下一个..." -ForegroundColor DarkYellow
        }
    }

    if ($null -eq $doc) {
        # 最后尝试：空白文档 + 手动打开模具
        Write-Host "  → 使用空白文档，手动加载模具..." -ForegroundColor Yellow
        $doc = $visio.Documents.Add("")
        $stencilPath = ""
        $possiblePaths = @(
            "C:\Program Files\Microsoft Office\root\Office16\Visio Content\2052\BASFLO_M.VSSX",
            "C:\Program Files\Microsoft Office\root\Office16\Visio Content\1033\BASFLO_M.VSSX",
            "$env:ProgramFiles\Microsoft Office\root\Office16\Visio Content\2052\BASFLO_M.VSSX",
            "$env:ProgramFiles\Microsoft Office\root\Office16\Visio Content\1033\BASFLO_M.VSSX"
        )
        foreach ($p in $possiblePaths) {
            if (Test-Path $p) {
                $stencilPath = $p
                break
            }
        }
        if ($stencilPath -ne "") {
            $stencilDoc = $visio.Documents.OpenEx($stencilPath, 4)  # visOpenDocked
            Write-Host "  ✓ 已加载模具: $stencilPath" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ 未找到 BASFLO_M.VSSX，尝试搜索..." -ForegroundColor DarkYellow
            $found = Get-ChildItem -Path "C:\Program Files\Microsoft Office" -Recurse -Filter "BASFLO_M.VSSX" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $stencilDoc = $visio.Documents.OpenEx($found.FullName, 4)
                Write-Host "  ✓ 已加载模具: $($found.FullName)" -ForegroundColor Green
            }
        }
    }

    $page = $visio.ActivePage
    $page.Name = "系统工作流程图"

    # 设置页面大小（英寸）- 足够容纳整个流程图
    $page.PageSheet.CellsU("PageWidth").ResultIU = 12.0
    $page.PageSheet.CellsU("PageHeight").ResultIU = 16.0
    Write-Host "  ✓ 页面大小: 12×16 英寸" -ForegroundColor Green

    # ============================================================
    # 3. 获取母版 (Masters)
    # ============================================================
    Write-Host "[3/8] 正在获取母版形状..." -ForegroundColor Yellow

    # 从文档母版集合获取（模板方式创建时在这里）
    # 如果模板方式失败，从打开的模具获取
    $masters = $doc.Masters

    # 尝试多种母版名称（中英文兼容）
    function Get-MasterSafe($mastersCollection, $names) {
        foreach ($name in $names) {
            try {
                $m = $mastersCollection.ItemU($name)
                Write-Host "  ✓ 找到母版: '$name'" -ForegroundColor Green
                return $m
            } catch {}
            try {
                $m = $mastersCollection.Item($name)
                Write-Host "  ✓ 找到母版(本地化): '$name'" -ForegroundColor Green
                return $m
            } catch {}
        }
        Write-Host "  ✗ 未找到母版: $($names -join ', ')" -ForegroundColor Red
        return $null
    }

    $mStartEnd   = Get-MasterSafe $masters @("Start/End", "Terminator", "开始/结束", "终止符")
    $mProcess    = Get-MasterSafe $masters @("Process", "进程", "流程")
    $mDecision   = Get-MasterSafe $masters @("Decision", "判定", "决策")
    $mConnector  = Get-MasterSafe $masters @("Dynamic connector", "Connector", "动态连接线", "连接线")
    $mRectangle  = Get-MasterSafe $masters @("Rectangle", "矩形")

    if ($null -eq $mProcess) {
        Write-Host "  ! 关键母版缺失，尝试使用矩形替代..." -ForegroundColor Red
        $mProcess = Get-MasterSafe $masters @("Rectangle", "矩形", "Square", "圆角矩形")
    }
    if ($null -eq $mDecision) {
        $mDecision = Get-MasterSafe $masters @("Diamond", "菱形", "Decision")
    }
    if ($null -eq $mStartEnd) {
        $mStartEnd = Get-MasterSafe $masters @("Rounded rectangle", "圆角矩形", "Start/End")
    }

    # ============================================================
    # 4. 辅助函数
    # ============================================================
    function Add-Shape($master, $x, $y, $w, $h, $text) {
        # 在指定 PinX/PinY 位置放置形状
        $shape = $page.Drop($master, $x, $y)
        $shape.CellsU("Width").ResultIU = $w
        $shape.CellsU("Height").ResultIU = $h
        $shape.CellsU("PinX").ResultIU = $x
        $shape.CellsU("PinY").ResultIU = $y
        $shape.Text = $text
        return $shape
    }

    function Set-FillColor($shape, $r, $g, $b) {
        $shape.CellsU("FillForegnd").FormulaU = "RGB($r,$g,$b)"
        $shape.CellsU("FillBkgnd").FormulaU = "RGB($r,$g,$b)"
        $shape.CellsU("FillPattern").FormulaU = "1"  # Solid
    }

    function Set-LineColor($shape, $r, $g, $b, $weight) {
        $shape.CellsU("LineColor").FormulaU = "RGB($r,$g,$b)"
        $shape.CellsU("LineWeight").FormulaU = "${weight} pt"
    }

    function Set-CharFormat($shape, $fontSize, $r, $g, $b, $bold=$false) {
        try {
            $chars = $shape.Characters
            $chars.Begin = 0
            $chars.End = $shape.CharCount
            $chars.CharProps(17) = $fontSize  # visCharacterSize
            $chars.CharProps(21) = "RGB($r,$g,$b)"  # visCharacterColor
            if ($bold) {
                $chars.CharProps(1) = 1  # visBold
            }
        } catch {
            Write-Host "  ⚠ 字符格式化失败（非致命）" -ForegroundColor DarkYellow
        }
    }

    function Add-Connector($mConn, $srcShape, $tgtShape, $label, $labelR, $labelG, $labelB) {
        $conn = $page.Drop($mConn, 0, 0)
        # 粘合起点到源形状
        $conn.CellsU("BeginX").GlueTo($srcShape.CellsU("PinX"))
        $conn.CellsU("BeginY").GlueTo($srcShape.CellsU("PinY"))
        # 粘合终点到目标形状
        $conn.CellsU("EndX").GlueTo($tgtShape.CellsU("PinX"))
        $conn.CellsU("EndY").GlueTo($tgtShape.CellsU("PinY"))
        # 设置连接线样式
        $conn.CellsU("LineColor").FormulaU = "RGB($labelR,$labelG,$labelB)"
        $conn.CellsU("LineWeight").FormulaU = "1.5 pt"
        if ($label -ne "") {
            # 在连接线上添加文本
            try {
                $conn.Text = $label
                $conn.CellsU("Char.Size").FormulaU = "9 pt"
                $conn.CellsU("Char.Color").FormulaU = "RGB($labelR,$labelG,$labelB)"
            } catch {}
        }
        return $conn
    }

    # ============================================================
    # 5. 创建所有形状
    # ============================================================
    Write-Host "[4/8] 正在创建形状..." -ForegroundColor Yellow
    $CX = 6.0   # 主流程中心 X 坐标（英寸）
    $LW = 2.6   # 大型流程框宽度
    $LH = 0.60  # 大型流程框高度
    $MW = 1.7   # 中型流程框宽度
    $MH = 0.55  # 中型流程框高度
    $SW = 1.5   # 小型流程框宽度
    $SH = 0.50  # 小型流程框高度
    $DW = 1.5   # 判定框宽度
    $DH = 0.70  # 判定框高度

    # ----- 主流程（从上到下） -----
    Write-Host "  创建主流程形状..." -ForegroundColor Gray
    $start      = Add-Shape $mStartEnd  $CX  0.65  $SW 0.45  "系统上电 / 复位"
    $m1         = Add-Shape $mProcess   $CX  1.80  $LW $LH   "model1 时钟分频`n产生各模块所需时钟"
    $m6idle     = Add-Shape $mProcess   $CX  3.00  $LW $LH   "model6 状态机 → IDLE`n等待玩家按下开始键"
    $decStart   = Add-Shape $mDecision  $CX  4.20  $DW $DH   "start?`n玩家按下开始?"
    $gaming     = Add-Shape $mProcess   $CX  5.55  $LW $LH   "状态机 → GAMING`n开始游戏循环"
    $scoreClr   = Add-Shape $mProcess   $CX  6.70  $LW $LH   "model7 计分器清零"

    # ----- 游戏循环体内部（横向排列） -----
    Write-Host "  创建游戏循环内部形状..." -ForegroundColor Gray
    $loopY1  = 8.30   # 第一行 Y
    $loopY2  = 9.60   # 第二行 Y (判定)
    $loopY3  = 10.80  # 第三行 Y (LED)

    $m2       = Add-Shape $mProcess   2.00  $loopY1  $MW $MH   "model2`n生成随机障碍列"
    $m4       = Add-Shape $mProcess   4.00  $loopY1  $MW $MH   "model4`n障碍物移位"
    $m3       = Add-Shape $mProcess   6.00  $loopY1  $MW $MH   "model3`n读取玩家输入"
    $m5       = Add-Shape $mProcess   8.00  $loopY1  $MW $MH   "model5`n碰撞检测"

    $decColl  = Add-Shape $mDecision  8.00  $loopY2  1.20 0.60  "碰撞?"

    $m7score  = Add-Shape $mProcess   9.80  $loopY2  1.50 0.50  "model7 计分+1"
    $m8led    = Add-Shape $mProcess   9.80  $loopY3  1.50 0.50  "model8`n刷新LED矩阵"

    # ----- GAMEOVER 分支（左侧） -----
    Write-Host "  创建 GAMEOVER 分支形状..." -ForegroundColor Gray
    $gameover  = Add-Shape $mProcess   2.80  12.20  $MW $MH   "GAMEOVER`n游戏结束"
    $gs        = Add-Shape $mProcess   2.80  13.40  $MW $MH   "GameState`n显示 GAMEOVER"
    $decRestart = Add-Shape $mDecision 2.80  14.60  $DW $DH   "重新开始?"

    Write-Host "  ✓ 所有形状已创建" -ForegroundColor Green

    # ============================================================
    # 6. 设置颜色
    # ============================================================
    Write-Host "[5/8] 正在设置颜色..." -ForegroundColor Yellow

    # 开始/结束 — 绿色
    Set-FillColor $start 67 160 71
    Set-LineColor $start 46 125 50 2.0
    Set-CharFormat $start 11 255 255 255 $true

    # model1 — 蓝色系
    Set-FillColor $m1 187 222 251
    Set-LineColor $m1 21 101 192 1.8
    Set-CharFormat $m1 10 13 71 161 $true

    # model6 IDLE — 紫色系
    Set-FillColor $m6idle 225 190 231
    Set-LineColor $m6idle 106 27 154 1.8
    Set-CharFormat $m6idle 10 74 20 140 $true

    # 判定 start? — 黄色系
    Set-FillColor $decStart 255 249 196
    Set-LineColor $decStart 249 168 37 1.8
    Set-CharFormat $decStart 10 230 81 0 $true

    # GAMING — 绿色系
    Set-FillColor $gaming 200 230 201
    Set-LineColor $gaming 56 142 60 2.0
    Set-CharFormat $gaming 10 27 94 32 $true

    # 计分清零 — 青色系
    Set-FillColor $scoreClr 178 223 219
    Set-LineColor $scoreClr 0 105 92 1.8
    Set-CharFormat $scoreClr 10 0 77 64 $true

    # model2 — 绿色
    Set-FillColor $m2 200 230 201
    Set-LineColor $m2 46 125 50 1.6
    Set-CharFormat $m2 9 27 94 32 $true

    # model4 — 绿色
    Set-FillColor $m4 165 214 167
    Set-LineColor $m4 46 125 50 1.6
    Set-CharFormat $m4 9 27 94 32 $true

    # model3 — 黄色
    Set-FillColor $m3 255 249 196
    Set-LineColor $m3 249 168 37 1.6
    Set-CharFormat $m3 9 230 81 0 $true

    # model5 — 橙色
    Set-FillColor $m5 255 204 188
    Set-LineColor $m5 191 54 12 1.6
    Set-CharFormat $m5 9 191 54 12 $true

    # 判定 碰撞? — 黄色
    Set-FillColor $decColl 255 249 196
    Set-LineColor $decColl 249 168 37 1.6
    Set-CharFormat $decColl 9 230 81 0 $true

    # model7 计分 — 青色
    Set-FillColor $m7score 178 223 219
    Set-LineColor $m7score 0 105 92 1.5
    Set-CharFormat $m7score 9 0 77 64 $true

    # model8 LED — 橙色
    Set-FillColor $m8led 255 224 178
    Set-LineColor $m8led 230 81 0 1.5
    Set-CharFormat $m8led 9 191 54 12 $true

    # GAMEOVER — 红色
    Set-FillColor $gameover 229 57 53
    Set-LineColor $gameover 198 40 40 2.0
    Set-CharFormat $gameover 10 255 255 255 $true

    # GameState — 紫色
    Set-FillColor $gs 237 231 246
    Set-LineColor $gs 123 31 162 1.8
    Set-CharFormat $gs 10 74 20 140 $true

    # 判定 重新开始? — 黄色
    Set-FillColor $decRestart 255 249 196
    Set-LineColor $decRestart 249 168 37 1.8
    Set-CharFormat $decRestart 10 230 81 0 $true

    Write-Host "  ✓ 颜色设置完成" -ForegroundColor Green

    # ============================================================
    # 6.5 游戏循环体背景框
    # ============================================================
    Write-Host "  创建游戏循环体背景框..." -ForegroundColor Gray

    # 循环体背景矩形（手动绘制矩形，不使用母版以避免依赖问题）
    $loopBox = $page.DrawRectangle(0.60, 7.50, 11.20, 11.50)
    $loopBox.CellsU("FillPattern").FormulaU = "0"     # 无填充
    $loopBox.CellsU("LinePattern").FormulaU = "2"     # 虚线
    $loopBox.CellsU("LineColor").FormulaU = "RGB(230,81,0)"
    $loopBox.CellsU("LineWeight").FormulaU = "2 pt"
    # 发送到最底层
    $loopBox.SendToBack()

    # 循环体标签
    $loopLabel = $page.DrawRectangle(0.60, 7.50, 2.00, 7.90)
    $loopLabel.CellsU("FillPattern").FormulaU = "0"
    $loopLabel.CellsU("LinePattern").FormulaU = "0"
    $loopLabel.Text = "游戏循环体"
    try {
        $loopLabel.Chars.CharProps(17) = 10
        $loopLabel.Chars.CharProps(21) = "RGB(230,81,0)"
    } catch {}

    Write-Host "  ✓ 游戏循环框创建完成" -ForegroundColor Green

    # ============================================================
    # 7. 创建所有连接线（精确粘合）
    # ============================================================
    Write-Host "[6/8] 正在创建连接线（精确对齐）..." -ForegroundColor Yellow

    # --- 主流程连接 ---
    Write-Host "  主流程连接..." -ForegroundColor Gray

    # Start → model1
    $c1 = Add-Connector $mConnector $start $m1 "" 80 80 80

    # model1 → model6 IDLE
    $c2 = Add-Connector $mConnector $m1 $m6idle "" 80 80 80

    # model6 IDLE → Decision(start?)
    $c3 = Add-Connector $mConnector $m6idle $decStart "" 80 80 80

    # Decision(start?) → GAMING (是/Yes，向下)
    $c4 = Add-Connector $mConnector $decStart $gaming "是" 67 160 71
    try {
        # 将标签移到连接线中间
        $c4.CellsU("Controls.TextPosition").FormulaU = "0.5"
    } catch {}

    # Decision(start?) → 回 model6 IDLE (否/No，向左绕回)
    $cNoStart = $page.Drop($mConnector, 0, 0)
    $cNoStart.CellsU("BeginX").GlueTo($decStart.CellsU("PinX"))
    $cNoStart.CellsU("BeginY").GlueTo($decStart.CellsU("PinY"))
    # 向左再向上绕回到 model6 IDLE 的左侧
    # 先向左到 x=3.5, 再向上到 y=3.0 (model6中心Y)
    $cNoStart.CellsU("EndX").GlueTo($m6idle.CellsU("PinX"))
    $cNoStart.CellsU("EndY").GlueTo($m6idle.CellsU("PinY"))
    $cNoStart.CellsU("LineColor").FormulaU = "RGB(229,57,53)"
    $cNoStart.CellsU("LineWeight").FormulaU = "1.5 pt"
    $cNoStart.CellsU("LinePattern").FormulaU = "3"  # 虚线 (3=虚线)
    $cNoStart.Text = "否"
    try {
        $cNoStart.Chars.CharProps(17) = 9
        $cNoStart.Chars.CharProps(21) = "RGB(229,57,53)"
    } catch {}

    # GAMING → 计分清零
    $c5 = Add-Connector $mConnector $gaming $scoreClr "" 80 80 80

    # 计分清零 → model2（进入循环体，向下再向左）
    $c6 = Add-Connector $mConnector $scoreClr $m2 "" 80 80 80

    # --- 循环体内部连接 ---
    Write-Host "  循环体内部连接..." -ForegroundColor Gray

    # model2 → model4
    $c7 = Add-Connector $mConnector $m2 $m4 "" 80 80 80

    # model4 → model3
    $c8 = Add-Connector $mConnector $m4 $m3 "" 80 80 80

    # model3 → model5
    $c9 = Add-Connector $mConnector $m3 $m5 "" 80 80 80
    # 在连接线上标注数据
    try {
        $c9.Text = "car_row[2:0]"
        $c9.Chars.CharProps(17) = 8
        $c9.Chars.CharProps(21) = "RGB(117,117,117)"
    } catch {}

    # model2 → model4 标注
    try {
        $c7.Text = "new_col[7:0]"
        $c7.Chars.CharProps(17) = 8
        $c7.Chars.CharProps(21) = "RGB(117,117,117)"
    } catch {}

    # model4 → model5 (obs_col数据)
    # 再补一条从 model4 下方到 model5 下方的数据连线
    $cDataObs = $page.Drop($mConnector, 0, 0)
    $cDataObs.CellsU("BeginX").GlueTo($m4.CellsU("PinX"))
    $cDataObs.CellsU("BeginY").GlueTo($m4.CellsU("PinY"))
    $cDataObs.CellsU("EndX").GlueTo($m5.CellsU("PinX"))
    $cDataObs.CellsU("EndY").GlueTo($m5.CellsU("PinY"))
    $cDataObs.CellsU("LineColor").FormulaU = "RGB(120,120,120)"
    $cDataObs.CellsU("LineWeight").FormulaU = "1.2 pt"
    try {
        $cDataObs.Text = "obs_pos[7:0]"
        $cDataObs.Chars.CharProps(17) = 8
        $cDataObs.Chars.CharProps(21) = "RGB(120,120,120)"
    } catch {}

    # model5 → Decision(碰撞?)
    $c10 = Add-Connector $mConnector $m5 $decColl "" 80 80 80

    # Decision(碰撞?) "否" → model7 计分
    $c11 = Add-Connector $mConnector $decColl $m7score "否" 67 160 71
    try {
        $c11.Chars.CharProps(17) = 9
        $c11.Chars.CharProps(21) = "RGB(67,160,71)"
    } catch {}

    # model7 计分 → model8 LED
    $c12 = Add-Connector $mConnector $m7score $m8led "" 80 80 80

    # model8 → 循环回到 model2 (右侧绕回上方)
    $cLoopBack = $page.Drop($mConnector, 0, 0)
    $cLoopBack.CellsU("BeginX").GlueTo($m8led.CellsU("PinX"))
    $cLoopBack.CellsU("BeginY").GlueTo($m8led.CellsU("PinY"))
    $cLoopBack.CellsU("EndX").GlueTo($m2.CellsU("PinX"))
    $cLoopBack.CellsU("EndY").GlueTo($m2.CellsU("PinY"))
    $cLoopBack.CellsU("LineColor").FormulaU = "RGB(100,100,100)"
    $cLoopBack.CellsU("LineWeight").FormulaU = "1.5 pt"
    $cLoopBack.CellsU("LinePattern").FormulaU = "2"  # 虚线 = 2
    $cLoopBack.Text = "下一游戏节拍"
    try {
        $cLoopBack.Chars.CharProps(17) = 9
        $cLoopBack.Chars.CharProps(21) = "RGB(100,100,100)"
    } catch {}

    # --- 碰撞分支：是 → GAMEOVER ---
    Write-Host "  碰撞分支连接..." -ForegroundColor Gray

    # decColl "是" → gameover (向下向左)
    $cHit = $page.Drop($mConnector, 0, 0)
    $cHit.CellsU("BeginX").GlueTo($decColl.CellsU("PinX"))
    $cHit.CellsU("BeginY").GlueTo($decColl.CellsU("PinY"))
    $cHit.CellsU("EndX").GlueTo($gameover.CellsU("PinX"))
    $cHit.CellsU("EndY").GlueTo($gameover.CellsU("PinY"))
    $cHit.CellsU("LineColor").FormulaU = "RGB(198,40,40)"
    $cHit.CellsU("LineWeight").FormulaU = "2.5 pt"
    $cHit.Text = "是 — 碰撞！"
    try {
        $cHit.Chars.CharProps(17) = 9
        $cHit.Chars.CharProps(21) = "RGB(198,40,40)"
        $cHit.Chars.CharProps(1) = 1  # Bold
    } catch {}

    # GAMEOVER → GameState
    $c13 = Add-Connector $mConnector $gameover $gs "" 80 80 80

    # GameState → Decision(重新开始?)
    $c14 = Add-Connector $mConnector $gs $decRestart "" 80 80 80

    # Decision(重新开始?) "是" → 回到 GAMING
    $cRestartYes = $page.Drop($mConnector, 0, 0)
    $cRestartYes.CellsU("BeginX").GlueTo($decRestart.CellsU("PinX"))
    $cRestartYes.CellsU("BeginY").GlueTo($decRestart.CellsU("PinY"))
    $cRestartYes.CellsU("EndX").GlueTo($gaming.CellsU("PinX"))
    $cRestartYes.CellsU("EndY").GlueTo($gaming.CellsU("PinY"))
    $cRestartYes.CellsU("LineColor").FormulaU = "RGB(67,160,71)"
    $cRestartYes.CellsU("LineWeight").FormulaU = "2.0 pt"
    $cRestartYes.Text = "是"
    try {
        $cRestartYes.Chars.CharProps(17) = 10
        $cRestartYes.Chars.CharProps(21) = "RGB(67,160,71)"
        $cRestartYes.Chars.CharProps(1) = 1
    } catch {}

    # Decision(重新开始?) "否" → 停留在 GameState (自循环)
    $cRestartNo = $page.Drop($mConnector, 0, 0)
    $cRestartNo.CellsU("BeginX").GlueTo($decRestart.CellsU("PinX"))
    $cRestartNo.CellsU("BeginY").GlueTo($decRestart.CellsU("PinY"))
    $cRestartNo.CellsU("EndX").GlueTo($gs.CellsU("PinX"))
    $cRestartNo.CellsU("EndY").GlueTo($gs.CellsU("PinY"))
    $cRestartNo.CellsU("LineColor").FormulaU = "RGB(229,57,53)"
    $cRestartNo.CellsU("LineWeight").FormulaU = "1.5 pt"
    $cRestartNo.CellsU("LinePattern").FormulaU = "3"  # 虚线
    $cRestartNo.Text = "否"
    try {
        $cRestartNo.Chars.CharProps(17) = 9
        $cRestartNo.Chars.CharProps(21) = "RGB(229,57,53)"
    } catch {}

    Write-Host "  ✓ 所有连接线创建完成" -ForegroundColor Green

    # ============================================================
    # 8. 保存文件
    # ============================================================
    Write-Host "[7/8] 正在保存文件..." -ForegroundColor Yellow
    $savePath = "c:\Users\17740\Desktop\digital\系统工作流程图.vsdx"

    # 如果文件已存在，先删除
    if (Test-Path $savePath) {
        Remove-Item $savePath -Force
        Write-Host "  → 已删除旧文件" -ForegroundColor Gray
    }

    $doc.SaveAs($savePath)
    Write-Host "  ✓ 文件已保存至: $savePath" -ForegroundColor Green

    # ============================================================
    # 9. 完成
    # ============================================================
    Write-Host "[8/8] 完成！" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  制图完成！" -ForegroundColor Cyan
    Write-Host "  文件: $savePath" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "提示: Visio 窗口保持打开，您可以手动微调布局。" -ForegroundColor White
    Write-Host "      确认无误后请关闭 Visio 窗口。" -ForegroundColor White

    # 保持 Visio 打开，不自动关闭
    # $doc.Close()
    # $visio.Quit()

} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  错误: $_" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red

    if ($null -ne $visio) {
        Write-Host "Visio 保持打开以便排查问题。" -ForegroundColor Yellow
    }

    # 不自动关闭 Visio，便于排查
    exit 1
}
