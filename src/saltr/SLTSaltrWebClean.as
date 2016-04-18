/**
 * Created by daal on 4/7/16.
 */
package saltr {
import saltr.api.call.SLTApiCall;
import saltr.api.call.factory.SLTApiCallFactory;
import saltr.api.call.factory.SLTWebApiCallFactory;
import saltr.game.SLTLevel;

use namespace saltr_internal;

public class SLTSaltrWebClean extends SLTSaltr {

    private var _sltLevel:SLTLevel;
    private var _callback:Function;

    public function SLTSaltrWebClean(clientKey:String, deviceId:String = null, socialId:String = null) {
        super(clientKey, deviceId, socialId);

        SLTApiCallFactory.factory = new SLTWebApiCallFactory();
    }

    override public function start():void {
        if (_socialId == null) {
            throw new Error("socialId field is required and can't be null.");
        }

        _appData.initEmpty();
        _started = true;
    }


    override public function initLevelContent(gameLevelsFeatureToken:String, sltLevel:SLTLevel, callback:Function, fromSaltr:Boolean = false):void {
        super.initLevelContent(gameLevelsFeatureToken, sltLevel, callback, true);
    }


    override protected function initLevelContentFromSaltr(gameLevelsFeatureToken:String, sltLevel:SLTLevel, callback:Function):void {
        _sltLevel = sltLevel;
        _callback = callback;

        var params:Object = {
            contentUrl: sltLevel.contentUrl
        };

        var levelContentApiCall:SLTApiCall = SLTApiCallFactory.factory.getCall(SLTApiCallFactory.API_CALL_LEVEL_CONTENT);
        levelContentApiCall.call(params, levelContentLoadSuccessCallback, levelContentLoadFailCallback, _requestIdleTimeout);
    }

    private function levelContentLoadSuccessCallback(data:Object):void {
        _sltLevel.updateContent(data);
        _callback(true);
    }

    private function levelContentLoadFailCallback():void {
        _callback(false);
    }
}
}