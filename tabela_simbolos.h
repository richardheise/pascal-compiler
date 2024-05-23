#define MAX_TABELA 1500
#define MAX_PARAM 20
#define TAM_TOKEN 16
#include "pilha_string.h"
#include "pilha_int.h"
#include "compilador.h"

enum tipo_variavel { INT, BOOL, SEM_TIPO };
enum tipo_passagem { VALOR, REFERENCIA };
enum tipo_operacao { PADRAO, SUB_ROT };
enum tipo_fator { F_NUM, F_IDENT, F_BOOL, F_FUNC};

typedef struct {
   int passagem;
} parametro_formal_t;

typedef struct {
   char rotulo[TAM_TOKEN];
   int num_param;
   int tipo_param[MAX_PARAM];
   int passagem_param[MAX_PARAM];
} sub_rotina_t;

typedef struct {
   int num_param;
   char nome[TAM_TOKEN];
   char *nome_atributo[MAX_PARAM];
   int tipo_atributo[MAX_PARAM];
} record_t;

typedef struct {
   char nome[TAM_TOKEN];
   int nivel;
   int tipo;
   int deslocamento;
   union {
      parametro_formal_t param;
      sub_rotina_t sub_rot;
      record_t record;
   };
   enum tipo_simb { VARIAVEL, PARAMETRO_FORMAL, PROCEDIMENTO, FUNCAO } forma;
} simbolo_t;


typedef struct {
   int topo;
   simbolo_t itens[MAX_TABELA];
} tabela_simbolos_t;


 
void inicializa_tabela (tabela_simbolos_t *ts);

void insere (tabela_simbolos_t *ts, simbolo_t s, int nivel); 

void retira (tabela_simbolos_t *ts, int n);

simbolo_t busca (tabela_simbolos_t ts, char* nome);

void imprime (tabela_simbolos_t ts);

void insereVarTabela (tabela_simbolos_t *ts, char* token, int nivel, int deslocamento);

void insereRotinaTabela (tabela_simbolos_t *ts, char* token, char* rotulo, int nivel, int tipo_rotina);

void insereParamTabela (tabela_simbolos_t *ts, char* token, int nivel, int passagem);

void atualizaTipoVar (tabela_simbolos_t *ts, int tipo, int quant);

void atualizaTipoParam (tabela_simbolos_t *ts, int tipo, int quant);

void atualizaDeslocamentoParam (tabela_simbolos_t *ts, int nivel, int quant);

void atualizaFunc (tabela_simbolos_t *ts, int tipo, int num_vars);

int quantVariaveis (tabela_simbolos_t ts, int nivel);

int quantSubRotinas (tabela_simbolos_t ts, int nivel);

simbolo_t buscaSimbolo (tabela_simbolos_t ts, char* nome);

void validaTipos (pilha_int* pilha, int tipo);

void empilhaNUM (char *token, pilha_int *pilha);

void empilhaIDENT (char *token, int ivar, int quantFator, int tipoOP, sub_rotina_t proc, pilha_int *pilha, tabela_simbolos_t ts);

void empilhaFunc (int tipo, pilha_int *pilha);

void inserePilha (tabela_simbolos_t *ts, simbolo_t s); 
simbolo_t removePilha (tabela_simbolos_t *ts);