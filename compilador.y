
// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"
#include "tabela_simbolos.h"
#include "pilha.h"


int num_vars_comando = 0;
int num_vars_tipo = 0;
int deslocamento = 0;

tabela_simbolos_t tabela;
pilha_t pilha;


%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token LABEL PROCEDURE FUNCTION OF
%token TRUE FALSE IF THEN ELSE WHILE DO GOTO
%token READ WRITE OR AND NOT
%token SOMA SUBT MULT DIVI
%token MENOR MAIOR IGUAL MENORI MAIORI
%token INTEGER BOOLEAN ARRAY NUM DIFERENTE

%%

programa    :{
             geraCodigo (NULL, "INPP");
             }
             PROGRAM IDENT
             ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
             bloco PONTO {
             geraCodigo (NULL, "PARA");
             imprime(tabela);
             }
;

bloco       :
              parte_declara_vars
              {
              }

              comando_composto
              ;




parte_declara_vars:  var
;


var         : { } VAR declara_vars
            |
;

declara_vars: declara_vars declara_var
            | declara_var
;

declara_var : { }
              lista_id_var DOIS_PONTOS
              tipo
              {
               char comando[100];
               sprintf(comando, "AMEM %d", num_vars_tipo);
               geraCodigo (NULL, comando);
               num_vars_tipo = 0;
              }
              PONTO_E_VIRGULA
;

tipo        : IDENT 
               {
                  if (strcmp(token, "integer") == 0)
                     atualizaTipoVar (&tabela, INT, num_vars_tipo);
                  else if (strcmp(token, "boolean") == 0)
                     atualizaTipoVar (&tabela, BOOL, num_vars_tipo);
                  else
                     imprimeErro ("Tipo de variavel não aceito.");
               }
;

lista_id_var: lista_id_var VIRGULA IDENT
              { /* insere �ltima vars na tabela de s�mbolos */ 
                  insereVarTabela (&tabela, token, 0, deslocamento);
                  deslocamento++;
                  num_vars_tipo++;
                  num_vars_comando++;
              }
            | IDENT 
               { /* insere vars na tabela de s�mbolos */
                  insereVarTabela (&tabela, token, 0, deslocamento);
                  deslocamento++;
                  num_vars_tipo++;
                  num_vars_comando++;
               }
;

lista_idents: lista_idents VIRGULA IDENT
            | IDENT
;


comando_composto: T_BEGIN comandos T_END 
                     {
                        char comando[100];
                        sprintf(comando, "DMEM %d", num_vars_comando);
                        geraCodigo (NULL, comando);
                        num_vars_comando = 0;
                     }
;

comandos: comandos comando_sem_rotulo |
          comando_sem_rotulo
;

comando_sem_rotulo: atribuicao
;

atribuicao: IDENT
               {
                  empilha (token, &pilha);
               } 
            ATRIBUICAO expressao 
               {
                  char comando[100];
                  char *destino = desempilha (&pilha);

                  simbolo_t var = busca (tabela, destino);

                  if (var.var.tipo != INT)
                     imprimeErro ("Atribuição inválida.");
                     
                  sprintf(comando, "ARMZ %d,%d", var.var.nivel, var.var.deslocamento);
                  geraCodigo (NULL, comando);
               }
            PONTO_E_VIRGULA
;

expressao: expressao operacao_boleana expressao_simples |
           expressao_simples

operacao_boleana: IGUAL | DIFERENTE | MENOR | MAIOR | MENORI | MAIORI
;

expressao_simples: expressao_simples operacao_inteira fator
                     {
                        char *op = desempilha (&pilha);
                        geraCodigo (NULL, op);
                     }
                   |
                   fator 
;

operacao_inteira: SOMA {empilha ("SOMA", &pilha);} |
                  SUBT {empilha ("SUBT", &pilha);} |
                  DIVI {empilha ("DIVI", &pilha);} |
                  MULT {empilha ("MULT", &pilha);}
;

fator: NUM
         {
            char comando[100];
            sprintf(comando, "CRCT %s", token);
            geraCodigo (NULL, comando);
         }
      | IDENT
         {
            char comando[100];
            simbolo_t var = busca (tabela, token);

            sprintf(comando, "CRVL %d,%d", var.var.nivel, var.var.deslocamento);
            geraCodigo (NULL, comando);
         }
;

%%
int main (int argc, char** argv) {
   FILE* fp;
   extern FILE* yyin;

   if (argc<2 || argc>2) {
         printf("usage compilador <arq>a %d\n", argc);
         return(-1);
      }

   fp=fopen (argv[1], "r");
   if (fp == NULL) {
      printf("usage compilador <arq>b\n");
      return(-1);
   }


/* -------------------------------------------------------------------
 *  Inicia a Tabela de S�mbolos
 * ------------------------------------------------------------------- */
   inicializa_tabela(&tabela);
   inicializa_pilha(&pilha);

   yyin=fp;
   yyparse();

   return 0;
}
