; FASM TV80.ASM
;
; Changes the so-called CGA 'phase' by setting the CRTC hsync position value.
; Only affects 80-color text mode, on a composite monitor.
;
; ASSUMPTION: hsync *width* has already been set to 0Fh (e.g. with TVCGAFIX).
;
; A smaller value will cause the hsync pulse to be shifted further to the
; right, so a longer slice of the missing +HRES color-burst signal will be
; generated, and the TV won't over-compensate as much, resulting in colors
; closer to a normal saturation.
;
; Without the CPU+CGA being in 'lockstep', the same values will not always
; produce the same results.  Therefore 3 values are possible, determined by
; the command-line argument: -, =, +.


;------------------------------  FASM MACROS  --------------------------------

macro waitForDisplayEnable {
    local x1
  x1:
    in    al,dx
    test  al,1
    jnz   x1
}

macro waitForDisplayDisable {
    local x1
  x1:
    in    al,dx
    test  al,1
    jz    x1
}


;--------------------------------- EQUATES -----------------------------------

include 'tsr_pos.inc'   ; offset of same in TVCGAFIX segment (if resident).
                        ; the include file is now created when assembling
                        ; TVCGAFIX, instead of the previous manual statement:
                        ;        TSR_VAL_POS    equ 12Bh   


;------------------------------- CODE BEGINS ---------------------------------

use16
org 100h

  ; VIDEO MODE CHECK
    mov    ah, 0Fh                       ; get current video mode
    int    10h
    cmp    ah, 80                        ; number of character columns
    je     mode_ok
    mov    dx, msgNot80
    call   showMsg
    ret                                  ; terminate

  ; PARAMETER CHECK
  mode_ok:
    mov    al, byte[82h]                 ; get the first command line char
    or     al, 20h                       ; convert to lowercase ('+/-/=' OK)
		cmp    byte[80h], 2                  ; correct length of command tail?
    je     check_char                    ;    ... yes, proceed
    mov    dx, msgUsage                  ;    ... negative - not cool!
    call   showMsg
    ret                                  ; terminate
  check_char:
    cmp    al, '-'                       ; ACTUALLY MEANS +1
    jne    c0
    inc    cx                            ; use CX for pos.modifier, not memory
    inc    cx                            ; init CX for COM=FF, so inc*2 for +1
    jmp    short modify_pos
  c0:
    cmp    al, '+'                       ; ACTUALLY MEANS -1
    jne    c1                            ; init CX for COM=FF = -1; do nothing
    jmp    short modify_pos
  c1:
    cmp    al, '='                       ; RESET TO '0'
    jne    c2
    inc    cx                            ; init CX for COM = FF, so inc for 0
    jmp    short modify_pos
  c2:
    cmp    al, 'p'
    jne    c3
    jmp    short switch_phase
  c3:
    xor    bx, bx                        ; PREPARE FOR BIOS DATA AREA 
    mov    ds, bx                  ; !!! ; careful - we've just destroyed DS
    mov    bl, byte[465h]                ; get mode select byte from data area
    cmp    al, 'c'
    jne    c4
    and    bl, 111011b                   ; 80-column, burst ON
    mov    cl, 0Fh                       ; optimal sync width for color
    jmp    short set_burst
  c4:
    cmp    al, 'b'
    jne    c5
    or     bl, 4                         ; 80-column, burst OFF
    mov    cl, 09h                       ; optimal sync width for color-KILLER
    jmp    short set_burst
  c5:
    push   cs
    pop    ds                      ; !!! ; see C3:
    mov    dx, msgUsage                  ; NO MATCHING PARAMETERS
    call   showMsg
    ret                                  ; terminate

  ; >>>>>>>>>>>>> SET BURST - COLOR OR MONO <<<<<<<<<<<<<

  set_burst:
    mov    dx, 03d4h                     ; CRTC registers
    mov    ah, cl                        ; sync width
    mov    al, 3
    out    dx, ax
    mov    al, bl
    mov    byte[465h], al                ; set mode select byte in data area
    mov    dl, 8                         ; mode select
    out    dx, al
    
    ret                                  ; terminate

  ; >>>>>>>>>>>>>>> FINE-TUNE POSITION <<<<<<<<<<<<<<<<<<

  modify_pos:
    ;push   ds                           ; destroyed, but no matter
  
    ; TVCGAFIX INSTALLATION CHECK
    mov    ax, 1200h                     ; if AL returns 12h then TVCGAFIX is
    mov    bl, 12h                       ;    resident. If so, its code segment
    int    10h                           ;    is returned in ES so we can use
    cmp    al, 12h                       ;    that to get current position val
    jne    use_vpt                       ; not installed? Get value from VPT

    ; TVCGAFIX INSTALLED - SET OFFSET
   ;mov    si, TSR_VAL_POS               ; SI has offset of binary value
    mov    si, TSR_VAL_POS-1             ; changed so we can load directly to
    jmp    short got_value               ;    AH with lodsw from prev. byte!
    
    ; TVCGAFIX NOT INSTALLED - USE VPT
    use_vpt:
    mov    ax, 351Dh                     ; Get interrupt vector
    int    21h                           ;    (in this case just a pointer!)
    inc    bx                            ; ES:BX -> current location of VPT
   ;inc    bx ;;; we need off. 2 in VPT; instead lets load in AH from off. 1!
    xchg   bx, si                        ; SI has offset of binary value
    
    ; GET THE VALUE FROM EITHER TSR OR VPT
    got_value:
    push   es                            ; both TSR + VPT methods return needed
    pop    ds                            ;    segment in ES.  Let's copy to DS
   ;lodsb                                ;    so we can get AL <- [DS:SI]!
    lodsw                                ;    ...whoops - use AH instead
    ;pop    ds
    
    ; APPLY MODIFIER AND USE IT
    shl    ah, 1                         ; Now AH has our value; *2 for 80-col!
    add    ah, cl                        ; our modifier offset
    mov    al, 2                         ; 02:     Horizontal Sync Position
    mov    dx, 3d4h                      ;         MC6845 registers
    out    dx, ax
    ret    

  ; >>>>>>>>>>>>>>>>>> SWITCH PHASE <<<<<<<<<<<<<<<<<<<<<
  
  switch_phase:
    mov    dx, 3DAh                      ; status register
    cli
    waitForDisplayEnable                 ; Do our tricks during active raster
    mov    dl, 0D4h                      ; CRTC registers
    mov    ax, 7200h                     ; 00:    Horizontal Total
    out    dx, ax                        ;        Odd # of chars to flip phase
    mov    dl, 0DAh                      ; status register
    waitForDisplayDisable
    waitForDisplayEnable
    mov    dl, 0D4h                      ; CRTC registers
    mov    ax, 0x7100                    ; 00:    Horizontal Total
    out    dx, ax                        ;        Back to normal 80-col value
    sti
    ret                                  ; terminate


;------------------------------- SUBROUTINES ---------------------------------

  showMsg:
    mov    ah, 9
    int    21h                           ; DS:DX -> '$'-terminated sctring
    ret


;------------------------------ DATA/MESSAGES --------------------------------


msgNot80:    db 'Please run in 80-column text mode.',13,10,'$'
msgUsage:
    db 'TV80 v1.0 (VileR 2018-08): finetune 80-column CGA output for TV',13,10
    db 13,10
    db 'Usage: TV80 command',13,10
    db 13,10
    db '  Position/phase finetuning commands:',13,10
    db '    +/-  offset hsyc position by 1 CRTC cycle either way (non-'
    db 'cumulative)',13,10
    db '    =    restore hsync position (remove offset applied with "+"'
    db ' or "-")',13,10
    db '    p    flip CGA/CRTC relative phase',13,10,13,10
    db '  Color burst commands:',13,10
    db '    c    color picture (burst enabled)',13,10
    db '    b    b&w picture (burst disabled)',13,10
    db 13,10
    db 'Loading TVCGAFIX first is recommended; see README.TXT for details'
    db 13,10,'$'
