╔═══════════════════════════════════════╗
║ MOD SUPPORT                           ║
╚═══════════════════════════════════════╝
Create a mod folder or ZIP archive and add characters, songs, stages, scripts, and more.
Mods can be enabled or disabled from the Mods menu.

FOLDER MOD
Create a folder inside mods/. The folder name becomes the mod name.

mods/
    example-mod/
        data/
        images/
        songs/
        videos/
        icon.png
        mod.json

ZIP MOD
Place example-mod.zip directly inside mods/. The archive can contain mod files at its
root, or inside one folder named example-mod (matching the ZIP file name, with or
without the .zip suffix).
The game reads ZIP contents directly and does not unpack the archive into mods/.

MANIFEST
Create mod.json in the mod root. The name is shown in the Mod Library; the other
fields provide the description, author, and version. icon.png is optional.
Example mod.json:
    {
      "name": "Example Mod",
      "description": "A short description of the mod.",
      "author": "Your Name",
      "version": "1.0.0"
    }

COMMON FILE LOCATIONS
    data/charts/<song>/       Chart JSON files
    data/characters/          Character JSON and TXT definitions
    data/events/              Custom event JSON files
    data/options/             Custom option JSON files
    data/scripts/             Scripts loaded with the song
    data/shaders/             .frag and .vert shader files
    data/stages/              Stage JSON files
    data/states/              Custom state scripts (.hx)
    data/substates/           Custom substate scripts (.hx)
    data/weeks/               Week JSON files
    images/characters/        Character sprites and Sparrow XML files
    images/icons/             Icons and other images
    songs/<song>/             Inst.ogg and Voices.ogg
    videos/                   Cutscene video files (.mp4)

SONG LIST
Add data/songList.txt to add songs to Freeplay. This is the only supported song-list
location.
Use one song per line:
    song-name:icon-name:week-number

You can optionally specify the available difficulties as a fourth field:
    song-name:icon-name:week-number:easy,normal,hard

Keep file and folder names consistent with the names referenced by your JSON files
and scripts. In ZIP archives, capitalization must match exactly.

MOD LIBRARY
The Mod Library shows each mod's name, author, version, description, enabled state, and
whether it is a folder or ZIP. An optional root icon.png is shown when available.
Use Up/Down or the mouse wheel to browse, Enter to enable or disable, R to refresh,
and 7 to open the editor.
