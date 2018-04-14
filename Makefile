
.SUFFIXES:

%.gbc: %.sav injecswap.asm
	cp $< SRAM.bin

	rgbasm -E -h -p 0 -o injecswap.o injecswap.asm
	rgblink -p 0 -o $@ injecswap.o
	rm injecswap.o

	rgbfix -Cjv -i IJSW -k NO -l 0x33 -m 0x01 -p 0 -t INJECSWAP $@
	rm SRAM.bin
