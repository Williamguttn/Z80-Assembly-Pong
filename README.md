# Overview
I created this as a beginner project to learn Z80 assembly by building a simple Pong game for the Game Boy. The code is not perfect, and probably contains a bunch of flaws (The collision detection is messed up).

## IMPORTANT
Since I am a total beginner at this stuff, the game moves really fast. I wasn't able to slow it down without breaking other stuff. To be able to actually play the game at a reasonable speed, do this in [BGB](#how-and-where-to-run):
- Right click, press options (Or press F11)
- Go to Graphics
- Open the vsync dropdown, and select **1 frame/3 vblanks**
- Apply and close

## How to Use
When the game ROM is loaded, the game **probably doesn't start immediately**. To start the game, **press "start"**. If you don't know which key that is, open up the [BGB](#how-and-where-to-run) settings and go to `Joypad` -> `configure keyboard`.


The game should immediately start in AI mode. You can also play with a second player. To switch to human vs. human mode, press (spam) `select + start`. After pressing that a couple of times, the game should go blank. Once again, press `start`. The game should now allow a second player to press `A` or `B` to move up or down (If AI mode is still enabled, just keep pressing and spamming these buttons).

Summary of all controls:
- To start the game: press **start**
- For 2-player mode: spam **Select + Start**, wait for the screen to go blank, then press **Start**
- To move paddle: For player 1, use D-Pad **up** and **down**. For player 2, use **A** for up and **B** for down

## Building the ROM
To assemble the program, I decided to use [RGBDS](https://github.com/gbdev/rgbds). To assemble the game (At least in my way), simply download the toolchain and link the required stuff in `makefile`. Then, run `make`.

## How and Where to Run
To run the output of `makefile`, you can download the [BGB GameBoy emulator](https://bgb.bircd.org/). Once done, open the executable and right click. Press "Load Rom...", and locate and select `pong.gb`. If all done right, the program should start.

## Credits
A big thanks to the following resources, which made development easier:
- [gbdev.io](https://gbdev.io/pandocs/About.html)
- [Game Boy Hardware definitions](https://github.com/gbdev/hardware.inc)