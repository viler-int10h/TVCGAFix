:: TV_BOOT has to be assembled before MAKEBOOT:

fasm TV_BOOT.ASM -s TV_BOOT.FAS && listing -a TV_BOOT.FAS TV_BOOT.LST

:: TVCGAFIX has to be assembled before TV80 and TVCGACAL:

del tsr_pos.inc
fasm TVCGAFIX.ASM -s TVCGAFIX.FAS > ___tmp.txt
type ___tmp.txt
listing -a TVCGAFIX.FAS TVCGAFIX.LST
for /f "tokens=* eol=2 skip=1" %%a in (___tmp.txt) do @echo %%a >> tsr_pos.inc

for %%A in (MAKEBOOT.ASM TV80.ASM TVCGACAL.ASM) do (fasm %%A -s %%~nA.fas && listing -a %%~nA.fas %%~nA.lst)

:: clean up after ourselves

del *.fas
del TV_BOOT.BIN
del ___tmp.txt
