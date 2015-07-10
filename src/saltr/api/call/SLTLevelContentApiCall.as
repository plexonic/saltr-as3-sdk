package saltr.api.call {
import flash.net.URLVariables;

import saltr.resource.SLTResource;
import saltr.saltr_internal;

use namespace saltr_internal;

/**
 * @private
 */
public class SLTLevelContentApiCall extends SLTApiCall {
    public function SLTLevelContentApiCall(isMobile:Boolean = true) {
        super(isMobile);
    }

    override saltr_internal function validateMobileParams():Object {
        return validateLevelContentUrl();
    }

    override saltr_internal function validateWebParams():Object {
        return validateLevelContentUrl();
    }

    override saltr_internal function buildCall():URLVariables {
        _url = _params.contentUrl;
        return null;
    }

    override saltr_internal function callRequestCompletedHandler(resource:SLTResource):void {
        var content:Object = resource.jsonData;
        var apiCallResult:SLTApiCallResult = new SLTApiCallResult();
        apiCallResult.success = content != null;
        apiCallResult.data = content;
        handleResult(apiCallResult);
    }

    private function validateLevelContentUrl():Object {
        var contentURL:String = _params.contentUrl;
        if (contentURL == null || contentURL == "") {
            return {isValid: false, message: "Missing contentUrl."};
        }
        return {isValid: true};
    }
}
}