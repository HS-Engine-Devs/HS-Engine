# HS Engine

<img src="docs/img/hs-engine.png" width="500" height="300" style="margin-left: -50px;">

</br>
HS Engine is a HaxeFlixel-based engine and modding framework for Friday Night Funkin'.
It provides custom gameplay content, in-game editors, scripting support, and tools for
building and managing mods.

## ModAPI

The ModAPI documents how to extend HS Engine with custom content. The documentation
lives in the `docs/` folder, starting at [docs/index.html](docs/index.html). The full
API reference is still growing; the current handbook covers mod creation and
supported resources.

## Credits

### HS Engine Developers
| Credits Icon | Username | Involvement |
| ------------ | -------- | ----------- |
| <img src="docs/img/haxel.png" width="64" height="64"/> | [HaxelDev](https://github.com/HaxelDev) | Main-Programmer of HS Engine
| <img src="docs/img/toska.png" width="64" height="64"/> | [teotm](https://github.com/teotm) | Programmer of HS Engine
| <img src="docs/img/wipek.png" width="64" height="64"/> | [Wipek](https://www.youtube.com/watch?v=lrJLIE3jGOs) | Artist of HS Engine
| <img src="docs/img/kot.png" width="64" height="64"/> | [Codding Cat](https://github.com/CoddingCatPL) | Ex-Programmer of HS Engine

### HS Engine Owner
| Credits Icon | Username | Involvement |
| ------------ | -------- | ----------- |
| <img src="docs/img/gidk.png" width="64" height="64"/> | [Gidk](https://www.youtube.com/watch?v=al74RjD4Ans) | HS engine owner

### Special Thanks
| Credits Icon | Username | Involvement |
| ------------ | -------- | ----------- |
| <img src="docs/img/shadowmario.png" width="64" height="64"/> | [Shadow Mario](https://twitter.com/Shadow_Mario_) | Some Stolen Stuff
| <img src="docs/img/CoreDev.png" width="64" height="64"/> | [CoreCat](https://github.com/Core5570RYT) | Some Stolen Stuff

### Friday Night Funkin'
| Credits Icon | Username | Involvement |
| ------------ | -------- | ----------- |
| <img src="docs/img/ninjamuffin99.png" width="64" height="64"/> | [ninja_muffin99](https://twitter.com/ninja_muffin99) | Programmer of Friday Night Funkin'
| <img src="docs/img/phantomarcade.png" width="64" height="64"/> | [PhantomArcade3K](https://twitter.com/PhantomArcade3K) | Artist of Friday Night Funkin'
| <img src="docs/img/evilsk8r.png" width="64" height="64"/> | [evilsk8r](https://twitter.com/evilsk8r) | Artist of Friday Night Funkin'
| <img src="docs/img/kawaisprite.png" width="64" height="64"/> | [Kawai Sprite](https://twitter.com/kawaisprite) | Composer of Friday Night Funkin'

## Build instructions

**Warning: Make sure to use Haxe version 4.2.5 as versions like 4.3.4 will not work properly with this engine.**

First you need to install Haxe and HaxeFlixel.
1. [Install Haxe 4.2.5](https://haxe.org/download/version/4.2.5/) (Download 4.2.5 instead of 4.1.5, seriously stop using Haxe 4.1.5, it misses a lot of stuffs)
2. Download [git-scm](https://git-scm.com/downloads). Works for Windows, Mac, and Linux, just select your build.
3. Next go install the necessary Haxe libraries in order to compile your mod by typing these commands in:
```cmd
haxelib install hmm
haxelib run hmm install
```

You should have everything ready for compiling the engine! Follow the guide below to continue!