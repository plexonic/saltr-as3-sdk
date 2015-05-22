/**
 * Created by TIGR on 5/12/2015.
 */
package tests.saltr {
import saltr.SLTSaltrMobile;
import saltr.SLTSaltrWeb;
import saltr.game.SLTLevel;
import saltr.game.SLTLevelPack;

public class SLTSaltrTest {
    private var _saltrMobile:SLTSaltrMobile;
    private var _saltrWeb:SLTSaltrWeb;
    private var _isSaltrMobile:Boolean;

    public function SLTSaltrTest() {
    }

    protected function setSaltrMobile(saltr:SLTSaltrMobile):void {
        _saltrMobile = saltr;
        _isSaltrMobile = true;
    }

    protected function setSaltrWeb(saltr:SLTSaltrWeb):void {
        _saltrWeb = saltr;
        _isSaltrMobile = false;
    }

    protected function clearSaltr():void {
        _saltrMobile = null;
        _saltrWeb = null;
    }

    protected function allLevelsTestPassed():Boolean {
        var testPassed:Boolean = false;
        if (_isSaltrMobile) {
            testPassed = 75 == _saltrMobile.allLevelsCount;
        } else {
            testPassed = 75 == _saltrWeb.allLevelsCount;
        }
        return testPassed;
    }

    protected function defineFeatureTestPassed():Boolean {
        var testPassed:Boolean = false;
        if (_isSaltrMobile) {
            _saltrMobile.defineFeature("SETTINGS", getDefineFeatureTestObject(), true);
            _saltrMobile.getFeatureProperties("SETTINGS");
            testPassed = 30 == _saltrMobile.getFeatureProperties("SETTINGS").general.lifeRefillTime;
        } else {
            _saltrWeb.defineFeature("SETTINGS", getDefineFeatureTestObject(), true);
            _saltrWeb.getFeatureProperties("SETTINGS");
            testPassed = 30 == _saltrWeb.getFeatureProperties("SETTINGS").general.lifeRefillTime;
        }
        return testPassed;
    }

    protected function getLevelByGlobalIndexWithValidIndexTestPassed():Boolean {
        var level:SLTLevel;
        if (_isSaltrMobile) {
            level = _saltrMobile.getLevelByGlobalIndex(20);
        } else {
            level = _saltrWeb.getLevelByGlobalIndex(20);
        }
        return 5 == level.localIndex;
    }

    protected function getLevelByGlobalIndexWithInvalidIndexPassed():Boolean {
        var level:SLTLevel;
        if (_isSaltrMobile) {
            level = _saltrMobile.getLevelByGlobalIndex(-1);
        } else {
            level = _saltrWeb.getLevelByGlobalIndex(-1);
        }
        return null == level;
    }

    protected function getPackByLevelGlobalIndexWithValidIndexPassed():Boolean {
        var levelPack:SLTLevelPack;
        if (_isSaltrMobile) {
            levelPack = _saltrMobile.getPackByLevelGlobalIndex(20);
        } else {
            levelPack = _saltrWeb.getPackByLevelGlobalIndex(20);
        }
        return 1 == levelPack.index;
    }

    protected function getPackByLevelGlobalIndexWithInvalidIndexPassed():Boolean {
        var levelPack:SLTLevelPack;
        if (_isSaltrMobile) {
            levelPack = _saltrMobile.getPackByLevelGlobalIndex(-1);
        } else {
            levelPack = _saltrWeb.getPackByLevelGlobalIndex(-1);
        }
        return null == levelPack;
    }

    private function getDefineFeatureTestObject():Object {
        return {
            general: {
                lifeRefillTime: 30
            }
        };
    }
}
}