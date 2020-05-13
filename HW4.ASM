.model tiny
.code
locals @@
org 100h

;-------------------------------------------------
VIDEOSEG	equ 0b800h
LeftTopAngle	equ 201d
RightTopAngle	equ 187d
LeftBotAngle	equ 200d
RightBotAngle	equ 188d
HorLine		equ 205d
VertLine	equ 186d
LenLbl		equ 12d
;-------------------------------------------------

Start:		mov bx, 80h
		cmp byte ptr [bx], 10d
		jae @@start
		mov ax, 4c00h
		int 21h

@@start:	add bx, 2
		xor di, di
		call createcoord	;di = left top angle

		mov ax, VIDEOSEG
		mov es, ax

		call readcol

		push di

		call reading		;read width and heigh and
					;set count of steps

ForDrawing:	pop di
		push di
		push cx
		call ChSize
		call DrBackGrWithSh

		mov cx, 0aaaah
Temp:		nop
		loop Temp

		pop cx
		loop ForDrawing

		pop di
		call DrLbl

		xor ax, ax
		int 16h
		
		Ret

Width_Fr	dw 25d
Heigh_Fr	dw 0d

Msg:		db "Don't sleep!", 00h

;-------------------------------------------------
;Destroy:	dh, ax, cx, di, bx
;-------------------------------------------------
DrBackGrWithSh	proc

		mov dh, ah
		and dh, 10000111b
		
		call DrFirstLine
		call DrEmLn
		call DrLastLine

		Ret
		endp

;-------------------------------------------------
;Enter:	di - address of beginning of line(we will draw here)
;	es - address of videosegment
;	ah - colour
;	dh - second color
;Result:	di - address of next line
;Destroy:	al, cx
;-------------------------------------------------
DrFirstLine	proc

		mov al, LeftTopAngle
		cld
		stosw

		mov cx, word ptr [Width_Fr]
		mov al, HorLine
		rep stosw

		mov al, RightTopAngle
		stosw

		xchg ah, dh
		add di, 160d
		stosw
		sub di, 162d
		xchg ah, dh

		sub di, word ptr [Width_Fr]
		sub di, word ptr [Width_Fr]
		sub di, 4
		add di, 160d

		Ret
		endp

;-------------------------------------------------
;Enter:		ah - colour
;		dh - second colour
;Destroy:	bx, cx, al
;-------------------------------------------------
DrEmLn		proc
		
		mov bx, word ptr [Heigh_Fr]
		cmp bx, 0
		je @@end

		call DrEmptyLines

@@end:		Ret
		endp

;-------------------------------------------------
;Enter:		di - address of line's beginning
;		es - address of video segment
;		bx - count of empty lines
;		ah - colour
;		dh - second colour
;Destroy:	cx, bx, al
;-------------------------------------------------
DrEmptyLines	proc

		mov cx, word ptr [Width_Fr]

		mov al, VertLine
		stosw

		mov al, ' '
		rep stosw

		mov al, VertLine
		stosw

		add di, 160d
		xchg ah, dh
		stosw
		xchg dh, ah
		sub di, 162d

		sub di, word ptr [Width_Fr]
		sub di, word ptr [Width_Fr]
		sub di, 4
		add di, 160d

		dec bx
		jne DrEmptyLines
		Ret
		endp

;-------------------------------------------------
;Enter:		di - address of line
;		es - address of video segment
;		ah - colour
;Destroy:	cx, ax, di, al
;-------------------------------------------------
DrLastLine	proc

		mov al, LeftBotAngle
		stosw
		add di, 160d
		xchg ah, dh
		stosw
		sub di, 162d
		xchg ah, dh

		mov al, HorLine
		mov cx, word ptr [Width_Fr]
		rep stosw

		add di, 81d shl 1
		sub di, word ptr [Width_Fr]
		sub di, word ptr [Width_Fr]
		mov cx, word ptr [Width_Fr]
		xchg ah, dh
		rep stosw

		xchg ah, dh
		sub di, 162d

		mov al, RightBotAngle
		stosw

		add di, 160d
		xchg ah, dh
		stosw
		xchg ah, dh
		
		Ret
		endp

;-------------------------------------------------
;Enter:		es - videoseg
;		di - address of left top angle in video
;Destroy:	di, bx, al
;-------------------------------------------------
DrLbl		proc
		mov bx, word ptr [Heigh_Fr]
		dec bx
		shr bx, 1
		xchg bx, ax
		push bx
		mov bx, 160d
		mul bx
		pop bx
		xchg ax, bx

		add di, bx
		add di, 160d
		mov bx, word ptr [Width_Fr]
		sub bx, LenLbl
		shr bx, 1
		shl bx, 1
		add di, bx
		add di, 2

		mov bx, offset Msg
		cmp byte ptr [bx], 00h
		je @@end

@@do:		mov al, byte ptr [bx]
		mov byte ptr es:[di], al
		add di, 2
		inc bx
		cmp byte ptr [bx], 00h
		jne @@do

@@end:		Ret
		endp
;-------------------------------------------------
;Enter:		bx - address of control line
;Destroy:	cx
;Result:	di - number of shift cells for left top angle
;-------------------------------------------------
createcoord	proc
		call putnumindi		;y_coord

		xchg di, ax
		mov cx, 80d
		mul cx
		xchg di, ax
		push di

		call putnumindi

		pop cx
		add cx, di
		mov di, cx
		shl di, 1

		Ret
		endp
		

;-------------------------------------------------
;Enter:		bx - address in memory
;Result:	di - number
;Destroy:	dl, cx
;-------------------------------------------------
putnumindi	proc
		xor di, di

@@make:		mov cl, byte ptr [bx]
		inc bx

		cmp cl, '0' + 9
		ja @@end
		cmp cl, '0'
		jb @@end

		mov ch, 10d
		xchg di, ax
		mul ch
		mov ch, 0
		sub cl, '0'
		add ax, cx
		xchg di, ax
		jmp @@make

@@end:		Ret
		endp

;-------------------------------------------------
;Result:	ah = Color
;Destroy:	ch
;Enter:		bx - address of control part
;-------------------------------------------------
readcol		proc
		xor ch, ch

@@beg:		mov al, byte ptr [bx]
		inc bx

		cmp al, '0'
		jb @@end

		cmp al, '9'
		jbe @@dig

		cmp al, 'A'
		jb @@end

		cmp al, 'F'
		jbe @@HiS

		cmp al, 'a'
		jb @@end

		cmp al, 'f'
		ja @@end

		shl ch, 4d
		sub al, 'a'
		add al, 10d
		add ch, al
		jmp @@beg

@@HiS:		shl ch, 4d
		sub al, 'A'
		add al, 10d
		add ch, al
		jmp @@beg

@@dig:		shl ch, 4d
		sub al, '0'
		add ch, al
		jmp @@beg

@@end:		mov ah, ch

		Ret
		endp

;-------------------------------------------------
;Destroy:	bx
;Increase Width_Fr and Heigh_Fr
;-------------------------------------------------
ChSize		proc

		mov bx, word ptr [Width_Fr]
		inc bx
		mov word ptr [Width_Fr], bx

		mov bx, word ptr [Heigh_Fr]
		inc bx
		mov word ptr [Heigh_Fr], bx

		Ret
		endp

;-------------------------------------------------
;Result:	Width_Fr - width of frame before animation
;		Heigh_Fr - heigh of frame before animation
;		cx - count of step in animation
;Destroy:	bx, cx, al, di
;-------------------------------------------------
reading		proc

		call putnumindi
		mov word ptr [Width_Fr], di
		
		call putnumindi
		mov word ptr [Heigh_Fr], di
		cmp di, word ptr [Width_Fr]
		ja @@anway

		sub word ptr [Width_Fr], di
		mov cx, di
		mov word ptr [Heigh_Fr], 0
		jmp @@end

@@anway:	sub di, word ptr [Width_Fr]
		mov cx, word ptr [Width_Fr]
		mov word ptr [Width_Fr], di
		mov word ptr [Heigh_Fr], 0

@@end:		Ret
		endp

end		Start