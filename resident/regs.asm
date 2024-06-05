

model tiny
.code

org 100H
    
_start:	
	mov ax, 0FFFFH
	mov bx, 0FFFFH
	mov cx, 0FFFFH
	mov dx, 0FFFFH
	mov di, 0FFFFH
	mov si, 0FFFFH
	jmp _start

end _start
