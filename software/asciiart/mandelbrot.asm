;;; ============================================================
;;;   mandelbrot.asm  -  Mandelbrot Set ASCII Art
;;;   MC68008/68000  Fixed-Point 4.12  (1.0 = 4096 = $1000)
;;;
;;;   Size   : 72 cols x 44 rows
;;;   Real   : -2.3 .. +0.9
;;;   Imag   : -1.15 .. +1.15
;;;   MaxIter: 64
;;;   Palette: 48-char gradient  ' ' -> dense -> '@' (inside)
;;;
;;;   Monitor I/O  (from Monitor/unimon_68000.lst):
;;;     CONOUT = $0008141A
;;;     CONIN  = $000813FA
;;;     CONST  = $0008140E
;;; ============================================================

        CPU     68000
        SUPMODE ON

;;; ---- Monitor entry points --------------------------------
CONOUT  EQU     $8141A
CONIN   EQU     $813FA
CONST   EQU     $8140E

;;; ---- Fixed-point constants  (4.12, 1.0 = 4096) ----------
;;;  X: -2.3*4096 = -9421  .. +0.9*4096 = 3686
;;;     DX = (3686+9421)/72 = 182 per column
;;;  Y: -1.15*4096 = -4710 .. +1.15*4096 = 4710
;;;     DY = 9420/44 = 214 per row
;;;  Escape: |Z|^2 > 4  =>  4*4096 = 16384 in 4.12
FP_XMN  EQU     -9421
FP_DX   EQU     182
FP_YMN  EQU     -4710
FP_DY   EQU     214
FP_ESC  EQU     16384

;;; ---- Image / iteration parameters -----------------------
WIDTH   EQU     72
HEIGHT  EQU     44
MAXITER EQU     64

;;; ---- Character palette length ---------------------------
CLEN    EQU     48              ; number of chars in PALETTE

;;; ===========================================================
        ORG     $00000400

;;; -----------------------------------------------------------
;;; START
;;; Register map (outer loops):
;;;   D7.W  = row counter   (HEIGHT..1)
;;;   D6.W  = CI            (imaginary coord, 4.12)
;;;   D5.W  = col counter   (WIDTH..1)
;;;   D4.W  = CR            (real coord, 4.12)
;;;   A5    = base of PALETTE string
;;; -----------------------------------------------------------
START:
        LEA     MSG_HDR,A0
        BSR     STROUT

        LEA     PALETTE,A5      ; A5 = palette base (constant)

        MOVE.W  #HEIGHT,D7
        MOVE.W  #FP_YMN,D6     ; CI starts at top (most negative)

ROW_LOOP:
        MOVE.W  #WIDTH,D5
        MOVE.W  #FP_XMN,D4     ; CR starts at left

COL_LOOP:
        ;;; ------------------------------------------------
        ;;; Mandelbrot inner loop
        ;;; Calling convention: D4=CR D6=CI (untouched)
        ;;; Work regs: D0 D1 D2 D3  (caller saves D4-D7 via stack)
        ;;; Result: D0.W = escape iteration (0 = inside set)
        ;;; ------------------------------------------------
        MOVEM.L D4-D7,-(A7)    ; save outer-loop state

        MOVEQ   #0,D0           ; ZR = 0 (4.12)
        MOVEQ   #0,D1           ; ZI = 0 (4.12)
        MOVE.W  D4,D2           ; D2 = CR  (will not change)
        MOVE.W  D6,D3           ; D3 = CI  (will not change)
        ;;; D4 = iteration counter  (we just saved D4 on stack)
        MOVE.W  #MAXITER,D4

        ;;; We need D5 as temp during iteration (saved on stack)
        ;;; Register use inside ITER:
        ;;;   D0 = ZR, D1 = ZI, D2 = CR, D3 = CI
        ;;;   D4 = iterations remaining
        ;;;   D5, D6, D7 = temporaries

ITER:
        ;;; ---- ZI_new = 2*ZR*ZI + CI -------------------------
        ;;;  D5.L = ZR * ZI  (intermediate, scale^2 = 2^24)
        ;;;  After ASR.L #11 => 2*ZR*ZI in 4.12 (shift 12-1)
        MOVE.W  D0,D5
        MULS.W  D1,D5           ; D5.L = ZR*ZI (4.12 * 4.12 = 8.24)
        ASR.L   #8,D5           ; shift 11 = 8+3
        ASR.L   #3,D5           ; D5.L = 2*ZR*ZI in 4.12
        ADD.W   D3,D5           ; D5.W = 2*ZR*ZI + CI  => ZI_new

        ;;; ---- ZR_new = ZR^2 - ZI^2 + CR --------------------
        ;;;  D6.L = ZR^2,  D7.L = ZI^2
        MOVE.W  D0,D6
        MULS.W  D0,D6           ; D6.L = ZR^2 (8.24)
        ASR.L   #8,D6           ; shift 12 = 8+4
        ASR.L   #4,D6           ; D6.L = ZR^2 in 4.12

        MOVE.W  D1,D7
        MULS.W  D1,D7           ; D7.L = ZI^2 (8.24)
        ASR.L   #8,D7           ; shift 12 = 8+4
        ASR.L   #4,D7           ; D7.L = ZI^2 in 4.12

        SUB.W   D7,D6           ; D6.W = ZR^2 - ZI^2
        ADD.W   D2,D6           ; D6.W = ZR^2 - ZI^2 + CR  => ZR_new

        ;;; ---- Escape check: |Z_new|^2 > 4 ------------------
        ;;;  Reuse D7: ZR_new^2 + ZI_new^2  (both in 4.12)
        MOVE.W  D6,D7
        MULS.W  D6,D7           ; D7.L = ZR_new^2 (8.24)
        ASR.L   #8,D7
        ASR.L   #4,D7           ; D7 = ZR_new^2 in 4.12

        MOVE.W  D5,D0           ; D0 = ZI_new (temp)
        MULS.W  D5,D0           ; D0.L = ZI_new^2 (8.24)
        ASR.L   #8,D0
        ASR.L   #4,D0           ; D0 = ZI_new^2 in 4.12

        ADD.W   D0,D7           ; D7.W = |Z_new|^2 in 4.12

        ;;; ---- Update ZR, ZI for next iteration -------------
        MOVE.W  D6,D0           ; D0 = ZR_new
        MOVE.W  D5,D1           ; D1 = ZI_new

        ;;; ---- Check escape or exhaustion -------------------
        CMP.W   #FP_ESC,D7     ; |Z|^2 >= 4.0?
        BGE.S   ESCAPED

        SUBQ.W  #1,D4
        BNE.S   ITER

        ;;; Inside set: D4=0
        MOVEQ   #0,D0           ; return 0 = inside
        BRA.S   ITER_DONE

ESCAPED:
        ;;; D4 = remaining iters.  Escaped at MAXITER - D4 + 1
        ;;; We want "how many iters ran" = MAXITER - D4 + 1
        MOVE.W  #MAXITER+1,D0
        SUB.W   D4,D0           ; D0 = iters taken (1..MAXITER)

ITER_DONE:
        MOVEM.L (A7)+,D4-D7    ; restore outer-loop state

        ;;; ------------------------------------------------
        ;;; Map D0 -> character and output
        ;;; D0 = 0  => inside set => '@'
        ;;; D0 = 1..MAXITER => palette[(D0-1)*(CLEN-1)/MAXITER]
        ;;; ------------------------------------------------
        TST.W   D0
        BNE.S   ESCAPED_PIXEL

        MOVE.B  #'@',D0
        JSR     CONOUT
        BRA.S   NEXT_COL

ESCAPED_PIXEL:
        ;;; index = (N-1) * (CLEN-1) / MAXITER
        ;;; N in D0 (1..64), result 0..47
        SUBQ.W  #1,D0           ; N-1 (0..63)
        MULS.W  #CLEN-1,D0     ; D0.L = (N-1)*(CLEN-1)
        DIVU.W  #MAXITER,D0    ; D0.W = quotient
        AND.L   #$0000FFFF,D0  ; keep quotient word
        MOVE.B  (A5,D0.W),D0   ; lookup character
        JSR     CONOUT

NEXT_COL:
        ADD.W   #FP_DX,D4      ; CR += step
        SUBQ.W  #1,D5
        BNE     COL_LOOP

        ;;; CR/LF at end of row
        MOVE.B  #$0D,D0
        JSR     CONOUT
        MOVE.B  #$0A,D0
        JSR     CONOUT

        ADD.W   #FP_DY,D6      ; CI += step
        SUBQ.W  #1,D7
        BNE     ROW_LOOP

        ;;; Done
        LEA     MSG_DONE,A0
        BSR     STROUT
        RTS

;;; -----------------------------------------------------------
;;; STROUT: print null-terminated string pointed by A0
;;;         clobbers D0
;;; -----------------------------------------------------------
STROUT:
        MOVE.B  (A0)+,D0
        BEQ.S   STROUT_END
        JSR     CONOUT
        BRA.S   STROUT
STROUT_END:
        RTS

;;; -----------------------------------------------------------
;;; Data
;;; -----------------------------------------------------------

MSG_HDR:
        DC.B    $0D,$0A
        DC.B    "================================================",$0D,$0A
        DC.B    " MANDELBROT SET  -  ASCII ART  (68000 asm)",$0D,$0A
        DC.B    " Real: -2.30 .. +0.90  Imag: -1.15 .. +1.15",$0D,$0A
        DC.B    " Size: 72x44  MaxIter: 64  Fixed-Point 4.12",$0D,$0A
        DC.B    "================================================",$0D,$0A
        DC.B    $00

MSG_DONE:
        DC.B    $0D,$0A
        DC.B    "================================================",$0D,$0A
        DC.B    " Done.",$0D,$0A
        DC.B    "================================================",$0D,$0A
        DC.B    $00

;;; 48-char gradient palette: index 0 = fast escape (sparse)
;;;                           index 47 = slow escape (dense border)
PALETTE:
        DC.B    " .`',-_:;+|i!rnczuvxXYUJCLQ0OZmwqpdbkhao*#%MW&8B"
        ;       0         1         2         3         4
        ;       0123456789012345678901234567890123456789012345678

        ALIGN   2

        END     START
