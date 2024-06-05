;; -----------------------------------------------------------------
;; Replaces interrupt with number /DI/ with function at /DS:DX/,
;; and with jmp far to old interrupt at /DS:SI/
;; 
;; Entry:  /SI/    -- Number of interrupt to replace (e.g. 09H)
;; 
;;         /ES:DX/ -- Pointer to function that will replace
;;                    old interrupt (with number /DI/)
;; 
;;         /ES:DI/ -- Pointer to buffer of size 4 bytes in
;;                    which old interrupt's offset and segment
;;                    will be saved (it can directly change
;;                    arguments of jmp far to old interrupt)
;; 
;; Return: None
;; 
;; Destr: /AX/, /BX/, /CX/, /DI/, /SI/
;; -----------------------------------------------------------------
intercept_interrupt proc
	mov cx, es

	xor bx, bx		; We'll be writing to ivt 
	mov ds, bx

	shl si, 2H		; Each ivt entry spans 4 bytes

	lodsw
	stosw

	lodsw
	stosw

	lea di, [si - 4]

	cli

	mov es, bx

	mov ax, dx
	stosw

	mov ax, cx
	stosw

	sti

	ret
intercept_interrupt endp

.hook_interrupt macro int_number, function
local @@interrupt_wrapper, @@previous_interrupt, @@after_declaration

	jmp @@after_declaration

@@interrupt_wrapper:
    	push si di dx cx bx ax
	call &function			; Calls int handler
    	pop  ax bx cx dx di si

	db 0EAH				; Opcode of "jmp far"
@@previous_interrupt dd 0H		; xxxx:xxxx -- dword

@@after_declaration:
	mov si, &int_number

	mov ax, cs
	mov es, ax

	lea dx, @@interrupt_wrapper
	lea di, @@previous_interrupt

	call intercept_interrupt
endm

.terminate_interrupt macro
	pop cx
    	pop ax bx cx dx di si
    	iret
endm    

.jmp_to_previous_handler macro    
    	ret
endm
