/***********************************************************************
*
* Autor: Eduardo Henrique dos Santos Cerolli
* GRR: 20190397
*
* Autor: Richard Fernando Heise Ferreira
* GRR: 20191053
*
* Data: 23/05/2024
* Instituição: Universidade Federal do Paraná
* Curso: Ciência da Computação
* Motivo: Trabalho de compiladores (CI1211)
*
***********************************************************************/

#define MAX 10000
#define TAM_TOKEN 16

typedef struct pilha_str {
   int topo;
   char itens[MAX][TAM_TOKEN];
} pilha_str; 
 
void inicializa_pilha_str (pilha_str *p); /*inicializa pilha com -1 no topo*/

int pilha_vazia_str (pilha_str p); /*se a pilha eh vazia retorna 1, caso contrario retorna 0*/

int empilha_str (char* x, pilha_str *p);  /*empilha_str o elemento x no topo, se funcionar retorna 1, se não funcionar -- pilha cheia -- retorna 0*/

char* desempilha_str (pilha_str *p);

int tamanho_pilha_str (pilha_str p); /*retorna o tamanho da pilha*/

void imprime_pilha_str (pilha_str *p);