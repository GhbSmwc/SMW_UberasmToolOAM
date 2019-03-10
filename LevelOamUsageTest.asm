!Freeram_OAMXPos = $60
!Freeram_OAMYPos = $62
main:
	LDA $15
	BIT.b #%00000010
	BNE .Left
	BIT.b #%00000001
	BNE .Right
	BRA +
	
	.Left
	REP #$20
	DEC !Freeram_OAMXPos
	SEP #$20
	BRA +
	
	.Right
	REP #$20
	INC !Freeram_OAMXPos
	SEP #$20
	
	+
	LDA $15
	BIT.b #%00001000
	BNE .Up
	BIT.b #%00000100
	BNE .Down
	BRA +
	
	.Up
	REP #$20
	DEC !Freeram_OAMYPos
	SEP #$20
	BRA +
	
	.Down
	REP #$20
	INC !Freeram_OAMYPos
	SEP #$20
	
	+
	REP #$30
	LDA !Freeram_OAMXPos
	STA $00
	LDA !Freeram_OAMYPos
	STA $02
	SEP #$20
	LDA #$40
	STA $04
	LDA.b #%00110000
	STA $05
	LDA #$01
	STA $06
	LDY #$01FC
	JSL LibraryOAMWrite_WriteOAM
	
	;Second OAM slot test
	REP #$20
	LDA !Freeram_OAMXPos
	CLC
	ADC #$0010
	STA $00
	LDA !Freeram_OAMYPos
	STA $02
	SEP #$20
	LDA #$40
	STA $04
	LDA.b #%00110000
	STA $05
	LDA #$01
	STA $06
	JSL LibraryOAMWrite_WriteOAM
	SEP #$30
	RTL