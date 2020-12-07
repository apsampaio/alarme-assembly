;===============================================================================
; Fatec Sorocaba
;
; Eletrônica Automotiva
; PIC 16F877A
; Clock 4MHz
;
; demo IDE MPLABx v 2.15v - Assembly Linguagem
;
; Baseado no Hardware da PCI Placa Mini Didativa V 0.1
;
; Princípio de operação das rotinas : Timer via SW (300mS)
;                                     Timer HW (Timer 0)
;                                     Timer 0 com interrupção
;===============================================================================
;
; Detalhes do hardware: O latch 74LS573 passa o dado do PORTD para os Leds, o pino
;                       de controle do latch correspondente é controlado pelo pino
;                       RE2 (LED-LE) Que deve ser mantido em nivel 1.
;                       Os CD4511 acionam os display de 7seg que também esta
;                       pino de controle desses latchas: PORTE pino RE1.
;                       Deve ser mantido baixo para escrever nos display de LED.
;
; Display LCD : C3 = RS
;               C4 = E
;               Dados = PORTD ( sem latch)
;==========================PIC Escolhido========================================
;
#include <P16F877A.inc>   ;Arquivo padrão MC p/ UCP PIC16F877A
;
;===============================================================================
 __CONFIG _HS_OSC & _WDT_OFF
;
;===============================================================================
;
#DEFINE BANK0 BCF STATUS,RP0 ;seta bank 0 de memória
#DEFINE BANK1 BSF STATUS,RP0 ;seta bank 1 de memória
;
        cblock 0X20                  ;end.incial mem.usuário
                cont
                cont0                ;contador 0
                cont1                ;contador 1
                cont2                ;contador 2
                cont3                ;contador 3
                flags                ;registrador de flags de uso geral
                aux1                 ;reg auxiliar 1
                aux2                 ;reg auxiliar 2
                aux3                 ;reg auxiliar 3
                Conta1
                Conta2
                Conta3
        endc                             ;fim do bloco de memória
;
;=========================Define entradas e saidas==============================
;
#DEFINE LEDATIVADO    PORTD,0         ;LED de Alarme ATIVADO
#DEFINE LEDSIRENE     PORTD,1         ;LED simulando SIRENE
#DEFINE LEDACIONADO   PORTD,2         ;LED DE Alarme ACIONADO
#DEFINE B0            PORTB,0         ;Botão ativa alarme
#DEFINE B1            PORTB,1         ;Botão desativa alarme
#DEFINE SENSOR        PORTB,2         ;Botão simulando SENSOR
#DEFINE LATCHDISPLAY  PORTE,1         ;LATCH (1 = DISPLAY NÃO MUDA/ 0 = DISPLAY MUDA)
#DEFINE LATCHLED      PORTE,2         ;LATCH (0 = LED NÃO MUDA / 1 = LED MUDA)
;
;===============================Vetor de Reset==================================
;
        ORG 0x00            ;end. incial de proc.
        goto            configura
;
;==============================Inicio da Interrupção============================
;
        ORG 0x04             ;vetor de atendimento a interrupção
        retfie
;===============================================================================
;
;                               INICIALIZAÇÃO
;
;===============================================================================
;
;inicialização dos REGs internos
;
  configura
            BANK1
                  movlw b'11111111'     ;todas entradas
                  movwf TRISA           ;PORT onde estão entradas analogicas
                  movlw b'00011111'
                  movwf TRISB           ;PORT onde estão as chaves
                  movlw b'00000000'     ;1 = entrada, 0 = saida
                  movwf TRISC
                  movlw b'00000000'     ;todas saidas(porta do LED)
                  movwf TRISD
                  movlw b'00000000'     ;todas saidas(porta do stroube com PSP=1)
                  movwf TRISE
                  movlw b'01000111'
                  movwf OPTION_REG
                  movlw b'00000000'
                  movwf INTCON          ;todas interrupções desabilitadas
                  bcf   TRISE,4         ;PORTD normal (não PSP)]
           BANK0
                  clrf aux1
                  clrf aux1
;===============================================================================
;Zera display e LEDs
    ZeraDeL
                 bsf LATCHDISPLAY
                 bsf LATCHLED
                 movlw b'11111111' ;Zera led
                 movwf PORTD
                 bcf LATCHDISPLAY
                 bcf LATCHLED
                 movlw b'00000000' ;Zera display
                 movwf PORTD
                 bsf LATCHDISPLAY
                 clrf Conta1
                 clrf Conta2
                 clrf Conta3
;===============================================================================
;Testa botão de acionamento
  b_liga         btfss B0       ;Testa botão que liga alarme
                 goto $-1
                 goto Conta9    ;Vai para Conta9
;===============================================================================
;Sinalização de Alarme
    Alarme
                btfss Conta1
                goto $+2
                goto $+7
                bsf LATCHLED
                bcf LEDATIVADO  ;Liga led de Alarme Ativado
                bcf LATCHLED
                movlw .1
                movwf Conta1

                btfss Conta2
                goto $+2
                goto $+8
                btfsc B1
                goto ZeraDeL
                btfss SENSOR    ;Testa botão que simula Sensor
                goto $-3
                movlw .1
                movwf Conta2
                goto Conta9     ;Vai para Conta9

                btfss Conta3
                goto $+2
                goto $+6
                bsf LATCHLED
                bcf LEDSIRENE   ;Liga led que simula Sirene
                bcf LEDACIONADO ;Liga led de alarme acionado
                movlw .1
                movwf Conta3
                goto Conta9     ;Vai para Conta9
                goto ZeraDeL    ;Volta para o zerador


;===============================================================================
;Tempo repetido 20x para somar 1s
        tempo
                 movlw .61          ;Tempo de 50mS
                 movwf TMR0

                 bcf INTCON, TMR0IF    ;Limpa a flag do timer0
                 btfss INTCON, TMR0IF  ;testa a flag do timer0
                 goto $-1

                 return
;===============================================================================
;Conta 9 segundos
    Conta9
                 movlw .20
                 movwf aux1
                 bcf LATCHDISPLAY

                 movlw .9           ;Move 9 pro display
                 movwf PORTD
                 call tempo         ;Chama tempo
                 decfsz aux1
                 goto $-1
                 decf PORTD         ;Decrementa do display
                 btfsc B1
                 goto ZeraDeL

                 bcf STATUS,Z       ;Limpa flag Z
                 movlw b'00000000'  ;Move 0 pro Work
                 xorwf PORTD,w      ;Testa se o PORTD = 0
                 btfss STATUS,Z     ;Testa se a conta deu 0
                 goto $-11
                 bsf LATCHDISPLAY
                 movlw b'11111111'  ;Move '11111111' para desligar leds
                 movwf PORTD
                 goto Alarme
;===============================================================================
;
;===============================================================================
end