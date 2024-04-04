
// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.

%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "tabela_simbolos.h"

int num_vars_tipo = 0;
int deslocamento = 0;
int nivel_lexico = 0;
int num_rotulos = 0;

tabela_simbolos_t tabela;
pilha_t pilha_tipos;
pilha_t pilha_simbolos;
pilha_t rotulos;
%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token LABEL PROCEDURE FUNCTION OF
%token TRUE FALSE IF THEN ELSE WHILE DO GOTO
%token READ WRITE OR AND NOT
%token SOMA SUBT MULT DIVI
%token MENOR MAIOR IGUAL MENORI MAIORI
%token INTEGER BOOLEAN ARRAY NUM DIFERENTE ASPAS ASPASDUPLAS
%%

programa:
   {
      geraCodigo(NULL, "INPP");
   }
   PROGRAM IDENT
   ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
   bloco PONTO
   {
      geraCodigo(NULL, "PARA");
      imprime(tabela);
   }
;

/*-----------------------------------------------------------------------*
* Variáveis                                                              
*------------------------------------------------------------------------*/
bloco:
   parte_declara_vars
   {
      char comando[100];
      int num_vars = quantVariaveis(tabela, nivel_lexico);
      sprintf(comando, "AMEM %d", num_vars);
      geraCodigo(NULL, comando);
   }
   comando_composto
;

parte_declara_vars:
   var
;

var: VAR declara_vars
   |
;

declara_vars: declara_vars declara_var
   | declara_var
;

declara_var:
   lista_id_var DOIS_PONTOS
   tipo { num_vars_tipo = 0; }
   PONTO_E_VIRGULA
;

tipo: IDENT
{
   if (strcmp(token, "integer") == 0)
      atualizaTipoVar(&tabela, INT, num_vars_tipo);
   else if (strcmp(token, "boolean") == 0)
      atualizaTipoVar(&tabela, BOOL, num_vars_tipo);
   else
      imprimeErro("Tipo de variavel não aceito.");
}
;

lista_id_var:
   lista_id_var VIRGULA IDENT
   { /* insere última vars na tabela de símbolos */
      insereVarTabela(&tabela, token, 0, deslocamento);
      deslocamento++;
      num_vars_tipo++;
   }
   | IDENT
{
   /* insere vars na tabela de símbolos */
   insereVarTabela(&tabela, token, 0, deslocamento);
   deslocamento++;
   num_vars_tipo++;
}
;

lista_idents:
   lista_idents VIRGULA IDENT
   | IDENT
;


/*-----------------------------------------------------------------------*
* Comandos
*------------------------------------------------------------------------*/
comando_composto:
   T_BEGIN comandos T_END
{
   char comando[100];
   int num_vars = quantVariaveis(tabela, nivel_lexico);
   sprintf(comando, "DMEM %d", num_vars);
   geraCodigo(NULL, comando);
}
;

comandos:
   comandos PONTO_E_VIRGULA comando_sem_rotulo
   | comando_sem_rotulo
;

comando_sem_rotulo:
   atribuicao 
   | comando_repetitivo
   | comando_condicional
   | write 
   | read
   |
;

comando_repetitivo:
   WHILE
{
   char rotulo[100];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha(rotulo, &pilha_simbolos);
   geraCodigo(rotulo, "NADA");
}
   expressao
{
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha(rotulo, &pilha_simbolos);

   char comando[100];
   sprintf(comando, "DSVF %s", rotulo);
   geraCodigo(NULL, comando);
}
   DO T_BEGIN comandos T_END
{
   char *rotEnd = desempilha(&pilha_simbolos);
   char *rotWhile = desempilha(&pilha_simbolos);

   char comando[100];

   sprintf(comando, "DSVS %s", rotWhile);
   geraCodigo(NULL, comando);

   geraCodigo(rotEnd, "NADA");
}
;

comando_condicional:
   IF expressao
{
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha(rotulo, &pilha_simbolos);

   char comando[100];
   sprintf(comando, "DSVF %s", rotulo);
   geraCodigo(NULL, comando);
} 
   THEN comando_sem_rotulo
{
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha(rotulo, &pilha_simbolos);

   char comando[100];
   sprintf(comando, "DSVS %s", rotulo);
   geraCodigo(NULL, comando);
}
   ELSE 
{
   char *rotEnd = desempilha(&pilha_simbolos);
   char *rotThen = desempilha(&pilha_simbolos);

   geraCodigo(rotThen, "NADA");

   empilha(rotEnd, &pilha_simbolos);
}
   comando_sem_rotulo
{
   char *rotEnd = desempilha(&pilha_simbolos);
   geraCodigo(rotEnd, "NADA");
}
   | IF expressao 
{
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha(rotulo, &pilha_simbolos);

   char comando[100];
   sprintf(comando, "DSVF %s", rotulo);
   geraCodigo(NULL, comando);
}
   THEN comando_sem_rotulo
{
   char *rotEnd = desempilha(&pilha_simbolos);
   geraCodigo(rotEnd, "NADA");
}
;

read:
   READ ABRE_PARENTESES lista_read FECHA_PARENTESES
;

lista_read:
   lista_read VIRGULA termo_read
   | termo_read
;

termo_read:
   IDENT
{
   geraCodigo(NULL, "LEIT");

   char comando[100];
   simbolo_t var = buscaSimbolo(tabela, token);

   sprintf(comando, "ARMZ %d,%d", var.var.nivel, var.var.deslocamento);
   geraCodigo(NULL, comando);
}
;

write:
   WRITE ABRE_PARENTESES lista_write FECHA_PARENTESES 
   | WRITE ABRE_PARENTESES FECHA_PARENTESES 
;

lista_write:
   lista_write VIRGULA termo_write
   | termo_write
;

termo_write:
   NUM
{
   char comando[100];
   sprintf(comando, "CRCT %s", token);
   geraCodigo(NULL, comando);
   geraCodigo(NULL, "IMPR");
}
   | IDENT
{
   char comando[100];

   simbolo_t var = buscaSimbolo(tabela, token);

   sprintf(comando, "CRVL %d,%d", var.var.nivel, var.var.deslocamento);
   geraCodigo(NULL, comando);
   geraCodigo(NULL, "IMPR");
}
   | NOT IDENT
{
   char comando[100];
   simbolo_t var = buscaSimbolo(tabela, token);

   if (var.var.tipo != BOOL)
      imprimeErro("Operação invalida.");

   sprintf(comando, "CRVL %d,%d", var.var.nivel, var.var.deslocamento);

   geraCodigo(NULL, comando);
   geraCodigo(NULL, "NEGA");
   geraCodigo(NULL, "IMPR");
}
;


/*-----------------------------------------------------------------------*
* Atribuição
*------------------------------------------------------------------------*/
atribuicao:
   IDENT
{
   empilha(token, &pilha_simbolos);
}
   ATRIBUICAO expressao
{
   char comando[100];

   char *exp = desempilha(&pilha_tipos);
   char *destino = desempilha(&pilha_simbolos);

   simbolo_t var = buscaSimbolo(tabela, destino);

   int tipoExp;
   if (strcmp(exp, "INT") == 0)
      tipoExp = INT;
   else if (strcmp(exp, "BOOL") == 0)
      tipoExp = BOOL;

   if (var.var.tipo != tipoExp)
      imprimeErro("Atribuição inválida.");

   sprintf(comando, "ARMZ %d,%d", var.var.nivel, var.var.deslocamento);
   geraCodigo(NULL, comando);
}
;

/*-----------------------------------------------------------------------*
* Expressões
*------------------------------------------------------------------------*/
expressao:
   expressao_simples operacao_booleana expressao_simples
{
   validaTipos(&pilha_tipos, tabela, INT);

   char *comando = desempilha(&pilha_simbolos);
   geraCodigo(NULL, comando);

   empilha("BOOL", &pilha_tipos);
}
   | expressao_simples
;

operacao_booleana:
   IGUAL { empilha("CMIG", &pilha_simbolos); }
   | DIFERENTE { empilha("CMDG", &pilha_simbolos); }
   | MENOR { empilha("CMME", &pilha_simbolos); }
   | MAIOR { empilha("CMMA", &pilha_simbolos); }
   | MENORI { empilha("CMEG", &pilha_simbolos); }
   | MAIORI { empilha("CMAG", &pilha_simbolos); }
;

expressao_simples:
   expressao_simples SOMA termo { validaTipos(&pilha_tipos, tabela, INT); geraCodigo(NULL, "SOMA"); empilha("INT", &pilha_tipos); }
   | expressao_simples SUBT termo { validaTipos(&pilha_tipos, tabela, INT); geraCodigo(NULL, "SUBT"); empilha("INT", &pilha_tipos); }
   | expressao_simples OR termo { validaTipos(&pilha_tipos, tabela, BOOL); geraCodigo(NULL, "DISJ"); empilha("BOOL", &pilha_tipos); }
   | SUBT termo {
      geraCodigo(NULL, "INVR");
   }
   | SOMA termo
   | termo
;

termo:
   fator
   | fator MULT fator { validaTipos(&pilha_tipos, tabela, INT); geraCodigo(NULL, "MULT"); empilha("INT", &pilha_tipos); }
   | fator DIVI fator { validaTipos(&pilha_tipos, tabela, INT); geraCodigo(NULL, "DIVI"); empilha("INT", &pilha_tipos); }
   | fator AND fator { validaTipos(&pilha_tipos, tabela, BOOL); geraCodigo(NULL, "CONJ"); empilha("BOOL", &pilha_tipos); }
;

fator:
   NUM
{
   char comando[100];
   sprintf(comando, "CRCT %s", token);
   geraCodigo(NULL, comando);

   empilha("INT", &pilha_tipos);
}
   | IDENT
{
   char comando[100];
   simbolo_t var = buscaSimbolo(tabela, token);

   sprintf(comando, "CRVL %d,%d", var.var.nivel, var.var.deslocamento);
   geraCodigo(NULL, comando);

   if (var.var.tipo == INT)
      empilha("INT", &pilha_tipos);
   else
      empilha("BOOL", &pilha_tipos);
}
   | ABRE_PARENTESES expressao FECHA_PARENTESES
   | NOT fator
{
   char *fator = desempilha(&pilha_tipos);

   if (strcmp(fator, "BOOL") != 0)
      imprimeErro("Atribuição inválida.");

   geraCodigo(NULL, "NEGA");

   empilha("BOOL", &pilha_tipos);
}
   | true_false
;

true_false:
   TRUE
{
   geraCodigo(NULL, "CRCT 1");
   empilha("BOOL", &pilha_tipos);
}
   | FALSE
{
   geraCodigo(NULL, "CRCT 0");
   empilha("BOOL", &pilha_tipos);
}
%%

int main(int argc, char **argv)
{
   FILE *fp;
   extern FILE *yyin;

   if (argc < 2 || argc > 2)
   {
      printf("usage compilador <arq>a %d\n", argc);
      return (-1);
   }

   fp = fopen(argv[1], "r");
   if (fp == NULL)
   {
      printf("usage compilador <arq>b\n");
      return (-1);
   }

   /* -------------------------------------------------------------------
   *  Inicializa estruturas
   * ------------------------------------------------------------------- */
   inicializa_tabela(&tabela);
   inicializa_pilha(&pilha_simbolos);
   inicializa_pilha(&pilha_tipos);
   inicializa_pilha(&rotulos);

   yyin = fp;
   yyparse();

   return 0;
}
