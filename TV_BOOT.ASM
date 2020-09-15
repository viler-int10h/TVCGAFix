; FASM TV_BOOT.ASM
;
; Boot sector - copies VPT to top 1K of RAM, reports 1K less available to the
; system, PATCHES copied VPT, and prompts for a new disk (the booter to run).

;-------------------------- EQUATES -------------------------------

VPT_PTR        equ 1Dh*4  ; IVT: pointer to video parameter table
VPT_SIZE_W     equ 2Ch    ; video parameter table size in WORDS (88d bytes)
RAM_SIZE_POS   equ 413h   ; BIOS data area (40:13): memory size in KBytes
HSYNCPOS_40COL equ 2h     ; -,
HSYNCPOS_80COL equ 12h    ;  |_ Offsets inside VPT
HSYNCPOS_GRAPH equ 22h    ;  |
HSYNCWID_80COL equ 13h    ; -'
GOODPOS        equ 2Bh    ; default; good for TV (OVERRIDE IN DISK WRITER?)
GOODWIDTH      equ 0Fh    ; most compatible hsync width for diff CRTC models
BOOTSTRAP_BASE equ 7000h  ; XTIDE hooks int 19h so we have to roll our own

;------------------------ CODE BEGINS -----------------------------

use16
org 7c00h

    jmp   short segfix
segfix:
    jmp   0:start               ; enforce correct CS:IP

start:
    cld
    xor   ax,ax
    mov   ss,ax
    mov   sp,7FFEh              ; set up stack at top of 32K limit
    push  cs
    pop   ds                    ; DS = CS = 0

    ; startup - show message
    xor   bh,bh                 ; active page 0
    mov   cx,(msg_ok - msg_start)
    mov   si,msg_start          ; starting char
  msg_start_loop:
    lodsb                       ; AL = character to write
    mov   ah,0Eh                ; teletype output
    int   10h                   ; write char
    loop  msg_start_loop

    ; did we already install?
    mov   si,VPT_PTR+2          ; check current VPT segment
    lodsw
    cmp   ax,0F000h             ; is it not in BIOS area?
    jb    already_installed     ; no it isn't - already installed!

    ; check and modify reported total RAM size
    mov   si,RAM_SIZE_POS
    mov   di,si                 ; for later
    lodsw                       ; AX <- DS:SI (ram size in KBytes)
    dec   ax                    ; minus one
    push  cs
    pop   es
    stosw                       ; AX -> ES:DI (store it)

    ; copy VPT - set target
    repeat 6
          shl ax,1              ; compute base segment for top of ram minus 1K
    end repeat
    mov   es,ax                 ; set it as target seg
    xor   di,di                 ; ...w/offset 0

    ; copy VPT - set source
    mov   si,VPT_PTR
    lodsw                       ; AX <- DS:SI (OFFSET part of vpt_ptr)
    push  ax
    lodsw                       ; AX <- DS:SI (SEGMENT part of vpt_ptr)
    mov   ds,ax
    pop   si

    mov   cx,VPT_SIZE_W         ; copy VPT - do it!
    rep   movsw

    ; patch our copied VPT
                                PatchOffset = $-$$+1 ;ASSEMBLY-TIME VAR
    mov   al,GOODPOS            ; OVERRIDE THIS IN DISK WRITER?
    mov   di,HSYNCPOS_40COL
    stosb
    mov   di,HSYNCPOS_GRAPH
    stosb
    shl   al,1                  ; *2 for +HRES
    mov   di,HSYNCPOS_80COL
    stosb
    mov   al,GOODWIDTH
    mov   di,HSYNCWID_80COL
    stosb

    ; update pointer to VPT
    push  es                    ; backup SEGMENT part
    push  cs
    pop   es                    ; ES = CS = VPT segment (0)
    mov   ax,es                 ; offset part is also 0
    mov   di,VPT_PTR
    stosw
    pop   ax                    ; SEGMENT part (old ES)
    stosw

    ; installed - show message
    mov   cx,(msg_nope - msg_ok)
    push  cs
    pop   ds                    ; DS = seg 0
    mov   si,msg_ok             ; starting char
  msg_ok_loop:
    lodsb                       ; AL = character to write
    mov   ah,0Eh                ; teletype output (BH ALREADY 0)
    int   10h                   ; write char
    loop  msg_ok_loop

  done:
    ; done - prepare to receive new disk
    mov   si,boot_strap         ; can't int19 with early XTIDE Universal BIOS
    mov   di,BOOTSTRAP_BASE     ; so let's copy our own boostrapper elsewhere
    mov   cx,BStrapSz           ; bytes to copy
    rep   movsb                 ; DS,ES are already 0

    ; prompt to change disk - show message
    mov   cx,(msgs_end - msg_done)
    mov   si,msg_done
  msg_done_loop:
    lodsb
    mov   ah,0Eh                ; teletype output (BH,DS ALREADY 0)
    int   10h
    loop  msg_done_loop
    xor   ax,ax
    int   16h                   ; wait for keypress
    mov   ax,2
    int   10h                   ; set up 80x25 B&W
    jmp   BOOTSTRAP_BASE        ; try to load the new disk

    ; already installed - show message
  already_installed:
    mov   cx,(msg_done - msg_nope)
    mov   si,msg_nope           ; starting char (DS ALREADY 0)
  msg_nope_loop:
    lodsb                       ; AL = character to write
    mov   ah,0Eh                ; teletype output (BH ALREADY 0)
    int   10h                   ; write char
    loop  msg_nope_loop
    jmp   done                  ; prompt for REAL disk

;-------------------- SOME NICE STRINGS ---------------------------

    msg_start: db 0Dh,0Ah
               db '    Boot-time TV CGA fix '
    msg_ok:    db 'v1.0 (VileR 2018-08) installed at top of RAM.',0Dh,0Ah
    msg_nope:  db 'ALREADY INSTALLED!',07h,0Dh,0Ah
    msg_done:  db '    Insert your CGA booter in drive A: and hit a key...'
    msgs_end:
                                BSectorSz = $-$$ ;ASSEMBLY-TIME VAR
boot_strap:
org BOOTSTRAP_BASE

;------------------------ BOOT_STRAP ------------------------------

    ; load system from diskette; CX has retry count
    mov   cx,4                  ; set retry count
  h1:                           ; ipl_system
    push  cx                    ; save retry count
    mov   ah,0                  ; reset the diskette system
    xor   dx,dx                 ; DL = drive 0
    int   13h                   ; diskette_io
    jc    h2                    ; if error, try again
    mov   ax,201h               ; AH = read; AL = single sector
    push  cs
    pop   es                    ; target segment = 0
    mov   bx,7c00h              ; target offset  = boot sector location
                                ; DL = drive 0, DH = head 0
    mov   cx,1                  ; sector 1, track 0
    int   13h                   ; diskette_io
  h2:
    pop   cx                    ; recover retry count
    jnc   h4                    ; cf set by unsuccessful read
    loop  h1                    ; do it for retry times
  h3:
    int   18h                   ; can't IPL from diskette, go to ROM BASIC
  h4:
    jmp   7c00h                 ; IPL was successful

                                BStrapSz = $-$$ ;ASSEMBLY-TIME VAR
                                ProgSz = BSectorSz+BStrapSz ;ASSEMBLY-TIME VAR

;-------------------------- PADDING -------------------------------

    times 508-ProgSz-SigSz db 1
                                Sig = $ ;ASSEMBLY-TIME VAR
    db    'ÄÄÄú ïîW úÄÄÄÄ'
    db    'Äú ä³›çâ¡€ úÄ'
    db    'Äú WÚÚ‹0â úÄ'
    times 12 db 1
                                SigSz = $ - Sig ;ASSEMBLY-TIME VAR
    dw    PatchOffset           ; Tell boot-disk maker where to patch.
    dw    0AA55h                ; magic marker
