model tiny
.code

org 100H

include stdlib.asm

.makeline macro symbols 	
    mov si, offset &symbols
    mov cx, frame_width - 2

    call draw_line
endm

.nextline macro symbols 	
    add di, (80 - frame_width) * 2
    .makeline &symbols
endm

;; ------ Box Constants ------
columns_count 	 equ	80

frame_width 	 equ	40
frame_height 	 equ	5

frame_y 	 equ	4
frame_x 	 equ	20

;; Color bytes:
yellow_on_red	 equ	4EH

;; --- Program Entry Point --- 
start:
    mov dx, videoseg 		 	; Needed to access video memory
    mov es, dx				; from the next_line function

    mov ax, columns_count	        ; Define initial frame position
    mov dx, frame_y
    mul dx	        
    add ax, frame_x
    add ax, ax
    mov di, ax

    mov ah, yellow_on_red		; Setup color of the frame:

    .makeline horizontal_top_symbols 	; ==> Draw topmost line

    mov dx, frame_height - 2		; Number of lines - top and bot
					; Loop while (dx --> 0):
next_line:				; ---------------------------+
    .nextline vertical_symbols 		; ==> Draw mid line in loop  | 
    .looper dx, next_line		; -------- Loop step --------+

    .nextline horizontal_bottom_symbols ; ==> Draw bottommost line

    .getchar			        ; Wait for user input, so he
    .program_exit success		; can see this beautiful frame

;; ------------------------------------------------------
;; Draws a line that starts with a si[0], continues cx
;; times with si[1], and ends with si[2]
;;
;; Entry: AH -- color attribute of a line in this format:
;; 		[blink, r, g, b, intensity, r, g, b] 
;;		 ^ ^          ^  ^   ^   	  ^
;;	 	 | |	      |  |   |		  |
;;		 +------------+  +----------------+
;;                 background	     foreground
;;                 |                 |
;;		 flag that enables   flag that makes
;;	         color blinking      color intensive
;;
;;	  CX -- desired width of the line, it's referenced
;;		in the documentation for SI below as width
;;	  
;; 	  DI -- address of the start of a line, counting
;;              from top left corner, generaly it works so:
;;	  
;;	  	| <- x -> |
;;	     ---+----------------------------------------+
;;            ^ |         |                              |
;;            | |                                        |
;;            y |         |                              |
;;            | |                                        |
;;            v |         |                              |
;;	     ---| - - - - +--------------------------+   |
;;	  	|         ^ top left corner          |   |
;;	  	|         |    WINDOW TO BE DRAWN    |   |
;;	  	|         +--------------------------+   |
;;	  	+----------------------------------------+
;;	  
;;	        For this positioning, you should pass in DI:
;;                  ==> y * 80 + x.
;;
;;        SI -- address of array of 3 bytes, that stores 
;;		symbols used to draw a line like so:
;;	  	[left symbol, middle symbol, right symbol]
;;	  	
;;	  	Left and right symbols are printed only
;;	  	once, at the start and the end of a line.
;;	  
;;	  	Middle symbol, on contrary, gets repeated
;;	  	width - 2 times in the middle of a string.
;;                                 
;; Note:  ES == should be set to videoseg address (0B800H)
;; 
;;  ==> After execution:
;;
;; 	  CX == 0 after the execution
;;
;; 	  DI is going to point to the cell immediatly after
;; 	  the last drawn symbol of the line.
;; 
;; 	  SI will point to the array element immediatly
;; 	  after the right frame symbol.
;;	
;; 
;;	  
;; Destr: AL, CX, DI, SI
;; ------------------------------------------------------

draw_line proc   
    lodsb			; Load left symbol to /al/
    stosw			; Write it to the screen

    lodsb			; Load middle symbol to /al/
    rep stosw

    lodsb			; Load right symbol to /al/
    stosw			; Write it to the screen

    ret
draw_line endp   

;; ------ Args Constant ------
cli_argument_offset	equ	81H

parse_string proc
string_start:	
	lodsb

	cmp dx, '\"'
	jne string_start
parse_string endp	

parse_integer proc
	xor dx, dx
	mov dl, '0'

integer_start:	
	add ax, ax

	sub dl, '0'
	;; add ax, dl		

	lodsb

	cmp dl, ' '
	jne integer_start

parse_integer endp

.data
horizontal_top_symbols     db 218, 196, 191
vertical_symbols           db 179, ' ', 179
horizontal_bottom_symbols  db 192, 196, 217

end start
