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
