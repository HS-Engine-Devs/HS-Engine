package states.editors.script;

#if sys
import flash.events.KeyboardEvent;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import openfl.events.Event;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class ScriptEditorState extends MusicBeatState
{
	var codeField:TextField;
	var lineNumbersField:TextField;
	var consoleField:TextField;
	var suggestionsField:TextField;
	var suggestionMatches:Array<String>;
	var suggestionIndex:Int = 0;
	var scriptPath:String;
	var runtime:ModScripts;

	override function create()
	{
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF303030;
		add(bg);

		scriptPath = resolveSongScriptPath();
		runtime = new ModScripts();
		runtime.interp.variables.set("trace", function(value:Dynamic) {
			appendConsole("trace: " + Std.string(value));
		});

		var title:FlxText = new FlxText(20, 16, 0, "Script Editor", 24);
		add(title);

		var pathText:FlxText = new FlxText(20, 48, FlxG.width - 40, scriptPath != null ? scriptPath : "No script path found", 8);
		pathText.color = FlxColor.WHITE;
		add(pathText);

		FlxG.mouse.visible = true;
		FlxG.mouse.useSystemCursor = true;
		buildOpenFLInputs();

		var saveButton:FlxButton = new FlxButton(20, FlxG.height - 35, "Save", function() saveCurrentScript());
		saveButton.scrollFactor.set(0, 0);
		add(saveButton);

		var runButton:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Run", function() runCurrentScript());
		runButton.scrollFactor.set(0, 0);
		add(runButton);

		var backButton:FlxButton = new FlxButton(runButton.x + runButton.width + 10, runButton.y, "Back to Charting", function() {
			FlxG.switchState(new states.editors.charting.ChartingEditorState());
		});
		backButton.scrollFactor.set(0, 0);
		add(backButton);

		loadCurrentScript();
		appendConsole("Loaded script editor.");
		highlightCode();
		updateLineNumbers();
		refreshSuggestionPanel();
		FlxG.mouse.visible = true;
		super.create();
	}

	override function update(elapsed:Float)
	{
		syncEditorPanels();
		super.update(elapsed);
	}

	function buildOpenFLInputs():Void
	{
		var editorFormat:TextFormat = new TextFormat("Courier New", 14, 0xD4D4D4);
		var consoleFormat:TextFormat = new TextFormat("Courier New", 12, 0xD4D4D4);
		var lineNumberFormat:TextFormat = new TextFormat("Courier New", 14, 0x5C5C5C);

		var editorWidth:Int = 900;
		var editorHeight:Int = 360;
		var editorX:Int = Std.int((FlxG.width - editorWidth) / 2);
		var editorY:Int = 80;
		var lineNumbersWidth:Int = 55;
		var lineNumbersX:Int = editorX - lineNumbersWidth - 6;
		var consoleX:Int = Std.int((FlxG.width - editorWidth) / 2);
		var consoleY:Int = editorY + editorHeight + 25;
		var consoleHeight:Int = 120;

		lineNumbersField = new TextField();
		lineNumbersField.x = lineNumbersX;
		lineNumbersField.y = editorY;
		lineNumbersField.width = lineNumbersWidth;
		lineNumbersField.height = editorHeight;
		lineNumbersField.multiline = true;
		lineNumbersField.wordWrap = false;
		lineNumbersField.type = TextFieldType.DYNAMIC;
		lineNumbersField.selectable = false;
		lineNumbersField.background = true;
		lineNumbersField.backgroundColor = 0xFF1E1E1E;
		lineNumbersField.border = true;
		lineNumbersField.borderColor = 0xFF3C3C3C;
		lineNumbersField.defaultTextFormat = lineNumberFormat;
		lineNumbersField.textColor = 0x808080;
		lineNumbersField.text = "1\n";
		FlxG.stage.addChild(lineNumbersField);

		codeField = new TextField();
		codeField.x = editorX;
		codeField.y = editorY;
		codeField.width = editorWidth;
		codeField.height = editorHeight;
		codeField.multiline = true;
		codeField.wordWrap = false;
		codeField.type = TextFieldType.INPUT;
		codeField.background = true;
		codeField.backgroundColor = 0xFF1E1E1E;
		codeField.border = true;
		codeField.borderColor = 0xFF3C3C3C;
		codeField.defaultTextFormat = editorFormat;
		codeField.textColor = 0xD4D4D4;
		codeField.addEventListener(Event.CHANGE, onCodeChanged);
		codeField.addEventListener(Event.SCROLL, onCodeScroll);
		codeField.addEventListener(KeyboardEvent.KEY_DOWN, onEditorKeyDown);
		codeField.setSelection(0, 0);
		FlxG.stage.addChild(codeField);

		consoleField = new TextField();
		consoleField.x = consoleX;
		consoleField.y = consoleY;
		consoleField.width = editorWidth;
		consoleField.height = consoleHeight;
		consoleField.multiline = true;
		consoleField.wordWrap = true;
		consoleField.type = TextFieldType.DYNAMIC;
		consoleField.selectable = false;
		consoleField.background = true;
		consoleField.backgroundColor = 0xFF2D2D30;
		consoleField.border = true;
		consoleField.borderColor = 0xFF3C3C3C;
		consoleField.defaultTextFormat = consoleFormat;
		consoleField.textColor = 0xD4D4D4;
		consoleField.text = "Console ready.\n";
		FlxG.stage.addChild(consoleField);

		suggestionsField = new TextField();
		suggestionsField.x = consoleX;
		suggestionsField.y = consoleY + consoleHeight + 8;
		suggestionsField.width = editorWidth;
		suggestionsField.height = 120;
		suggestionsField.multiline = true;
		suggestionsField.wordWrap = true;
		suggestionsField.type = TextFieldType.DYNAMIC;
		suggestionsField.selectable = false;
		suggestionsField.background = true;
		suggestionsField.backgroundColor = 0xFF242426;
		suggestionsField.border = true;
		suggestionsField.borderColor = 0xFF3C3C3C;
		suggestionsField.defaultTextFormat = consoleFormat;
		suggestionsField.textColor = 0xC8C8C8;
		suggestionsField.text = "Suggestions\nstart typing a symbol...";
		FlxG.stage.addChild(suggestionsField);
	}

	function onCodeChanged(event:Event):Void
	{
		highlightCode();
		updateLineNumbers();
		refreshSuggestionPanel();
	}

	function onCodeScroll(event:Event):Void
	{
		syncEditorPanels();
		refreshSuggestionPanel();
	}

	function onEditorKeyDown(event:KeyboardEvent):Void
	{
		if (event.keyCode == 38)
		{
			if (suggestionMatches != null && suggestionMatches.length > 0)
			{
				suggestionIndex--;
				if (suggestionIndex < 0)
					suggestionIndex = suggestionMatches.length - 1;
				refreshSuggestionPanel();
				event.preventDefault();
			}
			return;
		}

		if (event.keyCode == 40)
		{
			if (suggestionMatches != null && suggestionMatches.length > 0)
			{
				suggestionIndex++;
				if (suggestionIndex >= suggestionMatches.length)
					suggestionIndex = 0;
				refreshSuggestionPanel();
				event.preventDefault();
			}
			return;
		}

		if (event.keyCode == 9 || event.keyCode == 13)
		{
			if (suggestionMatches != null && suggestionMatches.length > 0)
			{
				applySelectedSuggestion();
				event.preventDefault();
				return;
			}

			var start:Int = codeField.selectionBeginIndex;
			var end:Int = codeField.selectionEndIndex;
			var selected:String = codeField.text.substring(start, end);
			codeField.replaceText(start, end, '    ' + selected.replace('\n', '\n    '));
			codeField.setSelection(start + 4, start + 4 + selected.length);
			event.preventDefault();
			refreshSuggestionPanel();
		}
	}

	function syncEditorPanels():Void
	{
		if (codeField == null || lineNumbersField == null)
			return;

		var lineCount:Int = codeField.text.split('\n').length;
		if (lineCount < 1)
			lineCount = 1;

		var nums:StringBuf = new StringBuf();
		for (i in 0...lineCount)
			nums.add((i + 1) + "\n");

		if (lineNumbersField.text != nums.toString())
			lineNumbersField.text = nums.toString();

		var targetScroll:Int = codeField.scrollV;
		if (targetScroll < 1)
			targetScroll = 1;
		if (targetScroll > lineNumbersField.maxScrollV)
			targetScroll = lineNumbersField.maxScrollV;

		lineNumbersField.scrollV = targetScroll;
		lineNumbersField.scrollH = 0;
		lineNumbersField.multiline = true;
		lineNumbersField.setSelection(0, 0);
	}

	function updateLineNumbers():Void
	{
		syncEditorPanels();
	}

	function getRuntimeFunctionList():Array<String>
	{
		return [
			'create', 'createPost', 'update', 'updatePost', 'stepHit', 'beatHit', 'startCountdown',
			'songStart', 'resume', 'endSong', 'performEvent', 'generateStaticArrows', 'popUpScore',
			'noteMiss', 'goodNoteHit', 'dadTurn', 'bfTurn', 'startVideo', 'createNoteSplash',
			'goToMenu', 'pause', 'startAndEnd', 'schoolIntro', 'darnellVideo', 'darnellIntro',
			'changeCharacter', 'addCharacterToList', 'removeCharacterFromList', 'setSongTime',
			'createCharacterGlow', 'stageDarken', 'createBullet', 'canKick', 'canKickSlow',
			'canKickForward', 'canHit', 'canShot', 'clearNotesBefore', 'resetFastCar', 'fastCarDrive',
			'moveTank', 'trainStart', 'updateTrainPos', 'resetCar', 'cleanupLightning', 'slowRain',
			'normalRain', 'toggleLightning', 'importScript', 'switchState', 'openSubState',
			'closeSubState', 'getOptionValue', 'setOnScripts', 'callOnScripts', 'setScriptFunction',
			'addScript', 'callFunction', 'loadScript', 'executeScript'
		];
	}

	function getRuntimeVariableList():Array<String>
	{
		return [
			'add', 'remove', 'insert', 'removeStage', 'startVideo', 'getObject', 'members',
			'camFollow', 'camFollowPos', 'boyfriend', 'dad', 'gf', 'boyfriendGroup', 'dadGroup',
			'gfGroup', 'camHUD', 'camGame', 'camOther', 'defaultCamZoom', 'curSong', 'SONG',
			'curStage', 'this', 'inCutscene', 'curBeat', 'curStep', 'playerStrums', 'dadStrums',
			'strumLineNotes', 'noteSplashes', 'mustHitSection', 'altAnim', 'babyArrow', 'daRating',
			'controls', 'window', 'FlxColor', 'FlxKey', 'BlendMode', 'FlxCameraFollowStyle',
			'FlxTextAlign', 'FlxTextBorderStyle', 'StringHelper'
		];
	}

	function isIdentifierChar(ch:String):Bool
	{
		return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || ch == '_';
	}

	function refreshSuggestionPanel():Void
	{
		if (codeField == null || suggestionsField == null || codeField.text == null)
			return;

		var text:String = codeField.text;
		var caret:Int = codeField.selectionBeginIndex;
		if (caret < 0)
			caret = 0;
		if (caret > text.length)
			caret = text.length;

		var start:Int = caret;
		while (start > 0 && isIdentifierChar(text.charAt(start - 1)))
			start--;

		var prefix:String = text.substring(start, caret);
		if (prefix.length == 0)
		{
			suggestionMatches = [];
			suggestionIndex = 0;
			suggestionsField.text = "Suggestions\nstart typing a symbol...";
			return;
		}

		suggestionMatches = [];
		for (name in getRuntimeFunctionList())
			if (name.toLowerCase().indexOf(prefix.toLowerCase()) == 0 && suggestionMatches.indexOf(name) == -1)
				suggestionMatches.push(name);
		for (name in getRuntimeVariableList())
			if (name.toLowerCase().indexOf(prefix.toLowerCase()) == 0 && suggestionMatches.indexOf(name) == -1)
				suggestionMatches.push(name);

		if (suggestionMatches.length == 0)
		{
			suggestionIndex = 0;
			suggestionsField.text = "Suggestions\nno runtime symbols for '" + prefix + "'";
			return;
		}

		if (suggestionIndex < 0)
			suggestionIndex = 0;
		if (suggestionIndex >= suggestionMatches.length)
			suggestionIndex = 0;

		var lines:Array<String> = [];
		for (i in 0...suggestionMatches.length)
		{
			var marker:String = (i == suggestionIndex) ? "> " : "  ";
			lines.push(marker + suggestionMatches[i]);
		}
		suggestionsField.text = "Suggestions\n" + lines.slice(0, 8).join("\n");
	}

	function applySelectedSuggestion():Void
	{
		if (codeField == null || suggestionsField == null || suggestionMatches == null || suggestionMatches.length == 0)
			return;

		var text:String = codeField.text;
		var caret:Int = codeField.selectionBeginIndex;
		if (caret < 0)
			caret = 0;
		if (caret > text.length)
			caret = text.length;

		var start:Int = caret;
		while (start > 0 && isIdentifierChar(text.charAt(start - 1)))
			start--;

		var word:String = suggestionMatches[suggestionIndex];
		codeField.replaceText(start, caret, word);
		codeField.setSelection(start + word.length, start + word.length);
		refreshSuggestionPanel();
	}

	function highlightCode():Void
	{
		var text:String = codeField.text;
		var baseFormat:TextFormat = new TextFormat("Courier New", 14, 0xD4D4D4);
		var keywordFormat:TextFormat = new TextFormat("Courier New", 14, 0x569CD6);
		var stringFormat:TextFormat = new TextFormat("Courier New", 14, 0xCE9178);
		var commentFormat:TextFormat = new TextFormat("Courier New", 14, 0x6A9955);
		var typeFormat:TextFormat = new TextFormat("Courier New", 14, 0x4EC9B0);
		var functionFormat:TextFormat = new TextFormat("Courier New", 14, 0xDCDCAA);
		var variableFormat:TextFormat = new TextFormat("Courier New", 14, 0x9CDCFE);
		var preprocFormat:TextFormat = new TextFormat("Courier New", 14, 0xC586C0);

		codeField.defaultTextFormat = baseFormat;
		codeField.setTextFormat(baseFormat, 0, text.length);

		var keywordList:Array<String> = [
			'class', 'function', 'var', 'override', 'if', 'else', 'for', 'while', 'return',
			'new', 'null', 'true', 'false', 'switch', 'case', 'public', 'private', 'static',
			'final', 'dynamic', 'import', 'using', 'extends', 'implements', 'break', 'continue',
			'cast', 'try', 'catch', 'throw', 'enum', 'abstract', 'typedef', 'package', 'this'
		];

		var runtimeFunctions:Array<String> = getRuntimeFunctionList();
		var runtimeVariables:Array<String> = getRuntimeVariableList();

		var i:Int = 0;
		while (i < text.length)
		{
			var c:String = text.charAt(i);
			if (c == '/' && i + 1 < text.length && text.charAt(i + 1) == '/')
			{
				var end:Int = text.indexOf('\n', i);
				if (end == -1) end = text.length;
				codeField.setTextFormat(commentFormat, i, end);
				i = end;
				continue;
			}

			if (c == '"' || c == "'")
			{
				var quote:String = c;
				var j:Int = i + 1;
				while (j < text.length)
				{
					if (text.charAt(j) == '\\')
					{
						j += 2;
						continue;
					}
					if (text.charAt(j) == quote)
					{
						break;
					}
					j++;
				}
				if (j < text.length)
					j++;
				codeField.setTextFormat(stringFormat, i, j);
				i = j;
				continue;
			}

			if (c == '#')
			{
				var j:Int = i + 1;
				while (j < text.length && text.charAt(j) != '\n') j++;
				codeField.setTextFormat(preprocFormat, i, j);
				i = j;
				continue;
			}

			if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_')
			{
				var start:Int = i;
				var j:Int = i + 1;
				while (j < text.length)
				{
					var ch:String = text.charAt(j);
					if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || ch == '_')
						j++;
					else
						break;
				}

				var word:String = text.substring(start, j);
				if (keywordList.indexOf(word) != -1)
					codeField.setTextFormat(keywordFormat, start, j);
				if (runtimeFunctions.indexOf(word) != -1)
					codeField.setTextFormat(functionFormat, start, j);
				else if (runtimeVariables.indexOf(word) != -1)
					codeField.setTextFormat(variableFormat, start, j);
				else if (word.charAt(0).toUpperCase() == word.charAt(0) && word.length > 1)
					codeField.setTextFormat(typeFormat, start, j);
				i = j;
				continue;
			}

			i++;
		}

		codeField.scrollH = 0;
		updateLineNumbers();
	}

	function resolveSongScriptPath():String
	{
		if (PlayState.SONG == null || PlayState.SONG.song == null)
			return null;

		var songName:String = PlayState.SONG.song.toLowerCase();
		var result:String = ModPaths.script("data/charts/" + songName + "/script");
		if (result == null)
			result = 'mods/' + PlayState.SONG.song.toLowerCase() + '/data/charts/' + songName + '/script.hx';
		return result;
	}

	function loadCurrentScript():Void
	{
		if (scriptPath == null || !ModPaths.exists(scriptPath))
		{
			codeField.text = "// script.hx not found for this song.\n// You can type code here and save it.\n";
			appendConsole("No script file exists yet. A new file will be created when saving.");
			refreshSuggestionPanel();
			return;
		}

		codeField.text = ModPaths.readContent(scriptPath);
		appendConsole("Loaded: " + scriptPath);
		updateLineNumbers();
		refreshSuggestionPanel();
	}

	function saveCurrentScript():Void
	{
		if (scriptPath == null)
		{
			appendConsole("Cannot save: no valid song script path found.");
			return;
		}
		if (StringTools.startsWith(scriptPath, "zip://"))
		{
			var archivePath:String = scriptPath.substr(6);
			var separator:Int = archivePath.indexOf("/");
			scriptPath = Path.join(["mods", archivePath.substr(0, separator), archivePath.substr(separator + 1)]);
		}

		var dir:String = Path.directory(scriptPath);
		if (!FileSystem.exists(dir))
			FileSystem.createDirectory(dir);

		File.saveContent(scriptPath, codeField.text);
		appendConsole("Saved: " + scriptPath);
	}

	function runCurrentScript():Void
	{
		appendConsole("Running script...");
		try
		{
			var expr = runtime.parser.parseString(codeField.text);
			runtime.interp.execute(expr);
			appendConsole("Script executed successfully.");
		}
		catch (error:Dynamic)
		{
			appendConsole("Error: " + Std.string(error));
		}
	}

	function appendConsole(message:String):Void
	{
		consoleField.appendText(message + "\n");
		consoleField.scrollV = consoleField.maxScrollV;
	}

	override function destroy()
	{
		if (FlxG.stage != null)
		{
			if (lineNumbersField != null && lineNumbersField.parent == FlxG.stage)
				FlxG.stage.removeChild(lineNumbersField);
			if (codeField != null && codeField.parent == FlxG.stage)
				FlxG.stage.removeChild(codeField);
			if (consoleField != null && consoleField.parent == FlxG.stage)
				FlxG.stage.removeChild(consoleField);
			if (suggestionsField != null && suggestionsField.parent == FlxG.stage)
				FlxG.stage.removeChild(suggestionsField);
		}
		lineNumbersField = null;
		codeField = null;
		consoleField = null;
		suggestionsField = null;
		super.destroy();
	}
}
#else
class ScriptEditorState extends MusicBeatState {}
#end
