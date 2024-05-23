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

#include <stdio.h>
#include <stdlib.h>
#include "pilha_int.h"

void inicializa_pilha_int(pilha_int *p) {
    p->topo = -1;
}

int pilha_vazia_int(pilha_int p) {
    return p.topo == -1;
}

int tamanho_pilha_int(pilha_int p) {
    return p.topo + 1;
}

int empilha_int(int x, pilha_int *p) {
    if (tamanho_pilha_int(*p) == MAX)
        return 0;

    p->topo++;
    p->itens[p->topo] = x;
    return 1;
}

int desempilha_int(pilha_int *p) {
    if (pilha_vazia_int(*p))
        return 0;

    int aux = p->itens[p->topo];
    p->topo--;
    return aux;
}

void imprime_pilha_int(pilha_int *p) {
    for (int i = 0; i <= p->topo; i++)
        printf("%d\n", p->itens[i]);
}