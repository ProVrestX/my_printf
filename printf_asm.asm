
section .text
    BufCamp equ 15

    global printf_asm

%macro push_regs 0
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
%endmacro

%macro pop_regs 0
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
%endmacro


printf_asm:
    pop qword [FuncRetAddr]
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi
    push rbx
    add rsp, 8
    
    mov byte [BufSize], 0
    mov rdi, Buf
    call GetStr
    call PrintBuf

ClrArgs:
    cmp byte [CntArgs], 6
    jg ClrArgsEnd
    pop rax
    inc byte [CntArgs]
    jmp ClrArgs

ClrArgsEnd:
    ; push qword [StrLen]
    ; push StrToLen

    ; call GetStr
    ; call PrintBuf

    ; mov rax, 0x3c
    ; xor rdi, rdi
    ; syscall
    sub rsp, 8
    pop rbx
    mov rax, qword [StrLen]
    push qword [FuncRetAddr]
    ret


; Input:    rsi
; Output:   rdi
GetStr:
    ; mov byte [CntArgs], 1
    pop qword [GetStrRetAddr]
    pop rsi

    ChkSym:
        call ChkBufSize
        lodsb
        cmp al, 0
        je ChkSymEnd

        cmp al, '%'
        je ChkPercent
        jmp SwInsEnd

    ChkPercent:
        xor rax, rax
        lodsb
        ; inc byte [CntArgs]
        ; cmp al, 'c'
        ; je SwInsC
        ; cmp al, 's'
        ; je SwInsS
        ; cmp al, 'd'
        ; je SwInsD
        ; cmp al, 'x'
        ; je SwInsX
        ; cmp al, 'o'
        ; je SwInsO
        ; cmp al, 'b'
        ; je SwInsB
        ; dec byte [CntArgs]
        ; jmp SwInsEnd
        mov r8, [JmpTable + (rax - '%')*8]
        jmp r8
        JmpTable:   dq SwInsEnd
                    times('b' - ('%' + 1)) dq SwInsErr
                    dq SwInsB
                    dq SwInsC
                    dq SwInsD
                    times('o' - ('d' + 1)) dq SwInsErr
                    dq SwInsO
                    times('s' - ('o' + 1)) dq SwInsErr
                    dq SwInsS
                    times('x' - ('s' + 1)) dq SwInsErr
                    dq SwInsX

    SwInsC:
        pop rax
        inc byte [BufSize]
        stosb
        jmp ChkSym

    SwInsS:
        mov rdx, rsi
        pop rsi              
        SwInsSLoop:
            lodsb       
            xchg rsi, rdx
            cmp al, 0   
            je ChkSym
            xchg rsi, rdx
            inc byte [BufSize]
            stosb
            call ChkBufSize
            jmp SwInsSLoop
    
    SwInsD:
        mov rbx, 10
        jmp SwInsNum
    SwInsX:
        mov rbx, 16
        jmp SwInsNum
    SwInsO:
        mov rbx, 8
        jmp SwInsNum
    SwInsB:
        mov rbx, 2
        jmp SwInsNum

    SwInsNum:
        pop rax
        ; cmp rax, 0
        ; je ChkSym

        call TranslNumSys

        cmp rax, 0
        jge NumIsPos
        imul rax, -1
        mov byte [rdi], '-'
        inc rdi
        inc byte [BufSize]

        NumIsPos:

        xor rcx, rcx 
        mov rbx, 16

        
        DivLoop:
            xor rdx, rdx
            div rbx
            mov dl, [DigitMass + rdx]
            push rdx
            inc rcx
            cmp rax, 0
            jne DivLoop
            
        InsLoop:
            pop rax
            inc byte [BufSize]
            stosb
            call ChkBufSize
            loop InsLoop
        
        jmp ChkSym  

    SwInsEnd:
        inc byte [BufSize]
        stosb
        jmp ChkSym

    SwInsErr:
        push_regs
        push rdi
        call PrintBuf

        mov rsi, ErrStr
        mov rdx, ErrStrLen
        mov rax, 1
        mov rdi, 1
        syscall

        pop rdi
        pop_regs
        inc rsi

        jmp ChkSym

    ChkSymEnd:

    push qword [GetStrRetAddr]
    ret

    

ChkBufSize:
    cmp byte [BufSize], BufCamp
    jge BufOversize
    ret
BufOversize:
    call PrintBuf
    ret

PrintBuf:
    ; push rax
    ; push rbx
    ; push rcx
    ; push rdx
    ; push rsi
    push_regs

    mov rax, 0x01
    mov rdi, 1
    mov rsi, Buf
    xor rdx, rdx
    mov dl, byte [BufSize]
    add qword [StrLen], rdx
    syscall

    mov byte [BufSize], 0
    mov rdi, Buf

    pop_regs
    ; pop rsi
    ; pop rdx
    ; pop rcx
    ; pop rbx
    ; pop rax
    ret

TranslNumSys:
    xor rcx, rcx
    mov r8, 1

    cmp rax, 0
    jge TranslDivLoop
    mov r8, -1
    imul rax, r8

    TranslDivLoop:
        xor rdx, rdx
        div rbx
        push rdx 
        inc rcx
        cmp rax, 0
        jne TranslDivLoop

    xor rax, rax

    TranslCompLoop:
        pop rdx
        ; imul rax, 16
        shl rax, 4
        add rax, rdx
        loop TranslCompLoop

    imul rax, r8
    ret

section .data

    GetStrRetAddr: dq 0
    FuncRetAddr: dq 0
    CntArgs: db 0
    DigitMass: db "0123456789abcdef"

    BufSize: db 0
    Buf: db BufCamp dup (0)
    StrLen: dq 0

    ; StrIn: db "Hello, %s%c\n", "Num 431 in\n", " hex: %x\n", " oct: %o\n", " bin: %b\n", 0x00
    ; StrIn: db "Hello, %s12345%c\n", 0x00
    ; StrIn: db "Hello", 0x00
    ; Str: db "World", 0x00
    ErrStr: db 0x0a, "Err with '%'", 0x0a, 0x00
    ErrStrLen equ $ - ErrStr
    StrToLen: db "Len: %d\n", 0x00
