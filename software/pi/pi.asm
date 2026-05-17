;;; ============================================================
;;;   pi.asm  -  Infinite Pi Digit Generator (Spigot Algorithm)
;;;   MC68008/68000
;;;
;;;   Streams decimal digits of pi to the serial console forever.
;;;   Based on the unbounded spigot algorithm by Gibbons (2006),
;;;   using the continued-fraction / LFT composition method.
;;;
;;;   Algorithm overview:
;;;     Pi can be expressed as the composition of an infinite
;;;     sequence of Moebius (linear fractional) transformations:
;;;       T_k = ( k, 4*k+2, 0, 2*k+1 )   for k = 1, 2, 3, ...
;;;
;;;     We maintain a composed transformation Z = (q, r, s, t)
;;;     starting from the identity (1, 0, 0, 1).
;;;
;;;     At each step:
;;;       1. Extract a trial digit: d = floor( (3*q + r) / (3*s + t) )
;;;          (safe estimate using floor( (q*3+r) / (s*3+t) ))
;;;       2. Check safety:  d == floor( (4*q + r) / (4*s + t) ) ?
;;;          (i.e. floor( (q*4+r) / (s*4+t) ))
;;;       3. If safe:
;;;            - Output digit d
;;;            - Update Z by "consuming" the digit:
;;;              Z' = ( 10*(q - d*s), 10*(r - d*t), s, t )
;;;       4. If not safe:
;;;            - "Produce" (compose) the next T_k into Z:
;;;              Z' = ( q*k, q*(4*k+2) + r*(2*k+1),
;;;                      s*k, s*(4*k+2) + t*(2*k+1) )
;;;              then increment k.
;;;
;;;   All arithmetic uses 32-bit signed integers.
;;;   When values overflow, the algorithm gracefully wraps and
;;;   will produce incorrect digits eventually, but for a 68000
;;;   with 32-bit MULS (16x16->32) this gives many correct digits.
;;;
;;;   To handle larger ranges, we use a software multiply
;;;   routine (MUL32) that does full 32x32->32 multiplication.
;;;
;;;   Monitor I/O  (from Monitor/unimon_68000.lst):
;;;     CONOUT = $0008141A   (D0.B = char to output)
;;;     CONIN  = $000813FA   (returns D0.B = char)
;;;     CONST  = $0008140E   (D0.B != 0 if key pressed)
;;;     STROUT = $0008079E   (A0 = ptr to null-terminated string)
;;;     CRLF   = $00080812   (outputs CR+LF)
;;; ============================================================

        CPU     68000
        SUPMODE ON

;;; ---- Monitor entry points --------------------------------
CONOUT  EQU     $8141A
CONIN   EQU     $813FA
CONST   EQU     $8140E
STROUT  EQU     $8079E
CRLF    EQU     $80812

;;; ---- RAM work area ----------------------------------------
;;; We place our variables in low RAM, after the program code.
;;; The LFT state (q, r, s, t) and counter k are kept in RAM.

;;; ---- Constants -------------------------------------------
DIGITS_PER_LINE EQU  64         ; digits per output line
DIGITS_PER_GRP  EQU  10         ; digits per group (space separator)

;;; ===========================================================
        ORG     $00000400

;;; -----------------------------------------------------------
;;; START - Main entry point
;;; -----------------------------------------------------------
START:
        LEA     MSG_HDR,A0
        JSR     STROUT

        ;; Initialize LFT state: Z = identity = (1, 0, 0, 1)
        MOVE.L  #1,ZQ
        MOVE.L  #0,ZR
        MOVE.L  #0,ZS
        MOVE.L  #1,ZT

        ;; k = 1 (continued fraction index)
        MOVE.L  #1,KK

        ;; Digit counters
        CLR.L   DCNT            ; total digits output
        CLR.L   LCNT            ; digits on current line

        ;; Output "3." first digit is always 3 but let algorithm produce it
        ;; Actually, let the algorithm produce all digits naturally.

;;; -----------------------------------------------------------
;;; MAIN_LOOP - Produce digits of pi one at a time
;;; -----------------------------------------------------------
MAIN_LOOP:
        ;; Step 1: Extract trial digit d = floor((3*q + r) / (3*s + t))
        ;;
        ;; Compute numerator: 3*q + r
        MOVE.L  ZQ,D0
        MOVE.L  D0,D1
        ADD.L   D0,D0           ; D0 = 2*q
        ADD.L   D1,D0           ; D0 = 3*q
        ADD.L   ZR,D0           ; D0 = 3*q + r  (numerator for extract)
        MOVE.L  D0,-(A7)        ; save numerator on stack

        ;; Compute denominator: 3*s + t
        MOVE.L  ZS,D1
        MOVE.L  D1,D2
        ADD.L   D1,D1           ; D1 = 2*s
        ADD.L   D2,D1           ; D1 = 3*s
        ADD.L   ZT,D1           ; D1 = 3*s + t  (denominator)

        ;; D0 = numerator, D1 = denominator
        ;; Compute floor division: D0 / D1 -> D0 (quotient)
        MOVE.L  (A7)+,D0        ; restore numerator
        BSR     SDIV32          ; D0 = floor(D0 / D1)
        MOVE.L  D0,D3           ; D3 = trial digit d

        ;; Step 2: Check safety
        ;; d_check = floor((4*q + r) / (4*s + t))
        MOVE.L  ZQ,D0
        LSL.L   #2,D0           ; D0 = 4*q
        ADD.L   ZR,D0           ; D0 = 4*q + r

        MOVE.L  ZS,D1
        LSL.L   #2,D1           ; D1 = 4*s
        ADD.L   ZT,D1           ; D1 = 4*s + t

        BSR     SDIV32          ; D0 = floor((4*q+r) / (4*s+t))

        CMP.L   D3,D0           ; d_check == d ?
        BNE     PRODUCE         ; not safe -> compose next T_k

        ;; ---- Safe: output digit d and consume it ----
OUTPUT_DIGIT:
        ;; Print the digit
        MOVE.L  D3,D0
        ADD.B   #'0',D0         ; convert to ASCII
        JSR     CONOUT

        ;; Increment digit counters
        ADDQ.L  #1,DCNT
        ADDQ.L  #1,LCNT

        ;; After first digit, print decimal point
        CMP.L   #1,DCNT
        BNE.S   .no_point
        MOVE.B  #'.',D0
        JSR     CONOUT
        BRA.S   .check_line
.no_point:
        ;; Group separator (space every DIGITS_PER_GRP digits after decimal point)
        ;; Actual position after decimal = DCNT - 1
        MOVE.L  DCNT,D0
        SUBQ.L  #1,D0           ; position after decimal point
        DIVU.W  #DIGITS_PER_GRP,D0
        SWAP    D0              ; remainder in low word
        TST.W   D0
        BNE.S   .check_line
        MOVE.B  #' ',D0
        JSR     CONOUT

.check_line:
        ;; Line break every DIGITS_PER_LINE digits (after decimal point)
        MOVE.L  DCNT,D0
        SUBQ.L  #1,D0
        BEQ.S   .consume        ; don't break after "3."
        DIVU.W  #DIGITS_PER_LINE,D0
        SWAP    D0
        TST.W   D0
        BNE.S   .consume
        JSR     CRLF

.consume:
        ;; Consume digit: Z' = (10*(q - d*s), 10*(r - d*t), s, t)
        ;; new_q = 10 * (q - d * s)
        MOVE.L  D3,D0           ; d
        MOVE.L  ZS,D1           ; s
        BSR     MUL32           ; D0 = d * s
        MOVE.L  ZQ,D1
        SUB.L   D0,D1           ; D1 = q - d*s
        MOVE.L  D1,D0
        MOVE.L  #10,D1
        BSR     MUL32           ; D0 = 10 * (q - d*s)
        MOVE.L  D0,ZQ

        ;; new_r = 10 * (r - d * t)
        MOVE.L  D3,D0           ; d
        MOVE.L  ZT,D1           ; t
        BSR     MUL32           ; D0 = d * t
        MOVE.L  ZR,D1
        SUB.L   D0,D1           ; D1 = r - d*t
        MOVE.L  D1,D0
        MOVE.L  #10,D1
        BSR     MUL32           ; D0 = 10 * (r - d*t)
        MOVE.L  D0,ZR

        ;; s and t unchanged
        ;; Check for key press to stop
        JSR     CONST
        TST.B   D0
        BNE     DONE

        BRA     MAIN_LOOP

;;; -----------------------------------------------------------
;;; PRODUCE - Compose next T_k into Z
;;;   T_k = ( k, 4*k+2, 0, 2*k+1 )
;;;   Z' = Z * T_k  (matrix multiply):
;;;     new_q = q * k
;;;     new_r = q * (4*k+2) + r * (2*k+1)
;;;     new_s = s * k
;;;     new_t = s * (4*k+2) + t * (2*k+1)
;;; -----------------------------------------------------------
PRODUCE:
        MOVE.L  KK,D4           ; D4 = k

        ;; Compute 2*k+1 and 4*k+2
        MOVE.L  D4,D5
        ADD.L   D5,D5           ; D5 = 2*k
        ADDQ.L  #1,D5           ; D5 = 2*k + 1

        MOVE.L  D5,D6
        ADD.L   D6,D6           ; D6 = 2*(2*k+1) = 4*k + 2

        ;; new_q = q * k
        MOVE.L  ZQ,D0
        MOVE.L  D4,D1
        BSR     MUL32
        MOVE.L  D0,-(A7)        ; save new_q on stack

        ;; new_r = q * (4*k+2) + r * (2*k+1)
        MOVE.L  ZQ,D0
        MOVE.L  D6,D1           ; 4*k+2
        BSR     MUL32
        MOVE.L  D0,-(A7)        ; save q*(4k+2) on stack

        MOVE.L  ZR,D0
        MOVE.L  D5,D1           ; 2*k+1
        BSR     MUL32           ; D0 = r*(2k+1)
        ADD.L   (A7)+,D0        ; D0 = q*(4k+2) + r*(2k+1) = new_r
        MOVE.L  D0,-(A7)        ; save new_r

        ;; new_s = s * k
        MOVE.L  ZS,D0
        MOVE.L  D4,D1
        BSR     MUL32
        MOVE.L  D0,-(A7)        ; save new_s

        ;; new_t = s * (4*k+2) + t * (2*k+1)
        MOVE.L  ZS,D0
        MOVE.L  D6,D1           ; 4*k+2
        BSR     MUL32
        MOVE.L  D0,-(A7)        ; save s*(4k+2)

        MOVE.L  ZT,D0
        MOVE.L  D5,D1           ; 2*k+1
        BSR     MUL32           ; D0 = t*(2k+1)
        ADD.L   (A7)+,D0        ; D0 = s*(4k+2) + t*(2k+1) = new_t
        MOVE.L  D0,ZT

        ;; Restore saved values
        MOVE.L  (A7)+,D0        ; new_s
        MOVE.L  D0,ZS
        MOVE.L  (A7)+,D0        ; new_r
        MOVE.L  D0,ZR
        MOVE.L  (A7)+,D0        ; new_q
        MOVE.L  D0,ZQ

        ;; k++
        ADDQ.L  #1,KK

        BRA     MAIN_LOOP

;;; -----------------------------------------------------------
;;; DONE - Key was pressed, clean up and return to monitor
;;; -----------------------------------------------------------
DONE:
        JSR     CONIN           ; consume the key press
        JSR     CRLF
        LEA     MSG_DONE,A0
        JSR     STROUT
        RTS

;;; ============================================================
;;; MUL32 - Signed 32-bit x 32-bit -> 32-bit multiply
;;;   Input:  D0.L = multiplicand, D1.L = multiplier
;;;   Output: D0.L = D0 * D1 (low 32 bits)
;;;   Clobbers: D1, D2
;;; ============================================================
MUL32:
        ;; Save sign: result is negative if signs differ
        MOVE.L  D0,D2
        EOR.L   D1,D2           ; D2 bit 31 = sign of result
        TST.L   D0
        BPL.S   .m_apos
        NEG.L   D0
.m_apos:
        TST.L   D1
        BPL.S   .m_bpos
        NEG.L   D1
.m_bpos:
        ;; Now D0, D1 are both >= 0
        ;; D0 = Ah:Al, D1 = Bh:Bl  (each 16-bit halves)
        ;; Result low 32 = Al*Bl + (Al*Bh + Ah*Bl) << 16
        MOVEM.L D3-D4,-(A7)

        MOVE.L  D0,D3           ; D3 = A
        MOVE.L  D1,D4           ; D4 = B

        ;; Al * Bl  (unsigned 16x16 -> 32)
        MOVE.W  D3,D0
        MULU.W  D4,D0           ; D0.L = Al * Bl

        ;; Al * Bh
        MOVE.W  D3,D1
        SWAP    D4
        MULU.W  D4,D1           ; D1.L = Al * Bh
        SWAP    D1              ; shift left 16 (keep low 16 of result)
        CLR.W   D1              ; mask upper (only care about low 32 of total)
        ADD.L   D1,D0

        ;; Ah * Bl
        SWAP    D3
        SWAP    D4              ; D4 back to original
        MOVE.W  D3,D1
        MULU.W  D4,D1           ; D1.L = Ah * Bl
        SWAP    D1
        CLR.W   D1
        ADD.L   D1,D0

        MOVEM.L (A7)+,D3-D4

        ;; Apply sign
        TST.L   D2
        BPL.S   .m_done
        NEG.L   D0
.m_done:
        RTS

;;; ============================================================
;;; SDIV32 - Signed 32-bit / 32-bit -> 32-bit floor division
;;;   Input:  D0.L = dividend, D1.L = divisor
;;;   Output: D0.L = floor(D0 / D1)
;;;   Clobbers: D1, D2, D3, D4, D5
;;;
;;;   Floor division: rounds toward negative infinity.
;;;   For positive divisor (our case): if dividend < 0 and
;;;   remainder != 0, quotient = -((-dividend)/divisor) - 1
;;; ============================================================
SDIV32:
        TST.L   D1
        BEQ.S   .div_zero       ; safety

        ;; Record signs
        MOVE.L  D0,D2           ; save dividend
        MOVE.L  D1,D3           ; save divisor

        ;; Make both positive
        TST.L   D0
        BPL.S   .d_apos
        NEG.L   D0
.d_apos:
        TST.L   D1
        BPL.S   .d_bpos
        NEG.L   D1
.d_bpos:
        ;; Unsigned division D0 / D1
        BSR     UDIV32          ; D0 = quotient, D1 = remainder

        ;; Determine sign of result
        MOVE.L  D2,D4
        EOR.L   D3,D4           ; D4 bit 31 = sign of quotient

        TST.L   D4
        BPL.S   .d_pos_result

        ;; Negative result
        NEG.L   D0
        TST.L   D1              ; remainder?
        BEQ.S   .d_done
        SUBQ.L  #1,D0           ; floor: round toward -inf
.d_pos_result:
        ;; Positive result - quotient is already correct
.d_done:
        RTS
.div_zero:
        MOVE.L  #0,D0           ; return 0 on divide by zero
        RTS

;;; ============================================================
;;; UDIV32 - Unsigned 32-bit / 32-bit division
;;;   Input:  D0.L = dividend (unsigned), D1.L = divisor (unsigned)
;;;   Output: D0.L = quotient, D1.L = remainder
;;;   Clobbers: D2, D3, D4, D5
;;; ============================================================
UDIV32:
        TST.L   D1
        BEQ.S   .udiv_zero

        ;; Try fast path: if dividend fits in 16 bits or using DIVU
        ;; For general case, use shift-and-subtract algorithm

        MOVEM.L D6-D7,-(A7)

        MOVE.L  D0,D6           ; D6 = dividend
        MOVE.L  D1,D7           ; D7 = divisor
        CLR.L   D0              ; D0 = quotient
        CLR.L   D1              ; D1 = remainder

        MOVEQ   #31,D5          ; bit counter

.udiv_loop:
        ;; Shift dividend left, top bit into remainder
        LSL.L   #1,D6           ; shift dividend left, top bit -> X
        ROXL.L  #1,D1           ; shift X into remainder

        ;; Try subtract
        CMP.L   D7,D1
        BCS.S   .udiv_skip      ; remainder < divisor, skip

        SUB.L   D7,D1           ; remainder -= divisor
        ADDQ.L  #1,D0           ; set bit in quotient
.udiv_skip:
        ;; Shift quotient left for next iteration (except last)
        TST.W   D5
        BEQ.S   .udiv_end
        LSL.L   #1,D0

        DBF     D5,.udiv_loop

.udiv_end:
        MOVEM.L (A7)+,D6-D7
        RTS

.udiv_zero:
        CLR.L   D0
        CLR.L   D1
        RTS

;;; -----------------------------------------------------------
;;; Data - Messages
;;; -----------------------------------------------------------

MSG_HDR:
        DC.B    $0D,$0A
        DC.B    "================================================",$0D,$0A
        DC.B    " Pi Digit Generator  (68000 Spigot Algorithm)",$0D,$0A
        DC.B    " Press any key to stop.",$0D,$0A
        DC.B    "================================================",$0D,$0A
        DC.B    $0D,$0A,$00

MSG_DONE:
        DC.B    $0D,$0A
        DC.B    "================================================",$0D,$0A
        DC.B    " Stopped.",$0D,$0A
        DC.B    "================================================",$0D,$0A
        DC.B    $00

        ALIGN   2

;;; -----------------------------------------------------------
;;; Variables (in RAM after code)
;;; -----------------------------------------------------------
ZQ:     DS.L    1               ; LFT matrix element q
ZR:     DS.L    1               ; LFT matrix element r
ZS:     DS.L    1               ; LFT matrix element s
ZT:     DS.L    1               ; LFT matrix element t
KK:     DS.L    1               ; continued fraction index k
DCNT:   DS.L    1               ; total digits output
LCNT:   DS.L    1               ; digits on current line

        END     START
