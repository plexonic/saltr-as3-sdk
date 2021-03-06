/*
 * Copyright (c) 2014 Plexonic Ltd
 */

package saltr.resource {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.TimerEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.utils.Timer;

import saltr.saltr_internal;
import saltr.utils.SLTHTTPStatus;

use namespace saltr_internal;


/**
 * The SLTResource class represents the resource.
 * @private
 */
//TODO @GSAR: review optimize this class!
public class SLTResource {

    private var _id:String;
    private var _isLoaded:Boolean;
    private var _ticket:SLTResourceURLTicket;
    private var _fails:int;
    private var _maxAttempts:int;
    private var _dropTimeout:Number;
    private var _httpStatus:int;
    private var _timeoutTimer:Timer;
    private var _urlLoader:URLLoader;
    private var _onSuccess:Function;
    private var _onFail:Function;
    private var _timeoutIncrease:int;
    private var _dataFormat:String;

    /**
     * Class constructor.
     * @param id The id of asset.
     * @param ticket The ticket for loading the asset.
     * @param onSuccess The callback function if loading succeed, function signature is function(asset:Asset).
     * @param onFail The callback function if loading fail, function signature is function(asset:Asset).
     * @param dataFormat Controls whether the downloaded data is received as text (URLLoaderDataFormat.TEXT), raw binary data (URLLoaderDataFormat.BINARY), or URL-encoded variables (URLLoaderDataFormat.VARIABLES).
     */
    public function SLTResource(id:String, ticket:SLTResourceURLTicket, onSuccess:Function, onFail:Function, dataFormat:String = URLLoaderDataFormat.TEXT) {
        _id = id;
        _ticket = ticket;
        _onSuccess = onSuccess;
        _onFail = onFail;
        _maxAttempts = _ticket.maxAttempts;
        _fails = 0;
        _dropTimeout = _ticket.dropTimeout;
        _httpStatus = -1;
        _timeoutIncrease = _ticket.timeoutIncrease;
        _dataFormat = dataFormat;
        initLoader();
    }

    /**
     * Data format.
     */
    public function get dataFormat():String {
        return _dataFormat;
    }

    /**
     * The loaded bytes.
     */
    saltr_internal function get bytesLoaded():int {
        return _urlLoader.bytesLoaded;
    }

    /**
     * The total bytes.
     */
    saltr_internal function get bytesTotal():int {
        return _urlLoader.bytesTotal;
    }

    /**
     * The loaded percent.
     */
    saltr_internal function get percentLoaded():int {
        return Math.round((bytesLoaded / bytesTotal) * 100.0);
    }

    /**
     * The JSON data.
     */
    saltr_internal function get jsonData():Object {
        var json:Object = null;
        try {
            json = JSON.parse(_urlLoader.data);
        }
        catch (e:Error) {
            trace("[SALTR][JSONAsset] JSON parsing Error. " + _ticket.variables + " \n  " + _urlLoader.data);
        }
        return json;
    }

    /**
     * The String data.
     */
    saltr_internal function get data():Object {
        return _urlLoader.data
    }

    /**
     * Starts load.
     */
    saltr_internal function load():void {
        initLoaderListeners(_urlLoader);
        _urlLoader.load(_ticket.getURLRequest());
        startDropTimeoutTimer();
    }

    /**
     * Stops load.
     */
    saltr_internal function stop():void {
        try {
            _urlLoader.close();
        } catch (e:Error) {
        }
    }

    /**
     * Dispose function.
     */
    saltr_internal function dispose():void {
        _urlLoader = null;
        _onSuccess = null;
        _onFail = null;
    }

    protected function initLoader():void {
        _urlLoader = new URLLoader();
        _urlLoader.dataFormat = _dataFormat;
        initLoaderListeners(_urlLoader);
    }

    /////////////////////////////////////////////
    //Handling Dropout Timer
    protected function startDropTimeoutTimer():void {
        if (_dropTimeout != 0.0) {
            _timeoutTimer = new Timer(_dropTimeout + _fails * _timeoutIncrease, 1);
            _timeoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, dropTimeOutTimerHandler);
            _timeoutTimer.start();
        }
    }

    protected function stopDropTimeoutTimer():void {
        if (_timeoutTimer == null) {
            return;
        }
        _timeoutTimer.stop();
        _timeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, dropTimeOutTimerHandler);
        _timeoutTimer = null;
    }

    protected function dropTimeOutTimerHandler(event:TimerEvent):void {
        trace("[SALTR][Error] Asset loading takes too long, so it is force-stopped.");
        _urlLoader.close();
        loadFailed(_urlLoader);
    }

    /////////////////////////////////////////////

    protected function initLoaderListeners(dispatcher:EventDispatcher):void {
        dispatcher.addEventListener(Event.COMPLETE, completeHandler);
        dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
        dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
        if (HTTPStatusEvent.HTTP_RESPONSE_STATUS) {
            dispatcher.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpResponseStatusHandler);
        }
        dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
    }

    protected function removeLoaderListeners(dispatcher:EventDispatcher):void {
        dispatcher.removeEventListener(Event.COMPLETE, completeHandler);
        dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
        dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
        if (HTTPStatusEvent.HTTP_RESPONSE_STATUS) {
            dispatcher.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpResponseStatusHandler);
        }
        dispatcher.removeEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
    }

    private function completeHandler(event:Event):void {
        stopDropTimeoutTimer();
        var dispatcher:EventDispatcher = event.target as EventDispatcher;
        removeLoaderListeners(dispatcher);
        if (SLTHTTPStatus.isInSuccessCodes(_httpStatus)) {
            _isLoaded = true;
            _onSuccess(this);
        }
        else {
            _onFail(this);
            trace("[SALTR][Error] Asset with path '" + _ticket.url + "' cannot be found.");
        }
    }

    private function ioErrorHandler(event:IOErrorEvent):void {
        loadFailed(event.target as EventDispatcher);
    }

    private function loadFailed(dispatcher:EventDispatcher):void {
        _fails++;
        stopDropTimeoutTimer();
        removeLoaderListeners(dispatcher);
        if (_fails == _maxAttempts) {
            _onFail(this);
        } else {
            load();
        }
    }

    private function securityErrorHandler(event:SecurityErrorEvent):void {
        stopDropTimeoutTimer();
        var dispatcher:EventDispatcher = event.target as EventDispatcher;
        removeLoaderListeners(dispatcher);
        _onFail(this);
    }

    private function httpStatusHandler(event:HTTPStatusEvent):void {
        var dispatcher:EventDispatcher = event.target as EventDispatcher;
        dispatcher.removeEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
        _httpStatus = event.status;
    }

    private function httpResponseStatusHandler(event:HTTPStatusEvent):void {
        var dispatcher:EventDispatcher = event.target as EventDispatcher;
        dispatcher.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpResponseStatusHandler);
        _httpStatus = event.status;
    }
}
}
