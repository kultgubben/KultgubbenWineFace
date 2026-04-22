# Genererar 5 små guldfärgade ikoner för kurv-texterna.
# Kör en gång: powershell -ExecutionPolicy Bypass -File generate-icons.ps1

Add-Type -AssemblyName System.Drawing

$outDir = "resources/drawables"
$size = 20
$goldA = 255
$goldR = 221  # 0xdd
$goldG = 161  # 0xa1
$goldB = 94   # 0x5e

$gold = [System.Drawing.Color]::FromArgb($goldA, $goldR, $goldG, $goldB)

function New-Icon {
    param([string]$name, [scriptblock]$drawAction)
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush $gold
    $pen = New-Object System.Drawing.Pen $gold, 1.5
    & $drawAction $g $brush $pen
    $bmp.Save((Join-Path $outDir "icon_$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose(); $brush.Dispose(); $pen.Dispose()
    Write-Host "Skapad: icon_$name.png"
}

# Hjärta (puls)
New-Icon -name "heart" -drawAction {
    param($g, $brush, $pen)
    $g.FillEllipse($brush, 2, 4, 8, 8)
    $g.FillEllipse($brush, 10, 4, 8, 8)
    $pts = @(
        (New-Object System.Drawing.PointF 3, 8),
        (New-Object System.Drawing.PointF 17, 8),
        (New-Object System.Drawing.PointF 10, 18)
    )
    $g.FillPolygon($brush, $pts)
}

# Batteri (horisontell, med cap)
New-Icon -name "battery" -drawAction {
    param($g, $brush, $pen)
    $pen.Width = 2
    $g.DrawRectangle($pen, 2, 6, 13, 8)
    $g.FillRectangle($brush, 15, 8, 3, 4)
    # Fyllnads-indikator
    $g.FillRectangle($brush, 4, 8, 6, 4)
}

# Fotspår (häl + tår)
New-Icon -name "foot" -drawAction {
    param($g, $brush, $pen)
    # Huvudfot (häl-oval)
    $g.FillEllipse($brush, 5, 10, 10, 9)
    # Tår
    $g.FillEllipse($brush, 6, 5, 3, 3)
    $g.FillEllipse($brush, 9, 3, 3, 3)
    $g.FillEllipse($brush, 12, 3, 3, 3)
    $g.FillEllipse($brush, 15, 5, 3, 3)
    $g.FillEllipse($brush, 15, 8, 2, 2)
}

# Stress-mätare (halvcirkel-gauge + visarnål)
New-Icon -name "bolt" -drawAction {
    param($g, $brush, $pen)
    $pen.Width = 2
    # Övre halvcirkel (startAngle=180°=9-o-clock, sweep=180° medsols via 12-o-clock till 3-o-clock)
    $g.DrawArc($pen, 2, 4, 16, 16, 180, 180)
    # Visarnål från hub (10, 12) upp-höger till ~13-vinkel (stress-indikation)
    $pen.Width = 2
    $g.DrawLine($pen, 10, 12, 15, 6)
    # Hub-dot i mitten
    $g.FillEllipse($brush, 9, 11, 3, 3)
    # Lilla "tick-marks" vid gaugens kanter för tydlighet
    $g.FillRectangle($brush, 2, 11, 2, 1)   # vänster ände
    $g.FillRectangle($brush, 16, 11, 2, 1)  # höger ände
}

# Body Battery — stick-figur (huvud + kropp + utsträckta armar + ben) → tydlig person-siluett
New-Icon -name "bodybattery" -drawAction {
    param($g, $brush, $pen)
    # Huvud (cirkel)
    $g.FillEllipse($brush, 7, 1, 6, 6)
    # Torso (rektangel)
    $g.FillRectangle($brush, 8, 8, 4, 6)
    # Armar (utsträckta horisontellt)
    $g.FillRectangle($brush, 2, 9, 6, 2)   # vänster arm
    $g.FillRectangle($brush, 12, 9, 6, 2)  # höger arm
    # Ben (två vertikala linjer)
    $g.FillRectangle($brush, 7, 14, 2, 5)  # vänster ben
    $g.FillRectangle($brush, 11, 14, 2, 5) # höger ben
}

Write-Host ""
Write-Host "Alla ikoner klara i $outDir/"
