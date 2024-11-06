rgblink = C:\Users\willi\Visual Studio Code\Pong\Z80-Assembly-Pong\rgbds-0.8.0-win64\rgblink.exe
rgbfix = C:\Users\willi\Visual Studio Code\Pong\Z80-Assembly-Pong\rgbds-0.8.0-win64\rgbfix.exe
rgbasm = C:\Users\willi\Visual Studio Code\Pong\Z80-Assembly-Pong\rgbds-0.8.0-win64\rgbasm.exe

filename = pong

all: $(filename).gb

$(filename).gb: $(filename).o
	$(rgblink) -o $(filename).gb $(filename).o
	$(rgbfix) -v -p 0 $(filename).gb

$(filename).o: $(filename).asm
	$(rgbasm) -o $(filename).o $(filename).asm

clean:
	rm -f $(filename).o