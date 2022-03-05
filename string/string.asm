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
;; Destr:  SI, DI, AL
;; ---------------------------------------------------------
strcmp proc
compare_symbols:	
    cmpsb
    ja string1_is_bigger
    jb string2_is_bigger

    cmp byte ptr ds:[si-1], 0H
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
;; Destr:  SI, DI
;; ---------------------------------------------------------
strcpy proc
write_string:	
    movsb

    cmp byte ptr ds:[si-1], 0
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
;; Destr:  AL, CX
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
;; 	  BX -- alignment
;; 	  DL -- alignment char
;; 
;; Destr: AH, BX, DX, CX
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
;; Mask number's leading byte
;; 
;; Entry: load_to   -- reg16/mem16 where to load masked result
;;        load_from -- reg16/mem16/imm16 target number
;; 
;; Destr: /load_to/
;; ---------------------------------------------------------
mask_leading_byte		equ 	08000H
mask_leading_oct		equ 	0E000H
mask_leading_hex		equ 	0F000H

shift_leading_byte		equ 	0FH
shift_leading_oct		equ 	0DH
shift_leading_hex		equ 	0CH
    
;; ---------------------------------------------------------
;; Insert 0-terminator
;;
;; Entry:   DX -- target number
;;          DI -- string destination (buffer)
;;
;; Expects: Cleared Destination Flag
;;
;; Note:    After execution /DI/ points to pointer immediately
;;	    after 0-terminator of produced string
;;
;; Destr:   AX, DX, CX, DI  
;; ---------------------------------------------------------
.terminate_string macro
    mov byte ptr es:[di], 0
    inc di
endm

;; ---------------------------------------------------------
;; Write binary representation of a number to string
;;
;; Entry:   DX -- target number
;;          DI -- string destination (buffer)
;;
;; Expects: Cleared Destination Flag
;;
;; Note:    After execution /DI/ points to pointer immediately
;;	    after 0-terminator of produced string
;;
;; Destr:   AX, DX, CX, DI  
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
;; Write hex representation of a number to string
;;
;; Entry:   DX -- target number
;;          DI -- string destination (buffer)
;;
;; Expects: Cleared Destination Flag
;;
;; Note:    After execution /DI/ points to pointer immediately
;;	    after 0-terminator of produced string
;;
;; Destr:   AX, DX, CX, DI  
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
;; Write octal representation of a number to string
;;
;; Entry:   DX -- target number
;;          DI -- string destination (buffer)
;;
;; Expects: Cleared Destination Flag
;;
;; Note:    After execution /DI/ points to pointer immediately
;;	    after 0-terminator of produced string
;;
;; Destr:   AX, DX, CX, DI  
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
;; Write decimal representation of a number to string
;;
;; Entry:   DX -- target number
;;          DI -- string destination (buffer)
;;
;; Expects: Cleared destination flag
;;
;; Note:    After execution /DI/ points to pointer immediately
;;	    after 0-terminator of produced string
;;
;; Destr:   AX, DX, CX, DI  
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
;; Parses number from its decimal representation in a string.
;; 
;; Entry:   SI -- string with number
;; 
;; Expects: Cleared destination flag
;; 
;; Returns: DX -- parsed number
;; 
;; Destr:   AX
;; ---------------------------------------------------------
atoi_decimal proc
    	xor dx, dx

@@next_symbol:    
	lodsb

    	cmp ax, 0H
    	je @@exit

	imul dx, 10D

    	sub ax, '0'
    	add dx, ax

    	jmp @@next_symbol

@@exit:	
    	ret
atoi_decimal endp

;; ---------------------------------------------------------
;; See /atoi_decimal/, with stack frame
;; ---------------------------------------------------------
atoi_decimal_stack proc
	push bp
    	mov bp, sp

    	mov si, [bp - 4] 
    	call atoi_decimal

    	pop bp
	ret
atoi_decimal_stack endp
