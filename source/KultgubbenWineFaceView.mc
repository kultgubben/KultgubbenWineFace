using Toybox.ActivityMonitor;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

class KultgubbenWineFaceView extends WatchUi.WatchFace {

    // Samma logik som KultgubbenWine / KultgubbenWineField
    const STEPS_PER_GLASS_DEFAULT = 4000;
    const STEPS_PER_GLASS_FRI_SAT = 3000;
    const ACTIVITY_MIN_VIGOROUS   = 30;

    // Palett — justerad för MIP-skärm (högre mättnad än mockupens sRGB-värden)
    const COLOR_BG          = 0x000000;
    const COLOR_GOLD        = 0xffaa00;  // Mättad bärnstens-guld
    const COLOR_GOLD_LIGHT  = 0xffcc33;  // Varmare ljus guld för tid
    const COLOR_GOLD_DIM    = 0xcc8800;  // Mörk guld för datum
    const COLOR_GOLD_GRAY   = 0xdda15e;  // Guldbrun för kurvtexter

    var _fontTime = null;       // Stor serif för tid
    var _fontNumber = null;     // Medelstor serif för glasantal
    var _fontText = null;       // Liten serif för datum
    var _fontArc = null;        // Små serif för kurvtexter

    // Senast kända sensor-värden (cacheas så vi inte blinkar "--" mellan samples)
    var _lastStress = null;
    var _lastBodyBattery = null;

    // Font-kandidater i fallback-ordning. PridiRegularGarmin är Garmins
    // anpassade slab-serif (mest "serifliknande" bland inbyggda); övriga fallback.
    const SERIF_FACES = ["PridiRegularGarmin", "PridiSemiBoldGarmin", "PridiRegular",
                         "ExoSemiBold", "RobotoCondensedRegular", "RobotoRegular"];

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
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
        _drawGlass(dc, w, h);
        _drawTime(dc, w, h);
        _drawDate(dc, w, h);
        _drawBottomArc(dc, w, h);
    }

    function _drawGlass(dc, w, h) {
        var glasses = _computeGlasses();
        var targetW = (w * 23) / 100;
        var yTop    = (h * 25) / 100;
        var scale   = targetW.toFloat() / 128.0;
        var ox      = (w / 2) - (targetW / 2);
        _drawWineGlass(dc, ox, yTop, scale, _computeFillFraction());
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

    function _computeFillFraction() {
        var steps = 0;
        try {
            var am = ActivityMonitor.getInfo();
            if (am != null && am.steps != null) { steps = am.steps; }
        } catch(e) {}
        var spg = _isFriSat() ? STEPS_PER_GLASS_FRI_SAT : STEPS_PER_GLASS_DEFAULT;
        return (steps % spg).toFloat() / spg.toFloat();
    }

    function _drawWineGlass(dc, ox, oy, scale, fillFraction) {
        // 10 control points — small angle change per segment = smooth rounded Burgundy bowl
        // Widest at y=38 (88 units), only ±0.1 slope change through the belly → no visible kink
        // xl[i] + xr[i] = 128 always (symmetric around x=64)
        var ys = [  8,  18,  28,  38,  46,  50,  62,  74,  82];
        var xl = [ 34,  30,  26,  22,  22,  24,  36,  48,  58];
        var xr = [ 94,  98, 102, 106, 106, 104,  92,  80,  70];
        var n  = 9;

        // Stem
        dc.setColor(0xBBBBBB, Graphics.COLOR_TRANSPARENT);
        var sw = (6.0 * scale).toNumber();
        if (sw < 1) { sw = 1; }
        dc.fillRectangle(
            (ox + 62.0 * scale).toNumber(), (oy + 82.0 * scale).toNumber(),
            sw, (56.0 * scale).toNumber()
        );

        // Wine fill — scanline (row-by-row) to correctly handle concave Burgundy shape
        if (fillFraction > 0.0) {
            var fillY  = 82.0 - fillFraction * (70.0 * 2.0 / 3.0);  // max fill at 2/3 of bowl
            var startPy = (oy + fillY * scale).toNumber();
            var endPy   = (oy + 82.0  * scale).toNumber();
            dc.setColor(0x992244, Graphics.COLOR_TRANSPARENT);
            for (var py = startPy; py <= endPy; py++) {
                var yNorm = (py - oy).toFloat() / scale;
                var s = n - 2;
                for (var ii = 0; ii < n - 1; ii++) {
                    if (yNorm <= ys[ii + 1]) { s = ii; break; }
                }
                var tt    = (yNorm - ys[s]) / (ys[s + 1] - ys[s]).toFloat();
                var xlRow = xl[s] + tt * (xl[s + 1] - xl[s]);
                var xrRow = xr[s] + tt * (xr[s + 1] - xr[s]);
                var rowL  = (ox + xlRow * scale).toNumber();
                var rowR  = (ox + xrRow * scale).toNumber();
                if (rowR > rowL) { dc.drawLine(rowL, py, rowR, py); }
            }

            // Surface sheen at fill level
            var seg = n - 2;
            for (var ii = 0; ii < n - 1; ii++) {
                if (fillY <= ys[ii + 1]) { seg = ii; break; }
            }
            var t      = (fillY - ys[seg]) / (ys[seg + 1] - ys[seg]).toFloat();
            var xlShen = xl[seg] + t * (xl[seg + 1] - xl[seg]);
            var xrShen = xr[seg] + t * (xr[seg + 1] - xr[seg]);
            var sheenL = (ox + xlShen * scale).toNumber() + 3;
            var sheenR = (ox + xrShen * scale).toNumber() - 3;
            var scy    = (oy + fillY  * scale).toNumber();
            if (sheenR > sheenL) {
                dc.setColor(0xCC3355, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(sheenL, scy,     sheenR, scy);
                dc.drawLine(sheenL, scy + 1, sheenR, scy + 1);
            }
        }

        // Outline — drawn on top of fill
        dc.setColor(0xBBBBBB, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < n - 1; i++) {
            dc.drawLine(
                (ox + xl[i]   * scale).toNumber(), (oy + ys[i]   * scale).toNumber(),
                (ox + xl[i+1] * scale).toNumber(), (oy + ys[i+1] * scale).toNumber()
            );
        }
        dc.drawLine(
            (ox + xl[n-1] * scale).toNumber(), (oy + ys[n-1] * scale).toNumber(),
            (ox + xr[n-1] * scale).toNumber(), (oy + ys[n-1] * scale).toNumber()
        );
        for (var i = 0; i < n - 1; i++) {
            dc.drawLine(
                (ox + xr[i]   * scale).toNumber(), (oy + ys[i]   * scale).toNumber(),
                (ox + xr[i+1] * scale).toNumber(), (oy + ys[i+1] * scale).toNumber()
            );
        }
        dc.drawLine(
            (ox + xl[0] * scale).toNumber(), (oy + ys[0] * scale).toNumber(),
            (ox + xr[0] * scale).toNumber(), (oy + ys[0] * scale).toNumber()
        );
        // Base foot
        dc.drawLine(
            (ox + 30.0 * scale).toNumber(), (oy + 138.0 * scale).toNumber(),
            (ox + 98.0 * scale).toNumber(), (oy + 138.0 * scale).toNumber()
        );
        dc.setPenWidth(1);
    }

    function _drawTime(dc, w, h) {
        var clock = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [
            clock.hour.format("%02d"),
            clock.min.format("%02d")
        ]);

        dc.setColor(COLOR_GOLD_LIGHT, Graphics.COLOR_TRANSPARENT);
        if (_fontTime != null) {
            dc.drawText(
                w / 2,
                (h * 58) / 100,
                _fontTime,
                timeStr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    function _drawDate(dc, w, h) {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateStr = Lang.format("$1$ $2$ $3$", [
            info.day_of_week,
            info.day.format("%02d"),
            info.month
        ]).toUpper();

        dc.setColor(COLOR_GOLD_DIM, Graphics.COLOR_TRANSPARENT);
        if (_fontText != null) {
            dc.drawText(
                w / 2,
                (h * 67) / 100,
                _fontText,
                dateStr,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    function _drawBottomArc(dc, w, h) {
        var cx = w / 2;
        var cy = h / 2;
        var radius = (w * 128) / 280;

        var stats = System.getSystemStats();
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

        var hr = _getHeartRate();
        var hrStr = (hr != null) ? hr.toString() : "--";

        _drawSegmentedArc(dc, cx, cy, radius, 270,
            [null, null, null],
            ["BAT: " + batteryStr, "STEP: " + stepsStr, "HR: " + hrStr],
            true);
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

    function _drawTopArc(dc, w, h) {
        var cx = w / 2;
        var cy = h / 2;
        var radius = (w * 118) / 280;  // 118/280 — mindre än botten för optisk balans

        var stress = _getSensorLatest(:getStressHistory);
        if (stress != null) { _lastStress = stress; }
        var stressStr = (_lastStress != null) ? _lastStress.toString() : "--";

        var bb = _getSensorLatest(:getBodyBatteryHistory);
        if (bb != null) { _lastBodyBattery = bb; }
        var bbStr = (_lastBodyBattery != null) ? _lastBodyBattery.toString() : "--";

        _drawSegmentedArc(dc, cx, cy, radius, 90,
            [null, null],
            ["STRESS: " + stressStr, "BODYBAT: " + bbStr],
            false);
    }

    // Ritar en sekvens av ikon+text-segment längs en båge, centrerade runt centerAngleDeg.
    // Varje segments bredd mäts dynamiskt så spacing blir konstant oavsett textinnehåll.
    // ccw=true: bottenbåge (CCW-riktning, låg→hög vinkel). false: toppbåge (CW, hög→låg).
    function _drawSegmentedArc(dc, cx, cy, radius, centerAngleDeg, icons, texts, ccw) {
        if (_fontArc == null) { return; }
        var n = icons.size();
        if (n == 0 || texts.size() != n) { return; }

        var gapIconText = 3;      // grader mellan ikon och sin text
        var gapBetweenSegments = 8;  // grader mellan två intilliggande segment
        var toDeg = 180.0 / Math.PI;

        // Mät varje segments angulära bredd i förväg
        var iconDegs = new [n];
        var textDegs = new [n];
        var totalDeg = 0.0;
        for (var i = 0; i < n; i++) {
            var iconPx = (icons[i] != null) ? icons[i].getWidth() : 0;
            iconDegs[i] = (iconPx / radius.toFloat()) * toDeg;
            var textPx = dc.getTextWidthInPixels(texts[i], _fontArc);
            textDegs[i] = (textPx / radius.toFloat()) * toDeg;
            var iconGap = (icons[i] != null) ? gapIconText : 0;
            totalDeg += iconDegs[i] + iconGap + textDegs[i];
        }
        totalDeg += gapBetweenSegments * (n - 1);

        // Direction-signs: CCW går "höger" = ökande vinkel; CW går "höger" = minskande vinkel
        var sign = ccw ? 1 : -1;
        var cursor = centerAngleDeg - sign * (totalDeg / 2.0);

        dc.setColor(COLOR_GOLD_GRAY, Graphics.COLOR_TRANSPARENT);

        var direction = ccw
            ? Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE
            : Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE;

        for (var j = 0; j < n; j++) {
            cursor = cursor + sign * (iconDegs[j] + (icons[j] != null ? gapIconText : 0));

            // Text: börjar vid cursor
            dc.drawRadialText(
                cx, cy, _fontArc, texts[j],
                Graphics.TEXT_JUSTIFY_LEFT,
                cursor, radius, direction
            );
            cursor = cursor + sign * (textDegs[j] + gapBetweenSegments);
        }
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

    function onEnterSleep() {}
    function onExitSleep() {}
}
