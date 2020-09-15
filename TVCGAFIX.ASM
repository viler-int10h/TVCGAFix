; FASM.EXE TVCGAFIX.ASM

; TSR traps int 10, and checks if text mode 3 is set.  If so, it sets the
; MC6845 hsync width to F to get color 80-column text mode on TV w/CGA.
; Also, for ANY CGA mode, sets custom values for the hsync position register
; to get better horizontal centering.

; ||||||||||||||||||||||||||||   FASM MACROS   |||||||||||||||||||||||||||||||

macro WRITEHEX wordvalue
{
  bits = 16
  repeat bits/4
      d = '0' + (wordvalue) shr (bits-%*4) and 0Fh
      if d > '9'
          d = d + 'A'-'9'-1
      end if
      display d
  end repeat
}

; |||||||||||||||||||||||||   RESIDENT PORTION   |||||||||||||||||||||||||||||

use16
org 100h

oldint:
    jmp    near init    ; jump to install routine- or to old INT 10h handler
    dw     0            ;     if already installed (we'll change the ptr!)

new10:                  ; NEW INT 10H HANDLER
    cmp    ax, 6        ; Are we setting (AH=0) a CGA mode (AL<6)?
    jbe    cgamode      ; ...Yes
    cmp    ax, 1200h    ; ...No; alternate function select?
    jne    oldint
    cmp    bl, 12h      ;        unused subfunction?
    jne    oldint
    mov    al, ah       ;        indicate program is resident
    push   cs
    pop    es           ; return segment too (for modding value if installed)
                        ;     we could ALSO return the value itself (for TV80
                        ;     and TVCGACAL) but that increases resident size
    iret                ; return from handler
    
  cgamode:
    push   ax           ; old int10h handler destroys AX, but we need it
    pushf               ; call old int 10h handler to set the mode
    push   cs
    call   oldint       ; NOTE: may be buggy with software that expects 
    pop    ax           ;     the real AX value returned by old int10h

    push   bx           ; Save any registers we destroy
    push   dx
    push   ax
    call   fixit
    pop    ax           ; Done; restore registers
    pop    dx
    pop    bx
    iret                ; return from handler

fixit:
  ; If we're here, we know that AL (=mode) is between 0 and 6
    VALPOS = $+1        ; FOR PATCHING VALUE IN BELOW INSTRUCTION

    mov    bl, 2Bh   ;2 ; DEFAULT hsync pos value
    mov    dx, 03d4h ;3 ; port 3D4h - MC6845 registers
    cmp    al, 3     ;2 ; Are we in COLOR mode 3?
    jne    not3      ;2 ;  * NO
    mov    ah, 0Fh   ;2 ;  * 0F03 = sync width + optimal value for color
    out    dx, ax    ;1
  not3:
    and    al, 6     ;2 ; Check if we're in 80-column modes, 2 or 3
    cmp    al, 2     ;2 ;     (true if (MODE AND 6) = 2)
    jne    set_hpos  ;2 ;  * NO? - just set h-pos as-is
    shl    bl, 1     ;2 ;  * YES? - double h-pos for +HRES
  set_hpos:
    mov    ah, bl    ;2 ; Get value for our mode
    mov    al, 2     ;2 ; 02:     Horizontal Sync Position
    out    dx, ax    ;1
    ret              ;1 fixit total size=26b
    
; |||||||||||||||||||||||||   TRANSIENT PORTION   ||||||||||||||||||||||||||||

    display '; THIS FILE IS AUTO-GENERATED AT ASSEMBLY TIME - do not modify manually!',0Dh,0Ah,0Dh,0Ah, 'TSR_VAL_POS equ '
    WRITEHEX VALPOS
    display 'h ; for inclusion in TV80 program', 0Dh,0Ah, '; SIZE OF RESIDENT CODE: '
    WRITEHEX init-$$
    display 0Dh,0Ah

init:
  ; PARAMETER CHECK
    cmp    byte[80h], 2                  ; correct length of command tail?
    jne    usage                         ; negative - not cool!
    mov    al, byte[82h]                 ; get the first command line char
    cmp    al, '0'
    jb     usage
    cmp    al, '9'
    ja     usage
    jmp    short param_ok

usage:
    mov    dx, msgUsage                  ; Show help text
    call   showMsg
    ret                                  ; TERMINATE

param_ok:
  ; PARAMETER OK - USE IT!
    mov    ah, 5Eh
    neg    al
    add    al, ah                        ; AL = raw reg value (5Eh-asciiCode)
    mov    byte[VALPOS], al              ; patch it into the code

    mov    dx, msgProgname               ; Show 'TVCGAFIX '
    call   showMsg

  ; INSTALLATION CHECK
    mov    ax, 1200h                     ; if AL returns 12h program is already
    mov    bl, 12h                       ;    resident (see above). If so, TSR
    int    10h                           ;    code seg is returned in ES so we
    cmp    al, 12h                       ;    know where to patch new value
    jne    install

  ; ALREADY INSTALLED
    mov    di, VALPOS                    ; ES:DI -> offset in HANDLER seg
    mov    al, byte[VALPOS]              ; new value in our current CS
    stosb
    mov    dx, msgAlready
    call   showMsg

; -------------
gotest:                                  ; done on first run
    mov    ah, 0Fh                       ; get current video mode
    int    10h
    cmp    al, 6                         ; is it a CGA mode (0-6)?
    ja     notcga                        ; no
    call   fixit
  notcga:
    ret
; -------------

install:
    mov    ax, 3510h                     ; create jump to old handler
    int    21h
    inc    byte [oldint]                 ; change opcode to far jump?
    mov    word [oldint+1], bx           ; offset of old handler
    mov    word [oldint+3], es           ; segment of old handler

    mov    dx, new10                     ; hook into chain: set int vector
    mov    ah, 25h                       ; AL = int# (already 10)
    int    21h                           ; DS:DX = new handler

    mov    es, word [2Ch]                ; free environment segment
    mov    ah, 49h
    int    21h

    call   gotest                        ; do on initial activation

    mov    dx, msgInst
    call   showMsg

    PARAGRAPHS = (init shr 4)            ; Let FASM find how many paragraphs
    if (init mod 16 <> 0)                ;    to leave resident: offset of
      PARAGRAPHS=PARAGRAPHS+1            ;    transient portion/16; +1 rounds
    end if                               ;    up to next paragraph if needed

    mov    dx, PARAGRAPHS
    mov    ax, 3100h                     ; terminate leaving DX paragraphs
    int    21h                           ; resident


display '; NUMBER OF RESIDENT PARAGRAPHS (incl. PSP): '
WRITEHEX PARAGRAPHS
;display 0Dh,0Ah

; ||||||||||||||||||||||||||||   SUBROUTINES   |||||||||||||||||||||||||||||||

showMsg:
    mov    ah, 9
    int    21h                           ; DS:DX -> '$'-terminated sctring
    ret


; ||||||||||||||||||||||||||   DATA / MESSAGES   |||||||||||||||||||||||||||||

msgUsage:    db 'TV CGA fix v1.0 / VileR 2018-08',0Dh,0Ah
             db "Optimizes CGA output for TV by adjusting the screen's "
             db 'horizontal position, and',0Dh,0Ah
             db 'fixing color output in 80-column text mode',0Dh,0Ah,0Dh,0Ah
             db 'Usage: TVCGAFIX #',0Dh,0Ah,0Dh,0Ah
             db '  # {0..9}: specifies the desired horizontal screen position'
             db 0Dh,0Ah
             db '    0=leftmost, 9=rightmost (1=CGA default; see README.TXT '
             db 'for details)',0Dh,0Ah,'$'
msgProgname: db 'TVCGAFIX $'
msgInst:     db 'loaded.',0Dh,0Ah,'$'
msgAlready:  db 'value changed.',0Dh,0Ah,'$'