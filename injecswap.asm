
INCLUDE "hardware.inc"
    rev_Check_hardware_inc 2.6


SECTION "Vectors", ROM0[$000]

rst00: ; memcpy
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, rst00
; rst08:
    ret
    ds 6

memsetLoop:
    ld a, d
rst10: ; memset
    ld d, a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, memsetLoop
    ret

rst18: ; strcpy
    ld a, [de]
    ld [hli], a
    inc de
    and a
    jr nz, rst18
    ret
    ds 1


SECTION "Loader", ROM0[$100]

EntryPoint:
    di
    jr Start

REPT $150 - $103
    db 0
ENDR

Start::
    ; Put stack in HRAM for later cartswap
    ld sp, $FFFF
    push af ; Save init value

    ; Shut LCD down
.waitVBlank
    ld a, [rLY]
    cp $90
    jr c, .waitVBlank
    xor a
    ld [rLCDC], a


    ; Clear $00 tile
    ld hl, $9000
    ld bc, $10
    rst $10 ; memset

    ; Switch to gfx bank
    inc a ; ld a, 1
    ld [rROMB0], a

    ; Load font
    ld hl, $9200
    ld de, FontTiles
    ld bc, FontTilesEnd - FontTiles
    rst $00 ; memcpy

    ; Clear tilemap
    ld hl, _SCRN0
    ld bc, SCRN_VY_B * SCRN_VX_B * 2
    xor a
    rst $10 ; memset


    ; Init common regs
    ld [rSCX], a
    ld [rSCY], a
    ld [rIE], a

    ; Common string dest
    ld hl, _SCRN0 + SCRN_Y_B / 2 * SCRN_VX_B

    pop af ; Get back init value
    cp $11
    jr z, .CGBInit

    ; Copy CGB-only str to screen
    ld de, CGBOnlyStr
    rst $18 ; strcpy

    ; Init DMG video regs
    ld a, $E4
    ld [rBGP], a

    scf ; Set C flag for later softlock
    jr .initDone

.CGBInit
    ld de, CopyingDataStr
    rst $18 ; strcpy

    ld hl, _SCRN1 + 9 * SCRN_VX_B + 8
    ld de, DoneStr
    rst $18 ; strcpy

    ; Load BG palette
    ld hl, CGBPal
    ld a, $80
    ld bc, 4 * 2 << 8 | LOW(rBCPS)
    ld [$ff00+c], a
    inc c
.loadPal
    ld a, [hli]
    ld [$ff00+c], a
    dec b
    jr nz, .loadPal

    ; Clear attribute maps
    ld a, 1
    ld [rVBK], a

    ld hl, _SCRN0
    ; b = 0
    ld bc, SCRN_VX_B * SCRN_VY_B * 2
    xor a
    rst $10 ; memset

    ; xor a
    ld [rVBK], a
    ; Carry is reset

.initDone


    ; Turn on LCD
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a

    ; Softlock if on DMG
    jr nc, .skipDMGSoftlock
    halt ; Will softlock since IE is zero
.skipDMGSoftlock


    ; Copy loader to HRAM
    ld bc, (LoaderEnd - Loader) << 8 | LOW(_HRAM)
    ld hl, Loader
.copyLoader
    ld a, [hli]
    ld [$ff00+c], a
    inc c
    dec b
    jr nz, .copyLoader


    ; Copy save file to WRAM
    ld a, BANK(SaveFileSection1)
    ld [rROMB0], a

    ld hl, _RAM ; Copy first block to WRAM0
    ld de, SaveFileSection1
    xor a
.copyOneBank
    push af ; Save section ID
    ld [rSVBK], a

    ld bc, $1000
    rst $00 ; memcpy

    ld h, $D0 ; Copy subsequent blocks to WRAMX
    ld a, d
    cp $80
    jr nz, .dontSwapBanks
    ld a, BANK(SaveFileSection2)
    ld [rROMB0], a
    ld d, HIGH(SaveFileSection2)
.dontSwapBanks

    pop af
    inc a
    cp a, 8
    jr nz, .copyOneBank


    ; Do as much prep work for the loader as possible, it needs to be as tiny as possible
    xor a
    ld [rIF], a
    ld [rP1], a
    ld a, $10
    ld [rIE], a

    ; Run loader
    jp _HRAM


SECTION "Loader source", ROM0

Loader:
    ; Go into deep sleep for cartswap
    stop


    ; Copy save file from WRAM
    ld a, CART_RAM_ENABLE
    ld [rRAMG], a

    ld hl, _RAM ; Copy first block to WRAM0
    ld de, _SRAM
    xor a
.copyOneBank
    push af ; Save section ID
    ld [rSVBK], a
    rra ; Carry is always clear
    ld [rRAMB], a

    ld bc, $1000
.copyBlock
    ld a, [hli]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .copyBlock

    ld h, $D0 ; Copy subsequent blocks to WRAMX
    ld a, d
    cp $C0
    jr nz, .dontResetDest
    ld d, HIGH(_SRAM)
.dontResetDest

    pop af
    inc a
    and a, 7
    jr nz, .copyOneBank

    ld a, LCDCF_ON | LCDCF_BG9C00 | LCDCF_BGON
    ld [rLCDC], a

    jr @
LoaderEnd:



SECTION "Gfx data", ROMX,BANK[1]

CGBPal:
    dw $7FFF, $56B5, $294A, $0000

CGBOnlyStr:
    db "    Please use a                "
    db "   Game Boy Color",0

CopyingDataStr:
    db "    Copying data",0

DoneStr:
    db "Done",0


FontTiles:
    dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 ; Space
	
	; Symbols 1
	dw $8000, $8000, $8000, $8000, $8000, $0000, $8000, $0000
	dw $0000, $6C00, $6C00, $4800, $0000, $0000, $0000, $0000
	dw $4800, $FC00, $4800, $4800, $4800, $FC00, $4800, $0000
	dw $1000, $7C00, $9000, $7800, $1400, $F800, $1000, $0000
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000 ; %, empty slot for now
	dw $6000, $9000, $5000, $6000, $9400, $9800, $6C00, $0000
	dw $0000, $3800, $3800, $0800, $1000, $0000, $0000, $0000
	dw $1800, $2000, $2000, $2000, $2000, $2000, $1800, $0000
	dw $1800, $0400, $0400, $0400, $0400, $0400, $1800, $0000
	dw $0000, $1000, $5400, $3800, $5400, $1000, $0000, $0000
	dw $0000, $1000, $1000, $7C00, $1000, $1000, $0000, $0000
	dw $0000, $0000, $0000, $0000, $3000, $3000, $6000, $0000
	dw $0000, $0000, $0000, $7C00, $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000, $0000, $6000, $6000, $0000
	dw $0000, $0400, $0800, $1000, $2000, $4000, $8000, $0000
	dw $3000, $5800, $CC00, $CC00, $CC00, $6800, $3000, $0000
	dw $3000, $7000, $F000, $3000, $3000, $3000, $FC00, $0000
	dw $7800, $CC00, $1800, $3000, $6000, $C000, $FC00, $0000
	dw $7800, $8C00, $0C00, $3800, $0C00, $8C00, $7800, $0000
	dw $3800, $5800, $9800, $FC00, $1800, $1800, $1800, $0000
	dw $FC00, $C000, $C000, $7800, $0C00, $CC00, $7800, $0000
	dw $7800, $CC00, $C000, $F800, $CC00, $CC00, $7800, $0000
	dw $FC00, $0C00, $0C00, $1800, $1800, $3000, $3000, $0000
	dw $7800, $CC00, $CC00, $7800, $CC00, $CC00, $7800, $0000
	dw $7800, $CC00, $CC00, $7C00, $0C00, $CC00, $7800, $0000
	dw $0000, $C000, $C000, $0000, $C000, $C000, $0000, $0000
	dw $0000, $C000, $C000, $0000, $C000, $4000, $8000, $0000
	dw $0400, $1800, $6000, $8000, $6000, $1800, $0400, $0000
	dw $0000, $0000, $FC00, $0000, $FC00, $0000, $0000, $0000
	dw $8000, $6000, $1800, $0400, $1800, $6000, $8000, $0000
	dw $7800, $CC00, $1800, $3000, $2000, $0000, $2000, $0000
	dw $0000, $2000, $7000, $F800, $F800, $F800, $0000, $0000 ; "Up" arrow, not ASCII but otherwise unused :P
	
	; Uppercase
	dw $3000, $4800, $8400, $8400, $FC00, $8400, $8400, $0000
	dw $F800, $8400, $8400, $F800, $8400, $8400, $F800, $0000
	dw $3C00, $4000, $8000, $8000, $8000, $4000, $3C00, $0000
	dw $F000, $8800, $8400, $8400, $8400, $8800, $F000, $0000
	dw $FC00, $8000, $8000, $FC00, $8000, $8000, $FC00, $0000
	dw $FC00, $8000, $8000, $FC00, $8000, $8000, $8000, $0000
	dw $7C00, $8000, $8000, $BC00, $8400, $8400, $7800, $0000
	dw $8400, $8400, $8400, $FC00, $8400, $8400, $8400, $0000
	dw $7C00, $1000, $1000, $1000, $1000, $1000, $7C00, $0000
	dw $0400, $0400, $0400, $0400, $0400, $0400, $F800, $0000
	dw $8400, $8800, $9000, $A000, $E000, $9000, $8C00, $0000
	dw $8000, $8000, $8000, $8000, $8000, $8000, $FC00, $0000
	dw $8400, $CC00, $B400, $8400, $8400, $8400, $8400, $0000
	dw $8400, $C400, $A400, $9400, $8C00, $8400, $8400, $0000
	dw $7800, $8400, $8400, $8400, $8400, $8400, $7800, $0000
	dw $F800, $8400, $8400, $F800, $8000, $8000, $8000, $0000
	dw $7800, $8400, $8400, $8400, $A400, $9800, $6C00, $0000
	dw $F800, $8400, $8400, $F800, $9000, $8800, $8400, $0000
	dw $7C00, $8000, $8000, $7800, $0400, $8400, $7800, $0000
	dw $7C00, $1000, $1000, $1000, $1000, $1000, $1000, $0000
	dw $8400, $8400, $8400, $8400, $8400, $8400, $7800, $0000
	dw $8400, $8400, $8400, $8400, $8400, $4800, $3000, $0000
	dw $8400, $8400, $8400, $8400, $B400, $CC00, $8400, $0000
	dw $8400, $8400, $4800, $3000, $4800, $8400, $8400, $0000
	dw $4400, $4400, $4400, $2800, $1000, $1000, $1000, $0000
	dw $FC00, $0400, $0800, $1000, $2000, $4000, $FC00, $0000
	
	; Symbols 2
	dw $3800, $2000, $2000, $2000, $2000, $2000, $3800, $0000
	dw $0000, $8000, $4000, $2000, $1000, $0800, $0400, $0000
	dw $1C00, $0400, $0400, $0400, $0400, $0400, $1C00, $0000
	dw $1000, $2800, $0000, $0000, $0000, $0000, $0000, $0000
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $FF00
	dw $C000, $6000, $0000, $0000, $0000, $0000, $0000, $0000
	
	; Lowercase
	dw $0000, $0000, $7800, $0400, $7C00, $8400, $7800, $0000
	dw $8000, $8000, $8000, $F800, $8400, $8400, $7800, $0000
	dw $0000, $0000, $7C00, $8000, $8000, $8000, $7C00, $0000
	dw $0400, $0400, $0400, $7C00, $8400, $8400, $7800, $0000
	dw $0000, $0000, $7800, $8400, $F800, $8000, $7C00, $0000
	dw $0000, $3C00, $4000, $FC00, $4000, $4000, $4000, $0000
	dw $0000, $0000, $7800, $8400, $7C00, $0400, $F800, $0000
	dw $8000, $8000, $F800, $8400, $8400, $8400, $8400, $0000
	dw $0000, $1000, $0000, $1000, $1000, $1000, $1000, $0000
	dw $0000, $1000, $0000, $1000, $1000, $1000, $E000, $0000
	dw $8000, $8000, $8400, $9800, $E000, $9800, $8400, $0000
	dw $1000, $1000, $1000, $1000, $1000, $1000, $1000, $0000
	dw $0000, $0000, $6800, $9400, $9400, $9400, $9400, $0000
	dw $0000, $0000, $7800, $8400, $8400, $8400, $8400, $0000
	dw $0000, $0000, $7800, $8400, $8400, $8400, $7800, $0000
	dw $0000, $0000, $7800, $8400, $8400, $F800, $8000, $0000
	dw $0000, $0000, $7800, $8400, $8400, $7C00, $0400, $0000
	dw $0000, $0000, $BC00, $C000, $8000, $8000, $8000, $0000
	dw $0000, $0000, $7C00, $8000, $7800, $0400, $F800, $0000
	dw $0000, $4000, $F800, $4000, $4000, $4000, $3C00, $0000
	dw $0000, $0000, $8400, $8400, $8400, $8400, $7800, $0000
	dw $0000, $0000, $8400, $8400, $4800, $4800, $3000, $0000
	dw $0000, $0000, $8400, $8400, $8400, $A400, $5800, $0000
	dw $0000, $0000, $8C00, $5000, $2000, $5000, $8C00, $0000
	dw $0000, $0000, $8400, $8400, $7C00, $0400, $F800, $0000
	dw $0000, $0000, $FC00, $0800, $3000, $4000, $FC00, $0000
	
	; Symbols 3
	dw $1800, $2000, $2000, $4000, $2000, $2000, $1800, $0000
	dw $1000, $1000, $1000, $1000, $1000, $1000, $1000, $0000
	dw $3000, $0800, $0800, $0400, $0800, $0800, $3000, $0000
	dw $0000, $0000, $4800, $A800, $9000, $0000, $0000, $0000
	
	dw $C000, $E000, $F000, $F800, $F000, $E000, $C000, $0000 ; Left arrow
FontTilesEnd:



SECTION "Save file banks 0-1", ROMX,BANK[2]

SaveFileSection1:
INCBIN "SRAM.bin", 0, $4000


SECTION "Save file banks 2-3", ROMX,BANK[3]

SaveFileSection2:
INCBIN "SRAM.bin", $4000, $4000
