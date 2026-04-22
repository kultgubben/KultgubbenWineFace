# Förlänger stammen på icon_wine.png från KultgubbenWine.
# 1. Laddar 32x32-originalet
# 2. Identifierar stam-raderna (de med minst vin-färgade pixlar)
# 3. Inför extra rader i stam-området
# 4. Skalar upp till 128x144 med HighQualityBicubic

Add-Type -AssemblyName System.Drawing

$src = "C:/Users/rickard.larsson/Documents/KultgubbenWine/resources/drawables/icon_wine.png"
$extraRows = 4   # pixlar att lägga till i stam-området (32+4 = 36)

$original = [System.Drawing.Bitmap]::new($src)
$origW = $original.Width
$origH = $original.Height

# Hitta stam-raderna: mycket smala rader med endast 1-4 synliga pixlar
$stemRows = @()
for ($y = 0; $y -lt $origH; $y++) {
    $count = 0
    for ($x = 0; $x -lt $origW; $x++) {
        $c = $original.GetPixel($x, $y)
        if ($c.A -gt 64) { $count++ }
    }
    if ($count -ge 1 -and $count -le 4) { $stemRows += $y }
}

if ($stemRows.Count -eq 0) {
    Write-Host "FEL: Inga stam-rader hittades i $src"
    exit 1
}

# Mittersta stam-raden → där vi duplicerar
$stemMid = $stemRows[[Math]::Floor($stemRows.Count / 2)]
Write-Host "Stam-rader: $($stemRows -join ','); mitt = $stemMid"

# Bygg ny bitmap med $extraRows extra rader insatta vid $stemMid
$newH = $origH + $extraRows
$new = New-Object System.Drawing.Bitmap $origW, $newH
$g = [System.Drawing.Graphics]::FromImage($new)
$g.Clear([System.Drawing.Color]::Transparent)

# Kopiera översta portionen (rader 0..stemMid)
$g.DrawImage($original,
    (New-Object System.Drawing.Rectangle 0, 0, $origW, ($stemMid + 1)),
    (New-Object System.Drawing.Rectangle 0, 0, $origW, ($stemMid + 1)),
    [System.Drawing.GraphicsUnit]::Pixel)

# Duplicera stam-raden $extraRows gånger
for ($i = 0; $i -lt $extraRows; $i++) {
    $g.DrawImage($original,
        (New-Object System.Drawing.Rectangle 0, ($stemMid + 1 + $i), $origW, 1),
        (New-Object System.Drawing.Rectangle 0, $stemMid, $origW, 1),
        [System.Drawing.GraphicsUnit]::Pixel)
}

# Kopiera botten-portionen (efter stam), shiftad ned med $extraRows
$bottomH = $origH - $stemMid - 1
$g.DrawImage($original,
    (New-Object System.Drawing.Rectangle 0, ($stemMid + 1 + $extraRows), $origW, $bottomH),
    (New-Object System.Drawing.Rectangle 0, ($stemMid + 1), $origW, $bottomH),
    [System.Drawing.GraphicsUnit]::Pixel)

# Skala upp till 128 bred, proportionell höjd
$finalW = 128
$finalH = [int]([Math]::Round(128.0 * $newH / $origW))

$big = New-Object System.Drawing.Bitmap $finalW, $finalH
$gBig = [System.Drawing.Graphics]::FromImage($big)
$gBig.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gBig.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gBig.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gBig.DrawImage($new, 0, 0, $finalW, $finalH)

$big.Save("resources/drawables/icon_glass.png", [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose(); $gBig.Dispose(); $new.Dispose(); $big.Dispose(); $original.Dispose()

Write-Host "Skapad: icon_glass.png (${finalW}x${finalH}, original $origW x $origH med $extraRows extra stam-rader)"
