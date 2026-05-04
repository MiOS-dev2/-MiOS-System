[org 0x7c00]
[bits 16]

KERNEL_OFFSET equ 0x1000

start:

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    

    mov [boot_drive], dl
    

    mov ax, 0x0003
    int 0x10
    
    mov si, msg_bootmgr
    call print_string

menu_wait:
    mov ah, 0x00
    int 0x16
    cmp al, '1'
    je do_reboot
    cmp al, '2'
    je do_boot
    mov si, msg_invalid
    call print_string
    jmp menu_wait

do_reboot:
    mov si, msg_reboot
    call print_string
    xor ah, ah
    int 0x16
    int 0x19              

do_boot:
    mov si, msg_loading
    call print_string
    

    call load_kernel
    jc disk_error
    

    mov dl, [boot_drive]  ; Передаем номер диска
    jmp 0x0000:KERNEL_OFFSET

disk_error:
    mov si, msg_load_error
    call print_string
    xor ah, ah
    int 0x16
    int 0x19              

load_kernel:
    pusha
    

    mov ax, 0x0000
    mov es, ax
    mov bx, KERNEL_OFFSET
    

    mov ah, 0x02
    mov al, 16
    mov ch, 0             
    mov cl, 2             
    mov dh, 0             
    mov dl, [boot_drive]  
    
    int 0x13
    jc .error
    
    cmp al, 16
    jne .error
    
    popa
    clc
    ret
    
.error:
    popa
    stc
    ret

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    jmp print_string
.done:
    ret

boot_drive db 0

msg_bootmgr  db 13,10,'=== MiOS Boot MGR ===',13,10
             db '1 - Reboot',13,10
             db '2 - Boot',13,10
             db 'Choice: ',0
msg_invalid  db 13,10,'Invalid choice!',13,10,0
msg_reboot   db 13,10,'Rebooting...',13,10,0
msg_loading  db 13,10,'Loading kernel...',13,10,0
msg_load_error db 13,10,'Disk error! Rebooting...',13,10,0

times 510-($-$$) db 0
dw 0xAA55