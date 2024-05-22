
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
pilha_int pilha_ivar;

int tipoOP = 0;
pilha_int pilha_tipoOP;

int quant_fator = 0;

int tipo_fator;

sub_rotina_t sub_rotina;
tabela_simbolos_t pilha_sub_rotina;

char declaraRot[TAM_TOKEN] = "";
pilha_str pilha_declaraRot;

tabela_simbolos_t tabela;
pilha_int pilha_tipos;
pilha_str pilha_simbolos;
pilha_str rotulos;
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
   printf("Pilha tipos %d\n", tamanho_pilha_int(pilha_tipos));
   printf("Pilha simbolos %d\n", tamanho_pilha_str(pilha_simbolos));
   printf("Pilha rotulos %d\n", tamanho_pilha_str(rotulos));
   printf("Pilha ivar %d\n", tamanho_pilha_int(pilha_ivar));
   printf("Pilha tipoOP %d\n", tamanho_pilha_int(pilha_tipoOP));
   printf("Pilha declaraRot %d\n", tamanho_pilha_str(pilha_declaraRot));
   printf("Pilha sub_rotina %d\n", pilha_sub_rotina.topo + 1);
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
   empilha_str(rotulo, &pilha_simbolos);

   char comando[100];
   sprintf(comando, "DSVS %s", rotulo);
   geraCodigo(NULL, comando);
} 
   declara_sub_rotinas
{
   char *rotulo = desempilha_str(&pilha_simbolos);
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

   char *p = desempilha_str(&pilha_simbolos);
   simbolo_t s = buscaSimbolo(tabela, p);
   int sub_rotinas = quantSubRotinas(tabela, nivel_lexico);

   sprintf(comando, "RTPR %d,%d", nivel_lexico, s.sub_rot.num_param);
   geraCodigo(NULL, comando);
   retira(&tabela, s.sub_rot.num_param + n_vars + sub_rotinas);
}
   | declaracao_function
{
   char comando[100];
   int n_vars = quantVariaveis(tabela, nivel_lexico);
   if (n_vars > 0) {
      sprintf(comando, "DMEM %d", n_vars);
      geraCodigo(NULL, comando);
   }

   char *f = desempilha_str(&pilha_simbolos);
   simbolo_t s = buscaSimbolo(tabela, f);
   int sub_rotinas = quantSubRotinas(tabela, nivel_lexico);

   sprintf(comando, "RTPR %d,%d", nivel_lexico, s.sub_rot.num_param);
   geraCodigo(NULL, comando);
   retira(&tabela, s.sub_rot.num_param + n_vars + sub_rotinas);
}
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
   empilha_str(token, &pilha_simbolos);
}
   atr_proc
;

atr_proc:
   atribuicao
   | chamada_sub_rotina
   |
{
   char *nome = desempilha_str(&pilha_simbolos);
   simbolo_t rotina = buscaSimbolo(tabela, nome);

   if (rotina.forma == FUNCAO) {
      geraCodigo (NULL, "AMEM 1");
   }
   else if (rotina.forma != PROCEDIMENTO)
      imprimeErro ("Operação inválida.");
   
   if (rotina.sub_rot.num_param > 0)
      imprimeErro ("Parametros inválidos.");

   char comando[100];
   sprintf(comando, "CHPR %s,%d", rotina.sub_rot.rotulo, nivel_lexico);
   geraCodigo (NULL, comando);
}
;

comando_repetitivo:
   WHILE
{
   char rotulo[100];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha_str(rotulo, &pilha_simbolos);
   geraCodigo(rotulo, "NADA");

   tipoOP = PADRAO;
}
   expressao
{
   int tipoExp = desempilha_int (&pilha_tipos);
   if (tipoExp != BOOL)
      imprimeErro ("Expressão não é booleana.");

   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha_str(rotulo, &pilha_simbolos);

   char comando[100];
   sprintf(comando, "DSVF %s", rotulo);
   geraCodigo(NULL, comando);
}
   DO comando_sem_rotulo
{
   char *rotEnd = desempilha_str(&pilha_simbolos);
   char *rotWhile = desempilha_str(&pilha_simbolos);

   char comando[100];

   sprintf(comando, "DSVS %s", rotWhile);
   geraCodigo(NULL, comando);

   geraCodigo(rotEnd, "NADA");
}
;

comando_condicional:
   if_then if_else 
{
   char *rotulo = desempilha_str(&pilha_simbolos);
   geraCodigo(rotulo, "NADA");
}
;

if_then:
   IF {tipoOP = PADRAO;} expressao
{
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);
   empilha_str(rotulo, &pilha_simbolos);

   char comando[100];
   sprintf(comando, "DSVF %s", rotulo);
   geraCodigo(NULL, comando);

   desempilha_int(&pilha_tipos);
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

   char *rotElse = desempilha_str(&pilha_simbolos);

   geraCodigo(rotElse, "NADA");

   empilha_str(rotulo, &pilha_simbolos);
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

   sprintf(comando, "ARMZ %d,%d", var.nivel, var.deslocamento);
   geraCodigo(NULL, comando);
}
;

write:
   WRITE ABRE_PARENTESES {tipoOP = PADRAO;} lista_write FECHA_PARENTESES 
   | WRITE ABRE_PARENTESES FECHA_PARENTESES 
;

lista_write:
   lista_write VIRGULA expressao {geraCodigo(NULL, "IMPR"); desempilha_int(&pilha_tipos);}
   | expressao {geraCodigo(NULL, "IMPR"); desempilha_int(&pilha_tipos);}
;

declaracao_procedure:
   PROCEDURE IDENT
{
   deslocamento = 0;
   num_vars = 0;
   num_vars_tipo = 0;
   
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);

   empilha_str(declaraRot, &pilha_declaraRot);
   strncpy(declaraRot, token, TAM_TOKEN);

   insereRotinaTabela(&tabela, token, rotulo, nivel_lexico, PROCEDIMENTO);

   char comando[100];
   sprintf(comando, "ENPR %d", nivel_lexico);
   geraCodigo(rotulo, comando);

   empilha_str (token, &pilha_simbolos);
}
   parametros_formais PONTO_E_VIRGULA bloco
{
   char *aux = desempilha_str(&pilha_declaraRot);
   strncpy(declaraRot, aux, TAM_TOKEN);
}
;

declaracao_function:
   FUNCTION IDENT 
{
   deslocamento = 0;
   num_vars = 0;
   num_vars_tipo = 0;
   
   char rotulo[50];
   sprintf(rotulo, "R%02d", num_rotulos++);

   empilha_str(declaraRot, &pilha_declaraRot);
   strncpy(declaraRot, token, TAM_TOKEN);

   insereRotinaTabela(&tabela, token, rotulo, nivel_lexico, FUNCAO);

   char comando[100];
   sprintf(comando, "ENPR %d", nivel_lexico);
   geraCodigo(rotulo, comando);

   empilha_str (token, &pilha_simbolos);
}
   parametros_formais DOIS_PONTOS IDENT
{
   if (strcmp(token, "integer") == 0)
      atualizaFunc(&tabela, INT, num_vars);
   else if (strcmp(token, "boolean") == 0)
      atualizaFunc(&tabela, BOOL, num_vars);
   else
      imprimeErro("Tipo de variavel não aceito.");
}
   PONTO_E_VIRGULA bloco
{
   char *aux = desempilha_str(&pilha_declaraRot);
   strncpy(declaraRot, aux, TAM_TOKEN);
}
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
   VAR {empilha_int(REFERENCIA, &pilha_tipos);} lista_idents_formais DOIS_PONTOS IDENT
{
   if (strcmp(token, "integer") == 0)
      atualizaTipoParam(&tabela, INT, num_vars_tipo);
   else if (strcmp(token, "boolean") == 0)
      atualizaTipoParam(&tabela, BOOL, num_vars_tipo);
   else
      imprimeErro("Tipo de variavel não aceito.");

   num_vars_tipo = 0;
   desempilha_int(&pilha_tipos);
}

   | {empilha_int(VALOR, &pilha_tipos);} lista_idents_formais DOIS_PONTOS IDENT
{
   if (strcmp(token, "integer") == 0)
      atualizaTipoParam(&tabela, INT, num_vars_tipo);
   else if (strcmp(token, "boolean") == 0)
      atualizaTipoParam(&tabela, BOOL, num_vars_tipo);
   else
      imprimeErro("Tipo de variavel não aceito.");

   num_vars_tipo = 0;
   desempilha_int(&pilha_tipos);
}
;

lista_idents_formais:
   lista_idents_formais VIRGULA IDENT
{
   int passagem = desempilha_int(&pilha_tipos);
   if (passagem == VALOR) 
      insereParamTabela(&tabela, token, nivel_lexico, VALOR);
   else if (passagem == REFERENCIA)
      insereParamTabela(&tabela, token, nivel_lexico, REFERENCIA);

   num_vars_tipo++;
   num_vars++;

   empilha_int (passagem, &pilha_tipos);
}
   | IDENT
{
   int passagem = desempilha_int(&pilha_tipos);
   if (passagem == VALOR) 
      insereParamTabela(&tabela, token, nivel_lexico, VALOR);

   else if (passagem == REFERENCIA)
      insereParamTabela(&tabela, token, nivel_lexico, REFERENCIA);

   num_vars_tipo++;
   num_vars++;

   empilha_int (passagem, &pilha_tipos);
}
;

chamada_sub_rotina:
{
   empilha_int(tipoOP, &pilha_tipoOP);
   tipoOP = SUB_ROT;

   empilha_int(ivar, &pilha_ivar);
   ivar = 0;

   quant_fator = 0;
   char *ident = desempilha_str(&pilha_simbolos);
   simbolo_t simb = buscaSimbolo(tabela, ident);   

   simbolo_t aux;
   aux.sub_rot = sub_rotina;
   inserePilha(&pilha_sub_rotina, aux);
   sub_rotina = simb.sub_rot;

   if (simb.forma == FUNCAO) {
      geraCodigo (NULL, "AMEM 1");
   }
}
   chamada_parametros
{
   if (ivar != sub_rotina.num_param)
      imprimeErro ("Parametros invalidos.");

   char comando[100];
   sprintf(comando, "CHPR %s,%d", sub_rotina.rotulo, nivel_lexico);
   geraCodigo (NULL, comando);

   ivar = desempilha_int(&pilha_ivar);
   tipoOP = desempilha_int(&pilha_tipoOP);

   simbolo_t aux = removePilha(&pilha_sub_rotina);
   sub_rotina = aux.sub_rot;
}
;

chamada_parametros:
   ABRE_PARENTESES lista_espressoes FECHA_PARENTESES
;

lista_espressoes:
   espressoes
   |
;

espressoes:
   espressoes VIRGULA expressao 
{
   int tipo = desempilha_int(&pilha_tipos);
   if (sub_rotina.passagem_param[ivar] == REFERENCIA) {
      if (tipo_fator != F_IDENT || quant_fator > 1)
         imprimeErro ("Parametro invalido.");
   }

   if (tipo != sub_rotina.tipo_param[ivar])
      imprimeErro("Parametro invalido.");

   quant_fator = 0;
   ivar++;
}
   | expressao
{
   int tipo = desempilha_int(&pilha_tipos);
   if (sub_rotina.passagem_param[ivar] == REFERENCIA) {
      if (tipo_fator != F_IDENT || quant_fator > 1)
         imprimeErro ("Parametro invalido.");
   }

   if (tipo != sub_rotina.tipo_param[ivar])
      imprimeErro("Parametro invalido.");

   quant_fator = 0;
   ivar++;
}
;


/*-----------------------------------------------------------------------*
* Atribuição
*------------------------------------------------------------------------*/
atribuicao:
   ATRIBUICAO 
{  
   tipoOP = PADRAO;
   char *destino = desempilha_str(&pilha_simbolos);
   simbolo_t var = buscaSimbolo(tabela, destino);
   if (var.forma == PROCEDIMENTO) {
      imprimeErro("Operação não permitida (deveria ser uma função).");
   }

   if ((var.forma == FUNCAO) && (strcmp(destino, declaraRot) != 0) && (var.nivel > nivel_lexico))
      imprimeErro("Atribuição inválida.");

   empilha_str(destino, &pilha_simbolos);
} 
   expressao
{
   char comando[100];

   int tipoExp = desempilha_int(&pilha_tipos);
   char *destino = desempilha_str(&pilha_simbolos);

   simbolo_t var = buscaSimbolo(tabela, destino);

   if (var.tipo != tipoExp)
      imprimeErro("Atribuição inválida.");

   if (var.forma == PARAMETRO_FORMAL && var.param.passagem == REFERENCIA) {
      sprintf(comando, "ARMI %d,%d", var.nivel, var.deslocamento);
   }
   else {
      sprintf(comando, "ARMZ %d,%d", var.nivel, var.deslocamento);
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

   char *comando = desempilha_str(&pilha_simbolos);
   geraCodigo(NULL, comando);

   empilha_int(BOOL, &pilha_tipos);
}
   | expressao_simples
;

operacao_booleana:
   IGUAL { empilha_str("CMIG", &pilha_simbolos); }
   | DIFERENTE { empilha_str("CMDG", &pilha_simbolos); }
   | MENOR { empilha_str("CMME", &pilha_simbolos); }
   | MAIOR { empilha_str("CMMA", &pilha_simbolos); }
   | MENORI { empilha_str("CMEG", &pilha_simbolos); }
   | MAIORI { empilha_str("CMAG", &pilha_simbolos); }
;

expressao_simples:
   expressao_simples SOMA termo { validaTipos(&pilha_tipos, INT); geraCodigo(NULL, "SOMA"); empilha_int(INT, &pilha_tipos); }
   | expressao_simples SUBT termo { validaTipos(&pilha_tipos, INT); geraCodigo(NULL, "SUBT"); empilha_int(INT, &pilha_tipos); }
   | expressao_simples OR termo { validaTipos(&pilha_tipos, BOOL); geraCodigo(NULL, "DISJ"); empilha_int(BOOL, &pilha_tipos); }
   | termo
;


termo:
   fator
   | termo MULT fator { validaTipos(&pilha_tipos, INT); geraCodigo(NULL, "MULT"); empilha_int(INT, &pilha_tipos); }
   | termo DIVI fator { validaTipos(&pilha_tipos, INT); geraCodigo(NULL, "DIVI"); empilha_int(INT, &pilha_tipos); }
   | termo AND fator { validaTipos(&pilha_tipos, BOOL); geraCodigo(NULL, "CONJ"); empilha_int(BOOL, &pilha_tipos); }
;

fator:
   NUM          {empilhaNUM(token, &pilha_tipos); quant_fator++; tipo_fator = F_NUM;}
   | SUBT NUM   {empilhaNUM(token, &pilha_tipos); geraCodigo(NULL, "INVR"); quant_fator++; tipo_fator = F_NUM;}
   | SOMA NUM   {empilhaNUM(token, &pilha_tipos); quant_fator++; tipo_fator = F_NUM;}
   | funcao_expressao
   | SUBT funcao_expressao {geraCodigo(NULL, "INVR");}
   | SOMA funcao_expressao
   | ABRE_PARENTESES expressao FECHA_PARENTESES 
   | SOMA ABRE_PARENTESES expressao FECHA_PARENTESES
{
   int t = desempilha_int(&pilha_tipos);
   if (t != INT)
      imprimeErro("Operação inválida.");

   empilha_int(INT, &pilha_tipos);
   quant_fator++;
   tipo_fator = F_NUM;
}
   | SUBT ABRE_PARENTESES expressao FECHA_PARENTESES
{
   int t = desempilha_int(&pilha_tipos);
   if (t != INT)
      imprimeErro("Operação inválida.");

   geraCodigo(NULL, "INVR");
   empilha_int(INT, &pilha_tipos);
   quant_fator++;
   tipo_fator = F_NUM;
}
   | NOT fator
{
   quant_fator++;
   int fator = desempilha_int(&pilha_tipos);

   if (fator != BOOL)
      imprimeErro("Atribuição inválida.");

   geraCodigo(NULL, "NEGA");

   empilha_int(BOOL, &pilha_tipos);
}
   | true_false {tipo_fator = F_BOOL;}
;

true_false:
   TRUE
{
   geraCodigo(NULL, "CRCT 1");
   empilha_int(BOOL, &pilha_tipos);
}
   | FALSE
{
   geraCodigo(NULL, "CRCT 0");
   empilha_int(BOOL, &pilha_tipos);
}

funcao_expressao:
   IDENT 
{

   simbolo_t var = buscaSimbolo(tabela, token);
   quant_fator++;
   if (var.forma == FUNCAO) {
      if ((tipoOP == SUB_ROT) && (sub_rotina.passagem_param[ivar] == REFERENCIA))
         imprimeErro("Parametro inválido");
      
      empilhaFunc(var.tipo, &pilha_tipos);
      tipo_fator = F_FUNC;

      empilha_str(token, &pilha_simbolos);
   }
   else if (var.forma == VARIAVEL || var.forma == PARAMETRO_FORMAL) {
      empilhaIDENT(token, ivar, quant_fator, tipoOP, sub_rotina, &pilha_tipos, tabela);
      tipo_fator = F_IDENT;

      empilha_str(token, &pilha_simbolos);
   }
   else 
      imprimeErro ("Operação inválida");

}
   chamada_rot_exp
;

chamada_rot_exp:
   chamada_sub_rotina
   |
{
   char *nome = desempilha_str(&pilha_simbolos);
   simbolo_t rotina = buscaSimbolo(tabela, nome);
   
   if (rotina.forma == PROCEDIMENTO)
      imprimeErro ("Operação inválida.");

   if (rotina.forma == FUNCAO) {
      geraCodigo (NULL, "AMEM 1");
   
      if (rotina.sub_rot.num_param > 0)
         imprimeErro ("Parametros inválidos.");

      char comando[100];
      sprintf(comando, "CHPR %s,%d", rotina.sub_rot.rotulo, nivel_lexico);
      geraCodigo (NULL, comando);
   }
}
;

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
   inicializa_pilha_str(&pilha_simbolos);
   inicializa_pilha_str(&rotulos);
   inicializa_pilha_int(&pilha_tipos);
   
   inicializa_pilha_int(&pilha_ivar);
   inicializa_pilha_int(&pilha_tipoOP);
   inicializa_pilha_str(&pilha_declaraRot);
   inicializa_tabela(&pilha_sub_rotina);

   yyin = fp;
   yyparse();

   return 0;
}