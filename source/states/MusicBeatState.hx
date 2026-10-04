package states;

import system.Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;

using StringTools;

class MusicBeatState extends FlxUIState
{
	public static var curState:String;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	#if sys
	public var scriptState:ModScripts = new ModScripts();
	#end

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		// thx again maru
		curState = CoolUtil.formatClass(this, false);

        #if sys
		if (!curState.endsWith("PlayState")) {
			for (mod in ModPaths.getModFolders()) {
				var statesPath:String = ModPaths.modPath(mod.folder, 'data/states');
				if (mod.enabled && ModPaths.isDirectory(statesPath)) {
					for (file in ModPaths.readDirectory(statesPath)) {
						if (file != null && file.endsWith('.hx')) {
							var stateName:String = CoolUtil.formatClass(this).split('states/')[1];
							var filePath:String = ModPaths.modPath(mod.folder, 'data/states/' + file);
							if (file == stateName + ".hx" && ModPaths.exists(filePath)) {
								scriptState.loadScript(filePath);
							}
						}
					}
				}
			}
			scriptState.interp.scriptObject = this;

			scriptState.interp.variables.set("add", function(value:flixel.FlxObject) {
				add(value);
			});

			scriptState.interp.variables.set("remove", function(value:flixel.FlxObject) {
				remove(value);
			});

			scriptState.interp.variables.set("controls", controls);

			scriptState.interp.variables.set("curBeat", curBeat);
			scriptState.interp.variables.set("curStep", curStep);

			scriptState.interp.variables.set("this", this);
			scriptState.callFunction("create", [this]);
	    }
		#end

		if (transIn != null)
			Logger.log('reg ' + transIn.region);

		super.create();

		#if sys
		if (!curState.endsWith("PlayState")) {
		    scriptState.callFunction("createPost", [this]);
	    }
		#end
	}

	override function update(elapsed:Float)
	{
        #if sys
		if (!curState.endsWith("PlayState")) {
		    scriptState.callFunction("update", [elapsed, this]);
		}
		#end

		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);

        #if sys
		if (!curState.endsWith("PlayState")) {
		    scriptState.callFunction("updatePost", [elapsed, this]);
		}
		#end
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();

        #if sys
		if (!curState.endsWith("PlayState")) {
		    scriptState.callFunction("stepHit", [curStep, this]);
		}
		#end
	}

	public function beatHit():Void
	{
        #if sys
		if (!curState.endsWith("PlayState")) {
		    scriptState.callFunction("beatHit", [curBeat, this]);
		}
		#end
	}
}
