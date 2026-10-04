package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;

class OptionsState extends MusicBeatState {
	var options:Array<String> = ['Preferences', 'Controls', 'Exit'];

	private static var curSelected:Int = 0;
	private var grpOptions:FlxTypedGroup<Alphabet>;

    override function create() {
		#if desktop
		DiscordClient.changePresence("In the Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length) {
            var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
            optionText.screenCenter();
            optionText.y += (100 * (i - (options.length / 2))) + 50;
            grpOptions.add(optionText);
        }

		changeSelection();
		Config.save();
		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		Config.save();
	}

	override function update(elapsed:Float) {
        if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);
		if (controls.ACCEPT)
			openSelectedOption(options[curSelected]);
		if (controls.BACK) {
			#if sys
			scriptState.callFunction("goToMenu", []);
			#end
            FlxG.switchState(new MainMenuState());
		}
		super.update(elapsed);
    }

	function openSelectedOption(label:String) {
		switch(label) {
			case 'Preferences':
                openSubState(new PreferencesSubstate());
			case 'Controls':
				openSubState(new substates.KeyBindMenu());
			case 'Exit':
				#if sys
				scriptState.callFunction("goToMenu", []);
				#end
                FlxG.switchState(new MainMenuState());
		}
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;
		var bullShit:Int = 0;
		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}

class PreferencesSubstate extends MusicBeatSubstate
{
	private static var curSelected:Int = 0;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxArray:Array<CheckboxThingie> = [];
	private var checkboxNumber:Array<Int> = [];
	private var descText:FlxText;
	private var bg:FlxSprite;

	public static var baseOptions:Array<Option> = [
		{ name: 'GAMEPLAY', value: false, isUnselectable: true },
		{ name: 'Scroll Layout', value: 'Up', isUnselectable: false, type: OptionType.STRING, values: ['Up', 'Down', 'Middle', 'Down + Middle'] },
		{ name: 'BotPlay', value: false, isUnselectable: false },
		{ name: 'Ghost Tapping', value: false, isUnselectable: false },
		{ name: 'VISUALS', value: false, isUnselectable: true },
		{ name: 'Note Splashes', value: false, isUnselectable: false },
		{ name: 'Flashing Menu', value: false, isUnselectable: false },
		{ name: 'Camera Zooms', value: false, isUnselectable: false },
		#if !mobile
		{ name: 'FPS', value: false, isUnselectable: true },
		{ name: 'FPS Counter', value: false, isUnselectable: false },
		{ name: 'FPS Cap', value: 60, isUnselectable: false, type: OptionType.INT, min: 30, max: 240, step: 1 },
		#end
		#if sys
		{ name: 'MODS', value: false, isUnselectable: true },
		{ name: 'Automatically Enable New Mods', value: true, isUnselectable: false },
		#end
	];

	static var options:Array<Option> = [];

	public function new()
	{
		super();

	    bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		buildOptions();

		for (i in 0...options.length)
		{
			var isCentered:Bool = options[i].isUnselectable;
			var optionLabel:String = getOptionLabel(options[i]);

			var optionText:Alphabet = new Alphabet(0, 70 * i, optionLabel, false, false);
			optionText.isMenuItem = true;

			if (isCentered)
			{
				optionText.screenCenter(X);
				optionText.forceX = optionText.x;
			}
			else
			{
				var xOffset:Float = 300;
				if (options[i].type == OptionType.INT || options[i].type == OptionType.FLOAT || options[i].type == OptionType.STRING)
				{
					xOffset = 180;
				}
				optionText.x += xOffset;
				optionText.forceX = xOffset;
			}

			optionText.yMult = 90;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (!isCentered && (options[i].type == null || options[i].type == OptionType.BOOL))
			{
				var useCheckbox:Bool = true;
				if (useCheckbox)
				{
					var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, false);
					checkbox.sprTracker = optionText;
					checkboxArray.push(checkbox);
					checkboxNumber.push(i);
					add(checkbox);
				}
			}
		}

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		for (i in 0...options.length)
		{
			if (!options[i].isUnselectable)
			{
				curSelected = i;
				break;
			}
		}

		changeSelection();
		reloadValues();
	}

    function buildOptions():Void {
        options = baseOptions.copy();

        #if sys
        var activeMods = [ for (modFolder in ModPaths.getModFolders()) if (modFolder.enabled) modFolder.folder ];

        for (mods in activeMods) {
			var folder = ModPaths.modPath(mods, 'data/options');
			if (!ModPaths.isDirectory(folder)) continue;

			var files = ModPaths.readDirectory(folder);
            var jsonFiles = [ for (f in files) if (StringTools.endsWith(f, '.json')) f ];

            for (i in (options.length - 1)...0) {
                var opt = options[i];
                if (opt.modSource != mods) continue;

                var base = opt.name + '.json';
                if (jsonFiles.indexOf(base, 0) == -1) {
                    options.splice(i, 1);
                }
            }

            for (f in jsonFiles) {
                var name = f.substr(0, f.length - 5);
                var existsOpt = false;
                for (opt in options) {
                    if (opt.modSource == mods && opt.name == name) {
                        existsOpt = true;
                        break;
                    }
                }
                if (!existsOpt) {
					var jsonPath = ModPaths.modPath(mods, 'data/options/' + f);
					var content = ModPaths.readContent(jsonPath);
                    var parsed = haxe.Json.parse(content);
                    for (item in (cast parsed : OptionsData).options) {
                        var syncedOption:Option = Config.syncCustomOption({
                            name: item.name,
                            value: item.value,
                            isUnselectable: item.isUnselectable,
                            modSource: mods,
                            type: item.type == null ? OptionType.BOOL : item.type,
                            values: item.values,
                            min: item.min,
                            max: item.max,
                            step: item.step,
                            description: item.description
                        });
                        options.push({
                            name: syncedOption.name,
                            value: syncedOption.value,
                            isUnselectable: syncedOption.isUnselectable,
                            modSource: syncedOption.modSource,
                            type: syncedOption.type == null ? OptionType.BOOL : syncedOption.type,
                            values: syncedOption.values,
                            min: syncedOption.min,
                            max: syncedOption.max,
                            step: syncedOption.step,
                            description: syncedOption.description
                        });
                    }
                }
            }
        }
        #end
    }

	var nextAccept:Int = 5;
	var optionHoldTimer:Float = 0;
	var optionHoldTime:Float = 0;

	function getOptionLabel(option:Option):String {
		if (option.name == 'FPS Cap') {
			return 'FPS Cap: ' + Std.string(Config.fpsCap);
		}
		if (option.type == OptionType.FLOAT) {
			return option.name + ': ' + Std.string(Math.round(Config.getFloat(option.name) * 10) / 10);
		}
		if (option.type == OptionType.INT || option.type == OptionType.STRING) {
			return option.name + ': ' + Std.string(Config.getOptionValue(option.name));
		}
		return option.name.split('_').join('-');
	}

	function refreshOptionLabels():Void {
		for (i in 0...grpOptions.members.length) {
			if (i < options.length) {
				grpOptions.members[i].changeText(getOptionLabel(options[i]));
			}
		}
	}

	function updateDescriptionText():Void {
		var daText:String = '';
		var selectedOption:Option = options[curSelected];
		switch(selectedOption.name) {
			case 'Scroll Layout':
				daText = "Choose up, down, middle, or middle-down note layout.";
			case 'Automatically Enable New Mods':
				daText = "Automatically enable mods the first time they are detected.";
			case 'FPS Counter':
				daText = "Show the FPS counter on screen.";
			case 'FPS Cap':
				daText = "Frame limit: " + Config.fpsCap + " FPS.";
			case 'BotPlay':
				daText = "Automatically plays for you.";
			case 'MiddleScroll':
				daText = "Center the notes on the screen.";
			case 'Ghost Tapping':
				daText = "Allows tapping outside the notes.";
			case 'Flashing Menu':
				daText = "Menu animations may flash.";
			case 'Note Splashes':
				daText = "Visual burst effects when hitting notes.";
			case 'Camera Zooms':
				daText = "Camera slightly zooms in on hits.";
			default:
				if (selectedOption.description != null && selectedOption.description.length > 0) {
					daText = selectedOption.description;
				} else {
					daText = "";
				}
		}
		descText.text = daText;
	}

	function applyOptionValue(selectedOption:Option, direction:Int = 1):Void {
		var selectedName:String = selectedOption.name;
		var selectedType:OptionType = selectedOption.type == null ? OptionType.BOOL : selectedOption.type;
		var currentValue:Dynamic = Config.getOptionValue(selectedName);
		var nextValue:Dynamic = currentValue;

		switch(selectedType) {
			case OptionType.BOOL:
				nextValue = !cast(currentValue, Bool);
			case OptionType.INT:
				var current:Int = cast(currentValue, Int);
				var minValue:Int = selectedOption.min != null ? Std.int(selectedOption.min) : 0;
				var maxValue:Int = selectedOption.max != null ? Std.int(selectedOption.max) : 100;
				var stepValue:Int = selectedOption.step != null ? Std.int(selectedOption.step) : 1;
				var calc:Int = current + (stepValue * direction);
				if (calc < minValue) calc = maxValue;
				if (calc > maxValue) calc = minValue;
				nextValue = calc;
			case OptionType.FLOAT:
				var current:Float = cast(currentValue, Float);
				var stepValue:Float = selectedOption.step != null ? selectedOption.step : 0.1;
				var minValue:Float = selectedOption.min != null ? selectedOption.min : 0;
				var maxValue:Float = selectedOption.max != null ? selectedOption.max : 1;
				var calc:Float = current + (stepValue * direction);
				if (calc < minValue) calc = maxValue;
				if (calc > maxValue) calc = minValue;
				nextValue = calc;
			case OptionType.STRING:
				if (selectedOption.values != null && selectedOption.values.length > 0) {
					var currentIndex:Int = selectedOption.values.indexOf(cast(currentValue, String));
					if (currentIndex == -1) currentIndex = 0;
					currentIndex += direction;
					if (currentIndex < 0) currentIndex = selectedOption.values.length - 1;
					if (currentIndex >= selectedOption.values.length) currentIndex = 0;
					nextValue = selectedOption.values[currentIndex];
				}
		}

		Config.setOptionValue(selectedName, nextValue);
		if (selectedName == 'FPS Counter' && Main.fpsVar != null) {
			Main.fpsVar.visible = Config.showFPS;
		}
	}

	override function update(elapsed:Float)
	{
		if (controls.UP_P)
		{
			changeSelection(-1);
		}

		if (controls.DOWN_P)
		{
			changeSelection(1);
		}

        var holdDirection:Int = 0;

        if (controls.LEFT) holdDirection = -1;
        if (controls.RIGHT) holdDirection = 1;

        var pressed:Bool = controls.LEFT_P || controls.RIGHT_P;

        if (holdDirection != 0) {
        	var selectedOption:Option = options[curSelected];
        	var selectedType:OptionType = selectedOption.type == null ? OptionType.BOOL : selectedOption.type;

        	if (selectedType == OptionType.INT || selectedType == OptionType.FLOAT || selectedType == OptionType.STRING) {
        		if (pressed) {
        			optionHoldTime = 0;
        			optionHoldTimer = 0.02;

        			applyOptionValue(selectedOption, holdDirection);

        			refreshOptionLabels();
        			updateDescriptionText();
        			FlxG.sound.play(Paths.sound('scrollMenu'));
        			reloadValues();
        		} else {
        			optionHoldTime += elapsed;
        			optionHoldTimer -= elapsed;

        			var repeatDelay:Float = Math.max(0, 0.03 - optionHoldTime * 0.015);

        			if (optionHoldTimer <= 0) {
        				applyOptionValue(selectedOption, holdDirection);

        				refreshOptionLabels();
        				updateDescriptionText();
        				reloadValues();

        				optionHoldTimer = repeatDelay;
        			}
        		}
        	}
        } else {
        	optionHoldTime = 0;
        	optionHoldTimer = 0;
        }

		if (controls.BACK) {
			grpOptions.forEachAlive(function(spr:Alphabet) {
				spr.alpha = 0;
			});
			for (i in 0...checkboxArray.length) {
				var spr:CheckboxThingie = checkboxArray[i];
				if(spr != null) {
					spr.alpha = 0;
				}
			}
			bg.alpha = 0;
			descText.alpha = 0;
			close();
		}

		var usesCheckbox = true;
		if(usesCheckbox) {
			if(controls.ACCEPT && nextAccept <= 0) {
				var selectedOption:Option = options[curSelected];
				var selectedName:String = selectedOption.name;
				var selectedType:OptionType = selectedOption.type == null ? OptionType.BOOL : selectedOption.type;
				var newValue:Dynamic = Config.getOptionValue(selectedName);

				switch(selectedType) {
					case OptionType.BOOL:
						newValue = !cast(newValue, Bool);
					case OptionType.INT:
						applyOptionValue(selectedOption, 1);
						newValue = Config.getOptionValue(selectedName);
					case OptionType.FLOAT:
						applyOptionValue(selectedOption, 1);
						newValue = Config.getOptionValue(selectedName);
					case OptionType.STRING:
						applyOptionValue(selectedOption, 1);
						newValue = Config.getOptionValue(selectedName);
				}

				if (selectedType == OptionType.BOOL) {
					Config.setOptionValue(selectedName, newValue);
				}
				if (selectedName == 'FPS Counter' && Main.fpsVar != null) {
					Main.fpsVar.visible = Config.showFPS;
				}
				buildOptions(); 
				refreshOptionLabels();
				FlxG.sound.play(Paths.sound('scrollMenu'));
				reloadValues();
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}
	
	function changeSelection(change:Int = 0)
	{
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = options.length - 1;
			if (curSelected >= options.length)
				curSelected = 0;
		} while (options[curSelected].isUnselectable);

		updateDescriptionText();

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;
	
			if (!options[bullShit - 1].isUnselectable) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
				for (j in 0...checkboxArray.length) {
					var tracker:FlxSprite = checkboxArray[j].sprTracker;
					if (tracker == item) {
						checkboxArray[j].alpha = item.alpha;
						break;
					}
				}
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadValues() {
		for (i in 0...checkboxArray.length) {
			var checkbox:CheckboxThingie = checkboxArray[i];
			if(checkbox != null) {
				var optionName:String = options[checkboxNumber[i]].name;
				var optionValue:Dynamic = Config.getOptionValue(optionName);
				if (Std.isOfType(optionValue, Bool)) {
					checkbox.daValue = cast(optionValue, Bool);
				} else {
					checkbox.daValue = false;
				}
			}
		}
	}
}

class CheckboxThingie extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var daValue(default, set):Bool;
	public var offsetX:Float = 0;
	public var offsetY:Float = 38;

	public function new(x:Float = 0, y:Float = 0, ?checked = false) {
		super(x, y);

		frames = Paths.getSparrowAtlas('checkboxThingie');
		animation.addByPrefix("unchecked", "Check Box unselected", 24, false);
		animation.addByPrefix("checked", "Check Box selecting animation", 24, false);

		antialiasing = true;
		setGraphicSize(Std.int(0.9 * width));
		updateHitbox();

		set_daValue(checked);
	}

	override function update(elapsed:Float) {
		if (sprTracker != null)
			setPosition(sprTracker.x - 130 + offsetX, sprTracker.y - 30 + offsetY);
		super.update(elapsed);
	}

	private function set_daValue(check:Bool):Bool {
		if (check) {
			if(animation.curAnim.name != 'checked') {
			    animation.play('checked', true);
			    offset.set(22, 90);
			}
		} else {
			animation.play('unchecked', true);
			offset.set();
		}
		return check;
	}
}
