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
