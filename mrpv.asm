BITS 16
ORG 0x7C00 ; Dirección donde es cargado el programa

start:
    ; Mostrar mensaje de inicio
    mov si, mensaje_bienvenida
    call print_string
    mov bx, 0               ; Iniciar puntaje

nuevo_juego:
    call generar_cadena_aleatoria
    mov si, buffer_aleatorio
    call print_string
    mov si, buffer_aleatorio
    call obtener_respuesta_letra_por_letra

; ======================
; Funciones auxiliares
; ======================
print_string:
    mov ah, 0x0E        ; Interrupción para imprimir caracteres
.loop:
    lodsb               ; Carga el siguiente carácter de SI en AL
    or al, al           ; Verifica si es el final de la cadena
    jz .done
    int 0x10            ; Llama a la BIOS para imprimir
    jmp .loop
.done:
    call salto_linea
    ret

salto_linea:
    mov ah, 0x0E                ; Función de la BIOS para imprimir caracteres
    mov al, 0x0D                ; Retorno de carro
    int 0x10                    ; Llama a la BIOS
    mov al, 0x0A                ; Salto de línea
    int 0x10                    ; Llama a la BIOS
    ret

; ======================
; Funciones principales
; ======================
generar_cadena_aleatoria:
    mov cx, 4                  ; Número de caracteres en la cadena
    mov di, buffer_aleatorio   ; Dirección del buffer de la cadena
.loop_aleatorio:
    ; Leer PIT
    mov al, 0                  ; Canal 0 del PIT
    out 0x43, al               ; Lee el contador
    in al, 0x40                ; Lee el byte menos significativo del contador
    mov ah, 0                  ; Limpia AH para obtener un valor de 16 bits en AX
    mov dx, ax

    ; Leer segundos desde RTC (CMOS puerto 0x70 / 0x71)
    mov al, 0x00                ; Segundos
    out 0x70, al                ; Selecciona el registro de segundos
    in al, 0x71                 ; Lee el valor de los segundos
    xor dx, ax                  ; Combinarlo con el PIT para más ruido

    and dx, 25                  ; Limita a 26 caracteres (A-Z)
    add dl, 'A'                 ; Convertir a caracteres 'A'-'Z'
    mov [di], dl                ; Guarda la letra en el buffer
    inc di                      ; Avanza al siguiente byte del buffer

    call delay_pequeno

    loop .loop_aleatorio        ; Repetir hasta completar la cadena
    mov byte [di], 0            ; Terminar la cadena con un byte nulo (final de cadena)
    ret

delay_pequeno:                  ; Delay breve para generar ruido
    push cx
    mov cx, 0xFFFF              ; Valor de retraso
.wait:
    loop .wait                  ; Bucle para generar retraso
    pop cx
    ret

obtener_respuesta_letra_por_letra:
    push si
    push bx
.loop:
    pop bx
    pop si
    lodsb
    push si
    push bx
    cmp al, 0                   ; Verifica si es el final de la cadena
    je mostrar_puntaje

.asociar_letra:
    sub al, 'A'                 ; Convierte la letra en un índice (0-25)
    movzx ax, al                ; Extiende el byte a una palabra
    mov bx, ax                  ; Guarda el índice en BX
    lea si, [cadenas]           ; Carga la dirección de la tabla de cadenas
    xor cx, cx                  ; Inicializa el contador de cadenas
    xor dx, dx                  ; Inicializa el contador de longitud
    mov di, si                  ; Guarda la dirección de la tabla de cadenas en DI

.buscar_palabra:
    mov al, [di]                ; Carga el carácter actual de la tabla de cadenas
    xor dx, dx                  ; Reinicia el contador de longitud

.contar_longitud:
    cmp al, 0                   ; Verifica si es el final de la cadena
    je .longitud_contada
    inc di                      ; Avanza al siguiente carácter
    inc dx                      ; Incrementa el contador de longitud
    mov al, [di]                ; Carga el siguiente carácter
    jmp .contar_longitud

.longitud_contada:
    inc di                      ; Avanza al siguiente byte
    cmp cx, bx                  ; Compara el índice de la cadena con el índice de la letra
    je .encontrada              ; Si son iguales, encontramos la palabra
    inc cx                      ; Avanza al siguiente índice
    jmp .buscar_palabra         ; Continúa buscando

.encontrada:
    sub di, dx                  ; Retrocede la longitud de la palabra para apuntar a esta
    dec di                      ; Retrocede un byte mas para leer toda la palabra desde la primera letra
    push di                     ; Guarda la dirección de la palabra en la pila para luego comparar
    jmp .esperar_entrada

.esperar_entrada:
    mov di, buffer_usuario      ; Apunta al inicio del buffer del usuario
.loop_entrada:
    mov ah, 0x00                ; Función para leer un carácter
    int 0x16                    ; Lee un carácter
    cmp al, 13                  ; Verifica si es Enter (fin de la entrada)
    je .finalizar_entrada
    mov [di], al                ; Guarda el carácter en el buffer
    inc di                      ; Avanza al siguiente byte
    mov ah, 0x0E                ; Función de la BIOS para imprimir caracteres
    int 0x10                    ; Llama a la BIOS para imprimir
    jmp .loop_entrada           ; Continúa leyendo la entrada

.finalizar_entrada:
    mov byte [di], 0            ; Termina la cadena con un byte nulo
    mov si, buffer_usuario      ; Carga la dirección del buffer del usuario
    pop di                      ; Carga la dirección de la palabra esperada
    call salto_linea
    jmp .loop_comparar    
      
.loop_comparar:
    mov al, [si]                ; Carga el carácter actual del buffer del usuario   
    mov dl, [di]                ; Carga el carácter actual de la palabra asociada
    cmp al, dl                  ; Compara los caracteres
    jne .incorrecto
    cmp al, 0                   ; Verifica si es el final de la cadena
    je .correcto
    inc si
    inc di
    jmp .loop_comparar

.incorrecto:
    mov si, mensaje_incorrecto
    call print_string
    jmp .loop

.correcto:
    pop bx                      ; Recupera el puntaje    
    inc bx                      ; Incrementa el puntaje
    push bx                     ; Guarda el puntaje
    mov si, mensaje_correcto
    call print_string
    jmp .loop

mostrar_puntaje:
    mov si, mensaje_puntaje
    call print_string
    pop bx                      ; Recupera el puntaje
    pop si                      ; Saca la dirección de la cadena aleatoria
    mov ax, bx

    cmp ax, 10                  ; Comprueba si el puntaje es menor a 10
    jl .menor_a_diez

    ;Imprime el numero de decenas
    mov dx, 0                   ; Dividendo
    mov cx, 10                  ; Divisor
    div cx                      ; Divide AX por CX
    add ax, '0'                 ; Convierte el resultado en un carácter
    mov ah, 0x0E                ; Función de la BIOS para imprimir caracteres
    int 0x10                    ; Llama a la BIOS para imprimir

    ;Imprime el numero de unidades
    mov ax, dx                  ; Mueve el resultado de la división a AX

.menor_a_diez:
    add ax, '0'                 ; Convierte el resultado en un carácter
    mov ah, 0x0E                ; Función de la BIOS para imprimir caracteres
    int 0x10                    ; Llama a la BIOS para imprimir
    call salto_linea
    call salto_linea
    jmp nuevo_juego             ; Vuelve a empezar el juego

; ======================
; Data section
; ======================

mensaje_bienvenida db "Bienvenido a MRPV! ", 0
mensaje_correcto db "Correcto, +1 punto", 0
mensaje_incorrecto db "Incorrecto", 0
mensaje_puntaje db "Pts: ", 0

buffer_usuario times 10 db 0
buffer_aleatorio times 5 db 0

cadenas:
    db "Alfa", 0, "Bravo", 0, "Charlie", 0, "Delta", 0, "Echo", 0, "Foxtrot", 0
    db "Golf", 0, "Hotel", 0, "India", 0, "Juliett", 0, "Kilo", 0, "Lima", 0
    db "Mike", 0, "November", 0, "Oscar", 0, "Papa", 0, "Quebec", 0
    db "Romeo", 0, "Sierra", 0, "Tango", 0, "Uniform", 0, "Victor", 0
    db "Whiskey", 0, "X-ray", 0, "Yankee", 0, "Zulu", 0

; ======================
; Boot sector padding
; ======================
times 510-($-$$) db 0
dw 0xAA55
