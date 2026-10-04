package states.editors.character;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import game.Character.CharJson;
import game.Character.AnimStuff;
import lime.system.Clipboard;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import openfl.utils.Assets;

using StringTools;

class CharacterEditorState extends MusicBeatState {
	var char:Character;
	var uiBox:FlxUITabMenu;

	var camFollow:FlxObject;
	var camFolPoint:FlxSprite;
	var characterToAdd:String = 'bf';
	var charList:Array<String> = [];

	var curAnim:Int = 0;
	var isDad:Bool = true;
	var charFile:CharJson;
	var healthIcon:HealthIcon;
	var ghostAnim:FlxSprite;

	var textAnim:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var charLayer:FlxTypedGroup<Character>;

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	private var stageBg:FlxSprite;
	private var stageFront:FlxSprite;
	private var stageCurtains:FlxSprite;

	override public function create() {
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.mouse.visible = true;

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		stageBg = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback', 'shared'));
		stageBg.antialiasing = true;
		stageBg.scrollFactor.set(0.9, 0.9);
		stageBg.active = false;
		add(stageBg);

		stageFront = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront', 'shared'));
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.antialiasing = true;
		stageFront.scrollFactor.set(0.9, 0.9);
		stageFront.active = false;
		add(stageFront);

		stageCurtains = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains', 'shared'));
		stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		stageCurtains.updateHitbox();
		stageCurtains.antialiasing = true;
		stageCurtains.scrollFactor.set(1.3, 1.3);
		stageCurtains.active = false;
		add(stageCurtains);

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.camera.follow(camFollow);

		dumbTexts = new FlxTypedGroup<FlxText>();
		dumbTexts.cameras = [camHUD];
		add(dumbTexts);

		textAnim = new FlxText(300, 16);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);

		ghostAnim = new FlxSprite();
		ghostAnim.visible = false;
		ghostAnim.alpha = 0.5;
		add(ghostAnim);

		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);

		createCameraPointer();

		loadChar();
		loadCharDropDown();

		healthIcon = new HealthIcon(charFile.healthIcon, false);
		healthIcon.y = FlxG.height - 150;
		healthIcon.cameras = [camHUD];
		add(healthIcon);

		addUIBox();
		addCharacterUI();
		addAnimationsUI();
		reloadCharacterOptions();

		super.create();
	}

	function addUIBox() {
		var tabs = [
			{name: "Character", label: 'Character'},
			{name: "Animations", label: 'Animations'}
		];
		uiBox = new FlxUITabMenu(null, tabs, true);
		uiBox.resize(400, 200);
		uiBox.x = FlxG.width - uiBox.width - 20;
		uiBox.y = 20;
		uiBox.cameras = [camHUD];
		uiBox.scrollFactor.set();
		add(uiBox);
	}

	var characterDropDown:FlxUIDropDownMenu;
	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;
	var check_usingAntialiasing:FlxUICheckBox;
	var check_flipX:FlxUICheckBox;
	var stepper_charXPos:FlxUINumericStepper;
	var stepper_charYPos:FlxUINumericStepper;
	var stepper_camXPos:FlxUINumericStepper;
	var stepper_camYPos:FlxUINumericStepper;
	var stepper_scale:FlxUINumericStepper;
	var stepper_singTime:FlxUINumericStepper;

	function addCharacterUI() {
		var tab_group = new FlxUI(null, uiBox);
		tab_group.name = "Character";

		characterDropDown = new FlxUIDropDownMenu(15, 30, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String) {
			characterToAdd = charList[Std.parseInt(character)];
			loadChar();
			loadCharDropDown();
		});
		characterDropDown.selectedLabel = characterToAdd;
		var cspText:FlxText = new FlxText(characterDropDown.x, characterDropDown.y - 15, FlxG.width, "Character Lists", 8);

		var check_player = new FlxUICheckBox(275, 30, null, null, "FlipX Character", 100);
		check_player.checked = characterToAdd.startsWith('bf');
		check_player.callback = function() {
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;
			updateCamPointPos();
		};

		imageInputText = new FlxUIInputText(15, characterDropDown.y + 40, 200, charFile.spritePath, 8);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Sprite", function() {
			char.imageFile = imageInputText.text;
			reloadCharacterImage();
			if (char.animation.curAnim != null) {
				char.playAnim(char.animation.curAnim.name, true);
			}
		});

		healthIconInputText = new FlxUIInputText(160, 35, 75, charFile.healthIcon, 8);

		check_usingAntialiasing = new FlxUICheckBox(15, 100, null, null, "Antialiasing", 70);
		check_usingAntialiasing.checked = charFile.antialiasing;
		check_usingAntialiasing.callback = function() {
			charFile.antialiasing = check_usingAntialiasing.checked;
			char.antialiasing = charFile.antialiasing;
		};

		check_flipX = new FlxUICheckBox(110, 100, null, null, "Flip X", 40);
		check_flipX.checked = charFile.flipX;
		check_flipX.callback = function() {
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if (char.isPlayer)
				char.flipX = !char.flipX;
		};

		stepper_singTime = new FlxUINumericStepper(175, 105, 0.1, 4, 0.1, 20, 1);
		stepper_singTime.value = charFile.singDuration;
		stepper_singTime.name = "step_singTime";

		stepper_charXPos = new FlxUINumericStepper(250, 120, 10, 0, -5000, 5000, 1);
		stepper_charXPos.value = charFile.characterOffset[0];
		stepper_charXPos.name = "step_cXPos";

		stepper_charYPos = new FlxUINumericStepper(320, 120, 10, 0, -5000, 5000, 1);
		stepper_charYPos.value = charFile.characterOffset[1];
		stepper_charYPos.name = "step_cYPos";

		stepper_camXPos = new FlxUINumericStepper(250, 155, 10, 0, -5000, 5000, 1);
		stepper_camXPos.value = charFile.cameraOffset[0];
		stepper_camXPos.name = "step_cmXPos";

		stepper_camYPos = new FlxUINumericStepper(320, 155, 10, 0, -5000, 5000, 1);
		stepper_camYPos.value = charFile.cameraOffset[1];
		stepper_camYPos.name = "step_cmYPos";

		stepper_scale = new FlxUINumericStepper(320, imageInputText.y, 0.1, 1, 0.1, 20, 1);
		stepper_scale.value = charFile.scale;
		stepper_scale.name = "step_charScale";

		var saveCharacterJsonButton:FlxButton = new FlxButton(15, 140, "Save as JSON", function() {
			saveCharacter("json");
		});

		var saveCharacterTxtButton:FlxButton = new FlxButton(120, 140, "Save as TXT", function() {
			saveCharacter("txt");
		});

		tab_group.add(check_player);

		tab_group.add(new FlxText(15, imageInputText.y - 15, FlxG.width, 'Sprite file name:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);

		tab_group.add(new FlxText(155, healthIconInputText.y - 15, FlxG.width, 'Health icon name:'));
		tab_group.add(healthIconInputText);

		tab_group.add(check_usingAntialiasing);
		tab_group.add(check_flipX);

		tab_group.add(new FlxText(stepper_singTime.x - 10, stepper_singTime.y - 15, FlxG.width, "Sing Hold Time", 8));
		tab_group.add(stepper_singTime);

		tab_group.add(new FlxText(stepper_charXPos.x, stepper_charXPos.y - 15, FlxG.width, "Character Position (X, Y)", 8));
		tab_group.add(stepper_charXPos);
		tab_group.add(stepper_charYPos);

		tab_group.add(new FlxText(stepper_camXPos.x, stepper_camXPos.y - 15, FlxG.width, "Camera Position (X, Y)", 8));
		tab_group.add(stepper_camXPos);
		tab_group.add(stepper_camYPos);

		tab_group.add(new FlxText(stepper_scale.x - 10, stepper_scale.y - 15, FlxG.width, "Character Scale", 8));
		tab_group.add(stepper_scale);

		tab_group.add(saveCharacterJsonButton);
		tab_group.add(saveCharacterTxtButton);

		tab_group.add(cspText);
		tab_group.add(characterDropDown);

		uiBox.addGroup(tab_group);
		uiBox.scrollFactor.set();
	}

	var animationDropDown:FlxUIDropDownMenu;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;

	function addAnimationsUI() {
		var tab_group = new FlxUI(null, uiBox);
		tab_group.name = "Animations";

		animationInputText = new FlxUIInputText(15, 85, 200, '', 8);
		animationInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 30, 200, '', 8);
		animationNameInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 30, 200, '', 8);
		animationIndicesInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 150, 35, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 150, 60, null, null, "Should it Loop?", 100);

		animationDropDown = new FlxUIDropDownMenu(15, 30, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			var anim:AnimStuff = char.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationNameFramerate.value = anim.fps;
			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		var ghostCreate:FlxButton;
		var ghostDelete:FlxButton;

		ghostCreate = new FlxButton(275, 30, "Create Ghost", function() {
			ghostAnim.setPosition(char.x, char.y);
			ghostAnim.visible = true;
			ghostAnim.revive();
			ghostAnim.loadGraphic(char.graphic);
			ghostAnim.frames.frames = char.frames.frames;
			ghostAnim.animation.copyFrom(char.animation);
			ghostAnim.animation.play(char.animation.curAnim.name, true, false, char.animation.curAnim.curFrame);
			ghostAnim.offset.copyFrom(char.offset);
			ghostAnim.scale.copyFrom(char.scale);
			ghostAnim.flipX = char.flipX;
			ghostAnim.animation.pause();
		});

		ghostDelete = new FlxButton(275, 60, "Delete Ghost", function() {
			ghostAnim.kill();
			ghostAnim.visible = false;
		});

		var addUpdateButton:FlxButton = new FlxButton(275, animationInputText.y + 15, "Add/Update", function() {
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if (indicesStr.length > 1) {
				for (i in 0...indicesStr.length) {
					var index:Int = Std.parseInt(indicesStr[i]);
					if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1) {
						indices.push(index);
					}
				}
			}

			var lastAnim:String = '';
			if (char.animationsArray[curAnim] != null) {
				lastAnim = char.animationsArray[curAnim].anim;
			}

			var lastOffsets:Array<Int> = [0, 0];
			for (anim in char.animationsArray) {
				if (animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if (char.animation.getByName(animationInputText.text) != null) {
						char.animation.remove(animationInputText.text);
					}
					char.animationsArray.remove(anim);
				}
			}

			var newAnim:AnimStuff = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationNameFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets
			};

			if (indices != null && indices.length > 0) {
				char.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);
			} else {
				char.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
			}

			if (!char.animOffsets.exists(newAnim.anim)) {
				char.addOffset(newAnim.anim, 0, 0);
			}
			char.animationsArray.push(newAnim);

			if (lastAnim == animationInputText.text) {
				var leAnim:FlxAnimation = char.animation.getByName(lastAnim);
				if (leAnim != null && leAnim.frames.length > 0) {
					char.playAnim(lastAnim, true);
				} else {
					for (i in 0...char.animationsArray.length) {
						if (char.animationsArray[i] != null) {
							leAnim = char.animation.getByName(char.animationsArray[i].anim);
							if (leAnim != null && leAnim.frames.length > 0) {
								char.playAnim(char.animationsArray[i].anim, true);
								curAnim = i;
								break;
							}
						}
					}
				}
			}

			reloadAnimationDropDown();
			genBoyOffsets();

			Logger.log('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:FlxButton = new FlxButton(275, animationNameInputText.y + 15, "Remove", function() {
			for (anim in char.animationsArray) {
				if (animationInputText.text == anim.anim) {
					var resetAnim:Bool = false;
					if (char.animation.curAnim != null && anim.anim == char.animation.curAnim.name)
						resetAnim = true;

					if (char.animation.getByName(anim.anim) != null) {
						char.animation.remove(anim.anim);
					}
					if (char.animOffsets.exists(anim.anim)) {
						char.animOffsets.remove(anim.anim);
					}
					char.animationsArray.remove(anim);

					if (resetAnim && char.animationsArray.length > 0) {
						char.playAnim(char.animationsArray[0].anim, true);
					}
					reloadAnimationDropDown();
					genBoyOffsets();

					Logger.log('Removed animation: ' + animationInputText.text);
					break;
				}
			}
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 15, FlxG.width, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 15, FlxG.width, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 15, FlxG.width, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 15, FlxG.width, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 15, FlxG.width, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(ghostCreate);
		tab_group.add(ghostDelete);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);

		uiBox.addGroup(tab_group);
		uiBox.scrollFactor.set();
	}

	function reloadAnimationDropDown() {
		var anims:Array<String> = [];
		for (anim in char.animationsArray) {
			anims.push(anim.anim);
		}
		if (anims.length < 1)
			anims.push('NO ANIMATIONS');
		animationDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(anims, true));
	}

	function reloadCharacterOptions() {
		if (uiBox != null) {
			imageInputText.text = charFile.spritePath;
			healthIconInputText.text = charFile.healthIcon;
			healthIcon.changeIcon(charFile.healthIcon);
			check_usingAntialiasing.checked = charFile.antialiasing;
			check_flipX.checked = charFile.flipX;
			stepper_singTime.value = charFile.singDuration;
			stepper_charXPos.value = charFile.characterOffset[0];
			stepper_charYPos.value = charFile.characterOffset[1];
			stepper_camXPos.value = charFile.cameraOffset[0];
			stepper_camYPos.value = charFile.cameraOffset[1];
			stepper_scale.value = charFile.scale;
			reloadAnimationDropDown();
		}
	}

	function loadChar(updateAnimLists:Bool = true) {
		loadCharJson(characterToAdd);

		charLayer.clear();

		if (char != null)
			char.kill();

		isDad = true;
		if (characterToAdd.startsWith('bf'))
			isDad = false;
		char = new Character(0, 0, characterToAdd, !isDad);
		if (char.animationsArray[0] != null) {
			char.playAnim(char.animationsArray[0].anim, true);
		}
		char.screenCenter();
		char.debugMode = true;
		charLayer.add(char);

		if (updateAnimLists)
			genBoyOffsets();

		camFollow.x = char.getMidpoint().x;
		camFollow.y = char.getMidpoint().y;

		updateCharPosition();
		updateCamPointPos();
		reloadCharacterOptions();
	}

	function loadCharDropDown() {
		var loadedCharacters:Map<String, Bool> = new Map();
		charList = [];
	
		#if sys
		for (modFolder in ModPaths.getModFolders()) {
			if (modFolder.enabled) {
				var modFolderPath:String = ModPaths.modPath(modFolder.folder, 'data/characters');
				if (ModPaths.isDirectory(modFolderPath)) {
					for (charFile in ModPaths.readDirectory(modFolderPath)) {
						var path:String = ModPaths.modPath(modFolder.folder, 'data/characters/' + charFile);
						if (!ModPaths.isDirectory(path) && (charFile.endsWith('.json') || (charFile.endsWith('.txt') && charFile != 'github-moment.txt'))) {
							var checkChar:String = charFile.endsWith('.json') ? charFile.substr(0, charFile.length - 5) : charFile.substr(0, charFile.length - 4);
							if (!loadedCharacters.exists(checkChar)) {
								charList.push(checkChar);
								loadedCharacters.set(checkChar, true);
							}
						}
					}
				}
			}
		}
	
		var defaultFolderPath:String = Paths.getPreloadPath('data/characters/');
		if (sys.FileSystem.exists(defaultFolderPath)) {
			for (charFile in sys.FileSystem.readDirectory(defaultFolderPath)) {
				var path:String = haxe.io.Path.join([defaultFolderPath, charFile]);
				if (!sys.FileSystem.isDirectory(path) && (charFile.endsWith('.json') || (charFile.endsWith('.txt')))) {
					var checkChar:String = charFile.endsWith('.json') ? charFile.substr(0, charFile.length - 5) : charFile.substr(0, charFile.length - 4);
					if (!loadedCharacters.exists(checkChar)) {
						charList.push(checkChar);
						loadedCharacters.set(checkChar, true);
					}
				}
			}
		}
		#else
		charList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end
	}

	function reloadCharacterImage() {
		var lastAnim:String = '';
		if (char.animation.curAnim != null) {
			lastAnim = char.animation.curAnim.name;
		}

		var anims:Array<AnimStuff> = char.animationsArray.copy();
		if (Assets.exists(Paths.file("images/" + char.imageFile + ".txt", TEXT, "shared")))
			char.frames = Paths.getPackerAtlas(char.imageFile, "shared");
		else if (Assets.exists(Paths.file("images/" + char.imageFile + ".xml", TEXT, "shared")))
			char.frames = Paths.getSparrowAtlas(char.imageFile, "shared");
		else
			char.frames = Paths.getSparrowAtlas(char.imageFile);

		if (char.animationsArray != null && char.animationsArray.length > 0) {
			for (anim in char.animationsArray) {
				var animIndices:Array<Int> = anim.indices;
				if (animIndices != null && animIndices.length > 0)
					char.animation.addByIndices(anim.anim, anim.name, animIndices, "", anim.fps, anim.loop);
				else
					char.animation.addByPrefix(anim.anim, anim.name, anim.fps, anim.loop);
				if (anim.offsets != null && anim.offsets.length > 1)
					char.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}

		if (lastAnim != '') {
			char.playAnim(lastAnim, true);
		} else {
			char.dance();
		}
	}

	function createCameraPointer() {
		if (camFolPoint != null)
			remove(camFolPoint);
		var pointerSprite:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		camFolPoint = new FlxSprite().loadGraphic(pointerSprite);
		camFolPoint.setGraphicSize(40, 40);
		camFolPoint.updateHitbox();
		camFolPoint.color = FlxColor.WHITE;
		add(camFolPoint);
	}

	function updateCamPointPos() {
		var xPos:Float = char.getMidpoint().x;
		var yPos:Float = char.getMidpoint().y;
		if (!char.isPlayer)
			xPos += 150 + char.cameraOffset[0];
		else
			xPos -= 100 + char.cameraOffset[0];
		yPos -= 100 - char.cameraOffset[1];
		xPos -= camFolPoint.width / 2;
		yPos -= camFolPoint.height / 2;
		camFolPoint.setPosition(xPos, yPos);
	}

	function updateCharPosition() {
		char.setPosition(char.characterOffset[0] + 100, char.characterOffset[1]);
	}

	function loadCharJson(character:String) {
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
			json = cast haxe.Json.parse(rawJson);
		else
			json = cast Character.parseTxt(rawJson);

		if (rawJson != null)
			charFile = json;
	}

	function genBoyOffsets():Void {
		var daLoop:Int = 0;

		var i:Int = dumbTexts.members.length - 1;
		while (i >= 0) {
			var member:FlxText = dumbTexts.members[i];
			if (member != null) {
				member.kill();
				dumbTexts.remove(member);
				member.destroy();
			}
			--i;
		}
		dumbTexts.clear();

		for (anim => offsets in char.animOffsets) {
			var text:FlxText = new FlxText(20, 65 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.scrollFactor.set();
			text.color = FlxColor.WHITE;
			text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			text.borderSize = 1;
			dumbTexts.add(text);
			daLoop++;
		}

		textAnim.visible = true;

		if (dumbTexts.length < 1) {
			var text:FlxText = new FlxText(10, 65, 0, "Error: Can't find any animations.", 15);
			text.scrollFactor.set();
			text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			text.borderSize = 1;
			dumbTexts.add(text);
			textAnim.visible = false;
		}
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if (sender == imageInputText) {
				char.imageFile = imageInputText.text;
			} else if (sender == healthIconInputText) {
				char.healthIcon = healthIconInputText.text;
				healthIcon.changeIcon(healthIconInputText.text);
			}
		} else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			switch (wname) {
				case 'step_cXPos':
					charFile.characterOffset[0] = Std.int(nums.value);
					char.characterOffset[0] = charFile.characterOffset[0];
					updateCharPosition();
				case 'step_cYPos':
					charFile.characterOffset[1] = Std.int(nums.value);
					char.characterOffset[1] = charFile.characterOffset[1];
					updateCharPosition();
				case 'step_cmXPos':
					charFile.cameraOffset[0] = Std.int(nums.value);
					char.cameraOffset[0] = charFile.cameraOffset[0];
					updateCamPointPos();
				case 'step_cmYPos':
					charFile.cameraOffset[1] = Std.int(nums.value);
					char.cameraOffset[1] = charFile.cameraOffset[1];
					updateCamPointPos();
				case 'step_charScale':
					charFile.scale = nums.value;
					char.jsonScale = charFile.scale;
					char.scale.set(charFile.scale, charFile.scale);
					char.updateHitbox();
					updateCamPointPos();
			}
		}
	}

	var multiplier = 0;

	override function update(elapsed:Float) {
		multiplier = (FlxG.keys.pressed.SHIFT ? 10 : 1);
		if (char.animation.curAnim != null && textAnim != null)
			textAnim.text = char.animation.curAnim.name;

		var goofyahhtext:Array<Bool> = [
			imageInputText.hasFocus,
			healthIconInputText.hasFocus,
			animationInputText.hasFocus,
			animationNameInputText.hasFocus,
			animationIndicesInputText.hasFocus
		];

		var inputTexts:Array<FlxUIInputText> = [
			imageInputText,
			healthIconInputText,
			animationInputText,
			animationNameInputText,
			animationIndicesInputText
		];

		if (!goofyahhtext.contains(true)) {
			var zoomAdd:Float = 500 * elapsed;

			if (FlxG.keys.pressed.SHIFT)
				zoomAdd *= 4;

			if (FlxG.keys.justPressed.R)
				FlxG.camera.zoom = 1;
			if (FlxG.keys.pressed.I)
				camFollow.y -= zoomAdd;
			if (FlxG.keys.pressed.K)
				camFollow.y += zoomAdd;

			if (FlxG.keys.pressed.J)
				camFollow.x -= zoomAdd;
			if (FlxG.keys.pressed.L)
				camFollow.x += zoomAdd;

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom > 3)
					FlxG.camera.zoom = 3;
			}

			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom < 0.1)
					FlxG.camera.zoom = 0.1;
			}
		} else {
			for (i in 0...inputTexts.length) {
				if (inputTexts[i].hasFocus) {
					if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V && Clipboard.text != null) {
						inputTexts[i].text = ClipboardAdd(inputTexts[i].text);
						inputTexts[i].caretIndex = inputTexts[i].text.length;
						getEvent(FlxUIInputText.CHANGE_EVENT, inputTexts[i], null, []);
					}
					if (FlxG.keys.justPressed.ENTER) {
						inputTexts[i].hasFocus = false;
					}
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					super.update(elapsed);
					return;
				}
			}
		}

		if (char.animationsArray.length > 0) {
			if (!goofyahhtext.contains(true)) {
				if (FlxG.keys.justPressed.W) {
					curAnim -= 1;
				}

				if (FlxG.keys.justPressed.S) {
					curAnim += 1;
				}

				if (curAnim < 0)
					curAnim = char.animationsArray.length - 1;

				if (curAnim >= char.animationsArray.length)
					curAnim = 0;

				if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE) {
					char.playAnim(char.animationsArray[curAnim].anim, true);
					genBoyOffsets();
				}

				var controlArray:Array<Bool> = [
					FlxG.keys.justPressed.LEFT,
					FlxG.keys.justPressed.RIGHT,
					FlxG.keys.justPressed.UP,
					FlxG.keys.justPressed.DOWN
				];

				for (i in 0...controlArray.length) {
					if (controlArray[i]) {
						var arrayValue = 0;

						if (i > 1)
							arrayValue = 1;

						var negativeMult:Int = 1;
						if (i % 2 == 1)
							negativeMult = -1;

						char.animationsArray[curAnim].offsets[arrayValue] += negativeMult * multiplier;

						char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
						char.playAnim(char.animationsArray[curAnim].anim, false);

						genBoyOffsets();
					}
				}
			}
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.mouse.visible = false;
			FlxG.switchState(new states.editors.EditorMenuState());
			FlxG.sound.playMusic(TitleState.freakyMenu);
		}

		super.update(elapsed);
	}

	function ClipboardAdd(prefix:String = ''):String {
		if (prefix.toLowerCase().endsWith('v')) {
			prefix = prefix.substring(0, prefix.length - 1);
		}
		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}

	var _file:FileReference;

	function onSaveComplete(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		Logger.log("Successfully saved file.");
	}

	function onSaveCancel(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		Logger.log("Error: Problem saving file");
	}

	function saveCharacter(format:String) {
		var json = {
			"animations": char.animationsArray,
			"spritePath": char.imageFile,
			"scale": char.jsonScale,
			"singDuration": char.singDuration,
			"healthIcon": char.healthIcon,
			"characterOffset": char.characterOffset,
			"cameraOffset": char.cameraOffset,
			"flipX": char.originalFlipX,
			"antialiasing": char.antialiasing
		};

		var data:String = "";

		if (format == "json") {
			data = haxe.Json.stringify(json, "\t");
		} else if (format == "txt") {
			data = stringifyTxt();
		}

		if (data.length > 0) {
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, characterToAdd + "." + format);
		}
	}

	function stringifyTxt():String {
		var lines:Array<String> = [];

		lines.push("spritePath=" + char.imageFile);
		lines.push("healthIcon=" + char.healthIcon);
		lines.push("scale=" + char.jsonScale);
		lines.push("flipX=" + char.originalFlipX);
		lines.push("antialiasing=" + char.antialiasing);
		lines.push("singDuration=" + char.singDuration);
		lines.push("cameraOffset=" + char.cameraOffset.join(":"));
		lines.push("characterOffset=" + char.characterOffset.join(":"));

		for (anim in char.animationsArray) {
		    lines.push("animation=" + [
				anim.anim,
				anim.name,
				Std.string(anim.fps),
				Std.string(anim.loop),
				anim.offsets.map(Std.string).join(":"),
				anim.indices.map(Std.string).join(" ")
			].join(","));
		}

		return lines.join("\n");
	}
}
