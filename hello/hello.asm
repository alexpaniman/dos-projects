model tiny
.code

org 100H

;; --- Constant Definitions --- 
puts   	 	equ	09H
exit_success    equ	4C00H
sys     	equ	21H

;; --- Program Entry Point ---- 
start:
	mov ah, puts
	mov dx, offset message
	int sys

	mov ax, exit_success
	int sys

;; ----- Data Definitions ----- 
.data
message db 'Hello, world!', '$'

end start
