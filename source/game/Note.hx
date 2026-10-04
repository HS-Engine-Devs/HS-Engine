package game;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var missed:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public var sustainParent:Note;
	public var sustainChildren:Array<Note> = [];

	public var noteScore:Float = 1;
	public var originalHeightForCalcs:Float = 6;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	private var earlyHitMult:Float = 0.5;

	public var noteType:String = '';
	static var noteJsonMap:Map<String, NoteJson> = new Map();

	public var belongsToSection:Int = 0;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?noteType:String = "")
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.noteType = noteType;

		x += (Config.middleScroll ? -278 : 48) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;

		this.noteData = noteData;

		if (noteData != -1) {
			if (isSustainNote && !prevNote.isSustainNote) {
				sustainParent = prevNote;
				prevNote.sustainChildren.push(this);
			} else if (isSustainNote && prevNote.isSustainNote) {
				sustainParent = prevNote.sustainParent;
				sustainParent.sustainChildren.push(this);
			}
		}

		loadNoteJson(noteType); 

		var noteJson = noteJsonMap.get(noteType);
		if (noteJson != null) {
			var spriteAntialiasing:Bool = true;
			var spriteScale:Float = 0;
			var isIgnoreNote = true;

			if (noteJson.antialiasing != null)
				spriteAntialiasing = noteJson.antialiasing;

			if (noteJson.isIgnoreNote != null)
				isIgnoreNote = noteJson.isIgnoreNote;

			if (noteJson.scale != null)
				spriteScale = noteJson.scale;

			frames = Paths.getSparrowAtlas(noteJson.spritePath);

			animation.addByPrefix('greenScroll', noteJson.animations.greenScroll);
			animation.addByPrefix('redScroll', noteJson.animations.redScroll);
			animation.addByPrefix('blueScroll', noteJson.animations.blueScroll);
			animation.addByPrefix('purpleScroll', noteJson.animations.purpleScroll);

			animation.addByPrefix('purpleholdend', noteJson.animations.purpleholdend);
			animation.addByPrefix('greenholdend', noteJson.animations.greenholdend);
			animation.addByPrefix('redholdend', noteJson.animations.redholdend);
			animation.addByPrefix('blueholdend', noteJson.animations.blueholdend);

			animation.addByPrefix('purplehold', noteJson.animations.purplehold);
			animation.addByPrefix('greenhold', noteJson.animations.greenhold);
			animation.addByPrefix('redhold', noteJson.animations.redhold);
			animation.addByPrefix('bluehold', noteJson.animations.bluehold);

			setGraphicSize(Std.int(width * (0.7 + spriteScale)));
			updateHitbox();
			antialiasing = spriteAntialiasing;
			ignoreNote = isIgnoreNote;

			if (isSustainNote && noteJson.alpha != null)
				alpha = noteJson.alpha;
		} else {
		    var daStage:String = PlayState.curStage;

		    switch (daStage)
		    {
		    	case 'school' | 'schoolEvil':
		    		loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);

		    		animation.add('greenScroll', [6]);
		    		animation.add('redScroll', [7]);
		    		animation.add('blueScroll', [5]);
		    		animation.add('purpleScroll', [4]);

		    		if (isSustainNote)
		    		{
		    			loadGraphic(Paths.image('weeb/pixelUI/arrowEnds'), true, 7, 6);

		    			animation.add('purpleholdend', [4]);
		    			animation.add('greenholdend', [6]);
		    			animation.add('redholdend', [7]);
		    			animation.add('blueholdend', [5]);
    
		    			animation.add('purplehold', [0]);
		    			animation.add('greenhold', [2]);
		    			animation.add('redhold', [3]);
		    			animation.add('bluehold', [1]);
		    		}

		    		originalHeightForCalcs = height;
		    		setGraphicSize(Std.int(width * PlayState.daPixelZoom));
		    		updateHitbox();
		    	default:
		    		frames = Paths.getSparrowAtlas('NOTE_assets');

		    		animation.addByPrefix('greenScroll', 'green0');
		    		animation.addByPrefix('redScroll', 'red0');
		    		animation.addByPrefix('blueScroll', 'blue0');
		    		animation.addByPrefix('purpleScroll', 'purple0');

		    		animation.addByPrefix('purpleholdend', 'pruple end hold');
		    		animation.addByPrefix('greenholdend', 'green hold end');
		    		animation.addByPrefix('redholdend', 'red hold end');
		    		animation.addByPrefix('blueholdend', 'blue hold end');

		    		animation.addByPrefix('purplehold', 'purple hold piece');
		    		animation.addByPrefix('greenhold', 'green hold piece');
		    		animation.addByPrefix('redhold', 'red hold piece');
		    		animation.addByPrefix('bluehold', 'blue hold piece');

		    		setGraphicSize(Std.int(width * 0.7));
				    updateHitbox();
		    		antialiasing = true;
		    }
		}

		switch (noteData)
		{
			case 0:
				x += swagWidth * 0;
				animation.play('purpleScroll');
			case 1:
				x += swagWidth * 1;
				animation.play('blueScroll');
			case 2:
				x += swagWidth * 2;
				animation.play('greenScroll');
			case 3:
				x += swagWidth * 3;
				animation.play('redScroll');
		}

		// Logger.log(prevNote);

		if (isSustainNote && prevNote != null)
		{
			noteScore * 0.2;
			alpha = 0.6;

			if(Config.downScroll) flipY = true;

			offsetX += width / 2;

			switch (noteData)
			{
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
				case 1:
					animation.play('blueholdend');
				case 0:
					animation.play('purpleholdend');
			}

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.curStage.startsWith('school'))
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		} else if(!isSustainNote) {
			earlyHitMult = 1;
		}
		x += offsetX;
	}

	public function loadNoteJson(noteType:String):Void {
		#if sys
		if (!noteJsonMap.exists(noteType)) {
			if (ModPaths.exists(ModPaths.data("notes/" + noteType))) {
				var jsonContent = ModPaths.readContent(ModPaths.data("notes/" + noteType));
				var parsedJson = haxe.Json.parse(jsonContent);
				if (parsedJson != null) {
					noteJsonMap.set(noteType, parsedJson);
					Logger.log("noteJson for " + noteType + " loaded successfully.");
				} else {
					Logger.log("Error: noteJson for " + noteType + " is null after parsing.");
				}
			}
		}
		#end
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}

typedef NoteJson = {
	var ?spritePath:String;
	var ?animations:NoteAnimations;
	var ?scale:Float;
	var ?alpha:Float;
	var ?antialiasing:Bool;
	var ?isIgnoreNote:Bool;
}

typedef NoteAnimations = {
	var greenScroll:String;
	var redScroll:String;
	var blueScroll:String;
	var purpleScroll:String;
	var purpleholdend:String;
	var greenholdend:String;
	var redholdend:String;
	var blueholdend:String;
	var purplehold:String;
	var greenhold:String;
	var redhold:String;
	var bluehold:String;
}
