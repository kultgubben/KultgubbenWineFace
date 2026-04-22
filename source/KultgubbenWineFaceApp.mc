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
