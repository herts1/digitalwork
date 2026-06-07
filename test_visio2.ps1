# Test Drop with stencil master - hidden Visio
Get-Process VISIO -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

$visio = New-Object -ComObject Visio.Application
$visio.Visible = $false       # Hidden mode
$visio.ShowChanges = $false   # No screen refresh
$visio.AlertResponse = 1
Start-Sleep -Seconds 1

Write-Host 'Creating blank doc...'
$doc = $visio.Documents.Add("")
$page = $visio.ActivePage
$page.Name = "Test"

Write-Host 'Opening stencil...'
$stencilPath = 'C:\Program Files\Microsoft Office\root\Office16\Visio Content\2052\BASFLO_M.VSSX'
$stencil = $visio.Documents.OpenEx($stencilPath, 64)  # visOpenRO + visOpenHidden
Write-Host ('Stencil masters count: ' + $stencil.Masters.Count)

Write-Host 'Getting Process master...'
$mProcess = $stencil.Masters.ItemU('Process')
Write-Host ('Master name: ' + $mProcess.NameU)

Write-Host 'Dropping shape on page...'
try {
    $shape = $page.Drop($mProcess, 5.0, 5.0)
    Write-Host 'Drop succeeded!'
    $shape.Text = 'Test OK'
    Write-Host 'Text set OK'
} catch {
    Write-Host ('Drop failed: ' + $_.Exception.Message)
    exit 1
}

Write-Host 'Saving...'
$savePath = 'c:\Users\17740\Desktop\digital\test_drop.vsdx'
if (Test-Path $savePath) { Remove-Item $savePath -Force }
$doc.SaveAs($savePath)
Write-Host ('Saved: ' + $savePath)

$doc.Close()
$visio.Quit()
Write-Host 'DONE - All OK!'
