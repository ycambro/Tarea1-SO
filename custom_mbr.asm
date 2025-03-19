[BITS 16]
[ORG 0x7C00]  ; MBR se carga en 0x7C00

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00  ; Configurar pila

    ; Mostrar mensaje de carga (opcional)
    mov si, load_msg
    call print_string

    ; Leer mrpv.bin desde el sector 1
    mov bx, 0x7E00   ; Cargar en 0x7E00
    mov dh, 1        ; Leer 1 sector
    call disk_load

    ; Saltar a ejecutar mrpv.bin
    jmp 0x0000:0x7E00

; ----------------------------
; Función para imprimir string
; ----------------------------
print_string:
    lodsb          ; Cargar siguiente byte en AL
    or al, al      ; ¿Es fin de cadena?
    jz done_print
    mov ah, 0x0E   ; Función de impresión de BIOS
    int 0x10       ; Imprimir carácter en AL
    jmp print_string

done_print:
    ret

; ----------------------------
; Función para leer del disco
; ----------------------------
disk_load:
    mov ah, 0x02   ; Función de lectura de BIOS
    mov al, dh     ; Número de sectores a leer
    mov ch, 0x00   ; Cilindro 0
    mov dh, 0x00   ; Cabeza 0
    mov cl, 0x02   ; Sector 2 (mrpv.bin está aquí)
    int 0x13       ; Llamar a la BIOS
    jc disk_error  ; Si falla, error
    ret

disk_error:
    mov si, error_msg
    call print_string
    hlt  ; Detener CPU

load_msg db 'Cargando MRPV...', 0
error_msg db 'Error de lectura!', 0

    times 510-($-$$) db 0  ; Rellenar hasta 510 bytes
    dw 0xAA55  ; Firma del MBR
