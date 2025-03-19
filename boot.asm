BITS 16                 ; Modo real de la CPU
ORG 0x7C00              ; Dirección donde se carga el bootloader

start:
    ; Mostrar mensaje de inicio
    mov si, mensaje
    call print_string

    ; Leer el programa MRPV desde la USB
    mov ah, 0x02        ; Función de interrupción para leer disco
    mov al, 1           ; Número de sectores a leer
    mov ch, 0           ; Cilindro 0
    mov cl, 2           ; Sector 2 (donde estará MRPV)
    mov dh, 0           ; Cabeza 0
    mov dl, 0x80        ; Primera unidad de disco (USB o HDD)
    mov bx, 0x1000      ; Dirección de memoria donde cargar MRPV
    int 0x13            ; Llamar a la BIOS para leer

    ; Verificar si hubo error
    jc error_halt

    ; Saltar a la ejecución del programa MRPV
    jmp 0x1000

error_halt:
    hlt                 ; Detener el CPU en caso de error

print_string:
    mov ah, 0x0E        ; Función de interrupción para imprimir caracteres
.loop:
    lodsb               ; Cargar siguiente carácter en AL
    or al, al           ; Verificar si es el fin de la cadena
    jz .done
    int 0x10            ; Llamar a la BIOS para imprimir
    jmp .loop
.done:
    ret

mensaje db "Cargando MRPV...", 0

times 510-($-$$) db 0   ; Rellenar con ceros hasta 510 bytes
dw 0xAA55               ; Firma de arranque (MBR)
