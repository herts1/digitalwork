$f = 'c:\Users\17740\Desktop\digital\create_flowchart_cn.ps1'
$c = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
$bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($f, $c, $bom)
Write-Host 'UTF-8 BOM added to create_flowchart_cn.ps1'
