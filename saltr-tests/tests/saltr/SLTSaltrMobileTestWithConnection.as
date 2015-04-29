/**
 * Created by TIGR on 4/28/2015.
 */
package tests.saltr {
import mockolate.runner.MockolateRule;
import mockolate.stub;

import org.flexunit.asserts.assertEquals;

import saltr.SLTSaltrMobile;
import saltr.api.ApiCallResult;
import saltr.api.ApiFactory;
import saltr.repository.SLTMobileRepository;
import saltr.saltr_internal;
import saltr.status.SLTStatus;

use namespace saltr_internal;

/**
 * The SLTSaltrMobileTestWithConnection class contain the tests which can be performed with saltr.connect()
 */
public class SLTSaltrMobileTestWithConnection {
    [Embed(source="../../../build/tests/saltr/app_data.json", mimeType="application/octet-stream")]
    private static const AppDataJson:Class;

    [Embed(source="../../../build/tests/saltr/level_packs.json", mimeType="application/octet-stream")]
    private static const LevelPacksJson:Class;

    private var clientKey:String = "";
    private var deviceId:String = "";
    private var _saltr:SLTSaltrMobile;

    [Rule]
    public var mocks:MockolateRule = new MockolateRule();
    [Mock(type="nice")]
    public var mobileRepository:SLTMobileRepository;
    [Mock(type="nice")]
    public var apiFactory:ApiFactory;
    [Mock(type="nice")]
    public var apiCallMock:ApiCallMock;

    public function SLTSaltrMobileTestWithConnection() {
    }

    [Before]
    public function tearUp():void {
        stub(mobileRepository).method("getObjectFromApplication").returns(JSON.parse(new LevelPacksJson()));
        stub(mobileRepository).method("cacheObject").calls(function():void{trace("cacheObject")});
        stub(mobileRepository).method("getObjectFromCache").returns(null);

        stub(apiFactory).method("getCall").returns(apiCallMock);

        _saltr = new SLTSaltrMobile(FlexUnitRunner.STAGE, clientKey, deviceId);
        _saltr.apiFactory = apiFactory;
        _saltr.repository = mobileRepository;

        _saltr.defineFeature("SETTINGS", {
            general: {
                lifeRefillTime: 30
            }
        }, true);

        //importLevels() takes as input levels path, in this test it is just a dummy value because of MobileRepository's mocking
        _saltr.importLevels("");
    }

    [After]
    public function tearDown():void {
        _saltr = null;
    }

    /**
     * connectTestNotStarted.
     * The intent of this test is to check the connect function without start(). An Error should be thrown.
     */
    [Test(expects="Error")]
    public function connectTestNotStarted():void {
        var successCallback:Function;
        var failCallback:Function;
        _saltr.connect(successCallback, failCallback);
    }

    /**
     * connectTestFailCallback.
     * The intent of this test is to check the connect function. Failed callback should be called.
     */
    [Test]
    public function connectTestFailCallback():void {
        var apiCallResult:ApiCallResult = new ApiCallResult();
        apiCallResult.status = new SLTStatus(SLTStatus.API_ERROR, "API call request failed.");
        stub(apiCallMock).method("getMockedCallResult").returns(apiCallResult);

        var isFailed:Boolean = false;
        var successCallback:Function;
        var failCallback:Function = function ():void {
            isFailed = true;
        };

        _saltr.start();
        _saltr.connect(successCallback, failCallback);
        assertEquals(true, isFailed);
    }

    /**
     * connectTestWithSuccess.
     * The intent of this test is to check the connect function.
     * Everything is OK, sync() not called, heartbeat() started.
     */
    [Test]
    public function connectTestWithSuccess():void {
        var apiCallResult:ApiCallResult = new ApiCallResult();
        //apiCallResult.status = new SLTStatus(SLTStatus.API_ERROR, "API call request failed.");
        apiCallResult.data = JSON.parse(new AppDataJson());
        apiCallResult.success = true;
        stub(apiCallMock).method("getMockedCallResult").returns(apiCallResult);

        var isConnected:Boolean = false;
        var failCallback:Function;
        var successCallback:Function = function ():void {
            isConnected = true;
        };

        _saltr.start();
        _saltr.connect(successCallback, failCallback);
        assertEquals(true, isConnected);
    }
}
}
