package states.editors.stage;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import system.Stage.StageJson;
import system.Stage.ObjectData;
import openfl.utils.Assets;

using StringTools;

// wip stage editor
class StageEditorState extends MusicBeatState {
	var uiBox:FlxUITabMenu;
	var stageFile:StageJson;
	var _file:FileReference;

	var BFXPOS:Float = 770;
	var BFYPOS:Float = 100;
	var DADXPOS:Float = 100;
	var DADYPOS:Float = 100;
	var GFXPOS:Float = 400;
	var GFYPOS:Float = 130;

	var bf:Character;
	var bfGroup:FlxTypedGroup<FlxSprite>;
	var gf:Character;
	var gfGroup:FlxTypedGroup<FlxSprite>;
	var dad:Character;
	var dadGroup:FlxTypedGroup<FlxSprite>;

	var characters:Array<String> = ['bf', 'gf', 'dad'];

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var camFollow:FlxObject;

	var stageToLoad:String = '<NO STAGES>';
	var stageObjects:FlxTypedGroup<FlxSprite>;
	var stageObjectsForeground:FlxTypedGroup<FlxSprite>;

	var curObject:Dynamic;
	var selectedThing:Bool = false;
	var selectedObj:Int = 0;

	var infos:Array<String> = ['Current Sprite: ', 'Position: '];
	var stageObjID:Array<Dynamic> = [];
	var stageDropDown:FlxUIDropDownMenu;
	var stageList:Array<String> = [];

	override function create() {
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		camFollow = new FlxObject(0, 0, 2, 2);
		add(camFollow);

		FlxG.camera.follow(camFollow);
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxCamera.defaultCameras = [camGame];

		FlxG.mouse.visible = true;

		stageObjects = new FlxTypedGroup<FlxSprite>();
		add(stageObjects);

		gfGroup = new FlxTypedGroup<FlxSprite>();
		add(gfGroup);

		dadGroup = new FlxTypedGroup<FlxSprite>();
		add(dadGroup);

		bfGroup = new FlxTypedGroup<FlxSprite>();
		add(bfGroup);

		stageObjectsForeground = new FlxTypedGroup<FlxSprite>();
		add(stageObjectsForeground);

		loadStageJSON(stageToLoad);
		createChar('bf');
		createChar('gf');
		createChar('dad');
		loadCharDropDown();
		loadStageDropDown();

		addUIBox();
		addDataUI();
		addObjectsUI();

		super.create();
	}

	function addUIBox() {
		var tabs = [{name: "Objects", label: 'Objects'}, {name: "Data", label: 'Data'}];
		uiBox = new FlxUITabMenu(null, tabs, true);
		uiBox.resize(400, 200);
		uiBox.x = FlxG.width - uiBox.width - 20;
		uiBox.y = 20;
		uiBox.cameras = [camHUD];
		uiBox.scrollFactor.set();
		add(uiBox);
	}

	var charList:Array<String> = [];
	var bfDropDown:FlxUIDropDownMenu;
	var gfDropDown:FlxUIDropDownMenu;
	var opDropDown:FlxUIDropDownMenu;
	var stepper_stageZoom:FlxUINumericStepper;

	function addDataUI():Void {
		var tab_group_selchar = new FlxUI(null, uiBox);
		tab_group_selchar.name = "Data";
		tab_group_selchar.cameras = [camHUD];

		stageDropDown = new FlxUIDropDownMenu(10, 30, FlxUIDropDownMenu.makeStrIdLabelArray(stageList, true), function(stage:String) {
			stageToLoad = stageList[Std.parseInt(stage)];
			if (stageToLoad != '<NO STAGES>')
				loadStage();
			loadStageDropDown();
		});
		stageDropDown.selectedLabel = characters[0];
		var sddText:FlxText = new FlxText(stageDropDown.x, stageDropDown.y - 15, FlxG.width, "Stage", 8);

		bfDropDown = new FlxUIDropDownMenu(10, 70, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String) {
			characters[0] = charList[Std.parseInt(character)];
			createChar('bf');
			loadCharDropDown();
		});
		bfDropDown.selectedLabel = characters[0];
		var bfddText:FlxText = new FlxText(bfDropDown.x, bfDropDown.y - 15, FlxG.width, "Boyfriend", 8);

		gfDropDown = new FlxUIDropDownMenu(160, 30, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String) {
			characters[1] = charList[Std.parseInt(character)];
			createChar('gf');
			loadCharDropDown();
		});
		gfDropDown.selectedLabel = characters[1];
		var gfddText:FlxText = new FlxText(gfDropDown.x, gfDropDown.y - 15, FlxG.width, "Girlfriend", 8);

		opDropDown = new FlxUIDropDownMenu(160, 70, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String) {
			characters[2] = charList[Std.parseInt(character)];
			createChar('dad');
			loadCharDropDown();
		});
		opDropDown.selectedLabel = characters[2];
		var opText:FlxText = new FlxText(opDropDown.x, opDropDown.y - 15, FlxG.width, "Dad", 8);

		stepper_stageZoom = new FlxUINumericStepper(300, 60, 0.1, 0.9, 0.1, 30, 1);
		stepper_stageZoom.name = 'step_stgZm';
		tab_group_selchar.add(stepper_stageZoom);
		var sszText:FlxText = new FlxText(stepper_stageZoom.x, stepper_stageZoom.y - 15, FlxG.width, "Default Zoom", 8);
		tab_group_selchar.add(sszText);

		var saveStageButton:FlxButton = new FlxButton(110, 110, 'Save Stage', function() {
			saveStageShit();
		});
		tab_group_selchar.add(saveStageButton);

		tab_group_selchar.add(opDropDown);
		tab_group_selchar.add(opText);
		tab_group_selchar.add(gfDropDown);
		tab_group_selchar.add(gfddText);
		tab_group_selchar.add(bfDropDown);
		tab_group_selchar.add(bfddText);
		tab_group_selchar.add(stageDropDown);
		tab_group_selchar.add(sddText);

		uiBox.addGroup(tab_group_selchar);
		uiBox.scrollFactor.set();
	}

	var input_spritePath:FlxUIInputText;
	var input_name:FlxUIInputText;
	var check_imgAntialias:FlxUICheckBox;
	var stepper_imageSf:FlxUINumericStepper;
	var stepper_imageScale:FlxUINumericStepper;
	var stepper_imageAlpha:FlxUINumericStepper;
	var stepper_imageLayer:FlxUINumericStepper;

	function addObjectsUI() {
		var tab_group_sprite = new FlxUI(null, uiBox);
		tab_group_sprite.cameras = [camHUD];
		tab_group_sprite.name = "Objects";

		input_spritePath = new FlxUIInputText(10, 20, 200, '', 8);
		tab_group_sprite.add(input_spritePath);
		var opText:FlxText = new FlxText(input_spritePath.x, input_spritePath.y - 15, FlxG.width, "Object Image Path", 8);
		tab_group_sprite.add(opText);

		check_imgAntialias = new FlxUICheckBox(10, 50, null, null, "Antialiasing", 70);
		check_imgAntialias.name = 'check_antialiasing';
		tab_group_sprite.add(check_imgAntialias);

		input_name = new FlxUIInputText(120, 55, 75, '', 8);
		tab_group_sprite.add(input_name);
		var oppText:FlxText = new FlxText(input_name.x, input_name.y - 15, FlxG.width, "Object Name", 8);
		tab_group_sprite.add(oppText);

		stepper_imageSf = new FlxUINumericStepper(10, 80, 0.1, 1, 0, 1, 1);
		tab_group_sprite.add(stepper_imageSf);
		var sisfText:FlxText = new FlxText(stepper_imageSf.x + stepper_imageSf.width + 5, stepper_imageSf.y + 1, FlxG.width, "| Scroll Factor", 8);
		tab_group_sprite.add(sisfText);

		stepper_imageScale = new FlxUINumericStepper(10, 100, 0.1, 1, 0.1, 50, 1);
		tab_group_sprite.add(stepper_imageScale);
		var sisText:FlxText = new FlxText(stepper_imageScale.x + stepper_imageScale.width + 5, stepper_imageScale.y + 1, FlxG.width, "| Scale", 8);
		tab_group_sprite.add(sisText);

		stepper_imageAlpha = new FlxUINumericStepper(10, 130, 0.1, 1, 0.1, 1, 1);
		tab_group_sprite.add(stepper_imageAlpha);
		var sisaText:FlxText = new FlxText(stepper_imageAlpha.x + stepper_imageAlpha.width + 5, stepper_imageAlpha.y + 1, FlxG.width, "| Alpha", 8);
		tab_group_sprite.add(sisaText);

		stepper_imageLayer = new FlxUINumericStepper(10, 150, 1, 0, 0, 1, 0);
		tab_group_sprite.add(stepper_imageLayer);
		var sisaText:FlxText = new FlxText(stepper_imageLayer.x + stepper_imageLayer.width + 5, stepper_imageLayer.y + 1, FlxG.width, "| Layer", 8);
		tab_group_sprite.add(sisaText);

		var createSprButton:FlxButton = new FlxButton(250, 15, 'Add Sprite', function() {
			addSpriteShit();
		});
		tab_group_sprite.add(createSprButton);

		var removeSprButton:FlxButton = new FlxButton(250, 50, 'Remove Sprite', function() {
			if (curObject != null) {
				if (curObject != bf && curObject != gf && curObject != dad) {
					var idShit:Int = 0;
					var e:Dynamic = [];
					for (i in 0...stageObjID.length) {
						if (stageObjID[i][0] == curObject) {
							idShit = stageObjID[i][1];
							e = stageObjID[i];
						}
					}
					stageFile.objects.remove(stageFile.objects[idShit]);
					if (stageObjects.members[idShit] != null) {
						stageObjects.members[idShit].kill();
						stageObjects.remove(stageObjects.members[idShit], true);
					}
					if (stageObjectsForeground.members[idShit] != null) {
						stageObjectsForeground.members[idShit].kill();
						stageObjectsForeground.remove(stageObjectsForeground.members[idShit], true);
					}
					stageObjID.remove(e);
					curObject = null;
				}
			}
		});
		tab_group_sprite.add(removeSprButton);

		uiBox.addGroup(tab_group_sprite);
		uiBox.scrollFactor.set();
	}

	function addSpriteShit() {
		var loopshit:Int = 0;
		for (i in 0...stageObjects.length) {
			loopshit++;
		}
		for (i in 0...stageObjectsForeground.length) {
			loopshit++;
		}
		var daSprite:FlxSprite = new FlxSprite();
		daSprite.loadGraphic(Paths.image(input_spritePath.text));
		daSprite.scale.set(stepper_imageScale.value, stepper_imageScale.value);
		daSprite.antialiasing = check_imgAntialias.checked;
		daSprite.setPosition(0, 0);
		daSprite.scrollFactor.set(stepper_imageSf.value, stepper_imageSf.value);
		daSprite.alpha = stepper_imageAlpha.value;
		daSprite.ID = loopshit;
		switch (Math.round(stepper_imageLayer.value)) {
			case 1:
				stageObjectsForeground.add(daSprite);
			default:
				stageObjects.add(daSprite);
		}
		var shit:ObjectData = {
			name: input_name.text,
			image: input_spritePath.text,
			alpha: stepper_imageAlpha.value,
			scale: stepper_imageScale.value,
			scrollFactor: stepper_imageSf.value,
			layer: Math.round(stepper_imageLayer.value),
			antialiasing: check_imgAntialias.checked,
			position: [0, 0],
		}
		stageFile.objects.push(shit);
		stageObjID.push([daSprite, daSprite.ID]);
	}

	var jsonWasNull:Bool = false;

	function loadStageJSON(stage:String = "") {
		if (stageToLoad != '<NO STAGES>') {
			var crapJSON = null;
			#if sys
			var charFile:String = ModPaths.data("stages/" + stage);
			if (sys.FileSystem.exists(charFile))
				crapJSON = sys.io.File.getContent(charFile);
			#end

			var json:StageJson = cast haxe.Json.parse(crapJSON);

			if (crapJSON != null) {
				jsonWasNull = false;
				stageFile = json;
			} else {
				jsonWasNull = true;
			}
		} else {
			stageFile = {
				objects: [],
				bfPosition: [770, 100],
				gfPosition: [400, 130],
				dadPosition: [100, 100],
				defaultCamZoom: 0.9
			}
		}
	}

	function createChar(charToAdd:String = '') {
		switch (charToAdd) {
			case 'bf':
				if (bf != null) {
					bf.kill();
					bfGroup.remove(bf);
					bf.destroy();
				}

				bf = new Character(BFXPOS, BFYPOS, characters[0], true);
				bfGroup.add(bf);

				if (!jsonWasNull) {
					bf.x = stageFile.bfPosition[0];
					bf.y = stageFile.bfPosition[1];
				}

				bf.x += bf.characterOffset[0];
				bf.y += bf.characterOffset[1];
			case 'gf':
				if (gf != null) {
					gf.kill();
					gfGroup.remove(gf);
					gf.destroy();
				}

				gf = new Character(GFXPOS, GFYPOS, characters[1], false);
				gfGroup.add(gf);

				if (!jsonWasNull) {
					gf.x = stageFile.gfPosition[0];
					gf.y = stageFile.gfPosition[1];
				}

				gf.x += gf.characterOffset[0];
				gf.y += gf.characterOffset[1];
			case 'dad':
				if (dad != null) {
					dad.kill();
					dadGroup.remove(dad);
					dad.destroy();
				}

				dad = new Character(DADXPOS, DADYPOS, characters[2], false);
				dadGroup.add(dad);

				if (!jsonWasNull) {
					dad.x = stageFile.dadPosition[0];
					dad.y = stageFile.dadPosition[1];
				}

				dad.x += dad.characterOffset[0];
				dad.y += dad.characterOffset[1];
		}
	}

	function loadStageDropDown() {
		var loadedStages:Map<String, Bool> = new Map();
		stageList = [];

		#if sys
		for (modFolder in ModPaths.getModFolders()) {
			if (modFolder.enabled) {
				var modFolderPath:String = ModPaths.modPath(modFolder.folder, 'data/stages');
				if (ModPaths.isDirectory(modFolderPath)) {
					for (stageJson in ModPaths.readDirectory(modFolderPath)) {
						var path:String = ModPaths.modPath(modFolder.folder, 'data/stages/' + stageJson);
						if (!ModPaths.isDirectory(path) && stageJson.endsWith('.json')) {
							var checkStage:String = stageJson.substr(0, stageJson.length - 5);
							if (!loadedStages.exists(checkStage)) {
								stageList.push(checkStage);
								loadedStages.set(checkStage, true);
							}
						}
					}
				}
			}
		}
		#end

		if (stageList.length == 0) {
			stageList.push('<NO STAGES>');
		}
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

	function loadStage() {
		stageFile = null;

		for (i in 0...stageObjects.length) {
			if (stageObjects.members[i] != null) {
				stageObjects.members[i].kill();
				stageObjects.remove(stageObjects.members[i]);
				stageObjects.members[i].destroy();
			}
		}

		for (i in 0...stageObjectsForeground.length) {
			if (stageObjectsForeground.members[i] != null) {
				stageObjectsForeground.members[i].kill();
				stageObjectsForeground.remove(stageObjectsForeground.members[i]);
				stageObjectsForeground.members[i].destroy();
			}
		}

		for (i in 0...stageObjID.length) {
			stageObjID.remove(stageObjID[i]);
		}

		loadStageJSON(stageToLoad);
		createChar('bf');
		createChar('gf');
		createChar('dad');

		if (!jsonWasNull) {
			stepper_stageZoom.value = stageFile.defaultCamZoom;
			for (i in 0...stageFile.objects.length) {
				var sprite:FlxSprite = new FlxSprite();
				sprite.loadGraphic(Paths.image(stageFile.objects[i].image));
				sprite.scale.set(stageFile.objects[i].scale, stageFile.objects[i].scale);
				sprite.antialiasing = stageFile.objects[i].antialiasing;
				sprite.setPosition(stageFile.objects[i].position[0], stageFile.objects[i].position[1]);
				sprite.scrollFactor.set(stageFile.objects[i].scrollFactor, stageFile.objects[i].scrollFactor);
				sprite.alpha = stageFile.objects[i].alpha;
				sprite.ID = i;
				switch (stageFile.objects[i].layer) {
					case 1:
						stageObjectsForeground.add(sprite);
					default:
						stageObjects.add(sprite);
				}
				stageObjID.push([sprite, sprite.ID]);
			}
		}
	}

	var curObjectID:Int = 0;

	function checkChars() {
		if (FlxG.mouse.overlaps(gf) && gf != null) {
			if (FlxG.mouse.pressed && selectedThing != true) {
				selectedThing = true;
				curObject = gf;
			}
		}

		if (FlxG.mouse.overlaps(bf) && bf != null) {
			if (FlxG.mouse.pressed && selectedThing != true) {
				selectedThing = true;
				curObject = bf;
			}
		}

		if (FlxG.mouse.overlaps(dad) && dad != null) {
			if (FlxG.mouse.pressed && selectedThing != true) {
				selectedThing = true;
				curObject = dad;
			}
		}

		stageObjects.forEachAlive(function(object:FlxSprite) {
			if (FlxG.mouse.overlaps(object)) {
				if (FlxG.mouse.pressed && selectedThing != true) {
					curObject = object;
					selectedThing = true;
					curObjectID = object.ID;
				}
			}
		});
		stageObjectsForeground.forEachAlive(function(object:FlxSprite) {
			if (FlxG.mouse.overlaps(object)) {
				if (FlxG.mouse.pressed && selectedThing != true) {
					curObject = object;
					selectedThing = true;
					curObjectID = object.ID;
				}
			}
		});
		if (!FlxG.mouse.pressed)
			selectedThing = false;
		if (FlxG.mouse.pressed && selectedThing) {
			curObject.x = FlxG.mouse.x - curObject.frameWidth / 2;
			curObject.y = FlxG.mouse.y - curObject.frameHeight / 2;

			if (curObject != bf && curObject != gf && curObject != dad) {
				var idShit:Int = 0;
				var e:Dynamic = [];
				for (i in 0...stageObjID.length) {
					if (stageObjID[i][0] == curObject) {
						idShit = stageObjID[i][1];
						e = stageObjID[i];
					}
				}
				stageFile.objects[idShit].position = [curObject.x, curObject.y];
			}
		}

		if (curObject != bf && curObject != gf && curObject != dad) {
			if (FlxG.keys.justPressed.DELETE && curObject != null) {
				var idShit:Int = 0;
				var e:Dynamic = [];
				for (i in 0...stageObjID.length) {
					if (stageObjID[i][0] == curObject) {
						idShit = stageObjID[i][1];
						e = stageObjID[i];
					}
				}
				stageFile.objects.remove(stageFile.objects[idShit - 1]);
				stageObjects.members[idShit - 1].kill();
				stageObjects.remove(curObject, true);
				stageObjectsForeground.members[idShit - 1].kill();
				stageObjectsForeground.remove(curObject, true);
				stageObjID.remove(e);
				curObject = null;
			}
		}

		var ugh:Bool = (bf == null && gf == null && dad == null);

		if (!jsonWasNull && !ugh) {
			stageFile.gfPosition = [gf.x, gf.y];
			stageFile.bfPosition = [bf.x, bf.y];
			stageFile.dadPosition = [dad.x, dad.y];
		}
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			switch (wname) {
				case 'step_stgZm':
					stageFile.defaultCamZoom = nums.value;
			}
		}
	}

	override function update(elapsed:Float) {
		checkChars();

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

		if (FlxG.keys.justPressed.SPACE) {
			bf.dance();
			gf.dance();
			dad.dance();
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.mouse.visible = false;
			FlxG.switchState(new states.editors.EditorMenuState());
			FlxG.sound.playMusic(TitleState.freakyMenu);
		}

		super.update(elapsed);
	}

	override function beatHit() {
		if (bf != null)
			bf.dance();
		if (gf != null)
			gf.dance();
		if (dad != null)
			dad.dance();

		super.beatHit();
	}

	function onSaveComplete(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		Logger.log("Successfully saved LEVEL DATA.");
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
		Logger.log("Error: Problem saving Level data");
	}

	function saveStageShit() {
		var jsonFile = {
			"objects": stageFile.objects,
			"defaultCamZoom": stageFile.defaultCamZoom,
			"bfPosition": stageFile.bfPosition = [bf.x - bf.characterOffset[0], bf.y - bf.characterOffset[1]],
			"gfPosition": stageFile.gfPosition = [gf.x - gf.characterOffset[0], gf.y - gf.characterOffset[1]],
			"dadPosition": stageFile.dadPosition = [dad.x - dad.characterOffset[0], dad.y - dad.characterOffset[1]]
		};

		var data:String = haxe.Json.stringify(jsonFile, "\t");

		if (data.length > 0) {
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, "stage.json");
		}
	}
}
