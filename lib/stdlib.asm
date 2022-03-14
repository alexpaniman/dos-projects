locals @@
.186					; Enable 80186 processor instructions

;; ---- DOS Services Nums ----
sys_write_char   equ	02H
sys_write_string equ	09H
sys_getchar	 equ	01H
sys_exit	 equ	00H

dos_services     equ	21H

;; Video segment location:
videoseg         equ	0B800H

;; Exit codes:
success		 equ	00H
failure		 equ	01H

;; ------------------------------------------------------------

.exit_program macro exit_code
	mov ah, sys_exit
	mov al, &exit_code
	int dos_services
endm

;; ------------------------------------------------------------

.exit_resident macro program_end, exit_code 
	mov ah, 31H
	mov al, &exit_code

	lea dx, &program_end
	add dx, 0FH		; Round upwards
	shr dx, 04H		; Divide by segment size

	int dos_services
endm

;; ------------------------------------------------------------

.read_char macro error_code
	mov ah, sys_getchar
	int dos_services
endm

;; ------------------------------------------------------------

.print_char macro symbol
	mov ah, sys_write_char
	mov dl, &symbol
	int dos_services
endm

;; ------------------------------------------------------------

.print_addr macro string_to_print
	mov ah, sys_write_string
	mov dx, &string_to_print

	int dos_services
endm

;; ------------------------------------------------------------
;; Print immediate string
;; 
;; Entry: /string_to_print/ -- '$'-terminated string label
;; 
;; Destr: /AH/ /DX/
;; ------------------------------------------------------------
.print macro string_to_print
	mov ah, sys_write_string
	lea dx, &string_to_print

	int dos_services
endm

;; ------------------------------------------------------------

.print_new_line macro
	;; Carret return '\r'
	.print_char 0DH

	;; New line character '\n'
	.print_char 0AH
endm

;; ------------------------------------------------------------

.println macro string_to_print
	.print &string_to_print
	.print_new_line
endm

;; ------------------------------------------------------------

.load_string_literal macro register_name, string
	local @@after_message, @@string
	jmp @@after_message
@@string db &string, 0

@@after_message:
	lea &register_name, @@string
endm

;; ------------------------------------------------------------

.load_string_literal_$_terminated macro register_name, string
	local @@after_message, @@string
	jmp @@after_message
@@string db &string, '$'

@@after_message:
	lea &register_name, @@string
endm

;; ------------------------------------------------------------

.print_literal macro string
local @@after_message, @@message
	jmp @@after_message
@@message db &string, '$'

@@after_message:
	.print @@message
endm

;; ------------------------------------------------------------

.println_literal macro string
	.print_literal &string
	.print_new_line
endm

;; ------------------------------------------------------------

.looper macro register, mark
	dec &register
	jnz &mark
endm

;; ------------------------------------------------------------

.peek macro register
	pop  &register
	push &register
endm

;; ------------------------------------------------------------
.load macro expression, label
    	mov word ptr &expression, offset &label
endm
;; ------------------------------------------------------------

true		=	1H
false		=	0H
