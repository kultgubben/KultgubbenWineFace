# Ritar ett nytt vinglas 128x128 som matchar originalets palett (burgundy + vit).
# Mer detaljerat än 32x32-originalet, samma färger.

Add-Type -AssemblyName System.Drawing

$size = 128
$wine  = [System.Drawing.Color]::FromArgb(255, 90, 0, 21)   # #5A0015
$white = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)

$bmp = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)
$bWine  = New-Object System.Drawing.SolidBrush $wine
$bWhite = New-Object System.Drawing.SolidBrush $white
$pWine  = New-Object System.Drawing.Pen $wine, 3

# Tulpan-skal som filled path (bezier-kurvor)
$bowl = New-Object System.Drawing.Drawing2D.GraphicsPath
$bowl.StartFigure()
$bowl.AddLine(34, 14, 94, 14)                                # topp-rim
$bowl.AddBezier(94, 14, 112, 30, 106, 64, 74, 80)            # höger sida ned
$bowl.AddLine(74, 80, 54, 80)                                # botten-smal (till skaft)
$bowl.AddBezier(54, 80, 22, 64, 16, 30, 34, 14)              # vänster sida upp
$bowl.CloseFigure()
$g.FillPath($bWine, $bowl)

# Vit highlight-kant runt topp-rimen (öppningen)
$rim = New-Object System.Drawing.Drawing2D.GraphicsPath
$rim.StartFigure()
$rim.AddBezier(34, 14, 44, 22, 84, 22, 94, 14)               # nedre rim-båge
$rim.AddLine(94, 14, 34, 14)                                 # övre rim (rak)
$rim.CloseFigure()
$g.FillPath($bWhite, $rim)

# Skaft (burgundy rektangel)
$g.FillRectangle($bWine, 60, 80, 8, 28)

# Fot (burgundy flat oval)
$g.FillEllipse($bWine, 30, 104, 68, 12)

$bmp.Save("resources/drawables/icon_glass.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
$bWine.Dispose(); $bWhite.Dispose(); $pWine.Dispose()
$bowl.Dispose(); $rim.Dispose()

Write-Host "Skapad: icon_glass.png (128x128, burgundy tulpan + vit rim)"
