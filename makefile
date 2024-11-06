rgblink = E:\"Visual Studio Code"\.vscode\Assembly\Z80\rgbds-0.9.0-rc2-win64\rgblink.exe
rgbfix = E:\"Visual Studio Code"\.vscode\Assembly\Z80\rgbds-0.9.0-rc2-win64\rgbfix.exe
rgbasm = E:\"Visual Studio Code"\.vscode\Assembly\Z80\rgbds-0.9.0-rc2-win64\rgbasm.exe

filename = timer

all: $(filename).gb

$(filename).gb: $(filename).o
	$(rgblink) -o $(filename).gb $(filename).o
	$(rgbfix) -v -p 0 $(filename).gb

$(filename).o: $(filename).asm
	$(rgbasm) -o $(filename).o $(filename).asm

clean:
	rm -f $(filename).o