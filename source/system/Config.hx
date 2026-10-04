package system;

import flixel.FlxG;
import states.OptionsState;

using StringTools;

class Config {
	public static var botplay:Bool = false;
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var noteSplashes:Bool = true;
	public static var ghostTapping:Bool = true;
	public static var flashingMenu:Bool = true;
	public static var camZooms:Bool = true;
	public static var autoEnableNewMods:Bool = true;
	public static var showFPS:Bool = true;
	public static var fpsCap:Int = 60;
	public static var keyBinds:Array<String> = ['A','S','W','D','R'];
	public static var customOptions:Array<Option> = [];
	public static var optionAliases:Map<String, String> = [
		"BotPlay" => "botplay",
		"DownScroll" => "downScroll",
		"MiddleScroll" => "middleScroll",
		"Note Splashes" => "noteSplashes",
		"Ghost Tapping" => "ghostTapping",
		"Flashing Menu" => "flashingMenu",
		"Camera Zooms" => "camZooms",
		"Automatically Enable New Mods" => "autoEnableNewMods",
		"FPS Counter" => "showFPS",
		"FPS Cap" => "fpsCap"
	];

	public static function getOptionValue(optionName:String):Dynamic {
		if (optionName == "Scroll Layout") {
			if (middleScroll) return downScroll ? "Down + Middle" : "Middle";
			return downScroll ? "Down" : "Up";
		}
		if (optionAliases.exists(optionName)) {
			var fieldName:String = optionAliases.get(optionName);
			if (Reflect.hasField(Config, fieldName)) {
				return Reflect.field(Config, fieldName);
			}
		}

		for (option in customOptions) {
			if (option.name == optionName) {
				return option.value;
			}
		}

		return false;
	}

	public static function setOptionValue(optionName:String, value:Dynamic):Bool {
		if (optionName == "Scroll Layout") {
			switch (value) {
				case "Up":
					downScroll = false;
					middleScroll = false;
				case "Down":
					downScroll = true;
					middleScroll = false;
				case "Middle":
					downScroll = false;
					middleScroll = true;
				case "Down + Middle":
					downScroll = true;
					middleScroll = true;
				default:
					return false;
			}
			return true;
		}
		if (optionAliases.exists(optionName)) {
			var fieldName:String = optionAliases.get(optionName);
			if (Reflect.hasField(Config, fieldName)) {
				Reflect.setField(Config, fieldName, value);
				if (fieldName == 'fpsCap') {
					applyFrameRate();
				}
				return true;
			}
		}

		for (option in customOptions) {
			if (option.name == optionName) {
				option.value = value;
				saveCustomOptions();
				return true;
			}
		}

		return false;
	}

	public static function applyFrameRate():Void {
		FlxG.drawFramerate = fpsCap;
		FlxG.updateFramerate = fpsCap;
	}

	public static function toggleOption(optionName:String):Dynamic {
		var curValue:Dynamic = getOptionValue(optionName);
		if (Std.isOfType(curValue, Bool)) {
			var nextValue:Bool = !cast(curValue, Bool);
			setOptionValue(optionName, nextValue);
			return nextValue;
		}
		if (Std.isOfType(curValue, Int)) {
			var nextValue:Int = cast(curValue, Int) + 1;
			setOptionValue(optionName, nextValue);
			return nextValue;
		}
		if (Std.isOfType(curValue, Float)) {
			var nextValue:Float = cast(curValue, Float) + 0.1;
			setOptionValue(optionName, nextValue);
			return nextValue;
		}
		return curValue;
	}

	public static function defineOption(name:String, value:Dynamic, isUnselectable:Bool = false, type:OptionType = OptionType.BOOL, ?values:Array<String>, ?min:Float, ?max:Float, ?step:Float, ?description:String):Option {
		for (option in customOptions) {
			if (option.name == name) {
				option.value = value;
				option.isUnselectable = isUnselectable;
				option.type = type;
				if (values != null) option.values = values;
				if (min != null) option.min = min;
				if (max != null) option.max = max;
				if (step != null) option.step = step;
				if (description != null) option.description = description;
				return option;
			}
		}

		var option:Option = {
			name: name,
			value: value,
			isUnselectable: isUnselectable,
			type: type,
			values: values,
			min: min,
			max: max,
			step: step,
			description: description
		};
		customOptions.push(option);
		return option;
	}

	public static function optionBool(name:String, value:Bool = false, isUnselectable:Bool = false, ?description:String):Option {
		return defineOption(name, value, isUnselectable, OptionType.BOOL, null, null, null, null, description);
	}

	public static function optionInt(name:String, value:Int = 0, min:Int = 0, max:Int = 100, step:Int = 1, isUnselectable:Bool = false, ?description:String):Option {
		return defineOption(name, value, isUnselectable, OptionType.INT, null, min, max, step, description);
	}

	public static function optionFloat(name:String, value:Float = 0, min:Float = 0, max:Float = 1, step:Float = 0.1, isUnselectable:Bool = false, ?description:String):Option {
		return defineOption(name, value, isUnselectable, OptionType.FLOAT, null, min, max, step, description);
	}

	public static function optionString(name:String, value:String = "", values:Array<String>, isUnselectable:Bool = false, ?description:String):Option {
		return defineOption(name, value, isUnselectable, OptionType.STRING, values, null, null, null, description);
	}

	public static function getBool(name:String, defaultValue:Bool = false):Bool {
		var value:Dynamic = getOptionValue(name);
		if (Std.isOfType(value, Bool)) {
			return cast(value, Bool);
		}
		return defaultValue;
	}

	public static function getInt(name:String, defaultValue:Int = 0):Int {
		var value:Dynamic = getOptionValue(name);
		if (Std.isOfType(value, Int)) {
			return cast(value, Int);
		}
		if (Std.isOfType(value, Float)) {
			return Std.int(cast(value, Float));
		}
		return defaultValue;
	}

	public static function getFloat(name:String, defaultValue:Float = 0):Float {
		var value:Dynamic = getOptionValue(name);
		if (Std.isOfType(value, Float)) {
			return cast(value, Float);
		}
		if (Std.isOfType(value, Int)) {
			return cast(value, Int);
		}
		return defaultValue;
	}

	public static function getString(name:String, defaultValue:String = ""):String {
		var value:Dynamic = getOptionValue(name);
		if (Std.isOfType(value, String)) {
			return cast(value, String);
		}
		return defaultValue;
	}

	public static function getOption(name:String):Dynamic {
		return getOptionValue(name);
	}

	public static function setOption(name:String, value:Dynamic):Bool {
		return setOptionValue(name, value);
	}

	public static function getOptionLabel(name:String):String {
		var value:Dynamic = getOptionValue(name);
		if (Std.isOfType(value, Bool)) {
			return name + ": " + (cast(value, Bool) ? "On" : "Off");
		}
		if (Std.isOfType(value, Int)) {
			return name + ": " + Std.string(cast(value, Int));
		}
		if (Std.isOfType(value, Float)) {
			return name + ": " + Std.string(cast(value, Float));
		}
		if (Std.isOfType(value, String)) {
			return name + ": " + cast(value, String);
		}
		return name;
	}

	public static function setBool(name:String, value:Bool):Bool {
		return setOptionValue(name, value);
	}

	public static function setInt(name:String, value:Int):Bool {
		return setOptionValue(name, value);
	}

	public static function setFloat(name:String, value:Float):Bool {
		return setOptionValue(name, value);
	}

	public static function setString(name:String, value:String):Bool {
		return setOptionValue(name, value);
	}

	public static function save() {
		FlxG.save.data.botplay = botplay;
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.flashingMenu = flashingMenu;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.autoEnableNewMods = autoEnableNewMods;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.fpsCap = fpsCap;
		FlxG.save.flush();
    }

	public static function load() {
		if(FlxG.save.data.botplay != null)
			botplay = FlxG.save.data.botplay;
		if(FlxG.save.data.downScroll != null)
			downScroll = FlxG.save.data.downScroll;
		if(FlxG.save.data.middleScroll != null)
			middleScroll = FlxG.save.data.middleScroll;
		if(FlxG.save.data.noteSplashes != null)
			noteSplashes = FlxG.save.data.noteSplashes;
		if(FlxG.save.data.ghostTapping != null)
			ghostTapping = FlxG.save.data.ghostTapping;
		if(FlxG.save.data.flashingMenu != null)
			flashingMenu = FlxG.save.data.flashingMenu;
		if(FlxG.save.data.camZooms != null)
			camZooms = FlxG.save.data.camZooms;
		if(FlxG.save.data.autoEnableNewMods != null)
			autoEnableNewMods = FlxG.save.data.autoEnableNewMods;
		if(FlxG.save.data.showFPS != null) {
			showFPS = FlxG.save.data.showFPS;
			if(Main.fpsVar != null) {
				Main.fpsVar.visible = showFPS;
			}
		}
		if(FlxG.save.data.fpsCap != null) {
			fpsCap = FlxG.save.data.fpsCap;
		}
		applyFrameRate();
		loadCustomOptions();
    }

	public static function saveCustomOptions() {
		#if sys
		for (modFolder in ModPaths.getModFolders()) {
			if (modFolder.enabled) {
				var optionsDirPath:String = ModPaths.modPath(modFolder.folder, 'data/options');
				if (StringTools.startsWith(optionsDirPath, 'zip://') || !ModPaths.isDirectory(optionsDirPath)) continue;

				for (optionJson in ModPaths.readDirectory(optionsDirPath)) {
					if (optionJson != null && optionJson.endsWith('.json')) {
						var optionFilePath:String = optionsDirPath + optionJson;
						var optionsToSave:Array<{name:String, value:Dynamic, isUnselectable:Bool, type:OptionType, values:Array<String>, min:Float, max:Float, step:Float, description:String}> = [];
						for (option in customOptions) {
							optionsToSave.push({
								name: option.name,
								value: option.value,
								isUnselectable: option.isUnselectable,
								type: option.type == null ? OptionType.BOOL : option.type,
								values: option.values,
								min: option.min,
								max: option.max,
								step: option.step,
								description: option.description
							});
						}
						var jsonData:String = haxe.Json.stringify({ options: optionsToSave }, "\t");
						var file:sys.io.FileOutput = sys.io.File.write(optionFilePath, false);
						file.writeString(jsonData);
						file.close();
					}
				}
			}
		}
		#end
	}

	public static function loadCustomOptions() {
		#if sys
		var found:Array<Option> = [];
		customOptions = [];

		for (modFolder in ModPaths.getModFolders()) {
			if (!modFolder.enabled) continue;
			var optionsDirPath = ModPaths.modPath(modFolder.folder, 'data/options');
			if (!ModPaths.isDirectory(optionsDirPath)) continue;

			for (optionJson in ModPaths.readDirectory(optionsDirPath)) {
				if (optionJson != null && optionJson.endsWith('.json')) {
					var fullPath = ModPaths.modPath(modFolder.folder, 'data/options/' + optionJson);
					if (!ModPaths.exists(fullPath)) continue;

					var jsonContent = ModPaths.readContent(fullPath);
					var jsonData: OptionsData = haxe.Json.parse(jsonContent);
					for (item in jsonData.options) {
						var opt:Option = {
							name: item.name,
							value: item.value,
							isUnselectable: item.isUnselectable,
							modSource: modFolder.folder,
							type: item.type == null ? OptionType.BOOL : item.type,
							values: item.values,
							min: item.min,
							max: item.max,
							step: item.step,
							description: item.description
						};
						var synced:Option = syncCustomOption(opt);
						found.push(synced);
					}
				}
			}
		}

		var bo = PreferencesSubstate.baseOptions;
		bo = bo.filter(o -> Lambda.exists(found, fn -> fn.name == o.name));

		for (n in found) {
			if (!Lambda.exists(bo, o -> o.name == n.name)) {
				bo.push(n);
			}
		}
		#end
	}

	public static function findCustomOption(name:String):Option {
		for (opt in customOptions) {
			if (opt.name == name) return opt;
		}
		return null;
	}

	public static function syncCustomOption(option:Option):Option {
		var existing:Option = findCustomOption(option.name);
		if (existing != null) {
			existing.value = option.value;
			existing.isUnselectable = option.isUnselectable;
			if (option.modSource != null) existing.modSource = option.modSource;
			existing.type = option.type == null ? OptionType.BOOL : option.type;
			existing.values = option.values;
			existing.min = option.min;
			existing.max = option.max;
			existing.step = option.step;
			existing.description = option.description;
			return existing;
		}
		customOptions.push(option);
		return option;
	}

	public static function isCustomOption(name:String):Bool {
		for (opt in customOptions) {
			if (opt.name == name) return true;
		}
		return false;
	}
}

enum OptionType {
	BOOL;
	INT;
	FLOAT;
	STRING;
}

typedef OptionsData = {
    var options:Array<Option>;
}

typedef Option = {
	var name:String;
	var value:Dynamic;
	var isUnselectable:Bool;
	@:optional var modSource:String;
	@:optional var type:OptionType;
	@:optional var values:Array<String>;
	@:optional var min:Float;
	@:optional var max:Float;
	@:optional var step:Float;
	@:optional var description:String;
}
