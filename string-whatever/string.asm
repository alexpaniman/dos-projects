.lodsb macro register, pointer
	mov &register, [&pointer]
	inc &pointer
endm

	
;; ---------------------------------------------------------
;; Lexicographically compares two strings
;; 
;; Entry: SI --  first string
;;        DI -- second string
;; 
;; Note:  This function expects strings in form of pointers
;;        to an array of a subsequent symbols, that end
;;        with a null-terminator symbol (With ASCII code 0)
;; 
;; Exit:  This function returns in AL:
;; 	  -> 00H if strings are equal
;; 	  -> 01H if first string < second string
;; 	  -> 10H if first string > second string
;; 
;; Destr:  
;; ---------------------------------------------------------

strcmp proc
compare_symbols:	
    .lodsb al, si 
    .lodsb bl, di 

    cmp al, bl
    ja string1_is_bigger
    jb string2_is_bigger

    cmp al, 0H
    jne compare_symbols
    ret

string1_is_bigger:	
    mov al, 10H
    ret

string2_is_bigger:	
    mov al, 01H
    ret
strcmp endp

;; ---------------------------------------------------------
;; Copies string to another destination
;; 
;; Expect: SI -- string to copy
;;         DI -- destination address
;; 
;; Note:   This function expects strings in form of pointers
;;         to an array of a subsequent symbols, that end
;;         with a null-terminator symbol (With ASCII code 0)
;; 
;; Return: None
;; 
;; Destr:  
;; ---------------------------------------------------------
strcpy proc
write_string:	
    lodsb
    stosb

    cmp ax, 0
    jne write_string
strcpy endp
	
;; ---------------------------------------------------------
;; Calculate string length
;; 
;; Expect: SI -- string to calculate length
;; 
;; Note:   This function expects strings in form of pointers
;;         to an array of a subsequent symbols, that end
;;         with a null-terminator symbol (With ASCII code 0)
;; 
;; Return: CX
;; 
;; Destr:  AX, CX
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
;; Print 0-terminated string, 
;; 
;; Entry: SI -- target string
;; 
;; Destr: AH, BX, DX, CX
;; ---------------------------------------------------------
print_string proc
    mov di, si
    call strlen

    mov ah, 40H
    mov dx, di
    mov bx, 1H

    int dos_services
print_string endp

;; ---------------------------------------------------------
;; Mask number's leading byte
;; 
;; Entry: load_to   -- reg16/mem16 where to load masked result
;;        load_from -- reg16/mem16/imm16 target number
;; 
;; Destr: /load_to/
;; ---------------------------------------------------------
leading_byte	equ 	08000H
leading_oct	equ 	0E000H
leading_hex	equ 	0F000H
    
.load_masked macro bit_mask, load_to, load_from
    mov &load_to, &load_from
    and &load_to, &bit_mask
endm

;; ---------------------------------------------------------
;; Write binary number representation to string
;; 
;; Entry: DX -- target number
;;        DI -- string destination
;; 
;; Destr:  
;; ---------------------------------------------------------
itoa_binary proc
	mov cx, 10H
	jmp @@skip_zeros_start

@@skip_leading_zeros:
	dec cx 
	shl dx, 1H

@@skip_zeros_start:
	.load_masked leading_byte, bx, dx
	cmp bx, 0H
	je @@skip_leading_zeros

@@write_to_string:
	.load_masked leading_byte, ax, dx
	shl dx, 1H

	shr ax, 0FH
	add al, '0'

    	stosb

	loop @@write_to_string
	ret
itoa_binary endp

;; ---------------------------------------------------------
;; Write hex representation of a number to string
;; 
;; Entry: DX -- target number
;;        DI -- string destination
;; 
;; Destr: AX, BX, CX, DI, DX
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
	.load_masked leading_hex, bx, dx
	cmp bx, 0H
	je @@skip_leading_zeros

@@write_to_string:
	.load_masked leading_hex, bx, dx
	shl dx, 4H

	shr bx, 0CH
    	mov al, [offset hex_translation_table + bx]

    	stosb

	loop @@write_to_string

    	mov al, 0  		; Terminate string
	stosb

	ret

hex_translation_table:
	db '0123456789ABCDEF'
itoa_hex endp

;; ---------------------------------------------------------
;; Write octal representation of a number to string
;; 
;; Entry: DX -- target number
;;        DI -- string destination
;; 
;; Destr:  
;; ---------------------------------------------------------
itoa_octal proc
	mov cx, 5H 			; [...0][000]  [000][0  00][00  0][000]

    	.load_masked leading_byte, bx, dx
	shl dx, 1H

    	cmp bx, 0H
    	je  @@skip_zeros_start

    	mov byte ptr es:[di], '1'
    	inc di
    	
	jmp @@skip_zeros_start

@@skip_leading_zeros:
	dec cx
	shl dx, 3H

@@skip_zeros_start:
	.load_masked leading_oct, bx, dx
	cmp bx, 0H
	je @@skip_leading_zeros

@@write_to_string:
	.load_masked leading_oct, ax, dx
	shl dx, 3H

	shr ax, 0DH
	add al, '0'

    	stosb

	loop @@write_to_string
	ret
itoa_octal endp

;; ---------------------------------------------------------
;; Parses number from its binary representation in a string.
;; 
;; Expects: SI -- string with number
;; 
;; Returns: DX -- parsed number
;; 
;; Destr:  
;; ---------------------------------------------------------
;; atoi_binary proc
;;     	mov ah, dl
;;     	div
;; atoi_binary endp
