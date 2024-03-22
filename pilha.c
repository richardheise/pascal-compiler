#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pilha.h"

 
void inicializa_pilha (pilha_t *p) {
    p->topo = -1;
    return;
}

int pilha_vazia (pilha_t p) {
    if (p.topo == -1)
        return 1;
    
    return 0;
}

int empilha (char* x, pilha_t *p) {
    if (tamanho_pilha (*p) == MAX)
        return 0;

    p->topo = p->topo + 1;
    strncpy(p->itens[p->topo], x, TAM_TOKEN);

    return 1;
}
    
char* desempilha (pilha_t *p) {
    if (pilha_vazia(*p))
        return 0;

    char* aux = p->itens[p->topo];
    p->topo = p->topo - 1;
    
    return aux;
}

int tamanho_pilha(pilha_t p) {
    return p.topo + 1;
}