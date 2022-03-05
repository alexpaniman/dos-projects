    mov dx, 0B800H
    mov es, dx

    mov di, 0

    mov cx, 80*25

    mov dx, 0H
    mov ds, dx

    add si, 0H

zaloop:	
    mov ax, ds:[si]
    stosw
    loop zaloop

    exit success
