/**
 * Created by daal on 6/24/15.
 */
package saltr.repository {
import flash.filesystem.File;

import saltr.SLTConfig;
import saltr.SLTDeserializer;
import saltr.saltr_internal;
import saltr.utils.SLTUtils;

use namespace saltr_internal;

public class SLTRepositoryStorageManager {

    private var _repository:ISLTRepository;
    private var _localContentRoot:String;

    private static function getCachedAppDataUrl():String {
        return SLTUtils.formatString(SLTConfig.CACHE_VERSIONED_APP_DATA_URL_TEMPLATE, SLTUtils.getAppVersion());
    }

    private static function getLevelDataFromApplicationUrl(contentRoot:String, token:String):String {
        return SLTUtils.formatString(SLTConfig.LOCAL_LEVEL_DATA_URL_TEMPLATE, contentRoot, token);
    }

    private static function getCachedLevelVersionsUrl(gameLevelsFeatureToken:String):String {
        return SLTUtils.formatString(SLTConfig.CACHE_VERSIONED_LEVEL_VERSIONS_URL_TEMPLATE, SLTUtils.getAppVersion(), gameLevelsFeatureToken);
    }

    private static function getCachedLevelUrl(gameLevelsFeatureToken:String, globalIndex:int):String {
        return SLTUtils.formatString(SLTConfig.CACHE_VERSIONED_LEVEL_URL_TEMPLATE, SLTUtils.getAppVersion(), gameLevelsFeatureToken, globalIndex);
    }

    private static function isCurrentAppVersionCacheDirExists(cacheDirectory:File):Boolean {
        var dir:File = cacheDirectory.resolvePath(SLTUtils.formatString(SLTConfig.CACHE_VERSIONED_CONTENT_ROOT_URL_TEMPLATE, SLTUtils.getAppVersion()));
        return dir.exists;
    }

    private static function cleanupCache(cacheDirectory:File):void {
        var rootDir:File = cacheDirectory.resolvePath(SLTConfig.DEFAULT_CONTENT_ROOT);
        if (rootDir.exists) {
            var contents:Array = rootDir.getDirectoryListing();
            var currentAppCacheName:String = "app_" + SLTUtils.getAppVersion();
            for (var i:uint = 0; i < contents.length; i++) {
                var contentName:String = contents[i].name;
                if (currentAppCacheName != contentName && 0 == contentName.indexOf("app_")) {
                    var dir:File = rootDir.resolvePath(contents[i].name);
                    if (dir.isDirectory) {
                        dir.deleteDirectory(true);
                    }
                }
            }
        }
    }

    public function SLTRepositoryStorageManager(repository:ISLTRepository) {
        _repository = repository;
        _localContentRoot = SLTConfig.DEFAULT_CONTENT_ROOT;
    }

    /**
     * Defines the local content root.
     * @param contentRoot The content root url.
     */
    public function setLocalContentRoot(contentRoot:String):void {
        _localContentRoot = contentRoot;
    }

    /**
     * Provides an object from storage.
     * @param name The name of the object.
     * @return The requested object.
     */
    public function getObjectFromStorage(fileName:String):Object {
        return _repository.getObjectFromStorage(fileName);
    }

    /**
     * Provides the cached application data.
     * @return The cached application data.
     */
    public function getAppDataFromCache():Object {
        return _repository.getObjectFromCache(getCachedAppDataUrl());
    }

    /**
     * Provides an level object from cache.
     * @param gameLevelsFeatureToken The GameLevels feature token
     * @param globalIndex The global identifier of the cached level.
     * @return The requested level from cache.
     */
    public function getLevelFromCache(gameLevelsFeatureToken:String, globalIndex:int):Object {
        return _repository.getObjectFromCache(getCachedLevelUrl(gameLevelsFeatureToken, globalIndex));
    }

    /**
     * Provides the cached level version.
     * @param gameLevelsFeatureToken The GameLevels feature token
     * @param globalIndex The global identifier of the cached level.
     * @return The version of the cached level.
     */
    public function getLevelVersionFromCache(gameLevelsFeatureToken:String, globalIndex:int):String {
        var version:String = null;
        var cachedLevelFile:Object = _repository.getObjectFromCache(getCachedLevelUrl(gameLevelsFeatureToken, globalIndex));
        if (null != cachedLevelFile) {
            var cachedLevelVersions:Object = _repository.getObjectFromCache(getCachedLevelVersionsUrl(gameLevelsFeatureToken));
            if (null != cachedLevelVersions) {
                version = SLTDeserializer.getCachedLevelVersion(cachedLevelVersions, globalIndex);
            }
        }
        return version;
    }

    /**
     * Stores an object.
     * @param name The name of the object.
     * @param object The object to store.
     */
    public function saveObject(fileName:String, objectToSave:Object):void {
        _repository.saveObject(fileName, objectToSave);
    }

    /**
     * Caches an level content.
     * @param gameLevelsFeatureToken The "GameLevels" feature token the level belong to.
     * @param globalIndex The global index of the level.
     * @param version The version of the level.
     * @param object The level to store.
     */
    public function cacheLevelContent(gameLevelsFeatureToken:String, globalIndex:int, version:String, object:Object):void {
        var cachedLevelFileName:String = getCachedLevelUrl(gameLevelsFeatureToken, globalIndex);
        _repository.cacheObject(cachedLevelFileName, object);
        //versions save here
        var cachedLevelVersionsFileName:String = getCachedLevelVersionsUrl(gameLevelsFeatureToken);
        var cachedLevelVersions:Array = _repository.getObjectFromCache(cachedLevelVersionsFileName) as Array;
        if (null == cachedLevelVersions) {
            cachedLevelVersions = new Array();
        }

        var versionUpdated:Boolean = false;
        for (var i:int = 0; i < cachedLevelVersions.length; ++i) {
            var cachedVersion:Object = cachedLevelVersions[i];
            if (globalIndex == cachedVersion.globalIndex) {
                cachedVersion.version = version;
                versionUpdated = true;
                break;
            }
        }
        if (!versionUpdated) {
            var objectToAdd:Object = new Object();
            objectToAdd["globalIndex"] = globalIndex;
            objectToAdd["version"] = int(version);
            cachedLevelVersions.push(objectToAdd);
        }

        _repository.cacheObject(cachedLevelVersionsFileName, cachedLevelVersions);
    }

    /**
     * Caches an application data.
     * @param object The object to store.
     */
    public function cacheAppData(object:Object):void {
        _repository.cacheObject(getCachedAppDataUrl(), object);
    }

    /**
     * Provides the level_data.json from application.
     * @param gameLevelsFeatureToken The GameLevels feature token
     * @return The requested level_data.json from application.
     */
    public function getLevelDataFromApplication(gameLevelsFeatureToken:String):Object {
        return _repository.getObjectFromApplication(getLevelDataFromApplicationUrl(_localContentRoot, gameLevelsFeatureToken));
    }

    /**
     * Provides an level object from application.
     * @param gameLevelsFeatureToken The GameLevels feature token
     * @param globalIndex The global identifier of the cached level.
     * @return The requested level from application.
     */
    public function getLevelFromApplication(gameLevelsFeatureToken:String, globalIndex:int):Object {
        return _repository.getObjectFromApplication(SLTUtils.formatString(SLTConfig.LOCAL_LEVEL_CONTENT_URL_TEMPLATE, _localContentRoot, gameLevelsFeatureToken, globalIndex));
    }


}
}