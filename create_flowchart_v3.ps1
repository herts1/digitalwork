# ============================================================
# System Workflow Chart - Visio COM Automation v3
# Fixed: hidden mode + ShowChanges off to avoid UI hang
# ============================================================
$ErrorActionPreference = "Stop"

try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  System Workflow Chart - Visio v3" -ForegroundColor Cyan
    Write-Host "========================================"

    # ---- Kill old instances ----
    Get-Process VISIO -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2

    # ---- 1. Launch Visio in HIDDEN mode ----
    Write-Host "[1/6] Launching Visio (hidden)..." -ForegroundColor Yellow
    $visio = New-Object -ComObject Visio.Application
    $visio.Visible = $false
    $visio.ShowChanges = $false
    $visio.AlertResponse = 1
    Start-Sleep -Seconds 1
    Write-Host "  OK" -ForegroundColor Green

    # ---- 2. Create doc + open stencil ----
    Write-Host "[2/6] Creating document..." -ForegroundColor Yellow
    $doc = $visio.Documents.Add("")
    $page = $visio.ActivePage
    $page.Name = "SystemWorkflowChart"
    $page.PageSheet.CellsU("PageWidth").ResultIU  = 12.0
    $page.PageSheet.CellsU("PageHeight").ResultIU = 16.0

    $stencilPath = "C:\Program Files\Microsoft Office\root\Office16\Visio Content\2052\BASFLO_M.VSSX"
    if (-not (Test-Path $stencilPath)) {
        $stencilPath = "C:\Program Files\Microsoft Office\root\Office16\Visio Content\1033\BASFLO_M.VSSX"
    }
    $stencil = $visio.Documents.OpenEx($stencilPath, 64)
    Write-Host "  OK - Stencil loaded, page 12x16 inches" -ForegroundColor Green

    # ---- 3. Get masters ----
    Write-Host "[3/6] Getting masters..." -ForegroundColor Yellow
    $mProcess   = $stencil.Masters.ItemU("Process")
    $mDecision  = $stencil.Masters.ItemU("Decision")
    $mStartEnd  = $stencil.Masters.ItemU("Start/End")
    $mConnector = $stencil.Masters.ItemU("Dynamic connector")
    Write-Host "  OK - All 4 masters ready" -ForegroundColor Green

    # ---- Helper functions ----
    function AddShape($master, $x, $y, $w, $h, $text, $fr, $fg, $fb, $lr, $lg, $lb, $lw, $fs, $cr, $cg, $cb) {
        $s = $page.Drop($master, $x, $y)
        $s.CellsU("Width").ResultIU  = $w
        $s.CellsU("Height").ResultIU = $h
        $s.CellsU("PinX").ResultIU   = $x
        $s.CellsU("PinY").ResultIU   = $y
        $s.Text = $text
        # Fill
        $s.CellsU("FillForegnd").FormulaU = "RGB($fr,$fg,$fb)"
        $s.CellsU("FillBkgnd").FormulaU   = "RGB($fr,$fg,$fb)"
        $s.CellsU("FillPattern").FormulaU = "1"
        # Line
        $s.CellsU("LineColor").FormulaU  = "RGB($lr,$lg,$lb)"
        $s.CellsU("LineWeight").FormulaU = "${lw} pt"
        # Font (bold + color + size)
        try {
            $c = $s.Characters; $c.Begin = 0; $c.End = $s.CharCount
            $c.CharProps(17) = $fs; $c.CharProps(21) = "RGB($cr,$cg,$cb)"; $c.CharProps(1) = 1
        } catch {}
        return $s
    }

    function AddConn($src, $tgt, $label, $lr, $lg, $lb, $lw, $dashed) {
        $conn = $page.Drop($mConnector, 0, 0)
        $conn.CellsU("BeginX").GlueTo($src.CellsU("PinX"))
        $conn.CellsU("BeginY").GlueTo($src.CellsU("PinY"))
        $conn.CellsU("EndX").GlueTo($tgt.CellsU("PinX"))
        $conn.CellsU("EndY").GlueTo($tgt.CellsU("PinY"))
        $conn.CellsU("LineColor").FormulaU  = "RGB($lr,$lg,$lb)"
        $conn.CellsU("LineWeight").FormulaU = "${lw} pt"
        if ($dashed) {
            $conn.CellsU("LinePattern").FormulaU = "3"
        }
        if ($label) {
            try { $conn.Text = $label; $conn.CellsU("Char.Size").FormulaU = "9 pt"; $conn.CellsU("Char.Color").FormulaU = "RGB($lr,$lg,$lb)" } catch {}
        }
        return $conn
    }

    # ---- 4. Create ALL shapes ----
    Write-Host "[4/6] Creating shapes..." -ForegroundColor Yellow
    $CX = 6.0   # Main flow center X

    # Row 1: Start
    $s1  = AddShape $mStartEnd $CX 0.65  1.50 0.45 "System Power-On / Reset"  67 160 71  46 125 50 2.0  11 255 255 255

    # Row 2: model1
    $s2  = AddShape $mProcess  $CX 1.80  2.60 0.60 "model1 Clock Divider~Generate clocks for all modules"  187 222 251  21 101 192 1.8  10 13 71 161

    # Row 3: model6 IDLE
    $s3  = AddShape $mProcess  $CX 3.00  2.60 0.60 "model6 FSM -> IDLE~Wait for player START"  225 190 231  106 27 154 1.8  10 74 20 140

    # Row 4: Decision start?
    $s4  = AddShape $mDecision $CX 4.20  1.50 0.70 "start?~Player pressed START?"  255 249 196  249 168 37 1.8  10 230 81 0

    # Row 5: GAMING
    $s5  = AddShape $mProcess  $CX 5.55  2.60 0.60 "FSM -> GAMING~Begin game loop"  200 230 201  56 142 60 2.0  10 27 94 32

    # Row 6: Score clear
    $s6  = AddShape $mProcess  $CX 6.70  2.60 0.60 "model7 Score Counter Reset"  178 223 219  0 105 92 1.8  10 0 77 64

    Write-Host "  Main flow shapes done" -ForegroundColor Gray

    # --- Game loop internal shapes ---
    $ly1 = 8.30
    $ly2 = 9.60
    $ly3 = 10.80

    $g1  = AddShape $mProcess  2.00 $ly1  1.70 0.55 "model2~Generate Random Obstacle"   200 230 201  46 125 50 1.6  9 27 94 32
    $g2  = AddShape $mProcess  4.00 $ly1  1.70 0.55 "model4~Shift Obstacle Left"        165 214 167  46 125 50 1.6  9 27 94 32
    $g3  = AddShape $mProcess  6.00 $ly1  1.70 0.55 "model3~Read Player Input(Up/Down)"  255 249 196  249 168 37 1.6  9 230 81 0
    $g4  = AddShape $mProcess  8.00 $ly1  1.70 0.55 "model5~Collision Detection"         255 204 188  191 54 12 1.6  9 191 54 12

    $g5  = AddShape $mDecision 8.00 $ly2  1.20 0.60 "Collision?"                         255 249 196  249 168 37 1.6  9 230 81 0
    $g6  = AddShape $mProcess  9.80 $ly2  1.50 0.50 "model7 Score +1"                    178 223 219  0 105 92 1.5  9 0 77 64
    $g7  = AddShape $mProcess  9.80 $ly3  1.50 0.50 "model8~Refresh LED Matrix"          255 224 178  230 81 0 1.5  9 191 54 12

    Write-Host "  Game loop shapes done" -ForegroundColor Gray

    # --- GAMEOVER branch (left) ---
    $e1  = AddShape $mProcess  2.80 12.20  1.70 0.55 "GAMEOVER~Game Over"           229 57 53  198 40 40 2.0  10 255 255 255
    $e2  = AddShape $mProcess  2.80 13.40  1.70 0.55 "GameState~Display GAMEOVER"    237 231 246  123 31 162 1.8  10 74 20 140
    $e3  = AddShape $mDecision 2.80 14.60  1.50 0.70 "Restart?"                      255 249 196  249 168 37 1.8  10 230 81 0

    Write-Host "  GAMEOVER branch shapes done" -ForegroundColor Gray

    # ---- Game loop background box ----
    Write-Host "  Creating loop container..." -ForegroundColor Gray
    $boxLeft=0.60; $boxTop=7.50; $boxRight=11.20; $boxBottom=11.50
    $loopBox = $page.DrawRectangle($boxLeft, $boxTop, $boxRight, $boxBottom)
    $loopBox.CellsU("FillPattern").FormulaU = "0"
    $loopBox.CellsU("LinePattern").FormulaU = "2"
    $loopBox.CellsU("LineColor").FormulaU   = "RGB(230,81,0)"
    $loopBox.CellsU("LineWeight").FormulaU  = "2 pt"
    $loopBox.SendToBack()

    $loopLabel = $page.DrawRectangle($boxLeft, $boxTop, $boxLeft+1.40, $boxTop+0.30)
    $loopLabel.CellsU("FillPattern").FormulaU = "0"
    $loopLabel.CellsU("LinePattern").FormulaU = "0"
    $loopLabel.Text = "Game Loop Body"
    try { $loopLabel.Chars.CharProps(17)=10; $loopLabel.Chars.CharProps(21)="RGB(230,81,0)" } catch {}
    Write-Host "  OK" -ForegroundColor Green

    # ---- 5. Create ALL connectors ----
    Write-Host "[5/6] Creating connectors..." -ForegroundColor Yellow

    # Main vertical flow
    $c01 = AddConn $s1 $s2 ""   80 80 80 1.5 $false
    $c02 = AddConn $s2 $s3 ""   80 80 80 1.5 $false
    $c03 = AddConn $s3 $s4 ""   80 80 80 1.5 $false

    # start? Yes -> GAMING
    $c04 = AddConn $s4 $s5 "Yes" 67 160 71 1.5 $false

    # start? No -> loop back to IDLE (dashed)
    $c04b = $page.Drop($mConnector, 0, 0)
    $c04b.CellsU("BeginX").GlueTo($s4.CellsU("PinX"))
    $c04b.CellsU("BeginY").GlueTo($s4.CellsU("PinY"))
    $c04b.CellsU("EndX").GlueTo($s3.CellsU("PinX"))
    $c04b.CellsU("EndY").GlueTo($s3.CellsU("PinY"))
    $c04b.CellsU("LineColor").FormulaU  = "RGB(229,57,53)"
    $c04b.CellsU("LineWeight").FormulaU = "1.5 pt"
    $c04b.CellsU("LinePattern").FormulaU = "3"
    $c04b.Text = "No"

    $c05 = AddConn $s5 $s6 ""   80 80 80 1.5 $false
    $c06 = AddConn $s6 $g1 ""   80 80 80 1.5 $false

    # Game loop internal connections
    $c07 = AddConn $g1 $g2 "new_col[7:0]"  80 80 80 1.3 $false
    $c08 = AddConn $g2 $g3 "obs_pos[7:0]"  80 80 80 1.3 $false
    $c09 = AddConn $g3 $g4 "car_row[2:0]"  80 80 80 1.3 $false
    $c10 = AddConn $g4 $g5 ""              80 80 80 1.3 $false

    # Collision? No -> model7 score
    $c11 = AddConn $g5 $g6 "No"            67 160 71 1.3 $false
    # model7 -> model8
    $c12 = AddConn $g6 $g7 ""              80 80 80 1.3 $false

    # model8 -> loop back to model2 (dashed, right side around)
    $cLoop = $page.Drop($mConnector, 0, 0)
    $cLoop.CellsU("BeginX").GlueTo($g7.CellsU("PinX"))
    $cLoop.CellsU("BeginY").GlueTo($g7.CellsU("PinY"))
    $cLoop.CellsU("EndX").GlueTo($g1.CellsU("PinX"))
    $cLoop.CellsU("EndY").GlueTo($g1.CellsU("PinY"))
    $cLoop.CellsU("LineColor").FormulaU  = "RGB(100,100,100)"
    $cLoop.CellsU("LineWeight").FormulaU = "1.5 pt"
    $cLoop.CellsU("LinePattern").FormulaU = "2"
    $cLoop.Text = "Next Game Tick"

    # Collision? Yes -> GAMEOVER (red, bold)
    $cHit = $page.Drop($mConnector, 0, 0)
    $cHit.CellsU("BeginX").GlueTo($g5.CellsU("PinX"))
    $cHit.CellsU("BeginY").GlueTo($g5.CellsU("PinY"))
    $cHit.CellsU("EndX").GlueTo($e1.CellsU("PinX"))
    $cHit.CellsU("EndY").GlueTo($e1.CellsU("PinY"))
    $cHit.CellsU("LineColor").FormulaU  = "RGB(198,40,40)"
    $cHit.CellsU("LineWeight").FormulaU = "2.5 pt"
    $cHit.Text = "YES - HIT!"

    # GAMEOVER -> GameState -> Restart?
    $c13 = AddConn $e1 $e2 ""  80 80 80 1.5 $false
    $c14 = AddConn $e2 $e3 ""  80 80 80 1.5 $false

    # Restart? Yes -> back to GAMING (green)
    $cRestartY = $page.Drop($mConnector, 0, 0)
    $cRestartY.CellsU("BeginX").GlueTo($e3.CellsU("PinX"))
    $cRestartY.CellsU("BeginY").GlueTo($e3.CellsU("PinY"))
    $cRestartY.CellsU("EndX").GlueTo($s5.CellsU("PinX"))
    $cRestartY.CellsU("EndY").GlueTo($s5.CellsU("PinY"))
    $cRestartY.CellsU("LineColor").FormulaU  = "RGB(67,160,71)"
    $cRestartY.CellsU("LineWeight").FormulaU = "2.0 pt"
    $cRestartY.Text = "Yes"

    # Restart? No -> stay at GameState (dashed)
    $cRestartN = $page.Drop($mConnector, 0, 0)
    $cRestartN.CellsU("BeginX").GlueTo($e3.CellsU("PinX"))
    $cRestartN.CellsU("BeginY").GlueTo($e3.CellsU("PinY"))
    $cRestartN.CellsU("EndX").GlueTo($e2.CellsU("PinX"))
    $cRestartN.CellsU("EndY").GlueTo($e2.CellsU("PinY"))
    $cRestartN.CellsU("LineColor").FormulaU  = "RGB(229,57,53)"
    $cRestartN.CellsU("LineWeight").FormulaU = "1.5 pt"
    $cRestartN.CellsU("LinePattern").FormulaU = "3"
    $cRestartN.Text = "No"

    Write-Host "  OK - All connectors done" -ForegroundColor Green

    # ---- 6. Save and show ----
    Write-Host "[6/6] Saving..." -ForegroundColor Yellow
    $savePath = "c:\Users\17740\Desktop\digital\SystemWorkflowChart.vsdx"
    if (Test-Path $savePath) { Remove-Item $savePath -Force }
    $doc.SaveAs($savePath)
    Write-Host "  OK - Saved: $savePath" -ForegroundColor Green

    # Make Visio visible for review
    $visio.ShowChanges = $true
    $visio.Visible = $true

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  DRAWING COMPLETE!" -ForegroundColor Cyan
    Write-Host "  File: $savePath" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Visio is now visible for manual adjustments." -ForegroundColor White
    Write-Host "Close Visio when done reviewing." -ForegroundColor White

} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ERROR at line $($_.InvocationInfo.ScriptLineNumber): $_" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    if ($visio) {
        $visio.Visible = $true
        Write-Host "Visio kept open for debugging." -ForegroundColor Yellow
    }
    exit 1
}
