BITS 16
ORG 0x1000          ; Dirección donde fue cargado el programa

start:
    mov si, mensaje_bienvenida
    call print_string
    mov bx, 0               ; Iniciar puntaje

nuevo_juego:
    call generar_cadena_aleatoria
    mov si, buffer_aleatorio
    call print_string
    mov si, buffer_aleatorio
    call obtener_respuesta_letra_por_letra

print_string:
    mov ah, 0x0E        ; Función de interrupción para imprimir caracteres
    
.loop:
    lodsb               ; Cargar siguiente carácter en AL
    or al, al           ; Verificar si es el fin de la cadena
    jz .done
    int 0x10            ; Llamar a la BIOS para imprimir
    jmp .loop

.done:
    call salto_linea
    ret

generar_cadena_aleatoria:
    mov cx, 4                 ; Longitud de la cadena aleatoria
    mov di, buffer_aleatorio   ; Apuntar al buffer donde guardaremos la cadena

.loop_aleatorio:
    ; Leer el contador de tiempo del PIT
    mov al, 0                 ; Canal 0 del PIT
    out 0x43, al              ; Enviar comando para leer el contador
    in al, 0x40               ; Leer el byte menos significativo del contador
    mov ah, 0                 ; Limpiar AH para obtener un valor de 16 bits en AX

    ; Usar el valor del PIT como semilla para generar una letra aleatoria
    mov dx, ax                ; Copiar el valor de AX en DX
    and dx, 25                ; Limitar el valor entre 0 y 25 (26 letras en total)
    add dl, 'A'               ; Convertir en letra (A = 65)

    mov [di], dl              ; Guardar la letra en el buffer
    inc di                    ; Mover el puntero al siguiente espacio
    loop .loop_aleatorio      ; Repetir hasta completar la cadena

    mov byte [di], 0          ; Terminar la cadena con un null ('\0')
    ret

salto_linea:
    mov ah, 0x0E            ; Función de BIOS para imprimir caracteres
    mov al, 0x0D            ; Retorno de carro (CR)
    int 0x10
    mov al, 0x0A            ; Salto de línea (LF)
    int 0x10
    ret

; Cadenas de texto concatenadas en un solo bloque
cadenas:
    db "Alfa", 0       ; Para 'A'
    db "Bravo", 0      ; Para 'B'
    db "Charlie", 0    ; Para 'C'
    db "Delta", 0      ; Para 'D'
    db "Echo", 0       ; Para 'E'
    db "Foxtrot", 0    ; Para 'F'
    db "Golf", 0       ; Para 'G'
    db "Hotel", 0      ; Para 'H'
    db "India", 0      ; Para 'I'
    db "Juliett", 0    ; Para 'J'
    db "Kilo", 0       ; Para 'K'
    db "Lima", 0       ; Para 'L'
    db "Mike", 0       ; Para 'M'
    db "November", 0   ; Para 'N'
    db "Oscar", 0      ; Para 'O'
    db "Papa", 0       ; Para 'P'
    db "Quebec", 0     ; Para 'Q'
    db "Romeo", 0      ; Para 'R'
    db "Sierra", 0     ; Para 'S'
    db "Tango", 0      ; Para 'T'
    db "Uniform", 0    ; Para 'U'
    db "Victor", 0     ; Para 'V'
    db "Whiskey", 0    ; Para 'W'
    db "X-ray", 0      ; Para 'X'
    db "Yankee", 0     ; Para 'Y'
    db "Zulu", 0       ; Para 'Z'

obtener_respuesta_letra_por_letra:
    ;mov si, cadena_prueba   ; Apuntar a la palabra que se debe deletrear
    push si                 ; Guardar la dirección de la palabra en la pila
    push bx

.loop:
    pop bx
    pop si                  ; Cargar la dirección de la palabra en SI
    lodsb                   ; Cargar la letra esperada en AL (SI ya apunta a la palabra)
    push si                 ; Guardar la dirección actual de la palabra en la pila
    push bx
    cmp al, 0
    je mostrar_puntaje

.asociar_letra:
    sub al, 'A'          ; Convertir la letra a un índice numérico
    movzx ax, al         ; Usamos 'AL' (letra) como índice
    mov bx, ax           ; Copiamos 'AL' a 'BX' para calcular el desplazamiento
    lea si, [cadenas]    ; Apuntar al inicio de las cadenas

    ; Ahora iteramos para encontrar la palabra correspondiente a la letra
    xor cx, cx           ; Reiniciamos cx, lo usamos para contar la longitud de las cadenas
    xor dx, dx           ; Usamos dx para el desplazamiento de las palabras
    mov di, si            ; Apuntar a la posición actual de la cadena

.buscar_palabra:
    ; Calcular la longitud de la cadena actual, que termina en un 0
    mov al, [di]         ; Cargar el primer carácter de la cadena
    xor dx, dx           ; Reiniciar dx (longitud de la palabra)

.contar_longitud:
    cmp al, 0            ; Si encontramos el byte nulo (fin de la cadena)
    je .longitud_contada
    inc di               ; Avanzar al siguiente carácter
    inc dx               ; Aumentar la longitud de la palabra
    mov al, [di]         ; Cargar el siguiente carácter
    jmp .contar_longitud

.longitud_contada:
    inc di
    cmp cx, bx           ; Si cx (el índice de palabra actual) coincide con bx (letra), encontramos la palabra
    je .encontrada
    inc cx               ; Avanzamos al siguiente índice
    jmp .buscar_palabra

.encontrada:
    sub di, dx
    dec di
    push di
    jmp .esperar_entrada

.esperar_entrada:
    ; Leer palabra completa del usuario
    mov di, buffer_usuario  ; Apuntar al inicio del buffer del usuario

.loop_entrada:
    mov ah, 0x00            ; Función para leer un carácter
    int 0x16                ; Leer un carácter
    cmp al, 13              ; Comprobar si es Enter (fin de la entrada)
    je .finalizar_entrada   ; Si es Enter, salir de la entrada

    mov [di], al            ; Guardar el carácter ingresado en el buffer
    inc di

    mov ah, 0x0E
    int 0x10                ; Imprimir el carácter mientras se escribe
    jmp .loop_entrada

.finalizar_entrada:
    mov byte [di], 0        ; Agregar un byte nulo al final de la cadena
    mov si, buffer_usuario  ; Apuntar al inicio del buffer del usuario
    pop di
    call salto_linea
    jmp .loop_comparar

.loop_comparar:
    mov al, [si]             ; Cargar un carácter del buffer del usuario
    mov dl, [di]             ; Cargar un carácter de la palabra asociada
    cmp al, dl               ; Comparar los caracteres
    jne .incorrecto          ; Si son diferentes, ir a incorrecto

    ; Verificar si llegamos al final de la palabra
    cmp al, 0                ; Si encontramos un byte nulo (fin de cadena)
    je .correcto             ; Si coinciden, y llegamos al final, es correcto

    inc si                   ; Avanzar al siguiente carácter del buffer
    inc di                   ; Avanzar al siguiente carácter de la palabra
    jmp .loop_comparar       ; Continuar comparando

.incorrecto:
    ; Aquí va el código para manejar el caso incorrecto
    ; Ejemplo: mostrar un mensaje de error
    mov si, mensaje_incorrecto
    call print_string
    jmp .loop

.correcto:
    pop bx
    inc bx                  ; Incrementar el puntaje
    push bx
    mov si, mensaje_correcto
    call print_string
    jmp .loop

mostrar_puntaje:
    mov si, mensaje_puntaje
    call print_string

    pop bx
    pop si

    ; Convertir y mostrar la puntuación numérica
    mov ax, bx              ; Copiar puntaje a AX
    add ax, '0'             ; Convertir a carácter ASCII
    mov ah, 0x0E
    int 0x10                ; Imprimir puntaje

    call salto_linea
    call salto_linea

    jmp nuevo_juego

section .data
    mensaje_correcto db "Correcto, +1 punto", 0
    mensaje_incorrecto db "Incorrecto", 0
    mensaje_bienvenida db "Bienvenido al juego foneticoa!", 0
    mensaje_puntaje db "Pts: ", 0

    buffer_usuario times 10 db 0  ; Almacena la respuesta del usuario
    buffer_aleatorio times 4 db 0 ; Almacena la cadena aleatoria