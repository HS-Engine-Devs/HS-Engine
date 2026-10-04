package states.editors.charting;

import game.Event;
import game.Event.ChartEvent;
import game.Event.EventListData;
import system.Conductor.BPMChangeEvent;
import system.Section.SwagSection;
import system.Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

using StringTools;

class ChartingEditorState extends MusicBeatState
{
	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	var validEvents:Array<EventListData> = [
		{ eventName: "bpm change", var1Hint: "New BPM", var2Hint: null, info: "Changes the song's tempo" },
		{ eventName: "play animation", var1Hint: "Animation name", var2Hint: "Target (e.g., bf, dad)", info: "Plays a character's animation" },
		{ eventName: "camera follow pos", var1Hint: "X", var2Hint: "Y", info: "Sets camera follow position" },
		{ eventName: "change character", var1Hint: "Target (bf/dad/gf)", var2Hint: "Character name", info: "Changes the character during the song" },
		{ eventName: "screen shake", var1Hint: "Intensity", var2Hint: "Duration (seconds)", info: "Shakes the screen" },
		{ eventName: "flash", var1Hint: "Duration (seconds)", var2Hint: "Color (e.g., 'red', '#FF0000')", info: "Screen flash with specified color" },
		{ eventName: "add camera zoom", var1Hint: "Game Zoom", var2Hint: "HUD Zoom", info: "Adds instant zoom to Game and HUD" },
		{ eventName: "tween hud alpha", var1Hint: "Alpha value (0-1)", var2Hint: "Duration (seconds)", info: "Animates HUD transparency" },
		{ eventName: "set hud alpha", var1Hint: "Alpha value (0-1)", var2Hint: null, info: "Sets HUD transparency" },
		//TODO
		//{ eventName: "change noteskin", var1Hint: "Skin name", var2Hint: "Target (bf/dad/all)", info: "Changes Note/Strum skin (add 'pixel' for pixel UI)" }
	];

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = 'Dadbattle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	var GRID_SIZE:Int = 40;
	var gridSnap:Int = 16;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedEvents:FlxTypedGroup<Event>;
	var ignoreRenderShit:FlxGroup = new FlxGroup();

	var bg:FlxSprite;
	var gridBG:FlxSprite;
	var eventGridBG:FlxSprite;

	var sectionBGs:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
	var eventSectionBGs:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();

	var funnyCamObj:FlxSprite;

	var _song:SwagSong;

	var undoStack:Array<String> = [];
	var redoStack:Array<String> = [];
	var historyLimit:Int = 50;

	function snapshotSong():String {
		return Json.stringify({ song: _song });
	}

	function recordUndoState(?clearRedo:Bool = true):Void {
		undoStack.push(snapshotSong());
		if (undoStack.length > historyLimit) undoStack.shift();
		if (clearRedo) redoStack = [];
	}

	function recordRedoState():Void {
		redoStack.push(snapshotSong());
		if (redoStack.length > historyLimit) redoStack.shift();
	}

	function restoreSongState(state:String):Void {
		var parsed:Dynamic = Json.parse(state);
		_song = parsed.song;
		if (_song.events == null) _song.events = [];
		if (_song.notes == null) _song.notes = [];
		if (_song.notes.length == 0) {
			_song.notes = [{
				lengthInSteps: 16,
				bpm: _song.bpm,
				changeBPM: false,
				mustHitSection: true,
				sectionNotes: [],
				typeOfSection: 0,
				altAnim: false
			}];
		}
		if (curSection >= _song.notes.length) curSection = _song.notes.length - 1;
		if (curSection < 0) curSection = 0;
		updateGrid();
		updateSectionUI();
	}

	function undo():Void {
		if (undoStack.length == 0) return;
		recordRedoState();
		var state:String = undoStack.pop();
		restoreSongState(state);
	}

	function redo():Void {
		if (redoStack.length == 0) return;
		recordUndoState(false);
		var state:String = redoStack.pop();
		restoreSongState(state);
	}

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;
	var curSelectedEvents:Array<ChartEvent> = [];

	var curEditingEventIndex:Int = 0;

	var tempBpm:Float = 0;

	var vocals:FlxSound;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

    var selectionBox:FlxSprite;
    var startMousePos:FlxPoint = new FlxPoint();
    var isSelecting:Bool = false;

    var selectedNotesGroup:Array<Note> = [];
	var oldSelectionData:Array<{time:Float, data:Int}> = [];
	var selectShader:SelectionShader = new SelectionShader();
	var copyBuffer:Array<Array<Dynamic>> = [];

    var selectedEventsGroup:Array<Event> = [];
    var copyBufferEvents:Array<Dynamic> = [];

    var waveformSprite:FlxSprite;
    var showWaveform:Bool = false;
	var waveColor:Int = 0xFF6666FF;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

	override function create()
	{
		curSection = lastSection;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.scrollFactor.set(0, 0);
        bg.color = 0xFF303030;
		add(bg);

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);

		eventGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, GRID_SIZE * 16);
		eventGridBG.x -= GRID_SIZE;

        var invisEventGridBG1 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, GRID_SIZE * 16);
		invisEventGridBG1.x -= GRID_SIZE;
        invisEventGridBG1.y = (eventGridBG.height * -1);
        invisEventGridBG1.alpha = 0.75;
        eventSectionBGs.add(invisEventGridBG1);

        eventSectionBGs.add(eventGridBG);

        var invisEventGridBG2 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE, GRID_SIZE * 16);
		invisEventGridBG2.x -= GRID_SIZE;
        invisEventGridBG2.y = eventGridBG.height;
        invisEventGridBG2.alpha = 0.75;

        eventSectionBGs.add(invisEventGridBG2);
        add(eventSectionBGs);

		var invisGridBG1 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		invisGridBG1.y = (gridBG.height * -1);
		invisGridBG1.alpha = 0.75;
		sectionBGs.add(invisGridBG1);

		sectionBGs.add(gridBG);

		var invisGridBG2 = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		invisGridBG2.y = gridBG.height;
		invisGridBG2.alpha = 0.75;
		
		sectionBGs.add(invisGridBG2);

		add(sectionBGs);

		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width / 2, gridBG.height * -1).makeGraphic(2, Std.int(gridBG.height * 3), FlxColor.BLACK);
		add(gridBlackLine);

		var gridEventLine:FlxSprite = new FlxSprite(0, gridBG.height * -1).makeGraphic(2, Std.int(gridBG.height * 3), FlxColor.BLACK);
		add(gridEventLine);

        waveformSprite = new FlxSprite(gridBG.x, gridBG.y - gridBG.height); 
        waveformSprite.makeGraphic(Std.int(gridBG.width), Std.int(gridBG.height * 3), 0x00000000);
		waveformSprite.antialiasing = true;
		waveformSprite.alpha = 0.8;
        add(waveformSprite);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedEvents = new FlxTypedGroup<Event>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			_song = {
				song: 'Test',
				notes: [],
				events: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				speed: 1,
				validScore: false
			};
		}

		// psych chart
        if (_song != null && _song.notes != null)
        {
            for (section in _song.notes)
            {
                if (Reflect.hasField(section, "sectionBeats")) 
                {
                    var beats:Float = Reflect.field(section, "sectionBeats");
                    section.lengthInSteps = Std.int(beats * 4);
                    Reflect.deleteField(section, "sectionBeats");
                }
            }
        }

		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		recordUndoState();

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(-40, 50).makeGraphic(Std.int(gridBG.width + eventGridBG.width), 4);
		add(strumLine);

		funnyCamObj = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
		funnyCamObj.alpha = 0;
		add(funnyCamObj);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		add(UI_box);

		var undoBtn:FlxButton = new FlxButton(10, 10, "Undo", function() undo());
		undoBtn.scrollFactor.set(0, 0);
		undoBtn.setGraphicSize(64, 24);
		add(undoBtn);

		var redoBtn:FlxButton = new FlxButton(80, 10, "Redo", function() redo());
		redoBtn.scrollFactor.set(0, 0);
		redoBtn.setGraphicSize(64, 24);
		add(redoBtn);

		//var scriptBtn:FlxButton = new FlxButton(150, 10, "Script", function() {
		//	FlxG.switchState(new states.editors.script.ScriptEditorState());
		//});
		//scriptBtn.scrollFactor.set(0, 0);
		//scriptBtn.setGraphicSize(64, 24);
		//add(scriptBtn);

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
        updateHeads();
        changeSection();

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedEvents);
		add(ignoreRenderShit);

		add(leftIcon);
		add(rightIcon);

        selectionBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLUE);
        selectionBox.alpha = 0.3;
        selectionBox.visible = false;
        add(selectionBox);

		super.create();
	}

	var eventDropDown:FlxUIDropDownMenu;
	var eventVar1:FlxUIInputText;
	var eventVar2:FlxUIInputText;
	var loadCurEvent:Void -> Void;

	function addEventsUI():Void {
		var tab_events = new FlxUI(null, UI_box);
		tab_events.name = 'Events';

		var events:Array<EventListData> = [];
		var eventNames:Array<String> = [];

		for (array in validEvents) {
			if (array != null) {
				events.push(array);
				eventNames.push(array.eventName);
			}
		}

		#if sys
		for (modFolder in ModPaths.getModFolders()) {
			if (modFolder.enabled) {
				var modFolderPath = ModPaths.modPath(modFolder.folder, 'data/events');
				if (ModPaths.isDirectory(modFolderPath)) {
					for (eventJson in ModPaths.readDirectory(modFolderPath)) {
						if (eventJson != null && eventJson.endsWith('.json')) {
							var jsonContent = ModPaths.readContent(ModPaths.modPath(modFolder.folder, 'data/events/' + eventJson));
							var parsedData:Dynamic = haxe.Json.parse(jsonContent);
							if (Std.is(parsedData, Array)) {
								var eventArray:Array<Dynamic> = cast parsedData;
								for (event in eventArray) {
									var eventData:EventListData = {
										eventName: event.eventName,
										var1Hint: event.var1Hint,
										var2Hint: event.var2Hint,
										info: event.info
									};
									events.push(eventData);
									eventNames.push(eventData.eventName);
								}
							} else {
								var event = parsedData;
								var eventData:EventListData = {
									eventName: event.eventName,
									var1Hint: event.var1Hint,
									var2Hint: event.var2Hint,
									info: event.info
								};
								events.push(eventData);
								eventNames.push(eventData.eventName);
							}
						}
					}
				}
			}
		}
		#end

		eventVar1 = new FlxUIInputText(10, 70);
		var eventVar1InfoText = new FlxText(eventVar1.x, eventVar1.y - 20);

		eventVar2 = new FlxUIInputText(10, 120);
		var eventVar2InfoText = new FlxText(eventVar2.x, eventVar2.y - 20);

		var eventInstructionText = new FlxText(10, 170, 280);
		eventInstructionText.setFormat(null, 8, FlxColor.WHITE, "left");
		eventInstructionText.text = "Left click to add or remove an event.\nRight click to edit events.\nClick 'Update' to save Event Changes.\nPlacing an event also saves.\n\nUse 'Add New Event' to\nadd multiple events to the same note.\n\nUse 'Next Event' to switch between\nevents of the same strumtime.\n\nUse 'Remove Event' to delete the current event.";

		eventDropDown = new FlxUIDropDownMenu(10, 20, FlxUIDropDownMenu.makeStrIdLabelArray(eventNames, true), function(selectedLabel:String) {
			if (curSelectedEvents.length > 0) {
				var selected = curSelectedEvents[curEditingEventIndex];
				selected.event = eventNames[Std.parseInt(selectedLabel)];

				for (event in events) {
					if (event != null && event.eventName.toLowerCase() == selected.event.toLowerCase()) {
						eventVar1InfoText.text = event.var1Hint;
						eventVar2InfoText.text = event.var2Hint;
						eventInstructionText.text = event.info;
						break;
					}
				}
			}
		});

		var saveButton:FlxButton = new FlxButton(200, 20, "Update", function() {
			if (curSelectedEvents.length > 0) {
				recordUndoState();
				var selected = curSelectedEvents[curEditingEventIndex];
				selected.event = eventDropDown.selectedLabel;
				selected.variable1 = eventVar1.text;
				selected.variable2 = eventVar2.text;
			}
		});

		var addNewEventButton = new FlxButton(200, 60, "Add New Event", function() {
            recordUndoState();
            var noteStrum:Float = (curSelectedEvents.length > 0) 
                ? curSelectedEvents[curEditingEventIndex].strumtime 
                : getStrumTime(dummyArrow.y) + sectionStartTime();

            var newEvent:ChartEvent = {
                strumtime: noteStrum,
                event: eventDropDown.selectedLabel,
                variable1: eventVar1.text,
                variable2: eventVar2.text
            };

            if (_song.events == null) _song.events = [];
            _song.events.push(newEvent);

            _song.events.sort(function(a, b) return Reflect.compare(a.strumtime, b.strumtime));

            curSelectedEvents = _song.events.filter(function(e) return Math.abs(e.strumtime - noteStrum) < 2);
            curEditingEventIndex = curSelectedEvents.length - 1;

			updateGrid();
			autosaveSong();
			loadCurEvent();
		});

		var nextEventButton = new FlxButton(200, 100, "Next Event", function() {
			if (curSelectedEvents.length > 1) {
				curEditingEventIndex = (curEditingEventIndex + 1) % curSelectedEvents.length;
				loadCurEvent();
			}
		});

		var removeEventButton = new FlxButton(200, 140, "Remove Event", function() {
			if (curSelectedEvents.length > 0) {
                recordUndoState();
                var selected = curSelectedEvents[curEditingEventIndex];
                _song.events.remove(selected);

                curSelectedEvents = _song.events.filter(function(e) return Math.abs(e.strumtime - selected.strumtime) < 2);

                if (curSelectedEvents.length > 0) {
                    curEditingEventIndex = curEditingEventIndex % curSelectedEvents.length;
                } else {
                    curEditingEventIndex = 0;
                }

                updateGrid();
                loadCurEvent();
                autosaveSong();
			}
		});

		loadCurEvent = function() {
			if (curSelectedEvents.length > 0) {
				var selected = curSelectedEvents[curEditingEventIndex];
				eventDropDown.selectedLabel = selected.event;

				eventVar1.text = selected.variable1;
				eventVar2.text = selected.variable2;

				for (event in events) {
					if (event != null && event.eventName.toLowerCase() == eventNames[eventNames.indexOf(selected.event)].toLowerCase()) {
						eventVar1InfoText.text = event.var1Hint;
						eventVar2InfoText.text = event.var2Hint;
						eventInstructionText.text = event.info;
						break;
					}
				}
			}
		}

		tab_events.add(eventVar1);
		tab_events.add(eventVar2);
		tab_events.add(eventVar1InfoText);
		tab_events.add(eventVar2InfoText);
		tab_events.add(eventInstructionText);
		tab_events.add(saveButton);
		tab_events.add(addNewEventButton);
		tab_events.add(nextEventButton);
		tab_events.add(removeEventButton);
		tab_events.add(eventDropDown);

		UI_box.addGroup(tab_events);
		UI_box.scrollFactor.set();
	}

    var stageInput:FlxUIInputText;
	var gfInput:FlxUIInputText;

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
		};

		var check_mute_inst = new FlxUICheckBox(10, 200, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

        var check_waveform = new FlxUICheckBox(10, 220, null, null, "Show Waveform (vocals)", 100);
        check_waveform.checked = showWaveform;
        check_waveform.callback = function()
        {
            showWaveform = check_waveform.checked;
            updateGrid();
        };

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		#if sys
 		var directories:Array<String> = [ModPaths.modFolder('data/characters/'), Paths.getPreloadPath('data/characters/')];
 		#else
 		var directories:Array<String> = [Paths.getPreloadPath('data/characters/')];
 		#end

 		var tempMap:Map<String, Bool> = new Map<String, Bool>();
 		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

 		for (i in 0...characters.length) {
 			tempMap.set(characters[i], true);
 		}

 		#if sys
 		for (i in 0...directories.length) {
 			var directory:String = directories[i];
			if(ModPaths.isDirectory(directory)) {
				for (file in ModPaths.readDirectory(directory)) {
					var path = directory + (directory.endsWith('/') ? '' : '/') + file;
					if (!ModPaths.isDirectory(path) && file.endsWith('.json')) {
 						var charToCheck:String = file.substr(0, file.length - 5);
 						if(!charToCheck.endsWith('-dead') && !tempMap.exists(charToCheck)) {
 							tempMap.set(charToCheck, true);
 							characters.push(charToCheck);
 						}
 					}
 				}
 			}
 		}
 		#end

		var player1DropDown = new FlxUIDropDownMenu(10, 120, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
            updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;

        var playerText:FlxText = new FlxText(player1DropDown.x, player1DropDown.y - 15, FlxG.width, "Player", 8);

		var player2DropDown = new FlxUIDropDownMenu(140, 120, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
            updateHeads();
		});

		player2DropDown.selectedLabel = _song.player2;

        var opponentText:FlxText = new FlxText(player2DropDown.x, player2DropDown.y - 15, FlxG.width, "Opponent", 8);

        stageInput = new FlxUIInputText(10, 160, 120, _song.stage != null ? _song.stage : "", 8);
		var opText:FlxText = new FlxText(stageInput.x, stageInput.y - 15, FlxG.width, "Stage", 8);

        gfInput = new FlxUIInputText(140, 160, 120, _song.gfVersion != null ? _song.gfVersion : "", 8);
		var opText2:FlxText = new FlxText(gfInput.x, gfInput.y - 15, FlxG.width, "Gf", 8);

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(check_waveform);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(stageInput);
		tab_group_song.add(opText);
		tab_group_song.add(gfInput);
		tab_group_song.add(opText2);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(playerText);
		tab_group_song.add(player2DropDown);
		tab_group_song.add(opponentText);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(funnyCamObj);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

    function addSectionUI():Void
    {
        var tab_group_section = new FlxUI(null, UI_box);
        tab_group_section.name = 'Section';

        var textLength:FlxText = new FlxText(5, 10, 0, "Section Length:");
        stepperLength = new FlxUINumericStepper(10, 25, 4, 16, 4, 999, 0);
        stepperLength.name = "section_length";

        check_mustHitSection = new FlxUICheckBox(10, 55, null, null, "Must Hit Section", 100);
        check_mustHitSection.name = 'check_mustHit';

        check_changeBPM = new FlxUICheckBox(10, 85, null, null, 'Change BPM', 100);
        check_changeBPM.name = 'check_changeBPM';

        var textBPM:FlxText = new FlxText(5, 115, 0, "Section BPM:");
        stepperSectionBPM = new FlxUINumericStepper(10, 130, 1, Conductor.bpm, 0, 999, 0);
        stepperSectionBPM.name = 'section_bpm';

        var textCopy:FlxText = new FlxText(105, 10, 0, "Copy from (idx):");
        var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 25, 1, 1, -999, 999, 0);

        var copyButton:FlxButton = new FlxButton(110, 50, "Copy Section", function() {
            copySection(Std.int(stepperCopy.value));
        });

        var swapSection:FlxButton = new FlxButton(110, 80, "Swap Side", function() {
            for (i in 0..._song.notes[curSection].sectionNotes.length) {
                var note = _song.notes[curSection].sectionNotes[i];
                note[1] = (note[1] + 4) % 8;
                _song.notes[curSection].sectionNotes[i] = note;
            }
            updateGrid();
        });

        var clearSectionButton:FlxButton = new FlxButton(10, 170, "Clear Section", clearSection);
        clearSectionButton.color = 0xFFFF6666;
        clearSectionButton.label.color = FlxColor.WHITE;

        var clearSongButton:FlxButton = new FlxButton(110, 170, "Clear Song", clearSong);
        clearSongButton.color = 0xFFFF0000;
        clearSongButton.label.color = FlxColor.WHITE;

        check_altAnim = new FlxUICheckBox(10, 210, null, null, "Alt Animation", 100);
        check_altAnim.name = 'check_altAnim';

        tab_group_section.add(textLength);
        tab_group_section.add(stepperLength);
        tab_group_section.add(textBPM);
        tab_group_section.add(stepperSectionBPM);
        tab_group_section.add(textCopy);
        tab_group_section.add(stepperCopy);
        tab_group_section.add(check_mustHitSection);
        tab_group_section.add(check_altAnim);
        tab_group_section.add(check_changeBPM);
        tab_group_section.add(copyButton);
        tab_group_section.add(swapSection);
        tab_group_section.add(clearSectionButton);
        tab_group_section.add(clearSongButton);

        UI_box.addGroup(tab_group_section);
    }

	var stepperSusLength:FlxUINumericStepper;
	var inputNoteType:FlxUIInputText;

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var noteTypeLabel = new FlxText(10, 40, 100, "Note Type:");
		noteTypeLabel.setFormat(null, 8, 0xFFFFFF, "left");

		inputNoteType = new FlxUIInputText(10, 60, 100, "", 8);
		inputNoteType.name = 'note_type';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(noteTypeLabel);
		tab_group_note.add(inputNoteType);
		tab_group_note.add(applyLength);

		UI_box.addGroup(tab_group_note);
	}

	function loadSong(daSong:String):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		FlxG.sound.playMusic(Paths.inst(daSong), 0.6);

		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function()
		{
			vocals.pause();
			vocals.time = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
		/* 
			var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
			loopCheck.checked = curNoteSelected.doesLoop;
			tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
			bullshitUI.add(loopCheck);

		 */
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
				    recordUndoState();
				    _song.notes[curSection].mustHitSection = check.checked;
					updateHeads();
				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = Std.int(nums.value);
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(nums.value));
			}
			else if (wname == 'note_susLength')
			{
				curSelectedNote[2] = nums.value;
				updateGrid();
			}
			else if (wname == 'note_type')
			{
				curSelectedNote[3] = nums.value;
				updateGrid();
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSection].bpm = Std.int(nums.value);
				updateGrid();
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == stageInput) {
				_song.stage = stageInput.text != "" ? stageInput.text : null;
			} else if (sender == gfInput) {
				_song.gfVersion = gfInput.text != "" ? gfInput.text : null;
			}
		}
		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (_song.notes[curSection].changeBPM)
				return _song.notes[curSection].lengthInSteps * (_song.notes[curSection].bpm / _song.bpm);
			else
				return _song.notes[curSection].lengthInSteps;
	}*/
	function sectionStartTime(?section:Int):Float
	{
		if (section == null)
			section = curSection;

		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...section)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = typingShit.text;

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));
		funnyCamObj.y = strumLine.y;

		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1))
		{
			if (_song.notes[curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		if (curStep < 16 * curSection && _song.notes[curSection - 1] != null) {
			changeSection(curSection - 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

        var mouseOverlappingNote:Bool = false;
        curRenderedNotes.forEachAlive(function(n:Note) {
            if (FlxG.mouse.overlaps(n)) mouseOverlappingNote = true;
        });

        var isMouseOverAnyGrid:Bool = (FlxG.mouse.x >= 0 && FlxG.mouse.x <= gridBG.width) || (FlxG.mouse.x < 0 && FlxG.mouse.x >= -40);

        if (FlxG.keys.pressed.SHIFT && FlxG.mouse.justPressed && isMouseOverAnyGrid && !mouseOverlappingNote) {
            isSelecting = true;
            startMousePos.set(FlxG.mouse.x, FlxG.mouse.y);
            selectionBox.visible = true;

            for (note in selectedNotesGroup) if (note != null) note.shader = null;
            selectedNotesGroup = []; 

            for (ev in selectedEventsGroup) if (ev != null) ev.shader = null;
            selectedEventsGroup = [];

            oldSelectionData = [];
        }

        if (FlxG.mouse.justPressed && !FlxG.keys.pressed.SHIFT && !isSelecting) 
        {
            if (!mouseOverlappingNote) {
                for (note in selectedNotesGroup) if (note != null) note.shader = null;
                selectedNotesGroup = [];

				for (ev in selectedEventsGroup) if (ev != null) ev.shader = null;
				selectedEventsGroup = [];

                oldSelectionData = [];
                updateGrid(); 
            }
        }

        if (isSelecting) {
            var minX = Math.min(FlxG.mouse.x, startMousePos.x);
            var minY = Math.min(FlxG.mouse.y, startMousePos.y);
            var maxX = Math.max(FlxG.mouse.x, startMousePos.x);
            var maxY = Math.max(FlxG.mouse.y, startMousePos.y);

            selectionBox.x = minX;
            selectionBox.y = minY;
            selectionBox.scale.set(Math.max(1, maxX - minX), Math.max(1, maxY - minY));
            selectionBox.updateHitbox();

            if (FlxG.mouse.justReleased) {
                isSelecting = false;
                selectionBox.visible = false;

                curRenderedNotes.forEachAlive(function(note:Note) {
                    if (selectionBox.getHitbox().overlaps(note.getHitbox())) {
                        if (!selectedNotesGroup.contains(note)) {
                            selectedNotesGroup.push(note);
                            note.shader = selectShader;
                        }
                    }
                });

                curRenderedEvents.forEachAlive(function(event:Event) {
                    if (selectionBox.getHitbox().overlaps(event.getHitbox())) {
                        if (!selectedEventsGroup.contains(event)) {
                            selectedEventsGroup.push(event);
                            event.shader = selectShader;
                        }
                    }
                });
            }
        }

        var movedSomething:Bool = false;

        if ((selectedNotesGroup.length > 0 || selectedEventsGroup.length > 0) && !typingShit.hasFocus && !isSelecting) {
            var moveTime:Bool = FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN;
            var moveData:Bool = FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT;

            if (moveTime || moveData)  {
                recordUndoState();
                movedSomething = true;
                var multiplier:Int = (FlxG.keys.justPressed.UP) ? -1 : 1;
                var shouldChangeSection:Int = 0;

                var newNoteSelectionData:Array<{time:Float, data:Int}> = [];
                var nextEventSelectionTimes:Array<Float> = [];

                if (selectedNotesGroup.length > 0) {
                    for (noteObject in selectedNotesGroup) {
                        var actualCol:Int = Math.floor(noteObject.x / GRID_SIZE);
                        var foundInSong:Bool = false;
                        for (sec in 0..._song.notes.length) {
                            for (songNote in _song.notes[sec].sectionNotes) {
                                if (Math.abs(songNote[0] - noteObject.strumTime) < 2 && Std.int(songNote[1]) == actualCol) {
                                    if (moveTime) {
                                        songNote[0] += Conductor.stepCrochet * multiplier;
                                        var start:Float = sectionStartTime(sec);
                                        var end:Float = start + (_song.notes[sec].lengthInSteps * Conductor.stepCrochet);
                                        if (songNote[0] < start && sec > 0) {
                                            _song.notes[sec - 1].sectionNotes.push(songNote);
                                            _song.notes[sec].sectionNotes.remove(songNote);
                                            if (sec == curSection) shouldChangeSection = -1;
                                        } else if (songNote[0] >= end && sec < _song.notes.length - 1) {
                                            _song.notes[sec + 1].sectionNotes.push(songNote);
                                            _song.notes[sec].sectionNotes.remove(songNote);
                                            if (sec == curSection) shouldChangeSection = 1;
                                        }
                                    }
                                    if (moveData) {
                                        var addCol:Int = (FlxG.keys.justPressed.RIGHT) ? 1 : -1;
                                        songNote[1] = (Std.int(songNote[1]) + addCol) % 8;
                                        if (songNote[1] < 0) songNote[1] = 7;
                                    }
                                    newNoteSelectionData.push({time: songNote[0], data: Std.int(songNote[1])});
                                    foundInSong = true; break;
                                }
                            }
                            if (foundInSong) break;
                        }
                    }
                }

                if (selectedEventsGroup.length > 0 && moveTime) {
                    for (ev in selectedEventsGroup) {
                        ev.thisEvent.strumtime += Conductor.stepCrochet * multiplier;
                        if (ev.thisEvent.strumtime < 0) ev.thisEvent.strumtime = 0;

                        nextEventSelectionTimes.push(ev.thisEvent.strumtime);

                        var start:Float = sectionStartTime(curSection);
                        var end:Float = start + (_song.notes[curSection].lengthInSteps * Conductor.stepCrochet);
                        if (ev.thisEvent.strumtime < start && curSection > 0) shouldChangeSection = -1;
                        else if (ev.thisEvent.strumtime >= end && curSection < _song.notes.length - 1) shouldChangeSection = 1;
                    }
                }

                oldSelectionData = newNoteSelectionData;
                if (shouldChangeSection != 0) {
                    curSection += shouldChangeSection;
                    if (shouldChangeSection == -1) {
                        var sectionLen:Float = _song.notes[curSection].lengthInSteps * Conductor.stepCrochet;
                        Conductor.songPosition = sectionStartTime(curSection) + sectionLen - Conductor.stepCrochet;
                    } else {
                        Conductor.songPosition = sectionStartTime(curSection);
                    }
                    FlxG.sound.music.time = Conductor.songPosition;
                }

                updateGrid(); 

                selectedNotesGroup = [];
                selectedEventsGroup = [];

                var reselectNote = function(n:Note) {
                    var visualCol:Int = Math.floor(n.x / GRID_SIZE);
                    for (sel in newNoteSelectionData) {
                        if (Math.abs(sel.time - n.strumTime) < 2 && sel.data == visualCol) {
                            n.shader = selectShader;
                            if (!selectedNotesGroup.contains(n)) selectedNotesGroup.push(n);
                        }
                    }
                };

                var reselectEvent = function(e:Event) {
                    for (t in nextEventSelectionTimes) {
                        if (Math.abs(e.thisEvent.strumtime - t) < 2) {
                            e.shader = selectShader;
                            if (!selectedEventsGroup.contains(e)) selectedEventsGroup.push(e);
                        }
                    }
                };

                curRenderedNotes.forEachAlive(reselectNote);
                curRenderedEvents.forEachAlive(reselectEvent);

                if (ignoreRenderShit != null) {
                    ignoreRenderShit.forEachAlive(function(basic:flixel.FlxBasic) {
                        if (Std.isOfType(basic, Note)) reselectNote(cast(basic, Note));
                        if (Std.isOfType(basic, Event)) reselectEvent(cast(basic, Event));
                    });
                }
            }
        }

        if (FlxG.keys.justPressed.BACKSPACE && !typingShit.hasFocus) {
            var deletedAnything:Bool = false;

            if (selectedNotesGroup.length > 0 || selectedEventsGroup.length > 0) {
                recordUndoState();
            }

            if (selectedNotesGroup.length > 0) {
                for (note in selectedNotesGroup) {
                    for (songNote in _song.notes[curSection].sectionNotes) {
                        var actualCol:Int = Math.floor(note.x / GRID_SIZE);
                        if (Math.abs(songNote[0] - note.strumTime) < 2 && songNote[1] == actualCol) {
                            _song.notes[curSection].sectionNotes.remove(songNote);
                            break;
                        }
                    }
                }
                selectedNotesGroup = [];
                deletedAnything = true;
            }

            if (selectedEventsGroup.length > 0) {
                var timesToRemove:Array<Float> = [];
                for (ev in selectedEventsGroup) timesToRemove.push(ev.thisEvent.strumtime);

                _song.events = _song.events.filter(function(e) {
                    for (time in timesToRemove) {
                        if (Math.abs(e.strumtime - time) < 2) return false;
                    }
                    return true;
                });

                selectedEventsGroup = [];
                deletedAnything = true;
            }

            if (deletedAnything) {
                oldSelectionData = [];
                updateGrid();
            }
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C && selectedNotesGroup.length > 0) {
            copyBuffer = [];
            for (note in selectedNotesGroup) {
                for (songNote in _song.notes[curSection].sectionNotes) {
                    var actualCol:Int = Math.floor(note.x / GRID_SIZE);
                    if (Math.abs(songNote[0] - note.strumTime) < 2 && songNote[1] == actualCol) {
                        var noteType:String = (songNote.length > 3) ? songNote[3] : "";
                        copyBuffer.push([songNote[0], songNote[1], songNote[2], noteType]);
                        break;
                    }
                }
            }
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V && copyBuffer.length > 0) {
            var minTime:Float = copyBuffer[0][0];
            for (n in copyBuffer) if (n[0] < minTime) minTime = n[0];

            for (n in copyBuffer) {
                var newTime:Float = curStep * Conductor.stepCrochet + (n[0] - minTime);
                var newData:Int = n[1];
                var newSus:Float = n[2];
                var newType:String = ""; 
                if (n.length > 3 && n[3] != null) {
                    newType = n[3];
                }
                _song.notes[curSection].sectionNotes.push([newTime, newData, newSus, newType]);
            }
            updateGrid();
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z && !typingShit.hasFocus) {
            undo();
        }
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y && !typingShit.hasFocus) {
            redo();
        }

		if (FlxG.keys.justPressed.SPACE && !typingShit.hasFocus)
		{
			if (FlxG.sound.music.playing)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}
			else
			{
				vocals.play();
				FlxG.sound.music.play();
			}
		}

		if (!typingShit.hasFocus && !FlxG.mouse.overlaps(UI_box))
		{
			if (!FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();
	
					var daTime:Float = 700 * FlxG.elapsed;
	
					if (FlxG.keys.pressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;
	
					vocals.time = FlxG.sound.music.time;
				}
			}
			else
			{
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
				{
					FlxG.sound.music.pause();
					vocals.pause();
	
					var daTime:Float = Conductor.stepCrochet * 2;
	
					if (FlxG.keys.justPressed.W)
					{
						FlxG.sound.music.time -= daTime;
					}
					else
						FlxG.sound.music.time += daTime;
	
					vocals.time = FlxG.sound.music.time;
					
				}
			}
		}

		if (!isSelecting && FlxG.mouse.x <= gridBG.width && FlxG.mouse.x >= 0)
		{
			if (FlxG.mouse.justPressed)
				{
					if (FlxG.mouse.overlaps(curRenderedNotes))
					{
						curRenderedNotes.forEach(function(note:Note)
						{
							if (FlxG.mouse.overlaps(note))
							{
								if (FlxG.keys.pressed.CONTROL)
								{
									selectNote(note);
								}
								else
								{
									deleteNote(note);
								}
							}
						});
					}
					else
					{
						if (FlxG.mouse.x > gridBG.x
							&& FlxG.mouse.x < gridBG.x + gridBG.width
							&& FlxG.mouse.y > gridBG.y
							&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
						{
							FlxG.log.add('added note');
							addNote();
						}
					}
				}

                if (FlxG.mouse.x > gridBG.x && FlxG.mouse.x < gridBG.x + gridBG.width) {
                    dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
                    if (FlxG.keys.pressed.ALT) 
                        dummyArrow.y = FlxG.mouse.y;
                    else
                        dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
				}

				if (FlxG.keys.justPressed.ENTER)
				{
					lastSection = curSection;
					PlayState.SONG = _song;
					FlxG.sound.music.stop();
					vocals.stop();
					FlxG.switchState(new PlayState());
				}

				if (FlxG.keys.justPressed.E)
				{
					changeNoteSustain(Conductor.stepCrochet);
				}
				if (FlxG.keys.justPressed.Q)
				{
					changeNoteSustain(-Conductor.stepCrochet);
				}

				if (FlxG.keys.justPressed.TAB)
				{
					if (FlxG.keys.pressed.SHIFT)
					{
						UI_box.selected_tab -= 1;
						if (UI_box.selected_tab < 0)
							UI_box.selected_tab = 2;
					}
					else
					{
						UI_box.selected_tab += 1;
						if (UI_box.selected_tab >= 3)
							UI_box.selected_tab = 0;
					}
				}

				if (!typingShit.hasFocus)
				{		
					if (FlxG.keys.justPressed.R)
					{
						if (FlxG.keys.pressed.SHIFT)
							resetSection(true);
						else
							resetSection();
					}
		
					if (FlxG.mouse.wheel != 0)
					{
						FlxG.sound.music.pause();
						vocals.pause();
		
						FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
						vocals.time = FlxG.sound.music.time;
					}
				}

                var shiftThing:Int = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
                if (!movedSomething && !typingShit.hasFocus) {
                    if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
                        changeSection(curSection + shiftThing, true);
                    if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
                        changeSection(curSection - shiftThing, true);
                }
		}

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C && selectedEventsGroup.length > 0) {
            copyBufferEvents = [];
            for (ev in selectedEventsGroup) {
                copyBufferEvents.push([
                    ev.thisEvent.strumtime,
                    ev.thisEvent.event,
                    ev.thisEvent.variable1,
                    ev.thisEvent.variable2
                ]);
            }
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V && copyBufferEvents.length > 0) {
            var minTime:Float = copyBufferEvents[0][0];
            for (e in copyBufferEvents) if (e[0] < minTime) minTime = e[0];

            for (e in copyBufferEvents) {
                var newTime:Float = curStep * Conductor.stepCrochet + (e[0] - minTime);
                var newEventData = {
                    strumtime: newTime,
                    event: e[1],
                    variable1: e[2],
                    variable2: e[3]
                };
                _song.events.push(newEventData);
            }
            updateGrid();
        }

		if (!isSelecting && FlxG.mouse.x < 0 && FlxG.mouse.x >= -40 && FlxG.mouse.y >= eventGridBG.y && FlxG.mouse.y < eventGridBG.height) {
			dummyArrow.x = eventGridBG.x;

			if (FlxG.keys.pressed.ALT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;

			if (FlxG.mouse.justPressed) {
				if (FlxG.mouse.overlaps(curRenderedEvents)) {
					curSelectedEvents = [];

					curRenderedEvents.forEach(function(event:Event) {
						if (FlxG.mouse.overlaps(event)) {
							if (FlxG.keys.pressed.CONTROL) {
                                var strum = event.thisEvent.strumtime;
                                curSelectedEvents = _song.events.filter(function(e) return Math.abs(e.strumtime - strum) < 2);
                                curEditingEventIndex = 0;
								loadCurEvent();
							} else {
								deleteEvent(event);
							}
						}
					});
				} else {
					UI_box.selected_tab_id = 'Events';
					addEvent();
				}
			}

			if (FlxG.mouse.justPressedRight) {
				if (FlxG.mouse.overlaps(curRenderedEvents)) {
					curSelectedEvents = [];
					curRenderedEvents.forEach(function(event:Event) {
						if (FlxG.mouse.overlaps(event)) {
                            var strum = event.thisEvent.strumtime;
                            curSelectedEvents = _song.events.filter(function(e) return Math.abs(e.strumtime - strum) < 2);
                            curEditingEventIndex = 0;
							loadCurEvent();
						}
					});
				}
			}
		}

		_song.bpm = tempBpm;

		bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
		    + " / "
		    + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
		    + "\nSection: "
		    + Std.string(curSection)
		    + "\nStep: "
		    + Std.string(curStep)
		    + "\nBeat: "
		    + Std.string(curBeat);
		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (_song.notes[sec] != null)
		{
			curSection = sec;

            if (_song.notes[curSection] != null) {
                var sectionData = _song.notes[curSection];
                if (Reflect.hasField(sectionData, "sectionBeats")) {
                    var beats = Reflect.field(sectionData, "sectionBeats");
                    if (sectionData.lengthInSteps == 0 || sectionData.lengthInSteps == -1) {
                         sectionData.lengthInSteps = Std.int(beats * 4);
                    }
                }
                stepperLength.value = sectionData.lengthInSteps;
            }

			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();
				vocals.pause();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			// updateGrid();
			updateSectionUI();
		}
	}

	function copySection(?sectionNum:Int = 1)
	{
		recordUndoState();

		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

    function generateWaveform():Void
    {
        if (waveformSprite == null) return;

        waveformSprite.pixels.fillRect(
            new openfl.geom.Rectangle(0, 0, waveformSprite.width, waveformSprite.height), 
            0x00000000
        );

        if (!showWaveform) return;

        for (i in -1...2) 
        {
            var sectionIdx:Int = curSection + i;
            if (sectionIdx >= 0 && sectionIdx < _song.notes.length) 
            {
                drawSectionWaveform(sectionIdx, i + 1);
            }
        }

        waveformSprite.dirty = true;
        waveformSprite.y = gridBG.y - gridBG.height;
    }

    function drawSectionWaveform(sec:Int, blockIdx:Int):Void
    {
        var st:Float = 0;
        for (i in 0...sec) st += _song.notes[i].lengthInSteps * Conductor.stepCrochet;
        var et:Float = st + (_song.notes[sec].lengthInSteps * Conductor.stepCrochet);

        var tempWavData:Array<Array<Array<Float>>> = [
            [new Array<Float>(), new Array<Float>()], 
            [new Array<Float>(), new Array<Float>()]
        ];

        @:privateAccess
        if (_song.needsVoices && vocals != null && vocals._sound != null) {
            var buffer = vocals._sound.__buffer;
            if (buffer != null) {
                tempWavData = getWaveformData(buffer, buffer.data, st, et, 0.8, tempWavData, gridBG.height);
            }
        }

        var hWidth:Int = Std.int(gridBG.width / 2);
        var yOffset:Float = blockIdx * gridBG.height;

        for (i in 0...Std.int(gridBG.height)) {
            var lmin:Float = 0; var lmax:Float = 0;
            var rmin:Float = 0; var rmax:Float = 0;

            if (i < tempWavData[0][0].length) lmin = tempWavData[0][0][i];
            if (i < tempWavData[0][1].length) lmax = tempWavData[0][1][i];
            if (i < tempWavData[1][0].length) rmin = tempWavData[1][0][i];
            if (i < tempWavData[1][1].length) rmax = tempWavData[1][1][i];

            var leftSize:Float = (lmin + lmax) * hWidth;
            var rightSize:Float = (rmin + rmax) * hWidth;
            var finalWidth:Float = leftSize + rightSize;
            if (finalWidth < 1) finalWidth = 1;

            waveformSprite.pixels.fillRect(
                new openfl.geom.Rectangle(hWidth - leftSize, yOffset + i, finalWidth, 1),
                waveColor
            );
        }
    }
    
    function getWaveformData(buffer:Dynamic, bytes:lime.utils.UInt8Array, time:Float, endTime:Float, multiply:Float, array:Array<Array<Array<Float>>>, steps:Float):Array<Array<Array<Float>>>
    {
        var khz:Float = (buffer.sampleRate / 1000);
        var channels:Int = buffer.channels;
        var index:Int = Std.int(time * khz);
        var samplesToProcess:Float = (endTime - time) * khz;
        var samplesPerRow:Float = samplesToProcess / steps;

        var gotIndex:Int = 0;
        var rows:Float = 0;
        var lmin:Float = 0; var lmax:Float = 0;
        var rmin:Float = 0; var rmax:Float = 0;

        while (index < (bytes.length / (channels * 2)) && gotIndex < steps) {
            var byteIdx:Int = index * channels * 2;
            if (byteIdx + 1 < bytes.length) {
                var raw:Int = (bytes[byteIdx + 1] << 8) | bytes[byteIdx];
                if (raw > 32767) raw -= 65536;
                var sample:Float = raw / 32768;

                if (sample > 0) { if (sample > lmax) lmax = sample; }
                else { if (sample < lmin) lmin = Math.abs(sample); }

                if (channels >= 2 && byteIdx + 3 < bytes.length) {
                    var rawR:Int = (bytes[byteIdx + 3] << 8) | bytes[byteIdx + 2];
                    if (rawR > 32767) rawR -= 65536;
                    var sampleR:Float = rawR / 32768;
                    if (sampleR > 0) { if (sampleR > rmax) rmax = sampleR; }
                    else { if (sampleR < rmin) rmin = Math.abs(sampleR); }
                }
            }

            if (rows >= samplesPerRow) {
                if (array[0][0].length <= gotIndex) {
                    array[0][0].push(lmin * multiply);
                    array[0][1].push(lmax * multiply);
                    array[1][0].push(rmin * multiply);
                    array[1][1].push(rmax * multiply);
                } else {
                    array[0][0][gotIndex] += lmin * multiply;
                    array[0][1][gotIndex] += lmax * multiply;
                    array[1][0][gotIndex] += rmin * multiply;
                    array[1][1][gotIndex] += rmax * multiply;
                }

                lmin = 0; lmax = 0; rmin = 0; rmax = 0;
                rows = 0;
                gotIndex++;
            }

            index++;
            rows++;
        }
        return array;
    }

	function updateHeads():Void
	{
        var healthIconP1:String = loadHealthIconFromCharacter(_song.player1);
        var healthIconP2:String = loadHealthIconFromCharacter(_song.player2);

		if (check_mustHitSection.checked)
		{
			leftIcon.changeIcon(healthIconP1);
 			rightIcon.changeIcon(healthIconP2);
		}
		else
		{
			leftIcon.changeIcon(healthIconP2);
 			rightIcon.changeIcon(healthIconP1);
		}
	}

	function loadHealthIconFromCharacter(char:String) {
        var rawJson = null;

        #if sys
        var moddyFile:String = ModPaths.data("characters/" + char);
		if(ModPaths.exists(moddyFile)) {
			rawJson = ModPaths.readContent(moddyFile);
        }
        #end

        if(rawJson == null) {
            #if sys
            rawJson = sys.io.File.getContent(Paths.json("characters/" + char));
            #else
            rawJson = Assets.getText(Paths.json("characters/" + char));
            #end
        }

        var json:game.Character.CharJson = cast Json.parse(rawJson);
        return json.healthIcon;
    }

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
	}

	function updateGrid():Void
	{
        oldSelectionData = []; 

        for (note in selectedNotesGroup) {
            if (note != null) oldSelectionData.push({time: note.strumTime, data: note.noteData});
        }

        selectedNotesGroup = [];
		selectedEventsGroup = [];

		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedEvents.clear();
		ignoreRenderShit.clear();

		var sectionInfo:Array<Dynamic> = _song.notes[curSection].sectionNotes;

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes.length)
			{
				for (notesse in 0..._song.notes[sec].sectionNotes.length)
				{
					if (_song.notes[sec].sectionNotes[notesse][2] == null)
					{
						Logger.log('SUS NULL');
						_song.notes[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		*/

        if ((curSection - 1) >= 0 && _song.notes[curSection - 1] != null) {
            for (i in _song.notes[curSection - 1].sectionNotes) generateSection(i, -1, curSection);
        }
        if (curSection < _song.notes.length - 1 && _song.notes[curSection + 1] != null) {
            for (i in _song.notes[curSection + 1].sectionNotes) generateSection(i, 1, curSection);
        }
        for (i in sectionInfo) generateSection(i, 0, curSection);

        if (_song.events != null) 
        {
            var viewStart:Float = sectionStartTime(curSection - 1);
            var viewEnd:Float = sectionStartTime(curSection + 2);
            for (e in _song.events) 
            {
                if (e != null && e.strumtime >= viewStart && e.strumtime < viewEnd) 
                {
                    var visualOffset:Int = 0;
                    if (e.strumtime < sectionStartTime(curSection)) 
                        visualOffset = -1;
                    else if (e.strumtime >= sectionStartTime(curSection + 1)) 
                        visualOffset = 1;
                    generateEventSection(e, visualOffset, curSection);
                }
            }
        }

		generateWaveform();
	}

    function generateSection(i:Array<Dynamic>, ?addToSection:Int = 0, currentSection:Int) {
		var section:Int = currentSection + addToSection;

		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus = i[2];
		var noteType:String = "";
		if (i.length > 3)
			noteType = i[3];

		var note:Note = new Note(daStrumTime, daNoteInfo % 4, null, false, noteType);
		note.sustainLength = daSus;
		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.belongsToSection = section;
		note.x = Math.floor(daNoteInfo * GRID_SIZE);
		note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime(section)) % (Conductor.stepCrochet * _song.notes[section].lengthInSteps), 
			sectionBGs.members[addToSection + 1]));

		if (daSus > 0) {
			if (addToSection == 0) {
				curRenderedSustains.add(setupSusNote(note, daSus, false));
			} else {
				ignoreRenderShit.add(setupSusNote(note, daSus, true));
			}
		}

		var actualGridCol:Int = Std.int(daNoteInfo);
        note.shader = null;

        if (addToSection == 0) {
            for (old in oldSelectionData) {
                if (Math.abs(old.time - daStrumTime) < 2 && old.data == actualGridCol) {
                    note.shader = selectShader; 
                    if (!selectedNotesGroup.contains(note))
                        selectedNotesGroup.push(note);
                }
            }
        }

		if (addToSection == 0) {
			curRenderedNotes.add(note);
		} else {
			note.alpha = 0.75;
			ignoreRenderShit.add(note);
		}
	}

	function setupSusNote(note:Note, daSus:Float, isNextSection:Bool):FlxSprite {
		var height:Int = Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, (gridBG.height)));
		var minHeight:Int = Std.int((GRID_SIZE / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		if(height < 1) height = 1;

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		if (isNextSection)
			spr.alpha = 0.75;
		return spr;
	}

	function generateEventSection(i:ChartEvent, ?addToSection:Int = 0, currentSection:Int) {
		var section:Int = currentSection + addToSection;

		var event:Event = new Event(i);
		event.setGraphicSize(GRID_SIZE, GRID_SIZE);
		event.updateHitbox();
		event.x = -40;
		event.y = Math.floor(getYfromStrum((i.strumtime - sectionStartTime(section)) % (Conductor.stepCrochet * _song.notes[section].lengthInSteps),
            eventSectionBGs.members[addToSection + 1]));

		if (addToSection == 0) {
			curRenderedEvents.add(event);
		} else {
			event.alpha = 0.75;
			ignoreRenderShit.add(event);
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i.strumTime == note.strumTime && i.noteData % 4 == note.noteData)
			{
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
			}

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
	}

    function deleteNote(note:Note):Void
    {
        recordUndoState();
        var col:Int = Math.floor(note.x / GRID_SIZE);
        for (songNote in _song.notes[curSection].sectionNotes)
        {
            if (Math.abs(songNote[0] - note.strumTime) < 2 && songNote[1] == col)
            {
                _song.notes[curSection].sectionNotes.remove(songNote);
                break;
            }
        }
        updateGrid();
    }

	function clearSection():Void
	{
		recordUndoState();
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void
	{
		recordUndoState();
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote():Void
	{
		recordUndoState();
		var noteStrum:Float = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData:Int = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteSus:Float = 0;
		var noteType:String = inputNoteType.text;

		_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, noteType]);

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL)
		{
			_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteType]);
		}

		updateGrid();
		updateNoteUI();

		autosaveSong();
	}

    private function addEvent():Void {
        recordUndoState();
        if (_song.events == null) _song.events = [];

        var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();

        var newEvent:ChartEvent = {
            strumtime: noteStrum,
            event: eventDropDown.selectedLabel,
            variable1: eventVar1.text,
            variable2: eventVar2.text
        };

        _song.events.push(newEvent);
        _song.events.sort(function(a, b) return Reflect.compare(a.strumtime, b.strumtime));

        updateGrid();
        autosaveSong();
    }

    function deleteEvent(event:Event):Void {
        recordUndoState();
        if (_song.events != null) {
            _song.events.remove(event.thisEvent);
        }
        updateGrid();
    }

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, ?grid:FlxSprite):Float
	{
		if (grid == null)
			grid = gridBG;

		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, grid.y, grid.y + grid.height);
	}

	/*
		function calculateSectionLengths(?sec:SwagSection):Int
		{
			var daLength:Int = 0;

			for (i in _song.notes)
			{
				var swagLength = i.lengthInSteps;

				if (i.typeOfSection == Section.COPYCAT)
					swagLength * 2;

				daLength += swagLength;

				if (sec != null && sec == i)
				{
				    Logger.log('swag loop??');
					break;
				}
			}

			return daLength;
	}*/
	private var daSpacing:Float = 0.3;

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
		FlxG.resetState();
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel()
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(openfl.events.Event.COMPLETE, onSaveComplete);
			_file.addEventListener(openfl.events.Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(openfl.events.Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(openfl.events.Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(openfl.events.Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(openfl.events.Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(openfl.events.Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(openfl.events.Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}
