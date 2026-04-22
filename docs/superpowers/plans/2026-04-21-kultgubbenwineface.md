# KultgubbenWineFace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bygga en Connect IQ watch face för Garmin Enduro 3 + Fenix 7/8 + FR955 som visar tid, vinglas-räknare (Kultgubben-logik), datum och fem komplikationer (stress, body battery, batteritid, steg, puls) — med symmetriska krökta texter längs bezelen i en elegant guldton.

**Architecture:** Connect IQ watch-face med `WatchUi.WatchFace`-basklass. All rendering sker i `onUpdate(dc)` + `onPartialUpdate(dc)` för AOD. Vinglas-logikkärnan återanvänds exakt från `KultgubbenWineField`. Krökt text via `Dc.drawRadialText()`, typografi via Garmins system-fonter i v1 (custom serif-font för v2). Ingen persistent state, ingen UI-interaktion.

**Tech Stack:** Connect IQ SDK 8.4.1 (Windows), Monkey C, PowerShell build-skript, VS Code tasks. minApiLevel `4.0.0` (krävs för `drawRadialText` och `batteryInDays`).

**Referenser:**
- Spec: `docs/superpowers/specs/2026-04-21-kultgubbenwineface-design.md`
- Mockup v10: `C:\Users\rickard.larsson\Documents\KultgubbenWineField\.superpowers\brainstorm\1748-1776771121\content\visual-style-v10.html`
- Logik-källa: `C:\Users\rickard.larsson\Documents\KultgubbenWineField\source\KultgubbenWineFieldView.mc`

**Sökvägsbas:** `C:\Users\rickard.larsson\Documents\KultgubbenWineFace\` (kallas `<root>` i planen)

---

## Task 1: Projektstruktur och build-kedja

**Files:**
- Create: `<root>\manifest.xml`
- Create: `<root>\monkey.jungle`
- Create: `<root>\version.txt`
- Create: `<root>\build-iq.ps1`
- Create: `<root>\.vscode\tasks.json`
- Create: `<root>\.gitignore`

- [ ] **Steg 1.1: Skapa projektroten och initiera git**

```bash
mkdir -p "C:\Users\rickard.larsson\Documents\KultgubbenWineFace"
cd "C:\Users\rickard.larsson\Documents\KultgubbenWineFace"
git init
```

- [ ] **Steg 1.2: Skriv manifest.xml**

Generera ny UUID för `id`-attributet (t.ex. via `uuidgen` eller online) — får inte vara samma som andra projekt.

`<root>\manifest.xml`:

```xml
<?xml version="1.0"?>
<iq:manifest version="3" xmlns:iq="http://www.garmin.com/xml/connectiq">
    <iq:application id="NYUUID-HÄR-NY-UNIK-UUID" type="watch-face" name="@Strings.AppName" entry="KultgubbenWineFaceApp" launcherIcon="@Drawables.LauncherIcon" minApiLevel="4.0.0">
        <iq:products>
            <iq:product id="enduro3"/>
            <iq:product id="fenix7x"/>
            <iq:product id="fenix7xpro"/>
            <iq:product id="fenix8solar51mm"/>
            <iq:product id="fenix7"/>
            <iq:product id="fenix7pro"/>
            <iq:product id="fenix8solar47mm"/>
            <iq:product id="fr955"/>
            <iq:product id="fenix7s"/>
            <iq:product id="fenix7spro"/>
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

- [ ] **Steg 1.3: Skriv monkey.jungle**

`<root>\monkey.jungle`:

```
project.manifest=manifest.xml
```

- [ ] **Steg 1.4: Skriv version.txt**

`<root>\version.txt`:

```
1.0
```

- [ ] **Steg 1.5: Skriv build-iq.ps1**

`<root>\build-iq.ps1`:

```powershell
# Bump version
$v = Get-Content version.txt
$parts = $v.Split('.')
$parts[1] = [int]$parts[1] + 1
$new = $parts -join '.'
$new | Set-Content version.txt

Write-Host "Version bumped to v$new"

# Build PRG
& "$env:APPDATA/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc.bat" -f monkey.jungle -d enduro3 -o build/KultgubbenWineFace.prg -y "$env:USERPROFILE/.connectiq/developer_key.der"

# Build IQ package
& "$env:APPDATA/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc.bat" -f monkey.jungle -d enduro3 -o build/KultgubbenWineFace.iq -y "$env:USERPROFILE/.connectiq/developer_key.der" -e

Write-Host "Build klar! Filerna finns i build/"
```

- [ ] **Steg 1.6: Skriv .vscode/tasks.json**

`<root>\.vscode\tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build KultgubbenWineFace",
            "type": "shell",
            "command": "\"${env:APPDATA}/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc.bat\"",
            "args": [
                "-f", "monkey.jungle",
                "-d", "enduro3",
                "-o", "build/KultgubbenWineFace.prg",
                "-y", "${env:USERPROFILE}/.connectiq/developer_key.der"
            ],
            "group": { "kind": "build", "isDefault": true },
            "problemMatcher": [],
            "presentation": { "reveal": "always", "panel": "shared" }
        },
        {
            "label": "Build IQ Package",
            "type": "shell",
            "command": "powershell -ExecutionPolicy Bypass -File build-iq.ps1",
            "options": { "cwd": "${workspaceFolder}" },
            "problemMatcher": [],
            "presentation": { "reveal": "always", "panel": "shared" }
        },
        {
            "label": "Start Simulator",
            "type": "shell",
            "command": "powershell",
            "args": [
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-Command",
                "if (-not (Get-Process simulator -ErrorAction SilentlyContinue)) { Start-Process \"$env:APPDATA\\Garmin\\ConnectIQ\\Sdks\\connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa\\bin\\simulator.exe\"; Start-Sleep -Seconds 3; Write-Host 'Simulator startad' } else { Write-Host 'Simulator redan igang' }"
            ],
            "problemMatcher": [],
            "presentation": { "reveal": "silent", "panel": "shared" }
        },
        {
            "label": "Run in Simulator",
            "type": "shell",
            "command": "\"${env:APPDATA}/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/monkeydo.bat\"",
            "args": [
                "build/KultgubbenWineFace.prg",
                "enduro3"
            ],
            "dependsOn": ["Build KultgubbenWineFace", "Start Simulator"],
            "dependsOrder": "sequence",
            "problemMatcher": [],
            "presentation": { "reveal": "always", "panel": "shared" }
        }
    ]
}
```

- [ ] **Steg 1.7: Skriv .gitignore**

`<root>\.gitignore`:

```
build/
bin/
*.prg
*.iq
.DS_Store
```

- [ ] **Steg 1.8: Commit**

```bash
cd "C:\Users\rickard.larsson\Documents\KultgubbenWineFace"
git add manifest.xml monkey.jungle version.txt build-iq.ps1 .vscode/tasks.json .gitignore
git commit -m "Task 1: project scaffolding and build tooling"
```

---

## Task 2: Minimal watch-face skelett (bygger och kör)

Målet: en tom svart urtavla som bygger utan fel och körs i simulatorn.

**Files:**
- Create: `<root>\source\KultgubbenWineFaceApp.mc`
- Create: `<root>\source\KultgubbenWineFaceView.mc`
- Create: `<root>\resources\strings\strings.xml`
- Create: `<root>\resources-swe\strings\strings.xml`
- Create: `<root>\resources\drawables\drawables.xml`
- Create: `<root>\resources\drawables\launcher_icon.png` (kopia)

- [ ] **Steg 2.1: Skriv KultgubbenWineFaceApp.mc**

`<root>\source\KultgubbenWineFaceApp.mc`:

```monkey
using Toybox.Application;
using Toybox.WatchUi;

class KultgubbenWineFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [ new KultgubbenWineFaceView() ];
    }
}
```

- [ ] **Steg 2.2: Skriv KultgubbenWineFaceView.mc (skelett med svart canvas)**

`<root>\source\KultgubbenWineFaceView.mc`:

```monkey
using Toybox.Graphics;
using Toybox.WatchUi;

class KultgubbenWineFaceView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
    }

    function onShow() {
    }

    function onHide() {
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
    }

    function onPartialUpdate(dc) {
    }

    function onEnterSleep() {
    }

    function onExitSleep() {
    }
}
```

- [ ] **Steg 2.3: Skriv strings.xml (engelska)**

`<root>\resources\strings\strings.xml`:

```xml
<strings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://developer.garmin.com/downloads/connect-iq/resources.xsd">
    <string id="AppName">KultgubbenWine</string>
</strings>
```

- [ ] **Steg 2.4: Skriv strings.xml (svenska)**

`<root>\resources-swe\strings\strings.xml`:

```xml
<strings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://developer.garmin.com/downloads/connect-iq/resources.xsd">
    <string id="AppName">KultgubbenWine</string>
</strings>
```

- [ ] **Steg 2.5: Skriv drawables.xml**

`<root>\resources\drawables\drawables.xml`:

```xml
<drawables xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://developer.garmin.com/downloads/connect-iq/resources.xsd">
    <bitmap id="LauncherIcon" filename="launcher_icon.png" />
</drawables>
```

- [ ] **Steg 2.6: Kopiera launcher_icon.png från KultgubbenWineField**

```bash
cp "C:/Users/rickard.larsson/Documents/KultgubbenWineField/resources/drawables/launcher_icon.png" \
   "C:/Users/rickard.larsson/Documents/KultgubbenWineFace/resources/drawables/launcher_icon.png"
```

- [ ] **Steg 2.7: Bygg och verifiera**

I VS Code: Ctrl+Shift+B → "Build KultgubbenWineFace".
Förvänta: `BUILD SUCCESSFUL` och att `build/KultgubbenWineFace.prg` skapas.

Om build misslyckas:
- Kontrollera UUID:n i manifest.xml är korrekt formaterad (standard UUID-format: 8-4-4-4-12 hex)
- Kontrollera att developer_key.der finns på `%USERPROFILE%/.connectiq/developer_key.der`

- [ ] **Steg 2.8: Kör i simulator och verifiera**

Ctrl+Shift+B → "Run in Simulator".
Förvänta: Simulatorn öppnas med Enduro 3-vy, visar svart urtavla.

- [ ] **Steg 2.9: Commit**

```bash
git add source/ resources/ resources-swe/
git commit -m "Task 2: minimal watch-face skeleton renders black canvas"
```

---

## Task 3: Vinglas-logik och glas-ikon i topp

Målet: stort guldfärgat vinglas + dynamiskt räknat antal syns högst upp i vyn (centrerat).

**Files:**
- Modify: `<root>\source\KultgubbenWineFaceView.mc`
- Create: `<root>\resources\drawables\icon_glass.png` (kopia)
- Modify: `<root>\resources\drawables\drawables.xml`

- [ ] **Steg 3.1: Kopiera glas-ikonen från KultgubbenWine**

```bash
cp "C:/Users/rickard.larsson/Documents/KultgubbenWine/resources/drawables/icon_wine.png" \
   "C:/Users/rickard.larsson/Documents/KultgubbenWineFace/resources/drawables/icon_glass.png"
```

- [ ] **Steg 3.2: Uppdatera drawables.xml**

`<root>\resources\drawables\drawables.xml` (ersätt hela filen):

```xml
<drawables xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://developer.garmin.com/downloads/connect-iq/resources.xsd">
    <bitmap id="LauncherIcon" filename="launcher_icon.png" />
    <bitmap id="IconGlass" filename="icon_glass.png" />
</drawables>
```

- [ ] **Steg 3.3: Uppdatera View med vinglas-logik och rendering**

`<root>\source\KultgubbenWineFaceView.mc` (ersätt hela filen):

```monkey
using Toybox.ActivityMonitor;
using Toybox.Graphics;
using Toybox.Time;
using Toybox.WatchUi;

class KultgubbenWineFaceView extends WatchUi.WatchFace {

    // Samma logik som KultgubbenWine / KultgubbenWineField
    const STEPS_PER_GLASS_DEFAULT = 4000;
    const STEPS_PER_GLASS_FRI_SAT = 3000;
    const ACTIVITY_MIN_VIGOROUS   = 30;

    // Palett
    const COLOR_BG          = 0x000000;
    const COLOR_GOLD        = 0xd4af37;
    const COLOR_GOLD_LIGHT  = 0xf0e6d2;
    const COLOR_GOLD_DIM    = 0x8a6d3b;
    const COLOR_GOLD_GRAY   = 0xa8936a;

    var _iconGlass = null;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        _iconGlass = WatchUi.loadResource(Rez.Drawables.IconGlass);
    }

    function onShow() {}
    function onHide() {}

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        _drawGlass(dc, w, h);
    }

    function _drawGlass(dc, w, h) {
        var glasses = _computeGlasses();

        // Glas-ikonen: centrerad horisontellt, top-area
        if (_iconGlass != null) {
            var iconW = _iconGlass.getWidth();
            var iconH = _iconGlass.getHeight();
            // Centrerad på 23% ned från toppen (motsvarar top:64 på 280px)
            var y = (h * 23 / 100) - (iconH / 2);
            var x = (w / 2) - (iconW / 2);
            dc.drawBitmap(x, y, _iconGlass);
        }

        // Antal glas: guld-text till höger om ikonen
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2 + 48,
            (h * 23 / 100) - 10,
            Graphics.FONT_NUMBER_MEDIUM,
            glasses.toString(),
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

    function _computeGlasses() {
        var totalSteps = 0;
        var vigorous = 0;
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

    function onPartialUpdate(dc) {}
    function onEnterSleep() {}
    function onExitSleep() {}
}
```

- [ ] **Steg 3.4: Bygg och verifiera**

Ctrl+Shift+B → "Build KultgubbenWineFace".
Förvänta: `BUILD SUCCESSFUL`.

- [ ] **Steg 3.5: Kör i simulator och verifiera**

Ctrl+Shift+B → "Run in Simulator".
Förvänta: Svart urtavla med vinglas-ikon i topp, centrerad, med antal (t.ex. "0" eller ett litet tal) till höger om glaset.

Test av räknaren:
- I simulatorn, öppna "Simulation" → "Activity Monitor" → sätt `steps` = 8000 → antalet ska visa "2".
- Sätt `steps` = 12000 → antalet ska visa "3".

- [ ] **Steg 3.6: Commit**

```bash
git add source/KultgubbenWineFaceView.mc resources/drawables/
git commit -m "Task 3: wine glass icon and live glass count rendering"
```

---

## Task 4: Tid och datum (centrerad grupp)

Målet: tid (stor) och datum (liten uppercase) renderas centrerat vertikalt på urtavlan.

**Files:**
- Modify: `<root>\source\KultgubbenWineFaceView.mc`

- [ ] **Steg 4.1: Lägg till tid + datum rendering**

Lägg till följande två metoder i `KultgubbenWineFaceView.mc` (före `_computeGlasses`):

```monkey
function _drawTime(dc, w, h) {
    var clock = System.getClockTime();
    var timeStr = Lang.format("$1$:$2$", [
        clock.hour.format("%02d"),
        clock.min.format("%02d")
    ]);

    dc.setColor(COLOR_GOLD_LIGHT, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
        w / 2,
        (h * 55 / 100),
        Graphics.FONT_NUMBER_HOT,
        timeStr,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );
}

function _drawDate(dc, w, h) {
    var info = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    var dateStr = Lang.format("$1$ $2$ $3$", [
        info.day_of_week,
        info.day.format("%02d"),
        info.month
    ]).toUpper();

    dc.setColor(COLOR_GOLD_DIM, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
        w / 2,
        (h * 73 / 100),
        Graphics.FONT_XTINY,
        dateStr,
        Graphics.TEXT_JUSTIFY_CENTER
    );
}
```

Uppdatera `onUpdate`:

```monkey
function onUpdate(dc) {
    var w = dc.getWidth();
    var h = dc.getHeight();

    dc.setColor(COLOR_BG, COLOR_BG);
    dc.clear();

    _drawGlass(dc, w, h);
    _drawTime(dc, w, h);
    _drawDate(dc, w, h);
}
```

Lägg till `using Toybox.Lang;` och `using Toybox.System;` längst upp i filen.

- [ ] **Steg 4.2: Bygg och verifiera**

Ctrl+Shift+B → "Build KultgubbenWineFace".
Förvänta: `BUILD SUCCESSFUL`.

- [ ] **Steg 4.3: Kör i simulator och verifiera**

Ctrl+Shift+B → "Run in Simulator".
Förvänta:
- Vinglas i toppen (som förut)
- Tid i mitten (t.ex. "14:32") — stor, ljus guld
- Datum under tiden (t.ex. "TIS 21 APR") — liten, dämpad guld
- Allt centrerat horisontellt

Ändra simulatortiden: Simulator → Settings → Clock → ändra tid → tiden på urtavlan ska uppdateras.

- [ ] **Steg 4.4: Commit**

```bash
git add source/KultgubbenWineFaceView.mc
git commit -m "Task 4: time and date rendering centered on watch"
```

---

## Task 5: Botten-kurva (batteri, steg, puls)

Målet: krökt text längs bottenkanten med `BAT 12d · STEG 7 240 · HR 62`.

**Files:**
- Modify: `<root>\source\KultgubbenWineFaceView.mc`

- [ ] **Steg 5.1: Lägg till botten-kurva-rendering**

Lägg till följande metod i `KultgubbenWineFaceView.mc` (före `_computeGlasses`):

```monkey
function _drawBottomArc(dc, w, h) {
    var cx = w / 2;
    var cy = h / 2;
    var radius = (w * 128) / 280;  // 128/280 proportion

    // Hämta data
    var stats = System.getSystemStats();
    var batteryStr;
    if (stats.batteryInDays != null) {
        batteryStr = Lang.format("BAT $1$d", [stats.batteryInDays.format("%d")]);
    } else {
        batteryStr = Lang.format("BAT $1$%", [stats.battery.format("%d")]);
    }

    var steps = 0;
    try {
        var am = ActivityMonitor.getInfo();
        if (am != null && am.steps != null) { steps = am.steps; }
    } catch(e) {}
    var stepsStr = Lang.format("STEG $1$", [_formatSteps(steps)]);

    var hr = _getHeartRate();
    var hrStr = (hr != null) ? "HR " + hr.toString() : "HR --";

    var fullStr = batteryStr + "  ·  " + stepsStr + "  ·  " + hrStr;

    dc.setColor(COLOR_GOLD_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawRadialText(
        cx, cy,
        Graphics.FONT_XTINY,
        fullStr,
        Graphics.TEXT_JUSTIFY_CENTER,
        270,              // startAngle: 270° = rakt ned (botten)
        radius,
        Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE
    );
}

function _formatSteps(steps) {
    // Tusentalsavgränsare (blanksteg): 7240 → "7 240"
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
```

Uppdatera `onUpdate` för att anropa den nya metoden:

```monkey
function onUpdate(dc) {
    var w = dc.getWidth();
    var h = dc.getHeight();

    dc.setColor(COLOR_BG, COLOR_BG);
    dc.clear();

    _drawGlass(dc, w, h);
    _drawTime(dc, w, h);
    _drawDate(dc, w, h);
    _drawBottomArc(dc, w, h);
}
```

- [ ] **Steg 5.2: Bygg och verifiera**

Ctrl+Shift+B → "Build KultgubbenWineFace".
Förvänta: `BUILD SUCCESSFUL`. Om felmeddelande om `drawRadialText` — kontrollera att minApiLevel i manifest.xml är `4.0.0`.

- [ ] **Steg 5.3: Kör i simulator och verifiera**

Förvänta:
- Botten-text krökt längs bezelen: `BAT Nd · STEG N NNN · HR NN`
- Text ska följa klockans rundning
- Läsbar på svart bakgrund, guldgrå färg

Test av data:
- Simulator → Settings → System Stats → ändra battery → bat-värdet ska uppdateras
- Simulator → Activity Monitor → ändra steps → stegräknaren ska uppdateras
- Simulator → Sensor → sätt Heart Rate → HR-värdet ska uppdateras

- [ ] **Steg 5.4: Commit**

```bash
git add source/KultgubbenWineFaceView.mc
git commit -m "Task 5: bottom radial arc with battery, steps, heart rate"
```

---

## Task 6: Topp-kurva (stress + body battery)

Målet: symmetrisk topptext `STRESS NN · BB NN` med mindre radie (118/280 istället för 128/280) för optisk balans.

**Files:**
- Modify: `<root>\source\KultgubbenWineFaceView.mc`

- [ ] **Steg 6.1: Lägg till topp-kurva-rendering**

Lägg till följande metoder i `KultgubbenWineFaceView.mc`:

```monkey
function _drawTopArc(dc, w, h) {
    var cx = w / 2;
    var cy = h / 2;
    var radius = (w * 118) / 280;  // 118/280 — mindre än botten för balans

    var stress = _getSensorLatest(:getStressHistory);
    var stressStr = (stress != null) ? "STRESS " + stress.toString() : "STRESS --";

    var bb = _getSensorLatest(:getBodyBatteryHistory);
    var bbStr = (bb != null) ? "BB " + bb.toString() : "BB --";

    var fullStr = stressStr + "  ·  " + bbStr;

    dc.setColor(COLOR_GOLD_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawRadialText(
        cx, cy,
        Graphics.FONT_XTINY,
        fullStr,
        Graphics.TEXT_JUSTIFY_CENTER,
        90,               // startAngle: 90° = rakt upp (topp)
        radius,
        Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE
    );
}

function _getSensorLatest(method) {
    try {
        if (!(Toybox has :SensorHistory)) { return null; }
        var iter;
        if (method == :getStressHistory) {
            iter = Toybox.SensorHistory.getStressHistory({:period => 1});
        } else if (method == :getBodyBatteryHistory) {
            iter = Toybox.SensorHistory.getBodyBatteryHistory({:period => 1});
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
```

Uppdatera `onUpdate`:

```monkey
function onUpdate(dc) {
    var w = dc.getWidth();
    var h = dc.getHeight();

    dc.setColor(COLOR_BG, COLOR_BG);
    dc.clear();

    _drawTopArc(dc, w, h);
    _drawGlass(dc, w, h);
    _drawTime(dc, w, h);
    _drawDate(dc, w, h);
    _drawBottomArc(dc, w, h);
}
```

Lägg till `using Toybox.SensorHistory;` längst upp (med `if` runt om ifall stödet saknas — redan hanterat via `Toybox has :SensorHistory`).

- [ ] **Steg 6.2: Bygg och verifiera**

Ctrl+Shift+B → "Build KultgubbenWineFace".
Förvänta: `BUILD SUCCESSFUL`.

- [ ] **Steg 6.3: Kör i simulator och verifiera**

Förvänta:
- Topp-text krökt längs topp-bezelen: `STRESS -- · BB --` (troligen -- i simulatorn om sensor history saknar data)
- Visuellt spegelsymmetrisk med botten-texten
- Om simulatorn har body battery + stress data → faktiska värden visas

- [ ] **Steg 6.4: Commit**

```bash
git add source/KultgubbenWineFaceView.mc
git commit -m "Task 6: top radial arc with stress and body battery"
```

---

## Task 7: Verifiera palett och vertikal rytm

Målet: säkerställa att färger och positioner matchar mockupen. Justera om nödvändigt.

**Files:**
- Modify: `<root>\source\KultgubbenWineFaceView.mc`

- [ ] **Steg 7.1: Visuell jämförelse mot mockup**

Öppna mockup v10 i webbläsare:
`file:///C:/Users/rickard.larsson/Documents/KultgubbenWineField/.superpowers/brainstorm/1748-1776771121/content/visual-style-v10.html`

Kör urtavlan i simulator samtidigt. Jämför sida vid sida:
- Glas-position (vertikalt): ska vara centrerad så att gruppen glas+tid+datum har sin mittpunkt på urtavlans mitt
- Tid: stor, ljus guld-vit, centrerad
- Datum: liten, uppercase, dämpad guld, strax under tid
- Topp-kurva: indragen något mer än bottenkurvan (mindre radie)
- Botten-kurva: följer bezel-kanten

- [ ] **Steg 7.2: Justera y-offset för glas och datum om gruppen inte är centrerad**

Om gruppen ligger för högt, justera procentsatserna i `_drawGlass`, `_drawTime`, `_drawDate`:

Referensvärden (från mockup v10 på 280px-skärm):
- Glas top y=64 → `(h * 23 / 100)` vid glas-radie ~28 (center y=92)
- Tid center y=179 → `(h * 64 / 100)` (ändra från 55 till 64 om nödvändigt)
- Datum y=210 → `(h * 75 / 100)` (ändra från 73 till 75)

Prova olika procentsatser i simulatorn tills gruppen känns centrerad.

- [ ] **Steg 7.3: Bygg och verifiera**

Bygg om och jämför visuellt igen. Iterera tills det ser rätt ut.

- [ ] **Steg 7.4: Commit**

```bash
git add source/KultgubbenWineFaceView.mc
git commit -m "Task 7: tune vertical layout to match design mockup"
```

---

## Task 8: AOD-beteende (always-on display)

Målet: i sleep-läge visas bara tid + glasantal i dämpad grå palett, med pixel-shift för burn-in-skydd.

**Files:**
- Modify: `<root>\source\KultgubbenWineFaceView.mc`

- [ ] **Steg 8.1: Lägg till sleep-state och AOD-rendering**

Lägg till `_isSleeping`-fält och uppdatera `onEnterSleep` / `onExitSleep`:

```monkey
var _isSleeping = false;

function onEnterSleep() {
    _isSleeping = true;
    WatchUi.requestUpdate();
}

function onExitSleep() {
    _isSleeping = false;
    WatchUi.requestUpdate();
}
```

Lägg till palettkonstant för sleep:

```monkey
const COLOR_AOD_GRAY = 0x808080;
```

Lägg till AOD-renderingsmetod:

```monkey
function _drawAod(dc, w, h) {
    dc.setColor(COLOR_BG, COLOR_BG);
    dc.clear();

    // Pixel-shift för burn-in-skydd — ±2px rotation per minut
    var clock = System.getClockTime();
    var shiftX = 0;
    var shiftY = 0;
    var phase = clock.min % 5;
    if (phase == 1) { shiftX = 2; }
    else if (phase == 2) { shiftY = 2; }
    else if (phase == 3) { shiftX = -2; }
    else if (phase == 4) { shiftY = -2; }

    dc.setColor(COLOR_AOD_GRAY, Graphics.COLOR_TRANSPARENT);

    // Tid
    var timeStr = Lang.format("$1$:$2$", [
        clock.hour.format("%02d"),
        clock.min.format("%02d")
    ]);
    dc.drawText(
        w / 2 + shiftX,
        (h * 55 / 100) + shiftY,
        Graphics.FONT_NUMBER_HOT,
        timeStr,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );

    // Glas-antal (bara siffran, ingen ikon i AOD → sparar energi)
    var glasses = _computeGlasses();
    dc.drawText(
        w / 2 + shiftX,
        (h * 23 / 100) + shiftY,
        Graphics.FONT_NUMBER_MEDIUM,
        "🍷 " + glasses.toString(),
        Graphics.TEXT_JUSTIFY_CENTER
    );
}
```

Uppdatera `onUpdate` så att AOD-rendering tar över i sleep:

```monkey
function onUpdate(dc) {
    if (_isSleeping) {
        _drawAod(dc, dc.getWidth(), dc.getHeight());
        return;
    }

    var w = dc.getWidth();
    var h = dc.getHeight();

    dc.setColor(COLOR_BG, COLOR_BG);
    dc.clear();

    _drawTopArc(dc, w, h);
    _drawGlass(dc, w, h);
    _drawTime(dc, w, h);
    _drawDate(dc, w, h);
    _drawBottomArc(dc, w, h);
}
```

Notera: emoji-tecknet 🍷 renderas inte av Garmins system-fonter. I v1 används texten `GLAS N` istället:

Ersätt raden med emoji:

```monkey
dc.drawText(
    w / 2 + shiftX,
    (h * 23 / 100) + shiftY,
    Graphics.FONT_NUMBER_MEDIUM,
    glasses.toString(),
    Graphics.TEXT_JUSTIFY_CENTER
);
```

- [ ] **Steg 8.2: Bygg och verifiera**

Ctrl+Shift+B → "Build KultgubbenWineFace".
Förvänta: `BUILD SUCCESSFUL`.

- [ ] **Steg 8.3: Kör i simulator och testa AOD**

I simulatorn: Menu → "Display" → "Enter Sleep" (eller motsvarande).
Förvänta:
- Bakgrund svart
- Endast glas-antal (siffra) + tid visas, båda i grått
- Ingen topp/botten-kurva, inget datum
- Efter några minuter: positionen shiftar ±2px

Exit sleep (väcka): Menu → "Exit Sleep".
Förvänta: Full urtavla återvänder omedelbart.

- [ ] **Steg 8.4: Commit**

```bash
git add source/KultgubbenWineFaceView.mc
git commit -m "Task 8: AOD rendering with pixel-shift burn-in protection"
```

---

## Task 9: Slutpolering och fel-tolerans

Målet: säkerställa att urtavlan inte kraschar om någon sensor saknas, och att texten inte overflow:ar på små enheter (fenix7s).

**Files:**
- Modify: `<root>\source\KultgubbenWineFaceView.mc`

- [ ] **Steg 9.1: Testa på fenix7s (minsta skärmen i device-listan)**

Ändra VS Code task `Run in Simulator` till fenix7s:

I `.vscode/tasks.json` under "Run in Simulator" task, ändra sista arg från `"enduro3"` till `"fenix7s"`. Bygg också för fenix7s i build task.

Förvänta:
- All text får plats utan att hamna utanför skärmen
- Botten/topp-kurvor skalas proportionellt (eftersom vi använder `w/280`-ratio)

Om texten overflow:ar: ändra `Graphics.FONT_XTINY` till mindre eller förkorta labels (t.ex. "BA" istället för "BAT", "ST" istället för "STEG").

Återställ task till enduro3 efter test.

- [ ] **Steg 9.2: Hantera null-värden explicit**

Granska `_drawBottomArc` och `_drawTopArc` — alla data-källor har redan fallbacks till `--` eller `0`. Verifiera att:
- `batteryInDays` null → visar `BAT NN%`
- HR null → visar `HR --`
- Steps null → visar `STEG 0`
- Stress null → visar `STRESS --`
- BB null → visar `BB --`

Om någon rad inte följer detta, fixa.

- [ ] **Steg 9.3: Bygg och verifiera**

Ctrl+Shift+B → "Build KultgubbenWineFace". Kör i simulator på enduro3.
Förvänta: ingen krasch, alla fallbacks fungerar.

- [ ] **Steg 9.4: Commit**

```bash
git add source/KultgubbenWineFaceView.mc .vscode/tasks.json
git commit -m "Task 9: null-value fallbacks and small-screen verification"
```

---

## Task 10: Paketera .iq och sidoladda på klockan

Målet: producera en distributionsfil (`.iq`) och ladda upp den på Enduro 3 för live-test.

**Files:**
- Generated: `<root>\build\KultgubbenWineFace.prg`
- Generated: `<root>\build\KultgubbenWineFace.iq`

- [ ] **Steg 10.1: Kör "Build IQ Package"**

Ctrl+Shift+B → "Build IQ Package".
Förvänta:
- `version.txt` bumpas (t.ex. `1.0` → `1.1`)
- `build/KultgubbenWineFace.prg` skapas
- `build/KultgubbenWineFace.iq` skapas

- [ ] **Steg 10.2: Anslut Enduro 3 via USB**

Anslut klockan med USB-kabeln. Välj "MTP" / tillåt filöverföring på klockan om den frågar.
Klockan dyker upp som en enhet i File Explorer.

- [ ] **Steg 10.3: Kopiera .prg till klockan**

I File Explorer:
- Navigera till klockan → `GARMIN\APPS\` (skapa `APPS` om den saknas)
- Kopiera `C:\Users\rickard.larsson\Documents\KultgubbenWineFace\build\KultgubbenWineFace.prg` dit

- [ ] **Steg 10.4: Koppla ur klockan säkert**

Eject klockan från File Explorer.

- [ ] **Steg 10.5: Aktivera urtavlan på klockan**

På klockan:
- Håll MENU (uppe till vänster) på nuvarande urtavla
- "Watch Face" → "Customize" → bläddra till "Connect IQ Watch Faces"
- Välj "KultgubbenWine" i listan
- "Apply"

- [ ] **Steg 10.6: Testa live**

Förvänta på klockan:
- Svart urtavla med vinglas + antal i topp
- Tid + datum i mitten
- Krökta komplikationer topp + botten
- Glasantal reflekterar dagens steg + bonusminuter
- AOD: dämpad grå version när handleden sänks

- [ ] **Steg 10.7: Commit (versionsbump)**

```bash
git add version.txt
git commit -m "Task 10: release v1.1 — first sideloadable build"
```

---

## Self-Review

**Spec coverage check:**

| Spec-sektion | Task |
|---|---|
| Visuell design (layout, palett, positioner) | Task 3, 4, 5, 6, 7 |
| AOD-beteende | Task 8 |
| Teknisk arkitektur (klasser, livscykel) | Task 2 |
| Data-källor (ActivityMonitor, SensorHistory, SystemStats) | Task 3, 5, 6 |
| Vinglas-formel | Task 3 |
| Krökt text (drawRadialText) | Task 5, 6 |
| Projektstruktur | Task 1, 2 |
| Enheter (manifest products) | Task 1 |
| Build-tooling (build-iq.ps1, VS Code tasks) | Task 1 |
| Null-fallbacks | Task 9 |

**Kända kompromisser (dokumenterade som framtida förbättringar):**
- Custom serif `.fnt`-font ingår inte i v1 → systemfonter används. Spec nämnde detta som möjlig fallback.
- Ikoner i kurvtexter (🔋 👣 ♥ ⚡) ersätts med textetiketter (`BAT`, `STEG`, `HR`, `STRESS`) i v1. Grafiska ikoner kan läggas till senare som extra task (rita som Dc-primitiver eller ladda som PNG:s).
- Font-byte i AOD för glaset: emoji 🍷 finns inte i Garmin-fonter → bara siffran visas i AOD.

**Type/method consistency:**
- `_isFriSat()`, `_computeGlasses()`, `_drawGlass()`, `_drawTime()`, `_drawDate()`, `_drawTopArc()`, `_drawBottomArc()`, `_drawAod()`, `_formatSteps()`, `_getHeartRate()`, `_getSensorLatest()` — konsistent namngivning genom hela planen.
- `COLOR_BG`, `COLOR_GOLD`, `COLOR_GOLD_LIGHT`, `COLOR_GOLD_DIM`, `COLOR_GOLD_GRAY`, `COLOR_AOD_GRAY` — konstanta färger.
- `_iconGlass` — enda bitmap-resursen i v1.

---
