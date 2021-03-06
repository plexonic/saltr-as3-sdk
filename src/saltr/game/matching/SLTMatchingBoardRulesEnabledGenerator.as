/**
 * Created by TIGR on 3/25/2015.
 */
package saltr.game.matching {
import plexonic.error.ErrorSingletonClassInstantiation;

import saltr.game.SLTAssetInstance;
import saltr.saltr_internal;

use namespace saltr_internal;

internal class SLTMatchingBoardRulesEnabledGenerator extends SLTMatchingBoardGeneratorBase {
    private static var sInstance:SLTMatchingBoardRulesEnabledGenerator;

    saltr_internal static function getInstance():SLTMatchingBoardRulesEnabledGenerator {
        if (!sInstance) {
            sInstance = new SLTMatchingBoardRulesEnabledGenerator();
        }
        return sInstance;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private var _boardConfig:SLTMatchingBoardConfig;
    private var _layer:SLTMatchingBoardLayer;
    private var _matchedAssetPositions:Vector.<MatchedAssetPosition>;

    public function SLTMatchingBoardRulesEnabledGenerator() {
        if (sInstance) {
            throw new ErrorSingletonClassInstantiation();
        }
    }

    override saltr_internal function generate(boardConfig:SLTMatchingBoardConfig, layer:SLTMatchingBoardLayer):void {
        _boardConfig = boardConfig;
        _layer = layer;
        if (null == _matchedAssetPositions) {
            _matchedAssetPositions = new <MatchedAssetPosition>[];
        }
        parseFixedAssets(layer, _boardConfig.cells, _boardConfig.assetMap);
        parseMatchingRuleDisabledChunks();
        generateLayer(layer);
    }

    private function parseMatchingRuleDisabledChunks():void {
        var chunks:Vector.<SLTChunk> = new <SLTChunk>[];
        for (var i:int = 0, length:int = _layer.chunks.length; i < length; ++i) {
            var chunk:SLTChunk = _layer.chunks[i];
            if (false == chunk.matchingRuleEnabled) {
                chunks.push(chunk);
            }
        }
        if (chunks.length > 0) {
            generateAssetData(chunks);
            fillLayerChunkAssets(chunks);
        }
    }

    private function getMatchingRuleEnabledChunks(layer:SLTMatchingBoardLayer):Vector.<SLTChunk> {
        var chunks:Vector.<SLTChunk> = new <SLTChunk>[];
        for (var i:int = 0, length:int = _layer.chunks.length; i < length; ++i) {
            var chunk:SLTChunk = _layer.chunks[i];
            if (chunk.matchingRuleEnabled) {
                chunks.push(chunk);
            }
        }
        return chunks;
    }

    private function generateLayer(layer:SLTMatchingBoardLayer):void {
        _matchedAssetPositions.length = 0;
        generateAssetData(getMatchingRuleEnabledChunks(layer));
        fillLayerChunkAssetsWithMatchingRules();
        if (_matchedAssetPositions.length > 0) {
            correctChunksMatchesWithChunkAssets();
        }
        if (_matchedAssetPositions.length > 0) {
            fillLayerMissingChunkAssetsWithoutMatchingRules(layer);
        }
    }

    private function fillLayerMissingChunkAssetsWithoutMatchingRules(layer:SLTMatchingBoardLayer):void {
        var correctionAssets:Vector.<SLTChunkAssetDatum> = null;
        for (var i:uint = 0, length:int = _matchedAssetPositions.length; i < length; ++i) {
            var matchedCellPosition:MatchedAssetPosition = _matchedAssetPositions[i];
            var chunk:SLTChunk = _layer.getChunkWithCellPosition(matchedCellPosition.col, matchedCellPosition.row);
            if (chunk.uniqueInAvailableAssetData.length > 0) {
                correctionAssets = chunk.uniqueInAvailableAssetData.concat();
            }
            if ((null == correctionAssets) || (null != correctionAssets && correctionAssets.length <= 0)) {
                correctionAssets = chunk.uniqueInCountAssetData.concat();
            }
            if (null != correctionAssets && correctionAssets.length > 0) {
                appendChunkAssetWithoutMatchCheck(correctionAssets[0], chunk, matchedCellPosition.col, matchedCellPosition.row);
                correctionAssets.length = 0;
                correctionAssets = null;
            }
        }
    }

    private function correctChunksMatchesWithChunkAssets():void {
        var correctionAssets:Vector.<SLTChunkAssetDatum>;
        var appendingResult:Boolean = false;
        for (var i:int = _matchedAssetPositions.length - 1; i >= 0; --i) {
            var matchedCellPosition:MatchedAssetPosition = _matchedAssetPositions[i];
            var chunk:SLTChunk = _layer.getChunkWithCellPosition(matchedCellPosition.col, matchedCellPosition.row);
            correctionAssets = chunk.uniqueInAvailableAssetData;
            for (var j:uint = 0, assetsLength:int = correctionAssets.length; j < assetsLength; ++j) {
                appendingResult = appendChunkAssetWithMatchCheck(correctionAssets[j], chunk, matchedCellPosition.col, matchedCellPosition.row);
                if (appendingResult) {
                    _matchedAssetPositions.splice(i, 1);
                    break;
                }
            }
        }
    }

    private function fillLayerChunkAssetsWithMatchingRules():void {
        var positionCells:Array = new Array();
        var chunkAvailableAssetData:Vector.<SLTChunkAssetDatum>;
        var assetDatum:SLTChunkAssetDatum;
        var appendResult:Boolean;

        for (var y:int = 0, rows:int = _boardConfig.rows; y < rows; ++y) {
            for (var x:int = 0, cols:int = _boardConfig.cols; x < cols; ++x) {
                positionCells.push([x, y]);
            }
        }

        var cellRandomIndex:uint = Math.floor(Math.random() * positionCells.length);
        var chunkAssetIndex:int = 0;

        while (positionCells.length > 0) {
            x = positionCells[cellRandomIndex][0];
            y = positionCells[cellRandomIndex][1];

            var chunk:SLTChunk = _layer.getChunkWithCellPosition(x, y);

            if (null != chunk && chunk.matchingRuleEnabled && chunk.availableAssetData.length > 0) {
                chunkAvailableAssetData = chunk.availableAssetData;

                assetDatum = null;
                if (chunkAssetIndex < chunkAvailableAssetData.length) {
                    assetDatum = chunkAvailableAssetData[chunkAssetIndex];
                }

                if (null != assetDatum && "" != assetDatum.assetToken) {
                    appendResult = appendChunkAssetWithMatchCheck(assetDatum, chunk, x, y);
                    if (appendResult) {
                        chunkAvailableAssetData.splice(chunkAssetIndex, 1);
                        positionCells.splice(cellRandomIndex, 1);
                        chunkAssetIndex = 0;
                        cellRandomIndex = Math.floor(Math.random() * positionCells.length);
                        removeFromMatchedAssetPosition(x, y);
                    }
                    else {
                        addMatchedAssetPosition(x, y);
                        ++chunkAssetIndex;
                    }
                }
                else {
                    chunkAssetIndex = 0;
                    positionCells.splice(cellRandomIndex, 1);
                    cellRandomIndex = Math.floor(Math.random() * positionCells.length);
                }
            }
            else {
                positionCells.splice(cellRandomIndex, 1);
                cellRandomIndex = Math.floor(Math.random() * positionCells.length);
            }
        }
    }

    private function addMatchedAssetPosition(x:uint, y:uint):void {
        var positionFound:Boolean = false;
        for (var i:uint = 0, length:int = _matchedAssetPositions.length; i < length; ++i) {
            var currentPosition:MatchedAssetPosition = _matchedAssetPositions[i];
            if (x == currentPosition.col && y == currentPosition.row) {
                positionFound = true;
                break;
            }
        }
        if (!positionFound) {
            _matchedAssetPositions.push(new MatchedAssetPosition(x, y));
        }
    }

    private function removeFromMatchedAssetPosition(x:uint, y:uint):void {
        for (var i:uint = 0, length:int = _matchedAssetPositions.length; i < length; ++i) {
            var currentPosition:MatchedAssetPosition = _matchedAssetPositions[i];
            if (x == currentPosition.col && y == currentPosition.row) {
                _matchedAssetPositions.splice(i, 1);
                break;
            }
        }
    }

    private function appendChunkAssetWithMatchCheck(assetDatum:SLTChunkAssetDatum, chunk:SLTChunk, col:uint, row:uint):Boolean {
        var matchesCount:int = _boardConfig.matchSize - 1;
        var horizontalMatches:int = calculateHorizontalMatches(assetDatum.assetToken, col, row);
        var verticalMatches:int = calculateVerticalMatches(assetDatum.assetToken, col, row);
        var squareMatch:Boolean = false;
        var excludedAsset:Boolean = false;
        var excludedMathAssets:Vector.<SLTChunkAssetDatum> = _boardConfig.excludedMatchAssets;

        if (_boardConfig.squareMatchingRuleEnabled) {
            squareMatch = checkSquareMatch(assetDatum.assetToken, col, row);
        }

        for (var i:uint = 0, length:int = excludedMathAssets.length; i < length; ++i) {
            if (assetDatum.assetId == excludedMathAssets[i].assetId) {
                excludedAsset = true;
                break;
            }
        }

        if (excludedAsset || (horizontalMatches < matchesCount && verticalMatches < matchesCount && !squareMatch)) {
            addAssetInstanceToChunk(assetDatum, chunk, col, row);
            return true;
        }
        return false;
    }

    private function appendChunkAssetWithoutMatchCheck(assetDatum:SLTChunkAssetDatum, chunk:SLTChunk, col:uint, row:uint):void {
        addAssetInstanceToChunk(assetDatum, chunk, col, row);
    }

    private function calculateHorizontalMatches(assetToken:String, col:uint, row:uint):int {
        var i:int = 1;
        var hasMatch:Boolean = true;
        var matchesCount:int = _boardConfig.matchSize - 1;
        var siblingCellAssetToken:String;
        var horizontalMatches:uint = 0;

        while (i <= Math.min(col, matchesCount) && hasMatch) {
            siblingCellAssetToken = getAssetTokenAtPosition(_boardConfig.cells, col - i, row, _layer.token);
            hasMatch = (assetToken == siblingCellAssetToken);
            if (hasMatch) {
                ++horizontalMatches;
                ++i;
            }
        }

        i = 1;
        hasMatch = true;

        while (i <= Math.min(_boardConfig.cols - col - 1, matchesCount) && hasMatch) {
            siblingCellAssetToken = getAssetTokenAtPosition(_boardConfig.cells, col + i, row, _layer.token);
            hasMatch = (assetToken == siblingCellAssetToken);
            if (hasMatch) {
                ++horizontalMatches;
                ++i;
            }
        }

        return horizontalMatches;
    }

    private function calculateVerticalMatches(assetToken:String, col:uint, row:uint):int {
        var i:int = 1;
        var hasMatch:Boolean = true;
        var matchesCount:int = _boardConfig.matchSize - 1;
        var siblingCellAssetToken:String;
        var verticalMatches:uint = 0;

        while (i <= Math.min(row, matchesCount) && hasMatch) {
            siblingCellAssetToken = getAssetTokenAtPosition(_boardConfig.cells, col, row - i, _layer.token);
            hasMatch = (assetToken == siblingCellAssetToken);
            if (hasMatch) {
                ++verticalMatches;
                ++i;
            }
        }

        i = 1;
        hasMatch = true;

        while (i <= Math.min(_boardConfig.rows - row - 1, matchesCount) && hasMatch) {
            siblingCellAssetToken = getAssetTokenAtPosition(_boardConfig.cells, col, row + i, _layer.token);
            hasMatch = (assetToken == siblingCellAssetToken);
            if (hasMatch) {
                ++verticalMatches;
                ++i;
            }
        }

        return verticalMatches;
    }

    private function checkSquareMatch(assetToken:String, col:uint, row:uint):Boolean {
        var directionMatchesCount:uint = 0;
        var directions:Array = [
            [
                [-1, 0],
                [-1, -1],
                [0, -1]
            ],
            [
                [0, -1],
                [1, -1],
                [1, 0]
            ],
            [
                [1, 0],
                [1, 1],
                [0, 1]
            ],
            [
                [0, 1],
                [-1, 1],
                [-1, 0]
            ]
        ];
        var direction:Object;
        var hasMatch:Boolean = false;
        var siblingCellAssetToken:String;

        for (var i:uint = 0, lengthA:uint = directions.length; i < lengthA; ++i) {
            directionMatchesCount = 0;
            direction = directions[i];

            for (var j:uint = 0, lengthB:uint = direction.length; j < lengthB; ++j) {
                siblingCellAssetToken = getAssetTokenAtPosition(_boardConfig.cells, col + direction[j][0], row + direction[j][1], _layer.token);

                if (assetToken == siblingCellAssetToken) {
                    ++directionMatchesCount;
                }
                else {
                    break;
                }
            }

            if (directionMatchesCount == 3) {
                hasMatch = true;
                break;
            }
        }

        return hasMatch;
    }

    private function getAssetTokenAtPosition(boardCells:SLTCells, col:int, row:int, layerToken:String):String {
        var assetToken:String = "";
        if (col < 0 || row < 0) {
            return assetToken;
        }
        var cell:SLTCell = boardCells.retrieve(col, row);
        if (null != cell) {
            var assetInstance:SLTAssetInstance = cell.getAssetInstanceByLayerId(layerToken);
            if (null != assetInstance) {
                assetToken = cell.getAssetInstanceByLayerId(layerToken).token;
            }
        }
        return assetToken;
    }

    private function addAssetInstanceToChunk(assetDatum:SLTChunkAssetDatum, chunk:SLTChunk, col:uint, row:uint):void {
        chunk.addAssetInstanceWithPosition(assetDatum, col, row);
    }
}
}

internal class MatchedAssetPosition {
    private var _col:uint;
    private var _row:uint;

    public function MatchedAssetPosition(col:uint, row:uint):void {
        _col = col;
        _row = row;
    }

    public function get col():uint {
        return _col;
    }

    public function get row():uint {
        return _row;
    }
}