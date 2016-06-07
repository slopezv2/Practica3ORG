	;; CONSTANTS
	
	sys_exit equ 1
	sys_read equ 3
	sys_write equ 4
	sys_open equ 5
	sys_close equ 6
	sys_create equ 8
	sys_sync equ 36
	sys_brk equ 45
	sys_newstat equ 106
	sys_call equ 128

	O_RDONLY equ 0		;READ ONLY
	O_WRONLY equ 1		;WRITE ONLY
	O_RDWR equ 2		;BOTH
	
	stdin equ 0
	stdout equ 1
	stderr equ 2

	struc STAT
	.st_dev: 	resd 1
	.st_ino: 	resd 1
	.st_mode:       resw 1
	.st_nlink:      resw 1
	.st_uid:        resw 1
	.st_gid:        resw 1
	.st_rdev:       resd 1
	.st_size:       resd 1
	.st_blksize:    resd 1
	.st_blocks:     resd 1
	.st_atime:      resd 1
	.st_atime_nsec: resd 1
	.st_mtime:      resd 1
	.st_mtime_nsec: resd 1
	.st_ctime:      resd 1
	.st_ctime_nsec: resd 1
	.unused4:       resd 1
	.unused5:       resd 1 
	endstruc
	
	section .data 		;AKA CONSTANTS
serr1	db 'Error: No parameters given to the program.',10 
slerr1	equ $-serr1
serr2	db 'Error: Parameters do no match with standard.',10
slerr2	equ $-serr2
sutilerr db 'Error: Command undefined',10 
slutilerr equ $-sutilerr
shelp	db 'Help here', 10	
slhelp	equ $-shelp
sversion db 'VERSION 0.1', 10
slversion equ $-sversion
sautor	db 'By: Juan Manuel Mejía B., Sebastian Lopez V. & Camilo Zuluaga V.', 10
slautor equ $-sautor
helpCom db '-h'
lhelpCom equ $-helpCom
verCom db '-v'
lverCom equ $-verCom
fileCom db '-f'
lfileCom equ $-fileCom
outCom	db '-o'
loutCom equ $-outCom
needHelp db 'Need help? Use -h for more info on how to run the program.',10
lneedHelp equ $-needHelp
null	equ 0x00
lbuffer dw 1024			;Size of our buffer
test:	db 'oli.txt',0
ltest equ $-test
szFile:	db "TEST",0
File_Len equ $-szFile
fileDes dd 0
debug db 'CAAATTDDOOOGG!',10
ldebug equ $-debug

	%define sizeof(x) x %+ _size
	
	section .bss			;AKA VARIABLES
par1:		resb 1			;VARIABLE FOR PARAMETER 1
par2:		resb 1			;VARIABLE FOR PARAMETER 2
lpar2:		resb 1
par3:		resb 1			;VARIABLE FOR PARAMETER 3
par4:		resb 1			;VARIABLE FOR PARAMETER 4
lpar4:		resb 1
buffer:		resb 1024		;READING BUFFER
message:	resb 1024		;MESSAGE TO MERGE.
lmessage:	resw 1			;MESSAGE LENGTH
binMessage:	resb 1024
lbinMessage:	resw 1
stat:		resb sizeof(STAT)
Org_Break:	resd 1
TempBuf:	resd 1
lTempBuf:	resd 1
	
	%macro esteganografia 3	;ENCRYPT. %1 = MESSAGE, %2 = IMG; %3 = SIZE IMG
	mov eax,%1
	mov ebx,%2
	mov ecx,%3

	
	%endmacro
	
	%macro writeC 2		;WRITE TO CONSOLE, %1 = STRING, %2 = STRING LENGTH
	mov eax,sys_write
	mov ebx,stdout
	mov ecx,%1
	mov edx,%2
	int sys_call
	%endmacro

	%macro debug 0
	writeC debug, ldebug
	%endmacro
	
	%macro cmpstr 3		;COMPARE 2 STRINGS, %1 = STRING 1, %2 = STRING 2, %3 = NUMBER OF ASCII CHARACTERS TO COMPARE.
	push ecx
	
	cld			;SCAN FORWARD (LEFT TO RIGHT)
	mov ecx,%3		;SCAN %3 CHARACTERS
	mov esi,%1		;STRING 1
	mov edi,%2		;STRING 2
	repe cmpsb		;REPE REPEATS ECX TIMES OR UNTIL EQUAL. CMPSB COMPARES 1 BYTE AT A TIME.
	pop ecx
	%endmacro

	%macro strlen 1

	push ebx		;STORE EBX IN THE STACK.

	xor eax,eax		;SET EAX TO 0X00. WILL BE USED AS A COUNTER.
	mov ebx,%1		;SET EBX TO THE ARGUMENT OF STRLEN

loopStrlen:	
	cmp [ebx], BYTE 0	;TRY TO FIND THE NULL CHARACTER IN ASCII, MAYBE?
	jz restoreStrlen
	
	inc eax			;CONTADOR++
	inc ebx			;POSICION EN LA STRING ++
	
	jmp loopStrlen

restoreStrlen:

	pop ebx			;GET EBX BACK TO ITS ORIGINAL VALUE.
	;; NOTE: THE VALUE OF EAX WILL REMAIN IN THE STACK IF NEEDED.
	
	%endmacro

	%macro messageToBits 0	;%1 = MESSAGE
	;; MSG NEEDS TO BE STORES IN EBX.
	xor eax,eax
	xor edi,edi		;WILL BE OUR INNER LOOP COUNTER.
	xor esi,esi		;WILL BE OUR RESULT.
	
.byteByByte:
	mov eax, byte[ebx]
	cmp eax,0
	jz .exit
	
.toBinary:	
	cmp eax,0
	je .end
	
	mov ebx,2
	div ebx 		;DIVIDE THE RESULT OF EAX BY THE VAUE OF EBX(2).

	mov eax,edx
	
	cmp eax,'0'		;THE RESULT OF THE DIVISION IS STORE IN EDX.
	je .addZero

	push eax
	mov eax,'1'
	mov [binMessage + ecx], eax
	pop eax

	jmp .toBinary
	
.addZero:
	push eax
	mov eax,0
	mov [binMessage + ecx], eax
	pop eax
	jmp .toBinary
.end:	

	inc ebx
	jmp .byteByByte
	
.exit:	
	
	%endmacro
	
	section .text		;AKA CODE
	global _start

_start:	
	;; START BY CAPTURING PARAMETERS. YAYY...

	POP EAX				;OUR ARGC
	POP EBX				;THE PROGRAM NAME, CAN BE OVERWRITTEN LATER AS IT IS NOT NEEDED
	
	;; START IF 1
	CMP EAX,1			;CHECK IF THERE IS THERE IS NO PARAMETERS TO READ. 
	JE err1

	CMP EAX,2
	JE util

	CMP EAX,6			;CHECK IF THERE IS 5 PARAMETERS, IN THIS CASE WE TRY TO FIND "MSG" -F [FILE] -O [FILE].
	JE exe


	JMP end
err1:
	;; PRINT DEB.
	writeC serr1,slerr1
	
	jmp end

util:
	POP EAX
	MOV [par1],EAX
	
	cmpstr helpCom,[par1],2
	jne notEqu		;IF NOT, CHECK IF -V
	jmp help		;ELSE, SHOW HELP MENU

notEqu:
	cmpstr verCom,[par1],2
	jne notEqu1		;IF NOT, GO ON.
	jmp version		;ELSE, SHOW VERSION
	
notEqu1:	
	writeC sutilerr, slutilerr ;Undefined variable.
	writeC needHelp, lneedHelp ;Need help

	jmp end

help:
	writeC shelp,slhelp	;DISPLAY HELP MESSAGE
	
	jmp end
version:
	writeC sversion, slversion ;DISPLAY VERSION
	writeC sautor, slautor	   ;DISPLAY AUTORS
	
	jmp end
exe:
	;; Now we need to check if the "message" -f [FILE] -o [FILE] formas is valid.

	;; NOTE: DO TO DERPS, I FORGOT TO READ THE MESSAGE FIRST. IT IS ANOTHER PARAMETER. Message needs to get the "" removed.

	pop ebx
	mov [message],ebx

	messageToBits
	
	strlen [message]
	mov [lmessage],eax
	
	pop ebx			;FIRST USEFUL PARAMETER. '-F'
	mov [par1], ebx
	;; CHECK FOR -F; IF SO, NEXT PARAMETER IS A FILE.
	cmpstr fileCom,[par1],2
	jne err2		;IF NOT, GO TO ERR2
	pop ebx			;SECOND USEFUL PARAMETER. [FILE]
	mov [par2], ebx

	;; CHECK FOR -O
	pop ebx			;THIRD USEFUL PARAMETER. '-O'
	mov [par3], ebx
	
	;; CHECK FOR -O; IF SO, NEXT PARAMETER IS A FILE.
	cmpstr outCom,[par3],2
	jne err2		;IF NOT, GO TO ERR2

	pop ebx			;FORTH USEFUL PARAMETER. [FILE]
	mov [par4], ebx

	;;  CREATE
	mov eax,sys_create	;SYS_CREATE
	mov ebx, [par4]		;PASS OUTPUT FILENAME
	mov ecx,511		;ALL ACCESS RIGHTS
	int sys_call

	mov [fileDes], eax
	
	;; ~ Get file size
	mov		ebx, szFile
	mov		ecx, stat
	mov		eax, sys_newstat
	int		80H

	mov eax,dword [stat + STAT.st_size]
	mov [lTempBuf], eax
	
	;; ~ Get end of bss section
	xor		ebx, ebx
	mov		eax, sys_brk
	int		80H
	mov	[Org_Break], eax
	mov	[TempBuf], eax
	push	eax

	;;  extend it by file size
	pop		ebx
	add		ebx, dword [stat + STAT.st_size]
	mov		eax, sys_brk
	int		80H

	;;  open file
	mov		ebx, szFile
	mov		ecx, O_RDONLY
	xor		edx, edx
	mov		eax, sys_open
	int		80H
	xchg    	eax, esi

	;;  READ
	mov     ebx, esi
	mov		ecx, [TempBuf]
	mov		edx, dword [stat + STAT.st_size]
	mov		eax, sys_read
	int		80H
	
	;; WRITE
	mov eax, 4
	mov ebx, [fileDes]
	mov ecx, [TempBuf]
	mov edx, [lTempBuf]
	int sys_call

	;; CLOSE
	mov eax,sys_close
	mov ebx,[fileDes]
	int sys_call
	
	;; PRINT TO TERMINAL
	mov ebx, stdout
	mov ecx, [TempBuf]
	mov edx, dword [stat + STAT.st_size]
	mov eax, sys_write
	int sys_call

	push edx
	
	;;  close file
	mov		ebx, esi
	mov		eax, sys_close
	int		80H
	
	;;  "free" memory
	mov     ebx, [Org_Break]
	mov     eax, sys_brk
	int     80H
	

	jmp end	
err2:
	;; Print deb.
	writeC serr2, slerr2
	
	jmp end

accessd:
	writeC debug, ldebug	;ACCESS DENIED TO FILE.
	
	jmp end
end:	
	mov eax,sys_exit		;SYS_EXIT
	mov ebx,0			;EXIT WITH NO ERROR
	int sys_call
