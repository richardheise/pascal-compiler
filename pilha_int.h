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

#ifndef PILHA_INT
#define PILHA_INT

#define MAX 10000

typedef struct pilha_s {
    int itens[MAX];
    int topo;
} pilha_int;

void inicializa_pilha_int(pilha_int *p);

int pilha_vazia_int(pilha_int p);

int tamanho_pilha_int(pilha_int p);

int empilha_int(int x, pilha_int *p);

int desempilha_int(pilha_int *p);

void imprime_pilha_int(pilha_int *p);

#endif
