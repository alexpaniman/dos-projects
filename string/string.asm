;; string.asm --- partial implementation of string.h in 16-bit TASM

;; Copyright (c) Alex Paniman, 2022

;; Note: In this file term 'string' is used a lot, this note
;; 	 clarifies what it means.
;; 	 
;; 	 String is a pointer to the first symbol (which is 
;; 	 represented by a single byte, because this file
;; 	 doesn't account for anything multibyte), that is
;; 	 immediately followed by subsequent symbols, and
;; 	 terminated with NUL-symbol (symbol with ASCII code 0)
;; 	 
;; 	 Example:	db 'DED', 0  -- is a valid string.

;; Note: Each function defined in this file has two forms:
;; 	 form that takes arguments from registers, and is  
;; 	 meant to be used in human-written assembly for
;; 	 perfomance-intensive purposes.
;; 	 
;; 	 And form that uses CDECL calling convention.
;;	 As defined in:
;;		https://www.agner.org/optimize/calling_conventions.pdf

locals @@

;; ---------------------------------------------------------
;; Lexicographically compares two strings
;; 
;; Entry: /SI/    --  First string
;;        /ES:DI/ -- Second string
;; 
;; Note:  This function expects strings in form of pointers
;;        to an array of a subsequent symbols, that end
;;        with a null-terminator symbol (With ASCII code 0)
;; 
;; Return:  This function returns in /AL/:
;; 	   -> 00H if strings are equal
;; 	   -> 01H if first string < second string
;; 	   -> 10H if first string > second string
;; 
;; Destr:  /AL/, /DI/, /SI/
;; ---------------------------------------------------------
strcmp proc
compare_symbols:	
	cmpsb
	ja string1_is_bigger
	jb string2_is_bigger

	cmp byte ptr ds:[si - 1], 0H
	jne compare_symbols

	xor al, al
	ret

string1_is_bigger:	
	mov al, 10H
	ret

string2_is_bigger:	
	mov al, 01H
	ret
strcmp endp

;; ---------------------------------------------------------
;; CDECL adapter for /strcmp/
;;
;; Signature:	void strcmp(uchar8_t* str0, uchar8_t* str1)
;; ---------------------------------------------------------
strcmp_cdecl proc
	push bp
    	mov bp, sp

    	push si di

	cld

    	mov si, [bp + 4] 
    	mov di, [bp + 6] 
    	call strcpy

    	pop di si

    	pop bp
	ret
strcmp_cdecl endp


;; ---------------------------------------------------------
;; Find first occurrence of symbol in a string
;; 
;; Expect: /SI/ -- String in which we're searching
;;         /DL/ -- Target character
;; 
;; Return: /SI/ -- Pointer to desired char inside a string if
;;		   if it was found, and pointer to its
;; 		   0-terminator if symbol isn't present in string
;; 
;; Destr:  /AL/, /SI/
;; ---------------------------------------------------------
strchr proc
@@next_symbol:	
    	lodsb

    	cmp al, 0
    	je @@end_of_string

	cmp al, dl
    	jne @@next_symbol
    
@@end_of_string:    	
    	ret
strchr endp

;; ---------------------------------------------------------
;; CDECL adapter for /strchr/
;;
;; Signature:	uchar8_t* strchr(uchar8_t* string, uchar8_t symbol)
;; ---------------------------------------------------------
strchr_cdecl proc
	push bp
    	mov bp, sp

    	push si

	cld
    
    	mov si, [bp + 4] 
    	mov dx, [bp + 6] 
    	call strcpy

    	mov ax, si

    	pop si

    	pop bp
	ret
strchr_cdecl endp


;; ---------------------------------------------------------
;; Copies string to another destination
;; 
;; Expect: /SI/    -- String to copy
;;         /ES:DI/ -- Destination address
;; 
;; Return: None
;; 
;; Destr:  /SI/, /DI/
;; ---------------------------------------------------------
strcpy proc
write_string:	
	movsb

	cmp byte ptr ds:[si - 1], 0
	jne write_string

	ret
strcpy endp

;; ---------------------------------------------------------
;; CDECL adapter for /strcpy/
;;
;; Signature:	void strcpy(uchar8_t* src, uchar8_t* dest)
;; ---------------------------------------------------------
strcpy_cdecl proc
	push bp
    	mov bp, sp

    	push si di

	cld
    
    	mov si, [bp + 4] 
    	mov di, [bp + 6] 
    	call strcpy

    	pop di si

    	pop bp
	ret
strcpy_cdecl endp
	

;; ---------------------------------------------------------
;; Calculate string length
;; 
;; Expect: /SI/ -- String to calculate length
;; 
;; Return: /CX/ -- Length of the string
;; 
;; Destr:  /AL/, /CX/, /SI/
;; ---------------------------------------------------------
strlen proc
	xor cx, cx

next_symbol:
	inc cx

	lodsb
	cmp al, 0H
	jne next_symbol

	dec cx

	ret
strlen endp

;; ---------------------------------------------------------
;; CDECL adapter for /strlen/
;;
;; Signature:	uint16_t strlen(uchar8_t* string)
;; ---------------------------------------------------------
strlen_cdecl proc
	push bp
    	mov bp, sp

	cld

    	push si

    	mov si, [bp + 4] 
    	call strlen

    	pop si

    	mov ax, cx

    	pop bp
	ret
strlen_cdecl endp


;; ---------------------------------------------------------
;; Print 0-terminated string to stdout, align it to the right
;; 
;; Entry: /SI/ -- Target string (0-terminated, on contrary to
;; 		  DOS method, which uses '$')
;;
;; 	  /BX/ -- Alignment (if it's zero, alignment is ignored)
;;
;; 	  /DL/ -- Alignment char (with this char, space to the 
;; 	   	  left of the string will be filled with to
;;                match desired alignment)
;; 
;; Destr: /AH/, /BX/, /CX/, /DX/, /DI/
;; ---------------------------------------------------------
print_string proc
	mov di, si
	call strlen

	cmp bx, 0H
	jbe @@no_alignment

	sub bx, cx
	jbe @@no_alignment

@@print_alignment_char:
	mov ah, sys_write_char
	int dos_services

	dec bx
	ja @@print_alignment_char

@@no_alignment:
	mov ah, 40H
	mov dx, di
	mov bx, 1H

	int dos_services
	ret
print_string endp

;; ---------------------------------------------------------
;; CDECL adapter for /print_string/
;; 
;; Signature:	void print_string(uchar8_t* string,
;;                                uint8_t align,
;;                                uchar8_t  alignment_char)
;; ---------------------------------------------------------
print_string_cdecl proc
	push bp
    	mov bp, sp

    	push bx di

    	mov si, [bp + 4] 
    	mov bx, [bp + 6] 
    	mov dl, [bp + 8] 
    	call print_string

    	push di bx

    	pop bp
	ret
print_string_cdecl endp

;; ---------------------------------------------------------
;; Print decimal number representation to stdout
;; 
;; Entry: /DX/ -- Target number
;; 
;; Destr: /AH/, /BX/, /CX/, /DX/, /DI/, /SI/
;; ---------------------------------------------------------
print_number_decimal proc
	lea di, @@output_buffer
	call itoa_decimal

	lea si, @@output_buffer
	xor bx, bx
	call print_string

	ret

@@output_buffer db 16 dup('X')
print_number_decimal endp

;; ---------------------------------------------------------
;; CDECL adapter for /print_number_decimal/
;; 
;; Signature:	void print_number_decimal(uint16_t number)
;; ---------------------------------------------------------
print_number_decimal_cdecl proc
	push bp
    	mov bp, sp

    	push bx di si

    	mov dx, [bp + 4] 
    	call print_number_decimal

    	push si di bx

    	pop bp
	ret
print_number_decimal_cdecl endp


;; ---------------------------------------------------------
;; Masks out all bits except selected
;; ---------------------------------------------------------
mask_leading_byte		equ 	08000H
mask_leading_oct		equ 	0E000H
mask_leading_hex		equ 	0F000H

;; ---------------------------------------------------------
;; Shift needed for leading selection to become last
;; ---------------------------------------------------------
shift_leading_byte		equ 	   0FH
shift_leading_oct		equ 	   0DH
shift_leading_hex		equ 	   0CH

    
;; ---------------------------------------------------------
;; Insert 0-terminator
;;
;; Entry:   /ES:DI/ -- Target string
;;
;; Note:    After execution /DI/ points to pointer immediately
;;	    after 0-terminator of produced string
;;
;; Destr:   DI
;; ---------------------------------------------------------
.terminate_string macro
    mov byte ptr es:[di], 0
    inc di
endm


;; ---------------------------------------------------------
;; Write binary representation of a number to string
;;
;; Entry:   /DX/    -- target number
;;          /ES:DI/ -- string destination (buffer)
;;
;; Expect:  Cleared Destination Flag
;;
;; Note:    After execution /DI/ points to pointer immediately
;;	    after 0-terminator of produced string
;;
;; Destr:   /AX/, /BX/, /CX/, /DX/, /DI/  
;; ---------------------------------------------------------
itoa_binary proc
	mov cx, 10H
	jmp @@skip_zeros_start

@@skip_leading_zeros:
    	cmp cx, 1H
    	je @@write_to_string

	dec cx 
	shl dx, 1H

@@skip_zeros_start:
	mov bx, dx
    	and bx, mask_leading_byte

	cmp bx, 0H
	je @@skip_leading_zeros

@@write_to_string:
    	mov ax, dx
	shl dx, 1H

	shr ax, shift_leading_byte
	add al, '0'

    	stosb

	loop @@write_to_string

	.terminate_string
	ret
itoa_binary endp

;; ---------------------------------------------------------
;; CDECL adapter for /itoa_binary/
;; 
;; Signature:	void itoa_binary(uint16_t  number,
;;				 uchar8_t* output_buffer) 
;; ---------------------------------------------------------
itoa_binary_cdecl proc
	push bp
    	mov bp, sp

    	push bx di

	cld
    
    	mov dx, [bp + 4] 
    	mov di, [bp + 6] 
    	call itoa_binary

    	pop di bx

    	pop bp
	ret
itoa_binary_cdecl endp


;; ---------------------------------------------------------
;; Write hex representation of a number to string
;;
;; Entry:   /DX/    -- target number
;;          /ES:DI/ -- string destination (buffer)
;;
;; Expect:  Cleared Destination Flag
;;
;; Note:    After execution /DI/ points to pointer immediately
;;	    after 0-terminator of produced string
;;
;; Destr:   /AX/, /BX/, /CX/, /DX/, /DI/  
;; ---------------------------------------------------------
itoa_hex proc
	mov cx, 4H
	jmp @@skip_zeros_start

@@skip_leading_zeros:
    	cmp cx, 1H
    	je @@write_to_string

	dec cx
	shl dx, 4H
    
@@skip_zeros_start:
	mov bx, dx
    	and bx, mask_leading_hex

	cmp bx, 0H
	je @@skip_leading_zeros

@@write_to_string:
	mov bx, dx
	shl dx, 4H

	shr bx, shift_leading_hex
    	mov al, cs:[offset hex_translation_table + bx]

    	stosb

	loop @@write_to_string

	.terminate_string
	ret

hex_translation_table:
	db '0123456789ABCDEF'
itoa_hex endp

;; ---------------------------------------------------------
;; CDECL adapter for /itoa_hex/
;; 
;; Signature:	void itoa_hex(uint16_t  number,
;; 			      uchar8_t* output_buffer) 
;; ---------------------------------------------------------
itoa_hex_cdecl proc
	push bp
    	mov bp, sp

    	push bx di

	cld
    
    	mov dx, [bp + 4] 
    	mov di, [bp + 6] 
    	call itoa_hex

    	pop di bx

    	pop bp
	ret
itoa_hex_cdecl endp


;; ---------------------------------------------------------
;; Write octal representation of a number to string
;;
;; Entry:   /DX/    -- target number
;;          /ES:DI/ -- string destination (buffer)
;;
;; Expect:  Cleared Destination Flag
;;
;; Note:    After execution /DI/ points to pointer immediately
;;	    after 0-terminator of produced string
;;
;; Destr:   /AX/, /BX/, /CX/, /DX/, /DI/  
;; ---------------------------------------------------------
itoa_octal proc
	mov cx, 5H 			; [...0][000]  [000][0  00][00  0][000]

	mov bx, dx
    	and bx, mask_leading_byte

	shl dx, 1H

    	cmp bx, 0H
    	je  @@skip_zeros_start

    	mov byte ptr es:[di], '1'
    	inc di
    	
	jmp @@skip_zeros_start

@@skip_leading_zeros:
    	cmp cx, 1H
    	je @@write_to_string

	dec cx
	shl dx, 3H

@@skip_zeros_start:
    	mov bx, dx
    	and bx, mask_leading_oct

	cmp bx, 0H
	je @@skip_leading_zeros

@@write_to_string:
	mov ax, dx
	shl dx, 3H

	shr ax, shift_leading_oct
	add al, '0'

    	stosb

	loop @@write_to_string

	.terminate_string
	ret

itoa_octal endp

;; ---------------------------------------------------------
;; CDECL adapter for /itoa_octal/
;; 
;; Signature:	void itoa_octal(uint16_t  number,
;; 				uchar8_t* output_buffer) 
;; ---------------------------------------------------------
itoa_octal_cdecl proc
	push bp
    	mov bp, sp

    	push bx di

    	cld

    	mov dx, [bp + 4] 
    	mov di, [bp + 6] 
    	call itoa_octal

    	pop di bx

    	pop bp
	ret
itoa_octal_cdecl endp


;; ---------------------------------------------------------
;; Write decimal representation of a number to string
;;
;; Entry:   /DX/    -- target number
;;          /ES:DI/ -- string destination (buffer)
;;
;; Expect:  Cleared destination flag
;;
;; Note:    After execution /DI/ points to pointer immediately
;;	    after 0-terminator of produced string
;;
;; Destr:   /AX/, /BX/, /DX/, /CX/, /SI/, /DI/  
;; ---------------------------------------------------------
itoa_decimal proc
	xor cx, cx

    	mov si, dx
    	mov ax, si

    	mov bx, 10D

    	cmp dx, 0H
    	je @@write_to_string

@@count_number_length:
        inc cx

    	mov dx, 0H
        div bx

        cmp ax, 0H
	jne @@count_number_length

    	mov ax, si

    	add di, cx
    	mov si, di

    	dec di

@@write_to_string:
    	mov dx, 0H
        div bx

    	add dl, '0'

    	mov es:[di], dl
    	dec di

        cmp ax, 0H
	jne @@write_to_string

	mov di, si
	.terminate_string	
    
    	ret
itoa_decimal endp

;; ---------------------------------------------------------
;; CDECL adapter for /itoa_decimal/
;; 
;; Signature:	void itoa_decimal(uint16_t  number,
;; 				  uchar8_t* output_buffer) 
;; ---------------------------------------------------------
itoa_decimal_cdecl proc
	push bp
    	mov bp, sp

    	push si di bx

    	cld

    	mov dx, [bp + 4] 
    	mov di, [bp + 6] 
    	call itoa_decimal

    	pop bx di si

    	pop bp
	ret
itoa_decimal_cdecl endp


;; ---------------------------------------------------------
;; Parses number from its decimal representation in a string.
;; 
;; Entry:  /SI/ -- string with number
;; 
;; Expect: Cleared destination flag
;; 
;; Return: /DX/ -- parsed number
;; 
;; Destr:  /AX/, /DI/, /SI/
;; ---------------------------------------------------------
atoi_decimal proc
    	xor dx, dx

@@next_symbol:    
	lodsb

    	cmp ax, 0H
    	je @@end_of_string

	imul dx, 10D

    	sub ax, '0'
    	add dx, ax

    	jmp @@next_symbol

@@end_of_string:	
    	ret
atoi_decimal endp

;; ---------------------------------------------------------
;; CDECL adapter for /atoi_decimal/
;; 
;; Signature:	uint16_t atoi_decimal(uchar8_t* src) 
;; ---------------------------------------------------------
atoi_decimal_cdecl proc
	push bp
    	mov bp, sp

    	push si

	cld
    
    	mov si, [bp + 4] 
    	call atoi_decimal

    	pop si
    	mov ax, dx

    	pop bp
	ret
atoi_decimal_cdecl endp
