;Miguel Jardim 92528
;Rodrigo Santos 92552
;Grupo 50

;este programa obtem valores de posicao (x,y) em funcao da velocidade e angulos de lancamento de acordo com as seguintes equacoes:
;x = velocidade * tempo * cos(angulo)
;y = velocidade * tempo * sen(angulo) - 0,5 * g * t * t

;ao longo do programa (salvo se dito o contrario) os numeros serao representados da seguinte forma:
;os dois primeiros digitos correspondem a parte interia e os outros dois a parte decimal
;ao longo do programa iremos referir-nos a esta representacao como 2/2
;a velocidade deve ser um valor entre 0 e 50 e o angulo entre 0 e 90
;para cada valor de tempo o programa ira guardar em memoria valores diferentes para x e y

IO_READ		EQU		FFFFh
IO_WRITE	EQU		FFFEh
IO_STATUS	EQU		FFFDh	
IO_CONTROL	EQU		FFFCh
FIM_TEXT 	EQU 	0

IO_TIMER_S	EQU		FFF7h
IO_TIMER_C	EQU		FFF6h

INT_MASK_ADDR 	EQU FFFAh
INT_MASK		EQU 8000h
SCORE			EQU	0127h
		
		ORIG	8000h
		
corpo	STR		'  O /|\/ \ ', FIM_TEXT
txt_vel	STR		'Velocidade: ', FIM_TEXT
txt_ang	STR		'Angulo: ', FIM_TEXT
txt_res	STR		'Jogar outra vez? (s/n) ', FIM_TEXT

txt_1	STR		'+--------------------------+', FIM_TEXT
txt_2	STR		'|Prima uma tecla para jogar|', FIM_TEXT
txt_3	STR		'Prima uma tecla para continuar', FIM_TEXT
limpa_3	STR		'                              ', FIM_TEXT

;numeros random
ran_1	WORD	0000h
ran_2	WORD	0000h
ran_3	WORD	0000h
ran_4	WORD	0000h
		
ang		WORD	003Ch		;angulo de lancamento: neste caso sao usados os quatro digitos para a parte inteira**
vel		WORD	3000h		;velocidade na representacao 2/2
radG	WORD	0474h		;(pi / 180) em hexa: neste caso sao usados os quatro digitos para a parte decimal**

gorila	WORD	0001h		;esta variavel vai funcionar como flag, se estiver a um foi o gorila 1 a lançar (respetivamente para o gorila 0)
score_0	WORD	0000h
score_1	WORD	0000h
max_score	WORD	0000h



FLAG				WORD	0000h
velocidade_timer	WORD	0001h

;** o uso de quatro digitos para a parte inteira no angulo e compensado pelo uso de quatro digitos para a parte fracionaria em radG (pi / 180)

seno	WORD	0000h		;posicao de memoria usada para armazenar o valor do seno
cosseno	WORD	0000h		;posicao de memoria usada para armazenar o valor do cosseno
x		WORD	0000h		;posicao de memoria usada para armazenar o valor de x 
y		WORD	0000h		;posicao de memoria usada para armazenar o valor de y
t		WORD	0000h		;para cada valor de tempo sao calculados diferentes valores de x e y
x0		WORD	0000h		;abcissa do gorila que ataca
y0		WORD	0000h		;ordenada do gorila que ataca
x1		WORD	0000h
y1		WORD	0000h

last_pos	WORD	1800h

CURSOR		WORD	0000h		;posicao do cursor na janela de texto

			ORIG	FE0Fh
			
INT_TIMER	WORD	ROT_TIMER


		ORIG	0000h
		;inicializacao do stack pointer
MAIN:	MOV		R1, FDFFh
		MOV		SP, R1
		
		;inicializacao do cursor		
		MOV		R1, FFFFh
		MOV		M[IO_CONTROL], R1
		MOV		M[CURSOR], R0
		
		MOV		R1, 1800h
		MOV		M[last_pos], R1	
		
		;permite inerrupcao timer
		MOV		R1, INT_MASK
		MOV		M[INT_MASK_ADDR], R1
		
		CALL	janela_inicial
		;reset score
inicio_1:		MOV		M[score_0], R0
				MOV		M[score_1], R0
				MOV		M[max_score], R0
				
inicio:	MOV		R1, M[ran_1]
		MOV		M[x0], R1
		MOV		R1, M[ran_2]
		MOV		M[x1], R1
		MOV		R1, M[ran_3]
		MOV		M[y0], R1
		MOV		R1, M[ran_4]
		MOV		M[y1], R1
		
		;inicializacao do stack pointer		
		MOV		R1, FDFFh
		MOV		SP, R1
		
		;inicializacao do cursor		
		MOV		R1, FFFFh
		MOV		M[IO_CONTROL], R1
		MOV		M[CURSOR], R0
		
		;inicializacao do score
		MOV		R1, SCORE
		MOV		M[CURSOR], R1
		MOV		R2, M[score_0]
		MOV		R3, M[score_1]
		ADD		R2, 0030h
		ADD		R3, 0030h
		MOV		M[IO_CONTROL], R1
		MOV		M[IO_WRITE], R2
		CALL	next_col
		MOV		R1, '-'
		MOV		M[IO_WRITE], R1
		CALL	next_col
		MOV		M[IO_WRITE], R3
		
		
		MOV		R1, 1800h
		MOV		M[last_pos], R1
		
		PUSH	M[x0]
		PUSH	M[y0]
		CALL	desenha_gorila
		
		PUSH	M[x1]
		PUSH	M[y1]
		CALL	desenha_gorila
		
;coloca o cursor na primeira coluna e primeira linha
		CALL	res_col					
		CALL	res_line
		
		MOV		M[t], R0
		
		DSI
			
;escreve mesagem que pede ao utilizador a velocidade
		PUSH	txt_vel
		CALL	escreve_msg				
				
		PUSH	R0
		CALL 	LerChar
		POP		R1						;R1 tem input da velocidade
		SHL		R1, 8
		MOV		M[vel], R1
			
		CALL	next_line
		CALL	res_col
		
;escreve mesagem que pede ao utilizador o angulo
		PUSH	txt_ang
		CALL	escreve_msg				
		
		PUSH	R0
		CALL	LerChar
		POP		R1						;R1 tem input do angulo
		MOV		M[ang], R1
		
;conversao de graus para radianos
		PUSH	R0
		PUSH	M[ang]              	
		CALL	rad						
		POP		R1						;R1 fica com o angulo em radiano
		MOV 	M[ang], R1				;angulo em radiano fica em ang
		
;calculo do seno		
		PUSH	R0
		PUSH	M[ang]
		CALL	sen						
		POP		R1 						
		MOV		M[seno], R1					;o valor do seno fica na posicao de memoria com a label seno
		
;calculo do cosseno		
		PUSH	R0
		PUSH	M[ang]
		CALL	cos				
		POP		R1 						
		MOV		M[cosseno], R1				;o valor do cosseno fica na posicao de memoria com a label cosseno
		
		MOV		R1, R0
		CMP     M[gorila], R0
		BR.Z	g
		MOV		M[gorila], R1
		BR		j
g:		MOV		R1, 0001h
j:		MOV		M[gorila], R1
	
		ENI
ativa_t:MOV		R1, M[velocidade_timer]
		MOV		M[IO_TIMER_C], R1
		MOV		R1, 0001h
		MOV		M[IO_TIMER_S], R1
		
ciclo:	CMP		R0, M[FLAG]
		JMP.Z	ciclo
		MOV		M[FLAG], R0
;incrementa o tempo
		MOV		R1, M[t]
		ADD		R1, 000Fh
		MOV		M[t], R1
		
;chamada da função que calcula coordenadas da banana
		CALL	projetil
		
		PUSH	M[x]
		PUSH	M[y]
		CALL	desenha_banana
				
		JMP		ativa_t
		
;calculo das coordenadas da banana				
projetil:	MOV	R1, M[vel]					;calculo do valor de x
			MOV		R2, M[t]				;R1 vai guardar o valor de x
			MOV		R3, M[cosseno]
			MUL		R1, R2					;produto da velocidade pelo tempo
			SHL		R1, 8	
			SHR		R2, 8
			ADD		R1, R2					;R1 fica com velocidade * tempo
		
;a ultilizacao da operacao shift nos dois registos seguida da soma dos mesmos permite-nos obter o resultado na forma inicialmente descrita: dois digitos para a parte interia e dois para as casas decimais
		
		MUL		R1, R3					;produto de velocidade * tempo pelo valor do cosseno
		SHL		R1, 8
		SHR		R3, 8
		ADD		R1, R3
		SHR		R1, 8					;eliminamos a parte decimal de x
						
		ADD		R1, M[x0]
		CMP		M[gorila], R0
		BR.Z	salta
		SUB		R1,	0005h			;se for o gorila 0 a lançar queremos somar 3, no caso do gorila 1 queremos subtrair 2 (3 - 5 = 2)
		MOV		R2, R1
		MOV		R1, M[x1]
		SUB		R1, R2				;subtrai-mos ah abcissa do ponto onde o gorila que atira a banana se encontra o valor de x
salta:	ADD		R1, 0003h			;impede que a banana substitua o braço do gorila
		CMP		R1, 80
		JMP.P	missed
		CMP		R1, 0
		JMP.N	missed
		
		MOV		M[x], R1				;armazenamos o valor de x na posicao de memoria correspondente
		
		;calculo do valor de y
		MOV		R1, M[vel]				;R1 vai guardar o valor de y
		MOV		R2, M[t]
		MOV		R3, M[seno]
		MUL		R1, R2					;produto da velocidade pelo tempo
		SHL		R1, 8
		SHR		R2, 8
		ADD		R1, R2					;R1 fica com velocidade * tempo
		MUL		R1, R3					;produto de velocidade * tempo pelo seno
		SHL		R1, 8
		SHR		R3, 8
		ADD		R1, R3					;R1 fica com velocidade * tempo * seno
		
		MOV		R2, M[t]
		MOV		R3, M[t]
		MUL		R2, R3					;calculo de t * t
		SHL 	R2, 8
		SHR     R3, 8
		ADD		R2, R3
		
		MOV		R3, 0500h				
		MUL		R2, R3					;calculo de 5 * t * t
		SHL 	R2, 8
		SHR     R3, 8
		ADD		R2, R3
		MOV		R4, 0000h
		SUB		R1, R2 					;R1 fica com o valor de y
		
		MOV		R3, M[y0]
		CMP		M[gorila], R0
		BR.Z	f
		MOV		R3, M[y1]
f:		SHL		R3, 8
		ADD		R1, R3				;somamos a ordenada do ponto onde se encontra o gorila que atira a banana
		JMP.N	missed			
		SHR		R1, 8					;eliminamos a parte decimal de y
		CMP		R1, 22
		JMP.P	missed
		MOV		M[y], R1				;armazenamos o valor de y na posicao de memoria correspondente
		RET

;funcao que calcula o seno de um valor passado atraves da stack
sen:	PUSH	R1
		PUSH	R2
		PUSH	R3
		PUSH	R4
		
		PUSH	R0
		PUSH	3
		PUSH	M[SP + 8]
		CALL	pot
		POP		R1						;x ao cubo em R1
		MOV		R4, 6
		DIV		R1,	R4
		MOV		R3, M[SP + 6]
		SUB		R3,	R1
		MOV		M[SP + 7], R3
		
		POP		R4
		POP		R3
		POP		R2
		POP		R1
		RETN	1
		
;funcao que calcula o cosseno de um valor passado atraves da stack
cos:	PUSH	R1
		PUSH	R2
		PUSH	R3
		PUSH	R4
		
		PUSH	R0
		PUSH	2
		PUSH	M[SP + 8]
		CALL	pot						
		POP		R2						;R2 tem x ao quadrado
		
		PUSH	R0
		PUSH	4
		PUSH	M[SP + 8]
		CALL    pot
		POP		R1						;R1 tem x a quarta
		MOV		R4, 2
		DIV		R2,	R4					;R2 tem x ao quadrado sobre dois
		MOV		R3, 0100h
		SUB		R3,	R2
		MOV		R4, 24
		DIV		R1, R4 
		ADD		R3, R1
		MOV 	M[SP + 7], R3			;R3 tem cosseno
		
		POP		R4
		POP		R3
		POP		R2
		POP		R1
		
		RETN	1

;funcao que calcula a potencia cuja base e o sao passados pela stack	
pot:	PUSH	R1
		PUSH	R2
		PUSH	R3
		
		MOV		R1, M[SP + 6]			;expoente
		MOV		R2, M[SP + 5]			;base
pot1:	MOV		R3, M[SP + 5]
		MUL		R2, R3
		SHL 	R2, 8
		SHR     R3, 8
		ADD		R2, R3
		DEC		R1
		CMP		R1, 1
		BR.NZ	pot1
		
		MOV		M[SP + 7], R2
		
		POP		R3
		POP		R2
		POP		R1
		RETN	2
	
;funcao que converte o angulo de graus para radianos	
rad:	PUSH	R1
		PUSH	R2
		
		MOV		R1, M[SP + 4]
		MOV		R2, M[radG]
		MUL		R1, R2
		SHL		R1, 8
		SHR		R2, 8
		ADD		R1, R2
		MOV		M[SP + 5], R1
		
		POP		R2
		POP		R1
		RETN	1

;funcao que escreve na janela de texto uma qualquer mensagem terminada em zero passada pela stack		
escreve_msg:	PUSH	R1
				PUSH	R2
				MOV		R1, M[SP + 4]		;R1 tem posicao de memoria da primeira letra da frase
				MOV		R2, M[R1]
next_char:		MOV		M[IO_WRITE], R2

				CALL	next_col
				
				INC		R1					;percorre as posicoes de memoria das letras da frase a escrever
				MOV		R2, M[R1]
				CMP		R2, R0
				BR.Z	fim_text
				BR		next_char
fim_text:		POP		R2
				POP 	R1
				RETN	1

;funcao que le input do utilizador
LerChar:	PUSH	R1
			PUSH	R2
			PUSH	R3
LerChar1:	CMP		M[IO_STATUS], R0
			BR.Z	LerChar1
			MOV		R1, M[IO_READ]
			CMP		R1, 002Fh
			BR.NP	LerChar1
			CMP		R1, 003Ah
			BR.NN	LerChar1			
			MOV		M[IO_WRITE], R1
			MOV		R2, R1
			SUB		R2, 0030h			;R2 tem o primero digito 
			
LerChar2:	CMP		M[IO_STATUS], R0
			BR.Z	LerChar2
			MOV		R1, M[IO_READ]
			CMP		R1, 000Ah
			BR.Z	not_num				;se o 'enter' for pressionado salta os passos seguintes
			
			CMP		R1, 002Fh
			BR.NP	LerChar2
			CMP		R1, 003Ah
			BR.NN	LerChar2
			
			CALL	next_col
			
			MOV		M[IO_WRITE], R1
			MOV		R3, 000Ah
			MUL		R3, R2
			SUB		R1, 0030h
			ADD		R2, R1
not_num:	MOV		M[SP + 5], R2
			POP		R3
			POP		R2
			POP		R1
			RET
	
;funcao que coloca o cursor na linha seguinte	
next_line:	PUSH	R1
			MOV		R1, M[CURSOR]
			ADD		R1, 0100h
			MOV		M[CURSOR], R1
			MOV		M[IO_CONTROL], R1
			POP 	R1
			RET

;funcao que coloca o cursor na coluna seguinte			
next_col:	PUSH	R1
			MOV		R1, M[CURSOR]
			ADD		R1, 0001h
			MOV		M[CURSOR], R1
			MOV		M[IO_CONTROL], R1
			POP 	R1
			RET	
			
;funcao que coloca o cursor na linha anterior	
prev_line:	PUSH	R1
			MOV		R1, M[CURSOR]
			SUB		R1, 0100h
			MOV		M[CURSOR], R1
			MOV		M[IO_CONTROL], R1
			POP 	R1
			RET

;funcao que coloca o cursor na coluna anterior			
prev_col:	PUSH	R1
			MOV		R1, M[CURSOR]
			SUB		R1, 0001h
			MOV		M[CURSOR], R1
			MOV		M[IO_CONTROL], R1
			POP 	R1
			RET

;funcao que coloca o cursor na primeira linha			
res_line:	PUSH	R1
			MOV		R1, M[CURSOR]
			SHL		R1, 8
			SHR		R1, 8
			MOV		M[CURSOR], R1
			MOV		M[IO_CONTROL], R1
			POP		R1
			RET

;funcao que coloca o cursor na primeira coluna			
res_col:	PUSH	R1
			MOV		R1, M[CURSOR]
			SHR		R1, 8
			SHL		R1, 8
			MOV		M[CURSOR], R1
			MOV		M[IO_CONTROL], R1
			POP		R1
			RET

;funcao que trata a situacao em que a banana falha o alvo			
missed:		PUSH	R1
			CMP		M[max_score], R0
			BR.NZ	continua
			JMP		inicio
			
continua:	CALL	res_line	
			CALL	next_line
			CALL	next_line
			CALL	res_col
			PUSH	txt_res
			CALL	escreve_msg
missed1:	CMP		R0, M[IO_STATUS]
			BR.Z 	missed1
			MOV		R1, M[IO_READ]
			CMP		R1, 's'
			JMP.Z	inicio_1
			CMP		R1, 'n'
			JMP.Z	MAIN
			BR		missed1
			

janela_inicial:	MOV		R1, 0A19h
				MOV		M[IO_CONTROL], R1
				MOV		M[CURSOR], R1
				PUSH	txt_1
				CALL	escreve_msg
		
				MOV		R1, 0B19h
				MOV		M[IO_CONTROL], R1
				MOV		M[CURSOR], R1
				PUSH	txt_2
				CALL	escreve_msg
				
				MOV		R1, 0C19h
				MOV		M[IO_CONTROL], R1
				MOV		M[CURSOR], R1
				PUSH	txt_1
				CALL	escreve_msg
				
				CALL	random

				RET

desenha_gorila:	PUSH	R1
				PUSH	R2
				PUSH	R3
				
				MOV		R1, M[SP + 6]
				MOV		R3, M[SP + 5]

				MOV		R2, 0018h
				SUB		R2, R3
				SHL		R2, 8
				ADD		R1, R2
				MOV		M[CURSOR], R1
				
				CALL	prev_col
				CALL	prev_line
				MOV		R1, corpo
				MOV		R3, R0
k:				MOV		R2, M[R1]
				MOV		M[IO_WRITE], R2
				CALL	next_col
				CMP		R3, 0003h
				BR.NZ   linechange
				MOV		R3, R0
				CALL	prev_col
				CALL	prev_col
				CALL	prev_col
				CALL	next_line
linechange:		INC		R3
				INC		R1
				CMP		R2, R0
				BR.NZ	k
				
				POP		R3
				POP		R2
				POP		R1
				
				RET
				
desenha_banana:	PUSH	R1
				PUSH	R2
				PUSH	R3
				PUSH	R4
				
				MOV		R1, M[SP + 7]
				MOV		R2, M[SP + 6]
				
				MOV		R3, 0018h
				SUB		R3, R2
		
				SHL 	R3, 8
				ADD		R1, R3
		
				MOV		R2, M[last_pos]
				MOV		R3, ' '
				MOV		M[IO_CONTROL], R2
				MOV		M[IO_WRITE], R3
				MOV		M[last_pos], R1
		
				MOV		M[IO_CONTROL], R1
				
				PUSH	R1
				
				PUSH	M[x1]
				PUSH	M[y1]
				CMP		M[gorila], R0
				BR.Z 	l
				POP		R1
				POP		R1
				
				PUSH	M[x0]
				PUSH	M[y0]
l:				CALL	hit
		
				MOV		R1, 'B'
				MOV		M[IO_WRITE], R1
				
				POP		R4
				POP		R3
				POP		R2
				POP		R1
				
				RET
			
				
hit:			MOV		R1, M[SP + 4]	;IO_CONTROL	x e y
				MOV		R2, M[SP + 3]	;x1 / x0
				MOV		R4, M[SP + 2]	;y1 / y0
				
				MOV		R3, 0018h
				SUB		R3, R4
				SHL		R3, 8
				ADD		R2, R3			;IO_CONTROL x1 / x0 e y1 / y0
				SUB		R2, 0101h
				CMP		R2, R1
				JMP.Z	score
				ADD		R2, 0001h
				CMP		R2, R1
				JMP.Z	score
				ADD		R2, 0001h
				CMP		R2, R1
				JMP.Z	score
				SUB		R2, 0002h
				ADD		R2, 0100h
				CMP		R2, R1
				JMP.Z	score
				ADD		R2, 0001h
				CMP		R2, R1
				JMP.Z	score
				ADD		R2, 0001h
				CMP		R2, R1
				JMP.Z	score
				SUB		R2, 0002h
				ADD		R2, 0100h
				CMP		R2, R1
				JMP.Z	score
				ADD		R2, 0001h
				CMP		R2, R1
				JMP.Z	score
				ADD		R2, 0001h
				CMP		R2, R1
				JMP.Z	score
				
				RETN	3
				
score:			CMP		M[gorila], R0
				BR.Z	fim_x
				MOV		R2, M[score_1]
				INC		R2
				MOV		M[score_1], R2
				JMP		fim_a
fim_x:			MOV		R2, M[score_0]
				INC		R2
				MOV		M[score_0], R2
				
fim_a:			MOV		R1, SCORE
				MOV		R2, M[score_0]
				MOV		R3, M[score_1]
				ADD		R2, 0030h
				ADD		R3, 0030h
				MOV		M[IO_CONTROL], R1
				MOV		M[CURSOR], R1
				MOV		M[IO_WRITE], R2
				CALL	next_col
				MOV		R1, '-'
				MOV		M[IO_WRITE], R1
				CALL	next_col
				MOV		M[IO_WRITE], R3	
				
				MOV		R1, 0002h
				CMP		R1, M[score_0]
				BR.Z	fim_b
				CMP		R1, M[score_1]
				BR.Z	fim_b
				BR		fim_c
fim_b:			MOV		R1, 0001h
				MOV		M[max_score], R1
				JMP		missed
				
fim_c:			MOV		R1, 0A19h
				MOV		M[IO_CONTROL], R1
				MOV		M[CURSOR], R1
				
				PUSH	txt_3
				CALL	escreve_msg
				
				CALL	random
				
				MOV		R1, 0A19h
				MOV		M[IO_CONTROL], R1
				MOV		M[CURSOR], R1
				
				PUSH	limpa_3
				CALL	escreve_msg
				
				JMP		inicio

random:			PUSH	R1
				PUSH	R2
				PUSH	R3
				PUSH	R4
				PUSH	R5
random1:		INC		R1
				INC		R2
				INC		R2
				CMP		R0, M[IO_READ]
				JMP.Z	random1
				MOV		R3, R1
				MOV		R4, R2
				MOV		R5, 000Ah
				SHR		R1, 8
				SHR		R2, 8
				SHL		R3, 8
				SHR		R3, 8
				SHL		R4, 8
				SHR		R4, 8
				
				
				DIV		R1, R5
				ADD		R5, 0002h
				MOV		M[ran_1], R5
				
				MOV		R5, 0009h				
				DIV		R2, R5
				MOV		R1, 0050h
				SUB		R1, R5
				SUB		R1, 0003h
				MOV		M[ran_2], R1
				
				MOV		R5, 0009h				
				DIV		R3, R5
				ADD		R5, 0002h
				MOV		M[ran_3], R5
				
				MOV		R5, 0009h				
				DIV		R4, R5
				ADD		R5, 0002h
				MOV		M[ran_4], R5
				
				POP		R5
				POP		R4
				POP		R3
				POP		R2
				POP		R1
				RET

	
ROT_TIMER:	MOV		R1, 0001h
			MOV		M[FLAG], R1
			RTI			