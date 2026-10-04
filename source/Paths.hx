package;

import flixel.FlxG;
import flash.media.Sound;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	#if (haxe >= "4.0.0")
	public static var customImagesLoaded:Map<String, FlxGraphic> = new Map();
	public static var customSoundsLoaded:Map<String, Sound> = new Map();
	#else
	public static var customImagesLoaded:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	public static var customSoundsLoaded:Map<String, Sound> = new Map<String, Sound>();
	#end

	static var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline static public function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function fragShader(key:String, ?library:String)
    {
		#if sys
		var file:String = ModPaths.modFolder('data/shaders/$key.frag');
		if(ModPaths.exists(file)) {
			return file;
		}
		#end
		return getPath('data/shaders/$key.frag', TEXT, library);
	}

	inline static public function vertShader(key:String, ?library:String)
    {
		#if sys
		var file:String = ModPaths.modFolder('data/shaders/$key.vert');
		if(ModPaths.exists(file)) {
			return file;
		}
		#end
		return getPath('data/shaders/$key.vert', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	static public function video(key:String, ?library:String)
	{
		#if sys
		var file:String = ModPaths.modFolder('videos/$key.mp4');
		if(ModPaths.exists(file)) {
			return ModPaths.physicalPath(file);
		}
		#end
		return getPath('videos/$key.mp4', TEXT, library);
	}

	inline static public function voices(song:String):Any
	{
		#if sys
		var file:Sound = returnSongFile(ModPaths.sound('songs/' + song.toLowerCase() + '/Voices'));
		if(file != null) {
			return file;
		}
		#end
		return 'songs:assets/songs/${song.toLowerCase()}/Voices.$SOUND_EXT';
	}

	inline static public function inst(song:String):Any
	{
		#if sys
		var file:Sound = returnSongFile(ModPaths.sound('songs/' + song.toLowerCase() + '/Inst'));
		if(file != null) {
			return file;
		}
		#end
		return 'songs:assets/songs/${song.toLowerCase()}/Inst.$SOUND_EXT';
	}

	inline static public function image(key:String, ?library:String):Dynamic
	{
		#if sys
		var imageToReturn:FlxGraphic = addCustomGraphic(key);
		if(imageToReturn != null) return imageToReturn;
		#end
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		#if sys
		var imageLoaded:FlxGraphic = addCustomGraphic(key);
		var xmlExists:Bool = false;
		if(ModPaths.exists(ModPaths.modFolder('images/$key.xml'))) {
			xmlExists = true;
		}
		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)), (xmlExists ? ModPaths.readContent(ModPaths.modFolder('images/$key.xml')) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}

	inline static public function getTextureAtlas(key:String, ?library:String)
	{
		#if sys
		var shit:String = ModPaths.modFolder('images/$key');
		if(ModPaths.exists(shit)) {
			return ModPaths.physicalPath(shit);
		}
		#end
		return file('images/$key', library);
	}

	inline static public function fileExists(key:String, ?type:AssetType, ?library:String)
	{
		if(OpenFlAssets.exists(getPath(key, type, library))) {
			return true;
		}
		#if sys
		if(ModPaths.exists(ModPaths.modFolder(key))) {
			return true;
		}
		#end
		return false;
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;
		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

    #if sys
	static private function addCustomGraphic(key:String):FlxGraphic {
		var imagePath:String = ModPaths.image(key);
		if(ModPaths.exists(imagePath)) {
			if(!customImagesLoaded.exists(key)) {
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(BitmapData.fromBytes(ModPaths.readBytes(imagePath)));
				newGraphic.persist = true;
				customImagesLoaded.set(key, newGraphic);
			}
			return customImagesLoaded.get(key);
		}
		return null;
	}

	inline static private function returnSongFile(file:String):Sound {
		if(ModPaths.exists(file)) {
            if(!customSoundsLoaded.exists(file)) {
		        customSoundsLoaded.set(file, Sound.fromFile(ModPaths.physicalPath(file)));
            }
            return customSoundsLoaded.get(file);
        }
        return null;
    }
	#end
}
