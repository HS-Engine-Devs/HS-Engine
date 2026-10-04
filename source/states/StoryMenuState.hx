package states;

import openfl.Lib;
import haxe.Json;
import openfl.utils.Assets;
#if desktop
import system.Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	var scoreText:FlxText;
	var weekData:Array<Dynamic> = [];
	var curDifficulty:Int = 1;
	var weekCharacters:Array<Dynamic> = [];
	var weekNames:Array<String> = [];
	var weekTextures:Array<String> = [];
	var weekDifficulties:Array<Dynamic> = [];
	var weekColors:Array<String> = [];
	var txtWeekTitle:FlxText;
	var yellowBG:FlxSprite;
	var colorTween:FlxTween;
	var curWeek:Int = 0;
	var txtTracklist:FlxText;
	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var grpLocks:FlxTypedGroup<FlxSprite>;
	var difficultySelectors:FlxGroup;
	var sprDifficulty:StoryDiffSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	public var selectedDifficulty:String = "";

	override function create()
	{
		readWeekFile();

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(TitleState.freakyMenu);
		}

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		yellowBG = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, FlxColor.WHITE, true);
		yellowBG.color = 0xFFF9CF51;

		var co = 0xFFF9CF51;
		if (weekColors[curWeek] != null) {
			var c = FlxColor.fromString(weekColors[curWeek]);
			if (c != null) co = c;
		}
		yellowBG.color = co;

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		Logger.log("Line 88");
		
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...weekData.length)
		{
			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, weekTextures[i]);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.screenCenter(X);
			weekThing.antialiasing = true;
			// weekThing.updateHitbox();
		}

		Logger.log("Line 107");

		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, weekCharacters[curWeek][char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		Logger.log("Line 119");

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		sprDifficulty = new StoryDiffSprite(leftArrow.x + 130, leftArrow.y + 10, "normal");
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		Logger.log("Line 138");

		add(yellowBG);
		add(grpWeekCharacters);

		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		updateText();
		changeWeek();
		changeDifficulty();

		Logger.log("Line 156");

		super.create();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		scoreText.text = "WEEK SCORE:" + lerpScore;

		txtWeekTitle.text = weekNames[curWeek].toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		// FlxG.watch.addQuick('font', scoreText.font);

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				if (controls.UP_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeWeek(-1);
					changeDifficulty();
				}

				if (controls.DOWN_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeWeek(1);
					changeDifficulty();
				}

				if (controls.RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.RIGHT_P) {
					sprDifficulty.doTween();
					changeDifficulty(1);
				} else if (controls.LEFT_P) {
					sprDifficulty.doTween();
					changeDifficulty(-1);
				}
			}

			if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			#if sys
			scriptState.callFunction("goToMenu", []);
			#end
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		// if (weekUnlocked[curWeek])
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				if(grpWeekCharacters.members[1].character != '') grpWeekCharacters.members[1].animation.play('confirm');
				stopspamming = true;
			}

			PlayState.storyPlaylist = weekData[curWeek];
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = CoolUtil.songDifficulties[curDifficulty];
			var poop:String = Highscore.formatSong(PlayState.storyPlaylist[0].toLowerCase(), diffic);

			Logger.log(poop);

			PlayState.storyDifficultyText = CoolUtil.songDifficulties[curDifficulty];

			PlayState.SONG = Song.loadFromJson(poop, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = curWeek;
			PlayState.storyDifficultyText = diffic.toUpperCase();
			PlayState.campaignScore = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, CoolUtil.songDifficulties.length - 1);

		var diff:String = CoolUtil.songDifficulties[curDifficulty].toLowerCase().trim();
		Logger.log(diff);

		sprDifficulty.changeDiff(diff);

		sprDifficulty.x = leftArrow.x + 60;
		sprDifficulty.x += (308 - sprDifficulty.width) / 3;

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, diff);
		#end

		selectedDifficulty = CoolUtil.songDifficulties[curDifficulty];
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= weekData.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = weekData.length - 1;

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0))
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		if (weekDifficulties[curWeek] != null){
			if (weekDifficulties[curWeek].length > 0)
				CoolUtil.songDifficulties = weekDifficulties[curWeek];
			else
				CoolUtil.songDifficulties = CoolUtil.defaultDifficulties;
		} else{
			CoolUtil.songDifficulties = CoolUtil.defaultDifficulties;
		}

		var diff:String = CoolUtil.songDifficulties[curDifficulty].toLowerCase().trim();
		sprDifficulty.changeDiff(diff);

	    FlxTween.cancelTweensOf(yellowBG);

		if (colorTween != null) colorTween.cancel();
		var co = 0xFFF9CF51;
		if (weekColors[curWeek] != null) {
			var c = FlxColor.fromString(weekColors[curWeek]);
			if (c != null) co = c;
		}
		colorTween = FlxTween.color(yellowBG, 0.8, yellowBG.color, co, {ease : FlxEase.quintOut});

		updateText();
	}

	function updateText()
	{
		txtTracklist.text = "Tracks\n";

		for (i in 0...grpWeekCharacters.length) {
			grpWeekCharacters.members[i].changeCharacter(weekCharacters[curWeek][i]);
		}

		var stringThing:Array<String> = weekData[curWeek];

		for (i in stringThing)
		{
			txtTracklist.text += "\n" + i;
		}

		txtTracklist.text += "\n";

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		var diff:String = CoolUtil.songDifficulties[curDifficulty].toLowerCase().trim();
		intendedScore = Highscore.getWeekScore(curWeek, diff);
		#end
	}

	public function addWeek(weekDataDef:WeekData) {
		weekNames.push(weekDataDef.name);
		weekTextures.push(weekDataDef.texture);
		weekData.push(weekDataDef.songs);
		weekCharacters.push(weekDataDef.characters);
		weekDifficulties.push(weekDataDef.difficulties);
		weekColors.push(weekDataDef.color);
	}

	public function readWeekFile() {
		var weeks = Json.parse(Assets.getText(Paths.json('weeks/weeks'))).weeks;
		for (i in 0...weeks.length) {
			addWeek(cast weeks[i]);
		}

        #if sys
		for (modFolder in ModPaths.getModFolders()) {
			if (modFolder.enabled) {
				var modFolderPath:String = ModPaths.modPath(modFolder.folder, 'data/weeks');
				if (ModPaths.isDirectory(modFolderPath)) {
					for (weekJson in ModPaths.readDirectory(modFolderPath)) {
						if (weekJson != null && weekJson.endsWith('.json')) {
							var jsonContent:String = ModPaths.readContent(ModPaths.modPath(modFolder.folder, 'data/weeks/' + weekJson));
							var weekData:Dynamic = Json.parse(jsonContent);
							addWeek(weekData);
						}
					}
				}
			}
		}
		#end
	}
}

typedef WeekData = {
	var name:String;
	var texture:String;
	var songs:Array<String>;
	var characters:Array<String>;
	var difficulties:Array<String>;
	var ?color:String;
}
