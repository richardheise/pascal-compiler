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
#include <string.h>
#include "pilha_string.h"

 
void inicializa_pilha_str (pilha_str *p) {
    p->topo = -1;
    return;
}

int pilha_vazia_str (pilha_str p) {
    if (p.topo == -1)
        return 1;
    
    return 0;
}

int empilha_str (char* x, pilha_str *p) {
    if (tamanho_pilha_str (*p) == MAX)
        return 0;

    p->topo = p->topo + 1;
    strncpy(p->itens[p->topo], x, TAM_TOKEN);

    return 1;
}
    
char* desempilha_str (pilha_str *p) {
    if (pilha_vazia_str(*p))
        return NULL;

    char* aux = p->itens[p->topo];
    p->topo = p->topo - 1;
    
    return aux;
}

int tamanho_pilha_str(pilha_str p) {
    return p.topo + 1;
}

void imprime_pilha_str (pilha_str *p) {
    for (int i = 0; i <= p->topo; i++)
        printf ("%s\n", p->itens[i]);
}