	CPU	68000

;;;
;;; Universal Monitor "BIOS" Call Addresses
;;;
CONIN	EQU	$813B4		; Read 1 character from console to D0.B
CONOUT	EQU	$813D4		; Write 1 character in D0.B to console
STROUT	EQU	$80752		; Print string pointed by A0 (null-terminated)
CRLF	EQU	$807C6		; Print CR/LF
HEXOUT2	EQU	$80770		; Print D0.B as 2-digit hex
HEXOUT4	EQU	$80768		; Print D0.W as 4-digit hex
HEXOUT8	EQU	$80760		; Print D0.L as 8-digit hex
GETLIN	EQU	$807D6		; Get line input from console

;;;
;;; User Program Area (RAM starts at $000000, 500KiB available)
;;; We start from $000400 to avoid clobbering the exception vectors (0x0-0x3FF)
;;;
	ORG	$000400

START:
	;; --- ここからコードを書き始められます ---

LOOP:
	;; "Hello, 68000 World!" を無限に表示し続ける
	LEA	MSG_HELLO,A0
	JSR	STROUT
	
	;; 少しウェイトを入れる場合はここに遅延処理を書きます
	;; 今回はフルスピードで出力し続けます
	BRA	LOOP

;;;
;;; Data Area
;;;
MSG_HELLO:
	DC.B	"Hello, 68000 World!", $0D, $0A, 0

