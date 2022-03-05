model tiny
.code

org 100H

;; ---- DOS Services Nums ---- 
sys_write_char   equ	02H
sys_exit 	 equ 	00H
dos_services     equ	21H

;; Successful exit code:
success	    	 equ	00H

;; ----- Box Dimensions ------
box_width	 equ	20
box_height	 equ	6

print_char macro symbol
    mov ah, sys_write_char
    mov dl, &symbol
    int dos_services
endm

print_newline macro
    ;; Carret return '\r'
    print_char 0DH

    ;; New line character '\n'
    print_char 0AH
endm

print_horizontal_filler macro fill, length
local @@loop_name
    mov cx, length
@@loop_name:	
    print_char &fill
    loop @@loop_name
endm

print_line macro left, mid, right
    print_char &left
    print_horizontal_filler &mid, box_width
    print_char &right
    print_newline
endm    

print_body macro left, fill, right
    ;; /cx/ is already used by fillers
    xor si, si

box_body:
    print_line &left, &fill, &right

    inc si 
    cmp si, box_height
    jle box_body
endm    

exit macro error_code
    mov ah, &sys_exit
    mov al, &error_code
    int dos_services
endm    

;; --- Program Entry Point --- 
start:
    ;; Following magic numbers are ASCII
    ;; representation of pseudographics
    ;; symbols, used to draw box:

    print_line 218, 196, 191
    print_body 179, ' ', 179
    print_line 192, 196, 217

    exit success
end start
