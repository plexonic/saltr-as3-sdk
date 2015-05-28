/**
 * Created by TIGR on 2/27/2015.
 */
package {
import flash.display.Sprite;
import flash.display.Stage;

import org.flexunit.internals.TraceListener;
import org.flexunit.listeners.AirCIListener;
import org.flexunit.runner.FlexUnitCore;

import tests.saltr.AppDataTest;
import tests.saltr.LevelDataTest;
import tests.saltr.SLTImportLevelsMobileTest;
import tests.saltr.SLTLoadLevelContentMobileTest;
import tests.saltr.SLTSaltrMobileTest;
import tests.saltr.SLTSaltrMobileTestWithConnection;
import tests.saltr.SLTSaltrWebTest;
import tests.saltr.SLTStartTest;
import tests.saltr.api.AddPropertiesApiCallTest;
import tests.saltr.api.AppDataApiCallTest;
import tests.saltr.api.HeartbeatApiCallTest;
import tests.saltr.api.LevelContentApiCallTest;
import tests.saltr.api.RegisterDeviceApiCallTest;
import tests.saltr.api.RegisterUserApiCallTest;
import tests.saltr.api.SendLevelEndApiCallTest;
import tests.saltr.api.SyncApiCallTest;
import tests.saltr.game.SLTLevelTest;
import tests.saltr.game.canvas2d.SLT2DAssetInstanceTest;
import tests.saltr.game.matching.SLTCellTest;
import tests.saltr.game.matching.SLTCellsTest;

public class FlexUnitRunner extends Sprite {

    public static var STAGE:Stage;

    public function FlexUnitRunner() {
        onCreationComplete();
    }

    private function onCreationComplete():void {
        STAGE = stage;
        var core:FlexUnitCore = new FlexUnitCore();
        core.addListener(new TraceListener());
        core.addListener(new AirCIListener());
        core.visualDisplayRoot = STAGE;
        core.run(currentRunTestSuite());
    }

    public function currentRunTestSuite():Array {
        var testsToRun:Array = new Array();
        testsToRun.push(SLTSaltrMobileTest);
        testsToRun.push(SLTImportLevelsMobileTest);
        testsToRun.push(SLTStartTest);
        testsToRun.push(AppDataTest);
        testsToRun.push(LevelDataTest);
        testsToRun.push(SLTCellTest);
        testsToRun.push(SLTCellsTest);
        testsToRun.push(SLTSaltrMobileTestWithConnection);
        testsToRun.push(SLTLoadLevelContentMobileTest);
        testsToRun.push(SLTLevelTest);
        testsToRun.push(SLT2DAssetInstanceTest);
        testsToRun.push(AddPropertiesApiCallTest);
        testsToRun.push(AppDataApiCallTest);
        testsToRun.push(HeartbeatApiCallTest);
        testsToRun.push(LevelContentApiCallTest);
        testsToRun.push(RegisterDeviceApiCallTest);
        testsToRun.push(RegisterUserApiCallTest);
        testsToRun.push(SendLevelEndApiCallTest);
        testsToRun.push(SyncApiCallTest);
        testsToRun.push(SLTSaltrWebTest);
        return testsToRun;
    }
}
}
