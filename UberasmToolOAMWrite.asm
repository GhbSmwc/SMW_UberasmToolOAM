;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Make sure you have the index register be 16-bit (REP #$10)
;and A be 8-bit (SEP #$20) before calling this.
;
;Input:
;OAM writer for uberasm tool
;Make sure you have the index processor flag be 16-bit (REP #$10).
;
; Y (16-bit): the starting index to search for OAM.
;             Y = 508 ($1FC) would search all 128 slots.
; $00-$01:    OAM X position
; $02-$03:    OAM Y position
; $04:        OAM tile number
; $05:        OAM tile properties
; $06:        Tile size (0 = 8x8, 1 = 16x16)
;
;Output:
; Y (16-bit): Index that represent the previous slot that
;             is free.
;             if Y = $FFFC, then all slots are taken.
; Carry:      Set if offscreen and clear if onscreen.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteOAM:
	.FindFreeSlot
	..Loop
	LDA $0201|!addr,y		;>Y position
	CMP #$F0			;\Free slot found.
	BEQ .SlotFound			;/
	
	...Next
	DEY #4				;\Next group of 4 bytes
	BPL ..Loop			;/
	SEP #$20
	RTL
	
	.SlotFound
	LDA $04				;\Tile number
	STA $0202|!addr,y		;/
	LDA $05				;\Tile properties
	STA $0203|!addr,y		;/
	
	..YPosHandle
	REP #$20			;\Don't take up a slot of offscreen vertically.
	LDA $02				;|
	CMP #$00E0			;|
	BCC .HandleXPos			;|
	CMP #$FFF1			;|
	BCS .HandleXPos			;/

	.OffScreen
	SEP #$20
	LDA #$F0			;\Be a free slot and not write.
	STA $0201|!addr,y		;/
	SEC
	RTL
	
	.HandleXPos
	SEP #$20
	LDA $02				;\Y position
	STA $0201|!addr,y		;/
	
	..XPositionHandle
	LDA $06					;\Position #$FFF8 is invisible for 8x8 tiles and
	ASL					;|Position #$FFF0 is invisible for 16x16 tiles.
	TAX					;/
	REP #$20
	LDA $00					;\Determine if on-screen horizontally
	CMP #$0100				;|
	BCC ..OnScreenHoriz			;|
	CMP LeftScreenBoundaryPos,x		;|
	BCS ..OnScreenHoriz			;/
	BRA .OffScreen				;>If not skip the whole thing.
	
	..OnScreenHoriz
	SEP #$20
	LDA $00					;\X position bits 0-7
	STA $0200|!addr,y			;/
	
	print "---------------------------------",pc
	REP #$20
	TYA			;>Take index
	LSR #2			;>Divide by 4 to obtain slot number
	SEP #$20		;\Round down to the nearest 4th value (Value = floor(SlotNumb/4)*4)
	AND.b #%11111100	;/
	STA $02			;>Store $0420 indexer to $02
	REP #$20
	TYA			;>Transfer IndexNumb to A
	LSR #2			;>Convert IndexNumb -> SlotNumb
	SEP #$20
	AND.b #%00000011	;>MOD 4
	STA $03			;>Store pair bits position to $03.
	
	PHY
	REP #$20
	LDA $02			;\Because indexes must be 16-bit, I had to clear their high bytes.
	AND #$00FF		;|
	TAY			;/
	LDA $03
	AND #$00FF
	TAX
	SEP #$20
	LDA $01			;\If X position negative, set bit to enable tile
	BNE ...SetXPosBit8	;/exceeding the left edge of screen without wrapping.
	
	...ClearXPosBit8
	LDA BitTableXHigh,x
	EOR #$FF
	AND $0420|!addr,y
	STA $0420|!addr,y
	BRA ...TileSize
	
	...SetXPosBit8
	LDA $0420|!addr,y
	ORA BitTableXHigh,x
	STA $0420|!addr,y
	
	...TileSize
	LDA $06
	BNE ...SixteenBySixteenTile
	
	...EightByEightTile
	LDA BitTableTileSize,x
	EOR #$FF
	AND $0420|!addr,y
	STA $0420|!addr,y
	BRA .Done
	
	...SixteenBySixteenTile
	LDA $0420|!addr,y
	ORA BitTableTileSize,x
	STA $0420|!addr,y
	
	.Done
	PLY
	DEY #4
	CLC
	RTL
	
	LeftScreenBoundaryPos:
	dw $FFF9, $FFF1

	BitTableXHigh:
	db %00000001
	db %00000100
	db %00010000
	db %01000000
	
	BitTableTileSize:
	db %00000010
	db %00001000
	db %00100000
	db %10000000