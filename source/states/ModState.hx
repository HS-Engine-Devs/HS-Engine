package states;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import openfl.display.BitmapData;
import system.ModSupport;
import system.ModSupport.ModMetadata;
import system.ModSupport.ModPaths;

class ModState extends MusicBeatState {
    private var bg:FlxBackdrop;
    private var shade:FlxSprite;
    private var listPanel:FlxSprite;
    private var detailPanel:FlxSprite;
    private var listGroup:FlxGroup;
    private var rowBackgrounds:Array<FlxSprite> = [];
    private var rowNames:Array<FlxText> = [];
    private var rowSources:Array<FlxText> = [];
    private var rowVersions:Array<FlxText> = [];
    private var rowStates:Array<FlxText> = [];
    private var detailTweens:Array<FlxTween> = [];
    private var mods:Array<ModMetadata> = [];
    private var selectedIndex:Int = 0;
    private var scrollOffset:Float = 0;
    private var detailIcon:FlxSprite;
    private var iconPlaceholder:FlxText;
    private var titleText:FlxText;
    private var descriptionText:FlxText;
    private var authorText:FlxText;
    private var versionText:FlxText;
    private var sourceText:FlxText;
    private var statusText:FlxText;
    private var countText:FlxText;

    private static inline var LIST_X:Float = 42;
    private static inline var LIST_Y:Float = 126;
    private static inline var LIST_WIDTH:Float = 410;
    private static inline var LIST_HEIGHT:Float = 492;
    private static inline var ROW_HEIGHT:Float = 58;

    override function create():Void {
		#if desktop
		DiscordClient.changePresence("In the Mod Library", null);
		#end

        bg = new FlxBackdrop(Paths.image('menuDesat'));
        bg.color = 0xFF39283D;
        bg.velocity.set(-12, 0);
        add(bg);

        shade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xD9101118);
        add(shade);

        var header = new FlxText(42, 30, 680, "MOD LIBRARY", 36);
        header.setFormat("VCR OSD Mono", 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        header.borderSize = 2;
        add(header);

        countText = new FlxText(FlxG.width - 310, 43, 268, "0 mods", 18);
        countText.setFormat("VCR OSD Mono", 18, FlxColor.CYAN, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(countText);

        listPanel = new FlxSprite(LIST_X, 92).makeGraphic(Std.int(LIST_WIDTH), Std.int(LIST_HEIGHT + 34), 0xD91A1B24);
        add(listPanel);
        detailPanel = new FlxSprite(470, 92).makeGraphic(FlxG.width - 512, Std.int(LIST_HEIGHT + 34), 0xD91A1B24);
        add(detailPanel);

        var listHeading = new FlxText(LIST_X + 18, 103, LIST_WIDTH - 36, "INSTALLED", 18);
        listHeading.setFormat("VCR OSD Mono", 18, FlxColor.CYAN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(listHeading);

        listGroup = new FlxGroup();
        add(listGroup);
        createDetailsPanel();
        reloadMods();

        var controlsText = new FlxText(42, FlxG.height - 48, FlxG.width - 84,
            "UP/DOWN  SELECT     WHEEL  SCROLL     ENTER  ENABLE/DISABLE     R  REFRESH     7  EDITOR     ESC  BACK", 16);
        controlsText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        controlsText.borderSize = 1.5;
        add(controlsText);

        super.create();
    }

    private function createDetailsPanel():Void {
        detailIcon = new FlxSprite(500, 126).makeGraphic(150, 150, 0xFF34333F);
        add(detailIcon);

        iconPlaceholder = new FlxText(500, 181, 150, "MOD", 24);
        iconPlaceholder.setFormat("VCR OSD Mono", 24, FlxColor.CYAN, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(iconPlaceholder);

        titleText = new FlxText(676, 128, FlxG.width - 716, "", 32);
        titleText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 1.5;
        add(titleText);

        authorText = new FlxText(678, 173, FlxG.width - 720, "", 18);
        authorText.setFormat("VCR OSD Mono", 18, FlxColor.CYAN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(authorText);

        versionText = new FlxText(678, 202, FlxG.width - 720, "", 16);
        versionText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(versionText);

        statusText = new FlxText(500, 304, FlxG.width - 540, "", 20);
        statusText.setFormat("VCR OSD Mono", 20, FlxColor.LIME, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(statusText);

        sourceText = new FlxText(500, 340, FlxG.width - 540, "", 16);
        sourceText.setFormat("VCR OSD Mono", 16, FlxColor.GRAY, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(sourceText);

        var descriptionHeading = new FlxText(500, 390, FlxG.width - 540, "DESCRIPTION", 16);
        descriptionHeading.setFormat("VCR OSD Mono", 16, FlxColor.CYAN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(descriptionHeading);

        descriptionText = new FlxText(500, 420, FlxG.width - 540, "", 20);
        descriptionText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        descriptionText.wordWrap = true;
        descriptionText.borderSize = 1;
        add(descriptionText);
    }

    private function reloadMods():Void {
        mods = [];
        for (modFolder in ModPaths.getModFolders()) {
            mods.push(ModSupport.getModMetadata(modFolder.folder));
        }
        if (mods.length == 0) {
            selectedIndex = -1;
        } else {
            selectedIndex = Std.int(Math.max(0, Math.min(selectedIndex, mods.length - 1)));
        }
        scrollOffset = 0;
        rebuildList();
        updateSelection();
    }

    private function rebuildList():Void {
        listGroup.clear();
        rowBackgrounds = [];
        rowNames = [];
        rowSources = [];
        rowVersions = [];
        rowStates = [];
        countText.text = mods.length + (mods.length == 1 ? " mod" : " mods");

        for (mod in mods) {
            var row = new FlxSprite(LIST_X + 12, 142).makeGraphic(Std.int(LIST_WIDTH - 24), 48, 0xFF242630);
            row.scrollFactor.set();
            rowBackgrounds.push(row);
            listGroup.add(row);

            var name = new FlxText(LIST_X + 24, 148, 164, mod.name, 17);
            name.setFormat("VCR OSD Mono", 17, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            name.scrollFactor.set();
            rowNames.push(name);
            listGroup.add(name);

            var source = new FlxText(LIST_X + 192, 153, 60, mod.isZip ? "ZIP" : "FOLDER", 12);
            source.setFormat("VCR OSD Mono", 12, mod.isZip ? FlxColor.CYAN : FlxColor.GRAY, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            source.scrollFactor.set();
            rowSources.push(source);
            listGroup.add(source);

            var version = new FlxText(LIST_X + 256, 153, 56, "v" + mod.version, 10);
            version.setFormat("VCR OSD Mono", 10, FlxColor.GRAY, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            version.scrollFactor.set();
            rowVersions.push(version);
            listGroup.add(version);

            var state = new FlxText(LIST_X + 317, 153, 64, mod.enabled ? "ON" : "OFF", 12);
            state.setFormat("VCR OSD Mono", 12, mod.enabled ? FlxColor.LIME : FlxColor.GRAY, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            state.scrollFactor.set();
            rowStates.push(state);
            listGroup.add(state);
        }

        updateListLayout();
    }

    private function updateListLayout():Void {
        var maxScroll:Float = 0;
        if (mods.length > 0) {
            var lastRowBottom = LIST_Y + 16 + (mods.length - 1) * ROW_HEIGHT + 48;
            var neededScroll = Math.max(0, lastRowBottom - (LIST_Y + LIST_HEIGHT - 8));
            maxScroll = Math.ceil(neededScroll / ROW_HEIGHT) * ROW_HEIGHT;
        }
        scrollOffset = Math.max(0, Math.min(scrollOffset, maxScroll));
        var rowY:Float = LIST_Y + 16;
        var viewportTop = LIST_Y + 8;
        var viewportBottom = LIST_Y + LIST_HEIGHT - 8;

        for (i in 0...rowBackgrounds.length) {
            var y = rowY + i * ROW_HEIGHT - scrollOffset;
            var isVisible = y >= viewportTop && y + 48 <= viewportBottom;
            rowBackgrounds[i].y = y;
            rowNames[i].y = y + 12;
            rowSources[i].y = y + 16;
            rowVersions[i].y = y + 17;
            rowStates[i].y = y + 16;
            rowBackgrounds[i].visible = isVisible;
            rowNames[i].visible = isVisible;
            rowSources[i].visible = isVisible;
            rowVersions[i].visible = isVisible;
            rowStates[i].visible = isVisible;
            rowBackgrounds[i].color = i == selectedIndex ? 0xFF56394F : 0xFF242630;
            rowBackgrounds[i].alpha = mods[i].enabled ? 1 : 0.55;
            rowNames[i].alpha = mods[i].enabled ? 1 : 0.6;
            rowSources[i].alpha = mods[i].enabled ? 1 : 0.6;
            rowVersions[i].alpha = mods[i].enabled ? 1 : 0.6;
            rowStates[i].text = mods[i].enabled ? "ON" : "OFF";
            rowStates[i].color = mods[i].enabled ? FlxColor.LIME : FlxColor.GRAY;
        }
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        handleInput();
    }

    private function handleInput():Void {
        if (FlxG.mouse.wheel != 0 && FlxG.mouse.overlaps(listPanel)) {
            scrollOffset -= FlxG.mouse.wheel * ROW_HEIGHT;
            updateListLayout();
        }

        if (controls.UP_P) {
            if (mods.length == 0) return;
            selectedIndex = (selectedIndex - 1 + mods.length) % mods.length;
            FlxG.sound.play(Paths.sound('scrollMenu'));
            updateSelection();
        } else if (controls.DOWN_P) {
            if (mods.length == 0) return;
            selectedIndex = (selectedIndex + 1) % mods.length;
            FlxG.sound.play(Paths.sound('scrollMenu'));
            updateSelection();
        } else if (FlxG.keys.justPressed.SEVEN) {
            FlxG.switchState(new states.editors.EditorMenuState());
        } else if (FlxG.keys.justPressed.R) {
            ModPaths.loadMods();
            reloadMods();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        } else if (controls.BACK) {
            if (ModPaths.checkRestartStatus()) {
                TitleState.initialized = false;
                TitleState.closedState = false;

                FlxG.sound.music.fadeOut(0.3);
                FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
            } else {
                scriptState.callFunction("goToMenu", []);
                FlxG.switchState(new MainMenuState());
            }
        } else if (controls.ACCEPT) {
            if (selectedIndex >= 0 && selectedIndex < mods.length) {
                var selectedMod = mods[selectedIndex];
                ModPaths.toggleMod(selectedMod.folder, !selectedMod.enabled);
                reloadMods();
            }
        }
    }

    private function updateSelection():Void {
        if (mods.length == 0 || selectedIndex < 0 || selectedIndex >= mods.length) {
            titleText.text = "No mods installed";
            authorText.text = "Add a folder or ZIP archive to mods/.";
            versionText.text = "";
            statusText.text = "";
            sourceText.text = "";
            descriptionText.text = "A mod can include mod.json and icon.png in its root.";
            detailIcon.visible = false;
            iconPlaceholder.visible = false;
            updateListLayout();
            return;
        }

        var selected = mods[selectedIndex];
        titleText.text = selected.name;
        authorText.text = "by " + selected.author;
        versionText.text = "Version " + selected.version;
        statusText.text = selected.enabled ? "ENABLED" : "DISABLED";
        statusText.color = selected.enabled ? FlxColor.LIME : FlxColor.ORANGE;
        sourceText.text = selected.isZip ? "ZIP ARCHIVE  /  " + selected.folder : "MOD FOLDER  /  " + selected.folder;
        descriptionText.text = selected.description;

        detailIcon.visible = selected.iconPath != null;
        iconPlaceholder.visible = selected.iconPath == null;
        if (selected.iconPath != null) {
            try {
                detailIcon.loadGraphic(BitmapData.fromBytes(ModPaths.readBytes(selected.iconPath)));
                detailIcon.setGraphicSize(150, 150);
                detailIcon.updateHitbox();
            } catch (error:Dynamic) {
                detailIcon.visible = false;
                iconPlaceholder.visible = true;
                Logger.log("Error: could not load mod icon for " + selected.folder + ": " + error);
            }
        }

        animateDetails();
        updateListLayout();
        var rowTop = LIST_Y + 16 + selectedIndex * ROW_HEIGHT;
        var rowBottom = rowTop + 48;
        if (rowTop - scrollOffset < LIST_Y + 8) scrollOffset = rowTop - (LIST_Y + 8);
        if (rowBottom - scrollOffset > LIST_Y + LIST_HEIGHT - 8) scrollOffset = rowBottom - (LIST_Y + LIST_HEIGHT - 8);
        updateListLayout();
    }

    private function animateDetails():Void {
        for (tween in detailTweens) {
            if (tween != null) tween.cancel();
        }
        detailTweens = [];

        var labels:Array<FlxText> = [titleText, authorText, versionText, statusText, sourceText, descriptionText];
        for (label in labels) {
            var targetY = label.y;
            label.alpha = 0;
            label.y = targetY + 8;
            detailTweens.push(FlxTween.tween(label, {alpha: 1, y: targetY}, 0.18, {ease: FlxEase.quadOut}));
        }

        if (detailIcon.visible) {
            detailIcon.alpha = 0;
            detailTweens.push(FlxTween.tween(detailIcon, {alpha: 1}, 0.2, {ease: FlxEase.quadOut}));
        }
    }
}
