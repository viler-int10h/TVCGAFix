; FASM TVCGACAL.ASM
;
; Lets you find the right horizontal position for CGA output on your TV

; Assemble TV_BOOT.ASM first (this includes the resulting .BIN)

;--------------------------------- EQUATES -----------------------------------

include 'tsr_pos.inc'   ; offset of same in TVCGAFIX segment (if resident).
                        ; the include file is now created when assembling
                        ; TVCGAFIX, instead of the previous manual statement:
                        ;        TSR_VAL_POS    equ 12Bh   

VRAM_DIGIT_P   equ 71Eh   ; offset of screen buffer to show digit
VRAM_METER_P   equ 706h   ; offset of screen buffer to show meter


;------------------------------- CODE BEGINS ---------------------------------

use16
org 100h

    mov    ah, 0Fh                       ; get current video mode
    int    10h
    push   ax ;s:0                       ; save for program end
    push   ds ;s:1                       ; gonna destroy DS so save it too

  ; TVCGAFIX INSTALLATION CHECK
    mov    ax, 1200h                     ; if AL returns 12h then TVCGAFIX is
    mov    bl, 12h                       ;    resident. If so, its code segment
    int    10h                           ;    is returned in ES so we can use
    cmp    al, 12h                       ;    that to get current position val
    jne    use_vpt                       ; not installed? Get value from VPT

  ; TVCGAFIX INSTALLED - SET OFFSET
    mov    si, TSR_VAL_POS               ; SI has offset of binary value
    jmp    short got_value

  ; TVCGAFIX NOT INSTALLED - USE VPT
  use_vpt:
    mov    ax, 351Dh                     ; Get interrupt vector
    int    21h                           ;    (in this case just a pointer!)
    inc    bx                            ; ES:BX -> current location of VPT
    inc    bx                            ; Val is at offset 2 in VPT: inc *2
    xchg   bx, si                        ; SI has offset of binary value

  ; GET THE VALUE FROM EITHER TSR OR VPT
  got_value:
    push   es ;s:3                       ; both TSR + VPT methods return needed
    pop    ds ;s:2                       ;    segment in ES.  Let's copy to DS
    lodsb                                ;    so we can get AL <- [DS:SI]!
    pop    ds ;s:1         
    xchg   ax, bx                        ; Now AL has our value - move to BL
    call   getAsciiDigitInBH             ;    and get its ascii digit in BH

  ; SET MODE 1
    mov    ax, 1                         ; 40-column text, color
    int    10h
    push   bx
    mov    ah, 0Fh                       ; get video mode, did we succeed?
    int    10h                           ; TOO BAD THIS DESTROYS BX
    pop    bx
    cmp    al, 1
    je     cga_ok
    mov    dx, msg_no_cga                ; no, complain and terminate
    call   showMsg
    int    20h                           ;    (stack soiled)

  ; SHOW SCREEN
  cga_ok:
    mov    dx, 03d8h                     ; mode control
    mov    al, 8                         ; -BLINK -640 +VIDEO -BW -GFX -HRES
    out    dx, al
    inc    dx                            ; color control
    mov    al, 4                         ; red border
    out    dx, al
    mov    ax, 0B800h                    ; copy data
    mov    es, ax
    xor    di, di
    mov    si, screenData
    mov    cx, 960
    rep    movsw
    call   updateScreen

  ; LOOP FOR USER INPUT HERE
  check_input:
    mov    ah, 0                         ; get keystroke
    int    16h
    cmp    ah, 4Bh                       ; cursor left
    je     move_left
    cmp    ah, 4Dh                       ; cursor right
    je     move_right
    cmp    ah, 1                         ; ESC
    jne    check_input

  ; GOODBYE
    pop    ax ;s:0                       ; restore video mode
    xor    ah, ah
    int    10h
    mov    dx, msg_how_to
    call   showMsg
    ret                                  ; terminate

  move_left:
    cmp    bh, '0'                       ; at leftmost already?
    je     check_input
    inc    bx
    jmp    short apply_move
  move_right:
    cmp    bh, '9'                       ; at rightmost already?
    je     check_input
    dec    bx
  apply_move:
    call   getAsciiDigitInBH
    call   updateScreen
    jmp    check_input


;------------------------------- SUBROUTINES ---------------------------------

  showMsg:
    mov    ah, 9
    int    21h                           ; DS:DX -> '$'-terminated sctring
    ret

  getAsciiDigitInBH:
  ;Input: BL = binary H_Position / Return: BH -> ASCII digit
    mov    bh, bl
    neg    bh
    add    bh, 5Eh                       ; ascii code = 5Eh-(raw reg value)
    mov    byte[valueDigit], bh          ; patch into msg while we're at it
    ret

  updateScreen:
    ; SHIFT ACCORDING TO VALUE IN BL
    mov    dx, 03d4h                     ; port 3D4h - MC6845 registers
    mov    al, 2                         ; 02:     Horizontal Sync Position
    mov    ah, bl
    out    dx, ax
    ; HIDE THE CURSOR
    mov    ax, 110Eh                     ; 0E:     Cursor Address (H)
    out    dx, ax
    inc    ax                            ; 0F:     Cursor Address (L)
    out    dx, ax
    ; DRAW METER
    mov    al, bh                        ; ascii digit first
    mov    di, VRAM_DIGIT_P
    stosb
    mov    ax, 084f9h                    ; meter dots
    mov    di, VRAM_METER_P
    mov    cx, 10
    rep    stosw
    mov    ax, 0b9feh                    ; indicator
    push   bx
    xchg   bh, bl                        ; calculate offset by ascii digit
    and    bx, 0Fh                       ; keep only last nybble
    shl    bx, 1                         ; double it
    mov    di, VRAM_METER_P
    add    di, bx
    stosw
    pop    bx
    ret


;------------------------------- SCREEN DATA ---------------------------------

screenData:  file 'TVCGACAL.BIN'


;--------------------------------- MESSAGES ----------------------------------

msg_how_to:  db 'To install with the last value displayed, run: TVCGAFIX '
valueDigit:  db 1,13,10,'$'
msg_no_cga:  db "Couldn't initialize CGA!",13,10,'$'
