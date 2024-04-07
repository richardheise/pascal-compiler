#define MAX_TABELA 1500
#define MAX_PARAM 20
#define TAM_TOKEN 16
#include "pilha.h"
#include "compilador.h"

enum tipo_variavel { INT, BOOL };
enum tipo_passagem { VALOR, REFERENCIA };
enum tipo_operacao { PADRAO, PROC };
enum tipo_fator { F_NUM, F_IDENT, F_BOOL};

typedef struct {
   char nome[TAM_TOKEN];
   int nivel;
   int deslocamento;
   int tipo;
} variavel_t;

typedef struct {
   char nome[TAM_TOKEN];
   int nivel;
   int deslocamento;
   int tipo;
   int passagem;
} parametro_formal_t;

typedef struct {
   char nome[TAM_TOKEN];
   int nivel;
   char rotulo[TAM_TOKEN];
   int num_param;
   int tipo_param[MAX_PARAM];
   int passagem_param[MAX_PARAM];
} procedimento_t;

typedef struct {
   char nome[TAM_TOKEN];
   int nivel;
   int tipo_retorno;
   char rotulo[TAM_TOKEN];
   int num_param;
   int tipo_param[MAX_PARAM];
   int passagem_param[MAX_PARAM];
} funcao_t;


typedef struct {
   union {
      variavel_t var;
      parametro_formal_t param;
      procedimento_t proc;
      funcao_t func;
   };
   enum tipo_simbolo { VARIAVEL, PARAMETRO_FORMAL, PROCEDIMENTO, FUNCAO } tipo;
} simbolo_t;


typedef struct {
   int topo;
   simbolo_t itens[MAX_TABELA];
} tabela_simbolos_t;


 
void inicializa_tabela (tabela_simbolos_t *ts);

void insere (tabela_simbolos_t *ts, simbolo_t s); 

void retira (tabela_simbolos_t *ts, int n); 

simbolo_t busca (tabela_simbolos_t ts, char* nome);

void imprime (tabela_simbolos_t ts);

void insereVarTabela (tabela_simbolos_t *ts, char* token, int nivel, int deslocamento);

void insereProcTabela (tabela_simbolos_t *ts, char* token, char* rotulo, int nivel);

void insereParamTabela (tabela_simbolos_t *ts, char* token, int nivel, int passagem);

void atualizaTipoVar (tabela_simbolos_t *ts, int tipo, int quant);

void atualizaTipoParam (tabela_simbolos_t *ts, int tipo, int quant);

void atualizaDeslocamentoParam (tabela_simbolos_t *ts, int nivel, int quant);

int quantVariaveis (tabela_simbolos_t ts, int nivel);

simbolo_t buscaSimbolo (tabela_simbolos_t tabela, char* nome);

void validaTipos (pilha_t* pilha, tabela_simbolos_t tabela, int tipo);

void empilhaNUM(char *token, pilha_t *pilha);
void empilhaIDENT(char *token, int ivar, int quantFator, int tipoOP, procedimento_t proc, pilha_t *pilha, tabela_simbolos_t tabela);