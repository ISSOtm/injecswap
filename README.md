
# InjecSwap

InjecSwap is a Game Boy Color program that injects save files into other consoles through cartswap.


# Usage

## Compilation

### Required

* [RGBDS](https://github.com/rednex/rgbds), confirmed to work with version 0.3.5
* `make` (it's possible to function without, though)
* The save file to be injected, with the `.sav` file extension (raw binary file) **CAUTION: Save file must be 32kB in size! Larger save files will be truncated, smaller files will fail to compile**
Included within this repo is a save file used for [N64 ACE](https://github.com/MrCheeze/pokestadium-ace).

### Compiling

First, make sure you are in the directory containing `injecswap.asm`, and have RGBDS installed. The save file must be present in the same directory, for example under the name `save_file.sav`.

If everything is OK, simply do `make save_file.gbc`. This will create the ROM, which you can then run using your favorite flashcart!


## Execution

### Required

* A Game Boy Color (monochrome Game Boys don't have enough RAM, and Game Boy Advance/SP doesn't play nice with GB/C cartswap)
* A flashcart (I'm using an [Everdrive GB X5](https://krikzz.com/store/home/47-everdrive-gb.html))
* The cartridge you wish to inject the save file into

### Uh... Execution?

Normally, nothing can go wrong for the hardware (I've tested this a few times, and done cartswap a good hundred times with no apparent damage). You should ensure that you DON'T shut your console down between pressing a button (step 4) and "Done" being displayed. This would cause your save file to be corrupted (though, you can re-do the procedure to correctly inject it).

1. Boot up the injection ROM using your flashcart. Do not touch any buttons.
2. Once the "Copying data" screen transitions into a black screen, remove the flashcart. If the console reboots, try again from step 1.
3. Insert the target cartridge. If the console reboots, try again from step 1.
4. Press any button. If nothing happens, try again from step 1.
5. "Copying data" should flash briefly, before being replaced with "Done". Once "Done" is displayed, it is safe to shut down the console.



# Troubleshooting

The method is simple enough that it should be idiot-proof. In case anything goes wrong, try injecting the save file again. No damage to the save file is permanent, except if somehow the hardware was damaged. This never happened to me (and I've done quite a lot of cartswaps), but I won't be responsible if it does happen to you.

Here are some problems you might encounter:


## I get stuck at the black screen!

Don't use a GBA. If you are using a GBC: try again, the console might have crashed when removing the flashcart. This never happened to me, but if it does, just keep trying again.


## I get stuck with a "Please use a GBC" message!

Do what it says. I've stated why monochrome Game Boys don't work : not enough RAM to store the save file.


## This works, but my save file gets erased if I turn the console off for too long!

The battery preserving your cartridge's save data is failing. Some gaming stores offer replacements (and if they do it for more than 5€, you're getting scammed, btw), but you can also do it yourself by getting an appropriate (gamebit) screwdriver, a button battery, and some adhesive/solder. There are tutorials online if you wish to DIY.
