/*
 * Copyright (c) 2014 Plexonic Ltd
 */

package saltr {
import saltr.game.SLTLevel;

use namespace saltr_internal;

/**
 * The SLTLevelCollection class provides the level data.
 */
public class SLTLevelCollectionBody {

    private var _levels:Vector.<SLTLevel>;

    /**
     * Class constructor.
     */
    public function SLTLevelCollectionBody(data:Object) {
        _levels = SLTDeserializer.decodeAndCreateNewLevels(data);
        sortLevel();
    }

    /**
     * All levels
     */
    public function get allLevels():Vector.<SLTLevel> {
        return _levels;
    }

    /**
     * All levels count.
     */
    public function get allLevelsCount():uint {
        return _levels.length;
    }

    /**
     *
     */
    public function updateLevels(data:Object):void {
        SLTDeserializer.decodeAndUpdateExistingLevels(data, _levels);
    }

    /**
     * Provides level with given level token
     * @param token The token of the level
     */
    public function getLevelByToken(token:String):SLTLevel {
        for (var i:int = 0, len:int = _levels.length; i < len; ++i) {
            var level:SLTLevel = _levels[i];
            if (token == level.levelToken) {
                return level;
            }
        }
        return null;
    }

    /**
     * Provides level with given global index
     * @param index The global index
     */
    public function getLevelByGlobalIndex(index:int):SLTLevel {
        if (index < 0 || index >= _levels.length) {
            return null;
        }
        for (var i:int = 0, len:int = _levels.length; i < len; ++i) {
            var level:SLTLevel = _levels[i];
            if (index == level.globalIndex) {
                return level;
            }
        }
        return null;
    }

    private function sortLevel():void {
        _levels.sort(function (level1:SLTLevel, level2:SLTLevel):Number {
            return level1.globalIndex - level2.globalIndex;
        })
    }

    private function disposeLevels():void {
        _levels.length = 0;
    }

}
}
