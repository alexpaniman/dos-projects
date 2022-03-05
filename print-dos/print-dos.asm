model tiny
.code

org 100H

;; ---- DOS Services Nums ---- 
sys_exit			equ 	00H
sys_getchar			equ 	01H
sys_get_interrupts_address	equ 	31H

dos_services     		equ	21H

;; Video segment location:
videoseg         		equ	0B800H

;; Successful exit code:
success	    	 		equ	00H

.program_exit macro error_code
    mov ah, &sys_exit
    mov al, &error_code
    int dos_services
endm    

.getchar macro error_code
    mov ah, &sys_getchar
    int dos_services
endm    

start:	
    mov dx, videoseg		; ES = VIDEOSEG
    mov es, dx

    mov di, 0			; Begining of the screen

    mov cx, 80 * 25 * 2		; Number of screen cells

    mov dx, 0H			; DS = int table segment
    mov ds, dx

    mov si, dos_services * 4	; SI = dos services offset

    lodsw			; Load DOS offset in BX
    mov bx, ax			; Can't load to SI directly,
				; because it's used by lodsw

    lodsw			; Load DOS segment in DS
    mov ds, ax
    mov si, bx			; Load DOS offset  in SI

dos_memory: 
    lodsw
    stosw
    loop dos_memory

    .getchar
    .program_exit success

end start
