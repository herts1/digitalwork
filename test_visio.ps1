# Kill existing Visio
Get-Process VISIO -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

$visio = New-Object -ComObject Visio.Application
$visio.Visible = $true
$visio.AlertResponse = 1
Start-Sleep -Seconds 2

# Try template file directly
$templatePath = 'C:\Program Files\Microsoft Office\root\Office16\Visio Content\2052\BASFLO_M.VSTX'
Write-Host ('Template: ' + $templatePath + ' | Exists: ' + (Test-Path $templatePath))

if (Test-Path $templatePath) {
    Write-Host 'Creating from template...'
    $doc = $visio.Documents.Add($templatePath)
    $page = $visio.ActivePage
    Write-Host ('Masters count: ' + $doc.Masters.Count)

    foreach ($m in $doc.Masters) {
        Write-Host ('  Master: ' + $m.NameU)
    }

    # Test drop
    $m = $doc.Masters.ItemU('Process')
    $s = $page.Drop($m, 5.0, 5.0)
    $s.Text = 'Test Process'
    Write-Host 'Shape dropped OK!'

    $savePath = 'c:\Users\17740\Desktop\digital\test_template.vsdx'
    $doc.SaveAs($savePath)
    Write-Host ('Saved: ' + $savePath)
    $doc.Close()
} else {
    Write-Host 'Template not found!'
}

$visio.Quit()
Write-Host 'Done.'
