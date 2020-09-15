; FASM MAKEBOOT.ASM
;
; Writes the boot-time version of the TV CGA fix to the boot sector of a
; floppy in A:.  Patches it according to the value specified in the command-
; line argument.
; 
; Assemble TV_BOOT.ASM first (this includes the resulting .BIN)

; B E G I N ==================================================================

use16
org 100h

    mov    dx,msgProgName
    call   showMsg
    
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
    mov    dx,msgUsage
    call   showMsg
    ret                                  ; TERMINATE

  ; PARAMETER OK, USE IT
  param_ok:
    mov    di, patchDigit                ; patch digit into "writing..." msg
    stosb                                ; ES:DI <- AL (our digit)
    mov    ah, 5Eh
    neg    al  
    add    al, ah                        ; AL = raw reg value (5Eh-asciiCode)
    mov    di, word[patchOffset]         ; now patch boot sector itself
    add    di, bootSector                ; DI <- offset in DS to patch
    stosb                                ; ES:DI <- AL (our raw reg value)
    
  ; PROMPT FOR DISK
    mov    dx, msgInsert
    call   showMsg
    xor    ax, ax
    int    16h                           ; wait for keystroke

  ; ARE YOU SURE?
    call   resetDiskSys                  ; make some noise (...)
    mov    dx, msgWarning
    call   showMsg
    xor    ax, ax
    int    16h                           ; wait for keystroke
    or     al, 20h                       ; convert to lowercase
    cmp    al, 'y'
    jne    bye
    
  ; DO IT!
    mov    dx, msgWriting
    call   showMsg
  
  ; WRITE SECTOR
    mov    cx, 4                         ; set retry count
  try1:
    push   cx                            ; save retry count
    call   resetDiskSys
    jc     error1                        ; if error, try again
    mov    ax, 301h                      ; AH = write; AL = single sector
    mov    bx, bootSector                ; ES:BX = our buffer (ES=0)
    xor    dx, dx                        ; DL = drive 0, DH = head 0
    mov    cx, 1                         ; sector 1, track 0
    int    13h                           ; write it
  error1:                         
    pop    cx                            ; recover retry count
    jnc    success1                      ; no CF = no error :)
    loop   try1                          ; do it for retry times
    mov    dx, statusFail                ; write failed - show status
    call   showMsg
    jmp    failed
  success1:
    mov    dx, statusOK
    call   showMsg
    mov    dx, msgVerify
    call   showMsg

  ; VERIFY SECTOR
    mov    cx, 4                         ; set retry count
  try2:
    push   cx                            ; save retry count
    call   resetDiskSys
    jc     error2                        ; if error, try again
    mov    ax, 401h                      ; AH = VERIFY; AL = single sector
    mov    bx, spareBuffer               ; ES:BX = our buffer (ES=0)
    xor    dx, dx                        ; DL = drive 0, DH = head 0
    mov    cx, 1                         ; sector 1, track 0
    int    13h                           ; write it
  error2:                         
    pop    cx                            ; recover retry count
    jnc    success2                      ; no CF = success
    loop   try2                          ; try again
    mov    dx, statusFail                ; write failed - show status
    call   showMsg
    jmp    failed
  success2:
    mov    dx, statusOK
    call   showMsg      
    mov    dx, msgDone
    call   showMsg
  bye:
    ret                                  ; SUCCESS

  failed:
    mov    dx,msgFail
    call   showMsg
    ret                                  ; TERMINATE

; S U B R O U T I N E S ======================================================
  
  showMsg:
    mov    ah, 9
    int    21h                           ; DS:DX -> '$'-terminated sctring
    ret

  resetDiskSys:    
    mov    ah, 0                         ; reset the diskette system
    xor    dx, dx                        ; DL = drive 0
    int    13h                           ; recalibrate to track 0
    ret

; B O O T   S E C T O R ======================================================

             times 7 db 2                ; just some padding
bootSector:  file 'TV_BOOT.BIN'
             patchOffset = $-4           ; WORD: offset in sector to patch

; D A T A / M E S S A G E S ==================================================

msgProgName: db 'TV CGA fix v1.0 Boot disk maker / VileR 2018-08',0Dh,0Ah,'$'
msgUsage:    db 'Creates a bootable diskette to optimize CGA output for TV '
             db 'at machine startup',0Dh,0Ah,0Dh,0Ah
             db 'Usage: MAKEBOOT #',0Dh,0Ah,0Dh,0Ah
             db '  # {0..9}: specifies the horizontal screen position to be '
             db 'set at boot -',0Dh,0Ah
             db '    0=leftmost, 9=rightmost (1=CGA default; see README.TXT '
             db 'for details)',0Dh,0Ah,'$'

msgInsert:   db 0Dh,0Ah
             db 'Insert a known good, UNUSED diskette in drive A: and hit a '
             db 'key when ready...$'
msgWarning:  db 0Dh,0Ah,0Dh,0Ah
             db "WARNING: THIS WILL REPLACE YOUR DISKETTE'S BOOT SECTOR!  "
             db 'Do it (Y/N)?$'
msgWriting:  db 0Dh,0Ah,0Dh,0Ah
             db 'Writing boot program (position value: '
patchDigit:  db 2, ')... write: $'
msgVerify:   db ', verify: $'

statusOK:    db 'OK$'
statusFail:  db 'FAIL!',7,'$'

msgDone:     db 0Dh,0Ah,'All done!',0Dh,0Ah,'$'
msgFail:     db 0Dh,0Ah,'No luck - try another disk?',0Dh,0Ah,'$'

spareBuffer: