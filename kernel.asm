[org 0x1000]
[bits 16]

kernel_start:

    mov [boot_drive], dl
    

    mov ax, 0x0012
    int 0x10
    

    mov ah, 0x0B
    mov bh, 0x00
    mov bl, 0x00    
    int 0x10
    
    mov ah, 0x0B
    mov bh, 0x01
    mov bl, 0x0F    
    int 0x10
    
    ; Запуск GUI
    jmp gui_main


gui_main:
    call clear_screen
    

    mov byte [menu_selected], 0
    
.draw_menu:
    call clear_screen
    

    mov si, msg_gui_title
    call print
    
    mov si, msg_gui_separator
    call print
    

    mov cx, 0
    mov si, menu_items
    
.draw_loop:
    cmp cx, 3
    je .menu_done
    

    cmp cl, [menu_selected]
    jne .not_selected
    

    mov si, msg_selected_prefix
    call print
    
    jmp .print_item
    
.not_selected:
    mov si, msg_unselected_prefix
    call print
    
.print_item:
    ; Расчет адреса строки
    push cx
    mov ax, cx
    mov bx, 30
    mul bx
    mov si, menu_items
    add si, ax
    call print
    pop cx
    
    mov si, msg_newline
    call print
    
    inc cx
    jmp .draw_loop
    
.menu_done:
    mov si, msg_newline
    call print
    mov si, msg_gui_help
    call print
    
.wait_key:
    mov ah, 0x00
    int 0x16
    
    cmp ah, 0x48    
    je .move_up
    cmp ah, 0x50    
    je .move_down
    cmp al, 0x0D    
    je .execute
    cmp al, 0x1B    
    je .draw_menu
    
    jmp .wait_key
    
.move_up:
    cmp byte [menu_selected], 0
    je .wait_key
    dec byte [menu_selected]
    jmp .draw_menu
    
.move_down:
    cmp byte [menu_selected], 2
    je .wait_key
    inc byte [menu_selected]
    jmp .draw_menu
    
.execute:
    mov al, [menu_selected]
    
    cmp al, 0
    je .run_pc_files
    cmp al, 1
    je .run_mios_about
    cmp al, 2
    je .run_shell
    
    jmp .wait_key
    
.run_pc_files:
    call run_pc_files
    jmp .draw_menu
    
.run_mios_about:
    call run_mios_about
    jmp .draw_menu
    
.run_shell:
    call run_shell_app
    jmp .draw_menu


run_pc_files:
    call clear_screen
    
    mov si, msg_esc_exit
    call print
    
    mov si, msg_newline
    call print
    mov si, msg_newline
    call print
    

    mov si, msg_dir
    call print
    

.wait_exit:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x1B
    jne .wait_exit
    
    ret


run_mios_about:
    call clear_screen
    
    mov si, msg_esc_exit
    call print
    
    mov si, msg_newline
    call print
    mov si, msg_newline
    call print
    

    mov si, msg_version
    call print
    
    mov si, msg_newline
    call print
    
    call show_sysinfo
    

.wait_exit_about:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x1B
    jne .wait_exit_about
    
    ret


run_shell_app:
    call clear_screen
    
    mov si, msg_esc_exit
    call print
    
    mov si, msg_newline
    call print
    mov si, msg_newline
    call print
    
    ; Запуск оболочки
    call shell_loop
    
    ret


shell_loop:
    mov si, msg_prompt
    call print
    

    mov di, input_buffer
    call input_string_uppercase
    

    cmp byte [input_buffer], 0
    je shell_loop
    

    cmp byte [input_buffer], 0x1B
    je shell_exit
    

    call execute_command
    
    jmp shell_loop

shell_exit:
    ret

execute_command:
    mov si, input_buffer
    

    mov di, cmd_help_str
    call strcmp_simple
    jc .do_help
    
    mov di, cmd_dir_str
    call strcmp_simple
    jc .do_dir
    
    mov di, cmd_cls_str
    call strcmp_simple
    jc .do_cls
    
    mov di, cmd_ver_str
    call strcmp_simple
    jc .do_ver
    
    mov di, cmd_info_str
    call strcmp_simple
    jc .do_info
    
    mov di, cmd_reboot_str
    call strcmp_simple
    jc .do_reboot
    
    mov di, cmd_time_str
    call strcmp_simple
    jc .do_time
    
    mov di, cmd_date_str
    call strcmp_simple
    jc .do_date
    
    mov di, cmd_edit_str
    call strcmp_simple
    jc .do_edit
    
    mov di, cmd_ascii_str
    call strcmp_simple
    jc .do_ascii
    
    mov di, cmd_calc_str
    call strcmp_simple
    jc .do_calc
    
    mov di, cmd_mem_str
    call strcmp_simple
    jc .do_mem
    
    mov di, cmd_echo_str
    call strcmp_simple
    jc .do_echo
    
    mov di, cmd_clear_str
    call strcmp_simple
    jc .do_cls
    
    mov di, cmd_ls_str
    call strcmp_simple
    jc .do_dir
    
    mov di, cmd_shutdown_str
    call strcmp_simple
    jc .do_shutdown
    
    mov di, cmd_exit_str
    call strcmp_simple
    jc shell_exit
    
    mov si, msg_unknown
    call print
    ret
    
.do_help:
    mov si, msg_help
    call print
    ret
    
.do_dir:
    mov si, msg_dir
    call print
    ret
    
.do_cls:
    call clear_screen
    ret
    
.do_ver:
    mov si, msg_version
    call print
    ret
    
.do_info:
    call show_sysinfo
    ret
    
.do_reboot:
    mov si, msg_rebooting
    call print
    mov ah, 0x00
    int 0x16
    db 0xEA
    dw 0x0000
    dw 0xFFFF
    
.do_shutdown:
    mov si, msg_shutdown
    call print
    cli
    hlt
    
.do_time:
    call show_time
    ret
    
.do_date:
    call show_date
    ret
    
.do_edit:
    call text_editor
    ret
    
.do_ascii:
    call show_ascii_table
    ret
    
.do_calc:
    call calculator
    ret
    
.do_mem:
    call show_memory
    ret
    
.do_echo:
    call echo_text
    ret


clear_screen:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x00    
    mov ch, 0
    mov cl, 0
    mov dh, 29      
    mov dl, 79      
    int 0x10
    

    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 0x10
    ret


strcmp_simple:
    push si
    push di
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    cmp al, ' '
    je .equal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
.equal:
    pop di
    pop si
    stc
    ret
.not_equal:
    pop di
    pop si
    clc
    ret


show_sysinfo:
    mov si, msg_sysinfo_header
    call print
    

    mov si, msg_cpu
    call print
    call detect_cpu
    

    mov si, msg_memory
    call print
    int 0x12
    call print_dec
    mov si, msg_kb
    call print
    

    mov si, msg_video_mode
    call print
    
    mov si, msg_newline
    call print
    ret

detect_cpu:
    push sp
    pop ax
    cmp ax, sp
    jne .is_8086
    

    pushf
    pop ax
    or ax, 0xF000
    push ax
    popf
    pushf
    pop ax
    and ax, 0xF000
    cmp ax, 0xF000
    je .is_8086
    

    mov ax, 0x7000
    push ax
    popf
    pushf
    pop ax
    and ax, 0x7000
    cmp ax, 0x7000
    je .is_286
    
    mov si, msg_cpu_386
    call print
    ret
    
.is_286:
    mov si, msg_cpu_286
    call print
    ret
    
.is_8086:
    mov si, msg_cpu_8086
    call print
    ret

show_memory:
    mov si, msg_memory_info
    call print
    
    int 0x12
    call print_dec
    mov si, msg_kb_conventional
    call print
    
    mov si, msg_newline
    call print
    ret

show_time:
    mov ah, 0x02
    int 0x1A
    jc .error
    
    mov si, msg_time_is
    call print
    
    mov al, ch
    call print_hex_byte
    mov al, ':'
    call putc
    
    mov al, cl
    call print_hex_byte
    mov al, ':'
    call putc
    
    mov al, dh
    call print_hex_byte
    
    mov si, msg_newline
    call print
    ret
    
.error:
    mov si, msg_time_error
    call print
    ret

show_date:
    mov ah, 0x04
    int 0x1A
    jc .error
    
    mov si, msg_date_is
    call print
    
    mov al, dl
    call print_hex_byte
    mov al, '/'
    call putc
    
    mov al, dh
    call print_hex_byte
    mov al, '/'
    call putc
    
    mov ax, cx
    call print_dec
    
    mov si, msg_newline
    call print
    ret
    
.error:
    mov si, msg_date_error
    call print
    ret


text_editor:
    call clear_screen
    
    mov si, msg_editor_help
    call print
    
    mov si, msg_editor_start
    call print
    
    mov di, edit_buffer
    mov word [edit_pos], 0
    mov byte [edit_cursor_x], 0
    mov byte [edit_cursor_y], 2
    
editor_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 27      
    je editor_exit
    cmp al, 0x0D    
    je editor_newline
    cmp al, 0x08    
    je editor_backspace
    
    cmp al, 0x20
    jb editor_loop
    

    cmp byte [edit_cursor_x], 78
    ja editor_loop
    cmp byte [edit_cursor_y], 28
    ja editor_loop
    

    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F    
    int 0x10
    

    mov bx, [edit_pos]
    mov [di + bx], al
    inc word [edit_pos]
    inc byte [edit_cursor_x]
    
    jmp editor_loop
    
editor_newline:
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    
    mov bx, [edit_pos]
    mov byte [di + bx], 13
    inc word [edit_pos]
    mov byte [di + bx + 1], 10
    inc word [edit_pos]
    
    mov byte [edit_cursor_x], 0
    inc byte [edit_cursor_y]
    
    jmp editor_loop
    
editor_backspace:
    cmp word [edit_pos], 0
    je editor_loop
    cmp byte [edit_cursor_x], 0
    je editor_loop
    
    dec word [edit_pos]
    dec byte [edit_cursor_x]
    
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    
    jmp editor_loop
    
editor_exit:
    mov bx, [edit_pos]
    mov byte [di + bx], 0
    
    call clear_screen
    mov si, msg_editor_saved
    call print
    

    mov si, edit_buffer
    call print
    mov si, msg_newline
    call print
    ret


show_ascii_table:
    call clear_screen
    mov si, msg_ascii_header
    call print
    
    mov cx, 0
    mov bx, 0
    
.loop:
    cmp cx, 96
    je .done
    
    push cx
    
    ; Вывод кода
    mov ax, cx
    add ax, 32
    call print_dec
    
    mov al, ':'
    call putc
    mov al, ' '
    call putc
    
    ; Вывод символа
    mov ax, cx
    add ax, 32
    call putc
    
    mov si, msg_tab
    call print
    
    pop cx
    inc cx
    inc bx
    
    cmp bx, 8
    jne .loop
    
    mov bx, 0
    mov si, msg_newline
    call print
    jmp .loop
    
.done:
    mov ah, 0x00
    int 0x16
    call clear_screen
    ret


calculator:
    mov si, msg_calc_welcome
    call print
    
calc_loop:
    mov si, msg_calc_prompt
    call print
    

    call input_number
    push ax
    

    mov ah, 0x00
    int 0x16
    mov bl, al
    mov ah, 0x0E
    int 0x10
    

    call input_number
    
    pop bx
    
    cmp bl, '+'
    je .add
    cmp bl, '-'
    je .sub
    cmp bl, '*'
    je .mul
    cmp bl, '/'
    je .div
    
    jmp calc_loop
    
.add:
    add ax, bx
    jmp .result
.sub:
    sub bx, ax
    mov ax, bx
    jmp .result
.mul:
    mul bx
    jmp .result
.div:
    cmp ax, 0
    je .error
    xchg ax, bx
    xor dx, dx
    div bx
    
.result:
    push ax
    mov si, msg_calc_result
    call print
    pop ax
    call print_dec
    mov si, msg_newline
    call print
    
    jmp calc_loop
    
.error:
    mov si, msg_div_error
    call print
    jmp calc_loop

input_number:
    xor ax, ax
    mov cx, 0
.loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x0D
    je .done
    cmp al, ' '
    je .done
    
    cmp al, '0'
    jb .loop
    cmp al, '9'
    ja .loop
    
    mov ah, 0x0E
    int 0x10
    
    sub al, '0'
    mov dx, ax
    mov ax, cx
    mov bx, 10
    mul bx
    add ax, dx
    mov cx, ax
    
    jmp .loop
.done:
    mov ax, cx
    ret


echo_text:
    mov si, input_buffer
    add si, 5    
    
    call print
    mov si, msg_newline
    call print
    ret


input_string_uppercase:
    xor cx, cx
.loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x0D
    je .done
    cmp al, 0x08
    je .backspace
    cmp al, 0x1B    ; ESC
    je .escape
    
    cmp al, ' '
    jb .loop
    

    cmp al, 'a'
    jb .not_lowercase
    cmp al, 'z'
    ja .not_lowercase
    sub al, 32    
    
.not_lowercase:
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F    
    int 0x10
    
    stosb
    inc cx
    cmp cx, 63
    je .done
    jmp .loop
    
.backspace:
    cmp cx, 0
    je .loop
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .loop
    
.escape:
    mov byte [di], 0x1B
    jmp .done_exit
    
.done:
    mov byte [di], 0
.done_exit:
    mov si, msg_newline
    call print
    ret


print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F    
    int 0x10
    jmp print
.done:
    ret

putc:
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F    
    int 0x10
    ret

print_dec:
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0
    mov bx, 10
.divide:
    mov dx, 0
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .divide
    
.print_loop:
    pop ax
    add al, '0'
    call putc
    loop .print_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_hex_byte:
    push ax
    shr al, 4
    call print_hex_nibble
    pop ax
    and al, 0x0F
    call print_hex_nibble
    ret

print_hex_nibble:
    cmp al, 10
    jb .digit
    add al, 'A' - 10
    jmp .print
.digit:
    add al, '0'
.print:
    call putc
    ret


boot_drive db 0
menu_selected db 0
edit_pos dw 0
edit_cursor_x db 0
edit_cursor_y db 0


menu_items:
    db '<PC files>', 0
    times 30-11 db ' '
    db '<MiOS About>', 0
    times 30-13 db ' '
    db '<shell>', 0
    times 30-8 db ' '


cmd_help_str db 'HELP', 0
cmd_dir_str db 'DIR', 0
cmd_cls_str db 'CLS', 0
cmd_clear_str db 'CLEAR', 0
cmd_ver_str db 'VER', 0
cmd_info_str db 'INFO', 0
cmd_reboot_str db 'REBOOT', 0
cmd_shutdown_str db 'SHUTDOWN', 0
cmd_time_str db 'TIME', 0
cmd_date_str db 'DATE', 0
cmd_edit_str db 'EDIT', 0
cmd_ascii_str db 'ASCII', 0
cmd_calc_str db 'CALC', 0
cmd_mem_str db 'MEM', 0
cmd_echo_str db 'ECHO', 0
cmd_ls_str db 'LS', 0
cmd_exit_str db 'EXIT', 0


input_buffer times 64 db 0
edit_buffer times 2048 db 0


msg_gui_title db 13,10,'MiOS 4.4 BETA Menu',13,10,0
msg_gui_separator db '========================',13,10,13,10,0
msg_gui_help db 13,10,'prees ENTER to select',13,10,0

msg_selected_prefix db ' => ', 0
msg_unselected_prefix db '    ', 0

msg_esc_exit db 'Press ESC to return to main menu',13,10,0

; Сообщения
msg_welcome db 'MiOS 4.4 BETA',13,10
            db 'Type HELP for available commands',13,10,0

msg_prompt db 13,10,'MiOS:\> ',0

msg_help db 13,10,'all commands:',13,10
         db '  HELP          - Show this help',13,10
         db '  DIR, LS       - Show files',13,10
         db '  CLS, CLEAR    - Clear screen',13,10
         db '  VER           - Show version',13,10
         db '  INFO          - System info',13,10
         db '  TIME          - Show time',13,10
         db '  DATE          - Show date',13,10
         db '  EDIT          - Text editor',13,10
         db '  ASCII         - ASCII table',13,10
         db '  CALC          - Calculator',13,10
         db '  MEM           - Memory info',13,10
         db '  ECHO [text]   - Display text',13,10
         db '  EXIT          - Return to GUI',13,10
         db '  REBOOT        - Restart',13,10
         db '  SHUTDOWN      - Power off',13,10,0

msg_dir db 13,10,' Volume in drive A is MIOS',13,10
        db ' Directory of A:\',13,10,13,10
        db ' README   TXT      512 bytes',13,10
        db ' KERNEL   BIN     8192 bytes',13,10
        db ' BOOT     BIN      512 bytes',13,10
        db ' CONFIG   SYS       64 bytes',13,10
        db ' AUTOEXEC BAT      128 bytes',13,10
        db ' SYSTEM   DAT     1024 bytes',13,10,0

msg_version db 13,10,'MiOS 4.4 (MiOS16)',13,10
            db 'Video Mode: 640x480 VGA',13,10
            db 'Build: 2026 (Mi-1.4B54)',13,10
            db 'Mikhail (c) 2026',13,10,0

msg_sysinfo_header db 13,10,'System Information:',13,10,0

msg_cpu db 13,10,'CPU: ',0
msg_cpu_8086 db '8086/8088',0
msg_cpu_286 db '80286',0
msg_cpu_386 db '80386+',0

msg_memory db 13,10,'Memory: ',0
msg_kb db ' KB',0
msg_kb_conventional db ' KB conventional',0

msg_video_mode db 13,10,'Video: 640x480 VGA (Mode 12h)',0

msg_memory_info db 13,10,'Conventional memory: ',0

msg_time_is db 13,10,'Current time: ',0
msg_time_error db 13,10,'Time not available',0

msg_date_is db 13,10,'Current date: ',0
msg_date_error db 13,10,'Date not available',0

msg_editor_help db 13,10,'Text Editor - ESC to exit, Enter for new line',0
msg_editor_start db 13,10,'Enter text:',13,10,0
msg_editor_saved db 13,10,'Text saved!',13,10,0

msg_ascii_header db 'ASCII Table ',13,10
                 db '====================',13,10,0

msg_calc_welcome db 13,10,'Calculator',13,10
                 db 'Enter expression (e.g., 2+3)',13,10,0
msg_calc_prompt db 13,10,'Calc> ',0
msg_calc_result db 13,10,'Result: ',0
msg_div_error db 13,10,'Error: Division by zero!',13,10,0

msg_unknown db 13,10,'Unknown command. Type HELP',13,10,0

msg_rebooting db 13,10,'Rebooting...',0
msg_shutdown db 13,10,'System halted. You can now turn off the computer.',13,10,0

msg_tab db '   ',0
msg_newline db 13,10,0

times 8192-($-$$) db 0