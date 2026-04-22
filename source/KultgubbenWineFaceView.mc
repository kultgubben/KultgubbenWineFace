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

    // Palett
    const COLOR_BG          = 0x000000;
    const COLOR_GOLD        = 0xd4af37;
    const COLOR_GOLD_LIGHT  = 0xf0e6d2;
    const COLOR_GOLD_DIM    = 0x8a6d3b;
    const COLOR_GOLD_GRAY   = 0xa8936a;

    var _iconGlass = null;
    var _fontTime = null;       // Stor serif för tid
    var _fontNumber = null;     // Medelstor serif för glasantal
    var _fontText = null;       // Liten serif för datum
    var _fontArc = null;        // Små serif för kurvtexter

    // Serif-kandidater i fallback-ordning. Pridi är den mest "serifliknande"
    // bland Garmins vektor-typsnitt; övriga är sans-fallbacks.
    const SERIF_FACES = ["PridiSemiBoldGarmin", "PridiRegularGarmin", "PridiRegular",
                         "RobotoCondensedRegular", "RobotoRegular", "Swiss721Regular"];

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        _iconGlass = WatchUi.loadResource(Rez.Drawables.IconGlass);
        var w = dc.getWidth();
        _fontTime   = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 72) / 280 });
        _fontNumber = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 42) / 280 });
        _fontText   = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 20) / 280 });
        _fontArc    = Graphics.getVectorFont({ :face => SERIF_FACES, :size => (w * 22) / 280 });
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
                (h * 69) / 100,
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

        if (_fontArc == null) { return; }

        dc.setColor(COLOR_GOLD_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRadialText(
            cx, cy,
            _fontArc,
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

    function _drawTopArc(dc, w, h) {
        var cx = w / 2;
        var cy = h / 2;
        var radius = (w * 118) / 280;  // 118/280 — mindre än botten för optisk balans

        var stress = _getSensorLatest(:getStressHistory);
        var stressStr = (stress != null) ? "STRESS " + stress.toString() : "STRESS --";

        var bb = _getSensorLatest(:getBodyBatteryHistory);
        var bbStr = (bb != null) ? "BB " + bb.toString() : "BB --";

        var fullStr = stressStr + "  ·  " + bbStr;

        if (_fontArc == null) { return; }

        dc.setColor(COLOR_GOLD_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRadialText(
            cx, cy,
            _fontArc,
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
