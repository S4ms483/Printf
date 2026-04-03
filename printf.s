global my_printf

section .text 

firstSymb   equ   62h
lastSymb    equ   78h

bufferLen   equ   128d
stdOut      equ   1h
funcNum     equ   1h

hexShift    equ   4h
octShift    equ   3h
binShift    equ   1h

hexMaxDigit equ   0fh
octMaxDigit equ   07h 
binMaxDigit equ   01h

decMaxDigit equ   09d

errorLen   equ   15d


start:
my_printf:      mov [oldRsp], qword rsp

                pop r10
                mov [retAdr], r10

                push r9
                push r8
                push rcx
                push rdx
                push rsi
    
                mov rcx, bufferLen
                mov rsi, buffer

                mov al, byte [rdi]
                mov rdx, bufferLen
                call print

                mov rsp, [oldRsp]

 printfEnd:     pop r9
                mov r10, [retAdr]
                push r10
                ret

;rdi rsi rdx rcx r8 r9


;rdi - stdOut
;rsi - buf
;rdx - len
;------------------------------------------------------------------
;Entry:         rcx - string len
;               al - first symbol
;               rsi - buffer address
;               rdi - string address
;               rdx - buffer length
;------------------------------------------------------------------
print           
 loop:          cmp al, 0
                je strEnd

                cmp al, '%'
                je percent

 noCompare:     mov [rsi], al
 
                inc rsi
                inc rdi
                dec rcx

                cmp rcx, 0
                je bufOutput

                mov al, byte [rdi]
                jmp loop

 bufOutput:     mov rdx, bufferLen
                mov rsi, buffer
                call bufferOutput

                mov rcx, bufferLen
                mov al, byte [rdi]

                mov qword [buffer], 0h
                jmp loop

 strEnd:        mov rsi, buffer
                mov rdx, bufferLen
                sub rdx, rcx
                call bufferOutput

                mov qword [buffer], 0h
                ret

 percent:       inc rdi
                mov al, [rdi]
                cmp al, '%'

                jne other

                jmp noCompare

 other:         pop r8
                pop r9
                mov [arg], r9

                push r8

                push rdi
                call .printPercent
                pop rdi

                inc rdi
                mov al, byte [rdi]
                mov rdx, bufferLen
                jmp loop
;---------------------------------------------
;Entry:         rdi - string address
;               al  - symbol following percent
;---------------------------------------------
.printPercent   xor rbx, rbx
                mov bl, al

                cmp rbx, firstSymb
                jl error

                cmp rbx, lastSymb
                ja error   

                sub rbx, firstSymb

                call [jumpTable + 8 * rbx]
                ret

 lb:            push rdi
                call strEnd
                pop rdi

                mov rax, [arg]
                mov r8, bufferLen
                mov cl, binShift
                mov r10, binMaxDigit
                call CountDigits
                call NumPrint

                mov rsi, buffer
                mov rcx, bufferLen
                ret

 lc:            push rdi
                call strEnd
                pop rdi

                mov rdx, 1
                mov rsi, buffer
                call bufferOutput

                mov rsi, buffer
                mov rcx, bufferLen

                ret

 ld:            push rdi
                call strEnd
                pop rdi

                mov rax, [arg]
                mov rcx, bufferLen
                call CountDecDigits
                call DecNumPrint

                mov rsi, buffer
                mov rcx, bufferLen
                ret

 lo:            push rdi
                call strEnd
                pop rdi

                mov rax, [arg]
                mov r8, bufferLen
                mov cl, octShift
                mov r10, octMaxDigit
                call CountDigits
                call NumPrint

                mov rsi, buffer
                mov rcx, bufferLen
                ret

 ls:            push rdi
                call strEnd
                pop rdi

                push rdi
                mov rdi, [arg]
                call strlen
                pop rdi
                mov rsi, [arg]
                call bufferOutput
                mov rsi, buffer
                ret

 lp:
 lx:            push rdi
                call strEnd
                pop rdi

                mov rax, [arg]
                mov r8, bufferLen
                mov cl, hexShift
                mov r10, hexMaxDigit
                call CountDigits
                call NumPrint

                mov rsi, buffer
                mov rcx, bufferLen
                ret

 error:         mov rsi, errorMsg
                mov rdx, errorLen
                call bufferOutput
                jmp printfEnd

;-----------------------------------------------------
strlen          xor rdx, rdx

 .len           mov al, byte [rdi]
                inc rdx
                inc rdi
                cmp al, 0
                jne .len

                ret
;-------------------------------------------------------
;Entry:         rax - num
;               cl - shift length
;               r10  - max digit
;Exit:          rbx - amount of digits
;-------------------------------------------------------
CountDigits     push rax
                push rcx
                xor rbx, rbx

 .count         inc rbx
                cmp rax, r10    ;max digit
                jle .end
                shr rax, cl    ;shift len
                jmp .count

 .end           pop rcx
                pop rax 
                ret
;--------------------------------------------------------
;Entry:         rax - num
;               rbx - number of digits
;               cl  - shift len
;               r8  - buffer len
;--------------------------------------------------------
NumPrint 
 .loop          push rax  
                push rbx

 .rShift        dec rbx
                jz .rContinue
                shr rax, cl
                jmp .rShift

 .rContinue     pop rbx

                mov byte dl, [digits + rax]

                mov byte [rsi], dl
                inc rsi
                dec r8

                mov r9, rax

                push rbx

 .lShift        dec rbx
                jz .lContinue
                shl r9, cl
                jmp .lShift

 .lContinue     pop rbx
                pop rax
                sub rax, r9

                dec rbx

                cmp rbx, 0
                je .strEnd
            
                cmp r8, 0
                je .bufOutput

                jmp .loop

 .bufOutput     push rax
                mov rdx, bufferLen
                mov rsi, buffer
                call bufferOutput
                pop rax

                mov r8, bufferLen

                mov qword [buffer], 0h
                jmp .loop
    
 .strEnd        mov rdx, bufferLen
                mov rsi, buffer
                sub rdx, r8
                call bufferOutput

                mov qword [buffer], 0h
                ret
;--------------------------------------------------------
;Entry:         rax - num
;Exit:          r8 - number of digits
;--------------------------------------------------------
CountDecDigits  mov eax, eax
                push rax
                shr rax, 31
                cmp rax, 1
                pop rax
                je .negative
                jmp .continue

 .negative      xor bx,bx
                sub bx, ax
                mov rax, rbx

                push rdi
                push rax

                mov rdx, 1
                mov rsi, buffer
                call bufferOutput 

                pop rax
                pop rdi
                mov rsi, buffer
                mov rcx, bufferLen

 .continue      xor r8, r8
                push rax
                push rdx

 .count         xor rdx, rdx
                inc r8
                cmp ax, decMaxDigit
                jle .end
                mov bx, 10d
                div bx
                jmp .count

 .end           pop rdx 
                pop rax
                ret
;--------------------------------------------------------
;Entry:         rax - num
;               r8  - number of digits
;--------------------------------------------------------
DecNumPrint     
.loop           push rax  
                push r8


 .rShift        xor rdx, rdx
                dec r8
                jz .rContinue
                mov bx, 10d
                div bx
                jmp .rShift

 .rContinue     pop r8

                mov byte dl, [digits + rax]

                mov byte [rsi], dl
                inc rsi
                dec rcx

                mov r9, rax

                push r8

 .lShift        xor rdx, rdx
                dec r8
                jz .lContinue
                mul bx
                jmp .lShift

 .lContinue     pop r8
                pop r9
                sub r9, rax
                mov rax, r9

                dec r8
            
                cmp r8, 0
                je .strEnd
                cmp rcx, 0
                je .bufOutput

                jmp .loop

 .bufOutput     push rax
                mov rdx, bufferLen
                mov rsi, buffer
                call bufferOutput
                pop rax

                mov rcx, bufferLen
                jmp .loop
    
 .strEnd        mov rdx, bufferLen
                sub rdx, rcx
                mov rsi, buffer
                call bufferOutput
                ret
;--------------------------------------------------------
bufferOutput    push rdi
                push rcx
                mov rdi, stdOut
                mov rax, funcNum
                syscall
                pop rcx
                pop rdi

                ret
;--------------------------------------------------------
section .data align=8   

digits:        db  '0123456789abcdef'

minus:         db  '-'

errorMsg:      db  'Syntax error \n'
buffer:        dq  0

oldRsp:        dq  0
arg:           dq  0
retAdr:        dq  0 

jumpTable:
 dq lb
 dq lc
 dq ld
 db ('o' - 'd' - 1) dup qword error
 dq lo
 dq lp
 db ('s' - 'p' - 1) dup qword error
 dq ls
 dq ('x' - 's' - 1) dup qword error
 dq lx
 dq error