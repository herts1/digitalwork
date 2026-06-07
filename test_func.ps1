# Test: does function wrapping cause hang?
Get-Process VISIO -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

$visio = New-Object -ComObject Visio.Application
$visio.Visible = $false
$visio.ShowChanges = $false
$visio.AlertResponse = 1
Start-Sleep -Seconds 1

$doc = $visio.Documents.Add("")
$page = $visio.ActivePage
$page.PageSheet.CellsU("PageWidth").ResultIU = 12.0
$page.PageSheet.CellsU("PageHeight").ResultIU = 16.0

$stencilPath = 'C:\Program Files\Microsoft Office\root\Office16\Visio Content\2052\BASFLO_M.VSSX'
$stencil = $visio.Documents.OpenEx($stencilPath, 64)

$mProcess  = $stencil.Masters.ItemU('Process')
$mDecision = $stencil.Masters.ItemU('Decision')
$mStartEnd = $stencil.Masters.ItemU('Start/End')
$mConnector = $stencil.Masters.ItemU('Dynamic connector')

Write-Host "Defining AddShape function..."
function AddShape($master, $x, $y, $w, $h, $text) {
    Write-Host "  AddShape ENTER: $text"
    $s = $page.Drop($master, $x, $y)
    Write-Host "  AddShape DROP OK"
    $s.CellsU("Width").ResultIU  = $w
    $s.CellsU("Height").ResultIU = $h
    $s.CellsU("PinX").ResultIU   = $x
    $s.CellsU("PinY").ResultIU   = $y
    Write-Host "  AddShape SIZE OK"
    $s.Text = $text
    Write-Host "  AddShape TEXT OK"
    $s.CellsU("FillForegnd").FormulaU = "RGB(200,230,201)"
    $s.CellsU("FillBkgnd").FormulaU   = "RGB(200,230,201)"
    $s.CellsU("FillPattern").FormulaU = "1"
    Write-Host "  AddShape FILL OK"
    try {
        $c = $s.Characters; $c.Begin = 0; $c.End = $s.CharCount
        $c.CharProps(17) = 10; $c.CharProps(21) = "RGB(0,0,0)"; $c.CharProps(1) = 1
        Write-Host "  AddShape FONT OK"
    } catch {
        Write-Host "  AddShape FONT FAIL: $_"
    }
    Write-Host "  AddShape EXIT: $text"
    return $s
}

Write-Host "Calling AddShape #1..."
$s1 = AddShape $mStartEnd 6.0 1.0 1.5 0.45 "Test 1"
Write-Host "AddShape #1 returned"

Write-Host "Calling AddShape #2..."
$s2 = AddShape $mProcess 6.0 2.0 2.6 0.6 "Test 2"
Write-Host "AddShape #2 returned"

Write-Host "Calling AddShape #3..."
$s3 = AddShape $mDecision 6.0 3.0 1.5 0.7 "Test 3"
Write-Host "AddShape #3 returned"

Write-Host "ALL DONE - Saving..."
$savePath = 'c:\Users\17740\Desktop\digital\test_func.vsdx'
if (Test-Path $savePath) { Remove-Item $savePath -Force }
$doc.SaveAs($savePath)
Write-Host "Saved: $savePath"

$visio.Visible = $true
$visio.ShowChanges = $true
Write-Host "DONE"
