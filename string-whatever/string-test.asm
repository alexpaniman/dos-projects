model tiny
.code

.186				; Enable 80186 processor instructions
    
org 100H

include stdlib.asm

start:
    .print_literal 'Testing itoa: '
    .print_new_line

    lea si, tests_table
    lea di, itoa_test
    lea dx, itoa_print_test_name

    call iterate_tests

    .exit_program success

itoa_test proc
    mov word ptr dx, [si]
    add si, 2

    push si

    lea di, @@message

    call itoa_hex

    lea di, @@message
    pop si

    call strcmp
    ret

.data
@@message db 16 dup (' ')
itoa_test endp

;; ------------------------------------------------------------
;; Prints itoa's test entry name.
;;
;; Entry:  /SI/ -- Pointer to test itoa test entry
;;
;; Side Effects: Prints test name 
;;
;; ------------------------------------------------------------
itoa_print_test_name proc
    add si, 2
    call print_string
    .print_literal ': '
    ret
itoa_print_test_name endp

;; ------------------------------------------------------------
;; Execute tests loaded from test table
;; 
;; Entry: /SI/ -- Pointer to test table, in format:
;;  			1: 1st test entry bytes
;;  			2: 2nd test entry bytes
;;  		      ...: ... more entries ...
;;  			N: nth test entry bytes
;; 		      N+1: 0 byte that signifies end of table
;;                          
;;                Entries shouldn't necessarily be the same
;;   		  size, what matters is that entry is skipped
;;                after function invokation, and /SI/ points
;; 		  to the next one (or to 0) in case it was the
;; 		  last entry in the table.
;; 
;;        /DI/ -- Function that performes test, when called
;; 		  /SI/ will point to current test entry, and
;; 		  after return, it should point to the next one.
;; 
;;        /DX/ -- Function that prints test number without new
;;                line, when called /SI/ will point to current
;;		  test entry, and after return.
;; 
;; 		  Note: function can freely modifiy value in /SI/
;; 
;; Destr: 
;; ------------------------------------------------------------
iterate_tests proc
@@next_test_in_test_table:
    push si dx di
    call itoa_print_test_name
    pop di dx si

    xor ax, ax

    push dx di

    call di
    cmp al, 0H

    call print_status

    pop di dx

    cmp byte ptr [si], 0
    jne @@next_test_in_test_table

    ret
iterate_tests endp
	

include testlib.asm    
include  string.asm

.data
output_number	db 16 dup(' '), '$'

.test_number macro number, output_string
    dw &number
    db &output_string, 0
endm    

.end_of_table macro number, output_string
    db '0'
endm    
    
tests_table:	
    .test_number 07ADAH, '7ADA'
    .test_number 0ABCDH, 'ABCD'
    .test_number 01234H, '1234'
    .test_number  0234H,  '234'
    .test_number  0E34H,  'E34'
    .test_number  0FEFH,  'FEF'
    .test_number  0DEDH,  'DED'
    .test_number   017H,   '17'
    .test_number   010H,   '10'
    .test_number    0H,     '0'
    .end_of_table

end start
