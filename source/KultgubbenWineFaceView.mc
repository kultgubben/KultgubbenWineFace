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

    var _iconGlass = null;
    var _iconBattery = null;
    var _iconFoot = null;
    var _iconHeart = null;
    var _iconBolt = null;
    var _iconBodyBattery = null;
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
        _iconGlass       = WatchUi.loadResource(Rez.Drawables.IconGlass);
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
        _drawGlass(dc, w, h);
        _drawTime(dc, w, h);
        _drawDate(dc, w, h);
        _drawBottomArc(dc, w, h);
    }

    function _drawGlass(dc, w, h) {
        var glasses = _computeGlasses();

        // Glas-ikonen uppskalad till ~23 % av skärmbredden.
        // Topp-kanten placerad så hela gruppen (glas + tid + datum) blir centrerad.
        var targetSize = (w * 23) / 100;  // ~64 px på 280 px-skärm
        var yTop = (h * 25) / 100;
        var x = (w / 2) - (targetSize / 2);
        if (_iconGlass != null) {
            dc.drawScaledBitmap(x, yTop, targetSize, targetSize, _iconGlass);
        }

        // Antal glas: serif-guld till höger om glaset, vertikalt centrerat med glaset
        dc.setColor(COLOR_GOLD, Graphics.COLOR_TRANSPARENT);
        if (_fontNumber != null) {
            dc.drawText(
                w / 2 + (targetSize / 2) + 6,
                yTop + (targetSize / 2),
                _fontNumber,
                glasses.toString(),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
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
        var radius = (w * 128) / 280;  // 128/280 proportion

        // Hämta data
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

        if (_fontArc == null) { return; }

        dc.setColor(COLOR_GOLD_GRAY, Graphics.COLOR_TRANSPARENT);

        // Tre segment längs botten-kurvan (270° = rakt ned).
        // Icon först, sedan text direkt till höger om ikonen (CCW = högre vinkel).
        _drawArcSegment(dc, cx, cy, radius, 240, _iconBattery, batteryStr, true);
        _drawArcSegment(dc, cx, cy, radius, 270, _iconFoot, stepsStr, true);
        _drawArcSegment(dc, cx, cy, radius, 300, _iconHeart, hrStr, true);
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

        if (_fontArc == null) { return; }

        dc.setColor(COLOR_GOLD_GRAY, Graphics.COLOR_TRANSPARENT);

        // Två segment längs topp-kurvan (90° = rakt upp).
        // CW-riktning: högre vinkel till vänster, lägre till höger.
        _drawArcSegment(dc, cx, cy, radius, 105, _iconBolt, stressStr, false);
        _drawArcSegment(dc, cx, cy, radius, 75,  _iconBodyBattery, bbStr, false);
    }

    // Ritar en ikon roterad i tangentens riktning vid angleDeg på en båge,
    // följt av text direkt efter ikonen. ccw=true för botten (CCW), false för topp (CW).
    function _drawArcSegment(dc, cx, cy, radius, angleDeg, icon, text, ccw) {
        if (icon != null) {
            // Ikon-rotation så "upp" pekar inåt (botten-kurva) / utåt (topp-kurva),
            // matchande textens tangent-orientering längs bågen.
            // CCW bottenkurva: rotation_deg = 270 - angleDeg (matematisk konv., + = CCW math = CW skärm)
            // CW toppkurva:    rotation_deg =  90 - angleDeg
            var rotDeg = ccw ? (270 - angleDeg) : (90 - angleDeg);
            var rotRad = rotDeg * Math.PI / 180.0;

            var iconW = icon.getWidth();
            var iconH = icon.getHeight();
            var halfW = iconW / 2.0;
            var halfH = iconH / 2.0;

            // Beräkna ikon-centrumets position på bågen
            var rad = angleDeg * Math.PI / 180.0;
            var px = cx + (radius * Math.cos(rad));
            var py = cy - (radius * Math.sin(rad));

            // Bygg transform: rotera runt ikonens egen mittpunkt
            var xform = new Graphics.AffineTransform();
            xform.translate(halfW, halfH);
            xform.rotate(rotRad);
            xform.translate(-halfW, -halfH);

            // drawBitmap2 placerar top-left vid (x, y) efter transformen
            dc.drawBitmap2(px - halfW, py - halfH, icon, {
                :transform => xform
            });
        }

        if (text == null || _fontArc == null) { return; }

        // Text-start: halv ikonbredd + litet gap, översatt till grader via arc-längd
        var iconAngularHalf = 0;
        if (icon != null) {
            iconAngularHalf = ((icon.getWidth() / 2.0) / radius) * 180.0 / Math.PI;
        }
        var gap = 2;
        var textStartAngle = ccw
            ? angleDeg + iconAngularHalf + gap
            : angleDeg - iconAngularHalf - gap;

        var direction = ccw
            ? Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE
            : Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE;

        dc.drawRadialText(
            cx, cy,
            _fontArc,
            text,
            Graphics.TEXT_JUSTIFY_LEFT,
            textStartAngle,
            radius,
            direction
        );
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
