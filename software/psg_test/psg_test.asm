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
;;; SN76489 PSG Address
;;;
PSG_PORT	EQU	$0A2000

;;;
;;; User Program Area (RAM starts at $000000, 500KiB available)
;;; We start from $000400 to avoid clobbering the exception vectors (0x0-0x3FF)
;;;
	ORG	$000400

START:
	;; --- ここからコードを書き始められます ---



	;; データバスが逆順(D7..D0 -> D0..D7)に配線されているため、
	;; 出力するデータはすべてビットを反転(MSB<->LSB)して送信します。

	;; 全チャンネルを無音(ミュート)に初期化
	;; 元データ: $9F (10011111) -> 逆順: $F9 (11111001)
	MOVE.B	#$F9, PSG_PORT	; Ch1 Vol = 15 (OFF)
	;; 元データ: $BF (10111111) -> 逆順: $FD (11111101)
	MOVE.B	#$FD, PSG_PORT	; Ch2 Vol = 15 (OFF)
	;; 元データ: $DF (11011111) -> 逆順: $FB (11111011)
	MOVE.B	#$FB, PSG_PORT	; Ch3 Vol = 15 (OFF)
	;; 元データ: $FF (11111111) -> 逆順: $FF (11111111)
	MOVE.B	#$FF, PSG_PORT	; Noise Vol = 15 (OFF)

	;; Ch1の周波数を設定 (例: 分周比 254 = $0FE -> 約440Hz / 3.58MHz時)
	;; コマンド: 1000(Ch1 Tone) + Freq下位4bit($E) = $8E (10001110)
	;; -> 逆順: $71 (01110001)
	MOVE.B	#$71, PSG_PORT
	;; コマンド: 0(データ) + Freq上位6bit($0F) = $0F (00001111)
	;; -> 逆順: $F0 (11110000)
	MOVE.B	#$F0, PSG_PORT

	;; Ch1のボリュームを最大に設定
	;; コマンド: 1001(Ch1 Vol) + Vol($0:最大) = $90 (10010000)
	;; -> 逆順: $09 (00001001)
	MOVE.B	#$09, PSG_PORT

LOOP:
	;; 無限ループ (音は鳴り続けます)
	BRA	LOOP

