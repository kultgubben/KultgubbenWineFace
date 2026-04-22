# Uppskalar KultgubbenWines originalikon icon_wine.png (32x32) till 128x128
# med HighQualityBicubic — högre upplösning ger mjukare rendering på klockan
# (som sedan skalar ned, vilket är snyggare än att skala upp 32→64 på enheten).

Add-Type -AssemblyName System.Drawing

$src = "C:/Users/rickard.larsson/Documents/KultgubbenWine/resources/drawables/icon_wine.png"
$dst = "resources/drawables/icon_glass.png"
$target = 128

$original = [System.Drawing.Bitmap]::new($src)
$big = New-Object System.Drawing.Bitmap $target, $target
$g = [System.Drawing.Graphics]::FromImage($big)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

$g.DrawImage($original, 0, 0, $target, $target)

$big.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $big.Dispose(); $original.Dispose()

Write-Host "Skapad: $dst ($target x $target, uppskalad från 32x32 med HighQualityBicubic)"
