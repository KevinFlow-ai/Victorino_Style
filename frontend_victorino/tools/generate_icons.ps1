Add-Type -AssemblyName System.Drawing
$root     = Split-Path $PSScriptRoot -Parent
$src      = "$root\assets\logos_app\logo_app1.3.png"
$res      = "$root\android\app\src\main\res"
$linuxPkg = "$root\linux\packaging\icons"
$winIco   = "$root\windows\runner\resources\app_icon.ico"
$source   = [System.Drawing.Image]::FromFile($src)
Write-Host "Fuente: $src  ($($source.Width)x$($source.Height) px)"
function Save-HQ([string]$destPath, [int]$size, [double]$padRatio = 1.0) {
    $canvas = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($canvas)
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $logoSize = [int]($size * $padRatio)
    $offset   = [int](($size - $logoSize) / 2)
    $g.DrawImage($source, $offset, $offset, $logoSize, $logoSize)
    $g.Dispose()
    $dir = Split-Path $destPath
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $canvas.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    $rel = $destPath.Replace($root + "\", "")
    Write-Host "  OK  $rel  ${size}x${size}"
}
Write-Host "--- ANDROID mipmap ---"
Save-HQ "$res\mipmap-mdpi\ic_launcher.png"    48
Save-HQ "$res\mipmap-hdpi\ic_launcher.png"    72
Save-HQ "$res\mipmap-xhdpi\ic_launcher.png"   96
Save-HQ "$res\mipmap-xxhdpi\ic_launcher.png"  144
Save-HQ "$res\mipmap-xxxhdpi\ic_launcher.png" 192
Write-Host "--- ANDROID adaptive foreground ---"
Save-HQ "$res\drawable-mdpi\ic_launcher_foreground.png"    108  0.667
Save-HQ "$res\drawable-hdpi\ic_launcher_foreground.png"    162  0.667
Save-HQ "$res\drawable-xhdpi\ic_launcher_foreground.png"   216  0.667
Save-HQ "$res\drawable-xxhdpi\ic_launcher_foreground.png"  324  0.667
Save-HQ "$res\drawable-xxxhdpi\ic_launcher_foreground.png" 432  0.667
Write-Host "--- ANDROID Play Store / App Store ---"
Save-HQ "$res\playstore.png"  512
Save-HQ "$res\appstore.png"   1024
Write-Host "--- LINUX DEB XDG hicolor ---"
foreach ($sz in @(16,22,24,32,48,64,128,256,512)) {
    Save-HQ "$linuxPkg\${sz}x${sz}\apps\victorino_style.png" $sz
}
Copy-Item $src "$root\linux\runner\my_app_icon.png" -Force
Write-Host "  OK  linux\runner\my_app_icon.png  1024x1024"
Write-Host "--- WINDOWS ICO multi-resolucion ---"
$icoSizes = @(16,32,48,64,128,256)
$pngBytes = @()
foreach ($s in $icoSizes) {
    $bmp = New-Object System.Drawing.Bitmap($s, $s)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($source, 0, 0, $s, $s)
    $g.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytes += ,$ms.ToArray()
    $ms.Dispose(); $bmp.Dispose()
}
$stream = New-Object System.IO.MemoryStream
$w = New-Object System.IO.BinaryWriter($stream)
$w.Write([uint16]0); $w.Write([uint16]1); $w.Write([uint16]$icoSizes.Count)
$dataOffset = 6 + 16 * $icoSizes.Count
for ($i = 0; $i -lt $icoSizes.Count; $i++) {
    $s = $icoSizes[$i]; $sz = $pngBytes[$i].Length
    $w.Write([byte](if ($s -eq 256) {0} else {$s}))
    $w.Write([byte](if ($s -eq 256) {0} else {$s}))
    $w.Write([byte]0); $w.Write([byte]0); $w.Write([uint16]1); $w.Write([uint16]32)
    $w.Write([uint32]$sz); $w.Write([uint32]$dataOffset)
    $dataOffset += $sz
}
foreach ($bytes in $pngBytes) { $w.Write($bytes) }
$w.Flush(); $icoData = $stream.ToArray(); $w.Dispose(); $stream.Dispose()
[System.IO.File]::WriteAllBytes($winIco, $icoData)
$kb = [math]::Round($icoData.Length/1KB,1)
Write-Host "  OK  windows\runner\resources\app_icon.ico  6 res ($kb KB)"
$source.Dispose()
Write-Host "COMPLETADO"