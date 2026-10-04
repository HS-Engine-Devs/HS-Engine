package game;

import haxe.Json;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import openfl.utils.Assets;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class Character extends FlxSprite
{
	public var stunned:Bool = false;

	public var animationNotes:Array<Dynamic> = [];
	public var animationsArray:Array<AnimStuff> = [];
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;
	public var singDuration:Float = 4;

	public var danceIdle:Bool = false;
	public var healthIcon:String = 'face';

	public var cameraOffset:Array<Float> = [0,0];
	public var characterOffset:Array<Float> = [0,0];

	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var goofyAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var skipDance:Bool = false;

	public var knifeRaised:Bool = false;
	public var finishedLowering:Bool = false;	
	public var danceLockout:Bool = false;
	public var blinkTime:Float = 0;

	public var BLINK_MIN:Float = 1;
	public var BLINK_MAX:Float = 3;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end

		curCharacter = character;
		this.isPlayer = isPlayer;

		loadCharacterJson(curCharacter);
		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf'))
			{
				// var animArray
				var oldRight = animation.getByName('singRIGHT').frames;
				animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
				animation.getByName('singLEFT').frames = oldRight;

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}
		}

		switch(curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
		}
	}

    public function loadCharacterJson(character:String) {
		#if sys
		var path:String = ModPaths.data("characters/" + character);
		if (!ModPaths.exists(path))
			path = Paths.json("characters/" + character);
		if (!ModPaths.exists(path))
			path = ModPaths.modFolder("data/characters/" + character + ".txt");
		if (!ModPaths.exists(path))
			path = Paths.txt("characters/" + character);
		if (!ModPaths.exists(path))
			path = Paths.json("characters/bf");
		var rawJson:String = ModPaths.readContent(path);
		#else
		var path:String = Paths.json("characters/" + character);
		if (!Assets.exists(path))
			path = Paths.json("characters/bf");
		if (!Assets.exists(path))
			path = Paths.txt("characters/" + character);
		var rawJson = Assets.getText(path);
		#end

		var json:CharJson;
		if (rawJson.startsWith("{"))
			json = cast Json.parse(rawJson);
		else
			json = cast parseTxt(rawJson);

		if (Assets.exists(Paths.file("images/" + json.spritePath + ".txt", TEXT, "shared")))
			frames = Paths.getPackerAtlas(json.spritePath, "shared");
		if (Assets.exists(Paths.file("images/" + json.spritePath + ".xml", TEXT, "shared")))
			frames = Paths.getSparrowAtlas(json.spritePath, "shared");
		else
			frames = Paths.getSparrowAtlas(json.spritePath);

		imageFile = json.spritePath;

		cameraOffset = json.cameraOffset;
		characterOffset = json.characterOffset;

		goofyAntialiasing = json.antialiasing;
		antialiasing = json.antialiasing;
		singDuration = json.singDuration;

		healthIcon = json.healthIcon;
		originalFlipX = flipX;
		flipX = json.flipX;

		animationsArray = json.animations;
		if(animationsArray != null && animationsArray.length > 0) {
			for (anim in animationsArray) {
				var animIndices:Array<Int> = anim.indices;
				if (animIndices != null && animIndices.length > 0)
					animation.addByIndices(anim.anim, anim.name, animIndices, "", anim.fps, anim.loop);
				else
					animation.addByPrefix(anim.anim, anim.name, anim.fps, anim.loop);
				if (anim.offsets != null && anim.offsets.length > 1)
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}

		if (json.scale != 1) {
			jsonScale = json.scale;
			setGraphicSize(Std.int(width * jsonScale));
			updateHitbox();
		}
	}

	public static function parseTxt(rawTxt:String):CharJson {
		var lines = rawTxt.split("\n");
		var json:CharJson = {
			animations: [],
			spritePath: "",
			healthIcon: "",
			scale: 1,
			flipX: false,
			antialiasing: false,
			singDuration: 4,
			cameraOffset: [0,0],
			characterOffset: [0,0]
		};
	
		for (line in lines) {
			var parts = line.split("=");
			if (parts.length < 2) continue;

			var key = parts[0].trim();
			var value = parts[1].trim();

			switch (key) {
				case "spritePath": json.spritePath = value;
				case "healthIcon": json.healthIcon = value;
				case "scale": json.scale = Std.parseFloat(value);
				case "flipX": json.flipX = CoolUtil.parseBool(value);
				case "antialiasing": json.antialiasing = CoolUtil.parseBool(value);
				case "singDuration": json.singDuration = Std.parseFloat(value);
				case "cameraOffset":
					var offsetParts = value.split(":");
					json.cameraOffset = [Std.parseFloat(offsetParts[0]), Std.parseFloat(offsetParts[1])];
				case "characterOffset":
					var offsetParts = value.split(":");
					json.characterOffset = [Std.parseFloat(offsetParts[0]), Std.parseFloat(offsetParts[1])];
				case "animation":
					var animParts = value.split(",");
					if (animParts.length >= 5) {
						var anim:AnimStuff = {
							anim: animParts[0].trim(),
							name: animParts[1].trim(),
							fps: Std.parseInt(animParts[2].trim()),
							loop: CoolUtil.parseBool(animParts[3].trim()),
							offsets: animParts[4].trim().split(":").map(Std.parseInt),
							indices: []
						};

						if (animParts.length > 5 && animParts[5].trim() != "") {
							anim.indices = parseIndices(animParts[5].trim());
						}

						json.animations.push(anim);
					}
			}
		}
		return json;
	}

	public static function parseIndices(indicesString:String):Array<Int> {
		var newArray:Array<Int> = [];

		if (indicesString != "") {
			var parts = indicesString.split(" ");

			for (part in parts) {
				newArray.push(Std.parseInt(part));
			}
		}

		return newArray;
	}

	override function update(elapsed:Float)
	{
		if(!debugMode && animation.curAnim != null)
		{
			if (!curCharacter.startsWith('bf'))
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}
	
				if (holdTimer >= Conductor.stepCrochet * 0.001 * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			switch(curCharacter)
			{
				case 'pico-speaker':
					if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
					{
						var noteData:Int = 1;
						if(animationNotes[0][1] > 2) noteData = 3;
	
						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
					if(animation.curAnim.finished) playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			}
		
			if (curCharacter == "nene" && animation.curAnim != null && animation.curAnim.name == "idleKnife")
			{
				blinkTime -= elapsed;
			
				if (blinkTime <= 0)
				{
					playAnim("idleKnife", true);
					blinkTime = FlxG.random.float(BLINK_MIN, BLINK_MAX);
				}
			}

			switch (curCharacter)
			{
				case 'gf':
					if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
						playAnim('danceRight');
			}

			if (animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !danceLockout)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight');
				else
					playAnim('danceLeft');
			}
			else if (animation.getByName('idle') != null)
			{
				if (curCharacter == 'tankman' && PlayState.SONG.song.toLowerCase() == 'stress' && PlayState.tankmangood == 1)
					playAnim('singDOWN-alt');
				else
					playAnim('idle');
			}
		}
	}

	function loadMappedAnims():Void
	{
		var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				animationNotes.push(songNotes);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;

		danceIdle = (animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null);

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}

		settingCharacterUp = false;
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}

typedef CharJson = {
	var animations:Array<AnimStuff>;
	var spritePath:String;
	var healthIcon:String;
	var scale:Float;
	var flipX:Bool;
	var antialiasing:Bool;
	var singDuration:Float;
	var cameraOffset:Array<Float>;
	var characterOffset:Array<Float>;
}

typedef AnimStuff = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}
