package game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;

using StringTools;

/**
 * Loosley based on FlxTypeText lolol
 */
class Alphabet extends FlxSpriteGroup
{
	public var delay:Float = 0.05;
	public var paused:Bool = false;

	// for menu shit
	public var targetY:Float = 0;
	public var yMult:Float = 120;
	public var isMenuItem:Bool = false;

	public var text:String = "";

	var _finalText:String = "";
	var _curText:String = "";

	public var widthOfWords:Float = FlxG.width;

	public var forceX:Float = Math.NEGATIVE_INFINITY;

	public var lettersArray:Array<AlphaCharacter> = [];

	var yMulti:Float = 1;

	// custom shit
	// amp, backslash, question mark, apostrophy, comma, angry faic, period
	var lastSprite:AlphaCharacter;
	var xPosResetted:Bool = false;
	var lastWasSpace:Bool = false;

	var splitWords:Array<String> = [];

	var isBold:Bool = false;

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false)
	{
		super(x, y);

		forceX = Math.NEGATIVE_INFINITY;

		_finalText = text;
		this.text = text;
		isBold = bold;

		if (text != "")
		{
			if (typed)
			{
				startTypedText();
			}
			else
			{
				addText();
			}
		}
	}

	public function changeText(newText:String)
	{
		for (i in 0...lettersArray.length)
		{
			var letter = lettersArray[0];
			letter.destroy();
			remove(letter);
			lettersArray.remove(letter);
		}

		lettersArray = [];
		splitWords = [];
		xPosResetted = false;
		lastSprite = null;

		var lastX = x;
		x = 0;
		_finalText = newText;
		text = newText;

		if (text != "")
		{
			addText();
		}

		x = lastX;
	}

	public function addText()
	{
		doSplitWords();

		var xPos:Float = 0;
		for (character in splitWords)
		{
			if (isBold && (character == "-" || character == "_"))
			{
				lastWasSpace = true;
				continue;
			}

			if (character == " ")
			{
				lastWasSpace = true;
			}

			#if (haxe >= "4.0.0")
			var isNumber:Bool = AlphaCharacter.numbers.contains(character);
			var isSymbol:Bool = AlphaCharacter.symbols.contains(character);
			#else
			var isNumber:Bool = AlphaCharacter.numbers.indexOf(character) != -1;
			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(character) != -1;
			#end

			if (AlphaCharacter.alphabet.indexOf(character.toLowerCase()) != -1 || isNumber || isSymbol)
			{
				if (lastSprite != null)
				{
					xPos = lastSprite.x + lastSprite.width;
				}

				if (lastWasSpace)
				{
					xPos += 40;
					lastWasSpace = false;
				}

				var letter:AlphaCharacter = new AlphaCharacter(xPos, 0, isBold ? 85 : 90);

				if (isBold && !isNumber && !isSymbol)
				{
					letter.createBold(character);
				}
				else if (isNumber)
				{
					letter.createNumber(character);
				}
				else if (isSymbol)
				{
					letter.createSymbol(character);
				}
				else
				{
					letter.createLetter(character);
				}

				add(letter);
				lettersArray.push(letter);

				lastSprite = letter;
			}
		}
	}

	function doSplitWords():Void
	{
		splitWords = _finalText.split("");
	}

	public var personTalking:String = 'gf';

	public function startTypedText():Void
	{
		_finalText = text;
		doSplitWords();

		// Logger.log(arrayShit);

		var loopNum:Int = 0;

		var xPos:Float = 0;
		var curRow:Int = 0;

		new FlxTimer().start(0.05, function(tmr:FlxTimer)
		{
			// Logger.log(_finalText.fastCodeAt(loopNum) + " " + _finalText.charAt(loopNum));
			if (_finalText.fastCodeAt(loopNum) == "\n".code)
			{
				yMulti += 1;
				xPosResetted = true;
				xPos = 0;
				curRow += 1;
			}

			if (splitWords[loopNum] == " ")
			{
				lastWasSpace = true;
			}

			#if (haxe >= "4.0.0")
			var isNumber:Bool = AlphaCharacter.numbers.contains(splitWords[loopNum]);
			var isSymbol:Bool = AlphaCharacter.symbols.contains(splitWords[loopNum]);
			#else
			var isNumber:Bool = AlphaCharacter.numbers.indexOf(splitWords[loopNum]) != -1;
			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(splitWords[loopNum]) != -1;
			#end

			if (AlphaCharacter.alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1 || isNumber || isSymbol)
				// if (AlphaCharacter.alphabet.contains(splitWords[loopNum].toLowerCase()) || isNumber || isSymbol)

			{
				if (lastSprite != null && !xPosResetted)
				{
					lastSprite.updateHitbox();
					xPos += lastSprite.width + 3;
					// if (isBold)
					// xPos -= 80;
				}
				else
				{
					xPosResetted = false;
				}

				if (lastWasSpace)
				{
					xPos += 20;
					lastWasSpace = false;
				}
				// Logger.log(_finalText.fastCodeAt(loopNum) + " " + _finalText.charAt(loopNum));

				// var letter:AlphaCharacter = new AlphaCharacter(30 * loopNum, 0);
				var letter:AlphaCharacter = new AlphaCharacter(xPos, 55 * yMulti, isBold ? 85 : 90);
				letter.row = curRow;
				if (isBold && !isNumber && !isSymbol)
				{
					letter.createBold(splitWords[loopNum]);
				}
				else
				{
					if (isNumber)
					{
						letter.createNumber(splitWords[loopNum]);
					}
					else if (isSymbol)
					{
						letter.createSymbol(splitWords[loopNum]);
					}
					else
					{
						letter.createLetter(splitWords[loopNum]);
					}

					letter.x += 90;
				}

				if (FlxG.random.bool(40))
				{
					var daSound:String = "GF_";
					FlxG.sound.play(Paths.soundRandom(daSound, 1, 4));
				}

				add(letter);

				lastSprite = letter;
			}

			loopNum += 1;

			tmr.time = FlxG.random.float(0.04, 0.09);
		}, splitWords.length);
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48), 0.16);

			if (forceX != Math.NEGATIVE_INFINITY)
			{
				x = forceX;
			}
			else
			{
			    x = FlxMath.lerp(x, (targetY * 20) + 90, 0.16);
			}
		}

		super.update(elapsed);
	}
}

class AlphaCharacter extends FlxSprite
{
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static var numbers:String = "1234567890";

	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";

	public var row:Int = 0;
	public var baselineY:Float = 110;

	public function new(x:Float, y:Float, baselineY:Float = 110)
	{
		super(x, y);
		this.baselineY = baselineY;
		var tex = Paths.getSparrowAtlas('alphabet');
		frames = tex;

		antialiasing = true;
	}

	public function createBold(letter:String)
	{
		if (AlphaCharacter.numbers.indexOf(letter) != -1)
		{
			createNumber(letter);
			return;
		}

		if (AlphaCharacter.symbols.indexOf(letter) != -1)
		{
			createSymbol(letter);
			return;
		}

		animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24);
		animation.play(letter);
		updateHitbox();
		y = (baselineY - height);
		y += row * 60;
	}

	public function createLetter(letter:String):Void
	{
		var letterCase:String = "lowercase";
		if (letter.toLowerCase() != letter)
		{
			letterCase = 'capital';
		}

		animation.addByPrefix(letter, letter + " " + letterCase, 24);
		animation.play(letter);
		updateHitbox();

		FlxG.log.add('the row' + row);

		y = (baselineY - height);
		y += row * 60;
	}

	public function createNumber(letter:String):Void
	{
		var framePrefix:String = letter + "0000";
		animation.addByPrefix(letter, framePrefix, 24);
		animation.play(letter);

		updateHitbox();
		y = (baselineY - height);
		y += row * 60;
	}

	public function createSymbol(letter:String)
	{
		var symbolName:String = switch (letter)
		{
			case '#': 'hashtag';
			case '.': 'period';
			case "'": 'apostraphie';
			case "?": 'question mark';
			case "!": 'exclamation point';
			case ':': ':';
			case ';': ';';
			case '-': '-';
			case '_': '_';
			case '+': '+';
			case '*': '*';
			case '|': '|';
			case '~': '~';
			case '@': '@';
			default: letter;
		};

		animation.addByPrefix(letter, symbolName, 24);
		animation.play(letter);

		updateHitbox();
		y = (baselineY - height);
		y += row * 60;
	}
}
