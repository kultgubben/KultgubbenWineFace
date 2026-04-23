# KultgubbenBeerFace & KultgubbenChampagneFace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Skapa två nya Garmin-urtavlor (BeerFace och ChampagneFace) som är direkta kopior av KultgubbenWineFace med egna ikoner, färgpaletter och steg-trösklar.

**Architecture:** Två oberoende Garmin Connect IQ-projekt i syskonmappar till KultgubbenWineFace. Varje projekt är helt självständigt (ingen delad kod). Samma layout som WineFace — topbåge (stress/body battery), center (dryckesikon + antal), tid, datum, bottenbåge (batteri/steg/puls). Ikoner genereras med PowerShell + System.Drawing, samma teknik som befintligt projekt.

**Tech Stack:** Monkey C, Garmin Connect IQ SDK 8.4.1, PowerShell + System.Drawing (ikongeneration). Målenheter: enduro3, fenix7-serien, fr955.

---

## Filkarta

### KultgubbenBeerFace/
| Fil | Åtgärd |
|-----|--------|
| `manifest.xml` | Skapa — ny UUID, AppName = KultgubbenBeer |
| `monkey.jungle` | Skapa — identisk med WineFace |
| `version.txt` | Skapa — `0.1` |
| `build-iq.ps1` | Skapa — anpassad för BeerFace |
| `draw-beer.ps1` | Skapa — ritar pintglas + skum i amber |
| `build/` | Skapa tom mapp |
| `source/KultgubbenBeerFaceApp.mc` | Skapa — entry point |
| `source/KultgubbenBeerFaceView.mc` | Skapa — amber-palett, trösklar 4000/3000, IconBeer |
| `resources/drawables/drawables.xml` | Skapa — registrerar IconBeer |
| `resources/drawables/icon_beer.png` | Genereras av draw-beer.ps1 |
| `resources/drawables/icon_battery.png` | Kopiera från WineFace |
| `resources/drawables/icon_foot.png` | Kopiera från WineFace |
| `resources/drawables/icon_heart.png` | Kopiera från WineFace |
| `resources/drawables/icon_bolt.png` | Kopiera från WineFace |
| `resources/drawables/icon_bodybattery.png` | Kopiera från WineFace |
| `resources/drawables/launcher_icon.png` | Kopiera från WineFace |
| `resources/strings/strings.xml` | Skapa — AppName eng |
| `resources-swe/strings/strings.xml` | Skapa — AppName swe |

### KultgubbenChampagneFace/
Samma struktur — `IconChampagne` istället för `IconBeer`, annan palett, `STEPS_PER_GLASS = 3000` alltid.

---

## Task 1: KultgubbenBeerFace — projektskelett

**Files:**
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\manifest.xml`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\monkey.jungle`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\version.txt`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\build-iq.ps1`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\resources\drawables\drawables.xml`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\resources\strings\strings.xml`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\resources-swe\strings\strings.xml`

- [ ] **Steg 1: Skapa mappstruktur**

```powershell
$base = "C:\Users\rickard.larsson\Documents\KultgubbenBeerFace"
New-Item -ItemType Directory -Force -Path "$base\source"
New-Item -ItemType Directory -Force -Path "$base\resources\drawables"
New-Item -ItemType Directory -Force -Path "$base\resources\strings"
New-Item -ItemType Directory -Force -Path "$base\resources-swe\strings"
New-Item -ItemType Directory -Force -Path "$base\build"
```

- [ ] **Steg 2: Skapa manifest.xml**

```xml
<?xml version="1.0"?>
<iq:manifest version="3" xmlns:iq="http://www.garmin.com/xml/connectiq">
    <iq:application id="a2fd5e10-c841-4b37-b912-852fa6d70002" type="watchface" name="@Strings.AppName" entry="KultgubbenBeerFaceApp" launcherIcon="@Drawables.LauncherIcon" minApiLevel="4.2.1">
        <iq:products>
            <iq:product id="enduro3"/>
            <iq:product id="fenix7"/>
            <iq:product id="fenix7pro"/>
            <iq:product id="fenix7s"/>
            <iq:product id="fenix7spro"/>
            <iq:product id="fenix7x"/>
            <iq:product id="fenix7xpro"/>
            <iq:product id="fenix8solar47mm"/>
            <iq:product id="fenix8solar51mm"/>
            <iq:product id="fr955"/>
        </iq:products>
        <iq:permissions>
            <iq:uses-permission id="UserProfile"/>
            <iq:uses-permission id="SensorHistory"/>
        </iq:permissions>
        <iq:languages>
            <iq:language>eng</iq:language>
            <iq:language>swe</iq:language>
        </iq:languages>
        <iq:barrels/>
    </iq:application>
</iq:manifest>
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\manifest.xml`

- [ ] **Steg 3: Skapa monkey.jungle**

```
project.manifest=manifest.xml
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\monkey.jungle`

- [ ] **Steg 4: Skapa version.txt**

```
0.1
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\version.txt`

- [ ] **Steg 5: Skapa build-iq.ps1**

```powershell
$v = Get-Content version.txt
$parts = $v.Split('.')
$parts[1] = [int]$parts[1] + 1
$new = $parts -join '.'
$new | Set-Content version.txt

Write-Host "Version bumped to v$new"

& "$env:APPDATA/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc.bat" -f monkey.jungle -d enduro3 -o build/KultgubbenBeerFace.prg -y "$env:USERPROFILE/.connectiq/developer_key.der"

& "$env:APPDATA/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc.bat" -f monkey.jungle -d enduro3 -o build/KultgubbenBeerFace.iq -y "$env:USERPROFILE/.connectiq/developer_key.der" -e

Write-Host "Build klar! Filerna finns i build/"
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\build-iq.ps1`

- [ ] **Steg 6: Skapa drawables.xml**

```xml
<drawables xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://developer.garmin.com/downloads/connect-iq/resources.xsd">
    <bitmap id="LauncherIcon"    filename="launcher_icon.png" />
    <bitmap id="IconBeer"        filename="icon_beer.png" />
    <bitmap id="IconBattery"     filename="icon_battery.png" />
    <bitmap id="IconFoot"        filename="icon_foot.png" />
    <bitmap id="IconHeart"       filename="icon_heart.png" />
    <bitmap id="IconBolt"        filename="icon_bolt.png" />
    <bitmap id="IconBodyBattery" filename="icon_bodybattery.png" />
</drawables>
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\resources\drawables\drawables.xml`

- [ ] **Steg 7: Skapa strings.xml (eng + swe)**

```xml
<strings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://developer.garmin.com/downloads/connect-iq/resources.xsd">
    <string id="AppName">KultgubbenBeer</string>
</strings>
```

Spara identisk fil till båda:
- `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\resources\strings\strings.xml`
- `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\resources-swe\strings\strings.xml`

- [ ] **Steg 8: Kopiera delade ikoner från WineFace**

```powershell
$src  = "C:\Users\rickard.larsson\Documents\KultgubbenWineFace\resources\drawables"
$dest = "C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\resources\drawables"
Copy-Item "$src\icon_battery.png"    $dest
Copy-Item "$src\icon_foot.png"       $dest
Copy-Item "$src\icon_heart.png"      $dest
Copy-Item "$src\icon_bolt.png"       $dest
Copy-Item "$src\icon_bodybattery.png" $dest
Copy-Item "$src\launcher_icon.png"   $dest
```

- [ ] **Steg 9: Commit**

```powershell
Set-Location "C:\Users\rickard.larsson\Documents\KultgubbenBeerFace"
git init
git add .
git commit -m "feat: initial BeerFace project skeleton"
```

---

## Task 2: KultgubbenBeerFace — ölikon

**Files:**
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\draw-beer.ps1`
- Create (genererad): `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\resources\drawables\icon_beer.png`

- [ ] **Steg 1: Skapa draw-beer.ps1**

```powershell
# Ritar ett pintglas med skumkrona i amberfärger, 128x128 px.

Add-Type -AssemblyName System.Drawing

$size   = 128
$amber  = [System.Drawing.Color]::FromArgb(255, 204, 119,   0)  # #CC7700
$foam   = [System.Drawing.Color]::FromArgb(255, 245, 230, 190)  # #F5E6BE
$edge   = [System.Drawing.Color]::FromArgb(255, 255, 170,  51)  # #FFAA33

$bmp = New-Object System.Drawing.Bitmap $size, $size
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

$bAmber = New-Object System.Drawing.SolidBrush $amber
$bFoam  = New-Object System.Drawing.SolidBrush $foam
$pEdge  = New-Object System.Drawing.Pen $edge, 2

# Glasets kropp (trapetsoidal form — bredare uppåt)
$body = New-Object System.Drawing.Drawing2D.GraphicsPath
$body.StartFigure()
$body.AddLine(22, 36, 84, 36)    # topp-kant (under skummet)
$body.AddLine(84, 36, 78, 108)   # höger sida
$body.AddLine(78, 108, 30, 108)  # botten
$body.AddLine(30, 108, 22, 36)   # vänster sida
$body.CloseFigure()
$g.FillPath($bAmber, $body)
$g.DrawPath($pEdge, $body)

# Handtag (höger sida, rundad bågform)
$pHandle = New-Object System.Drawing.Pen $amber, 10
$pHandle.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$pHandle.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawArc($pHandle, 72, 48, 30, 38, -90, 180)

# Skumkrona (cirklar + rektangel som bas)
$g.FillEllipse($bFoam, 14, 12, 40, 30)   # vänster skum-bulle
$g.FillEllipse($bFoam, 44, 8,  40, 32)   # mitten skum-bulle
$g.FillEllipse($bFoam, 60, 14, 36, 26)   # höger skum-bulle
$g.FillRectangle($bFoam, 22, 28, 62, 12) # förbindande bas så skummet möter glaset

$bmp.Save("resources/drawables/icon_beer.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
$bAmber.Dispose(); $bFoam.Dispose(); $pEdge.Dispose(); $pHandle.Dispose()
$body.Dispose()

Write-Host "Skapad: icon_beer.png (128x128, amber pintglas med skumkrona)"
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\draw-beer.ps1`

- [ ] **Steg 2: Generera ikonen**

```powershell
Set-Location "C:\Users\rickard.larsson\Documents\KultgubbenBeerFace"
.\draw-beer.ps1
```

Förväntat output: `Skapad: icon_beer.png (128x128, amber pintglas med skumkrona)`
Verifiera att `resources\drawables\icon_beer.png` finns och är > 0 bytes.

- [ ] **Steg 3: Commit**

```powershell
git add draw-beer.ps1 resources/drawables/icon_beer.png
git commit -m "feat: add beer mug icon (amber pint with foam crown)"
```

---

## Task 3: KultgubbenBeerFace — källkod

**Files:**
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\source\KultgubbenBeerFaceApp.mc`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\source\KultgubbenBeerFaceView.mc`

- [ ] **Steg 1: Skapa KultgubbenBeerFaceApp.mc**

```java
using Toybox.Application;
using Toybox.WatchUi;

class KultgubbenBeerFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [ new KultgubbenBeerFaceView() ];
    }
}
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\source\KultgubbenBeerFaceApp.mc`

- [ ] **Steg 2: Skapa KultgubbenBeerFaceView.mc**

```java
using Toybox.ActivityMonitor;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

class KultgubbenBeerFaceView extends WatchUi.WatchFace {

    const STEPS_PER_GLASS_DEFAULT = 4000;
    const STEPS_PER_GLASS_FRI_SAT = 3000;
    const ACTIVITY_MIN_VIGOROUS   = 30;

    const COLOR_BG          = 0x000000;
    const COLOR_AMBER       = 0xffaa33;
    const COLOR_AMBER_LIGHT = 0xffcc55;
    const COLOR_AMBER_DIM   = 0xcc8822;
    const COLOR_AMBER_GRAY  = 0xcc8833;

    var _iconBeer        = null;
    var _iconBattery     = null;
    var _iconFoot        = null;
    var _iconHeart       = null;
    var _iconBolt        = null;
    var _iconBodyBattery = null;
    var _fontTime        = null;
    var _fontNumber      = null;
    var _fontText        = null;
    var _fontArc         = null;

    var _lastStress      = null;
    var _lastBodyBattery = null;

    const SERIF_FACES = ["PridiRegularGarmin", "PridiSemiBoldGarmin", "PridiRegular",
                         "ExoSemiBold", "RobotoCondensedRegular", "RobotoRegular"];

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        _iconBeer        = WatchUi.loadResource(Rez.Drawables.IconBeer);
        _iconBattery     = WatchUi.loadResource(Rez.Drawables.IconBattery);
        _iconFoot        = WatchUi.loadResource(Rez.Drawables.IconFoot);
        _iconHeart       = WatchUi.loadResource(Rez.Drawables.IconHeart);
        _iconBolt        = WatchUi.loadResource(Rez.Drawables.IconBolt);
        _iconBodyBattery = WatchUi.loadResource(Rez.Drawables.IconBodyBattery);
        var w = dc.getWidth();
        _fontTime   = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 72) / 280 });
        _fontNumber = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 42) / 280 });
        _fontText   = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 20) / 280 });
        _fontArc    = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 28) / 280 });
    }

    function onShow() {}
    function onHide() {}

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();
        _drawTopArc(dc, w, h);
        _drawBeer(dc, w, h);
        _drawTime(dc, w, h);
        _drawDate(dc, w, h);
        _drawBottomArc(dc, w, h);
    }

    function _drawBeer(dc, w, h) {
        var glasses = _computeGlasses();
        var targetW = (w * 23) / 100;
        var yTop    = (h * 25) / 100;
        if (_iconBeer != null) {
            var srcW  = _iconBeer.getWidth();
            var scale = targetW.toFloat() / srcW;
            var x     = (w / 2) - (targetW / 2);
            var xform = new Graphics.AffineTransform();
            xform.scale(scale, scale);
            dc.drawBitmap2(x, yTop, _iconBeer, {
                :transform   => xform,
                :filterMode  => Graphics.FILTER_MODE_BILINEAR
            });
        }
        dc.setColor(COLOR_AMBER, Graphics.COLOR_TRANSPARENT);
        if (_fontNumber != null) {
            dc.drawText(
                w / 2 + (targetW / 2) + 6,
                yTop + (targetW / 2),
                _fontNumber,
                glasses.toString(),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    function _drawTime(dc, w, h) {
        var clock   = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [
            clock.hour.format("%02d"),
            clock.min.format("%02d")
        ]);
        dc.setColor(COLOR_AMBER_LIGHT, Graphics.COLOR_TRANSPARENT);
        if (_fontTime != null) {
            dc.drawText(w / 2, (h * 58) / 100, _fontTime, timeStr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function _drawDate(dc, w, h) {
        var info    = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$ $3$", [
            info.day_of_week,
            info.day.format("%02d"),
            info.month
        ]).toUpper();
        dc.setColor(COLOR_AMBER_DIM, Graphics.COLOR_TRANSPARENT);
        if (_fontText != null) {
            dc.drawText(w / 2, (h * 67) / 100, _fontText, dateStr,
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function _drawBottomArc(dc, w, h) {
        var cx     = w / 2;
        var cy     = h / 2;
        var radius = (w * 128) / 280;

        var stats      = System.getSystemStats();
        var batteryStr;
        if (stats.batteryInDays != null && stats.batteryInDays >= 1.0) {
            batteryStr = stats.batteryInDays.format("%d") + "d";
        } else if (stats.battery != null) {
            batteryStr = stats.battery.format("%d") + "%";
        } else {
            batteryStr = "--";
        }

        var steps = 0;
        try {
            var am = ActivityMonitor.getInfo();
            if (am != null && am.steps != null) { steps = am.steps; }
        } catch(e) {}
        var stepsStr = _formatSteps(steps);

        var hr    = _getHeartRate();
        var hrStr = (hr != null) ? hr.toString() : "--";

        _drawSegmentedArc(dc, cx, cy, radius, 270,
            [_iconBattery, _iconFoot, _iconHeart],
            [batteryStr, stepsStr, hrStr],
            true);
    }

    function _drawTopArc(dc, w, h) {
        var cx     = w / 2;
        var cy     = h / 2;
        var radius = (w * 118) / 280;

        var stress = _getSensorLatest(:getStressHistory);
        if (stress != null) { _lastStress = stress; }
        var stressStr = (_lastStress != null) ? _lastStress.toString() : "--";

        var bb = _getSensorLatest(:getBodyBatteryHistory);
        if (bb != null) { _lastBodyBattery = bb; }
        var bbStr = (_lastBodyBattery != null) ? _lastBodyBattery.toString() : "--";

        _drawSegmentedArc(dc, cx, cy, radius, 90,
            [_iconBolt, _iconBodyBattery],
            [stressStr, bbStr],
            false);
    }

    function _drawSegmentedArc(dc, cx, cy, radius, centerAngleDeg, icons, texts, ccw) {
        if (_fontArc == null) { return; }
        var n = icons.size();
        if (n == 0 || texts.size() != n) { return; }

        var gapIconText        = 3;
        var gapBetweenSegments = 8;
        var toDeg              = 180.0 / Math.PI;

        var iconDegs = new [n];
        var textDegs = new [n];
        var totalDeg = 0.0;
        for (var i = 0; i < n; i++) {
            var iconPx   = (icons[i] != null) ? icons[i].getWidth() : 0;
            iconDegs[i]  = (iconPx / radius.toFloat()) * toDeg;
            var textPx   = dc.getTextWidthInPixels(texts[i], _fontArc);
            textDegs[i]  = (textPx / radius.toFloat()) * toDeg;
            totalDeg    += iconDegs[i] + gapIconText + textDegs[i];
        }
        totalDeg += gapBetweenSegments * (n - 1);

        var sign   = ccw ? 1 : -1;
        var cursor = centerAngleDeg - sign * (totalDeg / 2.0);

        dc.setColor(COLOR_AMBER_GRAY, Graphics.COLOR_TRANSPARENT);

        var direction = ccw
            ? Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE
            : Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE;

        for (var j = 0; j < n; j++) {
            var iconCenterAngle = cursor + sign * (iconDegs[j] / 2.0);
            if (icons[j] != null) {
                _drawArcIcon(dc, cx, cy, radius, iconCenterAngle, icons[j], ccw);
            }
            cursor = cursor + sign * (iconDegs[j] + gapIconText);
            dc.drawRadialText(cx, cy, _fontArc, texts[j],
                Graphics.TEXT_JUSTIFY_LEFT, cursor, radius, direction);
            cursor = cursor + sign * (textDegs[j] + gapBetweenSegments);
        }
    }

    function _drawArcIcon(dc, cx, cy, radius, angleDeg, icon, ccw) {
        var rotDeg = ccw ? (270 - angleDeg) : (90 - angleDeg);
        var rotRad = rotDeg * Math.PI / 180.0;

        var iconW  = icon.getWidth();
        var iconH  = icon.getHeight();
        var halfW  = iconW / 2.0;
        var halfH  = iconH / 2.0;
        var capHalf   = 6;
        var iconRadius = ccw ? (radius - capHalf) : (radius + capHalf);

        var rad = angleDeg * Math.PI / 180.0;
        var px  = cx + (iconRadius * Math.cos(rad));
        var py  = cy - (iconRadius * Math.sin(rad));

        var xform = new Graphics.AffineTransform();
        xform.translate(halfW, halfH);
        xform.rotate(rotRad);
        xform.translate(-halfW, -halfH);

        dc.drawBitmap2(px - halfW, py - halfH, icon, { :transform => xform });
    }

    function _getSensorLatest(method) {
        try {
            if (!(Toybox has :SensorHistory)) { return null; }
            var iter;
            if (method == :getStressHistory) {
                iter = Toybox.SensorHistory.getStressHistory({});
            } else if (method == :getBodyBatteryHistory) {
                iter = Toybox.SensorHistory.getBodyBatteryHistory({});
            } else {
                return null;
            }
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    return sample.data.toNumber();
                }
            }
        } catch(e) {}
        return null;
    }

    function _computeGlasses() {
        var totalSteps = 0;
        var vigorous   = 0;
        try {
            var am = ActivityMonitor.getInfo();
            if (am != null) {
                if (am.steps != null) { totalSteps = am.steps; }
                if (am.activeMinutesDay != null && am.activeMinutesDay.vigorous != null) {
                    vigorous = am.activeMinutesDay.vigorous;
                }
            }
        } catch(e) {}
        var stepsPerGlass = _isFriSat() ? STEPS_PER_GLASS_FRI_SAT : STEPS_PER_GLASS_DEFAULT;
        var baseGlasses   = totalSteps / stepsPerGlass;
        var bonusGlasses  = vigorous / ACTIVITY_MIN_VIGOROUS;
        return baseGlasses + bonusGlasses;
    }

    function _isFriSat() {
        var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var day = now.day_of_week;
        return (day == 6 || day == 7);
    }

    function _formatSteps(steps) {
        if (steps < 1000) { return steps.toString(); }
        var thousands = steps / 1000;
        var remainder = steps % 1000;
        return thousands.toString() + " " + remainder.format("%03d");
    }

    function _getHeartRate() {
        try {
            var iter = ActivityMonitor.getHeartRateHistory(1, true);
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.heartRate != null
                    && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    return sample.heartRate;
                }
            }
        } catch(e) {}
        return null;
    }

    function onEnterSleep() {}
    function onExitSleep() {}
}
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenBeerFace\source\KultgubbenBeerFaceView.mc`

- [ ] **Steg 3: Commit**

```powershell
Set-Location "C:\Users\rickard.larsson\Documents\KultgubbenBeerFace"
git add source/
git commit -m "feat: add BeerFace source (amber palette, 4000/3000 thresholds)"
```

---

## Task 4: KultgubbenBeerFace — bygg och verifiera

- [ ] **Steg 1: Bygg**

```powershell
Set-Location "C:\Users\rickard.larsson\Documents\KultgubbenBeerFace"
.\build-iq.ps1
```

Förväntat output: `Build klar! Filerna finns i build/`
Verifiera att `build\KultgubbenBeerFace.prg` skapades.

- [ ] **Steg 2: Öppna i simulatorn**

```powershell
& "$env:APPDATA/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/simulator.bat"
```

Dra `build\KultgubbenBeerFace.prg` till simulatorfönstret (eller File → Open).
Välj enduro3. Verifiera visuellt:
- Svart bakgrund
- Ölikon i övre mitten
- Antal glas till höger om ikonen
- Tid i amber-guld
- Datum i dämpad amber
- Bågar med sensorvärden

- [ ] **Steg 3: Commit om allt ser OK ut**

```powershell
git commit --allow-empty -m "chore: BeerFace verified in simulator"
```

---

## Task 5: KultgubbenChampagneFace — projektskelett

**Files:**
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\manifest.xml`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\monkey.jungle`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\version.txt`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\build-iq.ps1`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\resources\drawables\drawables.xml`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\resources\strings\strings.xml`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\resources-swe\strings\strings.xml`

- [ ] **Steg 1: Skapa mappstruktur**

```powershell
$base = "C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace"
New-Item -ItemType Directory -Force -Path "$base\source"
New-Item -ItemType Directory -Force -Path "$base\resources\drawables"
New-Item -ItemType Directory -Force -Path "$base\resources\strings"
New-Item -ItemType Directory -Force -Path "$base\resources-swe\strings"
New-Item -ItemType Directory -Force -Path "$base\build"
```

- [ ] **Steg 2: Skapa manifest.xml**

```xml
<?xml version="1.0"?>
<iq:manifest version="3" xmlns:iq="http://www.garmin.com/xml/connectiq">
    <iq:application id="b3fe6f21-d952-4c48-ca23-963fb7e80003" type="watchface" name="@Strings.AppName" entry="KultgubbenChampagneFaceApp" launcherIcon="@Drawables.LauncherIcon" minApiLevel="4.2.1">
        <iq:products>
            <iq:product id="enduro3"/>
            <iq:product id="fenix7"/>
            <iq:product id="fenix7pro"/>
            <iq:product id="fenix7s"/>
            <iq:product id="fenix7spro"/>
            <iq:product id="fenix7x"/>
            <iq:product id="fenix7xpro"/>
            <iq:product id="fenix8solar47mm"/>
            <iq:product id="fenix8solar51mm"/>
            <iq:product id="fr955"/>
        </iq:products>
        <iq:permissions>
            <iq:uses-permission id="UserProfile"/>
            <iq:uses-permission id="SensorHistory"/>
        </iq:permissions>
        <iq:languages>
            <iq:language>eng</iq:language>
            <iq:language>swe</iq:language>
        </iq:languages>
        <iq:barrels/>
    </iq:application>
</iq:manifest>
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\manifest.xml`

- [ ] **Steg 3: Skapa monkey.jungle**

```
project.manifest=manifest.xml
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\monkey.jungle`

- [ ] **Steg 4: Skapa version.txt**

```
0.1
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\version.txt`

- [ ] **Steg 5: Skapa build-iq.ps1**

```powershell
$v = Get-Content version.txt
$parts = $v.Split('.')
$parts[1] = [int]$parts[1] + 1
$new = $parts -join '.'
$new | Set-Content version.txt

Write-Host "Version bumped to v$new"

& "$env:APPDATA/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc.bat" -f monkey.jungle -d enduro3 -o build/KultgubbenChampagneFace.prg -y "$env:USERPROFILE/.connectiq/developer_key.der"

& "$env:APPDATA/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc.bat" -f monkey.jungle -d enduro3 -o build/KultgubbenChampagneFace.iq -y "$env:USERPROFILE/.connectiq/developer_key.der" -e

Write-Host "Build klar! Filerna finns i build/"
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\build-iq.ps1`

- [ ] **Steg 6: Skapa drawables.xml**

```xml
<drawables xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://developer.garmin.com/downloads/connect-iq/resources.xsd">
    <bitmap id="LauncherIcon"    filename="launcher_icon.png" />
    <bitmap id="IconChampagne"   filename="icon_champagne.png" />
    <bitmap id="IconBattery"     filename="icon_battery.png" />
    <bitmap id="IconFoot"        filename="icon_foot.png" />
    <bitmap id="IconHeart"       filename="icon_heart.png" />
    <bitmap id="IconBolt"        filename="icon_bolt.png" />
    <bitmap id="IconBodyBattery" filename="icon_bodybattery.png" />
</drawables>
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\resources\drawables\drawables.xml`

- [ ] **Steg 7: Skapa strings.xml (eng + swe)**

```xml
<strings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://developer.garmin.com/downloads/connect-iq/resources.xsd">
    <string id="AppName">KultgubbenChampagne</string>
</strings>
```

Spara identisk fil till båda:
- `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\resources\strings\strings.xml`
- `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\resources-swe\strings\strings.xml`

- [ ] **Steg 8: Kopiera delade ikoner från WineFace**

```powershell
$src  = "C:\Users\rickard.larsson\Documents\KultgubbenWineFace\resources\drawables"
$dest = "C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\resources\drawables"
Copy-Item "$src\icon_battery.png"     $dest
Copy-Item "$src\icon_foot.png"        $dest
Copy-Item "$src\icon_heart.png"       $dest
Copy-Item "$src\icon_bolt.png"        $dest
Copy-Item "$src\icon_bodybattery.png" $dest
Copy-Item "$src\launcher_icon.png"    $dest
```

- [ ] **Steg 9: Commit**

```powershell
Set-Location "C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace"
git init
git add .
git commit -m "feat: initial ChampagneFace project skeleton"
```

---

## Task 6: KultgubbenChampagneFace — champagneikon

**Files:**
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\draw-champagne.ps1`
- Create (genererad): `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\resources\drawables\icon_champagne.png`

- [ ] **Steg 1: Skapa draw-champagne.ps1**

```powershell
# Ritar en champagneflöjt med stam, fot och bubblor i guldfärger, 128x128 px.

Add-Type -AssemblyName System.Drawing

$size   = 128
$gold   = [System.Drawing.Color]::FromArgb(255, 200, 170,  50)  # #C8AA32
$foam   = [System.Drawing.Color]::FromArgb(200, 255, 248, 200)  # #FFF8C8 halvtransparent
$bubble = [System.Drawing.Color]::FromArgb(160, 255, 248, 160)  # bubbelfärg

$bmp = New-Object System.Drawing.Bitmap $size, $size
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

$bGold   = New-Object System.Drawing.SolidBrush $gold
$bFoam   = New-Object System.Drawing.SolidBrush $foam
$bBubble = New-Object System.Drawing.SolidBrush $bubble
$pEdge   = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 220, 190, 60)), 2

# Flöjtens kropp (smal, lätt konisk — bredare uppåt)
# Top: x=42..86 vid y=12 — Botten av skålen: x=54..74 vid y=82
$flute = New-Object System.Drawing.Drawing2D.GraphicsPath
$flute.StartFigure()
$flute.AddBezier(42, 12, 40, 42, 52, 70, 54, 82)  # vänster sida
$flute.AddLine(54, 82, 74, 82)                     # skålens botten
$flute.AddBezier(74, 82, 76, 70, 88, 42, 86, 12)  # höger sida
$flute.CloseFigure()
$g.FillPath($bGold, $flute)
$g.DrawPath($pEdge, $flute)

# Stam
$g.FillRectangle($bGold, 61, 82, 6, 22)

# Fot (flat oval)
$g.FillEllipse($bGold, 42, 102, 44, 10)
$g.DrawEllipse($pEdge, 42, 102, 44, 10)

# Mousse-topp
$g.FillEllipse($bFoam, 36, 6, 56, 16)

# Bubblor som stiger i glaset
$g.FillEllipse($bBubble, 60, 68, 5, 5)
$g.FillEllipse($bBubble, 68, 54, 4, 4)
$g.FillEllipse($bBubble, 58, 44, 3, 3)
$g.FillEllipse($bBubble, 65, 32, 4, 4)
$g.FillEllipse($bBubble, 72, 62, 3, 3)

$bmp.Save("resources/drawables/icon_champagne.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
$bGold.Dispose(); $bFoam.Dispose(); $bBubble.Dispose(); $pEdge.Dispose()
$flute.Dispose()

Write-Host "Skapad: icon_champagne.png (128x128, guld flöjt med stam och bubblor)"
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\draw-champagne.ps1`

- [ ] **Steg 2: Generera ikonen**

```powershell
Set-Location "C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace"
.\draw-champagne.ps1
```

Förväntat output: `Skapad: icon_champagne.png (128x128, guld flöjt med stam och bubblor)`
Verifiera att `resources\drawables\icon_champagne.png` finns och är > 0 bytes.

- [ ] **Steg 3: Commit**

```powershell
git add draw-champagne.ps1 resources/drawables/icon_champagne.png
git commit -m "feat: add champagne flute icon (gold flute with bubbles)"
```

---

## Task 7: KultgubbenChampagneFace — källkod

**Files:**
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\source\KultgubbenChampagneFaceApp.mc`
- Create: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\source\KultgubbenChampagneFaceView.mc`

- [ ] **Steg 1: Skapa KultgubbenChampagneFaceApp.mc**

```java
using Toybox.Application;
using Toybox.WatchUi;

class KultgubbenChampagneFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [ new KultgubbenChampagneFaceView() ];
    }
}
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\source\KultgubbenChampagneFaceApp.mc`

- [ ] **Steg 2: Skapa KultgubbenChampagneFaceView.mc**

```java
using Toybox.ActivityMonitor;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

class KultgubbenChampagneFaceView extends WatchUi.WatchFace {

    // 3000 steg/glas alltid — ingen fre/lör-bonus för champagne
    const STEPS_PER_GLASS_DEFAULT = 3000;
    const ACTIVITY_MIN_VIGOROUS   = 30;

    const COLOR_BG         = 0x000000;
    const COLOR_GOLD       = 0xffe566;
    const COLOR_GOLD_LIGHT = 0xfff0a0;
    const COLOR_GOLD_DIM   = 0xaa9944;
    const COLOR_GOLD_GRAY  = 0x8877bb;  // lila för bågtexter

    var _iconChampagne   = null;
    var _iconBattery     = null;
    var _iconFoot        = null;
    var _iconHeart       = null;
    var _iconBolt        = null;
    var _iconBodyBattery = null;
    var _fontTime        = null;
    var _fontNumber      = null;
    var _fontText        = null;
    var _fontArc         = null;

    var _lastStress      = null;
    var _lastBodyBattery = null;

    const SERIF_FACES = ["PridiRegularGarmin", "PridiSemiBoldGarmin", "PridiRegular",
                         "ExoSemiBold", "RobotoCondensedRegular", "RobotoRegular"];

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        _iconChampagne   = WatchUi.loadResource(Rez.Drawables.IconChampagne);
        _iconBattery     = WatchUi.loadResource(Rez.Drawables.IconBattery);
        _iconFoot        = WatchUi.loadResource(Rez.Drawables.IconFoot);
        _iconHeart       = WatchUi.loadResource(Rez.Drawables.IconHeart);
        _iconBolt        = WatchUi.loadResource(Rez.Drawables.IconBolt);
        _iconBodyBattery = WatchUi.loadResource(Rez.Drawables.IconBodyBattery);
        var w = dc.getWidth();
        _fontTime   = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 72) / 280 });
        _fontNumber = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 42) / 280 });
        _fontText   = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 20) / 280 });
        _fontArc    = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 28) / 280 });
    }

    function onShow() {}
    function onHide() {}

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();
        _drawTopArc(dc, w, h);
        _drawChampagne(dc, w, h);
        _drawTime(dc, w, h);
        _drawDate(dc, w, h);
        _drawBottomArc(dc, w, h);
    }

    function _drawChampagne(dc, w, h) {
        var glasses = _computeGlasses();
        var targetW = (w * 23) / 100;
        var yTop    = (h * 25) / 100;
        if (_iconChampagne != null) {
            var srcW  = _iconChampagne.getWidth();
            var scale = targetW.toFloat() / srcW;
            var x     = (w / 2) - (targetW / 2);
            var xform = new Graphics.AffineTransform();
            xform.scale(scale, scale);
            dc.drawBitmap2(x, yTop, _iconChampagne, {
                :transform  => xform,
                :filterMode => Graphics.FILTER_MODE_BILINEAR
            });
        }
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        if (_fontNumber != null) {
            dc.drawText(
                w / 2 + (targetW / 2) + 6,
                yTop + (targetW / 2),
                _fontNumber,
                glasses.toString(),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    function _drawTime(dc, w, h) {
        var clock   = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [
            clock.hour.format("%02d"),
            clock.min.format("%02d")
        ]);
        dc.setColor(COLOR_GOLD_LIGHT, Graphics.COLOR_TRANSPARENT);
        if (_fontTime != null) {
            dc.drawText(w / 2, (h * 58) / 100, _fontTime, timeStr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function _drawDate(dc, w, h) {
        var info    = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$ $3$", [
            info.day_of_week,
            info.day.format("%02d"),
            info.month
        ]).toUpper();
        dc.setColor(COLOR_GOLD_DIM, Graphics.COLOR_TRANSPARENT);
        if (_fontText != null) {
            dc.drawText(w / 2, (h * 67) / 100, _fontText, dateStr,
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function _drawBottomArc(dc, w, h) {
        var cx     = w / 2;
        var cy     = h / 2;
        var radius = (w * 128) / 280;

        var stats      = System.getSystemStats();
        var batteryStr;
        if (stats.batteryInDays != null && stats.batteryInDays >= 1.0) {
            batteryStr = stats.batteryInDays.format("%d") + "d";
        } else if (stats.battery != null) {
            batteryStr = stats.battery.format("%d") + "%";
        } else {
            batteryStr = "--";
        }

        var steps = 0;
        try {
            var am = ActivityMonitor.getInfo();
            if (am != null && am.steps != null) { steps = am.steps; }
        } catch(e) {}
        var stepsStr = _formatSteps(steps);

        var hr    = _getHeartRate();
        var hrStr = (hr != null) ? hr.toString() : "--";

        _drawSegmentedArc(dc, cx, cy, radius, 270,
            [_iconBattery, _iconFoot, _iconHeart],
            [batteryStr, stepsStr, hrStr],
            true);
    }

    function _drawTopArc(dc, w, h) {
        var cx     = w / 2;
        var cy     = h / 2;
        var radius = (w * 118) / 280;

        var stress = _getSensorLatest(:getStressHistory);
        if (stress != null) { _lastStress = stress; }
        var stressStr = (_lastStress != null) ? _lastStress.toString() : "--";

        var bb = _getSensorLatest(:getBodyBatteryHistory);
        if (bb != null) { _lastBodyBattery = bb; }
        var bbStr = (_lastBodyBattery != null) ? _lastBodyBattery.toString() : "--";

        _drawSegmentedArc(dc, cx, cy, radius, 90,
            [_iconBolt, _iconBodyBattery],
            [stressStr, bbStr],
            false);
    }

    function _drawSegmentedArc(dc, cx, cy, radius, centerAngleDeg, icons, texts, ccw) {
        if (_fontArc == null) { return; }
        var n = icons.size();
        if (n == 0 || texts.size() != n) { return; }

        var gapIconText        = 3;
        var gapBetweenSegments = 8;
        var toDeg              = 180.0 / Math.PI;

        var iconDegs = new [n];
        var textDegs = new [n];
        var totalDeg = 0.0;
        for (var i = 0; i < n; i++) {
            var iconPx   = (icons[i] != null) ? icons[i].getWidth() : 0;
            iconDegs[i]  = (iconPx / radius.toFloat()) * toDeg;
            var textPx   = dc.getTextWidthInPixels(texts[i], _fontArc);
            textDegs[i]  = (textPx / radius.toFloat()) * toDeg;
            totalDeg    += iconDegs[i] + gapIconText + textDegs[i];
        }
        totalDeg += gapBetweenSegments * (n - 1);

        var sign   = ccw ? 1 : -1;
        var cursor = centerAngleDeg - sign * (totalDeg / 2.0);

        dc.setColor(COLOR_GOLD_GRAY, Graphics.COLOR_TRANSPARENT);

        var direction = ccw
            ? Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE
            : Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE;

        for (var j = 0; j < n; j++) {
            var iconCenterAngle = cursor + sign * (iconDegs[j] / 2.0);
            if (icons[j] != null) {
                _drawArcIcon(dc, cx, cy, radius, iconCenterAngle, icons[j], ccw);
            }
            cursor = cursor + sign * (iconDegs[j] + gapIconText);
            dc.drawRadialText(cx, cy, _fontArc, texts[j],
                Graphics.TEXT_JUSTIFY_LEFT, cursor, radius, direction);
            cursor = cursor + sign * (textDegs[j] + gapBetweenSegments);
        }
    }

    function _drawArcIcon(dc, cx, cy, radius, angleDeg, icon, ccw) {
        var rotDeg    = ccw ? (270 - angleDeg) : (90 - angleDeg);
        var rotRad    = rotDeg * Math.PI / 180.0;
        var iconW     = icon.getWidth();
        var iconH     = icon.getHeight();
        var halfW     = iconW / 2.0;
        var halfH     = iconH / 2.0;
        var capHalf   = 6;
        var iconRadius = ccw ? (radius - capHalf) : (radius + capHalf);
        var rad = angleDeg * Math.PI / 180.0;
        var px  = cx + (iconRadius * Math.cos(rad));
        var py  = cy - (iconRadius * Math.sin(rad));
        var xform = new Graphics.AffineTransform();
        xform.translate(halfW, halfH);
        xform.rotate(rotRad);
        xform.translate(-halfW, -halfH);
        dc.drawBitmap2(px - halfW, py - halfH, icon, { :transform => xform });
    }

    function _getSensorLatest(method) {
        try {
            if (!(Toybox has :SensorHistory)) { return null; }
            var iter;
            if (method == :getStressHistory) {
                iter = Toybox.SensorHistory.getStressHistory({});
            } else if (method == :getBodyBatteryHistory) {
                iter = Toybox.SensorHistory.getBodyBatteryHistory({});
            } else {
                return null;
            }
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    return sample.data.toNumber();
                }
            }
        } catch(e) {}
        return null;
    }

    function _computeGlasses() {
        var totalSteps = 0;
        var vigorous   = 0;
        try {
            var am = ActivityMonitor.getInfo();
            if (am != null) {
                if (am.steps != null) { totalSteps = am.steps; }
                if (am.activeMinutesDay != null && am.activeMinutesDay.vigorous != null) {
                    vigorous = am.activeMinutesDay.vigorous;
                }
            }
        } catch(e) {}
        var baseGlasses  = totalSteps / STEPS_PER_GLASS_DEFAULT;
        var bonusGlasses = vigorous / ACTIVITY_MIN_VIGOROUS;
        return baseGlasses + bonusGlasses;
    }

    function _formatSteps(steps) {
        if (steps < 1000) { return steps.toString(); }
        var thousands = steps / 1000;
        var remainder = steps % 1000;
        return thousands.toString() + " " + remainder.format("%03d");
    }

    function _getHeartRate() {
        try {
            var iter = ActivityMonitor.getHeartRateHistory(1, true);
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.heartRate != null
                    && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    return sample.heartRate;
                }
            }
        } catch(e) {}
        return null;
    }

    function onEnterSleep() {}
    function onExitSleep() {}
}
```

Spara till: `C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace\source\KultgubbenChampagneFaceView.mc`

- [ ] **Steg 3: Commit**

```powershell
Set-Location "C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace"
git add source/
git commit -m "feat: add ChampagneFace source (pale gold + purple, 3000 steps always)"
```

---

## Task 8: KultgubbenChampagneFace — bygg och verifiera

- [ ] **Steg 1: Bygg**

```powershell
Set-Location "C:\Users\rickard.larsson\Documents\KultgubbenChampagneFace"
.\build-iq.ps1
```

Förväntat output: `Build klar! Filerna finns i build/`
Verifiera att `build\KultgubbenChampagneFace.prg` skapades.

- [ ] **Steg 2: Öppna i simulatorn**

Dra `build\KultgubbenChampagneFace.prg` till simulatorfönstret. Välj enduro3.
Verifiera visuellt:
- Svart bakgrund
- Champagneflöjt i övre mitten med bubblor
- Antal glas (ljust guld) till höger om ikonen
- Tid i ljusguld (#fff0a0)
- Datum i dämpad guld (#aa9944)
- Bågtexter i lila (#8877bb)

- [ ] **Steg 3: Commit om allt ser OK ut**

```powershell
git commit --allow-empty -m "chore: ChampagneFace verified in simulator"
```
