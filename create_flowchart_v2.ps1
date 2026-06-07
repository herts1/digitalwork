# ============================================================
# 数字逻辑课程设计 — 系统工作流程图 (Visio COM 自动制图 v2)
# 修复：母版查找路径 + 模具直接引用
# ============================================================

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  System Workflow Chart - Visio Auto Draw v2" -ForegroundColor Cyan
    Write-Host "========================================"

    # ---- 1. Launch Visio ----
    Write-Host "[1/7] Launching Visio..." -ForegroundColor Yellow
    $visio = New-Object -ComObject Visio.Application
    $visio.Visible = $true
    Start-Sleep -Seconds 2
    Write-Host "  OK Visio started" -ForegroundColor Green

    # ---- 2. Create blank doc + open Basic Flowchart stencil ----
    Write-Host "[2/7] Creating document and loading stencil..." -ForegroundColor Yellow

    $doc = $visio.Documents.Add("")
    $page = $visio.ActivePage
    $page.Name = "SystemWorkflowChart"

    # Set page size (inches)
    $page.PageSheet.CellsU("PageWidth").ResultIU = 12.0
    $page.PageSheet.CellsU("PageHeight").ResultIU = 16.0

    # Open Basic Flowchart Shapes stencil (Chinese Visio - 2052 locale)
    $stencilPath = "C:\Program Files\Microsoft Office\root\Office16\Visio Content\2052\BASFLO_M.VSSX"
    if (-not (Test-Path $stencilPath)) {
        $stencilPath = "C:\Program Files\Microsoft Office\root\Office16\Visio Content\1033\BASFLO_M.VSSX"
    }
    $stencil = $visio.Documents.OpenEx($stencilPath, 4)  # visOpenDocked
    Write-Host "  OK Stencil loaded: $stencilPath" -ForegroundColor Green
    Write-Host "  OK Page size: 12 x 16 inches" -ForegroundColor Green

    # ---- 3. Get masters (from stencil, not blank doc) ----
    Write-Host "[3/7] Getting master shapes from stencil..." -ForegroundColor Yellow

    $mProcess   = $stencil.Masters.ItemU("Process")
    $mDecision  = $stencil.Masters.ItemU("Decision")
    $mStartEnd  = $stencil.Masters.ItemU("Start/End")
    $mConnector = $stencil.Masters.ItemU("Dynamic connector")

    Write-Host "  OK Process master" -ForegroundColor Green
    Write-Host "  OK Decision master" -ForegroundColor Green
    Write-Host "  OK Start/End master" -ForegroundColor Green
    Write-Host "  OK Dynamic connector master" -ForegroundColor Green

    # ---- 4. Helper functions ----
    function AddShape($master, $pinX, $pinY, $width, $height, $text) {
        $s = $page.Drop($master, $pinX, $pinY)
        $s.CellsU("Width").ResultIU  = $width
        $s.CellsU("Height").ResultIU = $height
        $s.CellsU("PinX").ResultIU   = $pinX
        $s.CellsU("PinY").ResultIU   = $pinY
        $s.Text = $text
        return $s
    }

    function SetFill($s, $r, $g, $b) {
        $s.CellsU("FillForegnd").FormulaU = "RGB($r,$g,$b)"
        $s.CellsU("FillBkgnd").FormulaU   = "RGB($r,$g,$b)"
        $s.CellsU("FillPattern").FormulaU = "1"
    }

    function SetLine($s, $r, $g, $b, $w) {
        $s.CellsU("LineColor").FormulaU   = "RGB($r,$g,$b)"
        $s.CellsU("LineWeight").FormulaU  = "${w} pt"
    }

    function SetFont($s, $size, $r, $g, $b) {
        try {
            $c = $s.Characters
            $c.Begin = 0
            $c.End   = $s.CharCount
            $c.CharProps(17) = $size       # Font size
            $c.CharProps(21) = "RGB($r,$g,$b)"  # Font color
            $c.CharProps(1)  = 1            # Bold
        } catch {}
    }

    function AddConn($src, $tgt, $label, $lr, $lg, $lb, $lw) {
        $conn = $page.Drop($mConnector, 0, 0)
        $conn.CellsU("BeginX").GlueTo($src.CellsU("PinX"))
        $conn.CellsU("BeginY").GlueTo($src.CellsU("PinY"))
        $conn.CellsU("EndX").GlueTo($tgt.CellsU("PinX"))
        $conn.CellsU("EndY").GlueTo($tgt.CellsU("PinY"))
        $conn.CellsU("LineColor").FormulaU  = "RGB($lr,$lg,$lb)"
        $conn.CellsU("LineWeight").FormulaU = "${lw} pt"
        if ($label) {
            try {
                $conn.Text = $label
                $conn.CellsU("Char.Size").FormulaU  = "9 pt"
                $conn.CellsU("Char.Color").FormulaU = "RGB($lr,$lg,$lb)"
            } catch {}
        }
        return $conn
    }

    # ---- 5. Create all shapes ----
    Write-Host "[4/7] Creating shapes..." -ForegroundColor Yellow

    $CX = 6.0    # Center X of main flow

    # --- Top-to-bottom main flow ---
    $shStart    = AddShape $mStartEnd $CX  0.65  1.5  0.45  "System Power-On / Reset"
    $shM1       = AddShape $mProcess  $CX  1.80  2.6  0.60  "model1 Clock Divider~Generate clocks for all modules"
    $shM6Idle   = AddShape $mProcess  $CX  3.00  2.6  0.60  "model6 FSM -> IDLE~Wait for player START"
    $shDecStart = AddShape $mDecision $CX  4.20  1.5  0.70  "start?~Player pressed START?"
    $shGaming   = AddShape $mProcess  $CX  5.55  2.6  0.60  "FSM -> GAMING~Begin game loop"
    $shScoreClr = AddShape $mProcess  $CX  6.70  2.6  0.60  "model7 Score Counter Reset"

    # --- Game loop internal shapes ---
    $ly1 = 8.30   # Row 1 Y
    $ly2 = 9.60   # Row 2 Y (collision decision)
    $ly3 = 10.80  # Row 3 Y (LED)

    $shM2      = AddShape $mProcess  2.00  $ly1  1.70  0.55  "model2~Generate Random Obstacle"
    $shM4      = AddShape $mProcess  4.00  $ly1  1.70  0.55  "model4~Shift Obstacle Left"
    $shM3      = AddShape $mProcess  6.00  $ly1  1.70  0.55  "model3~Read Player Input (Up/Down)"
    $shM5      = AddShape $mProcess  8.00  $ly1  1.70  0.55  "model5~Collision Detection"
    $shDecColl = AddShape $mDecision 8.00  $ly2  1.20  0.60  "Collision?"
    $shM7Score = AddShape $mProcess  9.80  $ly2  1.50  0.50  "model7 Score +1"
    $shM8Led   = AddShape $mProcess  9.80  $ly3  1.50  0.50  "model8~Refresh LED Matrix"

    # --- GAMEOVER branch (left side) ---
    $shGameOver  = AddShape $mProcess  2.80  12.20  1.70  0.55  "GAMEOVER~Game Over"
    $shGS        = AddShape $mProcess  2.80  13.40  1.70  0.55  "GameState~Display GAMEOVER"
    $shDecRestart = AddShape $mDecision 2.80 14.60  1.50  0.70  "Restart?"

    Write-Host "  OK All shapes created" -ForegroundColor Green

    # ---- 6. Set colors ----
    Write-Host "[5/7] Setting colors..." -ForegroundColor Yellow

    # Start - Green
    SetFill $shStart 67 160 71; SetLine $shStart 46 125 50 2.0; SetFont $shStart 11 255 255 255

    # model1 - Blue
    SetFill $shM1 187 222 251; SetLine $shM1 21 101 192 1.8; SetFont $shM1 10 13 71 161

    # model6 IDLE - Purple
    SetFill $shM6Idle 225 190 231; SetLine $shM6Idle 106 27 154 1.8; SetFont $shM6Idle 10 74 20 140

    # Decision start? - Yellow
    SetFill $shDecStart 255 249 196; SetLine $shDecStart 249 168 37 1.8; SetFont $shDecStart 10 230 81 0

    # GAMING - Green
    SetFill $shGaming 200 230 201; SetLine $shGaming 56 142 60 2.0; SetFont $shGaming 10 27 94 32

    # Score clear - Teal
    SetFill $shScoreClr 178 223 219; SetLine $shScoreClr 0 105 92 1.8; SetFont $shScoreClr 10 0 77 64

    # model2 - Light Green
    SetFill $shM2 200 230 201; SetLine $shM2 46 125 50 1.6; SetFont $shM2 9 27 94 32

    # model4 - Green
    SetFill $shM4 165 214 167; SetLine $shM4 46 125 50 1.6; SetFont $shM4 9 27 94 32

    # model3 - Yellow
    SetFill $shM3 255 249 196; SetLine $shM3 249 168 37 1.6; SetFont $shM3 9 230 81 0

    # model5 - Orange
    SetFill $shM5 255 204 188; SetLine $shM5 191 54 12 1.6; SetFont $shM5 9 191 54 12

    # Decision collision? - Yellow
    SetFill $shDecColl 255 249 196; SetLine $shDecColl 249 168 37 1.6; SetFont $shDecColl 9 230 81 0

    # model7 score - Teal
    SetFill $shM7Score 178 223 219; SetLine $shM7Score 0 105 92 1.5; SetFont $shM7Score 9 0 77 64

    # model8 LED - Orange
    SetFill $shM8Led 255 224 178; SetLine $shM8Led 230 81 0 1.5; SetFont $shM8Led 9 191 54 12

    # GAMEOVER - Red
    SetFill $shGameOver 229 57 53; SetLine $shGameOver 198 40 40 2.0; SetFont $shGameOver 10 255 255 255

    # GameState - Purple
    SetFill $shGS 237 231 246; SetLine $shGS 123 31 162 1.8; SetFont $shGS 10 74 20 140

    # Decision restart? - Yellow
    SetFill $shDecRestart 255 249 196; SetLine $shDecRestart 249 168 37 1.8; SetFont $shDecRestart 10 230 81 0

    Write-Host "  OK Colors set" -ForegroundColor Green

    # ---- 6.5 Game loop background box ----
    Write-Host "  Creating game loop container box..." -ForegroundColor Gray

    $boxLeft   = 0.60
    $boxTop    = 7.50
    $boxRight  = 11.20
    $boxBottom = 11.50

    $loopBox = $page.DrawRectangle($boxLeft, $boxTop, $boxRight, $boxBottom)
    $loopBox.CellsU("FillPattern").FormulaU  = "0"               # No fill
    $loopBox.CellsU("LinePattern").FormulaU  = "2"               # Dashed
    $loopBox.CellsU("LineColor").FormulaU    = "RGB(230,81,0)"   # Orange
    $loopBox.CellsU("LineWeight").FormulaU   = "2 pt"
    $loopBox.SendToBack()

    # Container label
    $loopLabel = $page.DrawRectangle($boxLeft, $boxTop, $boxLeft + 1.40, $boxTop + 0.30)
    $loopLabel.CellsU("FillPattern").FormulaU = "0"
    $loopLabel.CellsU("LinePattern").FormulaU = "0"
    $loopLabel.Text = "Game Loop Body"
    try { $loopLabel.Chars.CharProps(17) = 10; $loopLabel.Chars.CharProps(21) = "RGB(230,81,0)" } catch {}

    Write-Host "  OK Game loop box created" -ForegroundColor Green

    # ---- 7. Create all connectors (precise gluing) ----
    Write-Host "[6/7] Creating connectors..." -ForegroundColor Yellow

    # --- Main flow ---
    $c01 = AddConn $shStart    $shM1       ""         80  80  80  1.5
    $c02 = AddConn $shM1       $shM6Idle   ""         80  80  80  1.5
    $c03 = AddConn $shM6Idle   $shDecStart ""         80  80  80  1.5

    # Decision start? -> Yes (down) to GAMING
    $c04 = AddConn $shDecStart $shGaming   "Yes"      67 160 71  1.5

    # Decision start? -> No (loop back left to model6 IDLE)
    $c04b = $page.Drop($mConnector, 0, 0)
    $c04b.CellsU("BeginX").GlueTo($shDecStart.CellsU("PinX"))
    $c04b.CellsU("BeginY").GlueTo($shDecStart.CellsU("PinY"))
    $c04b.CellsU("EndX").GlueTo($shM6Idle.CellsU("PinX"))
    $c04b.CellsU("EndY").GlueTo($shM6Idle.CellsU("PinY"))
    $c04b.CellsU("LineColor").FormulaU   = "RGB(229,57,53)"
    $c04b.CellsU("LineWeight").FormulaU  = "1.5 pt"
    $c04b.CellsU("LinePattern").FormulaU = "3"   # Dashed
    $c04b.Text = "No"

    $c05 = AddConn $shGaming   $shScoreClr ""         80  80  80  1.5
    $c06 = AddConn $shScoreClr $shM2        ""         80  80  80  1.5

    # --- Game loop internal ---
    $c07 = AddConn $shM2       $shM4       "new_col[7:0]"  80 80 80 1.3
    $c08 = AddConn $shM4       $shM3       "obs_pos[7:0]"  80 80 80 1.3
    $c09 = AddConn $shM3       $shM5       "car_row[2:0]"  80 80 80 1.3
    $c10 = AddConn $shM5       $shDecColl  ""              80 80 80 1.3

    # Collision? No -> model7 score
    $c11 = AddConn $shDecColl  $shM7Score  "No"            67 160 71 1.3

    # model7 -> model8
    $c12 = AddConn $shM7Score  $shM8Led    ""              80 80 80 1.3

    # model8 -> loop back to model2 (right side around)
    $cLoopBack = $page.Drop($mConnector, 0, 0)
    $cLoopBack.CellsU("BeginX").GlueTo($shM8Led.CellsU("PinX"))
    $cLoopBack.CellsU("BeginY").GlueTo($shM8Led.CellsU("PinY"))
    $cLoopBack.CellsU("EndX").GlueTo($shM2.CellsU("PinX"))
    $cLoopBack.CellsU("EndY").GlueTo($shM2.CellsU("PinY"))
    $cLoopBack.CellsU("LineColor").FormulaU   = "RGB(100,100,100)"
    $cLoopBack.CellsU("LineWeight").FormulaU  = "1.5 pt"
    $cLoopBack.CellsU("LinePattern").FormulaU = "2"   # Dashed
    $cLoopBack.Text = "Next Game Tick"

    # --- Collision YES branch ---
    $cHit = $page.Drop($mConnector, 0, 0)
    $cHit.CellsU("BeginX").GlueTo($shDecColl.CellsU("PinX"))
    $cHit.CellsU("BeginY").GlueTo($shDecColl.CellsU("PinY"))
    $cHit.CellsU("EndX").GlueTo($shGameOver.CellsU("PinX"))
    $cHit.CellsU("EndY").GlueTo($shGameOver.CellsU("PinY"))
    $cHit.CellsU("LineColor").FormulaU   = "RGB(198,40,40)"
    $cHit.CellsU("LineWeight").FormulaU  = "2.5 pt"
    $cHit.Text = "YES - HIT!"

    $c13 = AddConn $shGameOver $shGS        ""         80 80 80 1.5
    $c14 = AddConn $shGS       $shDecRestart ""        80 80 80 1.5

    # Restart? Yes -> back to GAMING
    $cRestartY = $page.Drop($mConnector, 0, 0)
    $cRestartY.CellsU("BeginX").GlueTo($shDecRestart.CellsU("PinX"))
    $cRestartY.CellsU("BeginY").GlueTo($shDecRestart.CellsU("PinY"))
    $cRestartY.CellsU("EndX").GlueTo($shGaming.CellsU("PinX"))
    $cRestartY.CellsU("EndY").GlueTo($shGaming.CellsU("PinY"))
    $cRestartY.CellsU("LineColor").FormulaU   = "RGB(67,160,71)"
    $cRestartY.CellsU("LineWeight").FormulaU  = "2.0 pt"
    $cRestartY.Text = "Yes"

    # Restart? No -> stay at GameState
    $cRestartN = $page.Drop($mConnector, 0, 0)
    $cRestartN.CellsU("BeginX").GlueTo($shDecRestart.CellsU("PinX"))
    $cRestartN.CellsU("BeginY").GlueTo($shDecRestart.CellsU("PinY"))
    $cRestartN.CellsU("EndX").GlueTo($shGS.CellsU("PinX"))
    $cRestartN.CellsU("EndY").GlueTo($shGS.CellsU("PinY"))
    $cRestartN.CellsU("LineColor").FormulaU   = "RGB(229,57,53)"
    $cRestartN.CellsU("LineWeight").FormulaU  = "1.5 pt"
    $cRestartN.CellsU("LinePattern").FormulaU = "3"
    $cRestartN.Text = "No"

    Write-Host "  OK Connectors created" -ForegroundColor Green

    # ---- 8. Save ----
    Write-Host "[7/7] Saving file..." -ForegroundColor Yellow
    $savePath = "c:\Users\17740\Desktop\digital\SystemWorkflowChart.vsdx"

    if (Test-Path $savePath) {
        Remove-Item $savePath -Force
    }

    $doc.SaveAs($savePath)
    Write-Host "  OK File saved: $savePath" -ForegroundColor Green

    # ---- Done ----
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Drawing Complete!" -ForegroundColor Cyan
    Write-Host "  File: $savePath" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Visio window stays open for manual adjustments." -ForegroundColor White

} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ERROR: $_" -ForegroundColor Red
    Write-Host "  Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    if ($visio) { Write-Host "Visio kept open for debugging." -ForegroundColor Yellow }
    exit 1
}
