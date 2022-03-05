model tiny
.code
.186				; Enable 80186 processor instructions
    
org 100H

start:
    jmp entry

include  stdlib.asm
include testlib.asm    
include  string.asm

.test_itoa macro test_table, itoa_function, number
    .println_literal 'Testing &itoa_function: '

    .load_string_literal_$_terminated di, '&number'
    mov [current_itoa_number_str], di

    lea di, itoa_function
    mov [current_itoa_function], di

    .run_tests &test_table, itoa_test, itoa_print_test_name

    .print_new_line
endm

entry:	
    lea si, mmm
    push si
    call atoi_decimal_stack
    ;; call unit_test_itoa

    .exit_program success
mmm db '1234', 0

unit_test_itoa proc    
    .test_itoa itoa16_test_table,     itoa_hex, 16
    .test_itoa itoa02_test_table,  itoa_binary, 02
    .test_itoa itoa08_test_table,   itoa_octal, 08
    .test_itoa itoa10_test_table, itoa_decimal, 10
    ret
unit_test_itoa endp

test_atoi proc
    lea si, message
    call atoi_decimal

    lea di, space
    call itoa_decimal

    lea si, space
    mov bx, 0H
    call print_string

    ret

message db '1234', 0 
space 	db 16 dup(0)
test_atoi endp

itoa_test proc
    mov word ptr dx, [si]
    add si, 2

    push si

    lea di, @@message

    mov bx, [current_itoa_function]
    call bx

    lea di, @@message
    pop si

    call strcmp
    ret

@@message	db 64 dup (' ')
itoa_test endp

current_itoa_function		dw 0	; <== This will be changed after each block of tests 

;; ------------------------------------------------------------
;; Print itoa's test entry name.
;;
;; Entry: /SI/ -- Pointer to test itoa test entry
;; ------------------------------------------------------------
itoa_print_test_name proc
    add si, 2			; Skips target number in test
    .print @@indented_function_name

    mov di, [current_itoa_number_str]
    .print_addr di

    .print @@number_prelude

    mov bx, 10H			; Max register width in bytes
    mov dx, ' '
    call print_string

    .print @@number_conclude
    ret

@@indented_function_name	db '    itoa', '$'
@@number_prelude		db      '('  , '$'
@@number_conclude		db      '): ', '$'
itoa_print_test_name endp

current_itoa_number_str		dw 0	; <== This will be changed after each block of tests 

.test_number macro number, output_string
    dw &number
    db &output_string, 0
endm    

itoa16_test_table:	
    .test_number 07ADAH,             '7ADA'
    .test_number 0ABCDH,             'ABCD'
    .test_number 01234H,             '1234'
    .test_number  0234H,              '234'
    .test_number  0E34H,              'E34'
    .test_number  0FEFH,              'FEF'
    .test_number  0DEDH,              'DED'
    .test_number    17H,               '17'
    .test_number    10H,               '10'
    .test_number     0H,                '0'
    .end_of_table

itoa02_test_table:	
    .test_number 0ABCDH, '1010101111001101' 
    .test_number  7ADAH,  '111101011011010'
    .test_number  2234H,   '10001000110100'
    .test_number  1234H,    '1001000110100'
    .test_number  0FEFH,     '111111101111'
    .test_number  0DEDH,     '110111101101'
    .test_number  0E34H,     '111000110100'
    .test_number   634H,      '11000110100'
    .test_number   234H,       '1000110100'
    .test_number   195H,        '110010101'
    .test_number    95H,         '10010101'
    .test_number    57H,          '1010111'
    .test_number    37H,           '110111'
    .test_number    17H,            '10111'
    .test_number    10H,            '10000'
    .test_number     9H,             '1001'
    .test_number     6H,              '110'
    .test_number     2H,               '10'
    .test_number     0H,                '0'
    .end_of_table

itoa08_test_table:	
    .test_number 0ABCDH,           '125715' 
    .test_number  7ADAH,            '75332'
    .test_number  2234H,            '21064'
    .test_number  1234H,            '11064'
    .test_number  0FEFH,             '7757'
    .test_number  0E34H,             '7064'
    .test_number  0DEDH,             '6755'
    .test_number   634H,             '3064'
    .test_number   234H,             '1064'
    .test_number   195H,              '625'
    .test_number    95H,              '225'
    .test_number    57H,              '127'
    .test_number    37H,               '67'
    .test_number    17H,               '27'
    .test_number    10H,               '20'
    .test_number     9H,               '11'
    .test_number     6H,                '6'
    .test_number     2H,                '2'
    .test_number     0H,                '0'
    .end_of_table

itoa10_test_table:	
    .test_number 65535D,            '65535' 
    .test_number 16114D,            '16114' 
    .test_number  6114D,             '6114' 
    .test_number   420D,              '420' 
    .test_number    69D,               '69' 
    .test_number    16D,               '16' 
    .test_number     7D,                '7' 
    .test_number     0D,                '0' 
    .end_of_table

end start
