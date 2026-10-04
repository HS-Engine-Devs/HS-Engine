package states;

import flixel.util.FlxAxes;
import openfl.filters.BlurFilter;
#if desktop
import system.Discord.DiscordClient;
#end
import game.NoteSplash;
import system.Section.SwagSection;
import system.Song.SwagSong;
import shaders.WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.math.FlxAngle;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import flash.media.Sound;

#if VIDEOS
import hxvlc.flixel.FlxVideo;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState = null;

	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var deathCounter:Int = 0;

	var halloweenLevel:Bool = false;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public var boyfriendGroup:FlxTypedGroup<Boyfriend>;
	public var dadGroup:FlxTypedGroup<Character>;
	public var gfGroup:FlxTypedGroup<Character>;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	public var strumLine:FlxSprite;
	public var curSection:Int = 0;

	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

    public var isCameraOnForcedPos:Bool = false;

	public var strumLineNotes:FlxTypedGroup<FlxSprite>;
	public var playerStrums:FlxTypedGroup<FlxSprite>;
	public var dadStrums:FlxTypedGroup<FlxSprite>;

    public var bigSplashy:NoteSplash;

	public var camZooming:Bool = false;
	public var curSong:String = "";

	public var goToStory:Bool = true;
	public var goToGame:Bool = true;
	public var goToGameOver:Bool = true;
	public var goToPause:Bool = true;
	public var goToFreeplay:Bool = true;

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar;

	public var generatedMusic:Bool = false;
	public var startingSong:Bool = false;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	public var cameraSpeed:Float = 1;

	public var introSoundsSuffix:String = '';
	// public var noteSkinPath:String = 'NOTE_assets';
	public var noteSplashesPath:String = 'noteSplashes';

	public var accuracy:Float;

	public var botplayTxt:FlxText;

    public var camPos:FlxPoint;

	var stageBg:FlxSprite;
	var stageFront:FlxSprite;
    var stageCurtains:FlxSprite;

	var halloweenBG:FlxSprite;
	var isHalloween:Bool = false;

	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;

	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:FlxSprite;

	var upperBoppers:FlxSprite;
	var bottomBoppers:FlxSprite;
	var santa:FlxSprite;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();

	var foregroundSprites:FlxTypedGroup<BGSprite>;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;

	var talking:Bool = true;

	var rainShader:shaders.RainShader;
	var rainInensityEnd:Float = 0;

	var dimSprite:FlxSprite;
	var kickedCan:AtlasSprite;
	var characterGlow:FlxSprite;

	var phillyTraffic:FlxSprite;
	var phillyCars:FlxSprite;
	var phillyCarsBack:FlxSprite;

	var lightsStop:Bool = false;
	var lastChange:Int = 0;
	var changeInterval:Int = 8;

	var carWaiting:Bool = false;
	var carInterruptable:Bool = true;
	var car2Interruptable:Bool = true;

	var scrollingSkyAdd:FlxSprite;
	var streetBlurMultiply:FlxSprite;
	var additionalLighten:FlxSprite;
	var lightning:FlxSprite;

	var lightningSound:FlxSound = new FlxSound();
	var unpauseSoundCheck:Bool = false;

	var lightningTimer:Float = 3;
	var lightningActive:Bool = true;

	var abot:ABot;
	var abotLookDir:Bool = false;

	var finishedShooting:Bool = false;

	public var songScore:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	public static var campaignScore:Int = 0;
	public static var seenCutscene:Bool = false;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;

	public var gfVersion:String = 'gf';

	public var dadIsBetter:Bool = false;

	public var songHits:Int = 0;
	public var totalPlayed:Int = 0;

	#if sys
	public var scripts:Array<ModScripts> = [];
	#end

	public var foreground:FlxTypedGroup<FlxSprite>;

    public var dialogueFile:Array<String> = [];

	public static var storyDifficultyText:String = "";

	var songEvents:Array<ChartEvent> = [];

	#if desktop
	// Discord RPC variables
	var iconRPC:String = "";
	var songLength:Float = 0;
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	override public function create()
	{
		instance = this;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

        songEvents = [];
        if (SONG.events != null) {
            for (event in SONG.events) {
                if (event != null)
                    songEvents.push(event);
            }
        }
        songEvents.sort(function(a, b) return Reflect.compare(a.strumtime, b.strumtime));

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		foreground = new FlxTypedGroup<FlxSprite>();
		foregroundSprites = new FlxTypedGroup<BGSprite>();

		switch (SONG.song.toLowerCase())
		{
			case 'senpai':
				dialogueFile = CoolUtil.coolTextFile(Paths.txt('charts/senpai/senpaiDialogue'));
			case 'roses':
				dialogueFile = CoolUtil.coolTextFile(Paths.txt('charts/roses/rosesDialogue'));
			case 'thorns':
				dialogueFile = CoolUtil.coolTextFile(Paths.txt('charts/thorns/thornsDialogue'));
		}

		#if desktop
		// Making difficulty text for Discord Rich Presence.
		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week " + storyWeek;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		#end

		switch (SONG.song.toLowerCase())
		{
                        case 'spookeez' | 'monster' | 'south': 
                        {
                                curStage = 'spooky';
	                          halloweenLevel = true;

		                  var hallowTex = Paths.getSparrowAtlas('halloween_bg');

	                          halloweenBG = new FlxSprite(-200, -100);
		                  halloweenBG.frames = hallowTex;
	                          halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
	                          halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
	                          halloweenBG.animation.play('idle');
	                          halloweenBG.antialiasing = true;
	                          add(halloweenBG);

		                  isHalloween = true;
		          }
		          case 'pico' | 'blammed' | 'philly': 
                        {
		                  curStage = 'philly';

		                  var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('philly/sky'));
		                  bg.scrollFactor.set(0.1, 0.1);
		                  add(bg);

	                          var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('philly/city'));
		                  city.scrollFactor.set(0.3, 0.3);
		                  city.setGraphicSize(Std.int(city.width * 0.85));
		                  city.updateHitbox();
		                  add(city);

		                  phillyCityLights = new FlxTypedGroup<FlxSprite>();
		                  add(phillyCityLights);

		                  for (i in 0...5)
		                  {
		                          var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image('philly/win' + i));
		                          light.scrollFactor.set(0.3, 0.3);
		                          light.visible = false;
		                          light.setGraphicSize(Std.int(light.width * 0.85));
		                          light.updateHitbox();
		                          light.antialiasing = true;
		                          phillyCityLights.add(light);
		                  }

		                  var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('philly/behindTrain'));
		                  add(streetBehind);

	                          phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image('philly/train'));
		                  add(phillyTrain);

		                  trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
		                  FlxG.sound.list.add(trainSound);

		                  // var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

		                  var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.image('philly/street'));
	                          add(street);
		          }
		          case 'milf' | 'satin-panties' | 'high':
		          {
		                  curStage = 'limo';
		                  defaultCamZoom = 0.90;

		                  var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image('limo/limoSunset'));
		                  skyBG.scrollFactor.set(0.1, 0.1);
		                  add(skyBG);

		                  var bgLimo:FlxSprite = new FlxSprite(-200, 480);
		                  bgLimo.frames = Paths.getSparrowAtlas('limo/bgLimo');
		                  bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
		                  bgLimo.animation.play('drive');
		                  bgLimo.scrollFactor.set(0.4, 0.4);
		                  add(bgLimo);

		                  grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
		                  add(grpLimoDancers);

		                  for (i in 0...5)
		                  {
		                          var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
		                          dancer.scrollFactor.set(0.4, 0.4);
		                          grpLimoDancers.add(dancer);
		                  }

		                  var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic(Paths.image('limo/limoOverlay'));
		                  overlayShit.alpha = 0.5;
		                  // add(overlayShit);

		                  // var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

		                  // FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

		                  // overlayShit.shader = shaderBullshit;

		                  var limoTex = Paths.getSparrowAtlas('limo/limoDrive');

		                  limo = new FlxSprite(-120, 550);
		                  limo.frames = limoTex;
		                  limo.animation.addByPrefix('drive', "Limo stage", 24);
		                  limo.animation.play('drive');
		                  limo.antialiasing = true;

		                  fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image('limo/fastCarLol'));
		                  // add(limo);
		          }
		          case 'cocoa' | 'eggnog':
		          {
	                          curStage = 'mall';

		                  defaultCamZoom = 0.80;

		                  var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image('christmas/bgWalls'));
		                  bg.antialiasing = true;
		                  bg.scrollFactor.set(0.2, 0.2);
		                  bg.active = false;
		                  bg.setGraphicSize(Std.int(bg.width * 0.8));
		                  bg.updateHitbox();
		                  add(bg);

		                  upperBoppers = new FlxSprite(-240, -90);
		                  upperBoppers.frames = Paths.getSparrowAtlas('christmas/upperBop');
		                  upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
		                  upperBoppers.antialiasing = true;
		                  upperBoppers.scrollFactor.set(0.33, 0.33);
		                  upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
		                  upperBoppers.updateHitbox();
		                  add(upperBoppers);

		                  var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image('christmas/bgEscalator'));
		                  bgEscalator.antialiasing = true;
		                  bgEscalator.scrollFactor.set(0.3, 0.3);
		                  bgEscalator.active = false;
		                  bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
		                  bgEscalator.updateHitbox();
		                  add(bgEscalator);

		                  var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image('christmas/christmasTree'));
		                  tree.antialiasing = true;
		                  tree.scrollFactor.set(0.40, 0.40);
		                  add(tree);

		                  bottomBoppers = new FlxSprite(-300, 140);
		                  bottomBoppers.frames = Paths.getSparrowAtlas('christmas/bottomBop');
		                  bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
		                  bottomBoppers.antialiasing = true;
	                          bottomBoppers.scrollFactor.set(0.9, 0.9);
	                          bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
		                  bottomBoppers.updateHitbox();
		                  add(bottomBoppers);

		                  var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image('christmas/fgSnow'));
		                  fgSnow.active = false;
		                  fgSnow.antialiasing = true;
		                  add(fgSnow);

		                  santa = new FlxSprite(-840, 150);
		                  santa.frames = Paths.getSparrowAtlas('christmas/santa');
		                  santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
		                  santa.antialiasing = true;
		                  add(santa);
		          }
		          case 'winter-horrorland':
		          {
		                  curStage = 'mallEvil';
		                  var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('christmas/evilBG'));
		                  bg.antialiasing = true;
		                  bg.scrollFactor.set(0.2, 0.2);
		                  bg.active = false;
		                  bg.setGraphicSize(Std.int(bg.width * 0.8));
		                  bg.updateHitbox();
		                  add(bg);

		                  var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image('christmas/evilTree'));
		                  evilTree.antialiasing = true;
		                  evilTree.scrollFactor.set(0.2, 0.2);
		                  add(evilTree);

		                  var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image("christmas/evilSnow"));
	                          evilSnow.antialiasing = true;
		                  add(evilSnow);
                        }
		          case 'senpai' | 'roses':
		          {
		                  curStage = 'school';

		                  // defaultCamZoom = 0.9;

		                  var bgSky = new FlxSprite().loadGraphic(Paths.image('weeb/weebSky'));
		                  bgSky.scrollFactor.set(0.1, 0.1);
		                  add(bgSky);

		                  var repositionShit = -200;

		                  var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('weeb/weebSchool'));
		                  bgSchool.scrollFactor.set(0.6, 0.90);
		                  add(bgSchool);

		                  var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/weebStreet'));
		                  bgStreet.scrollFactor.set(0.95, 0.95);
		                  add(bgStreet);

		                  var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('weeb/weebTreesBack'));
		                  fgTrees.scrollFactor.set(0.9, 0.9);
		                  add(fgTrees);

		                  var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
		                  var treetex = Paths.getPackerAtlas('weeb/weebTrees');
		                  bgTrees.frames = treetex;
		                  bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		                  bgTrees.animation.play('treeLoop');
		                  bgTrees.scrollFactor.set(0.85, 0.85);
		                  add(bgTrees);

		                  var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
		                  treeLeaves.frames = Paths.getSparrowAtlas('weeb/petals');
		                  treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
		                  treeLeaves.animation.play('leaves');
		                  treeLeaves.scrollFactor.set(0.85, 0.85);
		                  add(treeLeaves);

		                  var widShit = Std.int(bgSky.width * 6);

		                  bgSky.setGraphicSize(widShit);
		                  bgSchool.setGraphicSize(widShit);
		                  bgStreet.setGraphicSize(widShit);
		                  bgTrees.setGraphicSize(Std.int(widShit * 1.4));
		                  fgTrees.setGraphicSize(Std.int(widShit * 0.8));
		                  treeLeaves.setGraphicSize(widShit);

		                  fgTrees.updateHitbox();
		                  bgSky.updateHitbox();
		                  bgSchool.updateHitbox();
		                  bgStreet.updateHitbox();
		                  bgTrees.updateHitbox();
		                  treeLeaves.updateHitbox();

		                  bgGirls = new BackgroundGirls(-100, 190);
		                  bgGirls.scrollFactor.set(0.9, 0.9);

		                  if (SONG.song.toLowerCase() == 'roses')
	                          {
		                          bgGirls.getScared();
		                  }

		                  bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
		                  bgGirls.updateHitbox();
		                  add(bgGirls);
		          }
		          case 'thorns':
		          {
		                  curStage = 'schoolEvil';

		                  var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
		                  var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

		                  var posX = 400;
	                          var posY = 200;

		                  var bg:FlxSprite = new FlxSprite(posX, posY);
		                  bg.frames = Paths.getSparrowAtlas('weeb/animatedEvilSchool');
		                  bg.animation.addByPrefix('idle', 'background 2', 24);
		                  bg.animation.play('idle');
		                  bg.scrollFactor.set(0.8, 0.9);
		                  bg.scale.set(6, 6);
		                  add(bg);

		                  /* 
		                           var bg:FlxSprite = new FlxSprite(posX, posY).loadGraphic(Paths.image('weeb/evilSchoolBG'));
		                           bg.scale.set(6, 6);
		                           // bg.setGraphicSize(Std.int(bg.width * 6));
		                           // bg.updateHitbox();
		                           add(bg);

		                           var fg:FlxSprite = new FlxSprite(posX, posY).loadGraphic(Paths.image('weeb/evilSchoolFG'));
		                           fg.scale.set(6, 6);
		                           // fg.setGraphicSize(Std.int(fg.width * 6));
		                           // fg.updateHitbox();
		                           add(fg);

		                           wiggleShit.effectType = WiggleEffectType.DREAMY;
		                           wiggleShit.waveAmplitude = 0.01;
		                           wiggleShit.waveFrequency = 60;
		                           wiggleShit.waveSpeed = 0.8;
		                    */

		                  // bg.shader = wiggleShit.shader;
		                  // fg.shader = wiggleShit.shader;

		                  /* 
		                            var waveSprite = new FlxEffectSprite(bg, [waveEffectBG]);
		                            var waveSpriteFG = new FlxEffectSprite(fg, [waveEffectFG]);

		                            // Using scale since setGraphicSize() doesnt work???
		                            waveSprite.scale.set(6, 6);
		                            waveSpriteFG.scale.set(6, 6);
		                            waveSprite.setPosition(posX, posY);
		                            waveSpriteFG.setPosition(posX, posY);

		                            waveSprite.scrollFactor.set(0.7, 0.8);
		                            waveSpriteFG.scrollFactor.set(0.9, 0.8);

		                            // waveSprite.setGraphicSize(Std.int(waveSprite.width * 6));
		                            // waveSprite.updateHitbox();
		                            // waveSpriteFG.setGraphicSize(Std.int(fg.width * 6));
		                            // waveSpriteFG.updateHitbox();

		                            add(waveSprite);
		                            add(waveSpriteFG);
		                    */
		          }
				  case 'guns' | 'stress' | 'ugh':
				  { 
					defaultCamZoom = 0.90;
					curStage = 'tank';
	
					var bg:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
					add(bg);
	
					var tankSky:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					tankSky.active = true;
					tankSky.velocity.x = FlxG.random.float(5, 15);
					add(tankSky);
	
					var tankMountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					tankMountains.setGraphicSize(Std.int(tankMountains.width * 1.2));
					tankMountains.updateHitbox();
					add(tankMountains);
	
					var tankBuildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.30, 0.30);
					tankBuildings.setGraphicSize(Std.int(tankBuildings.width * 1.1));
					tankBuildings.updateHitbox();
					add(tankBuildings);
	
					var tankRuins:BGSprite = new BGSprite('tankRuins', -200, 0, 0.35, 0.35);
					tankRuins.setGraphicSize(Std.int(tankRuins.width * 1.1));
					tankRuins.updateHitbox();
					add(tankRuins);
	
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
	
					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);
	
					// tankGround.
	
					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
	
					tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5, ['BG tank w lighting'], true);
					add(tankGround);
					// tankGround.active = false;
	
					tankmanRun = new FlxTypedGroup<TankmenBG>();
					add(tankmanRun);
	
					var tankGround:BGSprite = new BGSprite('tankGround', -420, -150);
					tankGround.setGraphicSize(Std.int(tankGround.width * 1.15));
					tankGround.updateHitbox();
					add(tankGround);
	
					moveTank();
	
					// smokeLeft.screenCenter();
	
					var fgTank0:BGSprite = new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']);
					foregroundSprites.add(fgTank0);
	
					var fgTank1:BGSprite = new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']);
					foregroundSprites.add(fgTank1);
	
					// just called 'foreground' just cuz small inconsistency no bbiggei
					var fgTank2:BGSprite = new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']);
					foregroundSprites.add(fgTank2);
	
					var fgTank4:BGSprite = new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']);
					foregroundSprites.add(fgTank4);
	
					var fgTank5:BGSprite = new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']);
					foregroundSprites.add(fgTank5);
	
					var fgTank3:BGSprite = new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']);
					foregroundSprites.add(fgTank3);
				  }
				  case 'darnell' | 'lit-up' | '2hot':
					defaultCamZoom = 0.75;
					curStage = 'phillyStreets';

					var scrollingSky = new FlxBackdrop(Paths.image("phillyStreets/phillySkybox", "weekend1"), 0x10);
					scrollingSky.setPosition(-650, -375);
					scrollingSky.scrollFactor.set(0.1, 0.1);
					scrollingSky.scale.set(0.65, 0.65);
					scrollingSky.velocity.x = -22;
					scrollingSky.antialiasing = true;
					add(scrollingSky);

					var phillySkyline = new FlxSprite(-545, -273).loadGraphic(Paths.image("phillyStreets/phillySkyline", "weekend1"));
					phillySkyline.scrollFactor.set(0.2, 0.2);
					phillySkyline.antialiasing = true;
					add(phillySkyline);

					var phillyForegroundCity = new FlxSprite(625, 94).loadGraphic(Paths.image("phillyStreets/phillyForegroundCity", "weekend1"));
					phillyForegroundCity.scrollFactor.set(0.3, 0.3);
					phillyForegroundCity.antialiasing = true;
					add(phillyForegroundCity);
			
					var phillyHighwayLights = new FlxSprite(284-400, 305).loadGraphic(Paths.image("phillyStreets/phillyHighwayLights", "weekend1"));
					phillyHighwayLights.scrollFactor.set(0.7, 1);
					phillyHighwayLights.antialiasing = true;
					add(phillyHighwayLights);
			
					var phillyHighwayLights_lightmap = new FlxSprite(284-400, 305).loadGraphic(Paths.image("phillyStreets/phillyHighwayLights_lightmap", "weekend1"));
					phillyHighwayLights_lightmap.scrollFactor.set(0.7, 1);
					phillyHighwayLights_lightmap.antialiasing = true;
					phillyHighwayLights_lightmap.blend = BlendMode.ADD;
					phillyHighwayLights_lightmap.alpha = 0.6;
					add(phillyHighwayLights_lightmap);
			
					var phillyHighway = new FlxSprite(139-400, 209).loadGraphic(Paths.image("phillyStreets/phillyHighway", "weekend1"));
					phillyHighway.scrollFactor.set(0.7, 1);
					phillyHighway.antialiasing = true;
					add(phillyHighway);
			
					var phillyConstruction = new FlxSprite(1800, 364).loadGraphic(Paths.image("phillyStreets/phillyConstruction", "weekend1"));
					phillyConstruction.scrollFactor.set(0.7, 1);
					phillyConstruction.antialiasing = true;
					add(phillyConstruction);
			
					var phillySmog = new FlxSprite(-6, 245).loadGraphic(Paths.image("phillyStreets/phillySmog", "weekend1"));
					phillySmog.scrollFactor.set(0.8, 1);
					phillySmog.antialiasing = true;
					add(phillySmog);
					
					phillyCarsBack = new FlxSprite(1748, 818);
					phillyCarsBack.frames = Paths.getSparrowAtlas("phillyStreets/phillyCars", "weekend1");
					phillyCarsBack.scrollFactor.set(0.9, 1);
					phillyCarsBack.antialiasing = true;
					phillyCarsBack.flipX = true;
					phillyCarsBack.animation.addByPrefix("car1", "car1", 0, false);
					phillyCarsBack.animation.addByPrefix("car2", "car2", 0, false);
					phillyCarsBack.animation.addByPrefix("car3", "car3", 0, false);
					phillyCarsBack.animation.addByPrefix("car4", "car4", 0, false);
					add(phillyCarsBack);
			
					phillyCars = new FlxSprite(1748, 818);
					phillyCars.frames = Paths.getSparrowAtlas("phillyStreets/phillyCars", "weekend1");
					phillyCars.scrollFactor.set(0.9, 1);
					phillyCars.antialiasing = true;
					phillyCars.animation.addByPrefix("car1", "car1", 0, false);
					phillyCars.animation.addByPrefix("car2", "car2", 0, false);
					phillyCars.animation.addByPrefix("car3", "car3", 0, false);
					phillyCars.animation.addByPrefix("car4", "car4", 0, false);
					add(phillyCars);
					
					phillyTraffic = new FlxSprite(1840, 608);
					phillyTraffic.frames = Paths.getSparrowAtlas("phillyStreets/phillyTraffic", "weekend1");
					phillyTraffic.scrollFactor.set(0.9, 1);
					phillyTraffic.antialiasing = true;
					phillyTraffic.animation.addByPrefix("togreen", "redtogreen", 24, false);
					phillyTraffic.animation.addByPrefix("tored", "greentored", 24, false);
					add(phillyTraffic);
			
					resetCar(true, true);

					var phillyTraffic_lightmap = new FlxSprite(1840, 608).loadGraphic(Paths.image("phillyStreets/phillyTraffic_lightmap", "weekend1"));
					phillyTraffic_lightmap.scrollFactor.set(0.9, 1);
					phillyTraffic_lightmap.antialiasing = true;
					phillyTraffic_lightmap.blend = BlendMode.ADD;
					phillyTraffic_lightmap.alpha = 0.6;
					add(phillyTraffic_lightmap);

					var phillyForeground = new FlxSprite(88, 317).loadGraphic(Paths.image("phillyStreets/phillyForeground", "weekend1"));
					phillyForeground.antialiasing = true;
					add(phillyForeground);

					dimSprite = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
					dimSprite.scale.set(1280/.5, 720/.5);
					dimSprite.updateHitbox();
					dimSprite.screenCenter();
					dimSprite.scrollFactor.set();
					dimSprite.alpha = 0;
					add(dimSprite);
				  case 'blazin':
				    defaultCamZoom = 0.75;
				    curStage = 'phillyBlazin';

		            var scrollingSky = new FlxBackdrop(Paths.image("phillyBlazin/skyBlur", "weekend1"), 0x10);
		            scrollingSky.setPosition(-600, -175);
		            scrollingSky.scrollFactor.set();
		            scrollingSky.scale.set(1.75, 1.75);
		            scrollingSky.updateHitbox();
		            scrollingSky.velocity.x = -35;
		            scrollingSky.antialiasing = true;
		            add(scrollingSky);

		            scrollingSkyAdd = new FlxBackdrop(Paths.image("phillyBlazin/skyBlur", "weekend1"), 0x10);
		            scrollingSkyAdd.setPosition(-600, -175);
		            scrollingSkyAdd.scrollFactor.set();
		            scrollingSkyAdd.scale.set(1.75, 1.75);
		            scrollingSkyAdd.updateHitbox();
		            scrollingSkyAdd.velocity.x = -35;
		            scrollingSkyAdd.antialiasing = true;
		            scrollingSkyAdd.blend = BlendMode.ADD;
		            scrollingSkyAdd.visible = false;
		            add(scrollingSkyAdd);

		            lightning = new FlxSprite(50, -300);
		            lightning.frames = Paths.getSparrowAtlas("phillyBlazin/lightning", "weekend1");
		            lightning.animation.addByPrefix("strike", "lightning", 24, false);
		            lightning.scrollFactor.set();
		            lightning.scale.set(1.75, 1.75);
		            lightning.visible = false;
		            lightning.updateHitbox();
		            lightning.antialiasing = true;
		            add(lightning);

		            var streetBlur = new FlxSprite(-600 + 152, -175 + 70).loadGraphic(Paths.image("phillyBlazin/streetBlur", "weekend1"));
		            streetBlur.scrollFactor.set(0.2, 0.2);
		            streetBlur.scale.set(1.75, 1.75);
		            streetBlur.updateHitbox();
		            streetBlur.antialiasing = true;
		            add(streetBlur);

		            streetBlurMultiply = new FlxSprite(-600 + 152, -175 + 70).loadGraphic(Paths.image("phillyBlazin/streetBlur", "weekend1"));
		            streetBlurMultiply.scrollFactor.set(0.2, 0.2);
		            streetBlurMultiply.scale.set(1.75, 1.75);
		            streetBlurMultiply.updateHitbox();
		            streetBlurMultiply.antialiasing = true;
		            streetBlurMultiply.blend = BlendMode.MULTIPLY;
		            streetBlurMultiply.visible = false;
		            add(streetBlurMultiply);

		            additionalLighten = new FlxSprite().makeGraphic(1, 1, 0xFFFFFFFF);
		            additionalLighten.scale.set(1280/defaultCamZoom, 720/defaultCamZoom);
		            additionalLighten.scrollFactor.set();
		            additionalLighten.updateHitbox();
		            additionalLighten.screenCenter();
		            additionalLighten.visible = false;
		            add(additionalLighten);
		          default:
		          {
		                  defaultCamZoom = 0.9;
		                  curStage = 'stage';
				
		                  stageBg = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback'));
		                  stageBg.antialiasing = true;
		                  stageBg.scrollFactor.set(0.9, 0.9);
		                  stageBg.active = false;
		                  add(stageBg);

		                  stageFront = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
		                  stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		                  stageFront.updateHitbox();
		                  stageFront.antialiasing = true;
		                  stageFront.scrollFactor.set(0.9, 0.9);
		                  stageFront.active = false;
		                  add(stageFront);

		                  stageCurtains = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains'));
		                  stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		                  stageCurtains.updateHitbox();
		                  stageCurtains.antialiasing = true;
		                  stageCurtains.scrollFactor.set(1.3, 1.3);
		                  stageCurtains.active = false;

		                  add(stageCurtains);
		          }
              }

		#if sys
		if (ModPaths.exists(ModPaths.data("stages/" + SONG.stage))) {
			new Stage(ModPaths.readContent(ModPaths.data("stages/" + SONG.stage)));
			defaultCamZoom = Stage.stageZoom;
			stageBg.alpha = 0;
			stageFront.alpha = 0;
			stageCurtains.alpha = 0;
		}
		#end

		#if sys
		setScriptFunction();
		#end

		if (curStage.startsWith('school')) {
			introSoundsSuffix = '-pixel';
		}

		if (SONG.gfVersion == null) {
			switch (curStage) {
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				case 'phillyStreets' | 'phillyBlazin':
					gfVersion = 'nene';
			}
		} else {
			gfVersion = SONG.gfVersion;
		}

		if (SONG.song.toLowerCase() == 'stress')
			gfVersion = 'pico-speaker';

		abot = new ABot(1100, 740);
		abot.lookLeft();

		if (gfVersion == 'nene')
			add(abot);

		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		#if sys
		if (ModPaths.exists(ModPaths.data("stages/" + SONG.stage))) {
			gf.x = Stage.gfPos[0];
			gf.y = Stage.gfPos[1];
		}
		#end

		gf.x += gf.characterOffset[0];
		gf.y += gf.characterOffset[1];

		switch (gfVersion)
		{
			case 'pico-speaker':
				gf.x -= 50;
				gf.y -= 200;

				var tempTankman:TankmenBG = new TankmenBG(20, 500, true);
				tempTankman.strumTime = 10;
				tempTankman.resetShit(20, 600, true);
				tankmanRun.add(tempTankman);

				for (i in 0...TankmenBG.animationNotes.length)
				{
					if (FlxG.random.bool(16))
					{
						var tankman:TankmenBG = tankmanRun.recycle(TankmenBG);
						// new TankmenBG(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
						tankman.strumTime = TankmenBG.animationNotes[i][0];
						tankman.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
						tankmanRun.add(tankman);
					}
				}
			case 'nene':
				gf.scrollFactor.set(1, 1);
		}

		dad = new Character(100, 100, SONG.player2);

        #if sys
		if (ModPaths.exists(ModPaths.data("stages/" + SONG.stage))) {
			dad.x = Stage.dadPos[0];
			dad.y = Stage.dadPos[1];
		}
		#end

        dad.x += dad.characterOffset[0];
		dad.y += dad.characterOffset[1];

		camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
			case 'senpai':
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'senpai-angry':
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'darnell':
				camPos.set(dad.getGraphicMidpoint().x + 950, dad.getGraphicMidpoint().y + 400);
		}

		boyfriend = new Boyfriend(770, 100, SONG.player1);

        #if sys
		if (ModPaths.exists(ModPaths.data("stages/" + SONG.stage))) {
			boyfriend.x = Stage.bfPos[0];
			boyfriend.y = Stage.bfPos[1];
		}
		#end

		boyfriend.x += boyfriend.characterOffset[0];
		boyfriend.y += boyfriend.characterOffset[1];

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'limo':
				boyfriend.y -= 220;
				boyfriend.x += 260;

				resetFastCar();
				add(fastCar);

			case 'mall':
				boyfriend.x += 200;

			case 'mallEvil':
				boyfriend.x += 320;
				dad.y -= 80;
			case 'school':
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case 'schoolEvil':
				// trailArea.scrollFactor.set();

				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				// evilTrail.changeValuesEnabled(false, false, false, false);
				// evilTrail.changeGraphic()
				add(evilTrail);
				// evilTrail.scrollFactor.set(1.1, 1.1);

				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case "tank":
				gf.y += 10;
				gf.x -= 30;
				boyfriend.x += 40;
				boyfriend.y += 0;
				dad.y += 60;
				dad.x -= 80;

				if (gfVersion != 'pico-speaker')
				{
					gf.x -= 170;
					gf.y -= 75;
				}
			case "phillyStreets":
				boyfriend.x = 2151 - 271;
				boyfriend.y = 1228 - 450;

                dad.x = 900 - 275;
				dad.y = 1110 - 475;

				gf.x = 1453 - 203;
				gf.y = 430;
			case "phillyBlazin":
				var gfPosOffset:FlxPoint = new FlxPoint(-225, -110);

			    boyfriend.x = 1372;
				boyfriend.y = 411;

		        dad.x = 730;
				dad.y = 377;

		        //  gf.x = 1353 + gfPosOffset.x;
				//  gf.y = 1090 + gfPosOffset.y;
		}

		gfGroup = new FlxTypedGroup<Character>();
		boyfriendGroup = new FlxTypedGroup<Boyfriend>();
		dadGroup = new FlxTypedGroup<Character>();

		add(gfGroup);
		gfGroup.add(gf);

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		if (dadIsBetter == false) {
			if (SONG.song.toLowerCase() != 'tutorial') {
				add(boyfriendGroup);
				boyfriendGroup.add(boyfriend);
			}
		}

        if (dadIsBetter == true) {
			add(dadGroup);
			dadGroup.add(dad);
		}

        #if sys
		if (dadIsBetter == false) {
			callOnScripts("betweenCharacters", []);
		}
		#end

        if (curStage == "phillyStreets") {
			characterGlow = new FlxSprite();
			characterGlow.visible = false;
			add(characterGlow);
		}

        if (dadIsBetter == false) {
		    add(dadGroup);
		    dadGroup.add(dad);
		}

        #if sys
		if (dadIsBetter == true) {
			callOnScripts("betweenCharacters", []);
		}
		#end

		if (dadIsBetter == true) {
			if (SONG.song.toLowerCase() != 'tutorial') {
				add(boyfriendGroup);
				boyfriendGroup.add(boyfriend);
			}
		}

		if (SONG.song.toLowerCase() == 'tutorial') {
			add(boyfriendGroup);
			boyfriendGroup.add(boyfriend);
		}

        if (curStage == "phillyStreets") {
			var spraycanPile = new FlxSprite(920, 1045).loadGraphic(Paths.image("phillyStreets/SpraycanPile", "weekend1"));
		    spraycanPile.antialiasing = true;
		    add(spraycanPile);

			kickedCan = new AtlasSprite(spraycanPile.x - 430, spraycanPile.y - 840, Paths.getTextureAtlas("spraycanAtlas", "weekend1"));
			kickedCan.antialiasing = true;
			kickedCan.visible = false;
			kickedCan.addAnimationByLabel("start", "Can Start", 24, false);
			kickedCan.addAnimationByFrame("kickUp", 0, 8, 24, false);
			kickedCan.addAnimationByFrame("kickUpSlow", 0, 8, 17, false);
			kickedCan.addAnimationByFrame("kickForward", 8, 11, 24, false);
			kickedCan.addAnimationByLabel("hit", "Hit Pico", 24, false);
			kickedCan.addAnimationByLabel("shot", "Can Shot", 24, false);
			kickedCan.animationEndCallback = function(name) {
				if(name == "hit" || name == "shot"){
					kickedCan.visible = false;
				}
			}
			add(kickedCan);
		}

        if (curStage == "phillyBlazin") {
			boyfriend.color = 0xFFDEDEDE;
		    dad.color = 0xFFDEDEDE;

		    gf.scrollFactor.set(0.7, 0.7);
		    gf.color = 0xFF888888;
		}

        if (curStage == "phillyStreets" || curStage == "phillyBlazin") {
			var rainStrength = (curStage == "phillyBlazin") ? 0.5 : (curStage == "phillyStreets") ? 0 : 0;
            rainShader = new shaders.RainShader(rainStrength, FlxG.height / 200);

			var shaderFilter = new ShaderFilter(rainShader.shader);
			camGame.setFilters([shaderFilter]);
			camGame.filtersEnabled = true;
			add(rainShader);

			if (SONG.song.toLowerCase() == 'darnell') {
				rainShader.uIntensity = 0;
				rainInensityEnd = 0.1;
			} else if (SONG.song.toLowerCase() == '2hot') {
				rainShader.uIntensity = 0.2;
				rainInensityEnd = 0.3;
			} else {
				rainShader.uIntensity = 0.1;
				rainInensityEnd = 0.2;
			}
		}

		add(foreground);
		add(foregroundSprites);

		var doof:DialogueBox = new DialogueBox(false, dialogueFile);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		if (Config.downScroll)
			strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();
        dadStrums = new FlxTypedGroup<FlxSprite>();

		// startCountdown();

		generateSong(SONG.song);

		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar'));
		if (Config.downScroll)
			healthBarBG.y = 80;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		scoreTxt = new FlxText(0, healthBarBG.y + 30, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, 0xFF000000);
		scoreTxt.borderSize = 2;
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		botplayTxt = new FlxText(0, 0, FlxG.width, "> BOTPLAY <", 28);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER, OUTLINE, 0xFF000000);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 2;
		botplayTxt.y = 90;
		if (Config.middleScroll)
			botplayTxt.y = 15;
		if (Config.downScroll)
			botplayTxt.y = FlxG.height - 105;
		if (Config.middleScroll) {
			if (Config.downScroll)
			    botplayTxt.y = FlxG.height - 40;
		}
		add(botplayTxt);

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		doof.cameras = [camOther];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode && !seenCutscene)
		{
			switch (curSong.toLowerCase())
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});

					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if(gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						snapCamFollowToPos(400, -2050);
						FlxG.camera.focusOn(camFollow);
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai':
					schoolIntro(doof);
				case 'roses':
					FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				case 'thorns':
					schoolIntro(doof);
				case 'ugh':
					startVideo('ughCutscene');
				case 'guns':
					startVideo('gunsCutscene');
				case 'stress':
					startVideo('stressCutscene');
				case 'darnell':
					darnellVideo();
				default:
					#if sys
                    var cutscenePath:String = ModPaths.script("data/cutscenes/" + SONG.song.toLowerCase());
					if (ModPaths.exists(cutscenePath)) {
                        addScript(cutscenePath); 
                        callOnScripts('startCutscene', []);
                    } else {
                        startCountdown();
                    }
					#end
					    startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
					startCountdown();
			}
		}

		super.create();

		#if sys
		callOnScripts("createPost", []);
		#end
	}

	#if sys
    function addScript(path:String) {
		if (!ModPaths.exists(path)) return;

        var newScript:ModScripts = new ModScripts();
        var variables = newScript.interp.variables;

		variables.set("add", function(value:FlxObject) {
			add(value);
		});

		variables.set("remove", function(value:FlxObject) {
			remove(value);
		});

		variables.set("insert", function(position:Int, value:FlxObject) {
			insert(position, value);
		});

		variables.set("removeStage", function() {
            remove(stageBg);
            remove(stageFront);
            remove(stageCurtains);
		});

		variables.set("startVideo", function(videoFile:String) {
			#if VIDEOS
			if(sys.FileSystem.exists(Paths.video(videoFile))) {
				startVideo(videoFile);
				return true;
			}
			return false;
			#else
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
			return true;
			#end
		});

		variables.set("getObject", function(object:String) {
			var object:FlxSprite = Stage.objectMap.get(object);
			return object;
		});

		variables.set("members", members);

		variables.set("camFollow", camFollow);
		variables.set("camFollowPos", camFollowPos);

		variables.set("boyfriend", boyfriend);
		variables.set("dad", dad);
		variables.set("gf", gf);

		variables.set("boyfriendGroup", boyfriendGroup);
		variables.set("dadGroup", dadGroup);
		variables.set("gfGroup", gfGroup);

		variables.set("camHUD", camHUD);
		variables.set("camGame", camGame);
		variables.set("camOther", camOther);

		variables.set("defaultCamZoom", defaultCamZoom);
		variables.set("curSong", SONG.song);
		variables.set("SONG", SONG);
		variables.set("curStage", curStage);

		variables.set("this", this);

		variables.set("inCutscene", inCutscene);
		variables.set("curBeat", curBeat);
		variables.set("curStep", curStep);

		variables.set("playerStrums", playerStrums);
		variables.set("dadStrums", dadStrums);
		variables.set("strumLineNotes", strumLineNotes);

		variables.set("noteSplashes", bigSplashy);

		if (SONG.notes[Math.floor(curStep / 16)] != null){
			variables.set('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			variables.set('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
		}

        newScript.loadScript(path);
        scripts.push(newScript);
	}

    function setScriptFunction() {
        scripts = [];

        var chartScript = ModPaths.script("data/charts/" + SONG.song.toLowerCase() + "/script");
        addScript(chartScript);

        for (modFolder in ModPaths.getModFolders()) {
            if (modFolder.enabled) {
				var modScriptFolderPath:String = ModPaths.modPath(modFolder.folder, 'data/scripts');
				if (ModPaths.isDirectory(modScriptFolderPath)) {
					for (file in ModPaths.readDirectory(modScriptFolderPath)) {
                        if (file != null && file.endsWith('.hx')) {
							addScript(ModPaths.modPath(modFolder.folder, 'data/scripts/' + file));
                        }
                    }
                }
            }
        }

        var stageScript = ModPaths.script("data/stages/" + SONG.stage);
        addScript(stageScript);

        callOnScripts('create', []);
    }

    public function setOnScripts(varName:String, value:Dynamic) {
        for (s in scripts) {
            if (s != null && s.interp != null) {
                s.interp.variables.set(varName, value);
            }
        }
    }

    public function callOnScripts(funcName:String, args:Array<Dynamic>) {
        for (s in scripts) {
            if (s != null) {
                s.callFunction(funcName, args);
            }
        }
    }
    #end

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		camHUD.visible = false;

		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
						add(dialogueBox);
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	public var runVideo:Bool = false;
	public var videoOver:Bool = false;
    public var video:FlxVideo = null;
    public var black:FlxSprite = null;

    function darnellVideo() {
		runVideo = true;
		inCutscene = true;
		camHUD.visible = false;
		FlxG.camera.zoom = 1.3;

		#if VIDEOS
		black = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		video = new FlxVideo();
		video.load(Paths.video('darnellCutscene'));
		video.onEndReached.add(function()
		{
			video.dispose();
			black.visible = false;
			videoOver = true;
			runVideo = false;
			darnellIntro();
			return;
		}, true);

		video.play();
		#else
		Logger.log('Warn: Platform not supported!');
		darnellIntro();
		return;
		#end
	}

    function darnellIntro() {
	    var beatTime:Float;
	    var picoPos:FlxPoint;
	    var darnellPos:FlxPoint;
	    var cutsceneManager:CutsceneManager;

		picoPos = new FlxPoint(boyfriend.getMidpoint().x - 100 + boyfriend.cameraOffset[0], boyfriend.getMidpoint().y - 100 + boyfriend.cameraOffset[1]);
		darnellPos = new FlxPoint(dad.getMidpoint().x + 150 + dad.cameraOffset[0], dad.getMidpoint().y - 100 + dad.cameraOffset[1]);

		beatTime = Conductor.getBeatTimeFromBpm(168);

		FlxG.sound.play(Paths.music("darnellCanCutscene", "weekend1"));
		camGame.fade(0xFF000000, 2, true);

		boyfriend.playAnim("pissed", true);
		dad.playAnim("idleLoop", true);
		gf.playAnim("idleLoop", true);

		boyfriend.playAnim("pissed", true, false, 24);

        camFollowPos.setPosition(picoPos.x + 250, picoPos.y);
	    FlxTween.tween(FlxG.camera, {zoom: 1.3}, 2, { ease: FlxEase.quadInOut });

		cutsceneManager = new CutsceneManager();
		add(cutsceneManager);

		cutsceneManager.addEvent(2, function() {
			FlxTween.tween(camFollowPos, {x: darnellPos.x + 180, y: darnellPos.y}, 2.5, { ease: FlxEase.quadInOut });
			FlxTween.tween(FlxG.camera, {zoom: 0.68}, 2.5, { ease: FlxEase.quadInOut });
		});

		cutsceneManager.addEvent(beatTime * 12, function() {
			dad.playAnim('lightCan', true);
			FlxG.sound.play(Paths.sound("Darnell_Lighter", "weekend1"));
		});

		cutsceneManager.addEvent(beatTime * 15, function() {
			boyfriend.playAnim('reload-cutscene', true);
			FlxG.sound.play(Paths.sound("Gun_Prep", "weekend1"));
			createBullet();
		});

		cutsceneManager.addEvent(beatTime * 16, function() {
			dad.playAnim('kickCan', true);
			FlxG.sound.play(Paths.sound("Kick_Can_UP", "weekend1"));
			canKickSlow();
		});

		cutsceneManager.addEvent(beatTime * 17.5, function() {
			dad.playAnim('kneeCan', true);
			FlxG.sound.play(Paths.sound("Kick_Can_FORWARD", "weekend1"));
			canKickForward();
		});

		cutsceneManager.addEvent(beatTime * 18, function() {
			boyfriend.playAnim('shoot-cutscene', true);
			FlxG.sound.play(Paths.sound("shot" + FlxG.random.int(1, 4), "weekend1"));
			FlxTween.tween(camFollowPos, {x: darnellPos.x + 100, y: darnellPos.y}, 1, { ease: FlxEase.quadInOut });
			stageDarken();
			canShot();
		});

		cutsceneManager.addEvent(beatTime * 19, function() {
			dad.playAnim('idle', true);
		});

		cutsceneManager.addEvent(beatTime * 20, function() {
			dad.playAnim('laughCutscene', true);
			FlxG.sound.play(Paths.sound("cutscene/darnell_laugh", "weekend1"));
		});

		cutsceneManager.addEvent(beatTime * 20.5, function() {
			gf.playAnim('laughCutscene', true);
			FlxG.sound.play(Paths.sound("cutscene/nene_laugh", "weekend1"));
		});

		cutsceneManager.addEvent(9, function() {
			camHUD.visible = true;
			startCountdown();

			FlxTween.tween(camFollowPos, {x: darnellPos.x, y: darnellPos.y}, 2, { ease: FlxEase.sineInOut });
			FlxTween.tween(FlxG.camera, {zoom: 0.75}, 2, { ease: FlxEase.sineInOut });
		});

		cutsceneManager.start();
	}

	public function startVideo(name:String)
	{
		#if VIDEOS
		runVideo = true;
		inCutscene = true;
		camHUD.visible = false;

		var filepath:String = Paths.video(name);
		#if sys
		if(!sys.FileSystem.exists(filepath))
		#else
		if(!Assets.exists(filepath))
		#end
		{
			Logger.log('Warn: Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		black = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		video = new FlxVideo();
		// Recent versions
		video.load(filepath);
		video.onEndReached.add(function()
		{
			video.dispose();
			videoOver = true;
			runVideo = false;
			black.visible = false;
			startAndEnd();
			return;
		}, true);
		video.play();
		#else
		Logger.log('Warn: Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		camHUD.visible = true;

		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	public var skipCountdown:Bool = false;
	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if(startedCountdown) { return; }

		if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

		inCutscene = false;
		camHUD.visible = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;

        startedCountdown = true;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		if(startOnTime < 0) startOnTime = 0;

		if (startOnTime > 0) {
			clearNotesBefore(startOnTime);
			setSongTime(startOnTime - 350);
			return;
		}
		else if (skipCountdown)
		{
			setSongTime(0);
			return;
		}

		#if sys
		callOnScripts('startCountdown', []);
        #end

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
			{
				gf.dance();
			}

			if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
			{
				boyfriend.dance();
			}

			if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
			{
			    dad.dance();
			}

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			introAssets.set('school', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);
			introAssets.set('schoolEvil', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			for (value in introAssets.keys())
			{
				if (value == curStage)
				{
					introAlts = introAssets.get(value);
					altSuffix = '-pixel';
				}
			}

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (curStage.startsWith('school'))
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.cameras = [camOther];
					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();

					if (curStage.startsWith('school'))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.cameras = [camOther];
					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();

					if (curStage.startsWith('school'))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.cameras = [camOther];
					go.updateHitbox();
					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);

		if (generatedMusic)
			notes.sort(FlxSort.byY, Config.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
	}

	public function createCharacterGlow():Void{
		FlxTween.cancelTweensOf(characterGlow);
		FlxTween.cancelTweensOf(characterGlow.scale);

		characterGlow.loadGraphicFromSprite(boyfriend);
		characterGlow.setPosition(boyfriend.x, boyfriend.y);
		characterGlow.scale.set(boyfriend.scale.x, boyfriend.scale.y);
		characterGlow.antialiasing = boyfriend.antialiasing;
		characterGlow.visible = true;
		characterGlow.alpha = 0.3;

		FlxTween.tween(characterGlow.scale, {x: characterGlow.scale.x * 1.4, y: characterGlow.scale.y * 1.4}, (Conductor.crochet / 1000), {ease: FlxEase.quadOut});
		FlxTween.tween(characterGlow, {alpha: 0}, ((Conductor.crochet / 1000) / 2), {startDelay: ((Conductor.crochet / 1000) / 2)});
	}

	public function stageDarken():Void{
		FlxTween.cancelTweensOf(dimSprite);
		dimSprite.alpha = 0.75;
		FlxTween.tween(dimSprite, {alpha: 0}, 1, {startDelay: 0.2});
	}

	public function createBullet():Void{
		var bullet = new PicoBullet(boyfriend.x + 159, boyfriend.y + 127);
		add(bullet);
	}

	public function canKick():Void{
		kickedCan.visible = true;
		kickedCan.playAnim("kickUp");
	}
	
	public function canKickSlow():Void{
		kickedCan.visible = true;
		kickedCan.playAnim("kickUpSlow");
	}

	public function canKickForward():Void{
		kickedCan.visible = true;
		kickedCan.playAnim("kickForward");
	}

	public function canHit():Void{
		kickedCan.visible = true;
		kickedCan.playAnim("hit");
	}

	public function canShot():Void{
		kickedCan.visible = true;
		kickedCan.playAnim("shot");
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
		    {
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		if(FlxG.sound.music.time != time)
			FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
		}
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		abot.setAudioSource(FlxG.sound.music);
		abot.startVisualizer();

		if (curStage == "phillyStreets")
            FlxTween.tween(rainShader, {uIntensity: rainInensityEnd}, FlxG.sound.music.length / 1000);

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			FlxG.sound.music.pause();
			vocals.pause();
		}

		#if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength);
		#end

		#if sys
		callOnScripts('songStart', []);
        #end
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var noteType:String = "";
				if (songNotes.length > 3)
				{
					noteType = songNotes[3];
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, noteType);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, noteType);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
					else if(Config.middleScroll)
					{
						swagNote.x += 310;
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(Config.middleScroll)
				{
					swagNote.x += 310;
				}
			}
			daBeats += 1;
		}

		// Logger.log(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; 

	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = Config.middleScroll ? -278 : 48;
		var strumLineY:Float = Config.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(strumLineX, strumLineY);

			switch (curStage)
			{
				case 'school' | 'schoolEvil':
					babyArrow.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);
					babyArrow.animation.add('green', [6]);
					babyArrow.animation.add('red', [7]);
					babyArrow.animation.add('blue', [5]);
					babyArrow.animation.add('purplel', [4]);

					babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.add('static', [0]);
							babyArrow.animation.add('pressed', [4, 8], 12, false);
							babyArrow.animation.add('confirm', [12, 16], 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.add('static', [1]);
							babyArrow.animation.add('pressed', [5, 9], 12, false);
							babyArrow.animation.add('confirm', [13, 17], 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.add('static', [2]);
							babyArrow.animation.add('pressed', [6, 10], 12, false);
							babyArrow.animation.add('confirm', [14, 18], 12, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.add('static', [3]);
							babyArrow.animation.add('pressed', [7, 11], 12, false);
							babyArrow.animation.add('confirm', [15, 19], 24, false);
					}

				default:
					babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrowLEFT');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					}
			}

			#if sys
		    setOnScripts("babyArrow", babyArrow);
			callOnScripts('generateStaticArrows', [player]);
			#end

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(Config.middleScroll) targetAlpha = 0;
			}

			if (!isStoryMode && !skipArrowStartTween)
			{
				var posAddition = Config.downScroll ? -50 : 50;
				babyArrow.y += posAddition;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y - posAddition, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = targetAlpha;

			babyArrow.ID = i;

			if (player == 1) {
				playerStrums.add(babyArrow);
			} else {
				if(Config.middleScroll) {
					babyArrow.x += 310;
				}
				dadStrums.add(babyArrow);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			playerStrums.forEach(function(spr:FlxSprite)
			{
				spr.centerOffsets();
			});

			dadStrums.forEach(function(spr:FlxSprite)
			{
				spr.centerOffsets();
			});

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override public function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override public function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);

			paused = false;

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	function calculateRatingPercent():Float {
		var totalNotes = songHits + songMisses;
		if (totalNotes <= 0) return -1;

		var accuracyy = songHits / totalNotes;

		if (Math.isNaN(accuracyy) || accuracyy < 0)
			return -1;

		return FlxMath.roundDecimal(accuracyy * 100, 2);
	}

	function funnyRatingText(ratingPercent:Float):String {
		var validRatings:Array<Dynamic> = [
			['Sick', 100],
			['Good', 85],
			['Bad', 65],
			['Shit', 40],
			['Bruh', 25]
		];

		if (ratingPercent != -1) {
			for (i in 0...validRatings.length) {
				if (validRatings[i + 1] != null && (ratingPercent > validRatings[i + 1][1] && ratingPercent <= validRatings[i][1]) || validRatings[i + 1] == null && ratingPercent <= validRatings[i][1]) {
					return '$ratingPercent% - ' + validRatings[i][0];
				}
			}
		}

		return 'N/A';
	}

	var crap:Float = 0;
	public static var tankmangood:Int = 0;

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

        if (!inCutscene && !paused && generatedMusic && FlxG.sound.music.playing) {
            while (songEvents.length > 0 && Conductor.songPosition >= songEvents[0].strumtime) {
                var event = songEvents[0];
                performEvent(event);
                songEvents.shift();
            }
        }

        #if VIDEOS
        if (runVideo && !videoOver && isStoryMode) {
			if (FlxG.keys.justPressed.ENTER) {
                FlxTween.tween(video, {alpha: 0, volume: 0}, 0.4, {
                    ease: FlxEase.quadInOut,
                    startDelay: 0.2,
                    type: FlxTween.ONESHOT,
                    onComplete: function(tween:FlxTween) {
                        video.dispose();
                        black.visible = false;
			    		videoOver = true;
						runVideo = false;
			    		if (SONG.song.toLowerCase() == 'darnell') {
                            darnellIntro();
                        } else {
                            startAndEnd();
                        }
			    		return;
                    }
                });
		    }
        }
        #end

		if (FlxG.keys.justPressed.NINE)
		{
			if (iconP1.animation.curAnim.name == 'bf-old')
				iconP1.animation.play(SONG.player1);
			else
				iconP1.animation.play('bf-old');
		}

		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
			case 'tank':
				moveTank();
			case 'phillyBlazin':
				if (lightningActive && !inCutscene) {
			        lightningTimer -= FlxG.elapsed;
		        }

		        if (lightningTimer <= 0){
		        	lightningStrike();
		        	lightningTimer = FlxG.random.float(7, 15);
		        }
		}

		#if sys
		callOnScripts("update", [elapsed]);
		#end

		super.update(elapsed);

		accuracy = calculateRatingPercent();

		scoreTxt.text = "Score:" + songScore + " / Misses:" + songMisses + " / Accuracy:" + funnyRatingText(accuracy);

		if (!startingSong)
		{
			if (FlxG.sound.music.playing)
			{
				if (Config.botplay)
				{
					botplayTxt.screenCenter(X);
					crap += SONG.bpm * elapsed;
					botplayTxt.alpha = 1 - Math.sin((3.14 * crap) / SONG.bpm);
				}
				else
				{
					botplayTxt.screenCenter(X);
					botplayTxt.alpha = 0;
				}
			}
		}
		else
		{
			botplayTxt.screenCenter(X);
			botplayTxt.alpha = 0;
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

		    if (curStage == "phillyBlazin" && lightningSound.playing) {
		    	unpauseSoundCheck = true;
		    	lightningSound.pause();
		    }

			#if sys
		    callOnScripts("pause", []);
			#end

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);

		    if(FlxG.sound.music != null) {
		    	FlxG.sound.music.pause();
		    	vocals.pause();
		    }

			if (goToPause)
			    openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		
			#if desktop
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new states.editors.charting.ChartingEditorState());

			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.scale.set(FlxMath.lerp(iconP1.scale.x, 1, 0.2), FlxMath.lerp(iconP1.scale.y, 1, 0.2));
		iconP2.scale.set(FlxMath.lerp(iconP2.scale.x, 1, 0.2), FlxMath.lerp(iconP2.scale.y, 1, 0.2));

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, Config.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		if (generatedMusic && PlayState.SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (camFollow.x != dad.getMidpoint().x + 150 + dad.cameraOffset[0] && !PlayState.SONG.notes[Math.floor(curStep / 16)].mustHitSection && !isCameraOnForcedPos)
			{
				camFollow.set(dad.getMidpoint().x + 150 + dad.cameraOffset[0], dad.getMidpoint().y - 100 + dad.cameraOffset[1]);

				#if sys
                callOnScripts("dadTurn", []);
				#end

				if (abotLookDir) {
				    abotLookDir = !abotLookDir;
				    abot.lookLeft();
				}

				switch (dad.curCharacter)
				{
					case 'mom':
						camFollow.y = dad.getMidpoint().y;
					case 'senpai':
						camFollow.y = dad.getMidpoint().y - 430;
						camFollow.x = dad.getMidpoint().x - 100;
					case 'senpai-angry':
						camFollow.y = dad.getMidpoint().y - 430;
						camFollow.x = dad.getMidpoint().x - 100;
				}

				if (dad.curCharacter == 'mom')
					vocals.volume = 1;

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					tweenCamIn();
				}
			}

			if (PlayState.SONG.notes[Math.floor(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100 + boyfriend.cameraOffset[0] && !isCameraOnForcedPos)
			{
				camFollow.set(boyfriend.getMidpoint().x - 100 + boyfriend.cameraOffset[0], boyfriend.getMidpoint().y - 100 + boyfriend.cameraOffset[1]);

				#if sys
                callOnScripts("bfTurn", []);
				#end

				if (!abotLookDir) {
				    abotLookDir = !abotLookDir;
				    abot.lookRight();
				}

				switch (curStage)
				{
					case 'limo':
						camFollow.x = boyfriend.getMidpoint().x - 300;
					case 'mall':
						camFollow.y = boyfriend.getMidpoint().y - 200;
					case 'school':
						camFollow.x = boyfriend.getMidpoint().x - 300;
						camFollow.y = boyfriend.getMidpoint().y - 250;
					case 'schoolEvil':
						camFollow.x = boyfriend.getMidpoint().x - 300;
						camFollow.y = boyfriend.getMidpoint().y - 250;
				}

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		if (health <= 0)
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			FlxTimer.globalManager.clear();
			FlxTween.globalManager.clear();

            if (curStage == "phillyStreets") {
				camGame.setFilters([]);
                camGame.filtersEnabled = false;
			}

			#if sys
            callOnScripts('gameOver', []);
			#end

			deathCounter += 1;

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);

			if (goToGameOver)
			    openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			
			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		var roundedSpeed:Float = FlxMath.roundDecimal(SONG.speed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if(roundedSpeed < 1) time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
				camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
				if(!Config.botplay) {
					keyShit();
				} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
				}
			}

			notes.forEachAlive(function(daNote:Note)
			{
				if (Config.botplay) {
					if(daNote.mustPress) {
					    if(daNote.isSustainNote) {
						    if(daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.ignoreNote) {
							    goodNoteHit(daNote);
						    }
					    } else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) && !daNote.ignoreNote) {
						    goodNoteHit(daNote);
					    }
					    boyfriend.holdTimer = 0;
				    }

		            playerStrums.forEach(function(spr:FlxSprite)
		            {
			            if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school'))
			            {
				            spr.centerOffsets();
				            spr.offset.x -= 13;
				            spr.offset.y -= 13;
			            }
			            else
				            spr.centerOffsets();
		            });
				}

				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				var strumX:Float = 0;
				var strumY:Float = 0;

				if(daNote.mustPress) {
					strumX = playerStrums.members[daNote.noteData].x;
					strumY = playerStrums.members[daNote.noteData].y;
				} else {
					strumX = dadStrums.members[daNote.noteData].x;
					strumY = dadStrums.members[daNote.noteData].y;
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;

				daNote.x = strumX;

				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				var center:Float = strumY + Note.swagWidth / 2;

				if (Config.downScroll) {
					daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
					if (daNote.isSustainNote) {
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
							if (curStage.startsWith('school')) {
								daNote.y += 8;
							}
						} 
						daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1) + 19;

						if(daNote.mustPress || !daNote.ignoreNote)
						{
							if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
								&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
								daNote.clipRect = swagRect;
							}
						}
					}
				} else {
					daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

					if(daNote.mustPress || !daNote.ignoreNote)
					{
						if (daNote.isSustainNote
							&& daNote.y + daNote.offset.y * daNote.scale.y <= center
							&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;
							daNote.clipRect = swagRect;
						}
					}
				}

				if (daNote.mustPress) {
					daNote.visible = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].visible;
					daNote.alpha = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].alpha;
				} else if (!daNote.wasGoodHit) {
					daNote.visible = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].visible;
					daNote.alpha = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].alpha;
				}

				var strum = daNote.mustPress ? playerStrums.members[daNote.noteData] : dadStrums.members[daNote.noteData];
				if (Config.middleScroll)
				{
					if (daNote.isSustainNote)
					{
						daNote.alpha = strum.alpha * 0.6;
					}
					else
					{
						daNote.alpha = strum.alpha;
					}
				}

                if (daNote.isSustainNote)
                	daNote.alpha = Math.min(daNote.alpha, 0.6);

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.ignoreNote)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					if (!dad.danceLockout)
					{
					    switch (Math.abs(daNote.noteData))
					    {
					    	case 0:
					    		dad.playAnim('singLEFT' + altAnim, true);
					    	case 1:
					    		dad.playAnim('singDOWN' + altAnim, true);
					    	case 2:
					    		dad.playAnim('singUP' + altAnim, true);
					    	case 3:
					    		dad.playAnim('singRIGHT' + altAnim, true);
					    }
				    }

					dadStrums.forEach(function(spr:FlxSprite)
					{
						if (Math.abs(daNote.noteData) == spr.ID)
						{
							spr.animation.play('confirm', true);
						}
						if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school'))
						{
							spr.centerOffsets();
							spr.offset.x -= 13;
							spr.offset.y -= 13;
						}
						else
							spr.centerOffsets();
					});

					if (daNote.noteType == "weekend-1-lightcan") {
						dad.playAnim('lightCan', true);
						FlxG.sound.play(Paths.sound("Darnell_Lighter", "weekend1"));
					} else if (daNote.noteType == "weekend-1-kickcan") {
						dad.playAnim('kickCan', true);
						FlxG.sound.play(Paths.sound("Kick_Can_UP", "weekend1"));
						canKick();
					} else if (daNote.noteType == "weekend-1-kneecan") {
						dad.playAnim('kneeCan', true);
						FlxG.sound.play(Paths.sound("Kick_Can_FORWARD", "weekend1"));
						canKickForward();
					}

					#if sys
					callOnScripts("dadNoteHit", [daNote]);
					#end

					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				var doKill:Bool = daNote.y < -daNote.height;
				if(Config.downScroll) doKill = daNote.y > FlxG.height;

				if (doKill)
				{
					if (daNote.mustPress && daNote.tooLate || !daNote.wasGoodHit && !daNote.ignoreNote && !endingSong && !Config.botplay)
					{
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
	    }

		if (Config.botplay) {
			playerStrums.forEach(function(spr:FlxSprite)
		    {
			    if (spr.animation.finished)
			    {
				    spr.animation.play('static');
				    spr.centerOffsets();
			    }
		    });
		}

		dadStrums.forEach(function(spr:FlxSprite)
		{
			if (spr.animation.finished)
			{
				spr.animation.play('static');
				spr.centerOffsets();
			}
		});

		if (Config.botplay) {
			botplayTxt.scale.set(FlxMath.lerp(botplayTxt.scale.x, 1, 0.2), FlxMath.lerp(botplayTxt.scale.y, 1, 0.2));
		}

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end

		#if sys
		callOnScripts("updatePost", [elapsed]);
		#end
	}

	function performEvent(event:ChartEvent) {
		switch (event.event.toLowerCase()) {
			case "bpm change":
				var newBPM = Std.parseFloat(event.variable1);
				if (!Math.isNaN(newBPM)) {
					Conductor.changeBPM(newBPM);
				}
			case "play animation":
				var animName = event.variable1;
				var target = event.variable2;
				if (animName != null && target != null) {
					switch (target.toLowerCase()) {
						case "bf": boyfriend.playAnim(animName, true);
						case "dad": dad.playAnim(animName, true);
						case "gf": gf.playAnim(animName, true);
					}
				}
			case "camera follow pos":
				var x = Std.parseFloat(event.variable1);
				var y = Std.parseFloat(event.variable2);
				if (!Math.isNaN(x) && !Math.isNaN(y)) {
					camFollowPos.setPosition(x, y);
				}
			case "change character":
				var target = event.variable1;
				var charName = event.variable2;
				if (target != null && charName != null) {
					switch (target.toLowerCase()) {
						case "bf": changeCharacter(charName, 0);
						case "dad": changeCharacter(charName, 1);
						case "gf": changeCharacter(charName, 2);
					}
				}
			case "screen shake":
				var intensity = Std.parseFloat(event.variable1);
				var duration = Std.parseFloat(event.variable2);
				if (!Math.isNaN(intensity) && !Math.isNaN(duration)) {
					camGame.shake(intensity, duration);
				}
			case "flash":
				var duration = Std.parseFloat(event.variable1);
				if (!Math.isNaN(duration)) {
					var color:FlxColor = FlxColor.WHITE;
					if (event.variable2 != null) {
						var parsedColor = FlxColor.fromString(event.variable2);
						if (parsedColor != null) {
							color = parsedColor;
						}
					}
					camGame.flash(color, duration);
				}
            case "add camera zoom":
                var zoomGame = Std.parseFloat(event.variable1);
                var zoomHUD = Std.parseFloat(event.variable2);
                if (!Math.isNaN(zoomGame)) {
                    FlxG.camera.zoom += zoomGame;
                }
                if (!Math.isNaN(zoomHUD)) {
                    camHUD.zoom += zoomHUD;
                }
			case "tween hud alpha":
				var alpha = Std.parseFloat(event.variable1);
				var duration = Std.parseFloat(event.variable2);
				if (!Math.isNaN(alpha) && !Math.isNaN(duration)) {
					FlxTween.tween(camHUD, {alpha: alpha}, duration);
				}
			case "set hud alpha":
				var alpha = Std.parseFloat(event.variable1);
				if (!Math.isNaN(alpha)) {
					camHUD.alpha = alpha;
				}
		}
		#if sys
		callOnScripts("performEvent", [event]);
		#end
	}

    public function resume() {
		if (curStage == "phillyBlazin" && unpauseSoundCheck){
			unpauseSoundCheck = false;
			lightningSound.play(false);
		}

		#if sys
		callOnScripts("resume", []);
		#end
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function endSong():Void
	{
		canPause = false;
		deathCounter = 0;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		seenCutscene = false;
		inCutscene = false;
		endingSong = true;

		if (SONG.validScore)
		{
			#if !switch
			Highscore.saveScore(SONG.song, songScore, storyDifficultyText);
			#end
		}

		#if sys
		callOnScripts('endSong', []);
		#end

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				if (goToStory)
				    FlxG.sound.playMusic(TitleState.freakyMenu);

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				if (goToStory)
				    FlxG.switchState(new StoryMenuState());

				if (SONG.validScore)
				{
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficultyText);
				}

				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				if (storyDifficultyText.toLowerCase() != "normal")
					difficulty += '-${storyDifficultyText.toLowerCase()}';

				Logger.log('LOADING NEXT SONG');
			    Logger.log(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				prevCamFollow = camFollow;
				prevCamFollowPos = camFollowPos;

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				if (goToGame)
				    LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else
		{
			Logger.log('WENT BACK TO FREEPLAY??');
			if (goToFreeplay)
			    FlxG.switchState(new FreeplayState());
		}
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		var cPosX:Float;
		var cPosY:Float;

		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					cPosX = boyfriend.x - boyfriend.characterOffset[0];
					cPosY = boyfriend.y - boyfriend.characterOffset[1];
					var newBoyfriend:Boyfriend = new Boyfriend(cPosX, cPosY, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					newBoyfriend.alpha = 0.0001;
					newBoyfriend.active = false;
					newBoyfriend.x += newBoyfriend.characterOffset[0];
					newBoyfriend.y += newBoyfriend.characterOffset[1];
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					cPosX = dad.x - dad.characterOffset[0];
					cPosY = dad.y - dad.characterOffset[1];
					var newDad:Character = new Character(cPosX, cPosY, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					newDad.alpha = 0.0001;
					newDad.active = false;
					newDad.x += newDad.characterOffset[0];
					newDad.y += newDad.characterOffset[1];
				}

			case 2:
				if(!gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(gf.x, gf.y, newCharacter, false);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					newGf.alpha = 0.0001;
					newGf.active = false;
				}
		}
	}

	public function changeCharacter(charName:String, charType:Int, ?delBef:Bool = false)
	{
		if (charType < 0)
			charType = 0;

		if (charType > 2)
			charType = 2;
		
		switch(charType) {
			case 0:
				if(boyfriend.curCharacter != charName) {
					if(!boyfriendMap.exists(charName)) {
						addCharacterToList(charName, charType);
					}
					var lastAlpha:Float = boyfriend.alpha;
					boyfriend.alpha = 0;
					boyfriend = boyfriendMap.get(charName);
					boyfriend.alpha = lastAlpha;
					boyfriend.active = true;
					iconP1.changeIcon(boyfriend.healthIcon);
				}
			case 1:
				if(dad.curCharacter != charName) {
					if(!dadMap.exists(charName)) {
						addCharacterToList(charName, charType);
					}
					var lastAlpha:Float = dad.alpha;
					dad.alpha = 0;
					dad = dadMap.get(charName);
					dad.alpha = lastAlpha;
					dad.active = true;
					iconP2.changeIcon(dad.healthIcon);
				}
			case 2:
				if(gf.curCharacter != charName) {
					if(!gfMap.exists(charName)) {
						addCharacterToList(charName, charType);
					}
					var lastAlpha:Float = gf.alpha;
					gf.alpha = 0;
					gf = gfMap.get(charName);
					gf.alpha = lastAlpha;
					gf.active = true;
				}
		}
	}

	public function removeCharacterFromList(charName:String, charType:Int)
	{
		if (charType < 0)
			charType = 0;

		if (charType > 2)
			charType = 2;

		var chId:Character;
		var bfId:Boyfriend;

		switch (charType)
		{
			case 0:
				if(boyfriendMap.exists(charName)) {
					bfId = boyfriendMap.get(charName);
					boyfriendMap.remove(charName);
					bfId.destroy();
				}
			case 1:
				if(dadMap.exists(charName)) {
					chId = dadMap.get(charName);
					dadMap.remove(charName);
					chId.destroy();
				}
			case 2:
				if(gfMap.exists(charName)) {
					chId = gfMap.get(charName);
					gfMap.remove(charName);
					chId.destroy();
				}
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(strumtime:Float, note:Note):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			score = 100;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
		{
			daRating = 'good';
			score = 200;
		}

		if (daRating == 'sick' && Config.noteSplashes) {
			createNoteSplash(note.noteData);
		}

		#if sys
		setOnScripts("daRating", daRating);
        callOnScripts("popUpScore", [strumtime, note]);
		#end

		songScore += score;

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (curStage.startsWith('school'))
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(rating);

		if (!curStage.startsWith('school'))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));

			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (!curStage.startsWith('school'))
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			Logger.log(combo);
			Logger.log(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function createNoteSplash(note:Int){
		bigSplashy = new NoteSplash(playerStrums.members[note].x, playerStrums.members[note].y, note);
		bigSplashy.cameras = [camHUD];
		add(bigSplashy);

		#if sys
		callOnScripts('createNoteSplash', [note]);
		#end
	}

	public function keyShit():Void {
		var holdingArray:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		var controlArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];

		if (holdingArray.contains(true) && generatedMusic) {
			notes.forEachAlive(function(daNote:Note) {
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdingArray[daNote.noteData])
					goodNoteHit(daNote);
			});
		}

		if (controlArray.contains(true) && generatedMusic) {
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = [];
			var ignoreList:Array<Int> = [];
			var removeList:Array<Note> = [];

			notes.forEachAlive(function(daNote:Note) {
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					if (ignoreList.contains(daNote.noteData)) {
						for (possibleNote in possibleNotes) {
							if (possibleNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - possibleNote.strumTime) < 10) {
								removeList.push(daNote);
							} else if (possibleNote.noteData == daNote.noteData && daNote.strumTime < possibleNote.strumTime) {
								possibleNotes.remove(possibleNote);
								possibleNotes.push(daNote);
							}
						}
					} else {
						possibleNotes.push(daNote);
						ignoreList.push(daNote.noteData);
					}
				}
			});

			for (badNote in removeList) {
				badNote.kill();
				notes.remove(badNote, true);
				badNote.destroy();
			}

			possibleNotes.sort(function(note1:Note, note2:Note) {
				return Std.int(note1.strumTime - note2.strumTime);
			});

			if (perfectMode) {
				goodNoteHit(possibleNotes[0]);
			} else if (possibleNotes.length > 0) {
				for (i in 0...controlArray.length) {
					if (controlArray[i] && !ignoreList.contains(i)) {
			            notes.forEachAlive(function(daNote:Note) {
				            badNoteHit(daNote, controlArray);
			            });
					}
				}
				for (possibleNote in possibleNotes) {
					if (controlArray[possibleNote.noteData]) {
						goodNoteHit(possibleNote);
					}
				}
			} else
			    notes.forEachAlive(function(daNote:Note) {
				    badNoteHit(daNote, controlArray);
			    });
		}

		if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
			&& !holdingArray.contains(true)
			&& boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss')) {
			boyfriend.dance();
		}

		playerStrums.forEach(function(spr:FlxSprite) {
			if (controlArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.animation.play('pressed');
			if (!holdingArray[spr.ID])
				spr.animation.play('static');

			if (!curStage.startsWith('school')) {
				spr.centerOrigin();

				spr.offset.x = spr.frameWidth / 2;
				spr.offset.y = spr.frameHeight / 2;

				spr.offset.x -= 156 * spr.scale.x / 2;
				spr.offset.y -= 156 * spr.scale.y / 2;
			} else
				spr.centerOffsets();
		});
	}

	public var resetMissHealth = false;

	function noteMiss(note:Note):Void
	{
		if (!boyfriend.stunned && !Config.botplay && !note.ignoreNote)
		{
			if (!resetMissHealth)
			    health -= 0.04;

			if (combo > 5 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;
			songScore -= 10;
			songMisses++;
			totalPlayed++;

			vocals.volume = 0;

            if (note.noteType == "weekend-1-firegun") {
                resetMissHealth = true;

				boyfriend.playAnim('shootMISS', true);
				FlxG.sound.play(Paths.sound("Pico_Bonk", "weekend1"));
				canHit();

				FlxTween.tween(this, {defaultCamZoom: 0.85}, (Conductor.crochet/1000) * 2, {
					ease: FlxEase.expoOut,
					onComplete: function(tween:FlxTween) {
                        defaultCamZoom = 0.75;
					}
				});

				// FlxTween.tween(camFollowPos, {
				// 	x: boyfriend.getMidpoint().x - 100 + boyfriend.cameraOffset[0],
				// 	y: boyfriend.getMidpoint().y - 100 + boyfriend.cameraOffset[1]
				// }, 1.9);

				health -= 0.5;
			}

			#if sys
			callOnScripts("noteMiss", [note]);
			#end

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			boyfriend.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});

			switch (note.noteData)
			{
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
			}
		}
	}

	function badNoteHit(note:Note, controlArray:Array<Bool>) {
		if (!note.missed && !Config.ghostTapping) {
		    note.missed = true;

			if (note.sustainChildren.length > 0) {
				for (i in note.sustainChildren) {
					note.missed = true;
				}
			}

		    for (i in 0...controlArray.length) {
			    if (controlArray[i])
				    noteMiss(note);
		    }
		}
	}

	public var resetGoodNoteHitHealth = false;

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			#if sys
			callOnScripts("goodNoteHit", [note]);
			#end

            if (note.noteType == "weekend-1-cockgun") {
				boyfriend.danceLockout = true;
				boyfriend.playAnim('cock', true);
				FlxG.sound.play(Paths.sound("Gun_Prep", "weekend1"));
                createCharacterGlow();
				createBullet();
			} else if (note.noteType == "weekend-1-firegun") {
				boyfriend.playAnim('shoot', true);
				boyfriend.danceLockout = true;
				finishedShooting = false;

				Logger.log("SHOOT ANIM STARTED");

				if (boyfriend.animation.curAnim.name == "shoot" && boyfriend.animation.curAnim != null)
				{
					boyfriend.animation.finishCallback = function(name)
					{
						if (!finishedShooting)
						{
							Logger.log("SHOOT FINISHED");
							finishedShooting = true;
							boyfriend.danceLockout = false;
							boyfriend.dance();
						}
					};
				}

				FlxG.sound.play(Paths.soundRandom("shot", 1, 4, "weekend1"));
				stageDarken();
				canShot();

				// FlxTween.tween(camFollowPos, {
				// 	x: boyfriend.getMidpoint().x - 100 + boyfriend.cameraOffset[0],
				// 	y: boyfriend.getMidpoint().y - 100 + boyfriend.cameraOffset[1]
				// }, 1.9);

				FlxTween.tween(this, {defaultCamZoom: 0.85}, (Conductor.crochet/1000) * 2, {
					ease: FlxEase.expoOut,
					onComplete: function(tween:FlxTween) {
                        defaultCamZoom = 0.75;
					}
				});
			}

			if(note.ignoreNote) return;

			if (!note.isSustainNote)
			{
				popUpScore(note.strumTime, note);
				songHits++;
                totalPlayed++;
				combo += 1;
			}

			if (!resetGoodNoteHitHealth) {
			    if (note.noteData >= 0)
			    	health += 0.023;
			    else
			    	health += 0.004;
		    }

			if (!boyfriend.danceLockout)
			{
			    switch (note.noteData)
			    {
			    	case 0:
			    		boyfriend.playAnim('singLEFT', true);
			    	case 1:
			    		boyfriend.playAnim('singDOWN', true);
			    	case 2:
			    		boyfriend.playAnim('singUP', true);
			    	case 3:
			    		boyfriend.playAnim('singRIGHT', true);
			    }
		    }

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
				    spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	function moveTank():Void
	{
		if (!inCutscene)
		{
			var daAngleOffset:Float = 1;
			tankAngle += FlxG.elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;

			tankGround.x = tankX + Math.cos(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1500;
			tankGround.y = 1300 + Math.sin(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1100;
		}
	}

	var tankResetShit:Bool = false;
	var tankMoving:Bool = false;
	var tankAngle:Float = FlxG.random.int(-90, 45);
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankX:Float = 400;

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	function changeLights(beat:Int):Void{

		lastChange = beat;
		lightsStop = !lightsStop;

		if(lightsStop){
			phillyTraffic.animation.play('tored');
			changeInterval = 20;
		} else {
			phillyTraffic.animation.play('togreen');
			changeInterval = 30;

			if(carWaiting == true) finishCarLights(phillyCars);
		}
	}

	function resetCar(left:Bool, right:Bool){
		if(left){
			carWaiting = false;
			carInterruptable = true;
			if (phillyCars != null) {
				FlxTween.cancelTweensOf(phillyCars);
				phillyCars.x = 1200;
				phillyCars.y = 818;
				phillyCars.angle = 0;
			}
		}

		if(right){
			car2Interruptable = true;
			if (phillyCarsBack != null) {
				FlxTween.cancelTweensOf(phillyCarsBack);
				phillyCarsBack.x = 1200;
				phillyCarsBack.y = 818;
				phillyCarsBack.angle = 0;
			}
		}
	}

	function finishCarLights(sprite:FlxSprite):Void{
		carWaiting = false;
		var duration:Float = FlxG.random.float(1.8, 3);
		var rotations:Array<Int> = [-5, 18];
		var offset:Array<Float> = [306.6, 168.3];
		var startdelay:Float = FlxG.random.float(0.2, 1.2);

		var path:Array<FlxPoint> = [
			FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15),
			FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
			FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 40)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.sineIn, startDelay: startdelay} );
		FlxTween.quadPath(sprite, path, duration, true,
		{
			ease: FlxEase.sineIn,
			startDelay: startdelay,
			onComplete: function(_) {
				carInterruptable = true;
			}
		});
	}

	function driveCarLights(sprite:FlxSprite):Void{
		carInterruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1,4);
		sprite.animation.play('car' + variant);
		var extraOffset = [0, 0];
		var duration:Float = 2;

		switch(variant){
			case 1:
				duration = FlxG.random.float(1, 1.7);
			case 2:
				extraOffset = [20, -15];
				duration = FlxG.random.float(0.9, 1.5);
			case 3:
				extraOffset = [30, 50];
				duration = FlxG.random.float(1.5, 2.5);
			case 4:
				extraOffset = [10, 60];
				duration = FlxG.random.float(1.5, 2.5);
		}
		
		var rotations:Array<Int> = [-7, -5];
		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);

		var path:Array<FlxPoint> = [
			FlxPoint.get(1500 - offset[0] - 20, 1049 - offset[1] - 20),
			FlxPoint.get(1770 - offset[0] - 80, 994 - offset[1] + 10),
			FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.cubeOut} );
		FlxTween.quadPath(sprite, path, duration, true,
		{
			ease: FlxEase.cubeOut,
			onComplete: function(_) {
				carWaiting = true;
				if(lightsStop == false) finishCarLights(phillyCars);
			}
		});
	}

	function driveCar(sprite:FlxSprite):Void{
		carInterruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1,4);
		sprite.animation.play('car' + variant);

		var extraOffset = [0, 0];
		var duration:Float = 2;

		switch(variant){
			case 1:
				duration = FlxG.random.float(1, 1.7);
			case 2:
				extraOffset = [20, -15];
				duration = FlxG.random.float(0.6, 1.2);
			case 3:
				extraOffset = [30, 50];
				duration = FlxG.random.float(1.5, 2.5);
			case 4:
				extraOffset = [10, 60];
				duration = FlxG.random.float(1.5, 2.5);
		}

		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);

		var rotations:Array<Int> = [-8, 18];

		var path:Array<FlxPoint> = [
			FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 30),
			FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
			FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 40)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, null);
		FlxTween.quadPath(sprite, path, duration, true,
		{
			ease: null,
			onComplete: function(_) {
				carInterruptable = true;
			}
		});
	}

	function driveCarBack(sprite:FlxSprite):Void{
		car2Interruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1,4);
		sprite.animation.play('car' + variant);

		var extraOffset = [0, 0];
		var duration:Float = 2;

		switch(variant){
			case 1:
				duration = FlxG.random.float(1, 1.7);
			case 2:
				extraOffset = [20, -15];
				duration = FlxG.random.float(0.6, 1.2);
			case 3:
				extraOffset = [30, 50];
				duration = FlxG.random.float(1.5, 2.5);
			case 4:
				extraOffset = [10, 60];
				duration = FlxG.random.float(1.5, 2.5);
		}

		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);

		var rotations:Array<Int> = [18, -8];

		var path:Array<FlxPoint> = [
			FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 60),
			FlxPoint.get(2400 - offset[0], 980 - offset[1] - 30),
			FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 10)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, null);
		FlxTween.quadPath(sprite, path, duration, true,
		{
			ease: null,
			onComplete: function(_) {
				car2Interruptable = true;
			}
		});
	}

	var LIGHTNING_FULL_DURATION = 1.5;
	var LIGHTNING_FADE_DURATION = 0.3;
	var LIGHTNING_HOLD_DURATION = 0.15;
	var CHARACTER_DARKEN_COLOR = 0xFF404040;

	function lightningStrike(?tag:String):Void{
		scrollingSkyAdd.visible = true;
		scrollingSkyAdd.alpha = 0.8;
		FlxTween.tween(scrollingSkyAdd, {alpha: 0.0}, LIGHTNING_FULL_DURATION, {startDelay: LIGHTNING_HOLD_DURATION, onComplete: cleanupLightning});

		streetBlurMultiply.visible = true;
		streetBlurMultiply.alpha = 0.8;
		FlxTween.tween(streetBlurMultiply, {alpha: 0.0}, LIGHTNING_FULL_DURATION, {startDelay: LIGHTNING_HOLD_DURATION});

		additionalLighten.visible = true;
		additionalLighten.alpha = 0.5;
		FlxTween.tween(additionalLighten, {alpha: 0.0}, LIGHTNING_FADE_DURATION, {startDelay: LIGHTNING_HOLD_DURATION});

		lightning.visible = true;
		lightning.animation.play('strike');

		if(FlxG.random.bool(65)){
			lightning.x = FlxG.random.int(-250, 280);
		}else{
			lightning.x = FlxG.random.int(780, 900);
		}

		boyfriend.color = CHARACTER_DARKEN_COLOR;
		dad.color = CHARACTER_DARKEN_COLOR;
		gf.color = CHARACTER_DARKEN_COLOR;

		FlxTween.color(boyfriend, LIGHTNING_FADE_DURATION, CHARACTER_DARKEN_COLOR, 0xFFDEDEDE, {startDelay: LIGHTNING_HOLD_DURATION});
		FlxTween.color(dad, LIGHTNING_FADE_DURATION, CHARACTER_DARKEN_COLOR, 0xFFDEDEDE, {startDelay: LIGHTNING_HOLD_DURATION});
		FlxTween.color(gf, LIGHTNING_FADE_DURATION, CHARACTER_DARKEN_COLOR, 0xFF888888, {startDelay: LIGHTNING_HOLD_DURATION});

		lightningSound = FlxG.sound.play(Paths.sound("Lightning" + FlxG.random.int(1, 3), "weekend1"));
	}

	function cleanupLightning(tween:FlxTween) {
		scrollingSkyAdd.visible = false;
		streetBlurMultiply.visible = false;
		additionalLighten.visible = false;
		lightning.visible = false;
	}

	function slowRain(tag:String):Void{
		FlxTween.tween(rainShader, {timeScale: 0.07}, 2.5, {ease: FlxEase.quadOut});
	}

	function normalRain(tag:String):Void{
		FlxTween.tween(rainShader, {timeScale: 1}, Conductor.crochet/1000, {ease: FlxEase.quadIn});
	}

	function toggleLightning(tag:String):Void{
		lightningActive = !lightningActive;
	}

    override function destroy():Void {
		#if sys
		callOnScripts("destroy", []);
		#end
        super.destroy();
	}

	override function stepHit()
	{
		super.stepHit();

		#if sys
		callOnScripts("stepHit", [curStep]);
		#end

		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

        if (SONG.song.toLowerCase() == "2hot") {
			var pozShit:FlxPoint = new FlxPoint(FlxMath.lerp(dad.getMidpoint().x + 150 + dad.cameraOffset[0], boyfriend.getMidpoint().x - 100 + boyfriend.cameraOffset[0], 0.5),
			    FlxMath.lerp(dad.getMidpoint().y - 100 + dad.cameraOffset[1], boyfriend.getMidpoint().y - 100 + boyfriend.cameraOffset[1], 0.5));

			if (curStep == 115 || curStep == 499 || curStep == 627 || curStep == 979 || curStep == 1043 || curStep == 1427) {
				FlxTween.tween(camFollowPos, {x: pozShit.x, y: pozShit.y - 100}, 1.9, { ease: FlxEase.expoOut });
			} else if (curStep == 116 || curStep == 500 || curStep == 628 || curStep == 980 || curStep == 1044 || curStep == 1428) {
				FlxTween.tween(this, {defaultCamZoom: 0.68}, (Conductor.crochet/1000) * 2, { ease: FlxEase.quadInOut });
			// } else if (curStep == 130 || curStep == 514 || curStep == 642 || curStep == 994 || curStep == 1058 || curStep == 1442) {
			// 	FlxTween.tween(this, {defaultCamZoom: 0.75}, 1.9, { ease: FlxEase.expoOut });
			}
		}

		if (dad.curCharacter == 'tankman' && SONG.song.toLowerCase() == 'ugh')
		{
			if (curStep == 59 || curStep == 443 || curStep == 523 || curStep == 827)
			{
				dad.addOffset("singUP", -15, -8);
				dad.animation.getByName('singUP').frames = dad.animation.getByName('singUP-alt').frames;
			}
			if (curStep == 64 || curStep == 448 || curStep == 528 || curStep == 832)
			{
				dad.addOffset("singUP", 48, 54);
				dad.animation.getByName('singUP').frames = dad.animation.getByName('singUP-2').frames;
			}
		}

		if (dad.curCharacter == 'tankman' && curStep > 734 && SONG.song.toLowerCase() == 'stress')
		{
			if (curStep == 735)
				tankmangood = 1;
			if (curStep == 763)
				tankmangood = 0;
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		#if sys
		callOnScripts("beatHit", [curBeat]);
		#end

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
		}
		// FlxG.log.add('change bpm' + SONG.notes[Math.floor(curStep / 16)].changeBPM);
		wiggleShit.update(Conductor.crochet);

		// HARDCODING FOR MILF ZOOMS!
		if (Config.camZooms && curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (Config.camZooms && camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}



		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		if (Config.botplay) {
			botplayTxt.scale.set(1.2, 1.2);
		}

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned && !gf.danceLockout)
		{
			gf.dance();
		}

		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned && !boyfriend.danceLockout)
		{
			boyfriend.dance();
		}

		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned && !dad.danceLockout)
		{
			dad.dance();
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}

		abot.bop();

		if (gf != null && gfVersion == "nene" && SONG.song.toLowerCase() != "blazin")
		{
			var animName = gf.animation.curAnim != null ? gf.animation.curAnim.name : "";
		
			if (health < 0.4)
			{
				if (!gf.knifeRaised)
				{
					gf.knifeRaised = true;
					gf.finishedLowering = false;
					gf.danceLockout = true;
					gf.blinkTime = FlxG.random.float(gf.BLINK_MIN, gf.BLINK_MAX);
					gf.playAnim("raiseKnife", true);
				}

				else if (gf.knifeRaised && animName == "raiseKnife" && gf.animation.curAnim.finished)
				{
					gf.playAnim("idleKnife", true);
				}
			}
			else if (health >= 0.4)
			{
				if (gf.knifeRaised && (animName == "idleKnife" || animName == "sad"))
				{
					gf.playAnim("lowerKnife", true);
					gf.knifeRaised = false;
					gf.finishedLowering = false;
					gf.danceLockout = true;
				}
				else if (animName == "lowerKnife" && gf.animation.curAnim.finished)
				{
					gf.finishedLowering = true;
					gf.danceLockout = false;
					gf.dance();
				}
			}

			if (gf.finishedLowering)
			{
				gf.finishedLowering = false;
				gf.danceLockout = false;
			}
		}

		foregroundSprites.forEach(function(spr:BGSprite)
		{
			spr.dance();
		});

		switch (curStage)
		{
			case 'school':
				bgGirls.dance();

			case 'mall':
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);

			case 'limo':
				grpLimoDancers.forEach(function(dancer:BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
			case 'tank':
				tankWatchtower.dance();
			case "phillyStreets":
				if (FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && carInterruptable == true){
					if(lightsStop == false){
						driveCar(phillyCars);
					}
					else{
						driveCarLights(phillyCars);
					}
				}

				if(FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && car2Interruptable == true && lightsStop == false) driveCarBack(phillyCarsBack);

				if (curBeat == (lastChange + changeInterval)) changeLights(curBeat);
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
	}

	var curLight:Int = 0;
}
