package system;

#if sys
import haxe.Json;
import flixel.FlxG;
import haxe.io.Path;
import flixel.FlxObject;
import flixel.math.FlxAngle;
import flixel.group.FlxGroup;
import flixel.util.FlxTimer;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.system.FlxSound;
import flixel.math.FlxMath;
import lime.utils.Assets;
import haxe.zip.Reader;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import hscript.Parser;
import hscript.Interp;
import sys.FileSystem;
import sys.io.File;

#if VIDEOS
import hxvlc.flixel.FlxVideo;
import hxvlc.flixel.FlxVideoSprite;
#end

using StringTools;

class ModSupport {
    static public function getModMetadata(modName:String):ModMetadata {
        var modRoot = ModPaths.modPath(modName, "");
        var metadata:ModMetadata = {
            folder: modName,
            name: modName,
            description: "No description provided.",
            author: "Unknown author",
            version: "1.0.0",
            enabled: ModPaths.isModEnabled(modName),
            isZip: modRoot != null && StringTools.startsWith(modRoot, "zip://"),
            iconPath: null
        };

        var manifestPath = ModPaths.modPath(modName, "mod.json");
        if (ModPaths.exists(manifestPath)) {
            try {
                var manifest:Dynamic = Json.parse(ModPaths.readContent(manifestPath));
                var name:Dynamic = Reflect.field(manifest, "name");
                var description:Dynamic = Reflect.field(manifest, "description");
                var author:Dynamic = Reflect.field(manifest, "author");
                var version:Dynamic = Reflect.field(manifest, "version");
                if (Std.isOfType(name, String) && StringTools.trim(name).length > 0) metadata.name = name;
                if (Std.isOfType(description, String) && StringTools.trim(description).length > 0) metadata.description = description;
                if (Std.isOfType(author, String) && StringTools.trim(author).length > 0) metadata.author = author;
                if (Std.isOfType(version, String) && StringTools.trim(version).length > 0) metadata.version = version;
            } catch (error:Dynamic) {
                Logger.log("Error: invalid mod manifest " + manifestPath + ": " + error);
            }
        }

        var iconPath = ModPaths.modPath(modName, "icon.png");
        if (ModPaths.exists(iconPath)) metadata.iconPath = iconPath;
        return metadata;
    }
}

class ModPaths {
    public static var modDirectory:String = "mods/";
    private static var modInfo:Array<{ folder:String, enabled:Bool }> = [];
    private static var zipEntries:Map<String, Map<String, Dynamic>> = new Map();
    private static var zipPaths:Map<String, String> = new Map();

    public static function loadMods():Void {
        modInfo = [];
        zipEntries = new Map();
        zipPaths = new Map();
        loadModSettings();
    }

    inline static public function image(path:String):String {
        return findFileInModFolders("images", path + ".png");
    }

    inline static public function sound(path:String):String {
        return findFileInModFolders("", path + ".ogg");
    }

    inline static public function data(path:String):String {
        return findFileInModFolders("data", path + ".json");
    }

    inline static public function script(path:String):String {
        return findFileInModFolders("", path + ".hx");
    }

    inline static public function modFolder(path:String):String {
        return findFileInModFolders("", path);
    }

    static private function findFileInModFolders(subfolder:String, path:String):String {
        var fullPath:String = null;
        for (modFolder in getModFolders()) {
            if (modFolder.enabled) {
                var folderPath:String = modPath(modFolder.folder, haxe.io.Path.join([subfolder, path]));
                if (exists(folderPath)) {
                    fullPath = folderPath;
                    break;
                }
            }
        }
        return fullPath;
    }

    static public function getModFolders():Array<{ folder:String, enabled:Bool }> {
        if (modInfo.length == 0) {
            loadModSettings();
        }

        var modsFolder:String = modDirectory;
        var newMods:Array<String> = [];

        if (FileSystem.exists(modsFolder)) {
            for (item in FileSystem.readDirectory(modsFolder)) {
                var itemPath = haxe.io.Path.join([modsFolder, item]);
                if (FileSystem.isDirectory(itemPath)) {
                    processModFolder(item, itemPath, newMods);
                } else if (haxe.io.Path.extension(item).toLowerCase() == "zip") {
                    var modName = haxe.io.Path.withoutExtension(item);
                    try {
                        mountZipMod(modName, itemPath);
                        processModFolder(modName, itemPath, newMods);
                    } catch (e:Dynamic) {
                        Logger.log("Error: reading mod ZIP " + itemPath + ": " + e);
                    }
                }
            }

            var removedMods = modInfo.filter(info -> !isModPresent(info.folder));
            if (removedMods.length > 0 || newMods.length > 0) {
                modInfo = modInfo.filter(info -> isModPresent(info.folder));
                saveModSettings();
            }
        }

        return modInfo;
    }

    static private function processModFolder(folderName:String, folderPath:String, newMods:Array<String>):Void {
        var modExists:Bool = false;
        for (info in modInfo) {
            if (info.folder == folderName) {
                modExists = true;
                break;
            }
        }
        if (!modExists) {
            newMods.push(folderName);
            modInfo.push({ folder: folderName, enabled: Config.autoEnableNewMods });
        }
    }

    static private function mountZipMod(modName:String, zipPath:String):Void {
        if (zipPaths.get(modName) == zipPath && zipEntries.exists(modName)) return;

        var reader = new Reader(new BytesInput(File.getBytes(zipPath)));
        var archiveEntries:Map<String, Dynamic> = new Map();
        var wrapperPrefixes:Array<String> = [modName + "/", modName + ".zip/"];
        for (entry in reader.read()) {
            var entryPath = normalizeZipPath(entry.fileName);
            if (entryPath.length > 0 && !entryPath.endsWith("/")) {
                archiveEntries.set(entryPath, entry);
            }
        }

        var entries:Map<String, Dynamic> = new Map();
        var entryCount:Int = 0;
        for (entryPath in archiveEntries.keys()) {
            var entry:Dynamic = archiveEntries.get(entryPath);
            entries.set(entryPath, entry);
            for (wrapperPrefix in wrapperPrefixes) {
                if (entryPath.toLowerCase().startsWith(wrapperPrefix.toLowerCase())) {
                    entries.set(entryPath.substr(wrapperPrefix.length), entry);
                    break;
                }
            }
            entryCount++;
        }

        zipPaths.set(modName, zipPath);
        zipEntries.set(modName, entries);
        Logger.log("Mounted mod ZIP: " + zipPath + " (" + entryCount + " files)");
    }

    static private function normalizeZipPath(path:String):String {
        var normalized = path.split("\\").join("/");
        while (normalized.startsWith("./")) normalized = normalized.substr(2);
        while (normalized.startsWith("/")) normalized = normalized.substr(1);
        while (normalized.endsWith("/")) normalized = normalized.substr(0, normalized.length - 1);
        return normalized;
    }

    static private function isModPresent(modName:String):Bool {
        return FileSystem.isDirectory(haxe.io.Path.join([modDirectory, modName]))
            || (zipPaths.exists(modName) && FileSystem.exists(zipPaths.get(modName)));
    }

    static private function splitZipPath(path:String):Array<String> {
        if (path == null || !path.startsWith("zip://")) return null;
        var locator = path.substr(6);
        var separator = locator.indexOf("/");
        if (separator < 0) return [locator, ""];
        return [locator.substr(0, separator), normalizeZipPath(locator.substr(separator + 1))];
    }

    static private function makeZipPath(modName:String, innerPath:String):String {
        return "zip://" + modName + "/" + normalizeZipPath(innerPath);
    }

    static public function exists(path:String):Bool {
        if (path == null) return false;
        var zipPath = splitZipPath(path);
        if (zipPath == null) return FileSystem.exists(path);
        var entries = zipEntries.get(zipPath[0]);
        if (entries == null) return false;
        if (findZipEntry(entries, zipPath[1]) != null) return true;
        var prefix = zipPath[1].toLowerCase().length == 0 ? "" : zipPath[1].toLowerCase() + "/";
        for (entryPath in entries.keys()) {
            if (entryPath.toLowerCase().startsWith(prefix)) return true;
        }
        return false;
    }

    static public function isDirectory(path:String):Bool {
        var zipPath = splitZipPath(path);
        if (zipPath == null) return FileSystem.isDirectory(path);
        if (!exists(path)) return false;
        return findZipEntry(zipEntries.get(zipPath[0]), zipPath[1]) == null;
    }

    static public function readBytes(path:String):Bytes {
        var zipPath = splitZipPath(path);
        if (zipPath == null) return File.getBytes(path);
        var entry:Dynamic = findZipEntry(zipEntries.get(zipPath[0]), zipPath[1]);
        if (entry == null) throw "File not found in mod ZIP: " + path;
        return entry.compressed ? Reader.unzip(entry) : entry.data;
    }

    static private function findZipEntry(entries:Map<String, Dynamic>, path:String):Dynamic {
        if (entries == null) return null;
        var entry:Dynamic = entries.get(path);
        if (entry != null) return entry;
        var normalizedPath = path.toLowerCase();
        for (entryPath in entries.keys()) {
            if (entryPath.toLowerCase() == normalizedPath) return entries.get(entryPath);
        }
        return null;
    }

    static public function readContent(path:String):String {
        return readBytes(path).toString();
    }

    static public function physicalPath(path:String):String {
        var zipPath = splitZipPath(path);
        if (zipPath == null) return path;
        var extension = haxe.io.Path.extension(zipPath[1]);
        var tempRoot = Sys.getEnv("TEMP");
        if (tempRoot == null || tempRoot.length == 0) tempRoot = Sys.getEnv("TMPDIR");
        if (tempRoot == null || tempRoot.length == 0) tempRoot = ".";
        var cacheDirectory = haxe.io.Path.join([tempRoot, "HS-Engine-ModCache"]);
        if (!FileSystem.exists(cacheDirectory)) FileSystem.createDirectory(cacheDirectory);
        var archivePath = zipPaths.get(zipPath[0]);
        var archiveStamp = archivePath == null ? "" : FileSystem.stat(archivePath).mtime.toString();
        var cacheName = haxe.crypto.Md5.encode(path + archiveStamp) + (extension.length > 0 ? "." + extension : "");
        var cachePath = haxe.io.Path.join([cacheDirectory, cacheName]);
        if (!FileSystem.exists(cachePath)) File.saveBytes(cachePath, readBytes(path));
        return cachePath;
    }

    static public function readDirectory(path:String):Array<String> {
        var zipPath = splitZipPath(path);
        if (zipPath == null) return FileSystem.readDirectory(path);
        var entries = zipEntries.get(zipPath[0]);
        if (entries == null) return [];
        var prefix = zipPath[1].toLowerCase().length == 0 ? "" : zipPath[1].toLowerCase() + "/";
        var children:Array<String> = [];
        for (entryPath in entries.keys()) {
            if (entryPath.toLowerCase().startsWith(prefix)) {
                var remainder = entryPath.substr(prefix.length);
                var child = remainder.split("/")[0];
                if (child.length > 0 && children.indexOf(child) < 0) children.push(child);
            }
        }
        return children;
    }

    static public function readModFile(modName:String, relativePath:String):Bytes {
        var directoryPath = haxe.io.Path.join([modDirectory, modName, relativePath]);
        if (FileSystem.exists(directoryPath)) return File.getBytes(directoryPath);
        return readBytes(makeZipPath(modName, relativePath));
    }

    static public function modPath(modName:String, relativePath:String):String {
        var directoryPath = haxe.io.Path.join([modDirectory, modName, relativePath]);
        if (zipEntries.exists(modName)) return makeZipPath(modName, relativePath);
        if (FileSystem.isDirectory(haxe.io.Path.join([modDirectory, modName]))) return directoryPath;
        return null;
    }

    static public function isModEnabled(folder:String):Bool {
        for (info in modInfo) {
            if (info.folder == folder) {
                return info.enabled;
            }
        }
        return false;
    }

    static public function toggleMod(folder:String, enable:Bool):Void {
        for (mod in modInfo) {
            if (mod.folder == folder) {
                mod.enabled = enable;
                saveModSettings();
                break;
            }
        }
    }

    static public function checkRestartStatus():Bool {
        for (modFolder in getModFolders()) {
            if (modFolder.enabled) {
                var filePath:String = modPath(modFolder.folder, "data/waitingToRestart.txt");
                if (exists(filePath)) {
                    var fileContent:String = readContent(filePath).trim().toLowerCase();
                    return (fileContent == "true");
                }
            }
        }
        return false;
    }

    static public function saveModSettings():Void {
        var savePath:String = "mod_settings.txt";
        var file:sys.io.FileOutput = sys.io.File.write(savePath, false);
        for (info in modInfo) {
            file.writeString(info.folder + ":" + (info.enabled ? "1" : "0") + "\n");
        }
        getModFolders();
        file.close();
    }

    static private function loadModSettings():Void {
        var savePath:String = "mod_settings.txt";
        if (sys.FileSystem.exists(savePath)) {
            var fileContent:String = sys.io.File.getContent(savePath);
            var lines:Array<String> = fileContent.split("\n");
            for (line in lines) {
                var parts:Array<String> = line.split(":");
                if (parts.length == 2) {
                    var folder:String = parts[0].trim();
                    var enabled:Bool = (parts[1].trim() == "1");
                    modInfo.push({ folder: folder, enabled: enabled });
                }
            }
        }
    }
}

typedef ModMetadata = {
    var folder:String;
    var name:String;
    var description:String;
    var author:String;
    var version:String;
    var enabled:Bool;
    var isZip:Bool;
    var iconPath:Null<String>;
}

class ModScripts {
	public var script:hscript.Expr;
	public var interp = new Interp();
	public var parser = new Parser();

	public function new() {
        executeScript();
    }

    public function executeScript() {
        parser.allowTypes = true;
        parser.allowJSON = true;
        parser.allowMetadata = true;

		interp.allowStaticVariables = true;
        interp.allowPublicVariables = true;

		interp.errorHandler = _errorHandler;

		interp.variables.set("Int", Int);
		interp.variables.set("String", String);
		interp.variables.set("Float", Float);
		interp.variables.set("Array", Array);
		interp.variables.set("Bool", Bool);
		interp.variables.set("Dynamic", Dynamic);
		interp.variables.set("Math", Math);
        interp.variables.set("Sys", Sys);
		interp.variables.set("FlxMath", FlxMath);
		interp.variables.set("Std", Std);
        interp.variables.set("Reflect", Reflect);
		interp.variables.set("StringTools", StringTools);
		interp.variables.set("FlxG", FlxG);
		interp.variables.set("FlxSound", FlxSound);
		interp.variables.set("FlxSprite", FlxSprite);
		interp.variables.set("FlxText", FlxText);
		interp.variables.set("FlxGraphic", FlxGraphic);
		interp.variables.set("FlxTween", FlxTween);
		interp.variables.set("FlxEase", FlxEase);
		interp.variables.set("FlxCamera", FlxCamera);
		interp.variables.set("Assets", Assets);
		interp.variables.set("File", File);
		interp.variables.set("Window", Window);
		interp.variables.set("FileSystem", FileSystem);
		interp.variables.set("PlayState", PlayState);
		interp.variables.set("FlxGroup", FlxGroup);
		interp.variables.set("FlxTimer", FlxTimer);
		interp.variables.set("FlxTypedGroup", FlxTypedGroup);
		interp.variables.set("CoolUtil", CoolUtil);
		interp.variables.set("Paths", Paths);
		interp.variables.set("Path", Path);
		interp.variables.set("Json", Json);
		interp.variables.set("FlxAngle", FlxAngle);
		interp.variables.set("FlxAtlasFrames", FlxAtlasFrames);
		interp.variables.set("FlxAtlas", FlxAtlas);
		interp.variables.set("Character", Character);
		interp.variables.set("Boyfriend", Boyfriend);
		interp.variables.set("Song", Song);
        interp.variables.set("Controls", Controls);
		interp.variables.set("Conductor", Conductor);
		interp.variables.set("Note", Note);
		interp.variables.set("Config", Config);
        interp.variables.set("ModPaths", ModPaths);
        interp.variables.set("MusicBeatState", MusicBeatState);
        interp.variables.set("MusicBeatSubstate", MusicBeatSubstate);
		#if VIDEOS
		interp.variables.set('VideoHandler', FlxVideo);
		interp.variables.set('FlxVideo', FlxVideo);
		interp.variables.set('FlxVideoSprite', FlxVideoSprite);
		#end
		interp.variables.set('BGSprite', BGSprite);
		interp.variables.set("FunkinShader", FunkinShader);
		interp.variables.set("CustomShader", CustomShader);
        interp.variables.set("window", lime.app.Application.current.window);
        interp.variables.set("FlxColor", system.classes.FlxColorHelper);
        interp.variables.set("FlxKey", system.classes.FlxKeyHelper);
        interp.variables.set("BlendMode", system.classes.BlendModeHelper);
        interp.variables.set("FlxCameraFollowStyle", system.classes.FlxCameraFollowStyleHelper);
        interp.variables.set("FlxTextAlign", system.classes.FlxTextAlignHelper);
        interp.variables.set("FlxTextBorderStyle", system.classes.FlxTextBorderStyleHelper);
        interp.variables.set("StringHelper", system.classes.StringHelper);

        interp.variables.set("importScript", function(path:String):Dynamic {
            var scriptPath = ModPaths.script(path);
            if (scriptPath == null) {
                Logger.log("Error: could not resolve path '" + path + "'");
            }
            if (!ModPaths.exists(scriptPath)) {
                Logger.log("Error: script not found at '" + scriptPath + "'");
            }

            var src = ModPaths.readContent(scriptPath);
            var expr = parser.parseString(src);
            return interp.execute(expr);
        });

        interp.variables.set("switchState", function(state:String):Void {
            var modStatePath = ModPaths.script("data/states/" + state);
            if (modStatePath != null) {
                if (ModPaths.exists(modStatePath)) {
                    FlxG.switchState(Type.createInstance(ModScriptState, [modStatePath]));
                }
            }
        });

        interp.variables.set("openSubState", function(substate:String, pauseGame:Bool = false):Void {
            var modSubStatePath = ModPaths.script("data/substates/" + substate);
            if (modSubStatePath != null) {
                if (ModPaths.exists(modSubStatePath)) {
                    PlayState.instance.openSubState(Type.createInstance(ModScriptSubstate, [modSubStatePath]));
                }
            }
            if(pauseGame) {
                PlayState.instance.persistentUpdate = false;
                PlayState.instance.persistentDraw = true;
                PlayState.instance.paused = true;
                if(FlxG.sound.music != null) {
                    FlxG.sound.music.pause();
                    PlayState.instance.vocals.pause();
                }
            }
        });

        interp.variables.set("closeSubState", function() {
			if(ModScriptSubstate.instance != null) {
                PlayState.instance.closeSubState();
                ModScriptSubstate.instance = null;
                return true;
            }
            return false;
        });

        interp.variables.set("getOptionValue", function(name:String):Dynamic {
            return Config.getOptionValue(name);
        });
        interp.variables.set("setOptionValue", function(name:String, value:Dynamic):Bool {
            return Config.setOptionValue(name, value);
        });
        interp.variables.set("getOption", function(name:String):Dynamic {
            return Config.getOptionValue(name);
        });
        interp.variables.set("setOption", function(name:String, value:Dynamic):Bool {
            return Config.setOptionValue(name, value);
        });
        interp.variables.set("optionBool", function(name:String, value:Bool = false, isUnselectable:Bool = false):Option {
            return Config.optionBool(name, value, isUnselectable);
        });
        interp.variables.set("optionInt", function(name:String, value:Int = 0, min:Int = 0, max:Int = 100, step:Int = 1, isUnselectable:Bool = false):Option {
            return Config.optionInt(name, value, min, max, step, isUnselectable);
        });
        interp.variables.set("optionFloat", function(name:String, value:Float = 0, min:Float = 0, max:Float = 1, step:Float = 0.1, isUnselectable:Bool = false):Option {
            return Config.optionFloat(name, value, min, max, step, isUnselectable);
        });
        interp.variables.set("optionString", function(name:String, value:String = "", values:Array<String>, isUnselectable:Bool = false):Option {
            return Config.optionString(name, value, values, isUnselectable);
        });
        interp.variables.set("getOptionLabel", function(name:String):String {
            return Config.getOptionLabel(name);
        });
    }

    public function loadScript(path:String):Void {
        var scriptContent:String = ModPaths.readContent(path);
        script = parser.parseString(scriptContent);
        interp.execute(script);
    }

	public function callFunction(funcName:String, ?args:Array<Dynamic>):Dynamic {
        if (interp == null) return null;
        if (!interp.variables.exists(funcName)) return null;

        var func = interp.variables.get(funcName);
        if (func != null && Reflect.isFunction(func)) return Reflect.callMethod(null, func, args);

        return null;
	}

	private function _errorHandler(error:hscript.Expr.Error) {
		var fileName = error.origin;
		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		if (err.startsWith(fn)) err = err.substr(fn.length);
        Logger.log("Error: " + err);
	}
}

class ModScriptState extends MusicBeatState {
    public var scriptPath:String;
	public var interp = new Interp();
	public var parser = new Parser();

    override public function new(scriptPath:String) {
        this.scriptPath = scriptPath;
        executeScript();
        loadScript();
        super();
    }

    override function create():Void {
        callFunction("create", []);
        super.create();
        callFunction("createPost", []);
    }

	override function update(elapsed:Float) {
        callFunction("update", [elapsed]);
        super.update(elapsed);
        callFunction("updatePost", [elapsed]);
    }

	override function stepHit():Void {
        callFunction("stepHit", [curStep]);
        super.stepHit();
    }

    override function beatHit():Void {
        callFunction("beatHit", [curBeat]);
        super.beatHit();
    }

    public function executeScript() {
        parser.allowTypes = true;
        parser.allowJSON = true;
        parser.allowMetadata = true;

        interp.scriptObject = this;

		interp.allowStaticVariables = true;
        interp.allowPublicVariables = true;

		interp.errorHandler = _errorHandler;

		interp.variables.set("Int", Int);
		interp.variables.set("String", String);
		interp.variables.set("Float", Float);
		interp.variables.set("Array", Array);
		interp.variables.set("Bool", Bool);
		interp.variables.set("Dynamic", Dynamic);
		interp.variables.set("Math", Math);
        interp.variables.set("Sys", Sys);
		interp.variables.set("FlxMath", FlxMath);
		interp.variables.set("Std", Std);
        interp.variables.set("Reflect", Reflect);
		interp.variables.set("StringTools", StringTools);
		interp.variables.set("FlxG", FlxG);
		interp.variables.set("FlxSound", FlxSound);
		interp.variables.set("FlxSprite", FlxSprite);
		interp.variables.set("FlxText", FlxText);
		interp.variables.set("FlxGraphic", FlxGraphic);
		interp.variables.set("FlxTween", FlxTween);
		interp.variables.set("FlxEase", FlxEase);
		interp.variables.set("FlxCamera", FlxCamera);
		interp.variables.set("Assets", Assets);
		interp.variables.set("File", File);
		interp.variables.set("Window", Window);
		interp.variables.set("FileSystem", FileSystem);
		interp.variables.set("PlayState", PlayState);
		interp.variables.set("FlxGroup", FlxGroup);
		interp.variables.set("FlxTimer", FlxTimer);
		interp.variables.set("FlxTypedGroup", FlxTypedGroup);
		interp.variables.set("CoolUtil", CoolUtil);
		interp.variables.set("Paths", Paths);
		interp.variables.set("Path", Path);
		interp.variables.set("Json", Json);
		interp.variables.set("FlxAngle", FlxAngle);
		interp.variables.set("FlxAtlasFrames", FlxAtlasFrames);
		interp.variables.set("FlxAtlas", FlxAtlas);
		interp.variables.set("Character", Character);
		interp.variables.set("Boyfriend", Boyfriend);
		interp.variables.set("Song", Song);
        interp.variables.set("Controls", Controls);
		interp.variables.set("Conductor", Conductor);
        interp.variables.set("controls", controls);
		interp.variables.set("Note", Note);
		interp.variables.set("Config", Config);
		interp.variables.set("OptionType", OptionType);
        interp.variables.set("ModPaths", ModPaths);
        interp.variables.set("MusicBeatState", MusicBeatState);
        interp.variables.set("MusicBeatSubstate", MusicBeatSubstate);
		#if VIDEOS
		interp.variables.set('VideoHandler', FlxVideo);
		interp.variables.set('FlxVideo', FlxVideo);
		interp.variables.set('FlxVideoSprite', FlxVideoSprite);
		#end
		interp.variables.set('BGSprite', BGSprite);
		interp.variables.set("FunkinShader", FunkinShader);
		interp.variables.set("CustomShader", CustomShader);
        interp.variables.set("window", lime.app.Application.current.window);
        interp.variables.set("FlxColor", system.classes.FlxColorHelper);
        interp.variables.set("FlxKey", system.classes.FlxKeyHelper);
        interp.variables.set("BlendMode", system.classes.BlendModeHelper);
        interp.variables.set("FlxCameraFollowStyle", system.classes.FlxCameraFollowStyleHelper);
        interp.variables.set("FlxTextAlign", system.classes.FlxTextAlignHelper);
        interp.variables.set("FlxTextBorderStyle", system.classes.FlxTextBorderStyleHelper);
        interp.variables.set("StringHelper", system.classes.StringHelper);

		interp.variables.set("members", members);
	    interp.variables.set("controls", controls);
	    interp.variables.set("curBeat", curBeat);
		interp.variables.set("curStep", curStep);

        interp.variables.set("importScript", function(path:String):Dynamic {
            var scriptPath = ModPaths.script(path);
            if (scriptPath == null) {
                Logger.log("Error: could not resolve path '" + path + "'");
            }
            if (!ModPaths.exists(scriptPath)) {
                Logger.log("Error: script not found at '" + scriptPath + "'");
            }

            var src = ModPaths.readContent(scriptPath);
            var expr = parser.parseString(src);
            return interp.execute(expr);
        });

        interp.variables.set("switchState", function(state:String):Void {
            var modStatePath = ModPaths.script("data/states/" + state);
            if (modStatePath != null) {
                if (ModPaths.exists(modStatePath)) {
                    FlxG.switchState(Type.createInstance(ModScriptState, [modStatePath]));
                }
            }
        });

        interp.variables.set("openSubState", function(substate:String, pauseGame:Bool = false):Void {
            var modSubStatePath = ModPaths.script("data/substates/" + substate);
            if (modSubStatePath != null) {
                if (ModPaths.exists(modSubStatePath)) {
                    PlayState.instance.openSubState(Type.createInstance(ModScriptSubstate, [modSubStatePath]));
                }
            }
            if(pauseGame) {
                PlayState.instance.persistentUpdate = false;
                PlayState.instance.persistentDraw = true;
                PlayState.instance.paused = true;
                if(FlxG.sound.music != null) {
                    FlxG.sound.music.pause();
                    PlayState.instance.vocals.pause();
                }
            }
        });

        interp.variables.set("closeSubState", function() {
			if(ModScriptSubstate.instance != null) {
                PlayState.instance.closeSubState();
                ModScriptSubstate.instance = null;
                return true;
            }
            return false;
        });

        interp.variables.set("getOptionValue", function(name:String):Dynamic {
            return Config.getOptionValue(name);
        });
        interp.variables.set("setOptionValue", function(name:String, value:Dynamic):Bool {
            return Config.setOptionValue(name, value);
        });
        interp.variables.set("getOption", function(name:String):Dynamic {
            return Config.getOptionValue(name);
        });
        interp.variables.set("setOption", function(name:String, value:Dynamic):Bool {
            return Config.setOptionValue(name, value);
        });
        interp.variables.set("optionBool", function(name:String, value:Bool = false, isUnselectable:Bool = false):Option {
            return Config.optionBool(name, value, isUnselectable);
        });
        interp.variables.set("optionInt", function(name:String, value:Int = 0, min:Int = 0, max:Int = 100, step:Int = 1, isUnselectable:Bool = false):Option {
            return Config.optionInt(name, value, min, max, step, isUnselectable);
        });
        interp.variables.set("optionFloat", function(name:String, value:Float = 0, min:Float = 0, max:Float = 1, step:Float = 0.1, isUnselectable:Bool = false):Option {
            return Config.optionFloat(name, value, min, max, step, isUnselectable);
        });
        interp.variables.set("optionString", function(name:String, value:String = "", values:Array<String>, isUnselectable:Bool = false):Option {
            return Config.optionString(name, value, values, isUnselectable);
        });
        interp.variables.set("getOptionLabel", function(name:String):String {
            return Config.getOptionLabel(name);
        });

		interp.variables.set("add", function(value:FlxObject) {
			add(value);
		});

		interp.variables.set("remove", function(value:FlxObject) {
			remove(value);
		});

		interp.variables.set("insert", function(position:Int, value:FlxObject) {
			insert(position, value);
		});
    }

    public function loadScript():Void {
        var scriptContent:String = ModPaths.readContent(scriptPath);
        var classDef = parser.parseString(scriptContent);
        interp.execute(classDef);
    }

	public function callFunction(funcName:String, ?args:Array<Dynamic>):Dynamic {
		if (args == null)
			args = [];
		try {
			var func:Dynamic = interp.variables.get(funcName);
			if (func != null && Reflect.isFunction(func))
				return Reflect.callMethod(null, func, args);
		} catch (error:hscript.Expr.Error) {
            _errorHandler(error);
		}
		return true;
	}

	private function _errorHandler(error:hscript.Expr.Error) {
		var fileName = error.origin;
		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		if (err.startsWith(fn)) err = err.substr(fn.length);
        Logger.log("Error: " + err);
	}
}

class ModScriptSubstate extends MusicBeatSubstate {
	public static var instance:ModScriptSubstate;

    public var scriptPath:String;
	public var interp = new Interp();
	public var parser = new Parser();

    override public function new(scriptPath:String) {
		instance = this;
        this.scriptPath = scriptPath;
        executeScript();
        loadScript();
        super();
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }

    override function create():Void {
        callFunction("create", []);
        super.create();
        callFunction("createPost", []);
    }

	override function update(elapsed:Float) {
        callFunction("update", [elapsed]);
        super.update(elapsed);
        callFunction("updatePost", [elapsed]);
    }

	override function stepHit():Void {
        callFunction("stepHit", [curStep]);
        super.stepHit();
    }

    override function beatHit():Void {
        callFunction("beatHit", [curBeat]);
        super.beatHit();
    }

    public function executeScript() {
        parser.allowTypes = true;
        parser.allowJSON = true;
        parser.allowMetadata = true;

        interp.scriptObject = this;

		interp.allowStaticVariables = true;
        interp.allowPublicVariables = true;

		interp.errorHandler = _errorHandler;

		interp.variables.set("Int", Int);
		interp.variables.set("String", String);
		interp.variables.set("Float", Float);
		interp.variables.set("Array", Array);
		interp.variables.set("Bool", Bool);
		interp.variables.set("Dynamic", Dynamic);
		interp.variables.set("Math", Math);
        interp.variables.set("Sys", Sys);
		interp.variables.set("FlxMath", FlxMath);
		interp.variables.set("Std", Std);
        interp.variables.set("Reflect", Reflect);
		interp.variables.set("StringTools", StringTools);
		interp.variables.set("FlxG", FlxG);
		interp.variables.set("FlxSound", FlxSound);
		interp.variables.set("FlxSprite", FlxSprite);
		interp.variables.set("FlxText", FlxText);
		interp.variables.set("FlxGraphic", FlxGraphic);
		interp.variables.set("FlxTween", FlxTween);
		interp.variables.set("FlxEase", FlxEase);
		interp.variables.set("FlxCamera", FlxCamera);
		interp.variables.set("Assets", Assets);
		interp.variables.set("File", File);
		interp.variables.set("Window", Window);
		interp.variables.set("FileSystem", FileSystem);
		interp.variables.set("PlayState", PlayState);
		interp.variables.set("FlxGroup", FlxGroup);
		interp.variables.set("FlxTimer", FlxTimer);
		interp.variables.set("FlxTypedGroup", FlxTypedGroup);
		interp.variables.set("CoolUtil", CoolUtil);
		interp.variables.set("Paths", Paths);
		interp.variables.set("Path", Path);
		interp.variables.set("Json", Json);
		interp.variables.set("FlxAngle", FlxAngle);
		interp.variables.set("FlxAtlasFrames", FlxAtlasFrames);
		interp.variables.set("FlxAtlas", FlxAtlas);
		interp.variables.set("Character", Character);
		interp.variables.set("Boyfriend", Boyfriend);
		interp.variables.set("Song", Song);
        interp.variables.set("Controls", Controls);
		interp.variables.set("Conductor", Conductor);
		interp.variables.set("Note", Note);
		interp.variables.set("Config", Config);
		interp.variables.set("OptionType", OptionType);
        interp.variables.set("ModPaths", ModPaths);
        interp.variables.set("MusicBeatState", MusicBeatState);
        interp.variables.set("MusicBeatSubstate", MusicBeatSubstate);
		#if VIDEOS
		interp.variables.set('VideoHandler', FlxVideo);
		interp.variables.set('FlxVideo', FlxVideo);
		interp.variables.set('FlxVideoSprite', FlxVideoSprite);
		#end
		interp.variables.set('BGSprite', BGSprite);
		interp.variables.set("FunkinShader", FunkinShader);
		interp.variables.set("CustomShader", CustomShader);
        interp.variables.set("window", lime.app.Application.current.window);
        interp.variables.set("FlxColor", system.classes.FlxColorHelper);
        interp.variables.set("FlxKey", system.classes.FlxKeyHelper);
        interp.variables.set("BlendMode", system.classes.BlendModeHelper);
        interp.variables.set("FlxCameraFollowStyle", system.classes.FlxCameraFollowStyleHelper);
        interp.variables.set("FlxTextAlign", system.classes.FlxTextAlignHelper);
        interp.variables.set("FlxTextBorderStyle", system.classes.FlxTextBorderStyleHelper);
        interp.variables.set("StringHelper", system.classes.StringHelper);

		interp.variables.set("members", members);
	    interp.variables.set("controls", controls);
	    interp.variables.set("curBeat", curBeat);
		interp.variables.set("curStep", curStep);

        interp.variables.set("importScript", function(path:String):Dynamic {
            var scriptPath = ModPaths.script(path);
            if (scriptPath == null) {
                Logger.log("Error: could not resolve path '" + path + "'");
            }
            if (!ModPaths.exists(scriptPath)) {
                Logger.log("Error: script not found at '" + scriptPath + "'");
            }

            var src = ModPaths.readContent(scriptPath);
            var expr = parser.parseString(src);
            return interp.execute(expr);
        });

        interp.variables.set("switchState", function(state:String):Void {
            var modStatePath = ModPaths.script("data/states/" + state);
            if (modStatePath != null) {
                if (ModPaths.exists(modStatePath)) {
                    FlxG.switchState(Type.createInstance(ModScriptState, [modStatePath]));
                }
            }
        });

        interp.variables.set("openSubState", function(substate:String, pauseGame:Bool = false):Void {
            var modSubStatePath = ModPaths.script("data/substates/" + substate);
            if (modSubStatePath != null) {
                if (ModPaths.exists(modSubStatePath)) {
                    PlayState.instance.openSubState(Type.createInstance(ModScriptSubstate, [modSubStatePath]));
                }
            }
            if(pauseGame) {
                PlayState.instance.persistentUpdate = false;
                PlayState.instance.persistentDraw = true;
                PlayState.instance.paused = true;
                if(FlxG.sound.music != null) {
                    FlxG.sound.music.pause();
                    PlayState.instance.vocals.pause();
                }
            }
        });

        interp.variables.set("closeSubState", function() {
			if(ModScriptSubstate.instance != null) {
                PlayState.instance.closeSubState();
                ModScriptSubstate.instance = null;
                return true;
            }
            return false;
        });

        interp.variables.set("getOptionValue", function(name:String):Dynamic {
            return Config.getOptionValue(name);
        });
        interp.variables.set("setOptionValue", function(name:String, value:Dynamic):Bool {
            return Config.setOptionValue(name, value);
        });
        interp.variables.set("getOption", function(name:String):Dynamic {
            return Config.getOptionValue(name);
        });
        interp.variables.set("setOption", function(name:String, value:Dynamic):Bool {
            return Config.setOptionValue(name, value);
        });
        interp.variables.set("optionBool", function(name:String, value:Bool = false, isUnselectable:Bool = false):Option {
            return Config.optionBool(name, value, isUnselectable);
        });
        interp.variables.set("optionInt", function(name:String, value:Int = 0, min:Int = 0, max:Int = 100, step:Int = 1, isUnselectable:Bool = false):Option {
            return Config.optionInt(name, value, min, max, step, isUnselectable);
        });
        interp.variables.set("optionFloat", function(name:String, value:Float = 0, min:Float = 0, max:Float = 1, step:Float = 0.1, isUnselectable:Bool = false):Option {
            return Config.optionFloat(name, value, min, max, step, isUnselectable);
        });
        interp.variables.set("optionString", function(name:String, value:String = "", values:Array<String>, isUnselectable:Bool = false):Option {
            return Config.optionString(name, value, values, isUnselectable);
        });
        interp.variables.set("getOptionLabel", function(name:String):String {
            return Config.getOptionLabel(name);
        });

		interp.variables.set("close", function() {
			close();
		});

		interp.variables.set("add", function(value:FlxObject) {
			add(value);
		});

		interp.variables.set("remove", function(value:FlxObject) {
			remove(value);
		});

		interp.variables.set("insert", function(position:Int, value:FlxObject) {
			insert(position, value);
		});
    }

    public function loadScript():Void {
        var scriptContent:String = ModPaths.readContent(scriptPath);
        var classDef = parser.parseString(scriptContent);
        interp.execute(classDef);
    }

	public function callFunction(funcName:String, ?args:Array<Dynamic>):Dynamic {
		if (args == null)
			args = [];
		try {
			var func:Dynamic = interp.variables.get(funcName);
			if (func != null && Reflect.isFunction(func))
				return Reflect.callMethod(null, func, args);
		} catch (error:hscript.Expr.Error) {
            _errorHandler(error);
		}
		return true;
	}

	private function _errorHandler(error:hscript.Expr.Error) {
		var fileName = error.origin;
		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		if (err.startsWith(fn)) err = err.substr(fn.length);
        Logger.log("Error: " + err);
	}
}
#end
