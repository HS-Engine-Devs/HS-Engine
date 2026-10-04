package states;

#if desktop
import system.Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.utils.Assets;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	private var curDiffString:String = "normal";
	private var curDiffArray:Array<String> = ["easy", "normal", "hard"];

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 0...initSonglist.length)
		{
			var data:Array<String> = initSonglist[i].split(':');
			var diffsStr = data[3];
			var diffs = ["easy", "normal", "hard"];
			if (diffsStr != null)
				diffs = diffsStr.split(",");
			songs.push(new SongMetadata(data[0], Std.parseInt(data[2]), data[1], diffs));
		}

		#if sys
		for (modFolder in ModPaths.getModFolders()) {
			if (modFolder.enabled) {
				var songListPath:String = ModPaths.modPath(modFolder.folder, 'data/songList.txt');
				if (ModPaths.exists(songListPath)) {
				    var songList = modTxtFile(songListPath);
					for (i in 0...songList.length) {
						var data:Array<String> = songList[i].split(":");
						var diffsStr = data[3];
						var diffs = ["easy", "normal", "hard"];
						if (diffsStr != null)
							diffs = diffsStr.split(",");
			            songs.push(new SongMetadata(data[0], Std.parseInt(data[2]), data[1], diffs));
					}
				}
			}
		}
		#end

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var displayName:String = formatFreeplayDisplayName(songs[i].songName);
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, displayName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		changeSelection();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			Logger.log(md);
		 */

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, ?difficulties:Array<String>)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, difficulties));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>, ?difficulties:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['dad'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num], difficulties);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			#if sys
			scriptState.callFunction("goToMenu", []);
			#end
			FlxG.switchState(new MainMenuState());
		}

		if (accepted)
		{
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDiffString);

			#if sys
			if (!Assets.exists(Paths.json('charts/' + songs[curSelected].songName.toLowerCase() + '/' + poop)) && !ModPaths.exists(ModPaths.data('charts/' + songs[curSelected].songName.toLowerCase() + '/' + poop)))
			#else
			if (!Assets.exists(Paths.json('charts/' + songs[curSelected].songName.toLowerCase() + '/' + poop)))
		    #end
			{
				openSubState(new substates.MissingFileSubstate(poop));
			}
			else
			{
				Logger.log(poop);

				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				PlayState.isStoryMode = false;
				PlayState.storyDifficultyText = curDiffString.toUpperCase();
				PlayState.storyWeek = songs[curSelected].week;
				Logger.log('CUR WEEK' + PlayState.storyWeek);
				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
	}

	function changeDiff(change:Int = 0)
	{
        curDifficulty = FlxMath.wrap(curDifficulty + change, 0, curDiffArray.length - 1);
        curDiffString = curDiffArray[curDifficulty].toUpperCase();

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDiffString);
		#end

		diffText.text = '< ' + curDiffString + ' >';
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, grpSongs.length - 1);

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDiffString);
		// lerpScore = 0;
		#end

		#if PRELOAD_ALL
		FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		#end

		curDiffArray = songs[curSelected].difficulties;

        if (curDiffArray.indexOf(curDiffString.toLowerCase()) == -1)
		{
			curDiffString = "normal";
			curDifficulty = curDiffArray.indexOf(curDiffString.toLowerCase());
		}
		else
		{
			curDifficulty = curDiffArray.indexOf(curDiffString.toLowerCase());
		}

		changeDiff();

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	#if sys
	function modTxtFile(path:String):Array<String>
	{
		var daList:Array<String> = ModPaths.readContent(path).trim().split('\n');
		for (i in 0...daList.length) {
			daList[i] = daList[i].trim();
		}
		return daList;
	}
	#end

	private static function formatFreeplayDisplayName(name:String):String
	{
		return name.split("_").join(" ").split("-").join(" ");
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var difficulties:Array<String> = ["easy", "normal", "hard"];

	public function new(song:String, week:Int, songCharacter:String, ?difficulties:Array<String> = null)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;

		if(difficulties != null)
			this.difficulties = difficulties;
	}
}
