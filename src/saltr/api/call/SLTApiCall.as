package saltr.api.call {
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;

import saltr.resource.SLTResource;
import saltr.resource.SLTResourceURLTicket;
import saltr.saltr_internal;
import saltr.status.SLTStatus;

use namespace saltr_internal;

/**
 * @private
 */
public class SLTApiCall {
    saltr_internal static const MOBILE_CLIENT:String = "AS3-Mobile";
    saltr_internal static const WEB_CLIENT:String = "AS3-Web";
    saltr_internal static const API_VERSION:String = "1.9.0";

    protected var _url:String;
    protected var _params:Object;
    protected var _successCallback:Function;
    protected var _failCallback:Function;
    protected var _isMobile:Boolean;
    protected var _client:String;
    protected var _nativeTimeout:int;
    protected var _dropTimeout:int;
    protected var _timeoutIncrease:int;

    internal static function removeEmptyAndNullsJSONReplacer(k:*, v:*):* {
        //if type of v is boolean v!="" always return false, and during json.stringify property is removed.
        if (v != null && v != "null" && v !== "") {
            return v;
        }
        return undefined;
    }

    internal static function getTicket(url:String, vars:URLVariables, timeout:int = 0, method:String = URLRequestMethod.POST):SLTResourceURLTicket {
        var ticket:SLTResourceURLTicket = new SLTResourceURLTicket(url, vars);
        ticket.method = method;
        if (timeout > 0) {
            ticket.idleTimeout = timeout;
        }
        return ticket;
    }

    public function SLTApiCall(isMobile:Boolean = true) {
        _isMobile = isMobile;
        _client = _isMobile ? MOBILE_CLIENT : WEB_CLIENT;
    }

    saltr_internal function call(params:Object, successCallback:Function = null, failCallback:Function = null, nativeTimeout:int = 0, dropTimeout:int = 0, timeoutIncrease:int = 0):void {
        _params = params;
        _successCallback = successCallback;
        _failCallback = failCallback;
        _nativeTimeout = nativeTimeout;
        _dropTimeout = dropTimeout;
        _timeoutIncrease = timeoutIncrease;
        var validationResult:Object = validateParams();
        if (validationResult.isValid == false) {
            returnValidationFailedResult(validationResult.message);
            return;
        }

        var urlVars:URLVariables = buildCall();
        doCall(urlVars);
    }

    private function returnValidationFailedResult(message:String):void {
        var apiCallResult:SLTApiCallResult = new SLTApiCallResult();
        apiCallResult.success = false;
        apiCallResult.status = new SLTStatus(SLTStatus.API_ERROR, message);
        handleResult(apiCallResult);
    }

    private function doCall(urlVars:URLVariables):void {
        var ticket:SLTResourceURLTicket = getURLTicket(urlVars, _nativeTimeout);
        ticket.dropTimeout = _dropTimeout;
        ticket.timeoutIncrease = _timeoutIncrease;
        var resource:SLTResource = new SLTResource("apiCall", ticket, callRequestCompletedHandler, callRequestFailHandler, getDataFormat());
        resource.load();
    }

    saltr_internal function getDataFormat():String {
        return URLLoaderDataFormat.TEXT;
    }

    saltr_internal function getURLTicket(urlVars:URLVariables, timeout:int):SLTResourceURLTicket {
        return SLTApiCall.getTicket(_url, urlVars, timeout);
    }

    saltr_internal function callRequestCompletedHandler(resource:SLTResource):void {
        var jsonData:Object = resource.jsonData;
        var success:Boolean = false;
        var apiCallResult:SLTApiCallResult = new SLTApiCallResult();
        var response:Object;
        if (jsonData && jsonData.hasOwnProperty("response")) {
            response = jsonData.response[0];
            success = response.success;
            if (success) {
                apiCallResult.data = response;
            } else {
                apiCallResult.status = new SLTStatus(response.error.code, response.error.message);
            }
        }
        else {
            var status:SLTStatus = new SLTStatus(SLTStatus.API_ERROR, "unknown API error: wrong response");
            apiCallResult.status = status;
        }

        apiCallResult.success = success;
        resource.dispose();
        handleResult(apiCallResult);
    }

    saltr_internal function callRequestFailHandler(resource:SLTResource):void {
        resource.dispose();
        var apiCallResult:SLTApiCallResult = new SLTApiCallResult();
        apiCallResult.status = new SLTStatus(SLTStatus.API_ERROR, "API call request failed.");
        handleResult(apiCallResult);
    }


    saltr_internal function buildCall():URLVariables {
        throw new Error("abstract method call error");
    }

    //TODO::daal. Now it is just an plain Object. Will be replaced with ValidationResult object...
    saltr_internal function validateParams():Object {
        if (_isMobile) {
            return validateMobileParams();
        }
        else {
            return validateWebParams();
        }
    }

    saltr_internal function validateMobileParams():Object {
        return validateDefaultMobileParams();
    }

    saltr_internal function validateWebParams():Object {
        return validateDefaultWebParams();
    }

    saltr_internal function validateDefaultMobileParams():Object {
        if (_params.deviceId == null) {
            return {isValid: false, message: "Field deviceId is required"};
        }
        if (_params.clientKey == null) {
            return {isValid: false, message: "Field clientKey is required"};
        }
        return {isValid: true};
    }

    saltr_internal function validateDefaultWebParams():Object {
        if (_params.socialId == null) {
            return {isValid: false, message: "Field socialId is required"};
        }
        if (_params.clientKey == null) {
            return {isValid: false, message: "Field clientKey is required"};
        }
        return {isValid: true};
    }

    saltr_internal function buildDefaultArgs():Object {
        var args:Object = {};
        if (_isMobile) {
            args.deviceId = _params.deviceId;
        }
        //socialId optional for Mobile, required for Web
        args.socialId = _params.socialId;
        args.apiVersion = SLTApiCall.API_VERSION;
        args.clientKey = _params.clientKey;
        args.client = _client;
        args.devMode = _params.devMode;
        return args;
    }

    internal function handleResult(result:SLTApiCallResult):void {
        if (result.success) {
            if (_successCallback != null) {
                _successCallback(result.data);
            }
        } else {
            if (_failCallback != null) {
                _failCallback(result.status);
            }
        }
    }

    //TODO: implement dispose
    protected function dispose():void {
        _params = null;
        _successCallback = null;
        _failCallback = null;
    }
}
}