
// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.

%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "tabela_simbolos.h"

int num_vars_tipo = 0;
int num_vars = 0;
int deslocamento = 0;
int nivel_lexico = 0;
int num_rotulos = 0;

int ivar = 0;
int tipoOP = 0;
int num_ident;
int quant_fator = 0;
int tipo_fator;
procedimento_t procedimento;

tabela_simbolos_t tabela;
pilha_t pilha_tipos;
pilha_t pilha_simbolos;
pilha_t rotulos;
%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO
%token LABEL PROCEDURE FUNCTION OF TYPE
%token TRUE FALSE IF THEN ELSE WHILE DO GOTO
%token READ WRITE OR AND NOT
%token SOMA SUBT MULT DIVI
%token MENOR MAIOR IGUAL MENORI MAIORI
%token INTEGER BOOLEAN ARRAY NUM DIFERENTE ASPAS ASPASDUPLAS

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%%

programa:
   {
      geraCodigo(NULL, "INPP");
   }
   PROGRAM IDENT
   ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
   bloco PONTO
{
   char comando[100];
   int n_vars = quantVariaveis(tabela, nivel_lexico);
   if (n_vars > 0) {
      sprintf(comando, "DMEM %d", n_vars);
      geraCodigo(NULL, comando);
   }

   geraCodigo(NULL, "PARA");
   imprime(tabela);
}
;

/*-----------------------------------------------------------------------*
* Variáveis                                                              
*------------------------------------------------------------------------*/
bloco:
   definicoes_bloco comando_composto
;

definicoes_bloco:
   parte_declara_rotulos
   parte_define_tipos
   parte_declara_vars
   parte_declara_sub_rotinas
;

parte_declara_rotulos:
   LABEL labels PONTO_E_VIRGULA
   |
;

labels:
   labels VIRGULA NUM
   | NUM
;

parte_define_tipos:
   TYPE types PONTO_E_VIRGULA
   |
;

types:
   types PONTO_E_VIRGULA definicao_tipo
   | definicao_tipo
;

definicao_tipo:
   IDENT IGUAL tipo
;

parte_declara_sub_rotinas:
{
   nivel_lexico++;
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha(rotulo, &pilha_simbolos);

   char comando[100];
   sprintf(comando, "DSVS %s", rotulo);
   geraCodigo(NULL, comando);
} 
   declara_sub_rotinas
{
   char *rotulo = desempilha(&pilha_simbolos);
   geraCodigo(rotulo, "NADA");
   nivel_lexico--;
}
   |
;

declara_sub_rotinas:
  declara_sub_rotinas declara_sub_rotina PONTO_E_VIRGULA
  | declara_sub_rotina PONTO_E_VIRGULA
;

declara_sub_rotina:
   declaracao_procedure
{
   char comando[100];
   int n_vars = quantVariaveis(tabela, nivel_lexico);
   if (n_vars > 0) {
      sprintf(comando, "DMEM %d", n_vars);
      geraCodigo(NULL, comando);
   }

   char *p = desempilha(&pilha_simbolos);
   simbolo_t s = buscaSimbolo(tabela, p);
   int sub_rotinas = quantSubRotinas(tabela, nivel_lexico);

   sprintf(comando, "RTPR %d,%d", nivel_lexico, s.proc.num_param);
   geraCodigo(NULL, comando);
   retira(&tabela, s.proc.num_param + n_vars + sub_rotinas);
}
   | declaracao_function
;



parte_declara_vars:
   var
{
   char comando[100];
   int num_vars = quantVariaveis(tabela, nivel_lexico);
   sprintf(comando, "AMEM %d", num_vars);
   geraCodigo(NULL, comando);
}
   |
;

var: 
   VAR declara_vars
;

declara_vars: 
   declara_vars declara_var
   | declara_var
;

declara_var:
   lista_id_var DOIS_PONTOS
   tipo { num_vars_tipo = 0; }
   PONTO_E_VIRGULA
;

tipo: 
   IDENT
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
   insereVarTabela(&tabela, token, nivel_lexico, deslocamento);
   deslocamento++;
   num_vars_tipo++;
}
   | IDENT
{
   /* insere vars na tabela de símbolos */
   insereVarTabela(&tabela, token, nivel_lexico, deslocamento);
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
;

comandos:
   comandos PONTO_E_VIRGULA comando_sem_rotulo
   | comando_sem_rotulo
;

comando_sem_rotulo:
   comando_com_ident
   | comando_repetitivo 
   | comando_condicional
   | comando_composto
   | write 
   | read
   |
;

comando_com_ident:
   IDENT 
{
   empilha(token, &pilha_simbolos);
}
   atr_proc
;

atr_proc:
   atribuicao
   | chamada_procedimento
;

comando_repetitivo:
   WHILE
{
   char rotulo[100];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha(rotulo, &pilha_simbolos);
   geraCodigo(rotulo, "NADA");

   tipoOP = PADRAO;
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
   DO comando_sem_rotulo
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
   if_then if_else 
{
   char *rotulo = desempilha(&pilha_simbolos);
   geraCodigo(rotulo, "NADA");
}
;

if_then:
   IF {tipoOP = PADRAO;} expressao
{
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha(rotulo, &pilha_simbolos);

   char comando[100];
   sprintf(comando, "DSVF %s", rotulo);
   geraCodigo(NULL, comando);
}
   THEN comando_sem_rotulo

if_else:
   ELSE 
{
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);

   char comando[100];
   sprintf(comando, "DSVS %s", rotulo);
   geraCodigo(NULL, comando);

   char *rotElse = desempilha(&pilha_simbolos);

   geraCodigo(rotElse, "NADA");

   empilha(rotulo, &pilha_simbolos);
}
   comando_sem_rotulo
   | %prec LOWER_THAN_ELSE
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

   sprintf(comando, "ARMZ %d,%d", var.nivel, var.var.deslocamento);
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

   simbolo_t simbolo = buscaSimbolo(tabela, token);
   if (simbolo.tipo == PARAMETRO_FORMAL && simbolo.param.passagem == REFERENCIA) {
      sprintf(comando, "CRVI %d,%d", simbolo.nivel, simbolo.var.deslocamento);
   }
   else {
      sprintf(comando, "CRVL %d,%d", simbolo.nivel, simbolo.var.deslocamento);
   }
   geraCodigo(NULL, comando);
   geraCodigo(NULL, "IMPR");
}
   | NOT IDENT
{
   char comando[100];
   simbolo_t simbolo = buscaSimbolo(tabela, token);

   if (simbolo.var.tipo != BOOL)
      imprimeErro("Operação invalida.");

   if (simbolo.tipo == PARAMETRO_FORMAL && simbolo.param.passagem == REFERENCIA) {
      sprintf(comando, "CRVI %d,%d", simbolo.nivel, simbolo.var.deslocamento);
   }
   else {
      sprintf(comando, "CRVL %d,%d", simbolo.nivel, simbolo.var.deslocamento);
   }

   geraCodigo(NULL, comando);
   geraCodigo(NULL, "NEGA");
   geraCodigo(NULL, "IMPR");
}
;

declaracao_procedure:
   PROCEDURE IDENT
{
   deslocamento = 0;
   num_vars = 0;
   num_vars_tipo = 0;
   
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);

   insereProcTabela(&tabela, token, rotulo, nivel_lexico);

   char comando[100];
   sprintf(comando, "ENPR %d", nivel_lexico);
   geraCodigo(rotulo, comando);

   empilha (token, &pilha_simbolos);
}
   parametros_formais PONTO_E_VIRGULA bloco
;

declaracao_function:
   FUNCTION IDENT 
   parametros_formais DOIS_PONTOS IDENT PONTO_E_VIRGULA bloco
;

parametros_formais:
   ABRE_PARENTESES lista_parametros_formais FECHA_PARENTESES
{
   atualizaDeslocamentoParam(&tabela, nivel_lexico, num_vars);
}
   |
;

lista_parametros_formais:
   lista_parametros_formais PONTO_E_VIRGULA secao_parametros_formais
   | secao_parametros_formais
;

secao_parametros_formais:
   lista_var_formais
   | FUNCTION lista_idents_formais DOIS_PONTOS IDENT
   | PROCEDURE lista_idents_formais
   |
;

lista_var_formais:
   VAR {empilha("REF", &pilha_tipos);} lista_idents_formais DOIS_PONTOS IDENT
{
   if (strcmp(token, "integer") == 0)
      atualizaTipoParam(&tabela, INT, num_vars_tipo);
   else if (strcmp(token, "boolean") == 0)
      atualizaTipoParam(&tabela, BOOL, num_vars_tipo);
   else
      imprimeErro("Tipo de variavel não aceito.");

   num_vars_tipo = 0;
   desempilha(&pilha_tipos);
}

   | {empilha("VALOR", &pilha_tipos);} lista_idents_formais DOIS_PONTOS IDENT
{
   if (strcmp(token, "integer") == 0)
      atualizaTipoParam(&tabela, INT, num_vars_tipo);
   else if (strcmp(token, "boolean") == 0)
      atualizaTipoParam(&tabela, BOOL, num_vars_tipo);
   else
      imprimeErro("Tipo de variavel não aceito.");

   num_vars_tipo = 0;
   desempilha(&pilha_tipos);
}
;

lista_idents_formais:
   lista_idents_formais VIRGULA IDENT
{
   char *passagem = desempilha(&pilha_tipos);
   if (strcmp(passagem, "VALOR") == 0) 
      insereParamTabela(&tabela, token, nivel_lexico, VALOR);
   else if (strcmp(passagem, "REF") == 0)
      insereParamTabela(&tabela, token, nivel_lexico, REFERENCIA);

   num_vars_tipo++;
   num_vars++;

   empilha (passagem, &pilha_tipos);
}
   | IDENT
{
   char *passagem = desempilha(&pilha_tipos);
   if (strcmp(passagem, "VALOR") == 0) 
      insereParamTabela(&tabela, token, nivel_lexico, VALOR);

   else if (strcmp(passagem, "REF") == 0)
      insereParamTabela(&tabela, token, nivel_lexico, REFERENCIA);

   num_vars_tipo++;
   num_vars++;

   empilha (passagem, &pilha_tipos);
}
;

chamada_procedimento:
{
   tipoOP = PROC;
   ivar = 0;
   quant_fator = 0;
   char *ident = desempilha(&pilha_simbolos);
   simbolo_t simb = buscaSimbolo(tabela, ident);   
   procedimento = simb.proc;
}
   chamada_parametros
{
   if (ivar != procedimento.num_param)
      imprimeErro ("Parametros invalidos.");

   char comando[100];
   sprintf(comando, "CHPR %s,%d", procedimento.rotulo, nivel_lexico);
   geraCodigo (NULL, comando);
}
;

chamada_parametros:
   ABRE_PARENTESES lista_espressoes FECHA_PARENTESES
   |
;

lista_espressoes:
   espressoes
   |
;

espressoes:
   espressoes VIRGULA expressao 
{
   char *tipo = desempilha(&pilha_tipos);
   if (procedimento.passagem_param[ivar] == REFERENCIA) {
      if (tipo_fator != F_IDENT || quant_fator > 1)
         imprimeErro ("Parametro invalido.");
   }

   int tipoExp;
   if (strcmp(tipo, "INT") == 0)
      tipoExp = INT;
   else if (strcmp(tipo, "BOOL") == 0)
      tipoExp = BOOL;

   if (tipoExp != procedimento.tipo_param[ivar])
      imprimeErro("Parametro invalido.");

   quant_fator = 0;
   ivar++;
}
   | expressao
{
   char *tipo = desempilha(&pilha_tipos);
   if (procedimento.passagem_param[ivar] == REFERENCIA) {
      if (tipo_fator != F_IDENT || quant_fator > 1)
         imprimeErro ("Parametro invalido.");
   }

   int tipoExp;
   if (strcmp(tipo, "INT") == 0)
      tipoExp = INT;
   else if (strcmp(tipo, "BOOL") == 0)
      tipoExp = BOOL;

   if (tipoExp != procedimento.tipo_param[ivar])
      imprimeErro("Parametro invalido.");

   quant_fator = 0;
   ivar++;
}
;


/*-----------------------------------------------------------------------*
* Atribuição
*------------------------------------------------------------------------*/
atribuicao:
   ATRIBUICAO {tipoOP = PADRAO;} expressao
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

   if (var.tipo == PARAMETRO_FORMAL && var.param.passagem == REFERENCIA) {
      sprintf(comando, "ARMI %d,%d", var.nivel, var.var.deslocamento);
   }
   else {
      sprintf(comando, "ARMZ %d,%d", var.nivel, var.var.deslocamento);
   }
   geraCodigo(NULL, comando);
}
;

/*-----------------------------------------------------------------------*
* Expressões
*------------------------------------------------------------------------*/
expressao:
   expressao_simples operacao_booleana expressao_simples
{
   validaTipos(&pilha_tipos, INT);

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
   expressao_simples SOMA termo { validaTipos(&pilha_tipos, INT); geraCodigo(NULL, "SOMA"); empilha("INT", &pilha_tipos); }
   | expressao_simples SUBT termo { validaTipos(&pilha_tipos, INT); geraCodigo(NULL, "SUBT"); empilha("INT", &pilha_tipos); }
   | expressao_simples OR termo { validaTipos(&pilha_tipos, BOOL); geraCodigo(NULL, "DISJ"); empilha("BOOL", &pilha_tipos); }
   | termo
;


termo:
   fator
   | termo MULT fator { validaTipos(&pilha_tipos, INT); geraCodigo(NULL, "MULT"); empilha("INT", &pilha_tipos); }
   | termo DIVI fator { validaTipos(&pilha_tipos, INT); geraCodigo(NULL, "DIVI"); empilha("INT", &pilha_tipos); }
   | termo AND fator { validaTipos(&pilha_tipos, BOOL); geraCodigo(NULL, "CONJ"); empilha("BOOL", &pilha_tipos); }
;

fator:
   NUM          {empilhaNUM(token, &pilha_tipos); quant_fator++; tipo_fator = F_NUM;}
   | SUBT NUM   {empilhaNUM(token, &pilha_tipos); geraCodigo(NULL, "INVR"); quant_fator++; tipo_fator = F_NUM;}
   | SOMA NUM   {empilhaNUM(token, &pilha_tipos); quant_fator++; tipo_fator = F_NUM;}
   | IDENT      {empilhaIDENT(token, ivar, ++quant_fator, tipoOP, procedimento, &pilha_tipos, tabela); tipo_fator = F_IDENT;}
   | SUBT IDENT {empilhaIDENT(token, ivar, ++quant_fator, tipoOP, procedimento, &pilha_tipos, tabela); geraCodigo(NULL, "INVR"); tipo_fator = F_IDENT;}
   | SOMA IDENT {empilhaIDENT(token, ivar, ++quant_fator, tipoOP, procedimento, &pilha_tipos, tabela); tipo_fator = F_IDENT;}
   | ABRE_PARENTESES expressao FECHA_PARENTESES
   | NOT fator
{
   quant_fator++;
   char *fator = desempilha(&pilha_tipos);

   if (strcmp(fator, "BOOL") != 0)
      imprimeErro("Atribuição inválida.");

   geraCodigo(NULL, "NEGA");

   empilha("BOOL", &pilha_tipos);
}
   | true_false {tipo_fator = F_BOOL;}
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