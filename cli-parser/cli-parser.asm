model tiny
.code

org 100H
locals

.program_exit macro error_code
	mov ah, &sys_exit
	mov al, &error_code
	int dos_services
endm    

.getchar macro error_code
	mov ah, &sys_getchar
	int dos_services
endm    

.looper macro register, mark
	dec &register
	ja &mark
endm   	

;; ---- DOS Services Nums ---- 
sys_write_char	=	02H
sys_exit 	=	00H
sys_getchar 	=	01H

dos_services    =	21H


_start:	
	.program_exit success

;; ------------------------------------------------------------------
;; Parses CLI arguments
;; 
;; Entry: SI -- pointer to start of CLI string
;; 
;; 
;; 
;; 
;; 
;; 
;; 
;; 
;; 
;; 
;; 
;; ------------------------------------------------------------------
parse_commands proc
	call skip_whitespace

endp

;; ------------------------------------------------------------------
;; Skips whitespace symbols  
;; 
;; Entry:  SI -- string (pointer to non-terminated array of char),
;; 		 which contains whitespace that need to be skipped.
;; 
;; Return: SI -- pointer to first non-whitespace symbol encountered
;; 		 in the passed string.
;; 
;; Destr: None
;; ------------------------------------------------------------------
skip_whitespace proc
current_symbol:	
	lodsb			; Load current symbol

	cmp al, ' '		; Exit if it's not whitespace symbol
	je current_symbol

	dec si			; Revert to last symbol checked
	ret
skip_whitespace endp


;; ------------------------------------------------------------------
;; Takes value of an arg, and returns information about argument, 
;; that it represents.
;; 
;; // TODO //
;; ------------------------------------------------------------------

recognise_flag proc
    lodsb



recognise_flag endp

;; ------------------------------------------------------------------
;; Compare two strings
;; 
;; // TODO //
;; ------------------------------------------------------------------
strcmp proc
find_matching_symbols:	
    mov ax, [si]
    inc si

    mov dx, [di]
    inc di



strcmp endp













.data

;; Enum of possible operator types
int_type	equ 		0
str_type	equ 		1
opt_type	equ 		3

cli_options:
    db '--width'   , '-w', int_type, 40
    db '--height'  , '-h', int_type, 25
    db '--centered', '-c', opt_type,  1 ; TODO explain default value

end _start
