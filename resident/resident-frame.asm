model tiny
.code

org 100H
    
_start:	
	jmp entry

	include stdlib.asm
	include string.asm

;; ------------------------------------------------------------
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
;; ------------------------------------------------------------
intercept_interrupt proc
	mov cx, ds

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
	pusha
	call &function			; Transparently calls interceptor function
	popa

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

	

;; ---------------------- ENTRY POINT -------------------------
entry:	
	.hook_interrupt 08H, int08_interceptor
	;; .hook_interrupt 08H, int08_interceptor

	.exit_resident program_end, success
;; ------------------------------------------------------------
keyboard_scan_code	equ	60H
switch_button_scan_code	equ	3BH

int09_interceptor proc
;;     	in al, keyboard_scan_code

;;     	cmp al, switch_button_scan_code
;;     	jne @@do_not_switch

;;     	not cs:[enable_registers_display]

;; @@do_not_switch:    
    	ret
        ;; mov ah, al
        ;; or al, 80h
        ;; out 61h, al
        ;; mov al, ah
        ;; out 61h, al
        
        ;; ; EOI
        ;; mov al, 20h
        ;; out 20h, al

    	;; pop cx
    	;; popa
    	;; iret
int09_interceptor endp

;; ------------------------------------------------------------

int08_interceptor proc
    	push bp
    	mov bp, sp

	push es ds

	mov ax, 0B800H
	mov es, ax

    	push (80*5 + 20) * 2
    	push 40D
    	push offset @@msg
    	push offset @@frame
    	push 4E00H

	call draw_line
   	add word ptr ss:[bp-6], (80)*2
    
	call draw_line
    	add sp, 5 * 2

    	pop ds es bp
	ret

@@frame	db '| |'
@@msg	db 'Hello', 0
int08_interceptor endp

;; ------------------------------------------------------------
;; Draws a line that starts with a si[0], continues cx
;; times with si[1], and ends with si[2]
;;
;; Entry: color -- Color attribute of a line in specified format:
;;                 	[blink, r, g, b, intensity, r, g, b] 
;;                  	^ ^          ^  ^   ^            ^
;;                  	| |          |  |   |            |
;;                  	+------------+  +----------------+
;;                  	  Background        Foreground
;;                  	  |                 |
;;                  	Flag that enables   Flag that makes
;;                  	color blinking      color intensive
;; 
;;		    ==> Note:
;;
;;		    	This actualy takes up just 1 byte, but
;;		    	pushed to the stack as 2 bytes.
;;
;;                  	To address this, only upped byte is taken
;; 			into account, lower byte byte isn't,
;;			you can push anything there (e.g. 0H)
;;
;;		    ==> Example:
;;
;; 			push 4E00H ; for yellow color on red
;;			       ^~ can be anything
;;
;;        width  -- Desired width in symbols of the line excluding
;;                  side symbols (so it's actual width - 2)
;; 
;;        text   -- String that should be drawn in this line 
;;        
;;        corner -- Address of the start of a line, counting
;;                  from top left corner, generaly it works so:
;;            
;;                  | <- x -> |
;;               ---+----------------------------------------+
;;                ^ |         |                              |
;;                | |                                        |
;;                y |         |                              |
;;                | |                                        |
;;                v |         |                              |
;;               ---| - - - - +--------------------------+   |
;;                  |         ^ top left corner          |   |
;;                  |         |     LINE TO BE DRAWN     |   |
;;                  |         +--------------------------+   |
;;                  +----------------------------------------+
;;            
;;                  For this positioning, you should pass in DI:
;;                      ==> y * 80 + x.
;;
;;        symbols -- address of array of 3 bytes, that stores 
;;                   symbols used to draw a line like so:
;;                   [left symbol, middle symbol, right symbol]
;;                   
;;                   Left and right symbols are printed only
;;                   once, at the start and the end of a line.
;;        
;;                   Middle symbol, on contrary, gets repeated
;;                   width - 2 times in the middle of a string.
;;                                 
;; Note:  /ES/ == should be set to videoseg address (0B800H)
;; 
;;  ==> After execution:
;;
;;        /CX/ == 0 after the execution
;;
;;        DI is going to point to the cell immediatly after
;;        the last drawn symbol of the line.
;; 
;;        SI will point to the array element immediatly
;;        after the right frame symbol.
;;      
;; Destr: /AL/, /BX/, /CX/, /DX/, /DI/, /SI/
;; ------------------------------------------------------------

draw_line proc   
    	push bp
    	mov bp, sp

    	mov dx, cs
    	mov ds, dx

    	mov ax, [bp + 04]
    	mov si, [bp + 06]
    	mov di, [bp + 12]

	lodsb			; Load left symbol to /AL/
	stosw			; Write it to the screen

    	mov dx, si

    	mov si, [bp + 08]
	call strlen

    	mov bx, [bp + 10]
	sub bx, cx
	mov cx, bx		

	shr bx, 1H		; Calculate right alignment
	sub cx, bx		; Calculate left  alignment

	mov si, dx		; Load filler symbol
	lodsb
    	mov dx, si

	rep stosw		; Write left  alignment

    	mov cx, bx
    	mov bl, al

	mov si, [bp + 08]	; <---- Write string -----

@@write_string:			
	lodsb		

    	cmp al, 0H
	je @@stop_writing_string

	stosw	
    	jmp @@write_string

@@stop_writing_string:

    	mov al, bl
	rep stosw

	mov si, dx
	lodsb			; Load right symbol to /AL/
	stosw			; Write it to the screen

    	pop bp
	ret
draw_line endp   

.data
	;; Frame is disabled by default
    	enable_registers_display	db false

;; ------------------------------------------------------------
program_end:			; Should be last
;; ------------------------------------------------------------
end _start
