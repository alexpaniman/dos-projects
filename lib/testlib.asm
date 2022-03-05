;; ------------------------------------------------------------
;; Prints status of the last comparison:
;; 	Prints 'success' to stdout if equal (ZF == ZR == 1)
;; 	Prints 'failure' otherwise
;; 
;; Entry: Status of the last comparison (ZF & ZR)
;; 
;; Destr: /AH/ /DX/
;; ------------------------------------------------------------
print_status proc
    je successful_execution

    .println failure_string
    ret

successful_execution:	
    .println success_string
    ret

success_string	db 'success', '$'
failure_string	db 'failure', '$'
endp

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
;; Note:  After execution SI will point to the last symbol of the
;; 	  test table, which is always 0. See: .end_of_table macro
;; 
;; Destr: /AX/ /SI/ and whatever /DI/ and /DX/ destroy
;; ------------------------------------------------------------
iterate_tests proc
@@next_test_in_test_table:
    push dx di si
    call dx

    xor ax, ax

    pop si
    .peek di

    call di
    cmp al, 0H

    call print_status

    pop di dx

    cmp byte ptr [si], '$'
    jne @@next_test_in_test_table

    ret
iterate_tests endp

;; ------------------------------------------------------------
;; Run tests via /iterate_tests/
;; 
;; Destr: /DI/ /DX/ and everything from /iterate_tests/ 
;; ------------------------------------------------------------
.run_tests macro table_with_tests, tester, test_name_printer
    lea si, &table_with_tests
    lea di, &tester
    lea dx, &test_name_printer

    call iterate_tests
endm

;; ------------------------------------------------------------
;; Insert symbol (0) that signifies end of table at the point
;; 
;; Destr: None
;; ------------------------------------------------------------
.end_of_table macro number, output_string
    db '$'
endm    
