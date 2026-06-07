# ============================================================
# System Workflow Chart - Visio COM vFinal
# No functions, verbose, inline-only, robust waits
# ============================================================
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  System Workflow Chart - Final" -ForegroundColor Cyan
Write-Host "========================================"

# Clean-kill any leftover Visio
Write-Host "[Clean] Killing Visio..." -ForegroundColor Yellow
Get-Process VISIO -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 4
Write-Host "[Clean] Done" -ForegroundColor Green

# Launch Visio
Write-Host "[1] Launching Visio..." -ForegroundColor Yellow
$visio = New-Object -ComObject Visio.Application
$visio.Visible = $false
$visio.ShowChanges = $false
$visio.AlertResponse = 1
Start-Sleep -Seconds 3
Write-Host "[1] OK" -ForegroundColor Green

# Create document
Write-Host "[2] Creating document..." -ForegroundColor Yellow
$doc = $visio.Documents.Add("")
$page = $visio.ActivePage
$page.Name = "WorkflowChart"
$page.PageSheet.CellsU("PageWidth").ResultIU  = 12.0
$page.PageSheet.CellsU("PageHeight").ResultIU = 16.0

# Open stencil with delay
$stencilPath = "C:\Program Files\Microsoft Office\root\Office16\Visio Content\2052\BASFLO_M.VSSX"
Write-Host "[2] Opening stencil: $stencilPath"
$stencil = $visio.Documents.OpenEx($stencilPath, 64)
Start-Sleep -Seconds 3
Write-Host "[2] Stencil Masters:" $stencil.Masters.Count -ForegroundColor Green

# Get masters with retry
Write-Host "[3] Getting masters..." -ForegroundColor Yellow
$mProcess   = $null
$mDecision  = $null
$mStartEnd  = $null
$mConnector = $null

for ($retry = 0; $retry -lt 5; $retry++) {
    try {
        if ($null -eq $mProcess)   { $mProcess   = $stencil.Masters.ItemU("Process") }
        if ($null -eq $mDecision)  { $mDecision  = $stencil.Masters.ItemU("Decision") }
        if ($null -eq $mStartEnd)  { $mStartEnd  = $stencil.Masters.ItemU("Start/End") }
        if ($null -eq $mConnector) { $mConnector = $stencil.Masters.ItemU("Dynamic connector") }
        if ($mProcess -and $mDecision -and $mStartEnd -and $mConnector) {
            Write-Host "[3] All masters OK" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "[3] Retry $retry ..."
        Start-Sleep -Seconds 2
    }
}

if (-not $mProcess -or -not $mDecision -or -not $mStartEnd -or -not $mConnector) {
    throw "Failed to get masters after retries!"
}

# ============================================================
# INLINE shape creation - no functions, proven to work
# ============================================================
Write-Host "[4] Creating shapes..." -ForegroundColor Yellow

$CX = 6.0  # Main flow center X

# --- Helper: set shape style ---
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

# ---- Row 1: Start ----
Write-Host "  Shape [1/16] Start..."
$sh1 = $page.Drop($mStartEnd, $CX, 0.65)
$sh1.CellsU("Width").ResultIU = 1.50; $sh1.CellsU("Height").ResultIU = 0.45
$sh1.CellsU("PinX").ResultIU = $CX; $sh1.CellsU("PinY").ResultIU = 0.65
$sh1.Text = "System Power-On / Reset"
StyleShape $sh1 67 160 71 46 125 50 2.0
ShapeFont $sh1 11 255 255 255
Write-Host "  Shape [1/16] OK" -ForegroundColor Gray

# ---- Row 2: model1 ----
Write-Host "  Shape [2/16] model1..."
$sh2 = $page.Drop($mProcess, $CX, 1.80)
$sh2.CellsU("Width").ResultIU = 2.60; $sh2.CellsU("Height").ResultIU = 0.60
$sh2.CellsU("PinX").ResultIU = $CX; $sh2.CellsU("PinY").ResultIU = 1.80
$sh2.Text = "model1 Clock Divider~Generate clocks for all modules"
StyleShape $sh2 187 222 251 21 101 192 1.8
ShapeFont $sh2 10 13 71 161
Write-Host "  Shape [2/16] OK" -ForegroundColor Gray

# ---- Row 3: model6 IDLE ----
Write-Host "  Shape [3/16] model6 IDLE..."
$sh3 = $page.Drop($mProcess, $CX, 3.00)
$sh3.CellsU("Width").ResultIU = 2.60; $sh3.CellsU("Height").ResultIU = 0.60
$sh3.CellsU("PinX").ResultIU = $CX; $sh3.CellsU("PinY").ResultIU = 3.00
$sh3.Text = "model6 FSM -> IDLE~Wait for player START"
StyleShape $sh3 225 190 231 106 27 154 1.8
ShapeFont $sh3 10 74 20 140
Write-Host "  Shape [3/16] OK" -ForegroundColor Gray

# ---- Row 4: Decision start? ----
Write-Host "  Shape [4/16] Decision start?..."
$sh4 = $page.Drop($mDecision, $CX, 4.20)
$sh4.CellsU("Width").ResultIU = 1.50; $sh4.CellsU("Height").ResultIU = 0.70
$sh4.CellsU("PinX").ResultIU = $CX; $sh4.CellsU("PinY").ResultIU = 4.20
$sh4.Text = "start?~Player pressed START?"
StyleShape $sh4 255 249 196 249 168 37 1.8
ShapeFont $sh4 10 230 81 0
Write-Host "  Shape [4/16] OK" -ForegroundColor Gray

# ---- Row 5: GAMING ----
Write-Host "  Shape [5/16] GAMING..."
$sh5 = $page.Drop($mProcess, $CX, 5.55)
$sh5.CellsU("Width").ResultIU = 2.60; $sh5.CellsU("Height").ResultIU = 0.60
$sh5.CellsU("PinX").ResultIU = $CX; $sh5.CellsU("PinY").ResultIU = 5.55
$sh5.Text = "FSM -> GAMING~Begin game loop"
StyleShape $sh5 200 230 201 56 142 60 2.0
ShapeFont $sh5 10 27 94 32
Write-Host "  Shape [5/16] OK" -ForegroundColor Gray

# ---- Row 6: Score clear ----
Write-Host "  Shape [6/16] Score Clear..."
$sh6 = $page.Drop($mProcess, $CX, 6.70)
$sh6.CellsU("Width").ResultIU = 2.60; $sh6.CellsU("Height").ResultIU = 0.60
$sh6.CellsU("PinX").ResultIU = $CX; $sh6.CellsU("PinY").ResultIU = 6.70
$sh6.Text = "model7 Score Counter Reset"
StyleShape $sh6 178 223 219 0 105 92 1.8
ShapeFont $sh6 10 0 77 64
Write-Host "  Shape [6/16] OK" -ForegroundColor Gray

# ---- Game Loop Row 1 (y=8.30) ----
$ly1 = 8.30; $ly2 = 9.60; $ly3 = 10.80

Write-Host "  Shape [7/16] model2..."
$g1 = $page.Drop($mProcess, 2.00, $ly1)
$g1.CellsU("Width").ResultIU = 1.70; $g1.CellsU("Height").ResultIU = 0.55
$g1.CellsU("PinX").ResultIU = 2.00; $g1.CellsU("PinY").ResultIU = $ly1
$g1.Text = "model2~Generate Random Obstacle"
StyleShape $g1 200 230 201 46 125 50 1.6
ShapeFont $g1 9 27 94 32

Write-Host "  Shape [8/16] model4..."
$g2 = $page.Drop($mProcess, 4.00, $ly1)
$g2.CellsU("Width").ResultIU = 1.70; $g2.CellsU("Height").ResultIU = 0.55
$g2.CellsU("PinX").ResultIU = 4.00; $g2.CellsU("PinY").ResultIU = $ly1
$g2.Text = "model4~Shift Obstacle Left"
StyleShape $g2 165 214 167 46 125 50 1.6
ShapeFont $g2 9 27 94 32

Write-Host "  Shape [9/16] model3..."
$g3 = $page.Drop($mProcess, 6.00, $ly1)
$g3.CellsU("Width").ResultIU = 1.70; $g3.CellsU("Height").ResultIU = 0.55
$g3.CellsU("PinX").ResultIU = 6.00; $g3.CellsU("PinY").ResultIU = $ly1
$g3.Text = "model3~Read Player Input(Up/Down)"
StyleShape $g3 255 249 196 249 168 37 1.6
ShapeFont $g3 9 230 81 0

Write-Host "  Shape [10/16] model5..."
$g4 = $page.Drop($mProcess, 8.00, $ly1)
$g4.CellsU("Width").ResultIU = 1.70; $g4.CellsU("Height").ResultIU = 0.55
$g4.CellsU("PinX").ResultIU = 8.00; $g4.CellsU("PinY").ResultIU = $ly1
$g4.Text = "model5~Collision Detection"
StyleShape $g4 255 204 188 191 54 12 1.6
ShapeFont $g4 9 191 54 12

Write-Host "  Shape [11/16] Decision Collision?..."
$g5 = $page.Drop($mDecision, 8.00, $ly2)
$g5.CellsU("Width").ResultIU = 1.20; $g5.CellsU("Height").ResultIU = 0.60
$g5.CellsU("PinX").ResultIU = 8.00; $g5.CellsU("PinY").ResultIU = $ly2
$g5.Text = "Collision?"
StyleShape $g5 255 249 196 249 168 37 1.6
ShapeFont $g5 9 230 81 0

Write-Host "  Shape [12/16] model7 Score..."
$g6 = $page.Drop($mProcess, 9.80, $ly2)
$g6.CellsU("Width").ResultIU = 1.50; $g6.CellsU("Height").ResultIU = 0.50
$g6.CellsU("PinX").ResultIU = 9.80; $g6.CellsU("PinY").ResultIU = $ly2
$g6.Text = "model7 Score +1"
StyleShape $g6 178 223 219 0 105 92 1.5
ShapeFont $g6 9 0 77 64

Write-Host "  Shape [13/16] model8 LED..."
$g7 = $page.Drop($mProcess, 9.80, $ly3)
$g7.CellsU("Width").ResultIU = 1.50; $g7.CellsU("Height").ResultIU = 0.50
$g7.CellsU("PinX").ResultIU = 9.80; $g7.CellsU("PinY").ResultIU = $ly3
$g7.Text = "model8~Refresh LED Matrix"
StyleShape $g7 255 224 178 230 81 0 1.5
ShapeFont $g7 9 191 54 12

# ---- GAMEOVER branch (left side) ----
Write-Host "  Shape [14/16] GAMEOVER..."
$e1 = $page.Drop($mProcess, 2.80, 12.20)
$e1.CellsU("Width").ResultIU = 1.70; $e1.CellsU("Height").ResultIU = 0.55
$e1.CellsU("PinX").ResultIU = 2.80; $e1.CellsU("PinY").ResultIU = 12.20
$e1.Text = "GAMEOVER~Game Over"
StyleShape $e1 229 57 53 198 40 40 2.0
ShapeFont $e1 10 255 255 255

Write-Host "  Shape [15/16] GameState..."
$e2 = $page.Drop($mProcess, 2.80, 13.40)
$e2.CellsU("Width").ResultIU = 1.70; $e2.CellsU("Height").ResultIU = 0.55
$e2.CellsU("PinX").ResultIU = 2.80; $e2.CellsU("PinY").ResultIU = 13.40
$e2.Text = "GameState~Display GAMEOVER"
StyleShape $e2 237 231 246 123 31 162 1.8
ShapeFont $e2 10 74 20 140

Write-Host "  Shape [16/16] Restart?..."
$e3 = $page.Drop($mDecision, 2.80, 14.60)
$e3.CellsU("Width").ResultIU = 1.50; $e3.CellsU("Height").ResultIU = 0.70
$e3.CellsU("PinX").ResultIU = 2.80; $e3.CellsU("PinY").ResultIU = 14.60
$e3.Text = "Restart?"
StyleShape $e3 255 249 196 249 168 37 1.8
ShapeFont $e3 10 230 81 0

Write-Host "[4] All 16 shapes created!" -ForegroundColor Green

# ---- Game Loop Container Box ----
Write-Host "[5] Creating loop container..." -ForegroundColor Yellow
$boxLeft = 0.60; $boxTop = 7.50; $boxRight = 11.20; $boxBottom = 11.50
$loopBox = $page.DrawRectangle($boxLeft, $boxTop, $boxRight, $boxBottom)
$loopBox.CellsU("FillPattern").FormulaU = "0"
$loopBox.CellsU("LinePattern").FormulaU = "2"
$loopBox.CellsU("LineColor").FormulaU   = "RGB(230,81,0)"
$loopBox.CellsU("LineWeight").FormulaU  = "2 pt"
$loopBox.SendToBack()

$loopLabel = $page.DrawRectangle($boxLeft, $boxTop, $boxLeft + 1.40, $boxTop + 0.30)
$loopLabel.CellsU("FillPattern").FormulaU = "0"
$loopLabel.CellsU("LinePattern").FormulaU = "0"
$loopLabel.Text = "Game Loop Body"
try { $loopLabel.CellsU("Char.Size").FormulaU = "10 pt"; $loopLabel.CellsU("Char.Color").FormulaU = "RGB(230,81,0)" } catch {}
Write-Host "[5] OK" -ForegroundColor Green

# ---- Connectors ----
Write-Host "[6] Creating connectors..." -ForegroundColor Yellow

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

Write-Host "  Connectors [1-6] main flow..."
$c01 = MakeConn $sh1 $sh2 80 80 80 1.5 $false ""
$c02 = MakeConn $sh2 $sh3 80 80 80 1.5 $false ""
$c03 = MakeConn $sh3 $sh4 80 80 80 1.5 $false ""
$c04 = MakeConn $sh4 $sh5 67 160 71 1.5 $false "Yes"
$c04b = MakeConn $sh4 $sh3 229 57 53 1.5 $true "No"
$c05 = MakeConn $sh5 $sh6 80 80 80 1.5 $false ""

Write-Host "  Connectors [7-12] game loop..."
$c06 = MakeConn $sh6 $g1 80 80 80 1.5 $false ""
$c07 = MakeConn $g1 $g2 80 80 80 1.3 $false "new_col[7:0]"
$c08 = MakeConn $g2 $g3 80 80 80 1.3 $false "obs_pos[7:0]"
$c09 = MakeConn $g3 $g4 80 80 80 1.3 $false "car_row[2:0]"
$c10 = MakeConn $g4 $g5 80 80 80 1.3 $false ""
$c11 = MakeConn $g5 $g6 67 160 71 1.3 $false "No"

Write-Host "  Connectors [13-18] branches..."
$c12 = MakeConn $g6 $g7 80 80 80 1.3 $false ""

# Loop back: model8 -> model2 (dashed)
$cLoop = $page.Drop($mConnector, 0, 0)
$cLoop.CellsU("BeginX").GlueTo($g7.CellsU("PinX"))
$cLoop.CellsU("BeginY").GlueTo($g7.CellsU("PinY"))
$cLoop.CellsU("EndX").GlueTo($g1.CellsU("PinX"))
$cLoop.CellsU("EndY").GlueTo($g1.CellsU("PinY"))
$cLoop.CellsU("LineColor").FormulaU  = "RGB(100,100,100)"
$cLoop.CellsU("LineWeight").FormulaU = "1.5 pt"
$cLoop.CellsU("LinePattern").FormulaU = "2"
$cLoop.Text = "Next Game Tick"

# Collision YES -> GAMEOVER
$cHit = $page.Drop($mConnector, 0, 0)
$cHit.CellsU("BeginX").GlueTo($g5.CellsU("PinX"))
$cHit.CellsU("BeginY").GlueTo($g5.CellsU("PinY"))
$cHit.CellsU("EndX").GlueTo($e1.CellsU("PinX"))
$cHit.CellsU("EndY").GlueTo($e1.CellsU("PinY"))
$cHit.CellsU("LineColor").FormulaU  = "RGB(198,40,40)"
$cHit.CellsU("LineWeight").FormulaU = "2.5 pt"
$cHit.Text = "YES - HIT!"

$c13 = MakeConn $e1 $e2 80 80 80 1.5 $false ""
$c14 = MakeConn $e2 $e3 80 80 80 1.5 $false ""

# Restart? Yes -> GAMING (green)
$cRestartY = $page.Drop($mConnector, 0, 0)
$cRestartY.CellsU("BeginX").GlueTo($e3.CellsU("PinX"))
$cRestartY.CellsU("BeginY").GlueTo($e3.CellsU("PinY"))
$cRestartY.CellsU("EndX").GlueTo($sh5.CellsU("PinX"))
$cRestartY.CellsU("EndY").GlueTo($sh5.CellsU("PinY"))
$cRestartY.CellsU("LineColor").FormulaU  = "RGB(67,160,71)"
$cRestartY.CellsU("LineWeight").FormulaU = "2.0 pt"
$cRestartY.Text = "Yes"

# Restart? No -> stay GameState (dashed)
$cRestartN = $page.Drop($mConnector, 0, 0)
$cRestartN.CellsU("BeginX").GlueTo($e3.CellsU("PinX"))
$cRestartN.CellsU("BeginY").GlueTo($e3.CellsU("PinY"))
$cRestartN.CellsU("EndX").GlueTo($e2.CellsU("PinX"))
$cRestartN.CellsU("EndY").GlueTo($e2.CellsU("PinY"))
$cRestartN.CellsU("LineColor").FormulaU  = "RGB(229,57,53)"
$cRestartN.CellsU("LineWeight").FormulaU = "1.5 pt"
$cRestartN.CellsU("LinePattern").FormulaU = "3"
$cRestartN.Text = "No"

Write-Host "[6] All connectors done!" -ForegroundColor Green

# ---- Save ----
Write-Host "[7] Saving..." -ForegroundColor Yellow
$savePath = "c:\Users\17740\Desktop\digital\SystemWorkflowChart.vsdx"
if (Test-Path $savePath) { Remove-Item $savePath -Force }
$doc.SaveAs($savePath)
Write-Host "[7] Saved: $savePath" -ForegroundColor Green

# Show Visio
$visio.ShowChanges = $true
$visio.Visible = $true

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  COMPLETE!" -ForegroundColor Cyan
Write-Host "  File: $savePath" -ForegroundColor Cyan
Write-Host "========================================"
