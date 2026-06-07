# Debug: step-by-step shape creation
Get-Process VISIO -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

$visio = New-Object -ComObject Visio.Application
$visio.Visible = $false
$visio.ShowChanges = $false
$visio.AlertResponse = 1
Start-Sleep -Seconds 1

Write-Host "Creating blank doc..."
$doc = $visio.Documents.Add("")
$page = $visio.ActivePage
$page.PageSheet.CellsU("PageWidth").ResultIU = 12.0
$page.PageSheet.CellsU("PageHeight").ResultIU = 16.0

$stencilPath = 'C:\Program Files\Microsoft Office\root\Office16\Visio Content\2052\BASFLO_M.VSSX'
Write-Host "Opening stencil..."
$stencil = $visio.Documents.OpenEx($stencilPath, 64)
Write-Host "Stencil opened. Masters: $($stencil.Masters.Count)"

Write-Host "Getting masters..."
$mProcess  = $stencil.Masters.ItemU('Process')
$mDecision = $stencil.Masters.ItemU('Decision')
$mStartEnd = $stencil.Masters.ItemU('Start/End')
Write-Host "Masters ready"

# Test 1: Drop Process
Write-Host "Test 1: Drop Process..."
try {
    $s = $page.Drop($mProcess, 6.0, 1.0)
    Write-Host "  OK"
    $s.Text = "Test Process"
    Write-Host "  Text set OK"
    $s.CellsU("Width").ResultIU = 2.0
    Write-Host "  Width set OK"
    $s.CellsU("Height").ResultIU = 0.6
    Write-Host "  Height set OK"
} catch {
    Write-Host "  FAIL: $_"
}

# Test 2: Drop Start/End
Write-Host "Test 2: Drop Start/End..."
try {
    $s2 = $page.Drop($mStartEnd, 6.0, 2.0)
    Write-Host "  OK"
    $s2.Text = "Test StartEnd"
    Write-Host "  Text set OK"
} catch {
    Write-Host "  FAIL: $_"
}

# Test 3: Drop Decision
Write-Host "Test 3: Drop Decision..."
try {
    $s3 = $page.Drop($mDecision, 6.0, 3.0)
    Write-Host "  OK"
    $s3.Text = "Test Decision"
    Write-Host "  Text set OK"
} catch {
    Write-Host "  FAIL: $_"
}

# Test 4: Multiple shapes
Write-Host "Test 4: Creating 10 Process shapes..."
try {
    for ($i = 0; $i -lt 10; $i++) {
        $y = 4.0 + $i * 0.7
        $sh = $page.Drop($mProcess, 6.0, $y)
        $sh.Text = "Shape $i"
        Write-Host "  Shape $i OK"
    }
    Write-Host "  All 10 OK"
} catch {
    Write-Host "  FAIL at shape $i : $_"
}

Write-Host "Saving..."
$savePath = 'c:\Users\17740\Desktop\digital\debug_test.vsdx'
if (Test-Path $savePath) { Remove-Item $savePath -Force }
$doc.SaveAs($savePath)
Write-Host "Saved: $savePath"

$visio.Visible = $true
$visio.ShowChanges = $true
Write-Host "DONE - check Visio window"
