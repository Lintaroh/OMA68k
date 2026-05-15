;;;
;;;	MC68681 (DUART) Console Driver
;;;

MR1A:	EQU	DUBASE+ 0*2	; Mode Register 1 A          (R/W)
MR2A:	EQU	DUBASE+ 0*2	; Mode Register 2 A          (R/W)
SRA:	EQU	DUBASE+ 1*2	; Status Register A          (R)
CSRA:	EQU	DUBASE+ 1*2	; Clock Select Register A      (W)
CRA:	EQU	DUBASE+ 2*2	; Command Register A           (W)
RBA:	EQU	DUBASE+ 3*2	; Receiver Buffer A          (R)
TBA:	EQU	DUBASE+ 3*2	; Transmitter Buffer A         (W)

IPCR:	EQU	DUBASE+ 4*2	; Input Port Change Register (R)
ACR:	EQU	DUBASE+ 4*2	; Auxiliary Control Register   (W)
ISR:	EQU	DUBASE+ 5*2	; Interrupt Status Register  (R)
IMR:	EQU	DUBASE+ 5*2	; Interrupt Mask Register      (W)
CUR:	EQU	DUBASE+ 6*2	; Counter Mode: Current MSB of Counter (R)
CTUR:	EQU	DUBASE+ 6*2	; Counter/Timer Upper Register (W)
CLR:	EQU	DUBASE+ 7*2	; Counter Mode: Current LSB of Counter (R)
CTLR:	EQU	DUBASE+ 7*2	; Counter/Timer Lower Register (W)

MR1B:	EQU	DUBASE+ 8*2	; Mode Register 1 B          (R/W)
MR2B:	EQU	DUBASE+ 8*2	; Mode Register 2 B          (R/W)
SRB:	EQU	DUBASE+ 9*2	; Status Register B          (R)
CSRB:	EQU	DUBASE+ 9*2	; Clock Select Register B      (W)
CRB:	EQU	DUBASE+10*2	; Command Register B           (W)
RBB:	EQU	DUBASE+11*2	; Receiver Buffer B          (R)
TBB:	EQU	DUBASE+11*2	; Transmitter Buffer B         (W)

INIT:
	;; Channel A
	MOVE.B	#$10,CRA	; Reset MR pointer
	MOVE.B	#MR1A_V,MR1A
	MOVE.B	#MR2A_V,MR2A

	;; Channel B
	MOVE.B	#$10,CRB	; Reset MR pointer
	MOVE.B	#MR1A_V,MR1B
	MOVE.B	#MR2A_V,MR2B

	RTS

CONIN:
	MOVE.B	SRA,D0
	AND.B	#$01,D0
	BEQ	CONIN
	MOVE.B	RBA,D0

	RTS

CONST:
	MOVE.B	SRA,D0
	AND.B	#$01,D0

	RTS

CONOUT:
	SWAP	D0
CO0:
	MOVE.B	SRA,D0
	AND.B	#$04,D0
	BEQ	CO0
	SWAP	D0
	MOVE.B	D0,TBA

	RTS
