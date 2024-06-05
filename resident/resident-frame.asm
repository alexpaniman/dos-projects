model tiny
.code

org 100H
    
_start:	
	jmp entry

	include stdlib.asm
	include string.asm

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
	call &function			; Transparently calls interceptor function
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

;; -------------------------- ENTRY POINT --------------------------
entry:	
	.hook_interrupt 09H, int09_interceptor
	.hook_interrupt 08H, int08_interceptor

	.exit_resident program_end, success
;; -----------------------------------------------------------------

keyboard_scan_port	equ	60H
keyboard_ctl_lines_port	equ 	61H
signal_port		equ 	20H
end_of_interrupt_signal	equ	20H

most_significant_bit	equ	80H

switch_button_scan_code	equ	3BH

int09_interceptor proc
    	in al, keyboard_scan_port

	cmp al, switch_button_scan_code
    	jne @@do_not_switch

    	not cs:[enable_registers_display]

        ;; Keyboard accepted signal
        mov ah, al
        or al, most_significant_bit
        out keyboard_ctl_lines_port, al

        mov al, ah
        out keyboard_ctl_lines_port, al
        
	;; End of interrupt signal
        mov al, end_of_interrupt_signal
        out signal_port, al

    	.terminate_interrupt

@@do_not_switch:    
	.jmp_to_previous_handler
int09_interceptor endp

;; -----------------------------------------------------------------
;; Draws desired text colored with color in rectangular frame
;; 
;; Call Convention: CDECL
;;
;; Signature:
;; 	void draw_frame(uint8_t color, uint8_t corner,
;; 			uchar8_t* message)
;; 	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; 
;; Entry: color   -- color in the same format as for /draw_line/
;;	 	     (see it's documentation for description) 
;;
;;	  message -- desired text message
;; -----------------------------------------------------------------
draw_frame proc
	push bp
	mov bp, sp

    	sub sp, 2H

    	mov si, [bp + 08]
	call split_multiline

    	mov [bp - 02], cx
    	mov dx, cx

    	xor bx, bx
    	mov si, [bp + 08]
@@next_line:
    	call strlen
    	inc si

    	cmp bx, cx
   	jae @@do_not_update_max
    	
   	mov bx, cx 
@@do_not_update_max:   	 
    	.looper dx, @@next_line

    	add bx, 2

	mov ax, videoseg
	mov es, ax
    	
    	push offset @@top_line
    	push offset @@empty
    	push [bp + 06]	
    	push bx
    	push [bp + 04]
    	call draw_line

	mov word ptr [bp - 04], \
	    offset @@mid_line

    	mov si, [bp + 08]

@@load_next_string:
    	add word ptr [bp - 08], 80 * 2

    	mov [bp - 06], si
    	call draw_line

    	mov cx, [bp - 02]
    	mov si, [bp - 06]
    	call strskip
    	
    	dec word ptr [bp - 02]
    	jnz @@load_next_string

    	add word ptr [bp - 08], 80 * 2

	mov word ptr [bp - 04], \
	    offset @@bot_line

	mov word ptr [bp - 06], \
            offset @@empty

    	call draw_line
    	
	leave
	ret

.data
@@empty		db 0

@@top_line	db '+-+'
@@mid_line	db '| |'
@@bot_line	db '+-+'

draw_frame endp
    
int08_interceptor proc
    	push bp
    	mov bp, sp

    	cmp cs:[enable_registers_display], false
    	je @@do_not_draw

	push es ds

    	push si di dx cx bx ax

    	mov ax, cs
    	mov ds, ax
    	mov es, ax

    	lea di, @@buffer_for_registers

    	mov ax, offset registers_names
    	mov cx, registers_count

    	call print_registers_in_buffer

    	add sp, 6 * 2H

    	push offset @@buffer_for_registers
    	push (80 * 4 + 20)*2
    	push 4E00H

    	call draw_frame
    	add sp, 3 * 2H

    	pop ds es

@@do_not_draw:
    	pop bp
	ret

@@buffer_for_registers	db 256 dup(0)

@@frame	db '| |'
@@msg	db 'Hello', 0
int08_interceptor endp

;; -----------------------------------------------------------------
;; Draws a line of a table (primarily for use in /draw_frame/)
;;
;; Call Convention: CDECL
;; 
;; Signature:
;; 	void draw_line(uint8_t color, uint8_t width, uint8_t corner,
;; 		       uchar8_t* text, uchar8_t* symbols)
;;      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; 
;; Entry: color   -- Color attribute of a line in specified format:
;;                      [blink, r, g, b, intensity, r, g, b] 
;;                   	^ ^          ^  ^   ^            ^
;;                   	| |          |  |   |            |
;;                   	+------------+  +----------------+
;;                   	  Background        Foreground
;;                   	  |                 |
;;                   	Flag that enables   Flag that makes
;;                   	color blinking      color intensive
;; 
;;		     ==> Note:
;;
;;		     	This actualy takes up just 1 byte, but
;;		     	pushed to the stack as 2 bytes.
;;
;;                   	To address this, only upped byte is taken
;; 		        into account, lower byte byte isn't,
;;		        you can push anything there (e.g. 0H)
;;
;;		     ==> Example:
;;
;; 			push 4E00H ; for yellow color on red
;;			       ^~ can be anything
;;
;;        width   -- Desired width in symbols of the line excluding
;;                   side symbols (so it's actual width - 2)
;;
;;        corner  -- Address of the start of a line, counting
;;                   from top left corner, generaly it works so:
;;            
;;                   | <- x -> |
;;                ---+----------------------------------------+
;;                 ^ |         |                              |
;;                 | |                                        |
;;                 y |         |                              |
;;                 | |                                        |
;;                 v |         |                              |
;;                ---| - - - - +--------------------------+   |
;;                   |         ^ top left corner          |   |
;;                   |         |     LINE TO BE DRAWN     |   |
;;                   |         +--------------------------+   |
;;                   +----------------------------------------+
;;            
;;                   For this positioning, you should pass in DI:
;;                       ==> y * 80 + x.
;;
;;        text    -- String that should be drawn in this line 
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
;; Destr: /AX/, /BX/, /CX/, /DX/, /DI/, /SI/
;; -----------------------------------------------------------------

draw_line proc   
    	push bp			; Function prologue
    	mov bp, sp

    	mov dx, cs		; /DS/ <== /CS/ (to ensure we can access
    	mov ds, dx		; our data, see .model tiny)

    	mov ax, [bp + 04]	; Load /color/ (actually in /AH/)
				; See /color/ for more information

    	mov di, [bp + 08]	; /DI/ <== /corner/
    	mov si, [bp + 12]	; /SI/ <== /symbols/

	lodsb			; Load left symbol (see /symbols/)
	stosw			; Write it to the screen

    	mov dx, si		; Save /symbols/ from destruction

    	mov si, [bp + 10]	; /SI/ <== /text/
	call strlen		; /CX/ <== length of /text/

    	mov bx, [bp + 06]	; Load /width/
	sub bx, cx		; /BX/ <== /width/ - length of /text/
	mov cx, bx		

	shr bx, 1H		; /BX/ <== (/BX/) / 2    (right padding)
	sub cx, bx		; /CX/ <== rest of width (left  padding)

	mov si, dx		; /SI/ <== middle filler symbol
	lodsb
    	mov dx, si

	rep stosw		; Write left  alignment

    	mov cx, bx
    	mov bl, al

	mov si, [bp + 10]	; <---- Write string -----

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

    	pop bp			; Epilogue
	ret
draw_line endp   

.data
;; Frame is disabled by default
enable_registers_display	db false

;; -----------------------------------------------------------------
;; Entry: registers -- Values of all general purpose registers,
;;		       populated by /pusha/
;;
;;		       ==> All register are passed through stack
;; 
;;	  /DS:AX/   -- Pointer to first structure with pointer to
;;		       register name string in /CX/-long array /CX/
;;
;; 	  /CX/      -- Number of entries in the table
;;
;;	  /ES:DI/   -- Pointer to buffer with register entries
;;
;; Side Effects: Writes registers to buffer
;;
;; Return: None
;; -----------------------------------------------------------------
print_registers_in_buffer proc
    	push bp
   	mov bp, sp 

	push ax cx

    	lea bx, [bp + 4]

@@next_register:
    	mov si, [bp - 2]
    	mov si, [si]
    	call strcpy

    	dec di

    	add word ptr [bp - 2], 2

    	push bx

    	mov dx, ss:[bx]
    	call itoa_hex

    	pop bx

    	add bx, 02

    	inc di
   	mov [di - 2], 0A0DH

    	dec word ptr [bp - 4]
    	jnz @@next_register

    	.terminate_string

	leave
    	ret
print_registers_in_buffer endp


ax_name:    .string 'AX = '
bx_name:    .string 'BX = '
cx_name:    .string 'CX = '
dx_name:    .string 'DX = '
si_name:    .string 'SI = '
di_name:    .string 'DI = '

registers_names:
    	dw offset ax_name
    	dw offset bx_name
    	dw offset cx_name
    	dw offset dx_name
    	dw offset di_name
    	dw offset si_name

registers_count = ($ - registers_names) / 2

;; -----------------------------------------------------------------
program_end:			; Should be last
;; -----------------------------------------------------------------
end _start
