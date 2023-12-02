LOCALS  @@

code    segment
        assume cs:code
        org 100h
@beg:   jmp @start

        numbers label byte
        include numbers.inc
        texture label byte
        include texture.inc
        buf    db   8 dup(32)
        hour   db   0
        min    db   0
        sec    db   0

@start: mov    ax,  13h
        int    10h
        mov    ax,  0A000h
        mov    es,  ax
        call   setpal
        xor    di,  di
        mov    cx,  4
        call   tex
@@1:    mov    ah,  2Ch
        int    21h
        xor    bp,  bp
        mov    al,  ch
        call   decode
        mov    al,  cl
        call   decode
        mov    al,  dh
        call   decode
        cmp    hour,  ch
        jne    @@2
        cmp    min,  cl
        jne    @@2
        cmp    sec,  dh
        je     @@3
@@2:    push   cx
        push   dx
        call   vertret
        mov    di,  16000
        mov    cx,  2
        call   tex
        call   outbuf
        pop    dx
        pop    cx
@@3:    mov    hour,  ch
        mov    min,  cl
        mov    sec,  dh
        mov    ah,  1
        int    16h
        jz     @@1
        mov    ax,  3
        int    10h
        int    20h

setpal  proc   near
        mov    si,  offset texture
        mov    dx,  3C8h
        mov    cx,  255
@@1:    mov    al,  cl
        mov    bp,  cx
        shl    bp,  2
        out    dx,  al
        inc    dx
        mov    al,  texture[bp + 2]
        shr    al,  4
        out    dx,  al
        mov    al,  texture[bp + 1]
        shr    al,  4
        out    dx,  al
        mov    al,  texture[bp]
        shr    al,  4
        out    dx,  al
        dec    dx
        loop   @@1
        mov    al,  7
        out    dx,  al
        inc    dx
        mov    al,  63
        out    dx,  al
        out    dx,  al
        out    dx,  al
        ret
setpal  endp

tex     proc   near
        mov    si,  offset texture + 1024
@@1:    push   cx
        push   di
        push   si
        mov    cx,  50
@@2:    push   cx
        mov    cx,  4
@@3:    push   si
        push   cx
        mov    cx,  40
        rep    movsw
        pop    cx
        pop    si
        loop   @@3
        add    si,  80
        pop    cx
        loop   @@2
        pop    si
        pop    di
        pop    cx
        add    di,  16000
        loop   @@1
        ret
tex     endp

outnum  proc   near
        push   ax
        push   cx
        mov    si,  offset numbers + 2560
        mov    bp,  sp
        mov    bx,  [bp + 6]
        cmp    bx,  32
        je     @@5
        mov    ax,  10
        sub    ax,  bx
        shl    al,  2
        sub    si,  ax
        xor    dx,  dx
        mov    ax,  [bp + 8]
        mov    bx,  320
        mul    bx
        add    ax,  [bp + 10]
        mov    di,  ax
        mov    cx,  64
@@1:    push   cx
        mov    cx,  4
@@2:    push   cx
        mov    cx,  8
@@3:    push   cx
        mov    al,  ds:[si]
        dec    cl
        shr    al,  cl
        test   al,  1
        jz     @@4
        mov    al,  7
        mov    es:[di],  al
@@4:    inc    di
        pop    cx
        loop   @@3
        inc    si
        pop    cx
        loop   @@2
        pop    cx
        add    di,  288
        sub    si,  44
        loop   @@1
@@5:    pop    cx
        pop    ax
        ret    6
outnum  endp

outbuf  proc   near
        mov    cx,  8
        mov    ax,  20
@@1:    push   ax
        push   68
        mov    bp,  8
        sub    bp,  cx
        xor    bh,  bh
        mov    bl,  buf[bp]
        push   bx
        call   outnum
        add    ax, 35
        loop   @@1
        ret
outbuf  endp

decode  proc   near
        xor    ah,  ah
        mov    bl,  10
        div    bl
        mov    buf[bp],  al
        mov    buf[bp + 1], ah
        add    bp,  3
        ret
decode  endp

vertret proc   near
        mov    dx,  3DAh
@@1:    in     al,  dx
        test   al,  8
        jz     @@1
@@2:    in     al,  dx
        test   al,  8
        jnz    @@2
        ret
vertret endp

code    ends
        end @beg
