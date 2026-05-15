;;; -*- asm -*-
;;;
;;; Universal Monitor 68000 config file for 68k8 Rev1
;;;
;;; Target:
;;;   CPU     : MC68008 / 8 MHz class, 8-bit external bus
;;;   RAM     : $00000000 - $0007FFFF  512 KiB SRAM
;;;   ROM     : $00080000 - $0008FFFF  64 KiB W27C512
;;;             At reset, ROM is also visible at $00000000 for vector fetch.
;;;   Console : MC68901 MFP at $00090000
;;;             RC clock = 8 MHz / 13 = 615.384 kHz
;;;             USART setting below gives about 38400 bps, 8N1.
;;;

;;;
;;; Memory
;;;

ROM_B:  EQU     $00080000        ; Real ROM base after reset-vector mirror

WORK_B: EQU     $0007F000        ; Monitor work area in high RAM
STACK:  EQU     $0007FFFE        ; Initial SSP, even address near top of RAM
USTACK: EQU     $0007FE00        ; Initial USP for user program

BUFLEN: EQU     24               ; Input buffer size
VECSIZ: EQU     256              ; 68000/68008 vector table entries

;;;
;;; Options
;;;

USE_IDENT = 0                    ; 0 is safer for MC68008 bring-up
MPU_SPEC = 0                     ; 0: MC68000/MC68008, 1: MC68010

USE_REGCMD = 1                   ; R command and register save/restore support
USE_SFDECODE = 1                 ; Decode exception stack frame

;;;
;;; Motorola MC6850
;;;

USE_DEV_6850 = 0
        IF USE_DEV_6850
ACIAC:  EQU     $00380001
ACIAD:  EQU     $00380003
CR_V:   EQU     $15              ; x16, 8bit, N, 1
        ENDIF

;;;
;;; Motorola MC68681
;;;

USE_DEV_68681 = 0
        IF USE_DEV_68681
DUBASE: EQU     $00080100
MR1A_V: EQU     $13              ; 8bit, N
MR2A_V: EQU     $07              ; 1 stop bit
CSRA_V: EQU     $BB              ; 9600 bps with 3.6864 MHz clock
        ENDIF

;;;
;;; Motorola MC68901
;;;

USE_DEV_68901 = 1
        IF USE_DEV_68901
MFBASE: EQU     $00090000        ; MFP base address
UCR_V:  EQU     $88              ; x16, 8bit, no parity, 1 stop
        ENDIF

;;;
;;; EMILY Board / Shared Memory
;;;

USE_DEV_EMILY = 0
        IF USE_DEV_EMILY
SMBASE: EQU     $00000FF0
        ENDIF