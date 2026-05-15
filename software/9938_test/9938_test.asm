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

;;;
;;; V9938 Address Mapping
;;; (000A0000hからマッピングされているとのこと)
;;;
VDP_BASE	EQU	$0A0000

	ORG	$000400

START:
	;; タイトルメッセージ出力
	LEA	MSG_START,A0
	JSR	STROUT

	;; 1. VDP空間(A00000 - A0000F)の16バイトダンプ
	;; (Even/Oddどちらにマッピングされていても読み出せるようにするため)
	LEA	MSG_DUMP,A0
	JSR	STROUT
	MOVE.L	#VDP_BASE,A1
	MOVE.W	#15,D1
DUMP_LOOP:
	MOVE.B	(A1)+,D0
	JSR	HEXOUT2
	MOVE.B	#' ',D0
	JSR	CONOUT
	DBRA	D1,DUMP_LOOP
	JSR	CRLF

	;; 2. VBlankステータスリードテスト
	;; V9938はPort 1 (Command Port)を読むと、Status Register 0が読めます。
	;; bit 7にV-Blankフラグがあり、約1/60秒ごとに1になり、読むと0クリアされます。
	;; データバスが逆順なら bit 0 に現れる可能性があります。
	;; ここでは、Even($A0002)とOdd($A0003)の両方のポートを少しの間監視し、
	;; 値が変化したら出力します。
	
	;; --- Even側の監視 ($A0002) ---
	LEA	MSG_STAT_EVEN,A0
	JSR	STROUT
	MOVE.L	#$0A0002,A1
	BSR	MONITOR_PORT

	;; --- Odd側の監視 ($A0003) ---
	LEA	MSG_STAT_ODD,A0
	JSR	STROUT
	MOVE.L	#$0A0003,A1
	BSR	MONITOR_PORT

	;; テスト終了、モニタに制御を戻す (RTS)
	LEA	MSG_DONE,A0
	JSR	STROUT
	RTS

;;;
;;; サブルーチン: A1で指定されたポートを一定回数読み、値が変わったら表示
;;;
MONITOR_PORT:
	MOVE.W	#64,D2		; 最大64回変化を検出、またはタイムアウトで抜ける
	MOVE.B	(A1),D3		; 初期値を読む
	MOVE.W	#200,D4		; タイムアウト用ループカウンタ

MON_LOOP:
	;; 少しウェイトを入れる (1/60秒を跨ぐため)
	MOVE.W	#50000,D1
WAIT_LOOP:
	NOP
	DBRA	D1,WAIT_LOOP

	MOVE.B	(A1),D0		; ポートを読む
	CMP.B	D0,D3		; 前回の値と比較
	BEQ	MON_NEXT	; 変化なしなら次へ

	;; 値が変化した！
	MOVE.B	D0,D3		; 新しい値を保存
	JSR	HEXOUT2		; 変化した値を表示
	MOVE.B	#' ',D0
	JSR	CONOUT

	SUBQ.W	#1,D2
	BEQ	MON_END		; 64回変化したら終わり

MON_NEXT:
	DBRA	D4,MON_LOOP	; タイムアウトまでループ

MON_END:
	JSR	CRLF
	RTS

;;;
;;; Data Area
;;;
MSG_START:
	DC.B	"--- V9938 Access Test ---", $0D, $0A, 0
MSG_DUMP:
	DC.B	"Port Dump (A00000-A0000F): ", 0
MSG_STAT_EVEN:
	DC.B	"Monitor Even Command Port (A00002): ", 0
MSG_STAT_ODD:
	DC.B	"Monitor Odd Command Port (A00003): ", 0
MSG_DONE:
	DC.B	"Test Complete. Return to Monitor.", $0D, $0A, 0

	ALIGN 2
