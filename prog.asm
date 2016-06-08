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

	EOL equ 10

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
serrad db 'ACCESS DENIED',10
slerrad equ $-serrad
null	equ 0x00
test:	db 'oli.txt',0
ltest equ $-test
szFile:	db "TEST",0
File_Len equ $-szFile
fileDes dd 0
fileDesIN dd 0
debug db 'CAAATTDDOOOGG!',10
ldebug equ $-debug
	
	%define sizeof(x) x %+ _size
	
section .bss			;AKA VARIABLES
	par1		resb 1			;VARIABLE FOR PARAMETER 1
	par2		resw 2			;VARIABLE FOR PARAMETER 2
	par3		resb 1			;VARIABLE FOR PARAMETER 3
	par4		resw 2			;VARIABLE FOR PARAMETER 4
	
	message		resb 1024		;MESSAGE TO MERGE.
	lmessage	resb 16			;MESSAGE LENGTH

	binMessage	resb 1024
	lbinMessage	resb 16

	stat		resb sizeof(STAT)
	Org_Break	resd 1
	formatSize	resb 16

	TempBuf:	resb 5242880
	lTempBuf	resb 1024

	%macro esteganografia 0
	
	mov ecx,TempBuf		;THE IMAGE IN MEMORY
	
	mov ebx,0
	mov edx,0
	
	jmp _readLine
	;; FIRST WE GOTTA JUMP AWAY FROM THE HEADER, A.K.A THE FIRST 3 LINES.
_readLine:
	cmp BYTE[ecx],EOL
	debug
	je _eol
	inc ebx			;COUNT ELEMENTS IN ROW (COLUMNS)
	inc ecx			;SHIFT
	
	jmp _readLine
_eol:
	inc edx			;COUNT ELEMENTS IN A COLUMN (ROWS)
	cmp edx,3		;WE NEED TO IGNORE 3 ROWS
	je _eoh
	inc ecx
	inc ebx
	jmp _readLine
_eoh:				;END OF THE HEADER, :D
	inc ebx
	mov [formatSize],ebx
_encrypt:
	mov ecx,[lbinMessage]
	xor edi,edi
	xor esi,esi
	add esi, [formatSize]
_cycleThroughImage:
	movzx eax, byte[TempBuf + esi] ;POSITION OF THE BYTE TO MODIFY AS A WORD.
	mov ebx,2
	mov edx,0
	div ebx
	
	cmp edx,1		;COMPARE THE RESULT OF THE DIVISION WITH 0
	je _LSBOne
	jmp _LSBZero

_LSBOne:
	cmp byte[binMessage + edi],'1'
	je _done
	and byte[TempBuf + esi],254

	jmp _done

_LSBZero:
	cmp byte[binMessage + edi],'0'
	je _done
	or byte[TempBuf + esi],1

	jmp _done

_done:
	inc esi
	inc edi
	dec ecx

	jz _write

	jmp _cycleThroughImage
_write:	
	%endmacro

	%macro messageToBits 1	;%1 = MESSAGE
;;;  MSG NEEDS TO BE STORES IN EBX.
	mov esi,%1

	xor ecx,ecx
_nextChar:
	movzx eax, byte[esi]
	cmp eax, 0
	je _end

_divide:
	mov edx, 0
	cmp eax, 1
	je  _endDivide
	mov ebx, 2
	div ebx
	cmp edx, 0
	je  _addZero
	jmp _addOne

_addZero:
	mov edi, '0'
	push edi
	jmp _divide

_addOne:
	mov edi, '1'
	push edi
	jmp _divide

_endDivide:
	mov edi, '1'
	push edi

	cmp byte[esi], 127
	jg _endChar
	cmp byte[esi], 64
	jge _concatOne
	cmp byte[esi], 32
	jl _concatThree
	jmp _concatTwo

_concatOne:
	mov edi, '0'
	push edi

	jmp _endChar

_concatTwo:
	mov edi, '0'
	push edi
	mov edi, '0'
	push edi

	jmp _endChar

_concatThree:
	mov edi, '0'
	push edi
	mov edi, '0'
	push edi
	mov edi, '0'
	push edi

	jmp _endChar

_endChar:
	pop edi
	mov [binMessage + ecx], edi
	inc ecx

	pop edi
	mov [binMessage + ecx], edi
	inc ecx

	pop edi
	mov [binMessage + ecx], edi
	inc ecx

	pop edi
	mov [binMessage + ecx], edi
	inc ecx

	pop edi
	mov [binMessage + ecx], edi
	inc ecx

	pop edi
	mov [binMessage + ecx], edi
	inc ecx

	pop edi
	mov [binMessage + ecx], edi
	inc ecx

	pop edi
	mov [binMessage + ecx], edi
	inc ecx

	inc esi
	jmp _nextChar

_end:
	mov byte [binMessage + ecx], byte 10

	mov ebx, [lmessage]
	mov eax, 8
	mul ebx
	mov [lbinMessage], eax
	%endmacro
	
	%macro writeC 2		;WRITE TO CONSOLE, %1 = STRING, %2 = STRING LENGTH
	push eax
	push ebx
	push ecx
	push edx
	
	mov eax,sys_write
	mov ebx,stdout
	mov ecx,%1
	mov edx,%2
	int sys_call
	
	pop edx
	pop ecx
	pop ebx
	pop eax
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
	
	section .text		;AKA CODE
	global _start

_start:	
	;; START BY CAPTURING PARAMETERS. YAYY...

	pop eax				;OUR ARGC
	pop ebx				;THE PROGRAM NAME, CAN BE OVERWRITTEN LATER AS IT IS NOT NEEDED
	
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
	
	strlen [message]
	mov [lmessage],eax
	
	pop ebx			;FIRST USEFUL PARAMETER. '-F'
	mov [par1], ebx
	;; CHECK FOR -F; IF SO, NEXT PARAMETER IS A FILE.
	cmpstr fileCom,[par1],2
	jne err2		;IF NOT, GO TO ERR2
	
	pop ebx			;SECOND USEFUL PARAMETER. [FILE]
	mov [par2], ebx

	;; ~ Get file size
	mov eax, sys_newstat
	mov ebx, [par2]
	mov ecx, stat
	int 80H

	mov eax,dword [stat + STAT.st_size]
	mov [lTempBuf], eax

	;; CHECK FOR -O
	pop ebx			;THIRD USEFUL PARAMETER. '-O'
	mov [par3], ebx
	
	;; CHECK FOR -O; IF SO, NEXT PARAMETER IS A FILE.
	cmpstr outCom,[par3],2
	jne err2		;IF NOT, GO TO ERR2

	pop ebx			;FORTH USEFUL PARAMETER. [FILE]
	mov [par4], ebx
	
	;;  OPEN FILE
	mov eax, sys_open
	mov ebx, [par2]
	mov ecx, 0		;READ ONLY
	int sys_call

	test eax,eax
	js accessd
	
	mov [fileDesIN],eax
	
	;;  READ
	mov eax, sys_read
	mov ebx,[fileDesIN]
	mov ecx, TempBuf
	mov edx, lTempBuf
	int sys_call
	
	js accessd
	;;  CLOSE
	mov eax, sys_close
	mov ebx, [fileDesIN]
	int sys_call

	;;  CREATE
	mov eax,sys_create	;SYS_CREATE
	mov ebx, [par4]		;PASS OUTPUT FILENAME
	mov ecx,6440		;CHMOD
	int sys_call

	mov [fileDes], eax

	messageToBits [message]
	esteganografia

	;; WRITE
	mov eax, sys_write
	mov ebx, [fileDes]
	mov ecx, TempBuf
	mov edx, [lTempBuf]
	int sys_call

	;; CLOSE
	mov eax,sys_close
	mov ebx,[fileDes]
	int sys_call
	
	jmp end	
err2:
	;; Print deb.
	writeC serr2, slerr2
	
	jmp end

accessd:
	writeC serrad, slerrad	;ACCESS DENIED TO FILE.
	
	jmp end
end:	
	mov eax,sys_exit		;SYS_EXIT
	mov ebx,0			;EXIT WITH NO ERROR
	int sys_call
